class_name TeamPrototypeNativeWidgets
extends RefCounted
## Shared native controls. Route presenters supply only copy, physical seat and action.

const Physical := preload("res://scripts/ui/m1_physical_ui_component.gd")
const Controls := preload("res://scripts/ui/physical_control_family.gd")


static func label(parent: Control, text: String, rect: Rect2, font_size: int, text_scale_bps: int, high_contrast: bool, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var result := Label.new()
	result.text = text
	result.horizontal_alignment = align
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size", scaled_font_size(font_size, text_scale_bps))
	result.add_theme_color_override("font_color", Color("ffffff") if high_contrast else Color("172b3c"))
	result.add_theme_color_override("font_outline_color", Color("06121c") if high_contrast else Color("f4e6c4"))
	result.add_theme_constant_override("outline_size", 3 if high_contrast else 1)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Physical.place_design(result, rect)
	parent.add_child(result)
	return result


static func button(parent: Control, caption: String, rect: Rect2, action: Callable, disabled: bool, kind: String, text_scale_bps: int, high_contrast: bool, minimum_design_hit := 0.0, transparent_hit := true) -> Button:
	var result := Button.new()
	result.text = caption
	result.disabled = disabled
	result.focus_mode = Control.FOCUS_ALL
	result.tooltip_text = caption
	result.accessibility_name = caption
	result.add_theme_font_size_override("font_size", scaled_font_size(27, text_scale_bps))
	result.add_theme_color_override("font_outline_color", Color("24160b"))
	result.add_theme_constant_override("outline_size", 2 if not high_contrast else 3)
	# The authored rectangle remains the visual/text center. Only the transparent
	# owner expands symmetrically when a contain-fit would otherwise shrink a touch
	# target below the platform minimum.
	var hit_rect := rect
	if minimum_design_hit > 0.0:
		var target_size := Vector2(maxf(rect.size.x, minimum_design_hit), maxf(rect.size.y, minimum_design_hit))
		hit_rect.position -= (target_size - rect.size) * 0.5
		hit_rect.size = target_size
	Physical.place_design(result, hit_rect)
	result.set_meta("authored_rect", rect)
	result.set_meta("expanded_hit_rect", hit_rect)
	Controls.apply(result, kind, false, transparent_hit)
	# PhysicalControlFamily establishes the material ink. Reapply the native edge
	# after its state styles so light labels stay legible on every control state.
	result.add_theme_color_override("font_outline_color", Color("24160b"))
	result.add_theme_constant_override("outline_size", 2 if not high_contrast else 3)
	if disabled and kind == "wide":
		# Disabled selectors and order controls remain explanatory, rather than
		# darkening unreadably with their physical owner.
		result.add_theme_color_override("font_disabled_color", Color("fff0c8"))
	Physical.add_inset_button_focus_ring(result, high_contrast)
	result.pressed.connect(action)
	parent.add_child(result)
	return result


static func scaled_font_size(base_size: int, text_scale_bps: int) -> int:
	return roundi(float(base_size) * (1.5 if text_scale_bps == 15000 else 1.0))
