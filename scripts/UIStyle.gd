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


static func creature_texture(creature: Dictionary) -> Texture2D:
	var path = "res://assets/sprites/%s" % creature["sprite"]
	if ResourceLoader.exists(path):
		return load(path)
	return null


static func _make_portrait_frame(size: Vector2) -> PanelContainer:
	var frame = PanelContainer.new()
	frame.custom_minimum_size = size
	var frame_style = StyleBoxFlat.new()
	frame_style.bg_color = Color(0.9, 0.87, 0.8)
	frame_style.border_color = Color(0.45, 0.38, 0.28)
	frame_style.set_border_width_all(2)
	frame_style.set_corner_radius_all(8)
	frame.add_theme_stylebox_override("panel", frame_style)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_child(center)
	return frame


static func make_creature_sprite(creature: Dictionary, size: Vector2, mode: String = "full") -> Control:
	var tex = creature_texture(creature)
	if mode == "full" and tex:
		var rect = TextureRect.new()
		rect.texture = tex
		rect.custom_minimum_size = size
		rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		return rect
	if mode == "seen" and tex:
		var rect = TextureRect.new()
		rect.texture = tex
		rect.custom_minimum_size = size
		rect.modulate = Color(0.15, 0.15, 0.15)
		rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		return rect

	return make_creature_placeholder(creature, size, mode)


static func make_creature_placeholder(creature: Dictionary, size: Vector2, mode: String = "full") -> Control:
	var wrap = CenterContainer.new()
	wrap.custom_minimum_size = size

	var accent = creature.get("placeholder_color", Color(0.3, 0.3, 0.3))
	match mode:
		"seen":
			accent = accent.darkened(0.35)
		"unknown":
			accent = Color(0.35, 0.35, 0.38)
		_:
			accent = accent.lightened(0.12)

	# Parchment frame — keeps colored swatches readable on dark UI
	var frame = PanelContainer.new()
	frame.custom_minimum_size = size
	var frame_style = StyleBoxFlat.new()
	frame_style.bg_color = Color(0.9, 0.87, 0.8)
	frame_style.border_color = Color(0.45, 0.38, 0.28)
	frame_style.set_border_width_all(2)
	frame_style.set_corner_radius_all(8)
	frame_style.shadow_color = Color(0, 0, 0, 0.35)
	frame_style.shadow_size = 4
	frame_style.shadow_offset = Vector2(0, 2)
	frame.add_theme_stylebox_override("panel", frame_style)

	var inner = CenterContainer.new()
	inner.custom_minimum_size = size * 0.88
	frame.add_child(inner)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = size * 0.72
	var style = StyleBoxFlat.new()
	style.bg_color = accent
	style.border_color = Color(1, 1, 1, 0.85)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(accent.r, accent.g, accent.b, 0.5)
	style.shadow_size = 6
	panel.add_theme_stylebox_override("panel", style)

	var icon = Label.new()
	icon.text = element_icon(creature.get("element", "arcane"))
	icon.add_theme_font_size_override("font_size", int(min(size.x, size.y) * 0.38))
	icon.add_theme_color_override("font_color", Color(0.08, 0.08, 0.1))
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(icon)
	inner.add_child(panel)
	wrap.add_child(frame)
	return wrap


static func apply_creature_sprite(slot: Control, creature: Dictionary, mode: String = "full") -> void:
	for child in slot.get_children():
		child.queue_free()

	var tex = creature_texture(creature)
	if mode == "full" and tex:
		if slot is ColorRect:
			slot.color = Color.TRANSPARENT
		var slot_size = slot.size
		if slot_size.x < 8 or slot_size.y < 8:
			slot_size = Vector2(120, 120)
		var framed = _make_portrait_frame(slot_size)
		var rect = TextureRect.new()
		rect.texture = tex
		rect.custom_minimum_size = slot_size * 0.78
		rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		framed.get_child(0).add_child(rect)
		framed.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		slot.add_child(framed)
		return
	if mode == "seen" and tex:
		if slot is ColorRect:
			slot.color = Color.TRANSPARENT
		var rect = TextureRect.new()
		rect.texture = tex
		rect.modulate = Color(0.15, 0.15, 0.15)
		rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot.add_child(rect)
		return

	var color = creature.get("placeholder_color", Color(0.3, 0.3, 0.3))
	if mode == "seen":
		color = color.darkened(0.35)
	elif mode == "unknown":
		color = Color(0.35, 0.35, 0.38)
	if slot is ColorRect:
		slot.color = Color.TRANSPARENT

	var slot_size = slot.size
	if slot_size.x < 8 or slot_size.y < 8:
		slot_size = Vector2(120, 120)
	var portrait = make_creature_placeholder(creature, slot_size, mode)
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slot.add_child(portrait)


static func make_bench_icon(creature: Dictionary) -> Control:
	return make_creature_sprite(creature, Vector2(48, 48))


static func load_hit_frames(creature_id: String) -> Array:
	var frames: Array = []
	var i = 0
	while true:
		var path = "res://assets/sprites/%s_hit_%02d.png" % [creature_id, i]
		if ResourceLoader.exists(path):
			frames.append(load(path))
			i += 1
			continue
		break
	return frames


static func make_blueprint_scroll(creature: Dictionary, size: Vector2 = Vector2(120, 160)) -> Control:
	var accent: Color = creature.get("placeholder_color", ACCENT_AMBER)
	var wrap = PanelContainer.new()
	wrap.custom_minimum_size = size

	var scroll = StyleBoxFlat.new()
	scroll.bg_color = Color(0.12, 0.11, 0.18, 0.98)
	scroll.border_color = accent.lightened(0.35)
	scroll.set_border_width_all(2)
	scroll.set_corner_radius_all(8)
	scroll.content_margin_left = 8
	scroll.content_margin_top = 10
	scroll.content_margin_right = 8
	scroll.content_margin_bottom = 10
	scroll.shadow_color = Color(ACCENT_PURPLE.r, ACCENT_PURPLE.g, ACCENT_PURPLE.b, 0.35)
	scroll.shadow_size = 8
	scroll.shadow_offset = Vector2(0, 2)
	wrap.add_theme_stylebox_override("panel", scroll)

	var stack = Control.new()
	stack.custom_minimum_size = Vector2(size.x - 16, size.y - 20)
	wrap.add_child(stack)

	var rune_top = Label.new()
	rune_top.text = "✦ ✧ ✦"
	rune_top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rune_top.add_theme_color_override("font_color", ACCENT_AMBER.lightened(0.15))
	rune_top.add_theme_font_size_override("font_size", 12)
	rune_top.position = Vector2(0, 2)
	rune_top.size = Vector2(stack.custom_minimum_size.x, 18)
	stack.add_child(rune_top)

	# Light viewport so portrait pops against the dark scroll
	var viewport = PanelContainer.new()
	viewport.position = Vector2(4, 22)
	viewport.size = Vector2(stack.custom_minimum_size.x - 8, stack.custom_minimum_size.y - 44)
	var viewport_style = StyleBoxFlat.new()
	viewport_style.bg_color = Color(0.9, 0.87, 0.8)
	viewport_style.border_color = Color(0.5, 0.42, 0.32)
	viewport_style.set_border_width_all(1)
	viewport_style.set_corner_radius_all(6)
	viewport.add_theme_stylebox_override("panel", viewport_style)

	var sprite_area = CenterContainer.new()
	sprite_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sprite = make_creature_sprite(creature, Vector2(68, 68), "full")
	sprite_area.add_child(sprite)
	viewport.add_child(sprite_area)
	stack.add_child(viewport)

	var rune_bottom = Label.new()
	rune_bottom.text = "BLUEPRINT"
	rune_bottom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rune_bottom.add_theme_color_override("font_color", ACCENT_PURPLE.lightened(0.2))
	rune_bottom.add_theme_font_size_override("font_size", 10)
	rune_bottom.position = Vector2(0, stack.custom_minimum_size.y - 18)
	rune_bottom.size = Vector2(stack.custom_minimum_size.x, 16)
	stack.add_child(rune_bottom)

	return wrap


const EQUIPMENT_ICONS = {
	"armor": "🛡",
	"weapon": "⚔",
	"accessory": "💍",
}


static func make_equipment_blueprint(equipment: Dictionary, size: Vector2 = Vector2(120, 150)) -> Control:
	var accent: Color = equipment.get("placeholder_color", ACCENT_AMBER)
	var eq_type: String = equipment.get("type", "armor")
	var wrap = PanelContainer.new()
	wrap.custom_minimum_size = size

	var scroll = StyleBoxFlat.new()
	scroll.bg_color = Color(0.1, 0.09, 0.16, 0.98)
	scroll.border_color = accent.lightened(0.2)
	scroll.set_border_width_all(2)
	scroll.set_corner_radius_all(8)
	scroll.content_margin_left = 8
	scroll.content_margin_top = 10
	scroll.content_margin_right = 8
	scroll.content_margin_bottom = 10
	wrap.add_theme_stylebox_override("panel", scroll)

	var stack = Control.new()
	stack.custom_minimum_size = Vector2(size.x - 16, size.y - 20)
	wrap.add_child(stack)

	var rune_top = Label.new()
	rune_top.text = "⚙ GEAR"
	rune_top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rune_top.add_theme_color_override("font_color", ACCENT_AMBER.lightened(0.1))
	rune_top.add_theme_font_size_override("font_size", 11)
	rune_top.position = Vector2(0, 2)
	rune_top.size = Vector2(stack.custom_minimum_size.x, 16)
	stack.add_child(rune_top)

	var viewport = PanelContainer.new()
	viewport.position = Vector2(4, 20)
	viewport.size = Vector2(stack.custom_minimum_size.x - 8, stack.custom_minimum_size.y - 40)
	var viewport_style = StyleBoxFlat.new()
	viewport_style.bg_color = Color(0.88, 0.86, 0.82)
	viewport_style.border_color = accent.darkened(0.1)
	viewport_style.set_border_width_all(2)
	viewport_style.set_corner_radius_all(6)
	viewport.add_theme_stylebox_override("panel", viewport_style)

	var inner = CenterContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var icon_panel = PanelContainer.new()
	icon_panel.custom_minimum_size = Vector2(72, 72)
	var icon_style = StyleBoxFlat.new()
	icon_style.bg_color = accent
	icon_style.border_color = Color(1, 1, 1, 0.7)
	icon_style.set_border_width_all(2)
	icon_style.set_corner_radius_all(10)
	icon_panel.add_theme_stylebox_override("panel", icon_style)
	var icon = Label.new()
	icon.text = EQUIPMENT_ICONS.get(eq_type, "⚙")
	icon.add_theme_font_size_override("font_size", 36)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_panel.add_child(icon)
	inner.add_child(icon_panel)
	viewport.add_child(inner)
	stack.add_child(viewport)

	var rune_bottom = Label.new()
	rune_bottom.text = eq_type.to_upper()
	rune_bottom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rune_bottom.add_theme_color_override("font_color", accent.lightened(0.15))
	rune_bottom.add_theme_font_size_override("font_size", 10)
	rune_bottom.position = Vector2(0, stack.custom_minimum_size.y - 16)
	rune_bottom.size = Vector2(stack.custom_minimum_size.x, 14)
	stack.add_child(rune_bottom)

	return wrap


static func apply_equipment_sprite(slot: Control, equipment: Dictionary) -> void:
	for child in slot.get_children():
		child.queue_free()
	if slot is ColorRect:
		slot.color = Color.TRANSPARENT
	var slot_size = slot.size
	if slot_size.x < 8 or slot_size.y < 8:
		slot_size = Vector2(120, 120)
	var portrait = make_equipment_blueprint(equipment, slot_size)
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slot.add_child(portrait)


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
