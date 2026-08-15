class_name WorkshopHotspotOverlay
extends Control
## Draw-only physical-prop highlight used by the accessible, unlabeled workshop buttons.

var accent := Color("9beaff")
var motion_enabled := true
var emphasis := 0.0
var phase := 0.0

func configure(tone: Color, allow_motion: bool, fixed_phase := 0.0) -> void:
	accent = tone
	motion_enabled = allow_motion
	phase = fixed_phase
	set_process(motion_enabled)
	queue_redraw()

func set_emphasis(value: float) -> void:
	emphasis = clampf(value, 0.0, 1.0)
	queue_redraw()

func _process(delta: float) -> void:
	phase = fmod(phase + delta * 0.55, TAU)
	queue_redraw()

func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(phase) if motion_enabled else 0.5
	var strength := 0.24 + pulse * 0.10 + emphasis * 0.42
	var rect := Rect2(Vector2.ZERO, size).grow(-3.0)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	# Bracket corners identify the real prop without turning its full hit area
	# into a translucent button plaque. A faint edge and halo keep it legible.
	var faint := Color(accent, strength * 0.16)
	draw_line(rect.position, Vector2(rect.end.x, rect.position.y), faint, 1.0)
	draw_line(Vector2(rect.position.x, rect.end.y), rect.end, faint, 1.0)
	var corner := minf(28.0, minf(rect.size.x, rect.size.y) * 0.24)
	var bright := Color(accent, strength)
	var halo := Color(accent, strength * 0.20)
	for width in [7.0, 3.0]:
		var color := halo if width > 3.0 else bright
		draw_line(rect.position, rect.position + Vector2(corner, 0), color, width)
		draw_line(rect.position, rect.position + Vector2(0, corner), color, width)
		draw_line(Vector2(rect.end.x - corner, rect.position.y), Vector2(rect.end.x, rect.position.y), color, width)
		draw_line(Vector2(rect.end.x, rect.position.y), Vector2(rect.end.x, rect.position.y + corner), color, width)
		draw_line(Vector2(rect.position.x, rect.end.y - corner), Vector2(rect.position.x, rect.end.y), color, width)
		draw_line(Vector2(rect.position.x, rect.end.y), Vector2(rect.position.x + corner, rect.end.y), color, width)
		draw_line(Vector2(rect.end.x - corner, rect.end.y), rect.end, color, width)
		draw_line(Vector2(rect.end.x, rect.end.y - corner), rect.end, color, width)
