class_name BattleFacingSpriteCache
extends RefCounted
## Battle-only front/rear living-print atlas contract.  Archive, Forge, and all
## other callers continue to use CreatureSpriteCache's original side-view art.

const CELL := Vector2i(384, 512)
const ATLAS_GUTTER := 2
const IDLE_FPS := 2.0
const FACING_DIRECTORY := "res://assets/creatures/2d/battle-facing"
const FACING_SUFFIX := "_battle_facing_4x2.png"
const LEGACY_VOLTWIG_ID := "voltwig"
const LEGACY_VOLTWIG_PATH := "res://assets/creatures/2d/voltwig_sprite_sheet.png"

static var _textures: Dictionary = {}
static var _texture_loads: Dictionary = {}
static var _reported_missing: Dictionary = {}
static var _catalog_ids: Dictionary = {}

static func sprite_path_for(creature_id: String) -> String:
	if uses_legacy_art(creature_id):
		return LEGACY_VOLTWIG_PATH
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
	_textures[path] = texture
	_texture_loads[path] = int(_texture_loads.get(path, 0)) + 1
	return texture

static func uses_legacy_art(creature_id: String) -> bool:
	# The approved interim exception is intentionally exact and battle-local.
	# No CreatureSpriteCache fallback is consulted for any other missing species.
	return creature_id == LEGACY_VOLTWIG_ID

static func has_directional_coverage(creature_id: String) -> bool:
	return _is_catalog_creature(creature_id) and not uses_legacy_art(creature_id) and ResourceLoader.exists(sprite_path_for(creature_id))

static func has_interim_coverage(creature_id: String) -> bool:
	if not _is_catalog_creature(creature_id):
		return false
	return ResourceLoader.exists(sprite_path_for(creature_id))

static func coverage_kind_for(creature_id: String) -> String:
	if not has_interim_coverage(creature_id):
		return "missing"
	return "legacy_voltwig" if uses_legacy_art(creature_id) else "directional"

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

static func frame_for_creature(creature_id: String, seat: int, idle_elapsed: float, beat_kind: String = "", beat_progress := 1.0) -> int:
	if not _is_catalog_creature(creature_id) or seat != 0 and seat != 1:
		return -1
	if uses_legacy_art(creature_id):
		return _legacy_voltwig_frame(idle_elapsed, beat_kind, beat_progress)
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
	# Legacy Voltwig is not classified as a front/rear row. Both seats use its
	# neutral legacy idle pose during raw clipping.
	return 0 if uses_legacy_art(creature_id) else raw_frame_for(seat)

static func release_coverage_errors() -> Array[String]:
	var errors: Array[String] = []
	for definition in Catalog.CREATURES:
		var creature_id := str((definition as Dictionary).get("id", ""))
		var path := sprite_path_for(creature_id)
		if creature_id.is_empty() or not has_interim_coverage(creature_id):
			errors.append("Missing required interim battle art for %s: %s" % [creature_id, path])
		elif uses_legacy_art(creature_id) and path != LEGACY_VOLTWIG_PATH:
			errors.append("Voltwig legacy exception must resolve only %s, got %s" % [LEGACY_VOLTWIG_PATH, path])
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
	push_error("Battle-facing art is unavailable for %s (%s). Legacy side-view art is intentionally not used on the battlefield except the explicit Voltwig mapping." % [creature_id, path])

static func _is_catalog_creature(creature_id: String) -> bool:
	if creature_id.is_empty():
		return false
	if _catalog_ids.is_empty():
		for definition in Catalog.CREATURES:
			var catalog_id := str((definition as Dictionary).get("id", ""))
			if not catalog_id.is_empty():
				_catalog_ids[catalog_id] = true
	return _catalog_ids.has(creature_id)

static func _legacy_voltwig_frame(idle_elapsed: float, beat_kind: String, beat_progress: float) -> int:
	# Legacy Voltwig preserves its original sheet semantics: idle frames 0..3,
	# action frames 4..7 only while the finite attack beat is active. These are
	# never described as the reviewed directional front/rear rows.
	if beat_kind == "attack":
		if beat_progress < .21:
			return 4
		if beat_progress < .42:
			return 5
		if beat_progress < .63:
			return 6
		if beat_progress < .84:
			return 7
	return int(floor(idle_elapsed * IDLE_FPS)) % 4
