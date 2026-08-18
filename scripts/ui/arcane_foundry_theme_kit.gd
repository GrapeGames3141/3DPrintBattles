class_name ArcaneFoundryThemeKit
extends RefCounted
## Cached semantic chrome. Raster 9-slices keep the selected Foundry depth at
## every screen size; high contrast deliberately stays code-native.

const PANEL_TEXTURE := preload("res://assets/ui/arcane_foundry/foundry_panel_compact_v1.png")
const KEYCAP_TEXTURE := preload("res://assets/ui/arcane_foundry/foundry_keycap_compact_v1.png")
const KEYCAP_HOVER_TEXTURE := preload("res://assets/ui/arcane_foundry/foundry_keycap_hover_compact_v1.png")
const KEYCAP_PRESSED_TEXTURE := preload("res://assets/ui/arcane_foundry/foundry_keycap_pressed_compact_v1.png")
const KEYCAP_DISABLED_TEXTURE := preload("res://assets/ui/arcane_foundry/foundry_keycap_disabled_compact_v1.png")
const CARTRIDGE_TEXTURE := preload("res://assets/ui/arcane_foundry/foundry_blueprint_cartridge_compact_v2.png")
const INSET_TEXTURE := preload("res://assets/ui/arcane_foundry/foundry_inset_well_compact_v1.png")
const DISPLAY_FONT := preload("res://assets/fonts/Arvo-Bold.ttf")
static var _cache: Dictionary = {}

static func panel(role := "surface", high_contrast := false) -> StyleBox:
	var key := "panel:%s:%s" % [role, high_contrast]
	if _cache.has(key): return _cache[key]
	if high_contrast:
		var fallback := StyleBoxFlat.new(); fallback.bg_color = Color("050505"); fallback.border_color = Color.WHITE; fallback.set_border_width_all(3); fallback.content_margin_left = 16; fallback.content_margin_right = 16; fallback.content_margin_top = 13; fallback.content_margin_bottom = 13; _cache[key] = fallback; return fallback
	# The panel source has a deeper top bevel and broader shoulder than the old
	# even-looking slice suggested. Keep copy clear of that bevel at every scale.
	var style := _texture_box(PANEL_TEXTURE, 36, 20, 36, 20, 15, 13)
	style.modulate_color = _role_tint(role, Color.WHITE)
	_cache[key] = style
	return style

static func cartridge(selected := false, high_contrast := false) -> StyleBox:
	var key := "cartridge:%s:%s" % [selected, high_contrast]
	if _cache.has(key): return _cache[key]
	if high_contrast: return panel("surface", true)
	var style := _texture_box(CARTRIDGE_TEXTURE, 30, 24, 30, 21, 12, 11)
	style.modulate_color = Color("ffffffff") if selected else Color("c4d7d9ff")
	_cache[key] = style
	return style

static func button(role := "primary", state := "normal", high_contrast := false) -> StyleBox:
	var key := "button:%s:%s:%s" % [role, state, high_contrast]
	if _cache.has(key): return _cache[key]
	if high_contrast:
		var fallback := StyleBoxFlat.new(); fallback.bg_color = Color("050505") if state != "pressed" else Color("272727"); fallback.border_color = Color.WHITE; fallback.set_border_width_all(3); fallback.content_margin_left = 10; fallback.content_margin_right = 10; fallback.content_margin_top = 6; fallback.content_margin_bottom = 6; _cache[key] = fallback; return fallback
	var texture := KEYCAP_TEXTURE
	if state in ["hover", "focus"]: texture = KEYCAP_HOVER_TEXTURE
	elif state == "pressed": texture = KEYCAP_PRESSED_TEXTURE
	elif state == "disabled": texture = KEYCAP_DISABLED_TEXTURE
	# Keycap artwork carries its visual weight below the geometric midpoint. The
	# asymmetric content inset moves the actual glyph block up two pixels, which
	# keeps one- and multi-line labels on the same optical baseline at 100-150%.
	var style := _texture_box(texture, 32, 14, 32, 13, 10, 8, 12)
	style.modulate_color = _role_tint(role, Color.WHITE)
	_cache[key] = style
	return style

static func inset(role := "surface", high_contrast := false) -> StyleBox:
	var key := "inset:%s:%s" % [role, high_contrast]
	if _cache.has(key): return _cache[key]
	if high_contrast: return panel(role, true)
	# Match the shallow source border after the compact derivative while leaving
	# a little more breathing room above copy and meter labels.
	var style := _texture_box(INSET_TEXTURE, 14, 11, 14, 10, 12, 10)
	style.modulate_color = _role_tint(role, Color.WHITE)
	_cache[key] = style
	return style

static func _texture_box(texture: Texture2D, left: float, top: float, right: float, bottom: float, horizontal: float, vertical_top: float, vertical_bottom := -1.0) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = left; style.texture_margin_top = top; style.texture_margin_right = right; style.texture_margin_bottom = bottom
	style.expand_margin_left = 3; style.expand_margin_top = 3; style.expand_margin_right = 3; style.expand_margin_bottom = 3
	style.content_margin_left = horizontal; style.content_margin_right = horizontal; style.content_margin_top = vertical_top; style.content_margin_bottom = vertical_bottom if vertical_bottom >= 0.0 else vertical_top
	style.draw_center = true
	return style

static func section_header(role := "surface", high_contrast := false) -> StyleBox:
	var key := "section_header:%s:%s" % [role, high_contrast]
	if _cache.has(key): return _cache[key]
	var style := _stamped_plate(role, high_contrast, 14, 7, 9)
	_cache[key] = style
	return style

static func status_chip(role := "surface", high_contrast := false) -> StyleBox:
	var key := "status_chip:%s:%s" % [role, high_contrast]
	if _cache.has(key): return _cache[key]
	var style := _stamped_plate(role, high_contrast, 12, 5, 7)
	_cache[key] = style
	return style

static func _stamped_plate(role: String, high_contrast: bool, horizontal: float, top: float, bottom: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("050505") if high_contrast else _role_tint(role, Color("162027")).darkened(0.78)
	style.border_color = Color.WHITE if high_contrast else _role_tint(role, Color("6bd6ed"))
	style.set_border_width_all(2 if high_contrast else 1)
	style.set_corner_radius_all(4)
	style.content_margin_left = horizontal; style.content_margin_right = horizontal; style.content_margin_top = top; style.content_margin_bottom = bottom
	return style

static func selected_button(role := "primary", high_contrast := false) -> StyleBox:
	# Reuse the illuminated Foundry keycap instead of introducing new selection art.
	return button(role, "focus", high_contrast)

static func _role_tint(role: String, fallback: Color) -> Color:
	match role:
		"commit": return Color("ffc06eff")
		"secondary": return Color("93b6d7ff")
		"arcane": return Color("d0a5ffff")
		"success": return Color("a6e9b2ff")
		"danger": return Color("ffaaa1ff")
		"muted": return Color("929b9fff")
		_: return fallback

static func clear_cache_for_test() -> void:
	_cache.clear()

static func cache_count_for_test() -> int:
	return _cache.size()

static func display_font() -> Font:
	return DISPLAY_FONT
