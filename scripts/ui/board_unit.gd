class_name BoardUnit
extends Control
## A print standing on the battlefield: the creature figure on a small bed
## plate, with its Attack and Health and markers for its keywords.

const SIZE := Vector2(140, 172)
const PLATE := Vector2(70, 142)
const HALO := 76.0

var u: Dictionary = {}
var def: Dictionary = {}
var mirrored := false
var can_act := false
## What this print can do right now (only set for your own prints on your turn):
## "ready" can attack, "fresh" was just printed, "spent" has attacked, "jam" is jammed.
var status := ""
var targeted := false
var target_color := UI.BAD
## Picked up to attack with: a gold ring, so no arrow is needed on touch.
var selected := false

var _sprite: TextureRect
var _mat: ShaderMaterial
var _base: Control
var _fx: Control
var _atk: Badge
var _hp: Badge
var _gear: Control
var _ambient: CPUParticles2D
var _heat_fx: CPUParticles2D
var _loot_fx: CPUParticles2D
var _loot_el := ""
var paint_id := "original"
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
	b.paint_id = str(unit.get("paint", "original"))
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
	var fil := GameData.element_color(def.get("element", "Neutral"))
	var paint := GameData.paint(paint_id)
	fil = Color.from_hsv(fposmod(fil.h + float(paint["hue"]) / 360.0, 1.0), clampf(fil.s * float(paint["sat"]), 0.0, 1.0), clampf(fil.v * float(paint["val"]), 0.0, 1.0))
	_mat.set_shader_parameter("filament", fil)
	UI.paint_params(_mat, paint_id)
	_mat.set_shader_parameter("flip", 1.0 if mirrored else 0.0)
	_sprite.material = _mat
	add_child(_sprite)
	set_frame(0)

	_ambient = _make_ambient(str(def.get("element", "Neutral")))
	if _ambient != null:
		add_child(_ambient)

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
	_apply_heat_and_loot()
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


func set_status(s: String) -> void:
	if status == s:
		return
	status = s
	can_act = s == "ready"
	_apply_heat_and_loot()
	_base.queue_redraw()
	_fx.queue_redraw()


func set_selected(on: bool) -> void:
	if selected != on:
		selected = on
		_base.queue_redraw()


## Greyed out: it cannot be attacked while a Guard print stands in the way.
func set_blocked(on: bool) -> void:
	modulate = Color(0.5, 0.52, 0.58, 0.9) if on else Color.WHITE


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
	if _ambient != null:
		_ambient.visible = not on
		_ambient.emitting = not on


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
	# One halo size for every highlight, so they all look alike.
	if selected:
		_ellipse(_base, PLATE, HALO, HALO * 0.365, Color(UI.GOLD, 0.95))
	elif targeted:
		_ellipse(_base, PLATE, HALO, HALO * 0.365, Color(target_color, 0.9))
	elif status == "ready":
		_ellipse(_base, PLATE, HALO, HALO * 0.365, Color(UI.GOOD, 0.95))
	_ellipse(_base, PLATE, 62, 20, Color("101826"))
	_ring(_base, PLATE, 58, 18.5, tint.darkened(0.15), 5.0)
	if kw.has("guard"):
		_ring(_base, PLATE, 66, 22.5, Color("dfe6f0"), 6.0)
	if int(u.get("heat", 0)) > 0:
		_ring(_base, PLATE, 70, 24.5, Color(1.0, 0.45, 0.12, 0.85), 4.0)
	if int(u.get("loot", 0)) > 0:
		_ring(_base, PLATE, 54, 16.5, Color(GameData.element_color(str(u.get("loot_el", "Neutral"))), 0.9), 3.0)


func _draw_fx() -> void:
	var kw: Array = u.get("kw", [])
	if kw.has("brim"):
		_ellipse(_fx, Vector2(70, 76), 66, 80, Color(1.0, 0.86, 0.35, 0.13))
		_ring(_fx, Vector2(70, 76), 66, 80, Color(1.0, 0.9, 0.5, 0.75), 2.5)
	# Guard is the one keyword that changes what the other player may do, so
	# it gets a big shield standing in front of the print and a name tag.
	if kw.has("guard"):
		var at := Vector2(70, 110)
		var outline := PackedVector2Array([at + Vector2(-25, -25), at + Vector2(25, -25), at + Vector2(25, 4), at + Vector2(0, 30), at + Vector2(-25, 4)])
		_fx.draw_colored_polygon(outline, Color("0b1220"))
		UI.draw_icon(_fx, "shield", at, 21.0, Color("dfe6f0"))
		var font := UI.bold()
		var wide := font.get_string_size("GUARD", HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		_fx.draw_string_outline(font, Vector2(70.0 - wide * 0.5, 113.0), "GUARD", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color("dfe6f0"))
		_fx.draw_string(font, Vector2(70.0 - wide * 0.5, 113.0), "GUARD", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("0b1220"))
	_draw_status_tag()
	# Other keyword markers sit between the two stat badges.
	var marks: Array = []
	if kw.has("siphon"):
		marks.append(["drop", UI.GOOD])
	if kw.has("twin"):
		marks.append(["twin", UI.AMBER])
	if int(u.get("jam", 0)) > 0:
		marks.append(["snow", UI.CYAN])
	if int(u.get("heat", 0)) > 0:
		marks.append(["flame", Color("ff7a2e")])
	if int(u.get("loot", 0)) > 0:
		marks.append(["spool", GameData.element_color(str(u.get("loot_el", "Neutral")))])
	var x := 70.0 - (marks.size() - 1) * 10.0
	for m in marks:
		_fx.draw_circle(Vector2(x, 156), 10.5, Color("0b1220"))
		UI.draw_icon(_fx, m[0], Vector2(x, 156), 7.5, m[1])
		x += 20.0


## A small tag over the print saying whether it can attack: READY, COOLING
## (printed this turn) or DONE (already attacked).
func _draw_status_tag() -> void:
	var tags := {"ready": ["READY", UI.GOOD, Color("06210f")], "fresh": ["COOLING", Color("8fb4e8"), Color("0a1a33")],
		"spent": ["DONE", Color("8a93a3"), Color("141a24")], "jam": ["JAMMED", UI.CYAN, Color("06242b")]}
	if not tags.has(status):
		return
	var t: Array = tags[status]
	var font := UI.bold()
	var w := font.get_string_size(t[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 16.0
	var r := Rect2(70.0 - w * 0.5, 0.0, w, 20.0)
	_fx.draw_style_box(UI.box(t[1], Color("0b1220"), 2, 10), r)
	_fx.draw_string(font, Vector2(r.position.x + 8.0, 15.0), t[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, t[2])


# --------------------------------------------------------------- ambience

## A heated print glows and smoulders. A thief wears its victims' colours: its
## paint shifts toward the filament it took and it sheds that element's
## particles.
func _apply_heat_and_loot() -> void:
	var heated := int(u.get("heat", 0)) > 0
	var tint := Color(1.0, 0.8, 0.66) if heated else Color.WHITE
	if status == "spent":
		tint *= Color(0.6, 0.62, 0.7)
	elif status == "fresh":
		tint *= Color(0.8, 0.86, 1.0)
	_sprite.modulate = tint
	if heated and _heat_fx == null:
		_heat_fx = _make_ambient("Fire")
		if _heat_fx != null:
			add_child(_heat_fx)
			move_child(_heat_fx, _sprite.get_index() + 1)
	if _heat_fx != null:
		_heat_fx.visible = heated
		_heat_fx.emitting = heated
	var loot := int(u.get("loot", 0))
	var el := str(u.get("loot_el", ""))
	var paint := GameData.paint(paint_id)
	var hue := float(paint["hue"]) / 360.0
	var sat := float(paint["sat"])
	var val := float(paint["val"])
	if loot > 0 and el != "":
		var theirs := GameData.element_color(el).h
		var mine := GameData.element_color(str(def.get("element", "Neutral"))).h
		var delta := fposmod(theirs - mine + 0.5, 1.0) - 0.5
		hue += delta * 0.4 * minf(float(loot), 3.0) / 3.0
		sat *= 1.0 + 0.06 * minf(float(loot), 3.0)
		val *= 1.0 + 0.04 * minf(float(loot), 3.0)
	_mat.set_shader_parameter("hue_shift", hue)
	_mat.set_shader_parameter("sat_mul", sat)
	_mat.set_shader_parameter("val_mul", val)
	if loot > 0 and el != _loot_el:
		_loot_el = el
		if _loot_fx != null:
			_loot_fx.queue_free()
		_loot_fx = _make_ambient(el)
		if _loot_fx != null:
			add_child(_loot_fx)
			move_child(_loot_fx, _sprite.get_index() + 1)

static var _dot_tex: Texture2D


## A soft round dot, shared by every ambient particle.
static func _dot() -> Texture2D:
	if _dot_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 32
		t.height = 32
		_dot_tex = t
	return _dot_tex


## A few slow particles that say what the print is made of: embers rise off
## Fire, snow settles on Ice, sparks jitter on Lightning. Quiet on purpose.
func _make_ambient(element: String) -> CPUParticles2D:
	# amount, lifetime, area (half-size of the spawn box), centre, direction, spread, speed, gravity, size, colors
	var cfg := {
		"Fire": [9, 1.7, Vector2(34, 6), Vector2(70, 122), Vector2(0, -1), 22.0, Vector2(16, 36), Vector2(0, -14), Vector2(2.5, 5.0), Color("ffc23a"), Color("ff4a12")],
		"Water": [6, 2.3, Vector2(36, 8), Vector2(70, 126), Vector2(0, -1), 14.0, Vector2(10, 22), Vector2(0, -6), Vector2(3.0, 6.5), Color("a8dcff"), Color("2f8fff")],
		"Lightning": [5, 0.55, Vector2(34, 44), Vector2(70, 84), Vector2(0, -1), 180.0, Vector2(16, 46), Vector2.ZERO, Vector2(1.8, 3.4), Color("fff27a"), Color("ffc400")],
		"Nature": [6, 2.8, Vector2(36, 30), Vector2(70, 70), Vector2(0.4, 1), 40.0, Vector2(6, 16), Vector2(0, 8), Vector2(3.0, 5.0), Color("a6e84a"), Color("2fae3f")],
		"Ice": [10, 2.6, Vector2(44, 4), Vector2(70, 20), Vector2(0, 1), 18.0, Vector2(8, 18), Vector2(0, 10), Vector2(1.8, 3.4), Color("d4f6ff"), Color("5fcfff")],
		"Stone": [5, 1.9, Vector2(40, 4), Vector2(70, 134), Vector2(0, -1), 40.0, Vector2(8, 20), Vector2(0, -2), Vector2(2.4, 4.4), Color("d9bf94"), Color("8f7248")],
		"Wind": [5, 1.9, Vector2(20, 40), Vector2(36, 84), Vector2(1, -0.15), 14.0, Vector2(34, 58), Vector2.ZERO, Vector2(3.0, 6.0), Color("d8fff0"), Color("6fdcb0")],
		"Arcane": [6, 1.9, Vector2(36, 40), Vector2(70, 90), Vector2(0, -1), 180.0, Vector2(6, 16), Vector2.ZERO, Vector2(2.2, 4.6), Color("f0b4ff"), Color("9a50ff")],
	}
	if not cfg.has(element):
		return null
	var c: Array = cfg[element]
	var p := CPUParticles2D.new()
	p.texture = _dot()
	p.amount = int(c[0])
	p.lifetime = float(c[1])
	p.preprocess = float(c[1])
	p.local_coords = true
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = c[2]
	p.position = c[3]
	p.direction = c[4]
	p.spread = float(c[5])
	p.initial_velocity_min = float((c[6] as Vector2).x)
	p.initial_velocity_max = float((c[6] as Vector2).y)
	p.gravity = c[7]
	# Sizes are in pixels across; the dot texture is 32 px.
	p.scale_amount_min = float((c[8] as Vector2).x) / 9.0
	p.scale_amount_max = float((c[8] as Vector2).y) / 9.0
	var ramp := Gradient.new()
	ramp.set_color(0, c[9])
	ramp.add_point(0.35, c[10])
	ramp.set_color(2, Color(c[10].r, c[10].g, c[10].b, 0.0))
	p.color_ramp = ramp
	p.emitting = true
	return p


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
	if _ambient != null:
		_ambient.emitting = false
	var tw := create_tween()
	tw.tween_method(func(v: float): _mat.set_shader_parameter("flash", v), 0.0, 1.0, 0.08)
	tw.tween_property(_sprite, "modulate:a", 0.0, 0.12)
	tw.parallel().tween_property(_sprite, "scale", Vector2(1.25, 0.7), 0.12)
	tw.tween_property(_base, "modulate:a", 0.0, 0.3)
	await tw.finished
