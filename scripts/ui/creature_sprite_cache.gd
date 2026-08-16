class_name CreatureSpriteCache
extends RefCounted
## Process-wide immutable sprite assets. Atlas edge repair is an offline asset
## step; runtime only reuses imported textures and a fixed safe source region.

const CELL := Vector2i(384, 512)
const ATLAS_GUTTER := 2

static var _textures: Dictionary = {}
static var _images: Dictionary = {}
static var _alpha_bounds: Dictionary = {}
static var _texture_loads: Dictionary = {}
static var _bounds_scans: Dictionary = {}

static func texture_for_path(path: String) -> Texture2D:
	if path.is_empty(): return null
	if _textures.has(path): return _textures[path] as Texture2D
	# PCK exports retain imported Texture2D resources while raw source paths may
	# not exist. Prefer that route everywhere, then use Image only as a local
	# editor/headless fallback when an import is unavailable or unreadable.
	var texture := ResourceLoader.load(path) as Texture2D
	var image: Image
	if texture != null:
		image = texture.get_image()
	if image == null or image.is_empty():
		var source := Image.load_from_file(ProjectSettings.globalize_path(path))
		if source != null and not source.is_empty():
			image = source
			if texture == null:
				texture = ImageTexture.create_from_image(source)
	if texture == null: return null
	_textures[path] = texture
	_texture_loads[path] = int(_texture_loads.get(path, 0)) + 1
	if image != null and not image.is_empty(): _images[path] = image
	return texture

static func texture_for_creature(creature_id: String) -> Texture2D:
	return texture_for_path(sprite_path_for(creature_id))

static func sprite_path_for(creature_id: String) -> String:
	var definition: Dictionary = Catalog.creature(creature_id)
	var path := str(definition.get("sprite_sheet", ""))
	if not path.is_empty() and ResourceLoader.exists(path): return path
	return str(Catalog.creature("mossmunk").get("sprite_sheet", ""))

static func safe_source_region(frame: int) -> Rect2:
	var normalized := posmod(frame, 8)
	var origin := Vector2((normalized % 4) * CELL.x, (normalized / 4) * CELL.y)
	return Rect2(origin + Vector2.ONE * ATLAS_GUTTER, Vector2(CELL) - Vector2.ONE * ATLAS_GUTTER * 2.0)

## Compatibility seam for existing Forge/checkpoint callers. This is now a
## fixed, scan-free source contract because assets are repaired offline.
static func alpha_bounds_for_path(path: String) -> Rect2:
	if _alpha_bounds.has(path): return _alpha_bounds[path] as Rect2
	var bounds := Rect2(Vector2.ONE * ATLAS_GUTTER, Vector2(CELL) - Vector2.ONE * ATLAS_GUTTER * 2.0)
	_alpha_bounds[path] = bounds
	_bounds_scans[path] = int(_bounds_scans.get(path, 0)) + 1
	return bounds

static func debug_stats() -> Dictionary:
	return {"texture_loads":_texture_loads.duplicate(true), "bounds_scans":_bounds_scans.duplicate(true)}

static func texture_load_count(path: String) -> int:
	return int(_texture_loads.get(path, 0))

static func alpha_bounds_scan_count(path: String) -> int:
	return int(_bounds_scans.get(path, 0))

static func clear_for_test() -> void:
	_textures.clear()
	_images.clear()
	_alpha_bounds.clear()
	_texture_loads.clear()
	_bounds_scans.clear()
