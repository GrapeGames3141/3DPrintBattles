class_name BattleFacingSpriteCache
extends RefCounted
## Battle-only front/rear living-print atlas contract.  Archive, Forge, and all
## other callers continue to use CreatureSpriteCache's original side-view art.

const CELL := Vector2i(384, 512)
const ATLAS_GUTTER := 2
const IDLE_FPS := 2.0
const FACING_DIRECTORY := "res://assets/creatures/2d/battle-facing"
const FACING_SUFFIX := "_battle_facing_4x2.png"
const VOLTWIG_ID := "voltwig"
const VOLTWIG_FACING_PATH := FACING_DIRECTORY + "/voltwig_battle_facing_2x1.png"
const DIRECTIONAL_ATLAS_SIZE := Vector2i(1536, 1024)
const VOLTWIG_ATLAS_SIZE := Vector2i(768, 512)
const INVALID_SOURCE_REGION := Rect2(Vector2.ZERO, Vector2.ONE)

static var _textures: Dictionary = {}
static var _texture_loads: Dictionary = {}
static var _reported_missing: Dictionary = {}
static var _catalog_ids: Dictionary = {}

static func sprite_path_for(creature_id: String) -> String:
	if creature_id == VOLTWIG_ID:
		return VOLTWIG_FACING_PATH
	return "%s/%s%s" % [FACING_DIRECTORY, creature_id, FACING_SUFFIX]

static func texture_for_creature(creature_id: String) -> Texture2D:
	if not _is_catalog_creature(creature_id):
		_report_missing(creature_id, "<invalid creature id>")
		return null
	var path := sprite_path_for(creature_id)
	if _textures.has(path):
		return _textures[path] as Texture2D
	if not ResourceLoader.exists(path):
		_report_missing(creature_id, path)
		_textures[path] = null
		return null
	var texture := ResourceLoader.load(path) as Texture2D
	if texture == null:
		_report_missing(creature_id, path)
		_textures[path] = null
		return null
	var expected_size := atlas_size_for_creature(creature_id)
	if texture.get_size() != Vector2(expected_size):
		_report_missing(creature_id, "%s (expected %s, got %s)" % [path, expected_size, texture.get_size()])
		_textures[path] = null
		return null
	_textures[path] = texture
	_texture_loads[path] = int(_texture_loads.get(path, 0)) + 1
	return texture

static func uses_legacy_art(creature_id: String) -> bool:
	# Compatibility query retained for callers migrating from the interim release.
	# Voltwig is now genuine directional-neutral battle art, never a legacy sheet.
	return false

static func has_directional_coverage(creature_id: String) -> bool:
	return _is_catalog_creature(creature_id) and ResourceLoader.exists(sprite_path_for(creature_id))

static func has_interim_coverage(creature_id: String) -> bool:
	if not _is_catalog_creature(creature_id):
		return false
	return ResourceLoader.exists(sprite_path_for(creature_id))

static func coverage_kind_for(creature_id: String) -> String:
	if not has_interim_coverage(creature_id):
		return "missing"
	return "directional_neutral" if creature_id == VOLTWIG_ID else "directional"

static func safe_source_region(frame: int) -> Rect2:
	# The original 4x2 API remains explicit directional geometry only. Species-aware
	# callers must use safe_source_region_for_creature.
	var normalized := clampi(frame, 0, 7)
	var origin := Vector2((normalized % 4) * CELL.x, (normalized / 4) * CELL.y)
	return Rect2(origin + Vector2.ONE * ATLAS_GUTTER, Vector2(CELL) - Vector2.ONE * ATLAS_GUTTER * 2.0)

static func atlas_size_for_creature(creature_id: String) -> Vector2i:
	if not _is_catalog_creature(creature_id):
		return Vector2i.ZERO
	return VOLTWIG_ATLAS_SIZE if creature_id == VOLTWIG_ID else DIRECTIONAL_ATLAS_SIZE

static func frame_count_for_creature(creature_id: String) -> int:
	if not _is_catalog_creature(creature_id):
		return 0
	return 2 if creature_id == VOLTWIG_ID else 8

static func is_valid_frame_for_creature(creature_id: String, frame: int) -> bool:
	return frame >= 0 and frame < frame_count_for_creature(creature_id)

static func safe_source_region_for_creature(creature_id: String, frame: int) -> Rect2:
	if not is_valid_frame_for_creature(creature_id, frame):
		# AtlasTexture interprets Rect2() as its full atlas. A one-pixel corner is
		# safe because every valid atlas has the two-pixel transparent gutter.
		return INVALID_SOURCE_REGION
	var origin := Vector2(frame * CELL.x, 0) if creature_id == VOLTWIG_ID else Vector2((frame % 4) * CELL.x, (frame / 4) * CELL.y)
	return Rect2(origin + Vector2.ONE * ATLAS_GUTTER, Vector2(CELL) - Vector2.ONE * ATLAS_GUTTER * 2.0)

static func frame_for(seat: int, idle_elapsed: float, beat_kind: String = "", beat_progress := 1.0) -> int:
	# Rival seat 1 uses the upper/front row; friendly seat 0 uses the lower/rear
	# row.  Never use the old action-loop frames while a unit is simply idle.
	if seat != 0 and seat != 1:
		return -1
	var row := 4 if seat == 0 else 0
	if beat_kind == "attack":
		if beat_progress < .42:
			return row + 2 # windup
		if beat_progress < .72:
			return row + 3 # contact
	# Recovery returns to the finite unit's normal breathing cadence.
	return row + int(floor(idle_elapsed * IDLE_FPS)) % 2

static func frame_for_creature(creature_id: String, seat: int, idle_elapsed: float, beat_kind: String = "", beat_progress := 1.0) -> int:
	if not _is_catalog_creature(creature_id) or seat != 0 and seat != 1:
		return -1
	if creature_id == VOLTWIG_ID:
		# Genuine neutral cells are front for rival (0) and rear for friendly (1).
		# Finite beats retain this authored direction rather than inventing poses.
		return 1 if seat == 0 else 0
	return frame_for(seat, idle_elapsed, beat_kind, beat_progress)

static func raw_frame_for(seat: int) -> int:
	# Printing geometry stays on the first idle pose until awakening; individual
	# print receipts may change progress clipping but must never morph the body.
	if seat != 0 and seat != 1:
		return -1
	return 4 if seat == 0 else 0

static func raw_frame_for_creature(creature_id: String, seat: int) -> int:
	if not _is_catalog_creature(creature_id) or seat != 0 and seat != 1:
		return -1
	if creature_id == VOLTWIG_ID:
		return 1 if seat == 0 else 0
	return raw_frame_for(seat)

static func release_coverage_errors() -> Array[String]:
	var errors: Array[String] = []
	for definition in Catalog.CREATURES:
		var creature_id := str((definition as Dictionary).get("id", ""))
		var path := sprite_path_for(creature_id)
		if creature_id.is_empty() or not has_directional_coverage(creature_id):
			errors.append("Missing required directional battle art for %s: %s" % [creature_id, path])
	return errors

static func debug_stats() -> Dictionary:
	return {"texture_loads":_texture_loads.duplicate(true), "reported_missing":_reported_missing.duplicate(true)}

static func clear_for_test() -> void:
	_textures.clear()
	_texture_loads.clear()
	_reported_missing.clear()
	_catalog_ids.clear()

static func _report_missing(creature_id: String, path: String) -> void:
	if _reported_missing.has(path):
		return
	_reported_missing[path] = creature_id
	push_error("Battle-facing art is unavailable for %s (%s). No side-view fallback is permitted on the battlefield." % [creature_id, path])

static func _is_catalog_creature(creature_id: String) -> bool:
	if creature_id.is_empty():
		return false
	if _catalog_ids.is_empty():
		for definition in Catalog.CREATURES:
			var catalog_id := str((definition as Dictionary).get("id", ""))
			if not catalog_id.is_empty():
				_catalog_ids[catalog_id] = true
	return _catalog_ids.has(creature_id)
