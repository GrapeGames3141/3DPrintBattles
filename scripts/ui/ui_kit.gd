class_name UI
extends RefCounted
## Shared look and helpers: colours, fonts, buttons, panels, textures, icons.

const INK := Color("0b1220")
const PANEL := Color("152038")
const PANEL_HI := Color("1f2d4d")
const BRASS := Color("d6a24a")
const BRASS_DARK := Color("7a5a24")
const CREAM := Color("f6ecd6")
const MUTED := Color("9fb0cc")
const CYAN := Color("4fd6ff")
const AMBER := Color("ffb347")
const GOOD := Color("6ee08a")
const BAD := Color("ff6464")
const GOLD := Color("ffd24a")

static var _tex: Dictionary = {}
static var _bold: FontFile
static var _theme: Theme


static func bold() -> FontFile:
	if _bold == null:
		_bold = load("res://assets/fonts/Arvo-Bold.ttf")
	return _bold


static func tex(path: String) -> Texture2D:
	if not _tex.has(path):
		_tex[path] = load(path) if ResourceLoader.exists(path) else null
	return _tex[path]


## One 384x512 cell of a creature sheet (4 columns x 2 rows). Single images
## (the Calibration Cube) are returned whole.
static func sprite(path: String, frame: int = 0) -> Texture2D:
	var t := tex(path)
	if t == null or t.get_width() < 1000:
		return t
	var key := "%s#%d" % [path, frame]
	if not _tex.has(key):
		var a := AtlasTexture.new()
		a.atlas = t
		var cw := t.get_width() / 4.0
		var ch := t.get_height() / 2.0
		a.region = Rect2((frame % 4) * cw, (frame / 4) * ch, cw, ch)
		_tex[key] = a
	return _tex[key]


## The UV rectangle of a sprite cell inside its sheet, for the print shader.
static func sprite_region(path: String, frame: int = 0) -> Vector4:
	var t := tex(path)
	if t == null or t.get_width() < 1000:
		return Vector4(0, 0, 1, 1)
	return Vector4((frame % 4) * 0.25, (frame / 4) * 0.5, 0.25, 0.5)


static func box(bg: Color, border := Color.TRANSPARENT, border_w := 0, radius := 10, shadow := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(radius)
	s.anti_aliasing_size = 1.0
	if shadow > 0:
		s.shadow_color = Color(0, 0, 0, 0.45)
		s.shadow_size = shadow
		s.shadow_offset = Vector2(0, shadow * 0.4)
	return s


static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font_size = 18
	t.set_color("font_color", "Label", CREAM)
	t.set_font("bold_font", "RichTextLabel", bold())
	t.set_color("default_color", "RichTextLabel", CREAM)
	var b := box(Color("2a3b63"), BRASS, 2, 10, 4)
	b.content_margin_left = 16
	b.content_margin_right = 16
	b.content_margin_top = 8
	b.content_margin_bottom = 8
	var h: StyleBoxFlat = b.duplicate()
	h.bg_color = Color("3a5290")
	h.border_color = GOLD
	var p: StyleBoxFlat = b.duplicate()
	p.bg_color = Color("1b2947")
	var d: StyleBoxFlat = b.duplicate()
	d.bg_color = Color("1a2236")
	d.border_color = Color("4a5568")
	t.set_stylebox("normal", "Button", b)
	t.set_stylebox("hover", "Button", h)
	t.set_stylebox("pressed", "Button", p)
	t.set_stylebox("disabled", "Button", d)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_font("font", "Button", bold())
	t.set_font_size("font_size", "Button", 20)
	t.set_color("font_color", "Button", CREAM)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", Color("6b7890"))
	t.set_stylebox("panel", "PanelContainer", box(Color(PANEL, 0.94), BRASS_DARK, 2, 14, 8))
	t.set_stylebox("panel", "Panel", box(Color(PANEL, 0.94), BRASS_DARK, 2, 14, 8))
	var le := box(Color("0d1526"), BRASS_DARK, 2, 8)
	le.content_margin_left = 10
	le.content_margin_right = 10
	le.content_margin_top = 6
	le.content_margin_bottom = 6
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", le)
	t.set_color("font_color", "LineEdit", CREAM)
	_theme = t
	return t


static func label(text: String, size: int = 18, color: Color = CREAM, use_bold := true, outline := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if use_bold:
		l.add_theme_font_override("font", bold())
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## kind: "primary" (brass), "go" (green), "danger" (red), "plain" (theme default)
static func button(text: String, kind := "plain", size := Vector2(0, 0), font_size := 20) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	b.size = size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font_size)
	var cols := {"primary": [Color("b07a1e"), Color("d99a2b"), GOLD], "go": [Color("1f8a4c"), Color("28ad60"), Color("a6f5c2")],
		"danger": [Color("8f2a2a"), Color("b83838"), Color("ffb0b0")]}
	if cols.has(kind):
		var c: Array = cols[kind]
		for state in ["normal", "hover", "pressed"]:
			var s := box(c[1] if state == "hover" else c[0], c[2], 2, 10, 4)
			if state == "pressed":
				s.bg_color = (c[0] as Color).darkened(0.25)
			s.content_margin_left = 16
			s.content_margin_right = 16
			s.content_margin_top = 8
			s.content_margin_bottom = 8
			b.add_theme_stylebox_override(state, s)
		b.add_theme_color_override("font_color", Color.WHITE)
	b.pressed.connect(func(): Audio.sfx("card"))
	return b


static func panel(parent: Node, rect: Rect2, style: StyleBox = null) -> Panel:
	var p := Panel.new()
	if style:
		p.add_theme_stylebox_override("panel", style)
	p.position = rect.position
	p.size = rect.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p


static func place(parent: Node, n: Control, pos: Vector2, size := Vector2(-1, -1)) -> Control:
	parent.add_child(n)
	n.position = pos
	if size.x >= 0:
		n.size = size
	return n


static func image(path: String, rect: Rect2, cover := false) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex(path)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if cover else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.position = rect.position
	t.size = rect.size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return t


## A floating text that drifts up and fades (damage numbers, toasts).
static func floater(parent: Node, text: String, pos: Vector2, color: Color, size := 34, rise := 46.0, time := 0.9) -> void:
	var l := label(text, size, color, true, 8)
	l.z_index = 60
	parent.add_child(l)
	l.reset_size()
	l.position = pos - l.size * 0.5
	l.pivot_offset = l.size * 0.5
	l.scale = Vector2(0.5, 0.5)
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "position:y", l.position.y - rise, time).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "modulate:a", 0.0, time * 0.4).set_delay(time * 0.6)
	tw.tween_callback(l.queue_free)


# ------------------------------------------------------------------- icons

static func _ngon(c: Vector2, r: float, n: int, rot := 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := rot + TAU * i / n
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


static func _star(c: Vector2, r_out: float, r_in: float, n: int, rot := -PI / 2.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n * 2:
		var a := rot + PI * i / n
		pts.append(c + Vector2(cos(a), sin(a)) * (r_out if i % 2 == 0 else r_in))
	return pts


static func _drop(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(c + Vector2(0, -r * 1.25))
	for i in 13:
		var a := -PI * 0.18 + (PI * 1.36) * i / 12.0
		pts.append(c + Vector2(cos(a), sin(a) * 0.95 + 0.22) * r * 0.82)
	return pts


## Draws a small vector icon centred on `c` with radius `r`.
static func draw_icon(ci: CanvasItem, kind: String, c: Vector2, r: float, col: Color) -> void:
	var dark := col.darkened(0.5)
	match kind:
		"coin":
			ci.draw_circle(c, r, col.darkened(0.35))
			ci.draw_circle(c, r * 0.84, col)
			ci.draw_colored_polygon(_ngon(c, r * 0.42, 6, PI / 6.0), col.darkened(0.4))
			ci.draw_arc(c, r * 0.66, -2.4, -1.0, 8, col.lightened(0.5), r * 0.12, true)
		"spool":
			ci.draw_circle(c, r, Color("1b2230"))
			ci.draw_circle(c, r * 0.8, col)
			ci.draw_arc(c, r * 0.62, 0, TAU, 24, col.darkened(0.25), r * 0.08, true)
			ci.draw_circle(c, r * 0.38, Color("1b2230"))
			ci.draw_circle(c, r * 0.16, Color("9aa6b8"))
		"shield":
			var pts := PackedVector2Array([c + Vector2(-r * 0.8, -r * 0.8), c + Vector2(r * 0.8, -r * 0.8), c + Vector2(r * 0.8, r * 0.1),
				c + Vector2(0, r), c + Vector2(-r * 0.8, r * 0.1)])
			ci.draw_colored_polygon(pts, dark)
			var inner := PackedVector2Array()
			for p in pts:
				inner.append(c + (p - c) * 0.74)
			ci.draw_colored_polygon(inner, col)
		"flame":
			ci.draw_colored_polygon(_drop(c + Vector2(0, r * 0.1), r), col)
			ci.draw_colored_polygon(_drop(c + Vector2(0, r * 0.42), r * 0.5), col.lightened(0.55))
		"drop":
			ci.draw_colored_polygon(_drop(c + Vector2(0, r * 0.1), r), col)
			ci.draw_arc(c + Vector2(0, r * 0.3), r * 0.48, 0.5, 2.0, 8, col.lightened(0.6), r * 0.14, true)
		"cube":
			var top := c + Vector2(0, -r)
			var mid := c
			var lft := c + Vector2(-r * 0.87, -r * 0.5)
			var rgt := c + Vector2(r * 0.87, -r * 0.5)
			var bl := c + Vector2(-r * 0.87, r * 0.5)
			var br := c + Vector2(r * 0.87, r * 0.5)
			var bot := c + Vector2(0, r)
			ci.draw_colored_polygon(PackedVector2Array([top, rgt, mid, lft]), col.lightened(0.3))
			ci.draw_colored_polygon(PackedVector2Array([lft, mid, bot, bl]), col)
			ci.draw_colored_polygon(PackedVector2Array([mid, rgt, br, bot]), col.darkened(0.3))
		"leaf":
			var pts := PackedVector2Array()
			for i in 17:
				var t := i / 16.0
				pts.append(c + Vector2(lerpf(-r, r, t), -sin(t * PI) * r * 0.62).rotated(-0.7))
			for i in 17:
				var t := 1.0 - i / 16.0
				pts.append(c + Vector2(lerpf(-r, r, t), sin(t * PI) * r * 0.62).rotated(-0.7))
			ci.draw_colored_polygon(pts, col)
			ci.draw_line(c + Vector2(-r, 0).rotated(-0.7), c + Vector2(r, 0).rotated(-0.7), dark, r * 0.12, true)
		"star":
			ci.draw_colored_polygon(_star(c, r, r * 0.45, 5), col)
		"burst":
			ci.draw_colored_polygon(_star(c, r, r * 0.68, 10), col)
		"hex":
			ci.draw_colored_polygon(_ngon(c, r, 6, PI / 6.0), col)
		"snow":
			for i in 3:
				var d := Vector2(cos(PI * i / 3.0), sin(PI * i / 3.0)) * r
				ci.draw_line(c - d, c + d, col, r * 0.2, true)
			ci.draw_circle(c, r * 0.24, col)
		"twin":
			for s in [-1.0, 1.0]:
				var o := c + Vector2(s * r * 0.48, 0)
				ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-r * 0.4, -r * 0.7), o + Vector2(r * 0.4, -r * 0.7), o + Vector2(0, r * 0.8)]), col)
		"lock":
			ci.draw_arc(c + Vector2(0, -r * 0.2), r * 0.45, PI, TAU, 12, col, r * 0.22, true)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.7, -r * 0.2), Vector2(r * 1.4, r * 1.1)), col)
		"check":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-r * 0.7, 0), c + Vector2(-r * 0.2, r * 0.55), c + Vector2(r * 0.8, -r * 0.6)]), col, r * 0.3, true)
		"pack":
			ci.draw_rect(Rect2(c - Vector2(r * 0.7, r), Vector2(r * 1.4, r * 2.0)), col)
			ci.draw_rect(Rect2(c - Vector2(r * 0.7, r * 0.2), Vector2(r * 1.4, r * 0.4)), col.lightened(0.5))
		_:
			ci.draw_circle(c, r, col)
