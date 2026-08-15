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
var _last_frame_signature := -1

func _ready() -> void:
	# Callers may supply a compact battle HUD height before the node enters the
	# tree. Preserve that explicit request; the large presentation default is
	# only for callers that do not size the stage.
	if custom_minimum_size.y <= 0.0:
		custom_minimum_size = Vector2(0, 250)
	set_process(not reduced_motion)
	queue_redraw()

func configure(player: Dictionary, rival: Dictionary, kind: String, actor: int, reduce: bool) -> void:
	left_id = str(player.get("id", "cinderpaw"))
	right_id = str(rival.get("id", "mossmunk"))
	event_kind = kind
	event_actor = actor
	reduced_motion = reduce
	elapsed = 0.0
	_last_frame_signature = -1
	CreatureSpriteCache.texture_for_creature(left_id)
	CreatureSpriteCache.texture_for_creature(right_id)
	set_process(not reduced_motion)
	queue_redraw()

func _process(delta: float) -> void:
	if reduced_motion or not is_visible_in_tree(): return
	elapsed += delta
	var next_signature := _frame_signature()
	if next_signature != _last_frame_signature:
		_last_frame_signature = next_signature
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

func _frame_signature() -> int:
	return _frame_for(true) * 10 + _frame_for(false)

## Catalog drives visual lookup; a definition without a sheet gets the safe mascot fallback.
static func sprite_path_for(creature_id: String) -> String:
	return CreatureSpriteCache.sprite_path_for(creature_id)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0b1728cc"), true)
	draw_line(Vector2(0, size.y - 26), Vector2(size.x, size.y - 26), Color("f1be69"), 2.0)
	_draw_creature(left_id, Rect2(18, 8, size.x * 0.43, size.y - 30), _frame_for(true), false)
	_draw_creature(right_id, Rect2(size.x * 0.55, 8, size.x * 0.43, size.y - 30), _frame_for(false), true)

func _draw_creature(id: String, target: Rect2, frame: int, flip: bool) -> void:
	var texture := CreatureSpriteCache.texture_for_creature(id)
	if texture == null: return
	var crop := CreatureSpriteCache.alpha_bounds_for_path(sprite_path_for(id))
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
