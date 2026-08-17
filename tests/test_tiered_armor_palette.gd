extends Node
## Ensures every visual tier remains shader-only over the same alpha master.

const PREVIEW := preload("res://scripts/ui/tiered_armor_palette_preview.gd")
const ROSTER := preload("res://scripts/ui/tiered_armor_roster.gd")
const MASTER_PATH := PREVIEW.MASTER_PATH
const SHADER_PATH := "res://assets/armor/tiered/cinderpaw_tier_palette.gdshader"
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(MASTER_PATH))
	require(image != null and not image.is_empty() and image.get_format() == Image.FORMAT_RGBA8 and image.get_size() == Vector2i(1254, 1254), "tiered armor runtime master is one 1254px RGBA texture")
	if image != null and not image.is_empty():
		_assert_alpha_and_mask_contract(image)
	var source_hash := _sha256(FileAccess.get_file_as_bytes(ProjectSettings.globalize_path(MASTER_PATH)))
	var palette_ids := PREVIEW.tier_ids()
	require(palette_ids == ["standard", "reinforced", "arcane", "masterwork", "legendary"], "five named presentation tiers are stable")
	for tier_id in palette_ids:
		require(PREVIEW.source_path_for_tier(tier_id) == MASTER_PATH and _sha256(FileAccess.get_file_as_bytes(ProjectSettings.globalize_path(PREVIEW.source_path_for_tier(tier_id)))) == source_hash, "%s tier uses the same master source hash" % tier_id)
		var palette: Dictionary = PREVIEW.PALETTES[tier_id]
		require(palette.has("shadow") and palette.has("primary") and palette.has("highlight"), "%s tier supplies all shader palette parameters" % tier_id)
	var tiered_dir := ProjectSettings.globalize_path("res://assets/armor/tiered")
	var pngs: Array[String] = []
	for filename in DirAccess.get_files_at(tiered_dir):
		if filename.to_lower().ends_with(".png"):
			pngs.append(filename)
	var recognized_masters := true
	for filename in pngs:
		recognized_masters = recognized_masters and ROSTER.expected_file_names().has(filename)
	require(pngs.has("cinderpaw_tiered_armor_signature_green_alpha_v3.png") and recognized_masters, "tiered armor directory contains only registered creature masters, with Cinderpaw v3 retained")
	var shader_text := FileAccess.get_file_as_string(ProjectSettings.globalize_path(SHADER_PATH))
	for uniform_name in ["plate_shadow", "plate_primary", "plate_highlight", "plate_mask_texture"]:
		require(shader_text.contains(uniform_name), "palette shader exposes %s" % uniform_name)
	if failures.is_empty():
		print("PASS: Cinderpaw alpha master and five shader-only palette contracts")
	call_deferred("finish")

func _assert_alpha_and_mask_contract(image: Image) -> void:
	for point in [Vector2i(0, 0), Vector2i(1253, 0), Vector2i(0, 1253), Vector2i(1253, 1253)]:
		require(image.get_pixelv(point).a <= 0.01, "runtime master has transparent outer corners")
	var opaque := 0
	var transparent := 0
	var magenta := 0
	var masked := 0
	var preserved := 0
	var legendary := PREVIEW.PALETTES.legendary
	for y in range(12, image.get_height(), 18):
		for x in range(12, image.get_width(), 18):
			var color := image.get_pixel(x, y)
			if color.a <= 0.04:
				transparent += 1
				continue
			opaque += 1
			if color.r > 0.65 and color.b > 0.55 and color.g < 0.45:
				magenta += 1
			var mask := PREVIEW.armor_mask_for_color(color)
			var recolored := PREVIEW.recolor_source_color(color, legendary)
			if mask > 0.10:
				masked += 1
			elif mask <= 0.0:
				preserved += 1
				require(recolored.is_equal_approx(color), "non-armor source colors stay stable under palette math")
	require(opaque > 200 and transparent > 400 and masked > 40 and preserved > 120 and magenta == 0, "alpha master has subject coverage, transparent surround, blue plate mask coverage, preserved source colors, and no magenta fringe")

func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
