class_name PhysicalControlFamily
extends RefCounted
## Shared text-free hardware. Material is cached by kind while every label,
## accessibility description, selection, and focus state remains native Godot.

const ROOT := "res://assets/ui/physical_ui/live-correction-r1/controls/"
const KINDS := {"wide":"wide_parchment_tab", "binding":"binding_tab", "square":"square_stud", "tall":"tall_index", "lever":"lever", "token":"token"}
const FONT_COLORS := {"wide_parchment_tab":"172b3c", "binding_tab":"fff0cf", "square_stud":"fff0cf", "tall_index":"fff0cf", "lever":"fff0cf", "token":"fff0cf"}
const SOURCE_MARGINS := {"wide_parchment_tab":18, "binding_tab":36, "square_stud":18, "tall_index":14, "lever":20, "token":28}

static var _textures: Dictionary = {}
static var _styles: Dictionary = {}

static func apply(button: Button, kind := "wide", active := false, transparent_hit := false) -> void:
	var resolved := str(KINDS.get(kind, KINDS["wide"]))
	var target := _target_size(button, resolved)
	button.add_theme_stylebox_override("normal", _style(resolved, "pressed" if active else "normal", transparent_hit, target))
	button.add_theme_stylebox_override("hover", _style(resolved, "hover", transparent_hit, target))
	button.add_theme_stylebox_override("pressed", _style(resolved, "pressed", transparent_hit, target))
	button.add_theme_stylebox_override("focus", _focus_style(transparent_hit))
	button.add_theme_stylebox_override("disabled", _style(resolved, "disabled", transparent_hit, target))
	var ink := Color(str(FONT_COLORS.get(resolved, "fff0cf")))
	button.add_theme_color_override("font_color", ink)
	button.add_theme_color_override("font_hover_color", ink)
	button.add_theme_color_override("font_pressed_color", ink)
	button.add_theme_color_override("font_focus_color", ink)
	button.add_theme_color_override("font_disabled_color", Color(ink, 0.48))

static func _target_size(button: Button, kind: String) -> Vector2i:
	# Texture margins must leave a live center at the smallest approved target.
	var minimum := button.custom_minimum_size
	var width := maxi(56, roundi(minimum.x))
	var height := maxi(56, roundi(minimum.y))
	if kind == "tall_index": height = maxi(height, 64)
	return Vector2i(width, height)

static func _style(kind: String, state: String, transparent_hit: bool, target: Vector2i) -> StyleBox:
	if transparent_hit: return _transparent_overlay(state)
	var cache_key := "%s:%s:%d:%d" % [kind, state, target.x, target.y]
	if _styles.has(cache_key): return _styles[cache_key]
	var texture := _texture(kind)
	if texture == null:
		var fallback := StyleBoxFlat.new()
		fallback.bg_color = Color("ead9b7")
		fallback.border_color = Color("8a6945")
		fallback.set_border_width_all(2)
		fallback.set_corner_radius_all(6)
		_styles[cache_key] = fallback
		return fallback
	var style := StyleBoxTexture.new()
	style.texture = texture
	var margin := mini(int(SOURCE_MARGINS.get(kind, 18)), maxi(1, mini(target.x, target.y) / 3))
	style.texture_margin_left = margin
	style.texture_margin_right = margin
	style.texture_margin_top = margin
	style.texture_margin_bottom = margin
	if state == "pressed":
		style.content_margin_top = 2
		style.content_margin_bottom = -2
	if state == "disabled": style.modulate_color = Color(0.43, 0.40, 0.34, 0.84)
	_styles[cache_key] = style
	return style

static func _texture(kind: String) -> Texture2D:
	if _textures.has(kind): return _textures[kind] as Texture2D
	var texture := ResourceLoader.load("%s%s/normal.png" % [ROOT, kind]) as Texture2D
	_textures[kind] = texture
	return texture

static func release_cached_resources() -> void:
	# Runtime intentionally retains these small shared styles for the session.
	# Isolated test/capture processes call this after their owned scene is freed so
	# Godot can complete a real teardown rather than report cache-held resources.
	_styles.clear()
	_textures.clear()

static func _transparent_overlay(state: String) -> StyleBoxFlat:
	var overlay := StyleBoxFlat.new()
	if state == "disabled":
		overlay.bg_color = Color(0.10, 0.06, 0.03, 0.16)
		overlay.border_color = Color("72552f")
	elif state == "pressed":
		overlay.bg_color = Color(0.93, 0.72, 0.30, 0.10)
		overlay.border_color = Color("b98b46")
	elif state == "hover":
		overlay.bg_color = Color(0.30, 0.75, 0.76, 0.07)
		overlay.border_color = Color("75d8dd")
	else:
		overlay.bg_color = Color(0, 0, 0, 0)
		overlay.border_color = Color(0, 0, 0, 0)
	overlay.set_border_width_all(2 if state != "normal" else 0)
	return overlay

static func _focus_style(transparent_hit: bool) -> StyleBoxFlat:
	# Focus is an outline/glaze, never an opaque bitmap replacement.
	var ring := StyleBoxFlat.new()
	ring.bg_color = Color(0.10, 0.72, 0.78, 0.08 if transparent_hit else 0.04)
	ring.border_color = Color("75d8dd")
	ring.set_border_width_all(3)
	return ring
