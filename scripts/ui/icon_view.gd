class_name IconView
extends Control
## A small vector icon (see UI.draw_icon for the kinds).

var kind := "coin"
var color := Color.WHITE


static func make(icon_kind: String, px: float, icon_color: Color) -> IconView:
	var v := IconView.new()
	v.kind = icon_kind
	v.color = icon_color
	v.custom_minimum_size = Vector2(px, px)
	v.size = Vector2(px, px)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return v


func _draw() -> void:
	UI.draw_icon(self, kind, size * 0.5, minf(size.x, size.y) * 0.5, color)
