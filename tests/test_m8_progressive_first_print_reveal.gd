extends Node

## M8 presentation-only guard: the Forge must never project a finished creature
## before the authoritative raw-complete boundary, and Back must preserve an
## accepted presentation for caller-safe resume.

const FORGE := preload("res://scripts/ui/arcane_forge_stage.gd")
const MAIN := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if value:
		return
	failures.append(message)
	push_error(message)

func _ready() -> void:
	await _progressive_masks()
	await _continuity_near_complete_guard()
	await _caller_safe_back()
	if failures.is_empty():
		print("PASS: M8 progressive Forge reveal and caller-safe Back contract")
	get_tree().quit(0 if failures.is_empty() else 1)

func _progressive_masks() -> void:
	var forge := FORGE.new()
	forge.name = "M8ForgePresentation"
	forge.size = Vector2(576, 700)
	add_child(forge)
	forge.configure("cinderpaw", false, false)
	forge.set_preview_phase(ArcaneForgeSequence.IDLE, 0)
	await get_tree().process_frame
	require(forge._last_solid_rect.size == Vector2.ZERO and forge._last_wireframe_rect.size == Vector2.ZERO and forge._last_scan_count == 0, "M8 idle keeps the build bed free of raw/wireframe creature geometry.")
	var printable_at_99 := Rect2()
	for progress in [1, 700, 1750, 4200, 6930]:
		forge.set_preview_phase(ArcaneForgeSequence.PRINTING, int(progress))
		await get_tree().process_frame
		var printable: Rect2 = forge._last_printable_rect
		var solid: Rect2 = forge._last_solid_rect
		var preview: Rect2 = forge._last_wireframe_rect
		var opaque_source: Rect2 = forge._last_opaque_source_bounds
		var first_layer := int(progress) <= 70
		var band_ok := preview.size.y <= printable.size.y * 0.0801 and preview.position.y >= printable.position.y - 0.5
		var solid_ok := first_layer or (solid.size.y > 0.0 and solid.end.y <= printable.end.y + 0.5 and solid.size.y < printable.size.y)
		var adjacent := first_layer or absf(preview.end.y - (solid.position.y - 1.0)) <= 1.5
		require(printable.size.y > 0.0 and forge._last_scan_count == 1 and (first_layer or band_ok) and solid_ok and (first_layer or preview.size.y > 0.0) and adjacent, "M8 progress %d keeps solid strictly below one scan datum with a single local <=8%% wireframe band (scan=%d first=%s band=%s solid_ok=%s adjacent=%s printable=%s solid=%s preview=%s)." % [int(progress), forge._last_scan_count, str(first_layer), str(band_ok), str(solid_ok), str(adjacent), str(printable), str(solid), str(preview)])
		if int(progress) == 6930: printable_at_99 = printable
		if int(progress) == 6930:
			var scan_y := solid.position.y - 1.0
			require(opaque_source.size.y > 0.0 and forge._last_revealed_opaque_rows > 0 and forge._last_unrevealed_opaque_rows >= 1 and scan_y >= printable.position.y - 1.5 and scan_y <= printable.end.y + 1.5, "M8 99%% reveal is alpha-aware: at least one real upper opaque source row remains hidden and the one datum intersects the actual opaque printable extent (source=%s revealed=%d hidden=%d scan=%.2f printable=%s)." % [opaque_source, forge._last_revealed_opaque_rows, forge._last_unrevealed_opaque_rows, scan_y, printable])
	forge.configure("cinderpaw", true, false)
	forge.set_preview_phase(ArcaneForgeSequence.PRINTING, 4200)
	await get_tree().process_frame
	require(forge._last_solid_rect.size.y > 0.0 and forge._last_solid_rect.size.y < forge._last_printable_rect.size.y and forge._last_wireframe_rect.size.y <= forge._last_preview_band_limit + 0.5, "M8 reduced motion preserves the 60% progressive-mask ownership instead of jumping to a complete figure.")
	forge.configure("cinderpaw", false, false)
	forge.set_preview_phase(ArcaneForgeSequence.RAW_COMPLETE, ArcaneForgeSequence.PRINT_COMPLETE_BPS)
	await get_tree().process_frame
	require(forge._last_solid_rect.size.y >= forge._last_printable_rect.size.y - 1.5 and forge._last_wireframe_rect.size == Vector2.ZERO and forge._last_printable_rect.position.distance_to(printable_at_99.position) <= 1.0 and forge._last_printable_rect.size.distance_to(printable_at_99.size) <= 1.0, "M8 permits the full raw print only at RAW_COMPLETE without a 99%-to-raw geometry pop.")
	forge.set_preview_phase(ArcaneForgeSequence.AWAKENING, ArcaneForgeSequence.PRINT_COMPLETE_BPS, 5000)
	await get_tree().process_frame
	require(forge._last_solid_rect.size.y > 0.0, "M8 retains raw ownership only during the finite awakening handoff.")
	forge.set_preview_phase(ArcaneForgeSequence.DEPARTING, ArcaneForgeSequence.PRINT_COMPLETE_BPS, 5000)
	await get_tree().process_frame
	require(forge._last_solid_rect.size == Vector2.ZERO and forge._last_wireframe_rect.size == Vector2.ZERO, "M8 departure clears raw/wireframe bed geometry before the living print leaves.")
	forge.queue_free()

func _continuity_near_complete_guard() -> void:
	# The approved physical station is rasterized at both normal review sizes.
	# At 99% it must retain a truly visible final slice, including reduced motion;
	# only RAW_COMPLETE may expose the full alpha-bound raw source.
	for raster in [Vector2(576, 1024), Vector2(720, 1280)]:
		for reduced in [false, true]:
			var forge := FORGE.new()
			forge.name = "M8ContinuityGuard-%dx%d-%s" % [int(raster.x), int(raster.y), "rm" if reduced else "normal"]
			forge.size = raster
			add_child(forge)
			forge.configure("cinderpaw", reduced, false)
			forge.set_continuity_station(true)
			forge.set_preview_phase(ArcaneForgeSequence.PRINTING, 6930)
			await get_tree().process_frame
			require(forge._last_unrevealed_opaque_rows > 0 and forge._last_unrevealed_logical_pixels >= 4.0 and forge._last_solid_rect.size.y < forge._last_printable_rect.size.y, "M8 continuity %dx%d %s keeps a visible %.2f logical-pixel final raw slice below the single scan datum at 99%%." % [int(raster.x), int(raster.y), "reduced motion" if reduced else "normal", forge._last_unrevealed_logical_pixels])
			forge.set_preview_phase(ArcaneForgeSequence.RAW_COMPLETE, ArcaneForgeSequence.PRINT_COMPLETE_BPS)
			await get_tree().process_frame
			require(forge._last_unrevealed_opaque_rows == 0 and forge._last_unrevealed_logical_pixels == 0.0 and forge._last_solid_rect.size.y >= forge._last_printable_rect.size.y - 1.5, "M8 continuity %dx%d %s exposes the full raw source only at RAW_COMPLETE." % [int(raster.x), int(raster.y), "reduced motion" if reduced else "normal"])
			forge.queue_free()

func _caller_safe_back() -> void:
	var selected: Dictionary = RULES.choose_starter(RULES.new_profile(), "cinderpaw").profile
	GameManager.profile = selected.duplicate(true)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(576, 1024)
	viewport.size_2d_override = Vector2i(576, 1024)
	viewport.size_2d_override_stretch = true
	viewport.disable_3d = true
	add_child(viewport)
	var canvas := Control.new()
	canvas.size = Vector2(576, 1024)
	viewport.add_child(canvas)
	var main := MAIN.instantiate()
	canvas.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().process_frame
	# This continuity fixture owns every presentation advance explicitly below.
	# Freeze Main's wall-clock tick so frame waits used for layout cannot race the
	# exact accepted sequence/progress comparison across caller-safe Back/resume.
	main.set_process(false)
	main.screen = "onboarding"
	main.open_printer("cinderpaw")
	await get_tree().process_frame
	var back := main.find_child("ArcaneForgeBack", true, false) as Button
	var profile_before := JSON.stringify(GameManager.profile)
	print("M8 back idle=%s rect=%s text=%s accessible=%s caller=%s" % [str(back != null), str(back.get_global_rect() if back != null else Rect2()), str(back.text if back != null else ""), str(back.accessibility_name if back != null else ""), main.printer_return_screen])
	require(back != null and back.get_global_rect().size.x >= 48.0 and back.get_global_rect().size.y >= 48.0 and back.text == "BACK TO\nWORKSHOP" and back.accessibility_name.contains("Back to Workshop") and back.find_child("PhysicalInsetFocusRing", true, false) != null, "M8 starter First Print exposes a readable two-line physical Back to Workshop target with truthful single-line accessibility copy and complete inset focus owner.")
	back.emit_signal("pressed")
	await get_tree().process_frame
	require(main.screen == "workshop" and JSON.stringify(GameManager.profile) == profile_before, "M8 visible idle Back returns the starter review to Workshop with zero profile mutation.")
	main.open_printer("cinderpaw")
	main.begin_printer()
	main.advance_printer_for_test(4200)
	await get_tree().process_frame
	var active_sequence: Variant = main.printer_sequence
	var active_progress: int = int(main.printer_sequence.progress_bps) if main.printer_sequence != null else -1
	var active_profile := JSON.stringify(GameManager.profile)
	main.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	await get_tree().process_frame
	require(main.screen == "workshop" and main.printer_sequence == active_sequence and main.printer_sequence.progress_bps == active_progress and JSON.stringify(GameManager.profile) == active_profile, "M8 Android Back leaves the accepted sequence intact at its caller instead of cancelling or committing it.")
	main.open_printer("cinderpaw")
	await get_tree().process_frame
	print("M8 back resume screen=%s same=%s progress=%d/%d phase=%s" % [main.screen, str(main.printer_sequence == active_sequence), main.printer_sequence.progress_bps if main.printer_sequence != null else -1, active_progress, str(main.printer_sequence.phase if main.printer_sequence != null else "")])
	require(main.screen == "printer" and main.printer_sequence == active_sequence and main.printer_sequence.progress_bps == active_progress, "M8 re-entering Forge resumes the same accepted sequence and progress without a duplicate print.")
	# A Title-resumed starter never inherits the Workshop caller. Its visible and
	# terminal Back paths return to Title without reopening starter selection.
	main.printer_sequence = null
	main.screen = "title"
	main.open_printer("cinderpaw")
	await get_tree().process_frame
	var title_back := main.find_child("ArcaneForgeBack", true, false) as Button
	require(title_back != null and title_back.text == "BACK TO\nTITLE" and title_back.accessibility_name.contains("Back to Title"), "M8 Title-resumed First Print names Title in its compact Back plaque and accessibility copy.")
	title_back.emit_signal("pressed")
	await get_tree().process_frame
	require(main.screen == "title", "M8 Title-resumed idle Back returns to Title rather than starter carousel or Workshop.")
	viewport.queue_free()
