extends Node
## Pure/render-structure audit for finite move presentation. It never mutates rules.

const MOVE_VFX := preload("res://scripts/ui/battle_move_vfx.gd")
const ATLAS_REPAIR := preload("res://tools/sprite_atlas_edge_repair.gd")

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	_assert_atlas_contract(MOVE_VFX.ELEMENT_ATLAS_PATH, Vector2i(1536, 1024), Vector2i(384, 512), "element")
	_assert_atlas_contract(MOVE_VFX.STATUS_ATLAS_PATH, Vector2i(1772, 886), Vector2i(443, 443), "status")
	var profiles := MOVE_VFX.audit_profiles()
	require(profiles.size() == BattleCatalog.DATA.CREATURES.size(), "every catalog creature has a presentation profile")
	var ids: Dictionary = {}
	var elements: Dictionary = {}
	for profile in profiles:
		var creature_id := str(profile.get("creature_id", ""))
		ids[creature_id] = true
		elements[str(profile.get("element", ""))] = true
		require(not str(profile.get("ability", "")).is_empty() and not str(profile.get("travel", "")).is_empty() and not str(profile.get("impact", "")).is_empty(), "%s has a complete ability profile" % creature_id)
		for accent in profile.get("accents", []):
			require(MOVE_VFX.STATUS_ATLAS_CELLS.has(str(accent)), "%s maps supported status accent %s" % [creature_id, str(accent)])
	require(ids.size() == BattleCatalog.DATA.CREATURES.size() and elements.size() == 8, "presentation audit covers all roster IDs and elements")
	var idle := BattleSpriteStage.new()
	idle.configure({"id":"cinderpaw"}, {"id":"mossmunk"}, "", 0, false, false, 0)
	require(not idle.is_processing() and BattleSpriteStage.select_frame("", 0, true, false, 99.0) == 0, "idle holds first frame without processing")
	var action := BattleSpriteStage.new()
	action.configure({"id":"cinderpaw"}, {"id":"mossmunk"}, "ability", 0, false, false, 1)
	require(action.is_event_active() and action.is_processing() and BattleSpriteStage.select_frame("ability", 0, true, false, 0.2) == 5, "accepted ability starts finite actor sequence")
	action.advance_presentation(1.0)
	require(not action.is_event_active() and not action.is_processing() and BattleSpriteStage.select_frame("ability", 0, true, false, 1.0) == 0, "finite event settles to static idle")
	action.configure({"id":"cinderpaw"}, {"id":"mossmunk"}, "ability", 0, false, false, 2)
	require(action.is_event_active() and is_zero_approx(action.elapsed), "new monotonic event token replays an identical ability")
	var reduced := BattleSpriteStage.new()
	reduced.configure({"id":"cinderpaw"}, {"id":"mossmunk"}, "ability", 0, true, false, 1)
	require(not reduced.is_event_active() and reduced.is_presentation_window_active() and reduced.is_processing() and BattleSpriteStage.select_frame("ability", 0, true, true, 0.2) == 0, "reduced motion keeps movement static while a finite presentation clock clears the Core peak")
	CreatureSpriteCache.clear_for_test()
	var cinder_path := CreatureSpriteCache.sprite_path_for("cinderpaw")
	var cold_started := Time.get_ticks_usec()
	var first_texture := CreatureSpriteCache.texture_for_creature("cinderpaw")
	var cold_usec := Time.get_ticks_usec() - cold_started
	var cached_started := Time.get_ticks_usec()
	var repeated_texture := CreatureSpriteCache.texture_for_creature("cinderpaw")
	var cached_usec := Time.get_ticks_usec() - cached_started
	require(first_texture != null and first_texture == repeated_texture and CreatureSpriteCache.texture_load_count(cinder_path) == 1, "runtime stage reuses the ordinary imported texture without alpha component cleanup")
	print("INFO: runtime texture lookup cold=%dus cached=%dus" % [cold_usec, cached_usec])
	var audited_frames := 0
	for definition in BattleCatalog.DATA.CREATURES:
		var creature_id := str(definition.get("id", ""))
		var sheet_path := str(definition.get("sprite_sheet", ""))
		var sheet_audit := ATLAS_REPAIR.audit_sheet(sheet_path)
		var frame_reports: Array = sheet_audit.get("frames", [])
		require(not sheet_audit.has("error") and frame_reports.size() == 8, "%s repaired atlas has eight auditable cells" % creature_id)
		var imported_texture := ResourceLoader.load(sheet_path) as Texture2D
		var imported_audit := ATLAS_REPAIR.audit_image(imported_texture.get_image() if imported_texture != null else null)
		var imported_frames: Array = imported_audit.get("frames", [])
		require(not imported_audit.has("error") and imported_frames.size() == 8, "%s imported Texture2D exposes all repaired cells" % creature_id)
		for frame_index in frame_reports.size():
			var cleanup: Dictionary = frame_reports[frame_index]
			var imported_cleanup: Dictionary = imported_frames[frame_index] if frame_index < imported_frames.size() else {}
			audited_frames += 1
			require(int(cleanup.get("alpha_pixels", 0)) > 0 and int(cleanup.get("largest_component_pixels", 0)) > 0, "%s frame %d retains valid alpha" % [creature_id, int(cleanup.get("frame", -1))])
			require(int(cleanup.get("secondary_edge_components", -1)) == 0, "%s frame %d has no removable non-largest edge component" % [creature_id, int(cleanup.get("frame", -1))])
			require(int(imported_cleanup.get("secondary_edge_components", -1)) == 0 and int(imported_cleanup.get("alpha_pixels", -1)) == int(cleanup.get("alpha_pixels", -2)), "%s imported frame %d matches repaired source alpha with no edge spill" % [creature_id, int(cleanup.get("frame", -1))])
	require(audited_frames == 24 * 8, "offline atlas audit visits all 24 sheets and eight cells")
	var safe_idle := BattleSpriteStage.safe_source_region("cinderpaw", 0)
	var safe_action := BattleSpriteStage.safe_source_region("cinderpaw", 5)
	require(safe_idle.position == Vector2(CreatureSpriteCache.ATLAS_GUTTER, CreatureSpriteCache.ATLAS_GUTTER) and safe_idle.size == safe_action.size and safe_action.position - Vector2(384, 512) == safe_idle.position and safe_action.end.x <= 2.0 * 384.0 - CreatureSpriteCache.ATLAS_GUTTER and safe_action.end.y <= 2.0 * 512.0 - CreatureSpriteCache.ATLAS_GUTTER, "stage uses the same stable inset crop for every repaired atlas frame")
	var optional_element := MOVE_VFX.optional_element_atlas()
	var optional_status := MOVE_VFX.optional_status_atlas()
	require((not ResourceLoader.exists(MOVE_VFX.ELEMENT_ATLAS_PATH) or optional_element != null) and (not ResourceLoader.exists(MOVE_VFX.STATUS_ATLAS_PATH) or optional_status != null), "optional atlas paths either load or safely retain code-native fallback")
	if failures.is_empty():
		print("PASS: finite battle move presentation and roster audit")
	call_deferred("finish")

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)

func _assert_atlas_contract(path: String, expected_size: Vector2i, cell: Vector2i, label_text: String) -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	require(image != null and not image.is_empty() and image.get_size() == expected_size, "%s atlas has expected 4x2 source dimensions" % label_text)
	if image == null or image.is_empty() or image.get_size() != expected_size:
		return
	for cell_index in 8:
		var origin := Vector2i((cell_index % 4) * cell.x, (cell_index / 4) * cell.y)
		var opaque_samples := 0
		for sample_y in 5:
			for sample_x in 5:
				var probe := origin + Vector2i(24 + sample_x * (cell.x - 48) / 4, 24 + sample_y * (cell.y - 48) / 4)
				if image.get_pixelv(probe).a > 0.08:
					opaque_samples += 1
		require(opaque_samples > 0, "%s atlas cell %d has visible alpha content" % [label_text, cell_index])
