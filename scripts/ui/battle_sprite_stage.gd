class_name BattleSpriteStage
extends Control
## Finite code-native combat presentation. BattleRules remains authoritative.

const CELL := Vector2i(384, 512)
const ATLAS_GUTTER := CreatureSpriteCache.ATLAS_GUTTER
const MOVE_VFX := preload("res://scripts/ui/battle_move_vfx.gd")
var left_id := "cinderpaw"
var right_id := "mossmunk"
var event_kind := ""
var event_actor := 0
var event_token := 0
var reduced_motion := false
var high_contrast := false
var elapsed := 0.0
var _last_frame_signature := -1

func _ready() -> void:
	if custom_minimum_size.y <= 0.0: custom_minimum_size = Vector2(0, 250)
	_update_processing()
	queue_redraw()

func configure(player: Dictionary, rival: Dictionary, kind: String, actor: int, reduce: bool, contrast := false, token := 0) -> void:
	var changed := left_id != str(player.get("id", "cinderpaw")) or right_id != str(rival.get("id", "mossmunk")) or event_kind != kind or event_actor != actor or reduced_motion != reduce or high_contrast != contrast or event_token != token
	left_id = str(player.get("id", "cinderpaw"))
	right_id = str(rival.get("id", "mossmunk"))
	event_kind = kind
	event_actor = actor
	reduced_motion = reduce
	high_contrast = contrast
	if changed:
		event_token = token
		elapsed = 0.0
		_last_frame_signature = -1
	CreatureSpriteCache.texture_for_creature(left_id)
	CreatureSpriteCache.texture_for_creature(right_id)
	_update_processing()
	queue_redraw()

func _update_processing() -> void:
	set_process(not reduced_motion and is_event_active())

func is_event_active() -> bool:
	return not reduced_motion and MOVE_VFX.is_finite_event(event_kind) and elapsed < MOVE_VFX.event_duration(event_kind)

func presentation_progress() -> float:
	var duration := MOVE_VFX.event_duration(event_kind)
	return clampf(elapsed / duration, 0.0, 1.0) if duration > 0.0 else 0.0

func _process(delta: float) -> void:
	if not is_visible_in_tree() or not is_event_active():
		_update_processing()
		return
	advance_presentation(delta)

## Narrow deterministic seam for presentation tests and capture fixtures. This
## advances visuals only; BattleState has already accepted the action.
func advance_presentation(delta: float) -> void:
	if not is_event_active():
		_update_processing()
		return
	elapsed = minf(MOVE_VFX.event_duration(event_kind), elapsed + delta)
	var next_signature := _frame_signature()
	if next_signature != _last_frame_signature or not is_event_active():
		_last_frame_signature = next_signature
		queue_redraw()
	if not is_event_active(): set_process(false)

static func select_frame(kind: String, actor: int, is_left: bool, reduce: bool, seconds: float) -> int:
	if reduce or not MOVE_VFX.is_finite_event(kind) or seconds >= MOVE_VFX.event_duration(kind): return 0
	if kind in ["attack", "ability"]:
		if (is_left and actor == 0) or (not is_left and actor == 1):
			if seconds < 0.12: return 4
			if seconds < 0.30: return 5
			return 6
		return 7 if seconds < 0.30 else 0
	if kind == "switch" and ((is_left and actor == 0) or (not is_left and actor == 1)):
		return 4 if seconds < 0.20 else 6
	return 0

func _frame_for(is_left: bool) -> int:
	return select_frame(event_kind, event_actor, is_left, reduced_motion, elapsed)

func _frame_signature() -> int:
	return _frame_for(true) * 10 + _frame_for(false) + int(presentation_progress() * 100.0) * 100

static func sprite_path_for(creature_id: String) -> String:
	return CreatureSpriteCache.sprite_path_for(creature_id)

static func safe_source_region(_creature_id: String, frame: int) -> Rect2:
	return CreatureSpriteCache.safe_source_region(frame)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0b1728cc"), true)
	draw_line(Vector2(0, size.y - 26), Vector2(size.x, size.y - 26), Color("f1be69"), 2.0)
	var left_target := Rect2(18, 8, size.x * 0.43, size.y - 30)
	var right_target := Rect2(size.x * 0.55, 8, size.x * 0.43, size.y - 30)
	var offset := _lunge_offset()
	var left_offset := offset if event_actor == 0 else Vector2.ZERO
	var right_offset := offset if event_actor == 1 else Vector2.ZERO
	var left_destination := _draw_creature(left_id, Rect2(left_target.position + left_offset, left_target.size), _frame_for(true), false)
	var right_destination := _draw_creature(right_id, Rect2(right_target.position + right_offset, right_target.size), _frame_for(false), true)
	_draw_move_vfx(left_destination, right_destination)

func _lunge_offset() -> Vector2:
	if event_kind not in ["attack", "ability"] or not is_event_active(): return Vector2.ZERO
	var travel := sin(presentation_progress() * PI) * minf(22.0, size.x * 0.035)
	return Vector2(travel if event_actor == 0 else -travel, 0)

func _draw_creature(id: String, target: Rect2, frame: int, flip: bool) -> Rect2:
	var texture := CreatureSpriteCache.texture_for_creature(id)
	if texture == null: return Rect2()
	var source := safe_source_region(id, frame)
	var fit: float = minf(target.size.x / source.size.x, target.size.y / source.size.y)
	var fitted := source.size * fit
	var destination := Rect2(target.position + (target.size - fitted) * 0.5, fitted)
	if flip:
		draw_set_transform(Vector2(destination.position.x + destination.size.x, destination.position.y), 0.0, Vector2(-1, 1))
		draw_texture_rect_region(texture, Rect2(Vector2.ZERO, destination.size), source)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_texture_rect_region(texture, destination, source)
	return destination

func _draw_move_vfx(left: Rect2, right: Rect2) -> void:
	if not is_event_active(): return
	var actor_id := left_id if event_actor == 0 else right_id
	var profile: Dictionary = MOVE_VFX.profile_for(actor_id, event_kind)
	var color: Color = profile.get("color", Color("d7a7ff"))
	if high_contrast: color = Color.WHITE
	var actor_rect := left if event_actor == 0 else right
	var foe_rect := right if event_actor == 0 else left
	var origin := actor_rect.get_center()
	var target := foe_rect.get_center()
	var progress := presentation_progress()
	var elemental_atlas := MOVE_VFX.optional_element_atlas()
	var status_atlas := MOVE_VFX.optional_status_atlas()
	if event_kind in ["attack", "ability"]:
		var travel := clampf((progress - 0.10) / 0.55, 0.0, 1.0)
		var point := origin.lerp(target, travel)
		draw_line(origin, point, color.darkened(0.22), 3.0 if event_kind == "ability" else 2.0, true)
		draw_circle(point, 5.0 + 7.0 * travel, color)
		if event_kind == "ability" and elemental_atlas != null:
			var effect_size := clampf(minf(size.x, size.y) * 0.16, 56.0, 104.0)
			_draw_atlas_cell(elemental_atlas, MOVE_VFX.element_atlas_region(elemental_atlas, str(profile.get("element", "Arcane"))), Rect2(point - Vector2.ONE * effect_size * 0.5, Vector2.ONE * effect_size), color)
		if progress >= 0.58:
			var radius := 14.0 + 26.0 * (progress - 0.58) / 0.42
			draw_arc(target, radius, 0.0, TAU, 16, color, 2.0, true)
			_draw_impact_marks(target, color, str(profile.get("impact", "impact")))
		if event_kind == "ability": _draw_effect_accents(actor_rect, foe_rect, profile.get("accents", []), color, progress, status_atlas)
	elif event_kind == "defend":
		draw_arc(origin, minf(actor_rect.size.x, actor_rect.size.y) * (0.25 + progress * 0.10), 0.0, TAU, 18, color, 3.0, true)
	elif event_kind == "card":
		draw_circle(origin + Vector2(0, -actor_rect.size.y * 0.22), 10.0 + progress * 6.0, color, false, 2.0, true)
	elif event_kind == "switch":
		draw_line(origin + Vector2(-20, 0), origin + Vector2(20, 0), color, 3.0, true)

func _draw_impact_marks(point: Vector2, color: Color, impact: String) -> void:
	var spokes := 8 if impact in ["spark", "nova"] else 5
	for index in spokes:
		var angle := TAU * float(index) / float(spokes)
		draw_line(point + Vector2(cos(angle), sin(angle)) * 8.0, point + Vector2(cos(angle), sin(angle)) * 20.0, color, 2.0, true)

func _draw_effect_accents(actor_rect: Rect2, foe_rect: Rect2, accents: Array, color: Color, progress: float, status_atlas: Texture2D = null) -> void:
	for index in accents.size():
		var accent := str(accents[index])
		var own := accent in ["heal", "shield", "filament", "attack_buff", "cleanse", "switch_discount"]
		var center := (actor_rect if own else foe_rect).get_center() + Vector2(0, -18.0 - index * 8.0)
		if status_atlas != null:
			var accent_size := clampf(minf(size.x, size.y) * 0.10, 38.0, 64.0)
			_draw_atlas_cell(status_atlas, MOVE_VFX.status_atlas_region(status_atlas, accent), Rect2(center - Vector2.ONE * accent_size * 0.5, Vector2.ONE * accent_size), color)
		match accent:
			"heal", "cleanse": draw_arc(center, 13.0 + progress * 8.0, 0.0, TAU, 14, Color("8ce59a") if not high_contrast else Color.WHITE, 2.0, true)
			"shield": draw_arc(center, 18.0, 0.0, TAU, 12, color, 3.0, true)
			"filament", "attack_buff", "switch_discount": draw_line(center + Vector2(0, 10), center + Vector2(0, -12), color, 3.0, true)
			"debuff", "ability_lock":
				draw_line(center + Vector2(-10, -10), center + Vector2(10, 10), Color("ff9b9b") if not high_contrast else Color.WHITE, 3.0, true)
				draw_line(center + Vector2(10, -10), center + Vector2(-10, 10), Color("ff9b9b") if not high_contrast else Color.WHITE, 3.0, true)

func _draw_atlas_cell(texture: Texture2D, source: Rect2, destination: Rect2, tint: Color) -> void:
	if source.size.x <= 0.0 or source.size.y <= 0.0:
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_texture_rect_region(texture, destination, source, tint)
