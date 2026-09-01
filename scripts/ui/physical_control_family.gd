class_name PhysicalControlFamily
extends RefCounted
## Native-label control family derived from the approved state atlas. The art is a
## material backdrop only; focus, accessibility, values, and feedback stay native.

const ROOT := "res://assets/ui/physical_ui/live-correction-r1/controls/"
const KINDS := {"wide":"wide_parchment_tab", "binding":"binding_tab", "square":"square_stud", "tall":"tall_index", "lever":"lever", "token":"token"}
const STATES := ["normal", "focused", "pressed", "disabled"]

static func apply(button: Button, kind := "wide", active := false, transparent_hit := false) -> void:
	var resolved := str(KINDS.get(kind, KINDS["wide"]))
	# A selected/latching object is mechanically depressed.  Cyan is reserved for
	# live keyboard/touch focus, so selection and focus never become ambiguous.
	button.add_theme_stylebox_override("normal", _style(resolved, "pressed" if active else "normal", transparent_hit))
	button.add_theme_stylebox_override("hover", _style(resolved, "focused", transparent_hit))
	button.add_theme_stylebox_override("pressed", _style(resolved, "pressed", transparent_hit))
	button.add_theme_stylebox_override("focus", _focus_style(resolved, transparent_hit))
	button.add_theme_stylebox_override("disabled", _style(resolved, "disabled", transparent_hit))
	button.add_theme_color_override("font_color", Color("47331f"))
	button.add_theme_color_override("font_hover_color", Color("47331f"))
	button.add_theme_color_override("font_pressed_color", Color("2e2115"))
	button.add_theme_color_override("font_focus_color", Color("47331f"))
	button.add_theme_color_override("font_disabled_color", Color("7f6a52"))

static func _style(kind: String, state: String, transparent_hit: bool) -> StyleBox:
	if transparent_hit:
		# Hit regions remain visually transparent over authored hardware, but each
		# interaction state adds a thin physical glaze/edge rather than silently
		# behaving like a flat invisible app button.
		var overlay := StyleBoxFlat.new(); overlay.bg_color = Color(0.10, 0.06, 0.03, 0.16) if state == "disabled" else Color(0.93, 0.72, 0.30, 0.10) if state == "pressed" else Color(0.30, 0.75, 0.76, 0.07) if state == "focused" else Color(0.0, 0.0, 0.0, 0.0); overlay.border_color = Color("72552f") if state == "disabled" else Color("b98b46") if state == "pressed" else Color("75d8dd") if state == "focused" else Color(0, 0, 0, 0); overlay.set_border_width_all(2 if state != "normal" else 0); overlay.content_margin_top = 2 if state == "pressed" else 0; return overlay
	var path := "%s%s/%s.png" % [ROOT, kind, state]
	var texture := ResourceLoader.load(path) as Texture2D
	if texture == null:
		var fallback := StyleBoxFlat.new(); fallback.bg_color = Color("ead9b7"); fallback.border_color = Color("8a6945"); fallback.set_border_width_all(2); fallback.corner_radius_top_left = 6; fallback.corner_radius_top_right = 6; fallback.corner_radius_bottom_left = 6; fallback.corner_radius_bottom_right = 6; return fallback
	var style := StyleBoxTexture.new(); style.texture = texture; style.texture_margin_left = 10; style.texture_margin_right = 10; style.texture_margin_top = 10; style.texture_margin_bottom = 10; style.expand_margin_left = 1; style.expand_margin_right = 1; style.expand_margin_top = 1; style.expand_margin_bottom = 1; return style

static func _focus_style(kind: String, transparent_hit: bool) -> StyleBox:
	var style := _style(kind, "focused", transparent_hit)
	if transparent_hit:
		var ring := StyleBoxFlat.new(); ring.bg_color = Color(0, 0, 0, 0); ring.border_color = Color("75d8dd"); ring.set_border_width_all(3); return ring
	return style
