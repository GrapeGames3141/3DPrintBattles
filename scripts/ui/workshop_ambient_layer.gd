class_name WorkshopAmbientLayer
extends Control
## Low-cost, code-native workshop life. It is presentation only and owns no game state.

var view_id := "overview"
var motion_enabled := true
var phase := 0.0

func configure(next_view_id: String, allow_motion: bool, fixed_phase := 0.0) -> void:
	view_id = next_view_id
	motion_enabled = allow_motion
	phase = fixed_phase
	process_mode = Node.PROCESS_MODE_INHERIT if motion_enabled else Node.PROCESS_MODE_DISABLED
	set_process(motion_enabled)
	queue_redraw()

func _process(delta: float) -> void:
	# Slow ping-pong progress means the print head reverses before either edge.
	phase = fmod(phase + delta * 0.14, 1.0)
	queue_redraw()

func _draw() -> void:
	var ping_pong := 1.0 - absf(phase * 2.0 - 1.0)
	var glow := 0.34 + 0.20 * sin(phase * TAU) if motion_enabled else 0.44
	for hologram in _hologram_regions(view_id):
		_draw_hologram(hologram, glow)
	for printer in _printer_regions(view_id):
		_draw_printer_life(printer, ping_pong, glow)

func _hologram_regions(id: String) -> Array[Rect2]:
	match id:
		"overview": return [Rect2(0.64, 0.33, 0.18, 0.28)]
		"printer": return [Rect2(0.67, 0.31, 0.18, 0.40)]
		"maker": return [Rect2(0.38, 0.27, 0.24, 0.39)]
		"terminal": return [Rect2(0.56, 0.34, 0.34, 0.31)]
		"proving": return [Rect2(0.42, 0.49, 0.22, 0.16)]
		"yard": return [Rect2(0.38, 0.42, 0.24, 0.24)]
	return []

func _printer_regions(id: String) -> Array[Rect2]:
	match id:
		"overview": return [Rect2(0.10, 0.43, 0.28, 0.31)]
		"printer": return [Rect2(0.36, 0.29, 0.33, 0.43)]
		"proving": return [Rect2(0.05, 0.46, 0.22, 0.25)]
	return []

func _draw_hologram(normalized: Rect2, glow: float) -> void:
	var rect := _scaled_rect(normalized)
	var tint := Color("70eaff")
	draw_rect(rect, Color(tint, glow * 0.06), true)
	draw_rect(rect, Color(tint, glow * 0.36), false, 1.5)
	var sweep_y := rect.position.y + rect.size.y * (0.18 + phase * 0.64)
	draw_line(Vector2(rect.position.x + 6.0, sweep_y), Vector2(rect.end.x - 6.0, sweep_y), Color(tint, glow * 0.65), 2.0)

func _draw_printer_life(normalized: Rect2, ping_pong: float, glow: float) -> void:
	var rect := _scaled_rect(normalized)
	var head_x := lerpf(rect.position.x + rect.size.x * 0.18, rect.end.x - rect.size.x * 0.18, ping_pong)
	var y := rect.position.y + rect.size.y * 0.40
	draw_line(Vector2(rect.position.x + 8.0, y), Vector2(rect.end.x - 8.0, y), Color("f1be69", glow * 0.36), 2.0)
	draw_circle(Vector2(head_x, y), 5.0, Color("a8edff", glow * 0.86))
	draw_circle(Vector2(head_x, y), 11.0, Color("a8edff", glow * 0.13))

func _scaled_rect(normalized: Rect2) -> Rect2:
	return Rect2(normalized.position * size, normalized.size * size)
