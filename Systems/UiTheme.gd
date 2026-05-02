class_name UiTheme
extends RefCounted

## Bright toy-like workshop palette — flat panels, rounded corners, soft shadows.


static func build_workshop_theme() -> Theme:
	var theme := Theme.new()

	var sky := Color(0.42, 0.78, 0.98)
	var sky_hover := Color(0.55, 0.86, 1.0)
	var sky_pressed := Color(0.28, 0.62, 0.92)
	var coral := Color(1.0, 0.52, 0.38)
	var cream := Color(1.0, 0.97, 0.92)
	var ink := Color(0.18, 0.22, 0.34)

	var radius := 14
	var shadow_col := Color(0, 0, 0, 0.22)

	var btn_normal := _sb_flat(sky, ink, radius, shadow_col, 5, Vector2(2, 4))
	var btn_hover := _sb_flat(sky_hover, ink, radius, shadow_col, 6, Vector2(2, 5))
	var btn_pressed := _sb_flat(sky_pressed, Color.WHITE, radius, shadow_col, 3, Vector2(1, 2))
	var btn_disabled := _sb_flat(Color(0.82, 0.86, 0.9), Color(0.55, 0.58, 0.62), radius, Color(0, 0, 0, 0.08), 2, Vector2(1, 2))

	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("disabled", "Button", btn_disabled)
	var focus_sb: StyleBoxFlat = btn_hover.duplicate()
	focus_sb.border_color = Color(coral.r, coral.g, coral.b, 0.65)
	focus_sb.border_width_left = 3
	focus_sb.border_width_top = 3
	focus_sb.border_width_right = 3
	focus_sb.border_width_bottom = 3
	theme.set_stylebox("focus", "Button", focus_sb)

	var panel := _sb_flat(cream, ink, radius + 2, Color(0, 0, 0, 0.18), 6, Vector2(3, 5))
	theme.set_stylebox("panel", "PanelContainer", panel)

	theme.set_color("font_color", "Label", ink)
	theme.set_color("font_shadow_color", "Label", Color(1, 1, 1, 0.35))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)

	theme.set_color("font_color", "Button", ink)
	theme.set_color("font_hover_color", "Button", ink)
	theme.set_color("font_pressed_color", "Button", ink)

	theme.set_constant("separation", "VBoxContainer", 10)
	theme.set_constant("separation", "HBoxContainer", 10)

	return theme


static func _sb_flat(bg: Color, border_col: Color, corner: int, shadow_col: Color, shadow_sz: int, shadow_off: Vector2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_width_left = 2
	s.border_width_top = 2
	s.border_width_right = 2
	s.border_width_bottom = 2
	s.border_color = Color(border_col.r, border_col.g, border_col.b, 0.28)
	s.corner_radius_top_left = corner
	s.corner_radius_top_right = corner
	s.corner_radius_bottom_left = corner
	s.corner_radius_bottom_right = corner
	s.shadow_color = shadow_col
	s.shadow_size = shadow_sz
	s.shadow_offset = shadow_off
	s.content_margin_left = 14
	s.content_margin_top = 10
	s.content_margin_right = 14
	s.content_margin_bottom = 10
	return s
