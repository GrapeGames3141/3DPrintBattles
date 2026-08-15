class_name CreatureSpriteCache
extends RefCounted
## Process-wide immutable sprite assets. Recreated presentation controls share this
## cache so alpha analysis is never repeated for the same catalog sheet.

const CELL := Vector2i(384, 512)

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

static func alpha_bounds_for_path(path: String) -> Rect2:
	if _alpha_bounds.has(path): return _alpha_bounds[path] as Rect2
	texture_for_path(path)
	var image := _images.get(path) as Image
	if image == null or image.is_empty():
		var fallback := Rect2(Vector2.ZERO, Vector2(CELL))
		_alpha_bounds[path] = fallback
		_bounds_scans[path] = 1
		return fallback
	var min_x := CELL.x
	var min_y := CELL.y
	var max_x := -1
	var max_y := -1
	# Union all eight cells in local coordinates. The fixed union removes frame
	# scale jitter while only scanning each path once in this process.
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a <= 0.01: continue
			var local_x := x % CELL.x
			var local_y := y % CELL.y
			min_x = mini(min_x, local_x)
			min_y = mini(min_y, local_y)
			max_x = maxi(max_x, local_x)
			max_y = maxi(max_y, local_y)
	var result := Rect2(Vector2(min_x, min_y), Vector2(maxi(1, max_x - min_x + 1), maxi(1, max_y - min_y + 1))) if max_x >= min_x else Rect2(Vector2.ZERO, Vector2(CELL))
	_alpha_bounds[path] = result
	_bounds_scans[path] = int(_bounds_scans.get(path, 0)) + 1
	return result

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
