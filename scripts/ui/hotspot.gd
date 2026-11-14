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


## 0..1 while this object's glint is running, else -1. Every few seconds a
## gold light runs once around the object, each on its own beat, so a finger
## can see what is there to tap without a label in the way.
func _glint() -> float:
	var ph := fmod(_t + _phase, GLINT_EVERY)
	return ph / GLINT_TIME if ph < GLINT_TIME else -1.0


func _shimmer() -> float:
	var g := _glint()
	return sin(PI * g) if g >= 0.0 else 0.0


func _draw() -> void:
	var glow := 0.0
	var col := accent
	if _down:
		glow = 1.0
	elif _hover:
		glow = 0.7 + 0.15 * sin(_t * 5.0)
	elif attention:
		glow = 0.25 + 0.2 * sin(_t * 2.6)
	var ring := _local.duplicate()
	ring.append(_local[0])
	if glow > 0.0:
		draw_colored_polygon(_local, Color(col.r, col.g, col.b, 0.13 * glow))
		draw_polyline(ring, Color(col.r, col.g, col.b, 0.22 * glow), 9.0, true)
		draw_polyline(ring, Color(col.r, col.g, col.b, 0.85 * glow), 3.0, true)
	if _hover or _down:
		return
	var g := _glint()
	if g < 0.0:
		return
	# The glint: a soft gold outline that swells and fades, with a bright
	# spark of light running once around it.
	var gold := UI.GOLD
	var swell := sin(PI * g)
	draw_colored_polygon(_local, Color(gold.r, gold.g, gold.b, 0.07 * swell))
	draw_polyline(ring, Color(gold.r, gold.g, gold.b, 0.18 * swell), 8.0, true)
	draw_polyline(ring, Color(gold.r, gold.g, gold.b, 0.45 * swell), 2.5, true)
	var total := 0.0
	for i in ring.size() - 1:
		total += ring[i].distance_to(ring[i + 1])
	var head := g * total
	var tail := head - total * 0.22
	var run := PackedVector2Array()
	var walked := 0.0
	for i in ring.size() - 1:
		var a := ring[i]
		var b := ring[i + 1]
		var seg := a.distance_to(b)
		var s0 := clampf((tail - walked) / maxf(seg, 0.001), 0.0, 1.0)
		var s1 := clampf((head - walked) / maxf(seg, 0.001), 0.0, 1.0)
		if s1 > s0:
			if run.is_empty():
				run.append(a.lerp(b, s0))
			run.append(a.lerp(b, s1))
		walked += seg
	if run.size() >= 2:
		draw_polyline(run, Color(gold.r, gold.g, gold.b, 0.35 * swell), 10.0, true)
		draw_polyline(run, Color(1.0, 0.96, 0.75, 0.95 * swell), 3.5, true)
