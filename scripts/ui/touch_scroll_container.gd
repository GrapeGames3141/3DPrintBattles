class_name TouchScrollContainer
extends ScrollContainer
## Shared touch-first scroller for long non-battle activity screens.

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
	bar.add_theme_stylebox_override("grabber", _bar_style(Color("6bd6ed"), 10))
	bar.add_theme_stylebox_override("grabber_highlight", _bar_style(Color("ffd36c"), 10))

func _bar_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 7
	style.content_margin_right = 7
	return style
