class_name BattleFacingSpriteCache
extends RefCounted
## Battle-only front/rear living-print atlas contract.  Archive, Forge, and all
## other callers continue to use CreatureSpriteCache's original side-view art.

const CELL := Vector2i(384, 512)
const ATLAS_GUTTER := 2
const IDLE_FPS := 2.0
const FACING_DIRECTORY := "res://assets/creatures/2d/battle-facing"
const FACING_SUFFIX := "_battle_facing_4x2.png"

static var _textures: Dictionary = {}
static var _texture_loads: Dictionary = {}
static var _reported_missing: Dictionary = {}

static func sprite_path_for(creature_id: String) -> String:
	return "%s/%s%s" % [FACING_DIRECTORY, creature_id, FACING_SUFFIX]

static func texture_for_creature(creature_id: String) -> Texture2D:
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
	_textures[path] = texture
	_texture_loads[path] = int(_texture_loads.get(path, 0)) + 1
	return texture

static func safe_source_region(frame: int) -> Rect2:
	var normalized := clampi(frame, 0, 7)
	var origin := Vector2((normalized % 4) * CELL.x, (normalized / 4) * CELL.y)
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

static func raw_frame_for(seat: int) -> int:
	# Printing geometry stays on the first idle pose until awakening; individual
	# print receipts may change progress clipping but must never morph the body.
	if seat != 0 and seat != 1:
		return -1
	return 4 if seat == 0 else 0

static func release_coverage_errors() -> Array[String]:
	var errors: Array[String] = []
	for definition in Catalog.CREATURES:
		var creature_id := str((definition as Dictionary).get("id", ""))
		var path := sprite_path_for(creature_id)
		if creature_id.is_empty() or not ResourceLoader.exists(path):
			errors.append("Missing required battle-facing sheet for %s: %s" % [creature_id, path])
	return errors

static func debug_stats() -> Dictionary:
	return {"texture_loads":_texture_loads.duplicate(true), "reported_missing":_reported_missing.duplicate(true)}

static func clear_for_test() -> void:
	_textures.clear()
	_texture_loads.clear()
	_reported_missing.clear()

static func _report_missing(creature_id: String, path: String) -> void:
	if _reported_missing.has(path):
		return
	_reported_missing[path] = creature_id
	push_error("Battle-facing art is unavailable for %s (%s). Legacy side-view art is intentionally not used on the battlefield." % [creature_id, path])
