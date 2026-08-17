class_name TouchScrollContainer
extends ScrollContainer
## Shared touch-first scroller for long non-battle activity screens.
const FOUNDRY_THEME := preload("res://scripts/ui/arcane_foundry_theme_kit.gd")

func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll_deadzone = 8
	follow_focus = true
	scroll_vertical_custom_step = 56.0
	call_deferred("_style_bar")

func _style_bar() -> void:
	var bar := get_v_scroll_bar()
	bar.name = "TouchScrollBar"
	bar.custom_minimum_size = Vector2(32, 44)
	bar.add_theme_stylebox_override("grabber", FOUNDRY_THEME.button("primary", "normal", false))
	bar.add_theme_stylebox_override("grabber_highlight", FOUNDRY_THEME.button("commit", "hover", false))

func _bar_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("ecd9ae") if color == Color("c39450") else Color("10292e")
	style.set_border_width_all(1)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 8
	style.content_margin_right = 8
	return style
