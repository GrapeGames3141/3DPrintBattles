extends Node
## Offline import/atlas proof for the battle-only facing family. This samples
## source PNGs only in editor QA; runtime resolves imported Texture2D resources.

const FACING := preload("res://scripts/ui/battle_facing_sprite_cache.gd")
const VOLTWIG := "voltwig"

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if value:
		return
	failures.append(message)
	push_error(message)

func _ready() -> void:
	FACING.clear_for_test()
	require(FACING.release_coverage_errors().is_empty(), "All 24 catalog creatures have approved interim battle presentation coverage: 23 directional sheets plus the named Voltwig legacy resource.")
	require(FACING.frame_for(1, 0.0) == 0 and FACING.frame_for(1, .51) == 1, "Directional rival seat maps its idle cadence to the front row.")
	require(FACING.frame_for(0, 0.0) == 4 and FACING.frame_for(0, .51) == 5, "Directional friendly seat maps its idle cadence to the rear row.")
	require(FACING.frame_for(1, 0.0, "attack", .20) == 2 and FACING.frame_for(1, 0.0, "attack", .50) == 3 and FACING.frame_for(1, 0.0, "attack", .85) < 2, "Directional rival attack uses only its finite front windup/contact cells.")
	require(FACING.frame_for(0, 0.0, "attack", .20) == 6 and FACING.frame_for(0, 0.0, "attack", .50) == 7 and FACING.frame_for(0, 0.0, "attack", .85) < 6, "Directional friendly attack uses only its finite rear windup/contact cells.")
	require(FACING.raw_frame_for(1) == 0 and FACING.raw_frame_for(0) == 4, "Directional printers retain their front/rear first-idle silhouette through raw-print clipping.")
	require(FACING.frame_for(-1, 0.0) == -1 and FACING.raw_frame_for(2) == -1 and FACING.frame_for_creature("cinderpaw", -1, 0.0) == -1 and FACING.raw_frame_for_creature("cinderpaw", 2) == -1, "Invalid seat values are rejected rather than silently selecting front/rear art.")
	require(not FACING.has_interim_coverage("not_a_catalog_creature") and FACING.coverage_kind_for("not_a_catalog_creature") == "missing" and FACING.frame_for_creature("not_a_catalog_creature", 0, 0.0) == -1, "Arbitrary missing IDs are rejected before they can substitute Mossmunk or another creature's battle art.")
	for definition in Catalog.CREATURES:
		_validate_creature(definition as Dictionary)
	if failures.is_empty():
		print("PASS: M11 interim battle-facing cache covers 23 directional species and explicit legacy Voltwig")
	get_tree().quit(0 if failures.is_empty() else 1)

func _validate_creature(definition: Dictionary) -> void:
	var creature_id := str(definition.get("id", ""))
	var is_voltwig := creature_id == VOLTWIG
	var path := FACING.sprite_path_for(creature_id)
	require(FACING.has_interim_coverage(creature_id), "%s has an explicit interim battle-art resource." % creature_id)
	require(FACING.uses_legacy_art(creature_id) == is_voltwig, "%s's legacy-art flag is exact; only Voltwig is the approved exception." % creature_id)
	require(FACING.coverage_kind_for(creature_id) == ("legacy_voltwig" if is_voltwig else "directional"), "%s is classified as its approved coverage kind." % creature_id)
	require(FACING.has_directional_coverage(creature_id) == not is_voltwig, "%s directional coverage distinguishes the reviewed 23-sheet family from Voltwig's named legacy resource." % creature_id)
	require(path == (FACING.LEGACY_VOLTWIG_PATH if is_voltwig else "%s/%s%s" % [FACING.FACING_DIRECTORY, creature_id, FACING.FACING_SUFFIX]), "%s resolves only its approved resource path." % creature_id)
	var texture := FACING.texture_for_creature(creature_id)
	require(texture != null, "%s battle-art resource imports as a Texture2D." % creature_id)
	if texture == null:
		return
	require(texture.resource_path == path, "%s resolves only its own explicit resource." % creature_id)
	var first_loads := int((FACING.debug_stats().get("texture_loads", {}) as Dictionary).get(path, 0))
	require(FACING.texture_for_creature(creature_id) == texture and int((FACING.debug_stats().get("texture_loads", {}) as Dictionary).get(path, 0)) == first_loads, "%s cache reuse does not grow imported texture loads." % creature_id)
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	require(image != null and not image.is_empty(), "%s source PNG is readable for offline atlas QA." % creature_id)
	if image == null or image.is_empty():
		return
	require(image.get_size() == Vector2i(1536, 1024), "%s uses the required eight-cell 1536x1024 atlas geometry." % creature_id)
	for seat in [0, 1]:
		var raw_frame := FACING.raw_frame_for_creature(creature_id, seat)
		var idle_frame := FACING.frame_for_creature(creature_id, seat, .51)
		var action_frame := FACING.frame_for_creature(creature_id, seat, 0.0, "attack", .50)
		require(raw_frame >= 0 and raw_frame < 8 and idle_frame >= 0 and idle_frame < 8 and action_frame >= 0 and action_frame < 8, "%s seat %d has valid raw, idle, and finite attack frames." % [creature_id, seat])
		for frame in [raw_frame, idle_frame, action_frame]:
			var region := FACING.safe_source_region(frame)
			require(region.size == Vector2(380, 508), "%s seat %d frame %d retains the fixed imported safe region." % [creature_id, seat, frame])
			if not is_voltwig:
				require(_cell_edges_are_clear(image, frame), "%s seat %d frame %d keeps transparent safe edges and does not bleed into a neighbor." % [creature_id, seat, frame])
	if is_voltwig:
		_validate_legacy_voltwig(image)
	else:
		_validate_directional_cells(creature_id, image)

func _validate_directional_cells(creature_id: String, image: Image) -> void:
	var signatures: Dictionary = {}
	for frame in 8:
		require(_cell_edges_are_clear(image, frame), "%s directional frame %d keeps transparent safe edges and does not bleed into a neighbor." % [creature_id, frame])
		var signature := _alpha_signature(image, frame)
		require(not signatures.has(signature), "%s directional frame %d has a distinct alpha silhouette/pose." % [creature_id, frame])
		signatures[signature] = frame
	require(signatures.size() == 8, "%s exposes eight distinct reviewed front/rear idle, windup, and contact cells." % creature_id)

func _validate_legacy_voltwig(image: Image) -> void:
	# This verifies the legacy sheet is a stable eight-cell source without making
	# a false front/rear claim. Both ownership seats deliberately share it.
	for frame in 8:
		require(FACING.safe_source_region(frame).size == Vector2(380, 508) and _cell_has_visible_alpha(image, frame), "Voltwig legacy cell %d remains a visible safe-cropped legacy source cell without a directional gutter assertion." % frame)
	require(FACING.raw_frame_for_creature(VOLTWIG, 0) == 0 and FACING.raw_frame_for_creature(VOLTWIG, 1) == 0, "Voltwig raw print uses neutral legacy idle frame 0 on both seats, not directional front/rear rows.")
	require(FACING.frame_for_creature(VOLTWIG, 0, .51) == FACING.frame_for_creature(VOLTWIG, 1, .51) and FACING.frame_for_creature(VOLTWIG, 0, .51) in [0, 1, 2, 3], "Voltwig idle remains in legacy idle frames 0..3 on both seats.")
	for progress in [.10, .30, .50, .70]:
		var first := FACING.frame_for_creature(VOLTWIG, 0, 0.0, "attack", progress)
		var second := FACING.frame_for_creature(VOLTWIG, 1, 0.0, "attack", progress)
		require(first == second and first >= 4 and first <= 7, "Voltwig attack progress %.2f uses a shared finite legacy action frame 4..7, not a directional row." % progress)

func _cell_edges_are_clear(image: Image, frame: int) -> bool:
	var origin := Vector2i((frame % 4) * 384, (frame / 4) * 512)
	for x in range(origin.x, origin.x + 384):
		if image.get_pixel(x, origin.y).a > .04 or image.get_pixel(x, origin.y + 1).a > .04 or image.get_pixel(x, origin.y + 510).a > .04 or image.get_pixel(x, origin.y + 511).a > .04:
			return false
	for y in range(origin.y, origin.y + 512):
		if image.get_pixel(origin.x, y).a > .04 or image.get_pixel(origin.x + 1, y).a > .04 or image.get_pixel(origin.x + 382, y).a > .04 or image.get_pixel(origin.x + 383, y).a > .04:
			return false
	return true

func _alpha_signature(image: Image, frame: int) -> String:
	var origin := Vector2i((frame % 4) * 384, (frame / 4) * 512)
	var signature := ""
	for y in range(origin.y + 8, origin.y + 504, 8):
		for x in range(origin.x + 8, origin.x + 376, 8):
			signature += "1" if image.get_pixel(x, y).a > .04 else "0"
	return signature

func _cell_has_visible_alpha(image: Image, frame: int) -> bool:
	var region := FACING.safe_source_region(frame)
	for y in range(int(region.position.y), int(region.end.y), 8):
		for x in range(int(region.position.x), int(region.end.x), 8):
			if image.get_pixel(x, y).a > .04:
				return true
	return false
