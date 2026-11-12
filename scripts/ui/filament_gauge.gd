class_name FilamentGauge
extends Control
## The player's Filament: a labelled panel with a big "have / total" number
## and ten spools that light up as Filament is gained and dim as it is spent.

var fil := 0
var cap := 0
var title := "FILAMENT"
var compact := false
var _number: Label
var _title: Label
var _flash := 0.0


static func make(gauge_size: Vector2, caption: String, is_compact: bool = false) -> FilamentGauge:
	var g := FilamentGauge.new()
	g.size = gauge_size
	g.title = caption
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
	return g


func set_value(new_fil: int, new_cap: int) -> void:
	var changed := new_fil != fil or new_cap != cap
	fil = new_fil
	cap = new_cap
	_number.text = "%d / %d" % [fil, cap]
	_number.add_theme_color_override("font_color", Color.WHITE if fil > 0 else Color("8aa0bd"))
	if changed and is_inside_tree():
		_number.pivot_offset = Vector2(_number.size.x, _number.size.y * 0.5)
		var tw := create_tween()
		tw.tween_property(_number, "scale", Vector2(1.25, 1.25), 0.08)
		tw.tween_property(_number, "scale", Vector2.ONE, 0.14)
	queue_redraw()


## Flashes red: "you cannot afford that".
func deny() -> void:
	var tw := create_tween()
	tw.tween_method(func(v: float):
		_flash = v
		queue_redraw(), 1.0, 0.0, 0.6)


func _draw() -> void:
	var border := UI.CYAN.lerp(UI.BAD, _flash)
	draw_style_box(UI.box(Color(0.03, 0.06, 0.12, 0.92).lerp(Color(0.35, 0.05, 0.05, 0.95), _flash * 0.7), border, 3 if not compact else 2, 14, 6), Rect2(Vector2.ZERO, size))
	# Ten spools: one row when there is room, otherwise two rows of five.
	var top := 34.0 if compact else 60.0
	var one_row := size.x >= 300.0
	var per := 10 if one_row else 5
	var rows := 1 if one_row else 2
	var gap := 4.0
	var r := minf((size.x - 24.0 - gap * (per - 1)) / (per * 2.0), (size.y - top - 10.0 - gap * (rows - 1)) / (rows * 2.0))
	var total_w := per * r * 2.0 + gap * (per - 1)
	var x0 := (size.x - total_w) * 0.5 + r
	for i in GameData.MAX_FILAMENT:
		var pos := Vector2(x0 + (i % per) * (r * 2.0 + gap), top + r + (i / per) * (r * 2.0 + gap))
		if i < fil:
			UI.draw_icon(self, "spool", pos, r, UI.CYAN)
		elif i < cap:
			UI.draw_icon(self, "spool", pos, r, Color("1f3550"))
			draw_arc(pos, r * 0.8, 0, TAU, 20, Color(0.3, 0.5, 0.7, 0.5), 1.5, true)
		else:
			draw_arc(pos, r * 0.78, 0, TAU, 20, Color(1, 1, 1, 0.13), 1.5, true)
