class_name PhysicalArchiveWorkbenchComponent
extends RefCounted
## Owns Collection folio and Deck Workbench controls over the shared M3 plate.

const RULES := preload("res://scripts/core/unified_rules.gd")
const UNIFIED_CARD_VIEW := preload("res://scripts/ui/unified_card_view.gd")
const CONTROLS := preload("res://scripts/ui/physical_control_family.gd")
const IMPRINT := preload("res://scripts/ui/physical_catalog_imprint.gd")
const DECK_INK_SHADER := preload("res://scripts/ui/physical_catalog_imprint.gdshader")
const ARCANE_FOUNDRY_THEME_KIT := preload("res://scripts/ui/arcane_foundry_theme_kit.gd")

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
	# CO-02 owns a dedicated inspection folio.  It is not a modal overlay on the
	# CO-01 grid: rendering both makes cards/facts collide and leaves inactive grid
	# targets beneath the detail leaf.
	if not main.unified_inspector_id.is_empty():
		_archive_detail(main, surface)
		return
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
	var wells := Control.new(); wells.name = "ArchiveLowerPhysicalWells"; wells.mouse_filter = Control.MOUSE_FILTER_IGNORE; wells.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); surface.add_child(wells)
	var rocker := Control.new(); rocker.name = "ArchivePageRocker"; rocker.mouse_filter = Control.MOUSE_FILTER_IGNORE; rocker.clip_contents = true; _set_normalized_rect(rocker, ARCHIVE_PAGE_ROCKER_RECT); wells.add_child(rocker)
	var previous := _archive_button("ArchivePagePrevious", "‹", func(): main.set_meta("m3_archive_page", maxi(0, page - 1)); main.render()); previous.disabled = page <= 0; previous.tooltip_text = "Previous archive page"; previous.anchor_right = 0.50; previous.anchor_bottom = 1.0; previous.custom_minimum_size = Vector2(48, 48); rocker.add_child(previous)
	var next := _archive_button("ArchivePageNext", "›", func(): main.set_meta("m3_archive_page", mini(pages - 1, page + 1)); main.render()); next.disabled = page >= pages - 1; next.tooltip_text = "Next archive page"; next.anchor_left = 0.50; next.anchor_right = 1.0; next.anchor_bottom = 1.0; next.custom_minimum_size = Vector2(48, 48); rocker.add_child(next)
	var owned_well := _archive_button("ArchiveWellOwned", "Owned", func(): main.m3_archive_owned_only = not bool(main.m3_archive_owned_only); main.set_meta("m3_archive_page", 0); main.render(), bool(main.m3_archive_owned_only)); _set_normalized_rect(owned_well, ARCHIVE_BOTTOM_WELLS[0]); owned_well.custom_minimum_size = Vector2(48, 48); wells.add_child(owned_well)
	var printable_well := _archive_button("ArchiveWellPrintable", "Printable", func(): main.m3_archive_printable_only = not bool(main.m3_archive_printable_only); main.set_meta("m3_archive_page", 0); main.render(), bool(main.m3_archive_printable_only)); _set_normalized_rect(printable_well, ARCHIVE_BOTTOM_WELLS[1]); printable_well.custom_minimum_size = Vector2(48, 48); wells.add_child(printable_well)
	var clear_well := _archive_button("ArchiveWellClear", "Clear", func(): main.m3_archive_owned_only = false; main.m3_archive_printable_only = false; main.set_meta("m3_archive_category", "all"); main.set_meta("m3_archive_page", 0); main.render()); _set_normalized_rect(clear_well, ARCHIVE_BOTTOM_WELLS[2]); clear_well.custom_minimum_size = Vector2(48, 48); wells.add_child(clear_well)
	if cards.is_empty():
		var empty: Label = main.label("No cards match these wells. Clear filters to browse.", 15, Color("513c25")); empty.name = "ArchiveEmptyState"; empty.position = Vector2(76, 470); surface.add_child(empty)

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
	button.add_theme_font_size_override("font_size", 12); CONTROLS.apply(button, "binding", active)
	# Archive rail/bottom controls sit directly on navy leather and brass wells.
	# Pale native ink is required there; CO-02's parchment actions explicitly
	# override this through _archive_detail_button.
	button.add_theme_color_override("font_color", Color("f3e5c9"))
	button.add_theme_color_override("font_hover_color", Color("fff4d8"))
	button.add_theme_color_override("font_pressed_color", Color("f3d995"))
	button.add_theme_color_override("font_focus_color", Color("f3e5c9"))
	if action.is_valid(): button.pressed.connect(action)
	return button

func _archive_button_style(fill: Color, edge: Color, width := 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = fill; style.border_color = edge; style.set_border_width_all(width); style.corner_radius_top_left = 7; style.corner_radius_top_right = 7; style.corner_radius_bottom_left = 7; style.corner_radius_bottom_right = 7; style.content_margin_left = 4; style.content_margin_right = 4; style.content_margin_top = 2; style.content_margin_bottom = 2; return style

func _archive_tile(card: Dictionary, owned: int, chip: String) -> Button:
	var tile := _archive_button("ArchiveTile", "", Callable()); tile.tooltip_text = "%s · %s" % [str(card.get("name", "Card")), chip]; tile.accessibility_name = tile.tooltip_text
	var is_creature := str(card.get("type", "")) == "creature"
	# The full dark master well is the outer seat.  This native parchment leaf is
	# deliberately broad enough to read as a filed blueprint page, not a second
	# tiny brass picture plaque pasted into the recess.
	tile.add_theme_stylebox_override("normal", _archive_leaf_style(Color("e5d1a8"), Color("8a6435"), 3))
	tile.add_theme_stylebox_override("hover", _archive_leaf_style(Color("f0dfbb"), Color("b98b46"), 3))
	var pressed_leaf := _archive_leaf_style(Color("d4bc8c"), Color("775128"), 3); pressed_leaf.content_margin_top = 3; tile.add_theme_stylebox_override("pressed", pressed_leaf)
	tile.add_theme_stylebox_override("focus", _archive_leaf_style(Color("e5d1a8"), Color("75d8dd"), 4))
	tile.add_theme_stylebox_override("disabled", _archive_leaf_style(Color("a89575"), Color("66523a"), 2))
	var ink := Color("f3e5c9") if is_creature else Color("47331f")
	var title := Label.new(); title.name = "ArchiveTileName"; title.text = str(card.get("name", "Card")); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; title.autowrap_mode = TextServer.AUTOWRAP_OFF; title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; title.add_theme_font_size_override("font_size", 13); title.add_theme_color_override("font_color", ink); title.mouse_filter = Control.MOUSE_FILTER_IGNORE; title.z_index = 2; title.anchor_left = 0.08; title.anchor_top = 0.05; title.anchor_right = 0.70; title.anchor_bottom = 0.20; tile.add_child(title)
	var cost := Label.new(); cost.name = "ArchiveTileCost"; cost.text = "%dF" % int(card.get("cost", 0)); cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; cost.add_theme_font_size_override("font_size", 10); cost.add_theme_color_override("font_color", Color("47331f")); cost.add_theme_stylebox_override("normal", _archive_leaf_style(Color("d0ad62"), Color("74522c"), 1)); cost.mouse_filter = Control.MOUSE_FILTER_IGNORE; cost.z_index = 2; cost.anchor_left = 0.73; cost.anchor_top = 0.05; cost.anchor_right = 0.94; cost.anchor_bottom = 0.20; tile.add_child(cost)
	if is_creature:
		# The authored blueprint has its own navy perimeter; the dark folio well is
		# its only seat.  Avoid placing a parchment/card face underneath it.
		tile.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		tile.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		tile.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		tile.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
		IMPRINT.add_blueprint_card(tile, "ArchiveTileBlueprintCard", IMPRINT.blueprint_texture(card), Rect2(0.035, 0.025, 0.93, 0.93))
	else:
		IMPRINT.add(tile, "ArchiveTileCatalogArt", UNIFIED_CARD_VIEW.art_for_definition(card), Rect2(0.08, 0.20, 0.84, 0.59), true)
	var status := Label.new(); status.name = "ArchiveTileStatus"; status.text = chip; status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; status.autowrap_mode = TextServer.AUTOWRAP_OFF; status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; status.add_theme_font_size_override("font_size", 10); status.add_theme_color_override("font_color", Color("f4e6c8")); status.add_theme_stylebox_override("normal", _archive_button_style(Color("223339"), Color("587e77"), 1)); status.mouse_filter = Control.MOUSE_FILTER_IGNORE; status.z_index = 2; status.anchor_left = 0.10; status.anchor_top = 0.82; status.anchor_right = 0.90; status.anchor_bottom = 0.95; tile.add_child(status)
	return tile

func _archive_leaf_style(fill: Color, edge: Color, width := 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = fill; style.border_color = edge; style.set_border_width_all(width); style.corner_radius_top_left = 14; style.corner_radius_top_right = 14; style.corner_radius_bottom_left = 14; style.corner_radius_bottom_right = 14; style.content_margin_left = 4; style.content_margin_right = 4; style.content_margin_top = 3; style.content_margin_bottom = 3; return style

func _archive_category_cards(cards: Array, category: String) -> Array:
	if category == "all": return cards
	var result: Array = []
	for card in cards:
		if str((card as Dictionary).get("type", "")) == category: result.append(card)
	return result

func _archive_detail(main: Control, surface: Control) -> void:
	var id := str(main.unified_inspector_id); var card: Dictionary = RULES.card(id)
	# CO-02 already owns the folio/detail composition. Keep every fact/action in its
	# paper apertures instead of introducing an app-style drawer over the master.
	var detail := Control.new(); detail.name = "M3ArchiveDetailApertures"; detail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); detail.clip_contents = true; surface.add_child(detail)
	if card.is_empty():
		# A stale catalog record still owns the CO-02 leaf.  Never fall through to the
		# grid or a generic error panel: the native fallback remains in the authored
		# inspection apertures and gives the player a real Close route.
		var fallback_title: Label = main.label("BLUEPRINT RECORD", 22, Color("47331f")); fallback_title.name = "ArchiveDetailNativeTitle"; fallback_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; _set_normalized_rect(fallback_title, Rect2(0.170, 0.145, 0.660, 0.055)); detail.add_child(fallback_title)
		var fallback_art := Label.new(); fallback_art.name = "ArchiveDetailFallbackMark"; fallback_art.text = "◇"; fallback_art.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; fallback_art.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; fallback_art.add_theme_font_size_override("font_size", 72); fallback_art.add_theme_color_override("font_color", Color("6d5234")); fallback_art.mouse_filter = Control.MOUSE_FILTER_IGNORE; _set_normalized_rect(fallback_art, Rect2(0.165, 0.225, 0.315, 0.355)); detail.add_child(fallback_art)
		var fallback_copy: Label = main.label("This blueprint record is unavailable. Your collection has not changed.", 14, Color("47331f")); fallback_copy.name = "ArchiveDetailNativeFacts"; fallback_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; fallback_copy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; _set_normalized_rect(fallback_copy, Rect2(0.555, 0.265, 0.245, 0.235)); detail.add_child(fallback_copy)
		var fallback_close := _archive_button("ArchiveDetailClose", "Close", func(): main.unified_inspector_id = ""; main.render()); fallback_close.custom_minimum_size = Vector2(56, 56); _set_normalized_rect(fallback_close, Rect2(0.390, 0.760, 0.230, 0.080)); detail.add_child(fallback_close)
		return
	# CO-02 has a dedicated top parchment plaque.  Keep the name wholly in that
	# plaque, then start the left-page art below its leather seam.
	var title: Label = main.label(str(card.get("name", id)), 20, Color("47331f")); title.name = "ArchiveDetailNativeTitle"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; title.autowrap_mode = TextServer.AUTOWRAP_OFF; title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; _set_normalized_rect(title, Rect2(0.185, 0.088, 0.630, 0.052)); detail.add_child(title)
	var creature := str(card.get("type", "")) == "creature"
	if creature:
		# A single complete blueprint card is seated inside the left-page aperture.
		# The right ledger is deliberately outside this rect, so neither card nor
		# native facts can bleed into the other authored page.
		IMPRINT.add_blueprint_card(detail, "ArchiveDetailBlueprintCard", IMPRINT.blueprint_texture(card), Rect2(0.165, 0.225, 0.510, 0.465))
	else:
		IMPRINT.add(detail, "ArchiveDetailCatalogImprint", UNIFIED_CARD_VIEW.art_for_definition(card), Rect2(0.185, 0.235, 0.470, 0.390), true)
	# The four native fact wells line up with the four CO-02 right-hand sockets.
	var facts := Control.new(); facts.name = "ArchiveDetailFacts"; facts.clip_contents = true; _set_normalized_rect(facts, Rect2(0.745, 0.185, 0.175, 0.555)); detail.add_child(facts)
	var owned := int(GameManager.profile.get("owned_cards", {}).get(id, 0))
	if creature:
		var fact_lines := [
			["Owned card copies", str(owned)],
			["Blueprint license", "Permanent" if RULES.has_printable_blueprint(GameManager.profile, id) else "Not learned"],
			["Printed models", str(_printed_model_count(id))],
			["Print facts", "HP %d · B%d · %dF" % [int(card.get("hp", 0)), int(card.get("bend", 0)), int(card.get("cost", 0))]]
		]
		for index in fact_lines.size():
			var line: Array = fact_lines[index]
			# CO-03's divider reaches farther into the right page at 720px.  Give every
			# ledger well a real parchment inset rather than letting its first glyph sit
			# against the binding; the narrower copy width still holds at 576px.
			var well: Label = main.label("%s\n%s" % [str(line[0]), str(line[1])], 10, Color("47331f")); well.name = "ArchiveDetailFact%d" % (index + 1); well.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; well.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; well.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; well.clip_text = true; _set_normalized_rect(well, Rect2(0.15, 0.02 + index * 0.245, 0.70, 0.210)); facts.add_child(well)
	else:
		var facts_label: Label = main.label("Owned copies: %d\n%s · %d filament\n%s" % [owned, str(card.get("type", "support")).capitalize(), int(card.get("cost", 0)), str(card.get("rules_text", card.get("description", "Support card")))], 10, Color("47331f")); facts_label.name = "ArchiveDetailNativeFacts"; facts_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; facts_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; _set_normalized_rect(facts_label, Rect2(0.06, 0.06, 0.88, 0.90)); facts.add_child(facts_label)
	var close := _archive_detail_button("ArchiveDetailClose", "Close", func(): main.unified_inspector_id = ""; main.render()); close.custom_minimum_size = Vector2(56, 56); _set_normalized_rect(close, Rect2(0.185, 0.808, 0.145, 0.080)); detail.add_child(close)
	var deck := _archive_detail_button("ArchiveDetailOpenDeck", "Open Deck", func(): main.set_meta("m3_deck_selected_card_id", id); main.screen = "unified_deck"; main.render(), true); deck.custom_minimum_size = Vector2(56, 56); deck.tooltip_text = "Open the active deck workbench with %s selected" % str(card.get("name", id)); deck.accessibility_name = deck.tooltip_text; _set_normalized_rect(deck, Rect2(0.360, 0.808, 0.235, 0.080)); detail.add_child(deck)
	if creature:
		var licensed := RULES.has_printable_blueprint(GameManager.profile, id); var forge := _archive_detail_button("ArchivePrintBlueprint", "Open Forge", func(): main.open_printer(id), true); forge.custom_minimum_size = Vector2(56, 56); forge.disabled = not licensed; forge.tooltip_text = "Open Forge" if licensed else "Blueprint license required before printing"; forge.accessibility_name = forge.tooltip_text; _set_normalized_rect(forge, Rect2(0.625, 0.808, 0.235, 0.080)); detail.add_child(forge)

func _printed_model_count(creature_id: String) -> int:
	var count := 0
	for raw_model in GameManager.profile.get("printed_models", {}).values():
		if raw_model is Dictionary and str((raw_model as Dictionary).get("blueprint_id", "")) == creature_id: count += 1
	return count

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
		var definition: Dictionary = definition_variant; var id := str(definition.get("id", "")); var owned := int(GameManager.profile.get("owned_cards", {}).get(id, 0)); var row_shell := Panel.new(); row_shell.name = "DeckOccurrencePlate" + id.capitalize(); row_shell.custom_minimum_size = Vector2(0, 48); row_shell.add_theme_stylebox_override("panel", _deck_recess_style()); rows.add_child(row_shell); var row := HBoxContainer.new(); row.name = "DeckOccurrence" + id.capitalize(); row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); row.offset_left = 4; row.offset_right = -4; row.add_theme_constant_override("separation", 6); row_shell.add_child(row)
		var minus := _deck_button("DeckMinus" + id.capitalize(), "−", main._m3_change_deck_occurrence.bind(id, false)); minus.custom_minimum_size = Vector2(48, 48); minus.disabled = main.unified_deck_draft.count(id) <= 0; row.add_child(minus)
		# The center is an input-only target over the dark recess, not another leather
		# rail.  That leaves an uninterrupted native-copy band above the +/- hardware.
		var select := Button.new(); select.name = "DeckSelect" + id.capitalize(); select.text = ""; select.flat = true; select.focus_mode = Control.FOCUS_ALL; CONTROLS.apply(select, "lever", id == selected_id, true); select.size_flags_horizontal = Control.SIZE_EXPAND_FILL; select.custom_minimum_size = Vector2(120, 48); select.tooltip_text = "Inspect %s" % str(definition.get("name", id)); select.accessibility_name = select.tooltip_text; select.pressed.connect(func(): main.set_meta("m3_deck_selected_card_id", id); main.render()); row.add_child(select)
		var plus := _deck_button("DeckPlus" + id.capitalize(), "+", main._m3_change_deck_occurrence.bind(id, true), true); plus.custom_minimum_size = Vector2(48, 48); plus.disabled = main.unified_deck_draft.count(id) >= owned; row.add_child(plus)
		var copy: Label = main.label("%s  ×%d/%d" % [str(definition.get("name", id)), main.unified_deck_draft.count(id), owned], 9, Color("f3e5c9")); copy.name = "DeckOccurrenceCopy" + id.capitalize(); copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; copy.vertical_alignment = VERTICAL_ALIGNMENT_TOP; copy.autowrap_mode = TextServer.AUTOWRAP_OFF; copy.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; copy.mouse_filter = Control.MOUSE_FILTER_IGNORE; copy.z_index = 3; _set_normalized_rect(copy, Rect2(0.225, 0.035, 0.550, 0.285)); row_shell.add_child(copy)
	var up := _deck_button("DeckOccurrencePrevious", "↑", func(): tray.scroll_vertical = maxi(0, tray.scroll_vertical - 104)); _set_normalized_rect(up, Rect2(0.055, 0.320, 0.070, 0.040)); up.custom_minimum_size = Vector2(48, 48); up.tooltip_text = "Scroll occurrence tray up"; up.accessibility_name = up.tooltip_text; host.add_child(up)
	var down := _deck_button("DeckOccurrenceNext", "↓", func(): tray.scroll_vertical = mini(int(tray.get_v_scroll_bar().max_value), tray.scroll_vertical + 104)); _set_normalized_rect(down, Rect2(0.620, 0.320, 0.070, 0.040)); down.custom_minimum_size = Vector2(48, 48); down.tooltip_text = "Scroll occurrence tray down"; down.accessibility_name = down.tooltip_text; host.add_child(down)

func _deck_inspector(main: Control, host: Control, selected_id: String, reason: String) -> void:
	var inspector := Control.new(); inspector.name = "DeckPhysicalInspector"; inspector.clip_contents = true; _set_normalized_rect(inspector, Rect2(0.748, 0.350, 0.185, 0.205)); host.add_child(inspector)
	var card := RULES.card(selected_id)
	if not card.is_empty():
		if str(card.get("type", "")) == "creature":
			_deck_inspector_parchment_sheet(inspector, Rect2(0.08, 0.02, 0.84, 0.48))
			_deck_blueprint_seat(inspector, "DeckInspectorBlueprintSeat", Rect2(0.08, 0.02, 0.84, 0.48))
		var inspector_art := IMPRINT.add_catalog_art(inspector, "DeckInspectorCatalogArt", card, Rect2(0.16, 0.06, 0.68, 0.38), UNIFIED_CARD_VIEW.art_for_definition(card))
		_deck_apply_blueprint_ink(inspector_art, card)
		# The count's fact seat is navy/brass hardware, so it always uses pale ink.
		var count_ink := Color("f3e5c9")
		var count_seat := Panel.new(); count_seat.name = "DeckInspectorCountSeat"; count_seat.mouse_filter = Control.MOUSE_FILTER_IGNORE; count_seat.add_theme_stylebox_override("panel", _deck_fact_style()); _set_normalized_rect(count_seat, Rect2(0.08, 0.50, 0.84, 0.13)); inspector.add_child(count_seat)
		var count: Label = main.label("×%d deck" % main.unified_deck_draft.count(selected_id), 11, count_ink); count.name = "DeckInspectorCount"; count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; _set_normalized_rect(count, Rect2(0.10, 0.51, 0.80, 0.11)); inspector.add_child(count)
	var legal_text := "%d · %s" % [main.unified_deck_draft.size(), "LEGAL" if reason.is_empty() else reason]
	var legal: Label = main.label(legal_text, 11, Color("f3e5c9") if reason.is_empty() else Color("ffd0c8")); legal.name = "DeckLegalityStatus"; legal.tooltip_text = "%d cards · %s" % [main.unified_deck_draft.size(), "legal" if reason.is_empty() else reason]; legal.accessibility_name = legal.tooltip_text; legal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; legal.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; legal.autowrap_mode = TextServer.AUTOWRAP_OFF; legal.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; legal.z_index = 3; legal.add_theme_stylebox_override("normal", _deck_recess_style()); _set_normalized_rect(legal, Rect2(0.04, 0.70, 0.92, 0.18)); inspector.add_child(legal)
	# The two lower-right physical wells are deliberately non-overlapping at 576px;
	# both retain a true 48px global target rather than relying on a narrow label.
	var save_rect := Rect2(0.730, 0.542, 0.118, 0.055)
	# PRE-PRINT is a two-word native action; reserve its full readable keycap
	# width instead of allowing Button minimum sizing to outgrow the visible well.
	var preprint_rect := Rect2(0.850, 0.542, 0.140, 0.055)
	var save := _deck_button("SaveActiveDeck", "Save", main._m3_save_deck, true); _set_normalized_rect(save, save_rect); save.custom_minimum_size = Vector2(56, 56); save.disabled = not reason.is_empty(); save.z_index = 3; host.add_child(save)
	var save_pre := _deck_button("SavePrePrintLoadout", "Pre-Print", main._m3_save_preprints); save_pre.add_theme_font_size_override("font_size", 9); _set_normalized_rect(save_pre, preprint_rect); save_pre.custom_minimum_size = Vector2(56, 56); save_pre.z_index = 3; host.add_child(save_pre)

func _deck_preprint_clamps(main: Control, host: Control) -> void:
	var clamps := Control.new(); clamps.name = "M3PrePrintClamps"; _set_normalized_rect(clamps, Rect2(0.070, 0.604, 0.860, 0.203)); host.add_child(clamps)
	for index in 3:
		var available := index < RULES.preprint_slots(GameManager.profile); var card_id := str(main.unified_preprint_draft[index]) if index < main.unified_preprint_draft.size() else ""
		var selected_id := str(main.get_meta("m3_deck_selected_card_id", "")); var selected: Dictionary = RULES.card(selected_id)
		var eligible: bool = available and str(selected.get("type", "")) == "creature" and main.unified_deck_draft.count(selected_id) > main.unified_preprint_draft.count(selected_id)
		var action: Callable = main._m3_remove_preprint.bind(index) if not card_id.is_empty() else main._m3_add_preprint.bind(selected_id)
		var clamp := _deck_transparent_button("PrePrintClamp%d" % (index + 1), action); _set_normalized_rect(clamp, Rect2(0.015 + index * 0.330, 0.08, 0.305, 0.84)); clamp.custom_minimum_size = Vector2(56, 56); clamp.disabled = not available or (card_id.is_empty() and not eligible); clamp.tooltip_text = "Remove Pre-Print %d" % (index + 1) if not card_id.is_empty() else ("Place %s in Pre-Print %d" % [str(selected.get("name", selected_id)), index + 1] if eligible else ("Pre-Print clamp %d is locked" % (index + 1) if not available else "Select an eligible creature in the deck tray")); clamp.accessibility_name = clamp.tooltip_text; clamps.add_child(clamp)
		var clamp_name := "Locked" if not available else (str(RULES.card(card_id).get("name", card_id)) if not card_id.is_empty() else "Empty")
		# Reserve an uninterrupted two-line header before the blueprint aperture.
		# At 150% the creature name remains a real visible second line rather than
		# being clipped behind the clamp hardware.
		var label: Label = main.label("Clamp %d\n%s" % [index + 1, clamp_name], 9, Color("47331f")); label.name = "PrePrintClampLabel%d" % (index + 1); label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; label.autowrap_mode = TextServer.AUTOWRAP_OFF; label.clip_text = true; label.mouse_filter = Control.MOUSE_FILTER_IGNORE; _set_normalized_rect(label, Rect2(0.035 + index * 0.330, 0.045, 0.265, 0.290)); clamps.add_child(label)
		if not card_id.is_empty():
			var clamp_card: Dictionary = RULES.card(card_id)
			if str(clamp_card.get("type", "")) == "creature": _deck_blueprint_seat(clamps, "PrePrintClampSeat%d" % (index + 1), Rect2(0.065 + index * 0.330, 0.370, 0.210, 0.440))
			var clamp_art := IMPRINT.add_catalog_art(clamps, "PrePrintClampArt%d" % (index + 1), clamp_card, Rect2(0.095 + index * 0.330, 0.415, 0.150, 0.340), UNIFIED_CARD_VIEW.art_for_definition(clamp_card))
			_deck_apply_blueprint_ink(clamp_art, clamp_card)

func _deck_owned_tray(main: Control, host: Control, owned_cards: Array, selected_id: String) -> void:
	var tray := ScrollContainer.new(); tray.name = "DeckOwnedArtTray"; tray.clip_contents = true; tray.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO; tray.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; _set_normalized_rect(tray, Rect2(0.075, 0.830, 0.850, 0.115)); tray.get_h_scroll_bar().modulate = Color(1, 1, 1, 0); tray.get_h_scroll_bar().mouse_filter = Control.MOUSE_FILTER_IGNORE; host.add_child(tray)
	var row := HBoxContainer.new(); row.name = "DeckOwnedArtRow"; row.custom_minimum_size = Vector2(maxi(1, owned_cards.size()) * 86, 0); row.add_theme_constant_override("separation", 6); tray.add_child(row)
	for definition_variant in owned_cards:
		var definition: Dictionary = definition_variant; var id := str(definition.get("id", "")); var tile := _deck_card_tile(definition, int(GameManager.profile.get("owned_cards", {}).get(id, 0)), id == selected_id); tile.name = "DeckOwnedCard" + id.capitalize(); tile.custom_minimum_size = Vector2(78, 104); tile.pressed.connect(func(): main.set_meta("m3_deck_selected_card_id", id); main.render()); row.add_child(tile)
	var previous := _deck_button("DeckOwnedPrevious", "‹", func(): tray.scroll_horizontal = maxi(0, tray.scroll_horizontal - 180)); _set_normalized_rect(previous, Rect2(0.025, 0.850, 0.052, 0.062)); previous.custom_minimum_size = Vector2(48, 48); host.add_child(previous)
	var next := _deck_button("DeckOwnedNext", "›", func(): tray.scroll_horizontal = mini(int(tray.get_h_scroll_bar().max_value), tray.scroll_horizontal + 180)); _set_normalized_rect(next, Rect2(0.925, 0.850, 0.052, 0.062)); next.custom_minimum_size = Vector2(48, 48); host.add_child(next)

func _deck_card_tile(card: Dictionary, copies: int, active := false) -> Button:
	var tile := _deck_button("DeckCompactCard", "", Callable(), active); tile.tooltip_text = "%s · %d copies" % [str(card.get("name", "Card")), copies]; tile.accessibility_name = tile.tooltip_text
	var creature := str(card.get("type", "")) == "creature"
	# Creature blueprints now share the same parchment leaf + recessed lip in each
	# deck context. The approved navy card remains intact, but never floats alone
	# as a sticker; support cards retain their existing treatment.
	var ink := Color("47331f")
	var name := Label.new(); name.name = "DeckCardName"; name.text = str(card.get("name", "Card")); name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; name.autowrap_mode = TextServer.AUTOWRAP_OFF; name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; name.add_theme_font_size_override("font_size", 10); name.add_theme_color_override("font_color", ink); name.mouse_filter = Control.MOUSE_FILTER_IGNORE; name.z_index = 2; _set_normalized_rect(name, Rect2(0.10, 0.04, 0.80, 0.13)); tile.add_child(name)
	if creature: _deck_blueprint_seat(tile, "DeckBlueprintSeat", Rect2(0.07, 0.16, 0.86, 0.66))
	var art := IMPRINT.add_catalog_art(tile, "DeckCardCatalogArt", card, Rect2(0.15, 0.23, 0.70, 0.52), UNIFIED_CARD_VIEW.art_for_definition(card))
	_deck_apply_blueprint_ink(art, card)
	var count := Label.new(); count.name = "DeckCardCopies"; count.text = "×%d" % copies; count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; count.add_theme_font_size_override("font_size", 10); count.add_theme_color_override("font_color", ink); count.mouse_filter = Control.MOUSE_FILTER_IGNORE; count.z_index = 2; _set_normalized_rect(count, Rect2(0.15, 0.84, 0.70, 0.10)); tile.add_child(count)
	return tile

func _deck_button(node_name: String, value: String, action: Callable, active := false) -> Button:
	var button := Button.new(); button.name = node_name; button.text = value; button.focus_mode = Control.FOCUS_ALL; button.add_theme_font_size_override("font_size", 11); CONTROLS.apply(button, "binding", active)
	# Deck actuators and occurrence rails are navy/brass hardware, not parchment.
	# The generic dark control ink was disappearing into their textured faces.
	button.add_theme_color_override("font_color", Color("f3e5c9"))
	button.add_theme_color_override("font_hover_color", Color("fff4d8"))
	button.add_theme_color_override("font_pressed_color", Color("f3d995"))
	button.add_theme_color_override("font_focus_color", Color("f3e5c9"))
	if node_name in ["UnifiedFoundryWorkshopReturn", "SaveActiveDeck", "SavePrePrintLoadout"]:
		var role := "commit" if node_name == "SaveActiveDeck" else "secondary"
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			button.add_theme_stylebox_override(state, _deck_keycap_style(role, state))
	if action.is_valid(): button.pressed.connect(action)
	return button

func _archive_detail_button(node_name: String, value: String, action: Callable, active := false) -> Button:
	var button := _archive_button(node_name, value, action, active)
	# The lower CO-02 control faces are dark brass/binding hardware.  Reuse the
	# pale rail ink so Close, Deck, and Forge remain visible without laying an
	# opaque app panel over the authored tray.
	button.add_theme_color_override("font_color", Color("f3e5c9"))
	button.add_theme_color_override("font_hover_color", Color("fff4d8"))
	button.add_theme_color_override("font_pressed_color", Color("f3d995"))
	button.add_theme_color_override("font_focus_color", Color("f3e5c9"))
	return button

func _deck_transparent_button(node_name: String, action: Callable) -> Button:
	var button := Button.new(); button.name = node_name; button.text = ""; button.focus_mode = Control.FOCUS_ALL; button.flat = true; CONTROLS.apply(button, "lever", false, true)
	if action.is_valid(): button.pressed.connect(action)
	return button

func _deck_recess_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("10232bd8")
	style.border_color = Color("a87938")
	style.set_border_width_all(1)
	style.corner_radius_top_left = 5; style.corner_radius_top_right = 5; style.corner_radius_bottom_left = 5; style.corner_radius_bottom_right = 5
	style.shadow_color = Color(0, 0, 0, 0.55); style.shadow_size = 3; style.shadow_offset = Vector2(1, 2)
	return style

func _deck_blueprint_seat(host: Control, node_name: String, rect: Rect2) -> void:
	# The DK-01 master already supplies each parchment leaf, tray and clamp.  Keep
	# a transparent clipped owner only: a second rounded face made every blueprint
	# look like a pasted card on top of its authored seat.
	var seat := Control.new(); seat.name = node_name; seat.mouse_filter = Control.MOUSE_FILTER_IGNORE; seat.clip_contents = true; seat.z_index = 0; _set_normalized_rect(seat, rect); host.add_child(seat)

func _deck_inspector_parchment_sheet(host: Control, rect: Rect2) -> void:
	# The right inspection pocket is the one Deck seat without authored light paper
	# beneath it.  Use a square, borderless clipped sheet there only; the folio,
	# owned tray and clamps remain direct ink over their existing parchment.
	var sheet := Panel.new()
	sheet.name = "DeckInspectorLooseParchment"
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.clip_contents = true
	sheet.z_index = -1
	var style := StyleBoxFlat.new()
	style.bg_color = Color("e7d4aa")
	sheet.add_theme_stylebox_override("panel", style)
	_set_normalized_rect(sheet, rect)
	host.add_child(sheet)

func _deck_keycap_style(role: String, state: String) -> StyleBox:
	var style: StyleBox = ARCANE_FOUNDRY_THEME_KIT.button(role, state).duplicate()
	# Preserve the 9-slice material over the whole touch target while giving its
	# native text enough interior width to remain readable at 150%.
	style.content_margin_left = 5
	style.content_margin_right = 5
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style

func _deck_fact_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("182f37d8")
	style.border_color = Color("b8833f")
	style.set_border_width_all(1)
	return style

func _deck_apply_blueprint_ink(art: TextureRect, card: Dictionary) -> void:
	# Deck parchment is a separate inspection medium. It tints only transparent
	# creature blueprints through the shared alpha-aware shader; Archive and Forge
	# retain the source-color approved card, and support cards keep their own art.
	if art == null or str(card.get("type", "")) != "creature": return
	var material := ShaderMaterial.new()
	material.shader = DECK_INK_SHADER
	material.set_shader_parameter("ink_tint", Color("47331f"))
	material.set_shader_parameter("ink_strength", 0.74)
	material.set_shader_parameter("remove_dark_matte", false)
	art.material = material
	art.set_meta("deck_blueprint_ink_treatment", true)

func _dirty_prompt(main: Control, surface: Control) -> void:
	# The workbench already has a central docket recess.  Put the decision there as
	# a physical sheet with stamp/tear/retract controls, never a floating app modal.
	var docket := Control.new(); docket.name = "M3DeckDirtyPrompt"; docket.clip_contents = true; _set_normalized_rect(docket, Rect2(0.190, 0.395, 0.550, 0.175)); surface.add_child(docket)
	var title: Label = main.label("UNSAVED DECK DOCKET", 15, Color("47331f")); title.name = "M3DeckDirtyTitle"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; _set_normalized_rect(title, Rect2(0.06, 0.08, 0.88, 0.20)); docket.add_child(title)
	for index in 3:
		var entry: Array = [["Save", main._m3_resolve_dirty_deck.bind("save")], ["Discard", main._m3_resolve_dirty_deck.bind("discard")], ["Cancel", main._m3_resolve_dirty_deck.bind("cancel")]][index]
		var button := _deck_transparent_button("M3DeckDirty" + str(entry[0]), entry[1]); button.text = str(entry[0]).to_upper(); button.custom_minimum_size = Vector2(56, 56); _set_normalized_rect(button, Rect2(0.05 + index * 0.315, 0.42, 0.275, 0.46)); button.tooltip_text = "%s unsaved deck changes" % str(entry[0]); button.accessibility_name = button.tooltip_text; docket.add_child(button)
