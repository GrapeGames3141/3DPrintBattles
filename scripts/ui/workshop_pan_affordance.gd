class_name WorkshopPanAffordance
extends Control
## A compact, non-text cue for a horizontally pannable portrait workshop view.

func _draw() -> void:
	var tint := Color("9beaff")
	var middle := size * 0.5
	var rail_y := middle.y
	draw_line(Vector2(7.0, rail_y), Vector2(size.x - 7.0, rail_y), Color(tint, 0.38), 1.5)
	_draw_chevron(Vector2(11.0, rail_y), -1.0, tint)
	_draw_chevron(Vector2(size.x - 11.0, rail_y), 1.0, tint)

func _draw_chevron(center: Vector2, direction: float, tint: Color) -> void:
	var reach := 5.0
	draw_line(center + Vector2(direction * reach, -reach), center + Vector2(-direction * reach, 0.0), tint, 2.0)
	draw_line(center + Vector2(-direction * reach, 0.0), center + Vector2(direction * reach, reach), tint, 2.0)
