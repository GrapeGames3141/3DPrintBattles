class_name FilamentGauge
extends Control
## A player's Filament, the way a printer has it: how much the nozzle can
## still lay down this turn (the lit spools and the big number), and how much
## is left on the Spool for the rest of the battle (the bar).

var flow := 0
var speed := 0
var spool := 0
var spool_max := 1
var compact := false
var _number: Label
var _title: Label
var _spool_text: Label
var _flash := 0.0


static func make(gauge_size: Vector2, caption: String, is_compact: bool = false) -> FilamentGauge:
	var g := FilamentGauge.new()
	g.size = gauge_size
	g.compact = is_compact
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g._title = UI.label(caption, 12 if is_compact else 15, UI.CYAN, true, 3)
	g._title.position = Vector2(12, 5 if is_compact else 8)
	g._title.size = Vector2(gauge_size.x - 24, 20)
	g.add_child(g._title)
	g._number = UI.label("0 / 0", 22 if is_compact else 40, Color.WHITE, true, 6)
	g._number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	g._number.position = Vector2(12, 0 if is_compact else 2)
	g._number.size = Vector2(gauge_size.x - 24, 30 if is_compact else 52)
	g.add_child(g._number)
	g._spool_text = UI.label("", 13 if is_compact else 17, Color.WHITE, true, 4)
	g._spool_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	g.add_child(g._spool_text)
	return g


func set_value(new_flow: int, new_speed: int, new_spool: int, new_spool_max: int) -> void:
	var flow_changed := new_flow != flow or new_speed != speed
	var spool_changed := new_spool != spool
	flow = new_flow
	speed = new_speed
	spool = new_spool
	spool_max = maxi(new_spool_max, 1)
	_number.text = "%d / %d" % [flow, speed]
	_number.add_theme_color_override("font_color", Color.WHITE if flow > 0 else Color("8aa0bd"))
	_spool_text.text = "SPOOL  %d" % spool
	_spool_text.add_theme_color_override("font_color", _spool_color().lerp(Color.WHITE, 0.75))
	var bar := _bar_rect()
	_spool_text.position = bar.position + Vector2(bar.size.y + 8.0, -1.0)
	_spool_text.size = Vector2(bar.size.x - bar.size.y - 8.0, bar.size.y)
	if is_inside_tree():
		if flow_changed:
			_pop(_number, Vector2(_number.size.x, _number.size.y * 0.5))
		if spool_changed:
			_pop(_spool_text, Vector2(0, _spool_text.size.y * 0.5))
	queue_redraw()


func _pop(label: Label, pivot: Vector2) -> void:
	label.pivot_offset = pivot
	var tw := label.create_tween()
	tw.tween_property(label, "scale", Vector2(1.25, 1.25), 0.08)
	tw.tween_property(label, "scale", Vector2.ONE, 0.14)


## Flashes red: "you cannot print that right now".
func deny() -> void:
	var tw := create_tween()
	tw.tween_method(func(v: float):
		_flash = v
		queue_redraw(), 1.0, 0.0, 0.6)


func _spool_color() -> Color:
	var left := float(spool) / float(spool_max)
	if left <= 0.12:
		return UI.BAD
	if left <= 0.3:
		return UI.AMBER
	return UI.CYAN


## Where the lit spools go, and where the Spool bar goes.
func _pip_rect() -> Rect2:
	if compact:
		return Rect2(10, 32, size.x * 0.42, size.y - 42)
	return Rect2(12, 58, size.x - 24, (size.y - 58) * 0.5 - 6.0) if size.x < 300.0 else Rect2(12, 34, size.x * 0.5 - 18, size.y - 46)


func _bar_rect() -> Rect2:
	if compact:
		var x := 10.0 + size.x * 0.42 + 8.0
		return Rect2(x, size.y - 38.0, size.x - x - 10.0, 26.0)
	if size.x < 300.0:
		return Rect2(12, size.y - 44.0, size.x - 24, 32.0)
	return Rect2(size.x * 0.5 + 4.0, size.y - 46.0, size.x * 0.5 - 16.0, 34.0)


func _draw() -> void:
	var border := UI.CYAN.lerp(UI.BAD, _flash)
	draw_style_box(UI.box(Color(0.03, 0.06, 0.12, 0.92).lerp(Color(0.35, 0.05, 0.05, 0.95), _flash * 0.7), border, 3 if not compact else 2, 14, 6), Rect2(Vector2.ZERO, size))

	# One spool per Filament the nozzle can lay down this turn.
	var area := _pip_rect()
	var n := maxi(maxi(speed, flow), 1)
	var gap := 5.0
	var r := minf((area.size.x - gap * (n - 1)) / (n * 2.0), area.size.y * 0.5)
	r = minf(r, 20.0 if not compact else 13.0)
	for i in n:
		var pos := Vector2(area.position.x + r + i * (r * 2.0 + gap), area.position.y + area.size.y * 0.5)
		if i < flow:
			UI.draw_icon(self, "spool", pos, r, UI.CYAN if i < speed else UI.GOLD)
		else:
			UI.draw_icon(self, "spool", pos, r, Color("1f3550"))
			draw_arc(pos, r * 0.8, 0, TAU, 20, Color(0.3, 0.5, 0.7, 0.5), 1.5, true)

	# The Spool: everything left for the rest of the battle.
	var bar := _bar_rect()
	var col := _spool_color()
	var radius := int(bar.size.y * 0.5)
	draw_style_box(UI.box(Color("0a1322"), col.darkened(0.45), 2, radius), bar)
	var left := clampf(float(spool) / float(spool_max), 0.0, 1.0)
	if left > 0.0:
		var fill := Rect2(bar.position + Vector2(3, 3), Vector2(maxf((bar.size.x - 6.0) * left, bar.size.y - 6.0), bar.size.y - 6.0))
		draw_style_box(UI.box(col.darkened(0.35), Color.TRANSPARENT, 0, radius - 3), fill)
	UI.draw_icon(self, "spool", bar.position + Vector2(bar.size.y * 0.5, bar.size.y * 0.5), bar.size.y * 0.5 - 2.0, col)
