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
	var style := _texture_box(PANEL_TEXTURE, 34, 18, 34, 18, 12, 10)
	style.modulate_color = _role_tint(role, Color.WHITE)
	_cache[key] = style
	return style

static func cartridge(selected := false, high_contrast := false) -> StyleBox:
	var key := "cartridge:%s:%s" % [selected, high_contrast]
	if _cache.has(key): return _cache[key]
	if high_contrast: return panel("surface", true)
	var style := _texture_box(CARTRIDGE_TEXTURE, 28, 22, 28, 22, 10, 9)
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
	var style := _texture_box(texture, 30, 12, 30, 12, 8, 4)
	style.modulate_color = _role_tint(role, Color.WHITE)
	_cache[key] = style
	return style

static func inset(role := "surface", high_contrast := false) -> StyleBox:
	var key := "inset:%s:%s" % [role, high_contrast]
	if _cache.has(key): return _cache[key]
	if high_contrast: return panel(role, true)
	# Match the shallow source border after the half-scale compact derivative.
	var style := _texture_box(INSET_TEXTURE, 11, 8, 11, 8, 10, 8)
	style.modulate_color = _role_tint(role, Color.WHITE)
	_cache[key] = style
	return style

static func _texture_box(texture: Texture2D, left: float, top: float, right: float, bottom: float, horizontal: float, vertical: float) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = left; style.texture_margin_top = top; style.texture_margin_right = right; style.texture_margin_bottom = bottom
	style.expand_margin_left = 3; style.expand_margin_top = 3; style.expand_margin_right = 3; style.expand_margin_bottom = 3
	style.content_margin_left = horizontal; style.content_margin_right = horizontal; style.content_margin_top = vertical; style.content_margin_bottom = vertical
	style.draw_center = true
	return style

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
