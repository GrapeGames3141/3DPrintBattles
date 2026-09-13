extends Node
## Offline source/import contract for 23 directional 4x2 sheets plus Voltwig's
## reviewed two-cell front/rear neutral atlas. Runtime loads Texture2D only.

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
	require(FACING.release_coverage_errors().is_empty(), "All 24 catalog creatures have required genuine directional battle coverage.")
	require(FACING.frame_for(1, 0.0) == 0 and FACING.frame_for(1, .51) == 1, "The 4x2 cache preserves rival front-row idle cadence.")
	require(FACING.frame_for(0, 0.0) == 4 and FACING.frame_for(0, .51) == 5, "The 4x2 cache preserves friendly rear-row idle cadence.")
	require(FACING.frame_for(1, 0.0, "attack", .20) == 2 and FACING.frame_for(1, 0.0, "attack", .50) == 3 and FACING.frame_for(1, 0.0, "attack", .85) < 2, "The 4x2 cache preserves rival finite windup/contact/recovery mapping.")
	require(FACING.frame_for(0, 0.0, "attack", .20) == 6 and FACING.frame_for(0, 0.0, "attack", .50) == 7 and FACING.frame_for(0, 0.0, "attack", .85) < 6, "The 4x2 cache preserves friendly finite windup/contact/recovery mapping.")
	require(FACING.raw_frame_for(1) == 0 and FACING.raw_frame_for(0) == 4, "The 4x2 cache preserves seat-correct raw print rows.")
	require(FACING.frame_for(-1, 0.0) == -1 and FACING.raw_frame_for(2) == -1 and FACING.frame_for_creature("cinderpaw", -1, 0.0) == -1 and FACING.raw_frame_for_creature("cinderpaw", 2) == -1, "Invalid seat values reject instead of selecting front/rear art.")
	require(FACING.frame_for_creature(VOLTWIG, 1, .51, "attack", .50) == 0 and FACING.frame_for_creature(VOLTWIG, 0, .51, "attack", .50) == 1, "Voltwig keeps genuine front/rear neutral cells through finite motion without invented poses.")
	require(FACING.raw_frame_for_creature(VOLTWIG, 1) == 0 and FACING.raw_frame_for_creature(VOLTWIG, 0) == 1, "Voltwig raw clipping uses the same seat-correct front/rear cells.")
	require(FACING.frame_for_creature("not_a_catalog_creature", 0, 0.0) == -1 and not FACING.is_valid_frame_for_creature(VOLTWIG, 2) and FACING.safe_source_region_for_creature(VOLTWIG, 2) == FACING.INVALID_SOURCE_REGION, "Invalid creature IDs, seats, and Voltwig frames fail closed without a full-atlas fallback.")
	for definition in Catalog.CREATURES:
		_validate_creature(definition as Dictionary)
	if failures.is_empty():
		print("PASS: Battle-facing cache covers all 24 directional species")
	get_tree().quit(0 if failures.is_empty() else 1)

func _validate_creature(definition: Dictionary) -> void:
	var creature_id := str(definition.get("id", ""))
	var is_voltwig := creature_id == VOLTWIG
	var expected_path := FACING.VOLTWIG_FACING_PATH if is_voltwig else "%s/%s%s" % [FACING.FACING_DIRECTORY, creature_id, FACING.FACING_SUFFIX]
	var expected_size := Vector2i(768, 512) if is_voltwig else Vector2i(1536, 1024)
	var expected_frames := 2 if is_voltwig else 8
	require(FACING.has_directional_coverage(creature_id), "%s has explicit directional battle coverage." % creature_id)
	require(not FACING.uses_legacy_art(creature_id), "%s is not classified as legacy side-view coverage." % creature_id)
	require(FACING.coverage_kind_for(creature_id) == ("directional_neutral" if is_voltwig else "directional"), "%s uses its reviewed directional coverage kind." % creature_id)
	require(FACING.sprite_path_for(creature_id) == expected_path, "%s resolves only its explicit battle atlas." % creature_id)
	require(FACING.atlas_size_for_creature(creature_id) == expected_size and FACING.frame_count_for_creature(creature_id) == expected_frames, "%s exposes the expected atlas geometry contract." % creature_id)
	for seat in [0, 1]:
		var raw_frame := FACING.raw_frame_for_creature(creature_id, seat)
		var idle_frame := FACING.frame_for_creature(creature_id, seat, .51)
		var action_frame := FACING.frame_for_creature(creature_id, seat, 0.0, "attack", .50)
		require(raw_frame >= 0 and raw_frame < expected_frames and idle_frame >= 0 and idle_frame < expected_frames and action_frame >= 0 and action_frame < expected_frames, "%s seat %d has valid raw, idle, and finite action frames." % [creature_id, seat])
		for frame in [raw_frame, idle_frame, action_frame]:
			require(FACING.safe_source_region_for_creature(creature_id, frame).size == Vector2(380, 508), "%s seat %d frame %d keeps its two-pixel safe source region." % [creature_id, seat, frame])
	var texture := FACING.texture_for_creature(creature_id)
	require(texture != null and texture.get_size() == Vector2(expected_size), "%s imports at its exact species-aware atlas size." % creature_id)
	if texture == null:
		return
	var first_loads := int((FACING.debug_stats().get("texture_loads", {}) as Dictionary).get(expected_path, 0))
	require(FACING.texture_for_creature(creature_id) == texture and int((FACING.debug_stats().get("texture_loads", {}) as Dictionary).get(expected_path, 0)) == first_loads, "%s cache reuse does not grow texture loads." % creature_id)
	var image := Image.load_from_file(ProjectSettings.globalize_path(expected_path))
	require(image != null and image.get_size() == expected_size, "%s source atlas is readable at its exact contract size." % creature_id)
	if image == null:
		return
	if is_voltwig:
		_validate_voltwig(image)
	else:
		_validate_directional_cells(creature_id, image)

func _validate_voltwig(image: Image) -> void:
	var signatures: Dictionary = {}
	for frame in [0, 1]:
		var region := FACING.safe_source_region_for_creature(VOLTWIG, frame)
		require(region.size == Vector2(380, 508), "Voltwig frame %d retains the two-pixel safe gutter." % frame)
		require(_cell_edges_are_clear(image, frame, 2), "Voltwig frame %d has two transparent edge pixels." % frame)
		var signature := _alpha_signature(image, frame, 2)
		require(not signatures.has(signature), "Voltwig front and rear cells have distinct alpha signatures.")
		signatures[signature] = frame
	require(signatures.size() == 2, "Voltwig exposes exactly two genuine directional-neutral cells.")

func _validate_directional_cells(creature_id: String, image: Image) -> void:
	var signatures: Dictionary = {}
	for frame in 8:
		require(_cell_edges_are_clear(image, frame, 4), "%s directional frame %d keeps transparent safe edges." % [creature_id, frame])
		var signature := _alpha_signature(image, frame, 4)
		require(not signatures.has(signature), "%s directional frame %d has a distinct alpha silhouette." % [creature_id, frame])
		signatures[signature] = frame
	require(signatures.size() == 8, "%s retains all eight reviewed 4x2 cells." % creature_id)

func _cell_edges_are_clear(image: Image, frame: int, columns: int) -> bool:
	var origin := Vector2i((frame % columns) * 384, (frame / columns) * 512)
	for x in range(origin.x, origin.x + 384):
		if image.get_pixel(x, origin.y).a > .04 or image.get_pixel(x, origin.y + 1).a > .04 or image.get_pixel(x, origin.y + 510).a > .04 or image.get_pixel(x, origin.y + 511).a > .04:
			return false
	for y in range(origin.y, origin.y + 512):
		if image.get_pixel(origin.x, y).a > .04 or image.get_pixel(origin.x + 1, y).a > .04 or image.get_pixel(origin.x + 382, y).a > .04 or image.get_pixel(origin.x + 383, y).a > .04:
			return false
	return true

func _alpha_signature(image: Image, frame: int, columns: int) -> String:
	var origin := Vector2i((frame % columns) * 384, (frame / columns) * 512)
	var signature := ""
	for y in range(origin.y + 8, origin.y + 504, 8):
		for x in range(origin.x + 8, origin.x + 376, 8):
			signature += "1" if image.get_pixel(x, y).a > .04 else "0"
	return signature
