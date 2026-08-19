class_name UnifiedCardView
extends Button
## A shared 2:3 Foundry card plate for the unified creature, equipment, spell,
## and refill catalog. SupportCardView remains the authoritative presenter for
## legacy support-card surfaces; this companion accepts every unified card type.

const SUPPORT_CARD_VIEW := preload("res://scripts/ui/support_card_view.gd")
const FULL_SIZE := Vector2(166, 249)
const COMPACT_SIZE := Vector2(142, 213)

func configure(definition: Dictionary, copies := 0, market_price := -1, status_text := "", compact := true, interactive := true, unknown := false) -> void:
	text = ""
	custom_minimum_size = COMPACT_SIZE if compact else FULL_SIZE
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	focus_mode = Control.FOCUS_ALL if interactive else Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	disabled = not interactive
	var summary := "Undiscovered creature card" if unknown else "%s · %s · %d filament · %s" % [str(definition.get("name", "Card")), str(definition.get("type", "card")).capitalize(), int(definition.get("cost", 0)), _detail_text(definition).replace("\n", ", ")]
	tooltip_text = summary
	accessibility_name = summary
	add_theme_stylebox_override("normal", _frame(false))
	add_theme_stylebox_override("hover", _frame(true))
	add_theme_stylebox_override("pressed", _frame(true))
	add_theme_stylebox_override("disabled", _frame(false))
	if unknown: _build_unknown_back(compact)
	else: _build_front(definition, copies, market_price, status_text, compact)

func _build_unknown_back(compact: bool) -> void:
	var back := TextureRect.new()
	back.name = "UnifiedCardUnknownBack"
	back.texture = SUPPORT_CARD_VIEW.card_back_for_test()
	back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 3)
	add_child(back)
	var rail := PanelContainer.new()
	rail.name = "UnifiedCardUnknownRail"
	rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rail.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	rail.offset_top = -42 if compact else -48
	rail.add_theme_stylebox_override("panel", _footer_frame())
	add_child(rail)
	var caption := _text("Undiscovered\nFind its blueprint", 9 if compact else 11, Color("dce8f4"))
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rail.add_child(caption)

static func art_for_definition(definition: Dictionary) -> Texture2D:
	var card_id := str(definition.get("id", ""))
	if str(definition.get("type", "")) == "creature":
		if not Catalog.creature(card_id).is_empty():
			var atlas := AtlasTexture.new()
			atlas.atlas = CreatureSpriteCache.texture_for_creature(card_id)
			atlas.region = CreatureSpriteCache.safe_source_region(0)
			return atlas
		var bespoke := load("res://assets/cards/creatures/%s_v1.png" % card_id) as Texture2D
		if bespoke != null: return bespoke
	if definition.has("art"): return SUPPORT_CARD_VIEW.atlas_region(definition)
	return SUPPORT_CARD_VIEW.card_back_for_test()

func _build_front(definition: Dictionary, copies: int, market_price: int, status_text: String, compact: bool) -> void:
	var inset := PanelContainer.new()
	inset.name = "UnifiedCardInset"
	inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 3)
	inset.add_theme_stylebox_override("panel", _inset_frame())
	add_child(inset)
	var content := VBoxContainer.new()
	content.name = "UnifiedCardContent"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 2)
	inset.add_child(content)
	var title_plate := PanelContainer.new()
	title_plate.name = "UnifiedCardTitlePlate"
	title_plate.custom_minimum_size = Vector2(0, 25 if compact else 28)
	title_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_plate.add_theme_stylebox_override("panel", _title_frame())
	content.add_child(title_plate)
	var title_row := Control.new()
	title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_plate.add_child(title_row)
	var title := _text(str(definition.get("name", "Card")), 11 if compact else 13, Color("f7ead0"))
	title.name = "UnifiedCardTitle"
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 2)
	title.offset_right = -29
	title_row.add_child(title)
	var cost := _text("%dF" % int(definition.get("cost", 0)), 9, Color("172333"))
	cost.name = "UnifiedCardCost"
	cost.custom_minimum_size = Vector2(23, 23)
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 1)
	cost.offset_left = -23
	cost.add_theme_stylebox_override("normal", _badge_frame())
	title_row.add_child(cost)
	var aspect := AspectRatioContainer.new()
	aspect.name = "UnifiedCardArtAspect"
	aspect.ratio = 1.5
	aspect.stretch_mode = AspectRatioContainer.STRETCH_WIDTH_CONTROLS_HEIGHT
	aspect.custom_minimum_size = Vector2(0, 82 if compact else 100)
	aspect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(aspect)
	var art_shell := PanelContainer.new()
	art_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_shell.add_theme_stylebox_override("panel", _art_frame())
	aspect.add_child(art_shell)
	var art := TextureRect.new()
	art.name = "UnifiedCardArt"
	art.texture = art_for_definition(definition)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_shell.add_child(art)
	var metadata := _text("%s · %s" % [str(definition.get("rarity", "common")).capitalize(), str(definition.get("type", "card")).capitalize()], 8 if compact else 9, _rarity_color(str(definition.get("rarity", "common"))))
	metadata.name = "UnifiedCardMetadata"
	metadata.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	metadata.autowrap_mode = TextServer.AUTOWRAP_OFF
	metadata.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	metadata.add_theme_stylebox_override("normal", _metadata_frame())
	content.add_child(metadata)
	var detail := _text(_detail_text(definition), 8 if compact else 10, Color("e5edf4"))
	detail.name = "UnifiedCardDetail"
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detail.add_theme_stylebox_override("normal", _detail_frame())
	content.add_child(detail)
	var footer := _text(_footer_text(copies, market_price, status_text), 8 if compact else 9, Color("bde3d8"))
	footer.name = "UnifiedCardFooter"
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_stylebox_override("normal", _footer_frame())
	content.add_child(footer)

static func _detail_text(definition: Dictionary) -> String:
	match str(definition.get("type", "")):
		"creature": return "HP %d · ATK %d\nPrint %dt" % [int(definition.get("hp", 0)), int(definition.get("attack", 0)), int(definition.get("print_ticks", 1))]
		"refill": return "+%d filament\nUp to spool cap" % int(definition.get("amount", definition.get("refill", 0)))
		"equipment": return "Attach · %s" % str(definition.get("effect", "field upgrade")).replace("_", " ").capitalize()
		_: return str(definition.get("effect", definition.get("rules", "Tactical printer effect"))).replace("_", " ").capitalize()

static func _footer_text(copies: int, market_price: int, status_text: String) -> String:
	var parts: Array[String] = []
	if copies > 0: parts.append("Owned x%d" % copies)
	if market_price >= 0: parts.append("Buy %d FC" % market_price)
	if not status_text.is_empty(): parts.append(status_text)
	return " · ".join(parts) if not parts.is_empty() else "Tap for card details"

func _text(value: String, font_size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = value
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

func _frame(active: bool) -> StyleBoxFlat:
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("15191a")
	frame.border_color = Color("6ac4cd") if active else Color("8a7048")
	frame.set_border_width_all(1)
	frame.corner_radius_top_left = 5; frame.corner_radius_top_right = 5
	frame.corner_radius_bottom_left = 5; frame.corner_radius_bottom_right = 5
	frame.shadow_color = Color(0, 0, 0, 0.42); frame.shadow_size = 3; frame.shadow_offset = Vector2(0, 2)
	frame.content_margin_left = 3; frame.content_margin_right = 3; frame.content_margin_top = 3; frame.content_margin_bottom = 3
	return frame

func _inset_frame() -> StyleBoxFlat:
	var frame := StyleBoxFlat.new(); frame.bg_color = Color("202426"); frame.border_color = Color("705f43")
	frame.set_border_width_all(1); frame.content_margin_left = 3; frame.content_margin_right = 3; frame.content_margin_top = 3; frame.content_margin_bottom = 3
	return frame

func _title_frame() -> StyleBoxFlat:
	var frame := StyleBoxFlat.new(); frame.bg_color = Color("292a29"); frame.border_color = Color("8a7048")
	frame.set_border_width_all(1); frame.content_margin_left = 4; frame.content_margin_right = 2
	return frame

func _badge_frame() -> StyleBoxFlat:
	var frame := StyleBoxFlat.new(); frame.bg_color = Color("b98b4d"); frame.border_color = Color("ecd9ae")
	frame.set_border_width_all(1); frame.corner_radius_top_left = 12; frame.corner_radius_top_right = 12; frame.corner_radius_bottom_left = 12; frame.corner_radius_bottom_right = 12
	return frame

func _art_frame() -> StyleBoxFlat:
	var frame := StyleBoxFlat.new(); frame.bg_color = Color("101314"); frame.border_color = Color("9a7744")
	frame.set_border_width_all(1); frame.content_margin_left = 1; frame.content_margin_right = 1; frame.content_margin_top = 1; frame.content_margin_bottom = 1
	return frame

func _metadata_frame() -> StyleBoxFlat:
	var frame := StyleBoxFlat.new(); frame.bg_color = Color("1a2021"); frame.border_color = Color("4ca5ae")
	frame.border_width_bottom = 1; frame.content_margin_top = 1; frame.content_margin_bottom = 1
	return frame

func _detail_frame() -> StyleBoxFlat:
	var frame := StyleBoxFlat.new(); frame.bg_color = Color("16191a"); frame.border_color = Color("4a4d4b")
	frame.set_border_width_all(1); frame.content_margin_left = 4; frame.content_margin_right = 4; frame.content_margin_top = 2; frame.content_margin_bottom = 2
	return frame

func _footer_frame() -> StyleBoxFlat:
	var frame := StyleBoxFlat.new(); frame.bg_color = Color("1b2425"); frame.border_color = Color("607f78")
	frame.border_width_top = 1; frame.content_margin_left = 3; frame.content_margin_right = 3; frame.content_margin_top = 1; frame.content_margin_bottom = 1
	return frame

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"epic", "mythic": return Color("d58bff")
		"rare", "legendary", "prismatic", "primordial": return Color("73dfff")
		"uncommon": return Color("87db91")
		_: return Color("d1b77d")
