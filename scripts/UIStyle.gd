# UIStyle.gd
# Shared visual helpers for placeholder-era UI polish (no external art required).

class_name UIStyle
extends RefCounted

const BG_DARK = Color(0.102, 0.102, 0.18)
const BG_DARKER = Color(0.051, 0.051, 0.102)
const ACCENT_PURPLE = Color(0.482, 0.184, 0.745)
const ACCENT_AMBER = Color(0.91, 0.627, 0.125)
const TEXT_MUTED = Color(0.667, 0.667, 0.667)

const ELEMENT_ICONS = {
	"fire": "🔥",
	"water": "💧",
	"lightning": "⚡",
	"nature": "🌿",
	"ice": "❄",
	"stone": "🪨",
	"wind": "🌬",
	"arcane": "✨",
}

const STARTER_GLYPHS = {
	"cinderpaw": "🦊",
	"aquafin": "🐬",
	"voltwig": "⚡",
}


static func element_icon(element: String) -> String:
	return ELEMENT_ICONS.get(element, "✨")


static func starter_glyph(creature_id: String) -> String:
	return STARTER_GLYPHS.get(creature_id, element_icon("arcane"))


static func card_stylebox(accent: Color, selected: bool = false) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.07, 0.13, 0.96)
	sb.border_color = accent.lightened(0.15) if selected else accent.darkened(0.1)
	sb.set_border_width_all(3 if selected else 2)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 14
	sb.content_margin_top = 14
	sb.content_margin_right = 14
	sb.content_margin_bottom = 14
	sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.35 if selected else 0.18)
	sb.shadow_size = 10 if selected else 6
	sb.shadow_offset = Vector2(0, 3)
	return sb


static func make_sprite_placeholder(creature_id: String, creature: Dictionary) -> Control:
	var accent: Color = creature["placeholder_color"]
	var wrap = PanelContainer.new()
	wrap.custom_minimum_size = Vector2(180, 180)
	var inner = StyleBoxFlat.new()
	inner.bg_color = Color(0.04, 0.04, 0.08)
	inner.border_color = accent
	inner.set_border_width_all(2)
	inner.set_corner_radius_all(10)
	wrap.add_theme_stylebox_override("panel", inner)

	var stack = Control.new()
	stack.custom_minimum_size = Vector2(180, 180)
	wrap.add_child(stack)

	# Filament "layer lines"
	for i in range(6):
		var line = ColorRect.new()
		line.color = Color(accent.r, accent.g, accent.b, 0.12)
		line.size = Vector2(180, 2)
		line.position = Vector2(0, 28 + i * 24)
		stack.add_child(line)

	var glow = ColorRect.new()
	glow.color = Color(accent.r, accent.g, accent.b, 0.35)
	glow.position = Vector2(20, 20)
	glow.size = Vector2(140, 140)
	stack.add_child(glow)

	var glyph = Label.new()
	glyph.text = starter_glyph(creature_id)
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	glyph.set_anchors_preset(Control.PRESET_FULL_RECT)
	glyph.add_theme_font_size_override("font_size", 72)
	stack.add_child(glyph)

	var badge = Label.new()
	badge.text = element_icon(creature["element"])
	badge.position = Vector2(8, 8)
	badge.add_theme_font_size_override("font_size", 22)
	stack.add_child(badge)

	return wrap


static func add_workshop_background(parent: Node) -> void:
	var base = ColorRect.new()
	base.set_anchors_preset(Control.PRESET_FULL_RECT)
	base.color = BG_DARK
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(base)
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Warm amber glow — top-left forge light
	var glow1 = ColorRect.new()
	glow1.color = Color(0.91, 0.627, 0.125, 0.06)
	glow1.position = Vector2(-80, -80)
	glow1.size = Vector2(500, 400)
	glow1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(glow1)

	# Arcane purple glow — bottom-right
	var glow2 = ColorRect.new()
	glow2.color = Color(0.482, 0.184, 0.745, 0.08)
	glow2.position = Vector2(880, 420)
	glow2.size = Vector2(480, 360)
	glow2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(glow2)

	# Subtle grid lines (workshop floor feel)
	for x in range(0, 1280, 80):
		var vline = ColorRect.new()
		vline.color = Color(1, 1, 1, 0.02)
		vline.position = Vector2(x, 0)
		vline.size = Vector2(1, 720)
		vline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(vline)


static func make_header_bar(title: String, subtitle: String = "") -> VBoxContainer:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)

	var brand = Label.new()
	brand.text = "⚙ PRINTFORGE LEGENDS"
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brand.add_theme_color_override("font_color", ACCENT_AMBER)
	brand.add_theme_font_size_override("font_size", 14)
	box.add_child(brand)

	var title_lbl = Label.new()
	title_lbl.text = title
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_color_override("font_color", ACCENT_AMBER)
	title_lbl.add_theme_font_size_override("font_size", 32)
	box.add_child(title_lbl)

	if subtitle != "":
		var sub = Label.new()
		sub.text = subtitle
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.add_theme_color_override("font_color", TEXT_MUTED)
		sub.add_theme_font_size_override("font_size", 18)
		box.add_child(sub)

	return box
