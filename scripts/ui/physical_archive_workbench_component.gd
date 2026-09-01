class_name PhysicalArchiveWorkbenchComponent
extends RefCounted
## Owns Collection folio and Deck Workbench controls over the shared M3 plate.

const RULES := preload("res://scripts/core/unified_rules.gd")
const UNIFIED_CARD_VIEW := preload("res://scripts/ui/unified_card_view.gd")

## Normalized against the 941x1672 CO-01 master.  These are the dark recess
## interiors, not a responsive app-grid: the brass rims remain authored art.
const ARCHIVE_CARD_WELLS := [
	Rect2(0.1875, 0.197266, 0.291667, 0.162109), Rect2(0.5174, 0.197266, 0.291667, 0.162109),
	Rect2(0.1875, 0.386719, 0.291667, 0.160156), Rect2(0.5174, 0.386719, 0.291667, 0.160156),
	Rect2(0.1875, 0.574219, 0.291667, 0.160156), Rect2(0.5174, 0.574219, 0.291667, 0.160156)
]
const ARCHIVE_PAGE_ROCKER_RECT := Rect2(0.054, 0.897, 0.182, 0.095)
const ARCHIVE_BOTTOM_WELLS := [
	Rect2(0.247, 0.897, 0.222, 0.095), Rect2(0.479167, 0.897, 0.224, 0.095),
	Rect2(0.714, 0.897, 0.224, 0.095)
]

func render_archive(main: Control, surface: Control, margin: Callable, heading: Callable) -> void:
	var hud := Control.new(); hud.name = "ArchiveNavyArchHud"; hud.anchor_left = 0.130; hud.anchor_top = 0.025; hud.anchor_right = 0.870; hud.anchor_bottom = 0.100; surface.add_child(hud)
	var back := _archive_button("ArchiveArchBack", "Back", main.navigate_to.bind("workshop"), false); back.set_anchors_preset(Control.PRESET_FULL_RECT); back.anchor_top = 0.18; back.anchor_right = 0.145; back.anchor_bottom = 0.82; back.offset_bottom = -2; back.custom_minimum_size = Vector2(54, 48); back.tooltip_text = "Return to Workshop"; back.accessibility_name = back.tooltip_text; hud.add_child(back)
	_archive_hud_label(main, hud, "ArchiveHudLevel", "Level %d" % int(GameManager.profile.get("level", 1)), Rect2(0.180, 0.14, 0.205, 0.68))
	_archive_hud_label(main, hud, "ArchiveHudXp", "XP %d" % int(GameManager.profile.get("spool_xp", 0)), Rect2(0.405, 0.14, 0.245, 0.68))
	_archive_hud_label(main, hud, "ArchiveHudCoins", "Coin %d" % int(GameManager.profile.get("forge_coins", 0)), Rect2(0.675, 0.14, 0.305, 0.68))
	var cards: Array = []
	for definition in RULES.all_cards():
		var id := str(definition.get("id", "")); var owned := int(GameManager.profile.get("owned_cards", {}).get(id, 0)) > 0; var printable := str(definition.get("type", "")) == "creature" and RULES.has_printable_blueprint(GameManager.profile, id)
		if (not bool(main.m3_archive_owned_only) or owned) and (not bool(main.m3_archive_printable_only) or printable): cards.append(definition)
	var category := str(main.get_meta("m3_archive_category", "all")); cards = _archive_category_cards(cards, category)
	var page := int(main.get_meta("m3_archive_page", 0)); var pages := maxi(1, ceili(cards.size() / 6.0)); page = clampi(page, 0, pages - 1); main.set_meta("m3_archive_page", page)
	var header := PanelContainer.new(); header.name = "ArchiveParchmentHeader"; header.anchor_left = 0.155; header.anchor_top = 0.105; header.anchor_right = 0.855; header.anchor_bottom = 0.164; header.add_theme_stylebox_override("panel", main._visual_style(Color("ead9b7"), Color("755332"), 8, 2)); surface.add_child(header)
	var header_box := VBoxContainer.new(); header_box.add_theme_constant_override("separation", 0); header.add_child(header_box); var title: Label = main.label("ARCHIVE", 18, Color("352516")); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.autowrap_mode = TextServer.AUTOWRAP_OFF; header_box.add_child(title); var count: Label = main.label("%d results · page %d/%d" % [cards.size(), page + 1, pages], 11, Color("513c25")); count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; count.autowrap_mode = TextServer.AUTOWRAP_OFF; header_box.add_child(count)
	var aperture := Control.new(); aperture.name = "ArchiveSixCardApertures"; aperture.clip_contents = true; aperture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); surface.add_child(aperture)
	var grid := Control.new(); grid.name = "ArchiveBookCardGrid"; grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); aperture.add_child(grid)
	var visible_cards: Array = cards.slice(page * 6, page * 6 + 6)
	for index in visible_cards.size():
		var host := Control.new(); host.name = "ArchiveCardWell%02d" % (index + 1); host.clip_contents = true; _set_normalized_rect(host, ARCHIVE_CARD_WELLS[index]); grid.add_child(host)
		var card: Dictionary = visible_cards[index]; var id := str(card.get("id", "")); var creature := str(card.get("type", "")) == "creature"; var owned := int(GameManager.profile.get("owned_cards", {}).get(id, 0))
		var view := _archive_tile(card, owned, "Owned ×%d" % owned if owned > 0 else ("Blueprint" if creature else "Support")); view.name = "ArchiveBlueprintCard" + id.capitalize(); view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); view.offset_left = 8; view.offset_top = 8; view.offset_right = -8; view.offset_bottom = -8; view.pressed.connect(func(): main.unified_inspector_id = id; main.unified_inspector_tab = "card"; main.render()); host.add_child(view)
	var rail := ScrollContainer.new(); rail.name = "ArchiveMetalCategoryRail"; rail.anchor_left = 0.245; rail.anchor_top = 0.777; rail.anchor_right = 0.755; rail.anchor_bottom = 0.863; rail.clip_contents = true; rail.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO; rail.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; rail.get_h_scroll_bar().modulate = Color(1, 1, 1, 0); rail.get_h_scroll_bar().mouse_filter = Control.MOUSE_FILTER_IGNORE; surface.add_child(rail)
	var tab_row := HBoxContainer.new(); tab_row.name = "ArchiveMetalCategoryTabRow"; tab_row.custom_minimum_size = Vector2(700, 52); tab_row.add_theme_constant_override("separation", 8); rail.add_child(tab_row)
	var categories := [["all","All"],["creature","Creatures"],["filament","Filament"],["spell","Spells"],["equipment","Equipment"],["trap","Traps"],["upgrade","Upgrades"]]
	for index in categories.size():
		var entry: Array = categories[index]; var id := str(entry[0]); var tab := _archive_button("ArchiveCategory" + id.capitalize(), str(entry[1]), func(): main.set_meta("m3_archive_category", id); main.set_meta("m3_archive_page", 0); main.render(), category == id); tab.custom_minimum_size = Vector2(92, 48); tab.tooltip_text = "Browse %s" % str(entry[1]).to_lower(); tab.accessibility_name = tab.tooltip_text; tab.focus_entered.connect(rail.ensure_control_visible.bind(tab)); tab_row.add_child(tab)
	var rail_previous := _archive_button("ArchiveCategoryRailPrevious", "‹", func(): _scroll_archive_tabs(rail, -1)); _set_normalized_rect(rail_previous, Rect2(0.150, 0.777, 0.090, 0.086)); rail_previous.custom_minimum_size = Vector2(48, 48); rail_previous.tooltip_text = "Show earlier archive categories"; rail_previous.accessibility_name = rail_previous.tooltip_text; surface.add_child(rail_previous)
	var rail_next := _archive_button("ArchiveCategoryRailNext", "›", func(): _scroll_archive_tabs(rail, 1)); _set_normalized_rect(rail_next, Rect2(0.760, 0.777, 0.090, 0.086)); rail_next.custom_minimum_size = Vector2(48, 48); rail_next.tooltip_text = "Show later archive categories"; rail_next.accessibility_name = rail_next.tooltip_text; surface.add_child(rail_next)
	var wells := Control.new(); wells.name = "ArchiveLowerPhysicalWells"; wells.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); surface.add_child(wells)
	var rocker := Control.new(); rocker.name = "ArchivePageRocker"; rocker.clip_contents = true; _set_normalized_rect(rocker, ARCHIVE_PAGE_ROCKER_RECT); wells.add_child(rocker)
	var previous := _archive_button("ArchivePagePrevious", "‹", func(): main.set_meta("m3_archive_page", maxi(0, page - 1)); main.render()); previous.disabled = page <= 0; previous.tooltip_text = "Previous archive page"; previous.anchor_right = 0.50; previous.anchor_bottom = 1.0; previous.custom_minimum_size = Vector2(48, 48); rocker.add_child(previous)
	var next := _archive_button("ArchivePageNext", "›", func(): main.set_meta("m3_archive_page", mini(pages - 1, page + 1)); main.render()); next.disabled = page >= pages - 1; next.tooltip_text = "Next archive page"; next.anchor_left = 0.50; next.anchor_right = 1.0; next.anchor_bottom = 1.0; next.custom_minimum_size = Vector2(48, 48); rocker.add_child(next)
	var owned_well := _archive_button("ArchiveWellOwned", "Owned", func(): main.m3_archive_owned_only = not bool(main.m3_archive_owned_only); main.set_meta("m3_archive_page", 0); main.render(), bool(main.m3_archive_owned_only)); _set_normalized_rect(owned_well, ARCHIVE_BOTTOM_WELLS[0]); owned_well.custom_minimum_size = Vector2(48, 48); wells.add_child(owned_well)
	var printable_well := _archive_button("ArchiveWellPrintable", "Printable", func(): main.m3_archive_printable_only = not bool(main.m3_archive_printable_only); main.set_meta("m3_archive_page", 0); main.render(), bool(main.m3_archive_printable_only)); _set_normalized_rect(printable_well, ARCHIVE_BOTTOM_WELLS[1]); printable_well.custom_minimum_size = Vector2(48, 48); wells.add_child(printable_well)
	var clear_well := _archive_button("ArchiveWellClear", "Clear", func(): main.m3_archive_owned_only = false; main.m3_archive_printable_only = false; main.set_meta("m3_archive_category", "all"); main.set_meta("m3_archive_page", 0); main.render()); _set_normalized_rect(clear_well, ARCHIVE_BOTTOM_WELLS[2]); clear_well.custom_minimum_size = Vector2(48, 48); wells.add_child(clear_well)
	if cards.is_empty():
		var empty: Label = main.label("No cards match these wells. Clear filters to browse.", 15, Color("513c25")); empty.name = "ArchiveEmptyState"; empty.position = Vector2(76, 470); surface.add_child(empty)
	if not main.unified_inspector_id.is_empty(): _archive_detail(main, surface)

func _set_normalized_rect(node: Control, rect: Rect2) -> void:
	node.anchor_left = rect.position.x; node.anchor_top = rect.position.y; node.anchor_right = rect.end.x; node.anchor_bottom = rect.end.y

func _scroll_archive_tabs(rail: ScrollContainer, direction: int) -> void:
	var maximum := int(rail.get_h_scroll_bar().max_value)
	rail.scroll_horizontal = clampi(rail.scroll_horizontal + direction * 132, 0, maximum)

func _archive_hud_label(main: Control, hud: Control, node_name: String, value: String, rect: Rect2) -> void:
	var label: Label = main.label(value, 14, Color("f3e5c9")); label.name = node_name; label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; label.autowrap_mode = TextServer.AUTOWRAP_OFF; label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; label.custom_minimum_size = Vector2(112, 48) if node_name == "ArchiveHudCoins" else Vector2(64, 48); label.tooltip_text = value; label.accessibility_name = value; _set_normalized_rect(label, rect); hud.add_child(label)

func _archive_button(node_name: String, value: String, action: Callable, active := false) -> Button:
	var button := Button.new()
	button.name = node_name; button.text = value; button.focus_mode = Control.FOCUS_ALL; button.tooltip_text = value; button.accessibility_name = value
	button.add_theme_font_size_override("font_size", 12); button.add_theme_color_override("font_color", Color("f4e6c8")); button.add_theme_color_override("font_disabled_color", Color("b9ad95"))
	button.add_theme_stylebox_override("normal", _archive_button_style(Color("1e2b35"), Color("9f7540")))
	button.add_theme_stylebox_override("hover", _archive_button_style(Color("30414a"), Color("d5ad67")))
	button.add_theme_stylebox_override("pressed", _archive_button_style(Color("493d2d"), Color("f0ca7a")))
	button.add_theme_stylebox_override("focus", _archive_button_style(Color("1e2b35"), Color("75d8dd"), 3))
	button.add_theme_stylebox_override("disabled", _archive_button_style(Color("18232b"), Color("66553b")))
	if active: button.add_theme_stylebox_override("normal", _archive_button_style(Color("5a482f"), Color("e0b45f"), 2))
	if action.is_valid(): button.pressed.connect(action)
	return button

func _archive_button_style(fill: Color, edge: Color, width := 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = fill; style.border_color = edge; style.set_border_width_all(width); style.corner_radius_top_left = 7; style.corner_radius_top_right = 7; style.corner_radius_bottom_left = 7; style.corner_radius_bottom_right = 7; style.content_margin_left = 4; style.content_margin_right = 4; style.content_margin_top = 2; style.content_margin_bottom = 2; return style

func _archive_tile(card: Dictionary, owned: int, chip: String) -> Button:
	var tile := _archive_button("ArchiveTile", "", Callable()); tile.tooltip_text = "%s · %s" % [str(card.get("name", "Card")), chip]; tile.accessibility_name = tile.tooltip_text; tile.add_theme_stylebox_override("normal", _archive_button_style(Color("24333a"), Color("a87a3f"))); tile.add_theme_stylebox_override("hover", _archive_button_style(Color("31464c"), Color("e1b35a"))); tile.add_theme_stylebox_override("focus", _archive_button_style(Color("24333a"), Color("75d8dd"), 3))
	var title := Label.new(); title.name = "ArchiveTileName"; title.text = str(card.get("name", "Card")); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; title.autowrap_mode = TextServer.AUTOWRAP_OFF; title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; title.add_theme_font_size_override("font_size", 11); title.add_theme_color_override("font_color", Color("f4e6c8")); title.mouse_filter = Control.MOUSE_FILTER_IGNORE; title.anchor_left = 0.06; title.anchor_top = 0.03; title.anchor_right = 0.76; title.anchor_bottom = 0.19; tile.add_child(title)
	var cost := Label.new(); cost.name = "ArchiveTileCost"; cost.text = "%dF" % int(card.get("cost", 0)); cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; cost.add_theme_font_size_override("font_size", 9); cost.add_theme_color_override("font_color", Color("f3d995")); cost.mouse_filter = Control.MOUSE_FILTER_IGNORE; cost.anchor_left = 0.77; cost.anchor_top = 0.04; cost.anchor_right = 0.96; cost.anchor_bottom = 0.18; tile.add_child(cost)
	var art := TextureRect.new(); art.name = "ArchiveTileCatalogArt"; art.texture = UNIFIED_CARD_VIEW.art_for_definition(card); art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; art.mouse_filter = Control.MOUSE_FILTER_IGNORE; art.anchor_left = 0.12; art.anchor_top = 0.20; art.anchor_right = 0.88; art.anchor_bottom = 0.75; tile.add_child(art)
	var status := Label.new(); status.name = "ArchiveTileStatus"; status.text = chip; status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; status.autowrap_mode = TextServer.AUTOWRAP_OFF; status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; status.add_theme_font_size_override("font_size", 9); status.add_theme_color_override("font_color", Color("b9e2d4")); status.add_theme_stylebox_override("normal", _archive_button_style(Color("223339"), Color("587e77"), 1)); status.mouse_filter = Control.MOUSE_FILTER_IGNORE; status.anchor_left = 0.08; status.anchor_top = 0.79; status.anchor_right = 0.92; status.anchor_bottom = 0.95; tile.add_child(status)
	return tile

func _archive_category_cards(cards: Array, category: String) -> Array:
	if category == "all": return cards
	var result: Array = []
	for card in cards:
		if str((card as Dictionary).get("type", "")) == category: result.append(card)
	return result

func _archive_detail(main: Control, surface: Control) -> void:
	var id := str(main.unified_inspector_id); var card: Dictionary = RULES.card(id); if card.is_empty(): return
	var detail := PanelContainer.new(); detail.name = "M3ArchiveDetailDrawer"; detail.anchor_left = 0.08; detail.anchor_top = 0.16; detail.anchor_right = 0.92; detail.anchor_bottom = 0.84; surface.add_child(detail); detail.add_theme_stylebox_override("panel", main._visual_style(Color("f1e3c7f8"), Color("6f4d2d"), 12, 3))
	var body := VBoxContainer.new(); body.add_theme_constant_override("separation", 8); detail.add_child(body)
	var close: Button = main._visual_button("Close", "Close", func(): main.unified_inspector_id = ""; main.render(), Color("8a6945")); close.custom_minimum_size = Vector2(56, 56); body.add_child(close)
	body.add_child(main.label(str(card.get("name", id)), 24, Color("352516")))
	var owned := int(GameManager.profile.get("owned_cards", {}).get(id, 0)); var creature := str(card.get("type", "")) == "creature"; body.add_child(main.label("Owned card copies: %d" % owned, 16, Color("513c25")))
	if creature:
		var model_count := int(GameManager.profile.get("printed_models", {}).get(id, 0)); var licensed := RULES.has_printable_blueprint(GameManager.profile, id); body.add_child(main.label("Blueprint license: %s · printed models: %d" % ["permanent" if licensed else "not learned", model_count], 15, Color("513c25"))); body.add_child(main.label("HP %d · BEND %d · Print %d filament" % [int(card.get("hp", 0)), int(card.get("bend", 0)), int(card.get("cost", 0))], 15, Color("513c25")))
		var print_button: Button = main._visual_button("ArchivePrintBlueprint", "Open Forge", func(): main.open_printer(id), Color("b67a38"), licensed); print_button.custom_minimum_size = Vector2(0, 56); print_button.disabled = not licensed; body.add_child(print_button)
	else: body.add_child(main.label("%s · %d filament\n%s" % [str(card.get("type", "support")).capitalize(), int(card.get("cost", 0)), str(card.get("rules_text", card.get("description", "Support card rules are shown in battle.")))], 15, Color("513c25")))

func render_deck(main: Control, surface: Control, margin: Callable, heading: Callable, scroll: Callable) -> void:
	# DK-01 is an authored workbench, rather than an app panel.  All live values
	# stay native, but each control is deliberately seated in its physical recess.
	main._m3_ensure_deck_draft()
	var host := Control.new(); host.name = "M3DeckWorkbench"; host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); surface.add_child(host)
	_deck_hud(main, host)
	var reason := RULES.deck_reason(GameManager.profile, main.unified_deck_draft)
	var selected_id := str(main.get_meta("m3_deck_selected_card_id", ""))
	var owned_cards: Array = []
	for definition in RULES.all_cards():
		var id := str(definition.get("id", ""))
		if int(GameManager.profile.get("owned_cards", {}).get(id, 0)) > 0: owned_cards.append(definition)
	if selected_id.is_empty() or RULES.card(selected_id).is_empty():
		if not main.unified_deck_draft.is_empty(): selected_id = str(main.unified_deck_draft[0])
		elif not owned_cards.is_empty(): selected_id = str((owned_cards[0] as Dictionary).get("id", ""))
		main.set_meta("m3_deck_selected_card_id", selected_id)
	_deck_folio(main, host, selected_id)
	_deck_slot_medallions(main, host)
	_deck_occurrence_tray(main, host, owned_cards, selected_id)
	_deck_inspector(main, host, selected_id, reason)
	_deck_preprint_clamps(main, host)
	_deck_owned_tray(main, host, owned_cards, selected_id)
	if not main.m3_pending_deck_slot_id.is_empty(): _dirty_prompt(main, surface)

func _deck_hud(main: Control, host: Control) -> void:
	var rail := Control.new(); rail.name = "DeckCompactHud"; rail.anchor_left = 0.090; rail.anchor_top = 0.018; rail.anchor_right = 0.920; rail.anchor_bottom = 0.092; host.add_child(rail)
	var back := _deck_button("UnifiedFoundryWorkshopReturn", "Back", main._m3_request_deck_exit); _set_normalized_rect(back, Rect2(0.0, 0.12, 0.12, 0.76)); back.custom_minimum_size = Vector2(54, 48); back.tooltip_text = "Return to Workshop"; back.accessibility_name = back.tooltip_text; rail.add_child(back)
	# Keep XP left of the centred clipboard crest instead of spanning it.
	for entry in [["DeckHudLevel", "Level %d" % int(GameManager.profile.get("level", 1)), Rect2(0.18, 0.10, 0.18, 0.80)], ["DeckHudXp", "XP %d" % int(GameManager.profile.get("spool_xp", 0)), Rect2(0.39, 0.10, 0.16, 0.80)], ["DeckHudCoins", "Coin %d" % int(GameManager.profile.get("forge_coins", 0)), Rect2(0.68, 0.10, 0.30, 0.80)]]:
		var label: Label = main.label(str(entry[1]), 12, Color("f3e5c9")); label.name = str(entry[0]); label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; label.autowrap_mode = TextServer.AUTOWRAP_OFF; label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; label.custom_minimum_size = Vector2(112, 48) if str(entry[0]) == "DeckHudCoins" else Vector2(64, 48); _set_normalized_rect(label, entry[2]); rail.add_child(label)

func _deck_folio(main: Control, host: Control, selected_id: String) -> void:
	var folio := Control.new(); folio.name = "DeckTopEightCardFolio"; folio.clip_contents = true; _set_normalized_rect(folio, Rect2(0.132, 0.112, 0.568, 0.205)); host.add_child(folio)
	var entries: Array = []
	for card_id in main.unified_deck_draft:
		if not str(card_id) in entries: entries.append(str(card_id))
	for index in mini(8, entries.size()):
		var card: Dictionary = RULES.card(str(entries[index])); var tile := _deck_card_tile(card, main.unified_deck_draft.count(str(entries[index])), str(entries[index]) == selected_id); tile.name = "DeckFolioCard%02d" % (index + 1); var column := index % 4; var row := index / 4; _set_normalized_rect(tile, Rect2(0.018 + column * 0.244, 0.045 + row * 0.480, 0.222, 0.425)); tile.pressed.connect(func(): main.set_meta("m3_deck_selected_card_id", str(entries[index])); main.render()); folio.add_child(tile)

func _deck_slot_medallions(main: Control, host: Control) -> void:
	var slots := Control.new(); slots.name = "ArchiveDeckSlots"; _set_normalized_rect(slots, Rect2(0.745, 0.080, 0.190, 0.240)); host.add_child(slots)
	for index in RULES.DECK_SLOTS.size():
		var slot: Dictionary = RULES.DECK_SLOTS[index]
		var id := str(slot.get("id", ""))
		var active := id == str(main.m3_deck_edit_slot_id)
		var slot_name := str(slot.get("name", id))
		var live_reason := RULES.deck_reason(GameManager.profile, main.unified_deck_draft)
		var live_status := "%d · %s" % [main.unified_deck_draft.size(), "LEGAL" if live_reason.is_empty() else live_reason]
		var visible_text := "%s\n%s" % [slot_name, live_status] if active else slot_name
		var pick := _deck_button("ArchiveDeckSlot" + id.capitalize(), visible_text, main._m3_request_deck_slot.bind(id), active)
		pick.autowrap_mode = TextServer.AUTOWRAP_OFF
		pick.add_theme_font_size_override("font_size", 10 if active else 11)
		pick.set_meta("deck_legality_text", live_status if active else "")
		_set_normalized_rect(pick, Rect2(0.08, 0.03 + index * 0.323, 0.84, 0.275)); pick.custom_minimum_size = Vector2(56, 56); pick.tooltip_text = "Edit %s deck slot%s" % [slot_name, " · %s" % live_status if active else ""]; pick.accessibility_name = pick.tooltip_text; slots.add_child(pick)

func _deck_occurrence_tray(main: Control, host: Control, owned_cards: Array, selected_id: String) -> void:
	var tray := ScrollContainer.new(); tray.name = "M3OwnedCardRack"; tray.clip_contents = true; tray.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; tray.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO; _set_normalized_rect(tray, Rect2(0.083, 0.350, 0.624, 0.238)); tray.get_v_scroll_bar().modulate = Color(1, 1, 1, 0); tray.get_v_scroll_bar().mouse_filter = Control.MOUSE_FILTER_IGNORE; host.add_child(tray)
	var rows := VBoxContainer.new(); rows.name = "DeckOccurrenceRows"; rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL; rows.add_theme_constant_override("separation", 4); tray.add_child(rows)
	for definition_variant in owned_cards:
		var definition: Dictionary = definition_variant; var id := str(definition.get("id", "")); var owned := int(GameManager.profile.get("owned_cards", {}).get(id, 0)); var row := HBoxContainer.new(); row.name = "DeckOccurrence" + id.capitalize(); row.custom_minimum_size = Vector2(0, 48); row.add_theme_constant_override("separation", 6); rows.add_child(row)
		var minus := _deck_button("DeckMinus" + id.capitalize(), "−", main._m3_change_deck_occurrence.bind(id, false)); minus.custom_minimum_size = Vector2(48, 48); minus.disabled = main.unified_deck_draft.count(id) <= 0; row.add_child(minus)
		var select := _deck_button("DeckSelect" + id.capitalize(), "%s  ×%d/%d" % [str(definition.get("name", id)), main.unified_deck_draft.count(id), owned], Callable(), id == selected_id); select.size_flags_horizontal = Control.SIZE_EXPAND_FILL; select.custom_minimum_size = Vector2(120, 48); select.tooltip_text = "Inspect %s" % str(definition.get("name", id)); select.accessibility_name = select.tooltip_text; select.pressed.connect(func(): main.set_meta("m3_deck_selected_card_id", id); main.render()); row.add_child(select)
		var plus := _deck_button("DeckPlus" + id.capitalize(), "+", main._m3_change_deck_occurrence.bind(id, true), true); plus.custom_minimum_size = Vector2(48, 48); plus.disabled = main.unified_deck_draft.count(id) >= owned; row.add_child(plus)
	var up := _deck_button("DeckOccurrencePrevious", "↑", func(): tray.scroll_vertical = maxi(0, tray.scroll_vertical - 104)); _set_normalized_rect(up, Rect2(0.055, 0.320, 0.070, 0.040)); up.custom_minimum_size = Vector2(48, 48); up.tooltip_text = "Scroll occurrence tray up"; up.accessibility_name = up.tooltip_text; host.add_child(up)
	var down := _deck_button("DeckOccurrenceNext", "↓", func(): tray.scroll_vertical = mini(int(tray.get_v_scroll_bar().max_value), tray.scroll_vertical + 104)); _set_normalized_rect(down, Rect2(0.620, 0.320, 0.070, 0.040)); down.custom_minimum_size = Vector2(48, 48); down.tooltip_text = "Scroll occurrence tray down"; down.accessibility_name = down.tooltip_text; host.add_child(down)

func _deck_inspector(main: Control, host: Control, selected_id: String, reason: String) -> void:
	var inspector := Control.new(); inspector.name = "DeckPhysicalInspector"; inspector.clip_contents = true; _set_normalized_rect(inspector, Rect2(0.748, 0.350, 0.185, 0.235)); host.add_child(inspector)
	var card := RULES.card(selected_id)
	if not card.is_empty():
		var art := TextureRect.new(); art.name = "DeckInspectorCatalogArt"; art.texture = UNIFIED_CARD_VIEW.art_for_definition(card); art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; art.mouse_filter = Control.MOUSE_FILTER_IGNORE; _set_normalized_rect(art, Rect2(0.14, 0.05, 0.72, 0.50)); inspector.add_child(art)
		var count: Label = main.label("×%d deck" % main.unified_deck_draft.count(selected_id), 11, Color("f3e5c9")); count.name = "DeckInspectorCount"; count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; _set_normalized_rect(count, Rect2(0.04, 0.56, 0.92, 0.18)); inspector.add_child(count)
	var legal: Label = main.label("%d cards · %s" % [main.unified_deck_draft.size(), "LEGAL" if reason.is_empty() else reason], 10, Color("b9e2d4") if reason.is_empty() else Color("f1a59a")); legal.name = "DeckLegalityStatus"; legal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; legal.autowrap_mode = TextServer.AUTOWRAP_OFF; legal.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; _set_normalized_rect(legal, Rect2(0.04, 0.74, 0.92, 0.20)); inspector.add_child(legal)
	var save := _deck_button("SaveActiveDeck", "Save", main._m3_save_deck, true); _set_normalized_rect(save, Rect2(0.748, 0.520, 0.104, 0.057)); save.custom_minimum_size = Vector2(56, 56); save.disabled = not reason.is_empty(); host.add_child(save)
	var save_pre := _deck_button("SavePrePrintLoadout", "Pre-Print", main._m3_save_preprints); _set_normalized_rect(save_pre, Rect2(0.857, 0.520, 0.076, 0.057)); save_pre.custom_minimum_size = Vector2(56, 56); host.add_child(save_pre)

func _deck_preprint_clamps(main: Control, host: Control) -> void:
	var clamps := Control.new(); clamps.name = "M3PrePrintClamps"; _set_normalized_rect(clamps, Rect2(0.070, 0.604, 0.860, 0.203)); host.add_child(clamps)
	for index in 3:
		var available := index < RULES.preprint_slots(GameManager.profile); var card_id := str(main.unified_preprint_draft[index]) if index < main.unified_preprint_draft.size() else ""; var clamp := _deck_transparent_button("PrePrintClamp%d" % (index + 1), main._m3_remove_preprint.bind(index)); _set_normalized_rect(clamp, Rect2(0.015 + index * 0.330, 0.08, 0.305, 0.84)); clamp.custom_minimum_size = Vector2(56, 56); clamp.disabled = not available or card_id.is_empty(); clamp.tooltip_text = "Remove Pre-Print %d" % (index + 1) if not card_id.is_empty() else ("Pre-Print clamp %d is locked" % (index + 1) if not available else "Pre-Print clamp %d is empty" % (index + 1)); clamp.accessibility_name = clamp.tooltip_text; clamps.add_child(clamp)
		var label: Label = main.label("Clamp %d · %s" % [index + 1, "Locked" if not available else (str(RULES.card(card_id).get("name", card_id)) if not card_id.is_empty() else "Empty")], 11, Color("47331f")); label.name = "PrePrintClampLabel%d" % (index + 1); label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.autowrap_mode = TextServer.AUTOWRAP_OFF; label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; label.mouse_filter = Control.MOUSE_FILTER_IGNORE; _set_normalized_rect(label, Rect2(0.045 + index * 0.330, 0.10, 0.245, 0.16)); clamps.add_child(label)
		if not card_id.is_empty():
			var art := TextureRect.new(); art.name = "PrePrintClampArt%d" % (index + 1); art.texture = UNIFIED_CARD_VIEW.art_for_definition(RULES.card(card_id)); art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; art.mouse_filter = Control.MOUSE_FILTER_IGNORE; _set_normalized_rect(art, Rect2(0.08 + index * 0.330, 0.28, 0.18, 0.50)); clamps.add_child(art)

func _deck_owned_tray(main: Control, host: Control, owned_cards: Array, selected_id: String) -> void:
	var tray := ScrollContainer.new(); tray.name = "DeckOwnedArtTray"; tray.clip_contents = true; tray.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO; tray.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; _set_normalized_rect(tray, Rect2(0.075, 0.830, 0.850, 0.115)); tray.get_h_scroll_bar().modulate = Color(1, 1, 1, 0); tray.get_h_scroll_bar().mouse_filter = Control.MOUSE_FILTER_IGNORE; host.add_child(tray)
	var row := HBoxContainer.new(); row.name = "DeckOwnedArtRow"; row.custom_minimum_size = Vector2(maxi(1, owned_cards.size()) * 86, 0); row.add_theme_constant_override("separation", 6); tray.add_child(row)
	for definition_variant in owned_cards:
		var definition: Dictionary = definition_variant; var id := str(definition.get("id", "")); var tile := _deck_card_tile(definition, int(GameManager.profile.get("owned_cards", {}).get(id, 0)), id == selected_id); tile.name = "DeckOwnedCard" + id.capitalize(); tile.custom_minimum_size = Vector2(78, 104); tile.pressed.connect(func(): main.set_meta("m3_deck_selected_card_id", id); main.render()); row.add_child(tile)
	var previous := _deck_button("DeckOwnedPrevious", "‹", func(): tray.scroll_horizontal = maxi(0, tray.scroll_horizontal - 180)); _set_normalized_rect(previous, Rect2(0.025, 0.850, 0.052, 0.062)); previous.custom_minimum_size = Vector2(48, 48); host.add_child(previous)
	var next := _deck_button("DeckOwnedNext", "›", func(): tray.scroll_horizontal = mini(int(tray.get_h_scroll_bar().max_value), tray.scroll_horizontal + 180)); _set_normalized_rect(next, Rect2(0.925, 0.850, 0.052, 0.062)); next.custom_minimum_size = Vector2(48, 48); host.add_child(next)

func _deck_card_tile(card: Dictionary, copies: int, active := false) -> Button:
	var tile := _deck_button("DeckCompactCard", "", Callable(), active); tile.tooltip_text = "%s · %d copies" % [str(card.get("name", "Card")), copies]; tile.accessibility_name = tile.tooltip_text
	var name := Label.new(); name.name = "DeckCardName"; name.text = str(card.get("name", "Card")); name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; name.autowrap_mode = TextServer.AUTOWRAP_OFF; name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; name.add_theme_font_size_override("font_size", 9); name.add_theme_color_override("font_color", Color("f4e6c8")); name.mouse_filter = Control.MOUSE_FILTER_IGNORE; _set_normalized_rect(name, Rect2(0.05, 0.03, 0.90, 0.16)); tile.add_child(name)
	var art := TextureRect.new(); art.name = "DeckCardCatalogArt"; art.texture = UNIFIED_CARD_VIEW.art_for_definition(card); art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; art.mouse_filter = Control.MOUSE_FILTER_IGNORE; _set_normalized_rect(art, Rect2(0.12, 0.20, 0.76, 0.58)); tile.add_child(art)
	var count := Label.new(); count.name = "DeckCardCopies"; count.text = "×%d" % copies; count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; count.add_theme_font_size_override("font_size", 9); count.add_theme_color_override("font_color", Color("f3d995")); count.mouse_filter = Control.MOUSE_FILTER_IGNORE; _set_normalized_rect(count, Rect2(0.15, 0.80, 0.70, 0.15)); tile.add_child(count)
	return tile

func _deck_button(node_name: String, value: String, action: Callable, active := false) -> Button:
	var button := Button.new(); button.name = node_name; button.text = value; button.focus_mode = Control.FOCUS_ALL; button.add_theme_font_size_override("font_size", 11); button.add_theme_color_override("font_color", Color("f4e6c8")); button.add_theme_color_override("font_disabled_color", Color("b9ad95")); button.add_theme_stylebox_override("normal", _archive_button_style(Color("1e2b35"), Color("9f7540"), 2)); button.add_theme_stylebox_override("hover", _archive_button_style(Color("30414a"), Color("d5ad67"), 2)); button.add_theme_stylebox_override("pressed", _archive_button_style(Color("493d2d"), Color("f0ca7a"), 2)); button.add_theme_stylebox_override("focus", _archive_button_style(Color("1e2b35"), Color("75d8dd"), 3)); button.add_theme_stylebox_override("disabled", _archive_button_style(Color("18232b"), Color("66553b"), 2)); if active: button.add_theme_stylebox_override("normal", _archive_button_style(Color("5a482f"), Color("e0b45f"), 3))
	if action.is_valid(): button.pressed.connect(action)
	return button

func _deck_transparent_button(node_name: String, action: Callable) -> Button:
	var button := Button.new(); button.name = node_name; button.text = ""; button.focus_mode = Control.FOCUS_ALL; button.flat = true; button.add_theme_stylebox_override("normal", StyleBoxEmpty.new()); button.add_theme_stylebox_override("hover", StyleBoxEmpty.new()); button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new()); button.add_theme_stylebox_override("focus", _archive_button_style(Color(0, 0, 0, 0), Color("75d8dd"), 3)); button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	if action.is_valid(): button.pressed.connect(action)
	return button

func _dirty_prompt(main: Control, surface: Control) -> void:
	var panel := PanelContainer.new(); panel.name = "M3DeckDirtyPrompt"; panel.anchor_left = 0.08; panel.anchor_top = 0.40; panel.anchor_right = 0.92; panel.anchor_bottom = 0.64; surface.add_child(panel); panel.add_theme_stylebox_override("panel", main._visual_style(Color("f1e3c7fa"), Color("8f2e24"), 10, 3))
	var body := VBoxContainer.new(); panel.add_child(body); body.add_child(main.label("Unsaved deck changes", 19, Color("352516")))
	for entry in [["Save", main._m3_resolve_dirty_deck.bind("save")], ["Discard", main._m3_resolve_dirty_deck.bind("discard")], ["Cancel", main._m3_resolve_dirty_deck.bind("cancel")]]:
		var b: Button = main._visual_button("M3DeckDirty" + str(entry[0]), str(entry[0]), entry[1], Color("b67a38") if str(entry[0]) == "Save" else Color("8a6945")); b.custom_minimum_size = Vector2(0, 56); body.add_child(b)
