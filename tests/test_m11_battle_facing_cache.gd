extends Node
## Offline import/atlas proof for the battle-only facing family.  This intentionally
## samples source PNGs during QA; the runtime cache never reads images or scans alpha.

const FACING := preload("res://scripts/ui/battle_facing_sprite_cache.gd")

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if value:
		return
	failures.append(message)
	push_error(message)

func _ready() -> void:
	FACING.clear_for_test()
	require(FACING.release_coverage_errors().is_empty(), "Every catalog creature must have a dedicated battle-facing sheet; the battle stage may not fall back to legacy side art.")
	require(FACING.frame_for(1, 0.0) == 0 and FACING.frame_for(1, .51) == 1, "Rival seat maps its idle cadence to the front row.")
	require(FACING.frame_for(0, 0.0) == 4 and FACING.frame_for(0, .51) == 5, "Friendly seat maps its idle cadence to the rear row.")
	require(FACING.frame_for(1, 0.0, "attack", .20) == 2 and FACING.frame_for(1, 0.0, "attack", .50) == 3 and FACING.frame_for(1, 0.0, "attack", .85) < 2, "Rival attack uses windup/contact only during its receipt beat, then returns to idle.")
	require(FACING.frame_for(0, 0.0, "attack", .20) == 6 and FACING.frame_for(0, 0.0, "attack", .50) == 7 and FACING.frame_for(0, 0.0, "attack", .85) < 6, "Friendly attack uses rear windup/contact only during its receipt beat, then returns to idle.")
	require(FACING.raw_frame_for(1) == 0 and FACING.raw_frame_for(0) == 4, "Each printer keeps its front/rear first-idle silhouette stable through all raw-print clipping receipts.")
	require(FACING.frame_for(-1, 0.0) == -1 and FACING.raw_frame_for(2) == -1, "Invalid seat values are rejected instead of silently becoming front-facing art.")
	for definition in Catalog.CREATURES:
		_validate_creature(definition as Dictionary)
	if failures.is_empty():
		print("PASS: M11 battle-facing atlas coverage and seat mapping")
	get_tree().quit(0 if failures.is_empty() else 1)

func _validate_creature(definition: Dictionary) -> void:
	var creature_id := str(definition.get("id", ""))
	var path := FACING.sprite_path_for(creature_id)
	var texture := FACING.texture_for_creature(creature_id)
	require(texture != null, "%s battle-facing sheet imports as a Texture2D." % creature_id)
	if texture == null:
		return
	require(texture.resource_path == path, "%s resolves only its own explicit battle-facing sheet." % creature_id)
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	require(image != null and not image.is_empty(), "%s battle-facing source PNG is readable." % creature_id)
	if image == null or image.is_empty():
		return
	require(image.get_size() == Vector2i(1536, 1024), "%s battle-facing sheet is the required 4x2 1536x1024 atlas." % creature_id)
	var signatures: Dictionary = {}
	for frame in 8:
		var region := FACING.safe_source_region(frame)
		require(region.size == Vector2(380, 508), "%s frame %d retains the fixed imported safe region." % [creature_id, frame])
		require(_cell_edges_are_clear(image, frame), "%s frame %d keeps transparent safe edges and does not bleed into a neighbor." % [creature_id, frame])
		var signature := _alpha_signature(image, frame)
		require(not signatures.has(signature), "%s frame %d has a distinct alpha silhouette/pose." % [creature_id, frame])
		signatures[signature] = frame
	require(signatures.size() == 8, "%s exposes eight distinct front/rear idle, windup, and contact cells." % creature_id)

func _cell_edges_are_clear(image: Image, frame: int) -> bool:
	var origin := Vector2i((frame % 4) * 384, (frame / 4) * 512)
	for x in range(origin.x, origin.x + 384):
		if image.get_pixel(x, origin.y).a > .04 or image.get_pixel(x, origin.y + 511).a > .04:
			return false
	for y in range(origin.y, origin.y + 512):
		if image.get_pixel(origin.x, y).a > .04 or image.get_pixel(origin.x + 383, y).a > .04:
			return false
	return true

func _alpha_signature(image: Image, frame: int) -> String:
	var origin := Vector2i((frame % 4) * 384, (frame / 4) * 512)
	var signature := ""
	for y in range(origin.y + 8, origin.y + 504, 8):
		for x in range(origin.x + 8, origin.x + 376, 8):
			signature += "1" if image.get_pixel(x, y).a > .04 else "0"
	return signature
