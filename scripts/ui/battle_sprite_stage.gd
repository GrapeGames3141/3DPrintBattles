class_name BattleSpriteStage
extends Control
## Code-native presentation only: combat remains entirely in BattleRules.

const CELL := Vector2i(384, 512)
var left_id := "cinderpaw"
var right_id := "mossmunk"
var event_kind := ""
var event_actor := 0
var reduced_motion := false
var elapsed := 0.0
var texture_cache: Dictionary = {}
var image_cache: Dictionary = {}
var alpha_bounds_cache: Dictionary = {}

func _ready() -> void:
	custom_minimum_size = Vector2(0, 250)
	queue_redraw()

func configure(player: Dictionary, rival: Dictionary, kind: String, actor: int, reduce: bool) -> void:
	left_id = str(player.get("id", "cinderpaw"))
	right_id = str(rival.get("id", "mossmunk"))
	event_kind = kind
	event_actor = actor
	reduced_motion = reduce
	elapsed = 0.0
	_texture_for(left_id)
	_texture_for(right_id)
	queue_redraw()

func _process(delta: float) -> void:
	if reduced_motion: return
	elapsed += delta
	queue_redraw()

static func select_frame(kind: String, actor: int, is_left: bool, reduce: bool, seconds: float) -> int:
	if reduce: return 0
	if kind in ["attack", "ability"] and seconds < 0.45:
		if (is_left and actor == 0) or (not is_left and actor == 1):
			if seconds < 0.12: return 4
			if seconds < 0.27: return 5
			return 6
		return 7 if seconds < 0.27 else 0
	return int(floor(seconds * 5.0)) % 4

func _frame_for(is_left: bool) -> int:
	return select_frame(event_kind, event_actor, is_left, reduced_motion, elapsed)

## Catalog drives visual lookup; a definition without a sheet gets the safe mascot fallback.
static func sprite_path_for(creature_id: String) -> String:
	var definition := Catalog.creature(creature_id)
	var path := str(definition.get("sprite_sheet", ""))
	if not path.is_empty() and ResourceLoader.exists(path): return path
	return str(Catalog.creature("mossmunk").get("sprite_sheet", ""))

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0b1728cc"), true)
	draw_line(Vector2(0, size.y - 26), Vector2(size.x, size.y - 26), Color("f1be69"), 2.0)
	_draw_creature(left_id, Rect2(18, 8, size.x * 0.43, size.y - 30), _frame_for(true), false)
	_draw_creature(right_id, Rect2(size.x * 0.55, 8, size.x * 0.43, size.y - 30), _frame_for(false), true)

func _draw_creature(id: String, target: Rect2, frame: int, flip: bool) -> void:
	var texture := _texture_for(id)
	if texture == null: return
	var crop := _alpha_bounds_for(sprite_path_for(id))
	var source := Rect2(Vector2((frame % 4) * CELL.x, (frame / 4) * CELL.y) + crop.position, crop.size)
	var fit: float = minf(target.size.x / crop.size.x, target.size.y / crop.size.y)
	var fitted := crop.size * fit
	var destination := Rect2(target.position + (target.size - fitted) * 0.5, fitted)
	if flip:
		draw_set_transform(Vector2(destination.position.x + destination.size.x, destination.position.y), 0.0, Vector2(-1, 1))
		draw_texture_rect_region(texture, Rect2(Vector2.ZERO, destination.size), source)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_texture_rect_region(texture, destination, source)

func _texture_for(creature_id: String) -> Texture2D:
	var path := sprite_path_for(creature_id)
	if texture_cache.has(path): return texture_cache[path] as Texture2D
	# The source PNG route preserves alpha during fresh editor/headless capture. Exported
	# PCKs may not expose raw files, so use the imported resource as a safe fallback.
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	var texture: Texture2D
	if image != null and not image.is_empty():
		texture = ImageTexture.create_from_image(image)
	else:
		texture = ResourceLoader.load(path) as Texture2D
		if texture != null: image = texture.get_image()
	if texture == null: return null
	if image != null and not image.is_empty(): image_cache[path] = image
	texture_cache[path] = texture
	return texture

func _alpha_bounds_for(path: String) -> Rect2:
	if alpha_bounds_cache.has(path): return alpha_bounds_cache[path] as Rect2
	if not image_cache.has(path): _texture_for(left_id if sprite_path_for(left_id) == path else right_id)
	var image := image_cache.get(path) as Image
	if image == null: return Rect2(Vector2.ZERO, Vector2(CELL))
	var min_x := CELL.x
	var min_y := CELL.y
	var max_x := -1
	var max_y := -1
	# Union all eight cells in local coordinates. That gives every frame the same crop
	# and eliminates scale jitter while using the actual transparent artwork bounds.
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a <= 0.01: continue
			var local_x := x % CELL.x
			var local_y := y % CELL.y
			min_x = mini(min_x, local_x); min_y = mini(min_y, local_y)
			max_x = maxi(max_x, local_x); max_y = maxi(max_y, local_y)
	var bounds := Rect2(Vector2(min_x, min_y), Vector2(maxi(1, max_x - min_x + 1), maxi(1, max_y - min_y + 1))) if max_x >= min_x else Rect2(Vector2.ZERO, Vector2(CELL))
	alpha_bounds_cache[path] = bounds
	return bounds
