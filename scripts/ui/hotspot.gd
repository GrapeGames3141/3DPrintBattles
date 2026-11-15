class_name Hotspot
extends Control
## An object in a painted scene that you can tap: the printer, the monitor, the
## stage. It is shaped like the object (a polygon), lights up under the pointer
## or a finger, and has a small plaque that names it.

signal activated

## The outline, in the parent's coordinates.
var outline := PackedVector2Array()
var accent := UI.GOLD
## True makes the object breathe a soft glow, to say "something is waiting here".
var attention := false

var _local := PackedVector2Array()
var _hover := false
var _down := false
var _t := 0.0
var _plaque: PanelContainer
var _desc: Label
var _anchor := Vector2.ZERO
var _badge: PanelContainer
var _phase := 0.0
var _shimmer_was := false
const GLINT_EVERY := 6.0
const GLINT_TIME := 1.8


## `points` outline the object; `label_at` is where the plaque's middle sits.
static func make(points: PackedVector2Array, label_at: Vector2, title: String, subs: Array, desc: String, color := UI.GOLD) -> Hotspot:
	var h := Hotspot.new()
	h.outline = points
	h.accent = color
	var lo := points[0]
	var hi := points[0]
	for p in points:
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.y))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.y))
	h.position = lo
	h.size = hi - lo
	for p in points:
		h._local.append(p - lo)
	h.mouse_filter = Control.MOUSE_FILTER_STOP
	h.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	h.focus_mode = Control.FOCUS_NONE
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	h.material = add
	h._anchor = label_at - lo
	h._build_plaque(title, subs, desc)
	# Hidden until the pointer is on the object, so the picture stays clear.
	h._plaque.visible = false
	h._phase = float(absi(hash(title)) % 1000) / 1000.0 * GLINT_EVERY
	return h


## A small count on the object (packs waiting), the only thing that stays on show.
func set_badge(text: String) -> void:
	if _badge != null:
		_badge.queue_free()
		_badge = null
	if text == "":
		return
	_badge = PanelContainer.new()
	_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge.material = CanvasItemMaterial.new()
	var st := UI.box(Color(0.05, 0.07, 0.12, 0.92), UI.GOLD, 3, 16, 5)
	st.content_margin_left = 11
	st.content_margin_right = 11
	st.content_margin_top = 1
	st.content_margin_bottom = 3
	_badge.add_theme_stylebox_override("panel", st)
	var l := UI.label(text, 22, UI.GOLD, true, 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge.add_child(l)
	_badge.z_index = 2
	add_child(_badge)
	_badge.resized.connect(func(): _badge.position = _anchor - _badge.size * 0.5)
	_badge.position = _anchor - _badge.size * 0.5


func _build_plaque(title: String, subs: Array, desc: String) -> void:
	# The plaque is a child, so it is drawn with the hotspot; an additive material
	# would wash it out, so it gets its own plain one.
	_plaque = PanelContainer.new()
	_plaque.material = CanvasItemMaterial.new()
	_plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plaque.add_theme_stylebox_override("panel", _plaque_style(false))
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 0)
	_plaque.add_child(box)
	var name_l := UI.label(title, 24, UI.CREAM, true, 5)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_l)
	for s in subs:
		var sl := UI.label(str(s[0]), 15, s[1] if s.size() > 1 else UI.MUTED, false, 3)
		sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(sl)
	_desc = UI.label(desc, 15, UI.AMBER, false, 3)
	_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc.visible = false
	box.add_child(_desc)
	_plaque.resized.connect(_place_plaque)
	_plaque.z_index = 2
	add_child(_plaque)
	_place_plaque()


func _plaque_style(lit: bool) -> StyleBoxFlat:
	var s := UI.box(Color(0.03, 0.05, 0.1, 0.9 if lit else 0.78), accent if lit else UI.BRASS, 3 if lit else 2, 12, 6)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 4
	s.content_margin_bottom = 6
	return s


func _place_plaque() -> void:
	if _plaque != null:
		_plaque.position = _anchor - _plaque.size * 0.5 + Vector2(0, -3 if _hover else 0)


func _has_point(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, _local)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			_set_hover(true)
		NOTIFICATION_MOUSE_EXIT:
			_set_hover(false)
			_down = false
			queue_redraw()


func _set_hover(on: bool) -> void:
	_hover = on
	_desc.visible = on
	_plaque.visible = on or _down
	_plaque.add_theme_stylebox_override("panel", _plaque_style(on))
	_plaque.reset_size()
	_place_plaque()
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_down = true
			_hover = true
			_plaque.visible = true
			queue_redraw()
			accept_event()
		elif _down:
			_down = false
			var inside := _has_point(event.position)
			# A finger leaves no "pointer exit" behind when it lifts, so the
			# label has to go now: either the touch ended off the object, or it
			# is a touch (which has no hover) at all.
			if not inside or event.device == InputEvent.DEVICE_ID_EMULATION:
				_set_hover(false)
			_plaque.visible = _hover
			queue_redraw()
			accept_event()
			if inside:
				Audio.sfx("click")
				activated.emit()


func _process(delta: float) -> void:
	_t += delta
	# Every few seconds a faint glint runs over each object, so a finger knows
	# what can be tapped without a label in the way.
	if _hover or _down or attention or _shimmer() > 0.0 or _shimmer_was:
		_shimmer_was = _shimmer() > 0.0
		queue_redraw()


## 0..1 while this object's gentle brightening is running, else -1. Every few
## seconds each object lights up softly, on its own beat, so a finger can see
## what is there to tap without a label in the way.
func _glint() -> float:
	var ph := fmod(_t + _phase, GLINT_EVERY)
	return ph / GLINT_TIME if ph < GLINT_TIME else -1.0


func _shimmer() -> float:
	var g := _glint()
	return sin(PI * g) if g >= 0.0 else 0.0


## A soft round light, brightest in the middle, shared by every hotspot.
static var _light_tex: Texture2D


static func _light() -> Texture2D:
	if _light_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.add_point(0.55, Color(1, 1, 1, 0.45))
		g.set_color(2, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 128
		t.height = 128
		_light_tex = t
	return _light_tex


## The object itself lights up: a soft warm light over it (drawn additively, so
## it brightens what is painted there) with no frame or edge. It glows when
## touched, and every few seconds it brightens gently on its own beat.
func _draw() -> void:
	var glow := 0.0
	if _down:
		glow = 1.0
	elif _hover:
		glow = 0.75 + 0.1 * sin(_t * 5.0)
	elif attention:
		glow = 0.35 + 0.2 * sin(_t * 2.6)
	glow = maxf(glow, _shimmer() * 0.35)
	if glow <= 0.0:
		return
	var gold := UI.GOLD
	var area := Rect2(Vector2.ZERO, size).grow_individual(size.x * 0.12, size.y * 0.12, size.x * 0.12, size.y * 0.12)
	draw_texture_rect(_light(), area, false, Color(gold.r, gold.g, gold.b, 0.5 * glow))
	if not (_hover or _down) and _glint() >= 0.0:
		_draw_sweep(_glint())


## The shimmer: a soft diagonal band of light that sweeps once across the
## object, brightest down its middle and fading out at its sides and ends, so
## it reads as light catching the object, not as a shape.
func _draw_sweep(g: float) -> void:
	var c := size * 0.5
	var half := size * 0.6
	var lean := Vector2(0.42, 1.0).normalized()          # the band's direction: steep, leaning right
	var across := Vector2(lean.y, -lean.x)               # perpendicular to it
	var reach := half.length()
	var mid := c + across * lerpf(-reach * 1.1, reach * 1.1, g)
	var width := maxf(size.x, size.y) * 0.13
	var steps := 8
	var warm := Color(1.0, 0.93, 0.7)
	var fade := func(p: Vector2) -> float:
		var d := (p - c) / half
		return clampf(1.0 - d.length(), 0.0, 1.0)
	for i in steps:
		var t0 := float(i) / steps
		var t1 := float(i + 1) / steps
		var a := mid + lean * lerpf(-reach, reach, t0)
		var b := mid + lean * lerpf(-reach, reach, t1)
		for side in [-1.0, 1.0]:
			var a2: Vector2 = a + across * width * side
			var b2: Vector2 = b + across * width * side
			var pts := PackedVector2Array([a, b, b2, a2])
			var k := 0.55 * sin(PI * g)
			var cols := PackedColorArray([
				Color(warm, k * fade.call(a)), Color(warm, k * fade.call(b)),
				Color(warm, 0.0), Color(warm, 0.0)])
			draw_polygon(pts, cols)
