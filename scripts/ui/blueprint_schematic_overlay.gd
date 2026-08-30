class_name BlueprintSchematicOverlay
extends Control
## Native drafting treatment layered over existing creature art. It deliberately
## owns no text or game data, so every label stays accessible and localizable.

var tint := Color("6defff")
var strength := 0.62

func configure(next_tint: Color, next_strength := 0.62) -> void:
	tint = next_tint
	strength = clampf(next_strength, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if rect.size.x < 4.0 or rect.size.y < 4.0:
		return
	var step := maxf(16.0, minf(size.x, size.y) / 9.0)
	var fine := Color(tint, 0.09 * strength)
	var major := Color(tint, 0.20 * strength)
	var x := 0.0
	while x <= size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), major if int(x / step) % 4 == 0 else fine, 1.0)
		x += step
	var y := 0.0
	while y <= size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), major if int(y / step) % 4 == 0 else fine, 1.0)
		y += step
	draw_rect(rect.grow(-2.0), Color(tint, 0.75 * strength), false, 1.5)
	var corner := minf(18.0, minf(size.x, size.y) * 0.18)
	for point in [Vector2(2, 2), Vector2(size.x - 2, 2), Vector2(2, size.y - 2), Vector2(size.x - 2, size.y - 2)]:
		var dx := 1.0 if point.x < size.x * 0.5 else -1.0
		var dy := 1.0 if point.y < size.y * 0.5 else -1.0
		draw_line(point, point + Vector2(corner * dx, 0), Color(tint, strength), 2.0)
		draw_line(point, point + Vector2(0, corner * dy), Color(tint, strength), 2.0)
