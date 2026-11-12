class_name BoardUnit
extends Control
## A print standing on the battlefield: the creature figure on a small bed
## plate, with its Attack and Health and markers for its keywords.

const SIZE := Vector2(140, 172)
const PLATE := Vector2(70, 142)

var u: Dictionary = {}
var def: Dictionary = {}
var mirrored := false
var can_act := false
var targeted := false
var target_color := UI.BAD

var _sprite: TextureRect
var _mat: ShaderMaterial
var _base: Control
var _fx: Control
var _atk: Badge
var _hp: Badge
var _gear: Control
var _path := ""
var _phase := 0.0
var _busy_anim := false


static func make(unit: Dictionary, is_mirrored: bool) -> BoardUnit:
	var b := BoardUnit.new()
	b.size = SIZE
	b.pivot_offset = PLATE
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	b.mirrored = is_mirrored
	b.def = GameData.card(unit["id"])
	b._path = GameData.art_path(b.def)
	b._phase = randf() * TAU
	b._build()
	b.refresh(unit, false)
	return b


func _build() -> void:
	_base = Control.new()
	_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_base.draw.connect(_draw_base)
	add_child(_base)

	_sprite = TextureRect.new()
	_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sprite.position = Vector2(6, -12)
	_sprite.size = Vector2(128, 166)
	_sprite.pivot_offset = Vector2(64, 150)
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://assets/shaders/print_reveal.gdshader")
	_mat.set_shader_parameter("filament", GameData.element_color(def.get("element", "Neutral")))
	_mat.set_shader_parameter("flip", 1.0 if mirrored else 0.0)
	_sprite.material = _mat
	add_child(_sprite)
	set_frame(0)

	_fx = Control.new()
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx.draw.connect(_draw_fx)
	add_child(_fx)

	_gear = Control.new()
	_gear.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_gear)

	_atk = Badge.make("burst", CardView.ATK_AMBER, 44)
	_atk.position = Vector2(-4, 126)
	add_child(_atk)
	_hp = Badge.make("hex", CardView.HP_RED, 44)
	_hp.position = Vector2(100, 126)
	add_child(_hp)


func _process(delta: float) -> void:
	if _busy_anim:
		return
	_phase += delta * 2.2
	_sprite.scale = Vector2(1.0 + sin(_phase) * 0.012, 1.0 - sin(_phase) * 0.018)


func set_frame(frame: int) -> void:
	_sprite.texture = UI.sprite(_path, frame)
	var r := UI.sprite_region(_path, frame)
	_mat.set_shader_parameter("region", r)


## Takes the latest unit data from the rules engine and redraws.
func refresh(unit: Dictionary, attack_ready: bool) -> void:
	u = unit.duplicate(true)
	can_act = attack_ready
	_atk.set_value(int(u["atk"]), UI.GOOD if int(u["atk"]) > int(def["atk"]) else Color.WHITE)
	var hp := int(u["hp"])
	var hp_col := Color.WHITE
	if hp < int(u["max_hp"]):
		hp_col = Color("ffb0b0")
	elif int(u["max_hp"]) > int(def["hp"]):
		hp_col = UI.GOOD
	_hp.set_value(maxi(hp, 0), hp_col)
	_mat.set_shader_parameter("frost", 1.0 if int(u["jam"]) > 0 else 0.0)
	for ch in _gear.get_children():
		ch.queue_free()
	var gear: Array = u.get("gear", [])
	for i in mini(gear.size(), 3):
		var t := UI.image(GameData.ARMOR_ART % gear[i], Rect2(104, -2 + i * 28, 34, 34))
		_gear.add_child(t)
	_base.queue_redraw()
	_fx.queue_redraw()


func set_targeted(on: bool, color := UI.BAD) -> void:
	if targeted == on and target_color == color:
		return
	targeted = on
	target_color = color
	_base.queue_redraw()


func set_ready(on: bool) -> void:
	if can_act != on:
		can_act = on
		_base.queue_redraw()


## Middle of the figure in the parent's coordinates (the node scales around
## its plate, so the offset shrinks with it).
func center() -> Vector2:
	return position + PLATE + (Vector2(70, 80) - PLATE) * scale


## The area that counts as "on this print" for taps and drops.
func hit_rect() -> Rect2:
	return Rect2(position + PLATE + (Vector2(4, 0) - PLATE) * scale, Vector2(132, 168) * scale)


## Where the top printed layer is, for print progress 0..1 (parent coords).
func layer_point(v: float) -> Vector2:
	return position + PLATE + (Vector2(70, -12.0 + 166.0 * (1.0 - v)) - PLATE) * scale


## Bare: just the figure, no plate or numbers (while it is on the Printer).
func set_bare(on: bool) -> void:
	for n in [_base, _fx, _atk, _hp, _gear]:
		(n as Control).visible = not on


func begin_print() -> void:
	_busy_anim = true
	_sprite.scale = Vector2.ONE
	_mat.set_shader_parameter("progress", 0.0)
	_mat.set_shader_parameter("colorize", 0.0)


func set_print_progress(v: float) -> void:
	_mat.set_shader_parameter("progress", v)


func set_print_color(v: float) -> void:
	_mat.set_shader_parameter("colorize", v)


func end_print() -> void:
	_mat.set_shader_parameter("progress", 1.0)
	_mat.set_shader_parameter("colorize", 1.0)
	_busy_anim = false


func _ellipse(ci: Control, c: Vector2, rx: float, ry: float, col: Color) -> void:
	ci.draw_set_transform(c, 0.0, Vector2(1.0, ry / rx))
	ci.draw_circle(Vector2.ZERO, rx, col)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _ring(ci: Control, c: Vector2, rx: float, ry: float, col: Color, w: float) -> void:
	ci.draw_set_transform(c, 0.0, Vector2(1.0, ry / rx))
	ci.draw_arc(Vector2.ZERO, rx, 0, TAU, 48, col, w, true)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_base() -> void:
	var kw: Array = u.get("kw", [])
	var tint := GameData.element_color(def.get("element", "Neutral"))
	_ellipse(_base, PLATE + Vector2(0, 6), 66, 22, Color(0, 0, 0, 0.45))
	if targeted:
		_ellipse(_base, PLATE, 74, 27, Color(target_color, 0.9))
	elif can_act:
		_ellipse(_base, PLATE, 72, 26, Color(UI.GOOD, 0.95))
	_ellipse(_base, PLATE, 62, 20, Color("101826"))
	_ring(_base, PLATE, 58, 18.5, tint.darkened(0.15), 5.0)
	if kw.has("guard"):
		_ring(_base, PLATE, 66, 22.5, Color("dfe6f0"), 5.0)


func _draw_fx() -> void:
	var kw: Array = u.get("kw", [])
	if kw.has("brim"):
		_ellipse(_fx, Vector2(70, 76), 66, 80, Color(1.0, 0.86, 0.35, 0.13))
		_ring(_fx, Vector2(70, 76), 66, 80, Color(1.0, 0.9, 0.5, 0.75), 2.5)
	# Keyword markers sit between the two stat badges.
	var marks: Array = []
	if kw.has("guard"):
		marks.append(["shield", Color("dfe6f0")])
	if kw.has("siphon"):
		marks.append(["drop", UI.GOOD])
	if kw.has("twin"):
		marks.append(["twin", UI.AMBER])
	if int(u.get("jam", 0)) > 0:
		marks.append(["snow", UI.CYAN])
	var x := 70.0 - (marks.size() - 1) * 10.0
	for m in marks:
		_fx.draw_circle(Vector2(x, 156), 10.5, Color("0b1220"))
		UI.draw_icon(_fx, m[0], Vector2(x, 156), 7.5, m[1])
		x += 20.0


# ------------------------------------------------------------- animations

func flash() -> void:
	var tw := create_tween()
	tw.tween_method(func(v: float): _mat.set_shader_parameter("flash", v), 0.9, 0.0, 0.25)
	if _sprite.texture is AtlasTexture:
		set_frame(7)
		tw.tween_callback(set_frame.bind(0))
	var home := _sprite.position
	var sh := create_tween()
	for i in 4:
		sh.tween_property(_sprite, "position", home + Vector2(randf_range(-7, 7), randf_range(-4, 4)), 0.035)
	sh.tween_property(_sprite, "position", home, 0.04)


func pulse(color: Color) -> void:
	var base := scale
	var tw := create_tween()
	tw.tween_property(self, "scale", base * 1.16, 0.1)
	tw.tween_property(self, "scale", base, 0.16)
	var m := create_tween()
	m.tween_property(self, "modulate", color.lerp(Color.WHITE, 0.4) * 1.3, 0.1)
	m.tween_property(self, "modulate", Color.WHITE, 0.2)


## Breaks into plastic shards.
func shatter() -> void:
	_busy_anim = true
	var p := CPUParticles2D.new()
	p.position = Vector2(70, 90)
	p.amount = 26
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.55
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.gravity = Vector2(0, 620)
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 300.0
	p.angular_velocity_min = -500.0
	p.angular_velocity_max = 500.0
	p.scale_amount_min = 5.0
	p.scale_amount_max = 11.0
	p.color = GameData.element_color(def.get("element", "Neutral"))
	p.emitting = true
	add_child(p)
	_atk.visible = false
	_hp.visible = false
	_gear.visible = false
	_fx.visible = false
	var tw := create_tween()
	tw.tween_method(func(v: float): _mat.set_shader_parameter("flash", v), 0.0, 1.0, 0.08)
	tw.tween_property(_sprite, "modulate:a", 0.0, 0.12)
	tw.parallel().tween_property(_sprite, "scale", Vector2(1.25, 0.7), 0.12)
	tw.tween_property(_base, "modulate:a", 0.0, 0.3)
	await tw.finished
