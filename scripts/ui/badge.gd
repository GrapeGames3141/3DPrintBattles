class_name Badge
extends Control
## A number on a coloured shape: Filament cost, Attack, Health, Armor.

var shape := "circle"
var color := Color.WHITE
var _label: Label


static func make(badge_shape: String, badge_color: Color, px: float) -> Badge:
	var b := Badge.new()
	b.shape = badge_shape
	b.color = badge_color
	b.size = Vector2(px, px)
	b.custom_minimum_size = b.size
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b._label = UI.label("", int(px * 0.6), Color.WHITE, true, int(px * 0.16))
	b._label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b._label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	b._label.size = b.size
	b._label.position = Vector2(0, -px * 0.03)
	b.add_child(b._label)
	return b


func set_value(v: int, text_color := Color.WHITE) -> void:
	_label.text = str(v)
	_label.add_theme_color_override("font_color", text_color)


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5
	match shape:
		"spool":
			draw_circle(c, r, Color("0b1220"))
			UI.draw_icon(self, "spool", c, r * 0.92, color)
			draw_circle(c, r * 0.5, color.darkened(0.55))
		"burst":
			draw_colored_polygon(UI._star(c, r, r * 0.74, 10), Color("0b1220"))
			draw_colored_polygon(UI._star(c, r * 0.88, r * 0.66, 10), color)
			draw_circle(c, r * 0.58, color.darkened(0.3))
		"hex":
			draw_colored_polygon(UI._ngon(c, r, 6, PI / 6.0), Color("0b1220"))
			draw_colored_polygon(UI._ngon(c, r * 0.86, 6, PI / 6.0), color)
			draw_colored_polygon(UI._ngon(c, r * 0.62, 6, PI / 6.0), color.darkened(0.3))
		"shield":
			UI.draw_icon(self, "shield", c, r, color)
		_:
			draw_circle(c, r, Color("0b1220"))
			draw_circle(c, r * 0.86, color)
