extends Node

const ROOT := "res://assets/ui/physical_ui/live-correction-r1/controls/"
const KINDS := ["wide_parchment_tab", "binding_tab", "square_stud", "tall_index", "lever", "token"]
const STATES := ["normal", "focused", "pressed", "disabled"]
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func read(path: String) -> String:
	return FileAccess.get_file_as_string(path)

func _ready() -> void:
	var processor := read("res://tools/process_live_control_atlas.gd")
	require(processor.contains("_keep_center_component") and processor.contains("near_neutral"), "Atlas processor must remove checkerboard and reject adjacent-row leakage.")
	for kind in KINDS:
		for state in STATES:
			var path := "%s%s/%s.png" % [ROOT, kind, state]
			var image := Image.new(); require(image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK, "Missing processed physical control: %s" % path)
			require(image.get_format() == Image.FORMAT_RGBA8, "Processed physical control must preserve RGBA alpha: %s" % path)
			var corners := [image.get_pixel(0, 0), image.get_pixel(image.get_width() - 1, 0), image.get_pixel(0, image.get_height() - 1), image.get_pixel(image.get_width() - 1, image.get_height() - 1)]
			var transparent_corner := false
			for corner in corners:
				if corner.a < 0.25: transparent_corner = true
			require(transparent_corner, "Processed slice needs transparent checkerboard-free edge: %s" % path)
	var family := read("res://scripts/ui/physical_control_family.gd")
	var imprint := read("res://scripts/ui/physical_catalog_imprint.gd")
	var archive := read("res://scripts/ui/physical_archive_workbench_component.gd")
	var supply := read("res://scripts/ui/physical_supply_reward_component.gd")
	var settings := read("res://scripts/ui/physical_settings_recovery_component.gd")
	var result := read("res://scripts/ui/physical_result_receipt_component.gd")
	require(family.contains("StyleBoxTexture") and family.contains("transparent_hit") and family.contains("content_margin_top") and family.contains("pressed") and family.contains("disabled"), "Physical family must provide visible material normal/focus/pressed/disabled state overlays, including transparent-hit feedback.")
	var shader := read("res://scripts/ui/physical_catalog_imprint.gdshader")
	require(imprint.contains("clip_contents = true") and imprint.contains("ShaderMaterial"), "Catalog imprint must be clipped and material-backed.")
	require(imprint.contains("remove_dark_matte") and shader.contains("uniform bool remove_dark_matte") and shader.contains("dark_matte") and shader.contains("edge") and shader.contains("low-luminance"), "Support art seating must remove opaque black matte corners only for support/card art while preserving transparent creature ink.")
	require(archive.contains("Place %s in Pre-Print") and archive.contains("ArchiveDetailOpenDeck"), "Deck clamp placement and Archive-to-Deck handoff must be reachable.")
	require(supply.contains("inspect committed pack card") and not supply.contains("focus_mode = Control.FOCUS_NONE"), "Persisted Pack cards must be focusable inspection controls.")
	require(not settings.contains('"RecoveryBack"'), "Recovery must not render a false Back action under read-only guard.")
	require(not result.contains('"ResultReceiptBack"'), "Result Continue must be the single exit owner.")
	if failures.is_empty(): print("PASS: M3 live physical art integration")
	get_tree().quit(0 if failures.is_empty() else 1)
