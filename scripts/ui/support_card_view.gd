class_name SupportCardView
extends Button
## A single, portrait-first card renderer shared by archive, deck, shop and battle.
## Art never carries copy: every player-facing label remains a real Godot control.
const CARD_RULES := preload("res://scripts/battle/support_card_rules.gd")
const ATLAS_PATHS := {"resources":"res://assets/cards/support_cards_resources_source_v1.png", "defense":"res://assets/cards/support_cards_defense_source_v1.png", "offense":"res://assets/cards/support_cards_offense_source_v1.png", "utility":"res://assets/cards/support_cards_utility_source_v1.png"}
const CARD_BACK_PATH := "res://assets/cards/support_card_back_source_v1.png"
const FULL_SIZE := Vector2(174, 261) # Canonical 2:3 silhouette.
const COMPACT_SIZE := Vector2(150, 225) # Battle carousel tier; still touch-safe and readable.
static var _textures: Dictionary = {}
static var _regions: Dictionary = {}

func configure(definition: Dictionary, copies := 1, disabled_reason := "", hidden := false, compact := false, interactive := true) -> void:
	text = "" # Native Button text must never overdraw the composed card.
	custom_minimum_size = COMPACT_SIZE if compact else FULL_SIZE
	# A VBox may otherwise stretch the handoff back into a wide banner. Every
	# host receives the card's intrinsic 2:3 dimensions and can center it.
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var semantic := "Hidden support card" if hidden else "%s - %d Filament - %s - %s - Target: %s" % [str(definition.get("name", "Support Card")), int(definition.get("cost", 0)), str(definition.get("rarity", "common")).capitalize(), CARD_RULES.rules_text(definition), CARD_RULES.target_text(definition)]
	tooltip_text = semantic
	accessibility_name = semantic
	focus_mode = Control.FOCUS_ALL if interactive else Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	disabled = not disabled_reason.is_empty() or not interactive
	add_theme_stylebox_override("normal", _outer_frame(definition, disabled_reason, hidden))
	add_theme_stylebox_override("hover", _outer_frame(definition, disabled_reason, hidden, true))
	add_theme_stylebox_override("pressed", _outer_frame(definition, disabled_reason, hidden, true))
	add_theme_stylebox_override("disabled", _outer_frame(definition, disabled_reason, hidden))
	name = name if not name.is_empty() else "SupportCardView"
	if hidden:
		_build_hidden_back()
	else:
		_build_front(definition, copies, disabled_reason, compact)

func _outer_frame(definition: Dictionary, disabled_reason: String, hidden: bool, hover := false) -> StyleBoxFlat:
	var rarity := str(definition.get("rarity", "common"))
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("111c2f") if not hidden else Color("121b2b")
	frame.border_color = _rarity_color(rarity).lightened(0.18) if hover and disabled_reason.is_empty() else _rarity_color(rarity)
	frame.set_border_width_all(3)
	frame.corner_radius_top_left = 12; frame.corner_radius_top_right = 12
	frame.corner_radius_bottom_left = 12; frame.corner_radius_bottom_right = 12
	frame.shadow_color = Color(0.0, 0.0, 0.0, 0.48); frame.shadow_size = 5; frame.shadow_offset = Vector2(0, 3)
	frame.content_margin_left = 5; frame.content_margin_right = 5; frame.content_margin_top = 5; frame.content_margin_bottom = 5
	return frame

func _build_hidden_back() -> void:
	var back := TextureRect.new()
	back.name = "CardBackArt"
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 2)
	back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	back.texture = card_back_for_test()
	add_child(back)

func _build_front(definition: Dictionary, copies: int, disabled_reason: String, compact: bool) -> void:
	var inset := PanelContainer.new()
	inset.name = "CardInsetBorder"
	inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 3)
	inset.add_theme_stylebox_override("panel", _inset_frame(definition))
	add_child(inset)
	var content := VBoxContainer.new()
	content.name = "CardContent"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 3 if compact else 4)
	inset.add_child(content)
	var title_plate := PanelContainer.new()
	title_plate.name = "CardTitlePlate"
	title_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_plate.custom_minimum_size = Vector2(0, 24 if compact else 28)
	title_plate.add_theme_stylebox_override("panel", _title_frame(definition))
	content.add_child(title_plate)
	var title_row := Control.new()
	title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_plate.add_child(title_row)
	var title := _text(str(definition.get("name", "Support Card")), 12 if compact else 14, Color("fff0a1"))
	title.name = "CardTitle"
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 1)
	title.offset_right = -34
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_row.add_child(title)
	var cost := _text("%d F" % int(definition.get("cost", 0)), 11 if compact else 12, Color("102033"))
	cost.name = "CardCostBadge"
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost.custom_minimum_size = Vector2(30, 22)
	cost.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 1)
	cost.offset_left = -30
	cost.add_theme_stylebox_override("normal", _badge_frame())
	title_row.add_child(cost)
	var art_frame := PanelContainer.new()
	art_frame.name = "CardArtWindow"
	art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_frame.custom_minimum_size = Vector2(0, 72 if compact else 88)
	art_frame.add_theme_stylebox_override("panel", _art_frame(definition))
	content.add_child(art_frame)
	var art := TextureRect.new()
	art.name = "CardArt"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture = atlas_region(definition)
	art_frame.add_child(art)
	var role := _text("%s  •  %s" % [str(definition.get("rarity", "common")).capitalize(), str(definition.get("role", "utility")).capitalize()], 9 if compact else 10, _rarity_color(str(definition.get("rarity", "common"))))
	role.name = "CardRarityRole"
	role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(role)
	var rules := _text(CARD_RULES.rules_text(definition), 9 if compact else 11, Color("e8f1fa"))
	rules.name = "CardRulesPanel"
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rules.add_theme_stylebox_override("normal", _rules_frame())
	content.add_child(rules)
	var target := _text("Target: " + CARD_RULES.target_text(definition), 8 if compact else 9, Color("b9dff1"))
	target.name = "CardTargetFooter"
	target.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(target)
	if copies > 1:
		var count := _text("In hand / owned: x%d" % copies, 8 if compact else 9, Color("b3e8a3"))
		count.name = "CardOwnershipCount"
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(count)
	if not disabled_reason.is_empty():
		var disabled_banner := _text(disabled_reason, 8 if compact else 9, Color("fff0e2"))
		disabled_banner.name = "CardLegalityBanner"
		disabled_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		disabled_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		disabled_banner.add_theme_stylebox_override("normal", _disabled_frame())
		content.add_child(disabled_banner)

func _inset_frame(definition: Dictionary) -> StyleBoxFlat:
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("1a2c43")
	frame.border_color = Color("ad7b35")
	frame.set_border_width_all(2)
	frame.corner_radius_top_left = 8; frame.corner_radius_top_right = 8
	frame.corner_radius_bottom_left = 8; frame.corner_radius_bottom_right = 8
	frame.content_margin_left = 5; frame.content_margin_right = 5; frame.content_margin_top = 5; frame.content_margin_bottom = 5
	return frame

func _badge_frame() -> StyleBoxFlat:
	var frame := StyleBoxFlat.new(); frame.bg_color = Color("f0bd62"); frame.border_color = Color("ffe5a7")
	frame.set_border_width_all(1); frame.corner_radius_top_left = 6; frame.corner_radius_top_right = 6; frame.corner_radius_bottom_left = 6; frame.corner_radius_bottom_right = 6
	return frame

func _title_frame(definition: Dictionary) -> StyleBoxFlat:
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("263b53")
	frame.border_color = _rarity_color(str(definition.get("rarity", "common"))).darkened(0.15)
	frame.set_border_width_all(1)
	frame.corner_radius_top_left = 5; frame.corner_radius_top_right = 5
	frame.corner_radius_bottom_left = 5; frame.corner_radius_bottom_right = 5
	frame.content_margin_left = 4; frame.content_margin_right = 3; frame.content_margin_top = 1; frame.content_margin_bottom = 1
	return frame

func _art_frame(definition: Dictionary) -> StyleBoxFlat:
	var frame := StyleBoxFlat.new(); frame.bg_color = Color("091426"); frame.border_color = _rarity_color(str(definition.get("rarity", "common"))).darkened(0.2)
	frame.set_border_width_all(2); frame.corner_radius_top_left = 5; frame.corner_radius_top_right = 5; frame.corner_radius_bottom_left = 5; frame.corner_radius_bottom_right = 5
	frame.content_margin_left = 2; frame.content_margin_right = 2; frame.content_margin_top = 2; frame.content_margin_bottom = 2
	return frame

func _rules_frame() -> StyleBoxFlat:
	var frame := StyleBoxFlat.new(); frame.bg_color = Color("0c1d31"); frame.border_color = Color("314f69")
	frame.set_border_width_all(1); frame.corner_radius_top_left = 4; frame.corner_radius_top_right = 4; frame.corner_radius_bottom_left = 4; frame.corner_radius_bottom_right = 4
	frame.content_margin_left = 4; frame.content_margin_right = 4; frame.content_margin_top = 3; frame.content_margin_bottom = 3
	return frame

func _disabled_frame() -> StyleBoxFlat:
	var frame := StyleBoxFlat.new(); frame.bg_color = Color("803f45"); frame.border_color = Color("ffaaa1")
	frame.set_border_width_all(1); frame.corner_radius_top_left = 4; frame.corner_radius_top_right = 4; frame.corner_radius_bottom_left = 4; frame.corner_radius_bottom_right = 4
	frame.content_margin_left = 3; frame.content_margin_right = 3; frame.content_margin_top = 2; frame.content_margin_bottom = 2
	return frame

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"epic": return Color("d58bff")
		"rare": return Color("73dfff")
		"uncommon": return Color("87db91")
		_: return Color("d1b77d")

static func atlas_texture_for_test(atlas_id: String) -> Texture2D:
	if not ATLAS_PATHS.has(atlas_id): return null
	if not _textures.has(atlas_id): _textures[atlas_id] = ResourceLoader.load(str(ATLAS_PATHS[atlas_id])) as Texture2D
	return _textures.get(atlas_id) as Texture2D

static func card_back_for_test() -> Texture2D:
	if not _textures.has("back"): _textures["back"] = ResourceLoader.load(CARD_BACK_PATH) as Texture2D
	return _textures.get("back") as Texture2D

static func atlas_region(definition: Dictionary) -> Texture2D:
	var art = definition.get("art", {})
	var atlas_id := str(art.get("atlas", "")) if art is Dictionary else ""
	var cell := int(art.get("cell", -1)) if art is Dictionary else -1
	var key := "%s:%d" % [atlas_id, cell]
	if _regions.has(key): return _regions[key]
	var texture := atlas_texture_for_test(atlas_id)
	if texture == null or cell < 0 or cell >= 8: return card_back_for_test()
	var size := texture.get_size()
	var region := AtlasTexture.new()
	region.atlas = texture
	region.region = Rect2(float(cell % 4) * size.x / 4.0, float(cell / 4) * size.y / 2.0, size.x / 4.0, size.y / 2.0)
	_regions[key] = region
	return region

static func cache_count_for_test() -> int: return _textures.size() + _regions.size()
static func reset_cache_for_test() -> void: _textures.clear(); _regions.clear()

func _text(value: String, size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = value; result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size", size); result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result
