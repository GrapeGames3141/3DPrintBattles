class_name PhysicalSupplyRewardComponent
extends RefCounted
## Owns native Pack Machine receipt docks over the shared M3 plate.

const RULES := preload("res://scripts/core/unified_rules.gd")
const UNIFIED_CARD_VIEW := preload("res://scripts/ui/unified_card_view.gd")

func render_market(main: Control, surface: Control, margin: Callable, heading: Callable, scroll: Callable) -> void:
	# MK-01 is a cabinet with six physical cubbies.  Browsing and selecting are
	# local presentation state; only the existing confirmation callback mutates.
	main._m3_prepare_market_once()
	var host := Control.new(); host.name = "M3SupplyCabinet"; host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); surface.add_child(host)
	_market_hud(main, host)
	var snapshot: Dictionary = main.m3_market_snapshot if main.m3_market_snapshot is Dictionary else {}
	var tab := str(main.unified_market_tab)
	var offers := _market_offers(snapshot, tab)
	# A catalog id is not a presentation identity: the same id can occupy more than
	# one frozen offer slot.  Give every visible occurrence a stable slot key so one
	# pressed cubby stays selected without changing purchase rule resolution.
	for index in offers.size():
		var offer: Dictionary = offers[index]
		offer["slot_key"] = "%s:%03d" % [str(offer.get("id", "")), index]
		offers[index] = offer
	var page := clampi(int(main.get_meta("m3_market_page", 0)), 0, maxi(0, ceili(offers.size() / 6.0) - 1)); var pages := maxi(1, ceili(offers.size() / 6.0)); main.set_meta("m3_market_page", page)
	var selected_key := str(main.get_meta("m3_market_selected_offer_key", "")); var visible: Array = offers.slice(page * 6, page * 6 + 6)
	if selected_key.is_empty() or not _market_has_offer_key(offers, selected_key):
		selected_key = str((visible[0] as Dictionary).get("slot_key", "")) if not visible.is_empty() else ""
		main.set_meta("m3_market_selected_offer_key", selected_key)
	var selected: Dictionary = _market_find_offer_key(offers, selected_key)
	_market_offer_cubbies(main, host, visible, selected_key)
	_market_page_shuttle(main, host, page, pages)
	_market_selector_bank(main, host, tab)
	_market_detail_bays(main, host, selected)
	_market_receipt(main, host, tab, page, pages, selected)

func _market_hud(main: Control, host: Control) -> void:
	var rail := Control.new(); rail.name = "MarketCompactHud"; rail.anchor_left = 0.100; rail.anchor_top = 0.015; rail.anchor_right = 0.900; rail.anchor_bottom = 0.073; host.add_child(rail)
	var back := _market_button("UnifiedFoundryWorkshopReturn", "Back", main.navigate_to.bind("workshop")); _set_normalized_rect(back, Rect2(0.0, 0.08, 0.14, 0.84)); back.custom_minimum_size = Vector2(54, 48); back.tooltip_text = "Return to Workshop"; back.accessibility_name = back.tooltip_text; rail.add_child(back)
	for entry in [["MarketHudLevel", "Level %d" % int(GameManager.profile.get("level", 1)), Rect2(0.19, 0.08, 0.20, 0.84)], ["MarketHudXp", "XP %d" % int(GameManager.profile.get("spool_xp", 0)), Rect2(0.43, 0.08, 0.21, 0.84)], ["MarketHudCoins", "Coin %d" % int(GameManager.profile.get("forge_coins", 0)), Rect2(0.68, 0.08, 0.30, 0.84)]]:
		var label: Label = main.label(str(entry[1]), 12, Color("f3e5c9")); label.name = str(entry[0]); label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; label.autowrap_mode = TextServer.AUTOWRAP_OFF; label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; label.custom_minimum_size = Vector2(112, 48) if str(entry[0]) == "MarketHudCoins" else Vector2(64, 48); _set_normalized_rect(label, entry[2]); rail.add_child(label)

func _market_offers(snapshot: Dictionary, tab: String) -> Array:
	var offers: Array = []
	match tab:
		"packs":
			for id_variant in RULES.PACKS:
				var id := str(id_variant); var pack: Dictionary = RULES.PACKS[id]; offers.append({"id":id, "name":"%s Pack" % id.capitalize(), "price":int(pack.get("price", 0)), "consequence":"Commit one persisted pack receipt before its reveal."})
		"upgrades":
			for id_variant in RULES.WORKSHOP_UPGRADES:
				var id := str(id_variant); var upgrade: Dictionary = RULES.WORKSHOP_UPGRADES[id]; offers.append({"id":id, "name":id.replace("_", " ").capitalize(), "price":int(upgrade.get("cost", 0)), "consequence":"Install this existing permanent Workshop upgrade."})
		"cosmetics":
			for id_variant in RULES.COSMETICS:
				var id := str(id_variant); var cosmetic: Dictionary = RULES.COSMETICS[id]; offers.append({"id":id, "name":str(cosmetic.get("name", id)), "price":int(cosmetic.get("coins", 0)), "consequence":"Add this existing cosmetic; it does not change gameplay."})
		_:
			for raw_offer in snapshot.get(tab, []):
				if raw_offer is Dictionary:
					var offer: Dictionary = raw_offer; var id := str(offer.get("id", "")); offers.append({"id":id, "name":str(RULES.card(id).get("name", id.replace("_", " ").capitalize())), "price":int(offer.get("price", offer.get("cost", 0))), "consequence":"Add the offered blueprint license." if tab == "blueprints" else "Add the offered owned card copy."})
	return offers

func _market_offer_cubbies(main: Control, host: Control, visible: Array, selected_key: String) -> void:
	var grid := Control.new(); grid.name = "MarketOfferCubbies"; grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); host.add_child(grid)
	var cubbies := [Rect2(0.105, 0.150, 0.245, 0.175), Rect2(0.377, 0.150, 0.245, 0.175), Rect2(0.650, 0.150, 0.245, 0.175), Rect2(0.105, 0.342, 0.245, 0.175), Rect2(0.377, 0.342, 0.245, 0.175), Rect2(0.650, 0.342, 0.245, 0.175)]
	for index in visible.size():
		var offer: Dictionary = visible[index]; var id := str(offer.get("id", "")); var slot_key := str(offer.get("slot_key", "")); var cubby := Control.new(); cubby.name = "MarketOfferCubby%02d" % (index + 1); cubby.clip_contents = true; _set_normalized_rect(cubby, cubbies[index]); grid.add_child(cubby)
		var tile := _market_offer_tile(offer, slot_key == selected_key); tile.name = "MarketOffer" + id.capitalize() + "Slot%02d" % (index + 1); tile.set_meta("market_offer_slot_key", slot_key); tile.set_meta("market_offer_selected", slot_key == selected_key); tile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); tile.offset_left = 8; tile.offset_top = 8; tile.offset_right = -8; tile.offset_bottom = -8; tile.pressed.connect(func(): main.set_meta("m3_market_selected_offer_key", slot_key); main.m3_market_confirmation.clear(); main.render()); cubby.add_child(tile)

func _market_page_shuttle(main: Control, host: Control, page: int, pages: int) -> void:
	var well := Control.new(); well.name = "MarketCategoryPageWell"; well.clip_contents = true; _set_normalized_rect(well, Rect2(0.080, 0.535, 0.385, 0.075)); host.add_child(well)
	var previous := _market_button("MarketPagePrevious", "‹", func(): main.set_meta("m3_market_page", maxi(0, page - 1)); main.render()); _set_normalized_rect(previous, Rect2(0.00, 0.05, 0.22, 0.90)); previous.custom_minimum_size = Vector2(48, 48); previous.disabled = page <= 0; well.add_child(previous)
	var label: Label = main.label("PAGE %d/%d" % [page + 1, pages], 11, Color("f3e5c9")); label.name = "MarketPageIndicator"; label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; label.autowrap_mode = TextServer.AUTOWRAP_OFF; _set_normalized_rect(label, Rect2(0.24, 0.05, 0.52, 0.90)); well.add_child(label)
	var next := _market_button("MarketPageNext", "›", func(): main.set_meta("m3_market_page", mini(pages - 1, page + 1)); main.render()); _set_normalized_rect(next, Rect2(0.78, 0.05, 0.22, 0.90)); next.custom_minimum_size = Vector2(48, 48); next.disabled = page >= pages - 1; well.add_child(next)

func _market_selector_bank(main: Control, host: Control, tab: String) -> void:
	var bank := Control.new(); bank.name = "V3MarketTabs"; _set_normalized_rect(bank, Rect2(0.305, 0.640, 0.420, 0.125)); host.add_child(bank)
	for index in [["blueprints", "Plans"], ["cards", "Cards"], ["packs", "Packs"], ["upgrades", "Forge"], ["cosmetics", "Style"]].size():
		var entry: Array = [["blueprints", "Plans"], ["cards", "Cards"], ["packs", "Packs"], ["upgrades", "Forge"], ["cosmetics", "Style"]][index]
		var id := str(entry[0]); var visible_label := str(entry[1]); var spoken_label := "Blueprints" if id == "blueprints" else visible_label
		var button := _market_button("MarketTab" + id.capitalize(), visible_label, func(): main.unified_market_tab = id; main.set_meta("m3_market_page", 0); main.set_meta("m3_market_selected_offer_key", ""); main.m3_market_confirmation.clear(); main.render(), id == tab)
		_set_normalized_rect(button, Rect2(index * 0.20, 0.06, 0.20, 0.82)); button.custom_minimum_size = Vector2(48, 48); button.tooltip_text = "Browse %s" % spoken_label; button.accessibility_name = button.tooltip_text; bank.add_child(button)

func _market_detail_bays(main: Control, host: Control, offer: Dictionary) -> void:
	var detail := Control.new(); detail.name = "MarketSelectedOfferBay"; detail.clip_contents = true; _set_normalized_rect(detail, Rect2(0.032, 0.652, 0.260, 0.190)); host.add_child(detail)
	var purchase := Control.new(); purchase.name = "MarketPurchaseBay"; purchase.clip_contents = true; _set_normalized_rect(purchase, Rect2(0.742, 0.652, 0.225, 0.190)); host.add_child(purchase)
	if offer.is_empty():
		var empty: Label = main.label("No cabinet offer", 12, Color("f3e5c9")); empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; _set_normalized_rect(empty, Rect2(0.05, 0.35, 0.90, 0.25)); detail.add_child(empty); return
	var id := str(offer.get("id", "")); var card := RULES.card(id)
	var name: Label = main.label(str(offer.get("name", id)), 12, Color("f3e5c9")); name.name = "MarketSelectedOfferName"; name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; name.autowrap_mode = TextServer.AUTOWRAP_OFF; name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; _set_normalized_rect(name, Rect2(0.05, 0.05, 0.90, 0.18)); detail.add_child(name)
	if not card.is_empty():
		var art := TextureRect.new(); art.name = "MarketSelectedCatalogArt"; art.texture = UNIFIED_CARD_VIEW.art_for_definition(card); art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; art.mouse_filter = Control.MOUSE_FILTER_IGNORE; _set_normalized_rect(art, Rect2(0.18, 0.27, 0.64, 0.52)); detail.add_child(art)
	var cue: Label = main.label(_market_offer_cue(id), 10, Color("b9e2d4")); cue.name = "MarketOfferOwnershipCue"; cue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; cue.autowrap_mode = TextServer.AUTOWRAP_OFF; cue.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; _set_normalized_rect(cue, Rect2(0.04, 0.82, 0.92, 0.14)); detail.add_child(cue)
	var confirmation: Dictionary = main.m3_market_confirmation if main.m3_market_confirmation is Dictionary else {}
	if not confirmation.is_empty():
		var confirm := Control.new(); confirm.name = "M3MarketConfirm"; confirm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); purchase.add_child(confirm)
		var title: Label = main.label("CONFIRM ORDER", 11, Color("f3e5c9")); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; _set_normalized_rect(title, Rect2(0.05, 0.04, 0.90, 0.17)); confirm.add_child(title)
		var copy: Label = main.label("%d coins\n%s" % [int(confirmation.get("price", 0)), str(confirmation.get("consequence", ""))], 9, Color("f3e5c9")); copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; _set_normalized_rect(copy, Rect2(0.06, 0.22, 0.88, 0.35)); confirm.add_child(copy)
		var submit := _market_button("M3MarketConfirmPurchase", "Submitting…" if main.m3_action_in_flight else "Confirm", main._m3_confirm_market_purchase, true); _set_normalized_rect(submit, Rect2(0.06, 0.62, 0.88, 0.22)); submit.custom_minimum_size = Vector2(56, 56); submit.disabled = main.m3_action_in_flight; confirm.add_child(submit)
		var cancel := _market_button("M3MarketCancelPurchase", "Cancel", main._m3_cancel_market_purchase); _set_normalized_rect(cancel, Rect2(0.06, 0.84, 0.88, 0.16)); cancel.custom_minimum_size = Vector2(48, 48); cancel.disabled = main.m3_action_in_flight; confirm.add_child(cancel)
	else:
		var price: Label = main.label("%d COINS" % int(offer.get("price", 0)), 12, Color("f3d995")); price.name = "MarketExactPrice"; price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; _set_normalized_rect(price, Rect2(0.06, 0.15, 0.88, 0.20)); purchase.add_child(price)
		var status: Label = main.label(_market_offer_cue(id), 10, Color("b9e2d4")); status.name = "MarketPurchaseStatus"; status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; status.autowrap_mode = TextServer.AUTOWRAP_OFF; status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; _set_normalized_rect(status, Rect2(0.06, 0.38, 0.88, 0.16)); purchase.add_child(status)
		var buy := _market_transparent_button("MarketPurchaseSelected", "PURCHASE", main._m3_request_market_purchase.bind(str(main.unified_market_tab), id, int(offer.get("price", 0)), str(offer.get("consequence", ""))), true); _set_normalized_rect(buy, Rect2(0.08, 0.64, 0.84, 0.34)); buy.custom_minimum_size = Vector2(56, 56); buy.disabled = main.m3_action_in_flight; buy.tooltip_text = "Purchase %s for %d Forge Coins" % [str(offer.get("name", id)), int(offer.get("price", 0))]; buy.accessibility_name = buy.tooltip_text; purchase.add_child(buy)

func _market_receipt(main: Control, host: Control, tab: String, page: int, pages: int, offer: Dictionary) -> void:
	var strip := PanelContainer.new(); strip.name = "MarketFrozenReceiptStrip"; _set_normalized_rect(strip, Rect2(0.535, 0.535, 0.385, 0.075)); strip.add_theme_stylebox_override("panel", _pack_style(Color("ead9b7"), Color("79582f"), 2)); host.add_child(strip)
	var content := Control.new(); content.name = "MarketFrozenReceiptContent"; content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); strip.add_child(content)
	var label: Label = main.label("%s · FROZEN REV %d" % [tab.capitalize(), int(main.m3_market_revision)], 10, Color("47331f")); label.name = "MarketFrozenRevision"; label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; label.autowrap_mode = TextServer.AUTOWRAP_OFF; label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; _set_normalized_rect(label, Rect2(0.02, 0.08, 0.96, 0.84)); content.add_child(label)
	# The emerging central paper carries the full consequence, leaving the upper
	# long well as a calm frozen-revision fact only.
	var receipt := Control.new(); receipt.name = "MarketConsequenceReceipt"; receipt.clip_contents = true; _set_normalized_rect(receipt, Rect2(0.337, 0.801, 0.335, 0.051)); host.add_child(receipt)
	var consequence: Label = main.label(str(offer.get("consequence", "No selected offer.")), 11, Color("47331f")); consequence.name = "MarketReceiptConsequence"; consequence.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; consequence.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; consequence.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; _set_normalized_rect(consequence, Rect2(0.04, 0.08, 0.92, 0.84)); receipt.add_child(consequence)

func _market_offer_tile(offer: Dictionary, active: bool) -> Button:
	var tile := _market_button("MarketOfferTile", "", Callable(), active); tile.tooltip_text = "%s · %d Forge Coins" % [str(offer.get("name", "Offer")), int(offer.get("price", 0))]; tile.accessibility_name = tile.tooltip_text
	var name := Label.new(); name.name = "MarketOfferName"; name.text = str(offer.get("name", "Offer")); name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; name.autowrap_mode = TextServer.AUTOWRAP_OFF; name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; name.add_theme_font_size_override("font_size", 10); name.add_theme_color_override("font_color", Color("f4e6c8")); name.mouse_filter = Control.MOUSE_FILTER_IGNORE; _set_normalized_rect(name, Rect2(0.06, 0.04, 0.88, 0.16)); tile.add_child(name)
	var card := RULES.card(str(offer.get("id", "")))
	if not card.is_empty():
		var art := TextureRect.new(); art.name = "MarketOfferCatalogArt"; art.texture = UNIFIED_CARD_VIEW.art_for_definition(card); art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; art.mouse_filter = Control.MOUSE_FILTER_IGNORE; _set_normalized_rect(art, Rect2(0.17, 0.23, 0.66, 0.48)); tile.add_child(art)
	var price := Label.new(); price.name = "MarketOfferPrice"; price.text = "%d" % int(offer.get("price", 0)); price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; price.add_theme_font_size_override("font_size", 10); price.add_theme_color_override("font_color", Color("f3d995")); price.mouse_filter = Control.MOUSE_FILTER_IGNORE; _set_normalized_rect(price, Rect2(0.10, 0.76, 0.38, 0.16)); tile.add_child(price)
	var cue := Label.new(); cue.name = "MarketOfferCue"; cue.text = _market_offer_cue(str(offer.get("id", ""))); cue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; cue.autowrap_mode = TextServer.AUTOWRAP_OFF; cue.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; cue.add_theme_font_size_override("font_size", 8); cue.add_theme_color_override("font_color", Color("b9e2d4")); cue.mouse_filter = Control.MOUSE_FILTER_IGNORE; _set_normalized_rect(cue, Rect2(0.50, 0.76, 0.42, 0.16)); tile.add_child(cue)
	return tile

func _market_offer_cue(id: String) -> String:
	var card := RULES.card(id)
	if not card.is_empty() and int(GameManager.profile.get("owned_cards", {}).get(id, 0)) > 0: return "OWNED ×%d" % int(GameManager.profile.get("owned_cards", {}).get(id, 0))
	if bool(GameManager.profile.get("owned_blueprints", {}).get(id, false)): return "LICENSED"
	if id in GameManager.profile.get("workshop_upgrades", []): return "INSTALLED"
	return "AVAILABLE"

func _market_has_offer_key(offers: Array, key: String) -> bool:
	return not _market_find_offer_key(offers, key).is_empty()

func _market_find_offer_key(offers: Array, key: String) -> Dictionary:
	for raw in offers:
		if raw is Dictionary and str((raw as Dictionary).get("slot_key", "")) == key: return (raw as Dictionary).duplicate(true)
	return {}

func _market_button(node_name: String, value: String, action: Callable, active := false) -> Button:
	var button := Button.new(); button.name = node_name; button.text = value; button.focus_mode = Control.FOCUS_ALL; button.add_theme_font_size_override("font_size", 11); button.add_theme_color_override("font_color", Color("f4e6c8")); button.add_theme_color_override("font_disabled_color", Color("b9ad95")); button.add_theme_stylebox_override("normal", _pack_style(Color("1e2b35"), Color("9f7540"), 2)); button.add_theme_stylebox_override("hover", _pack_style(Color("30414a"), Color("d5ad67"), 2)); button.add_theme_stylebox_override("pressed", _pack_style(Color("493d2d"), Color("f0ca7a"), 2)); button.add_theme_stylebox_override("focus", _pack_style(Color("1e2b35"), Color("75d8dd"), 3)); button.add_theme_stylebox_override("disabled", _pack_style(Color("18232b"), Color("66553b"), 2)); if active: button.add_theme_stylebox_override("normal", _pack_style(Color("5a482f"), Color("e0b45f"), 3))
	if action.is_valid(): button.pressed.connect(action)
	return button

func _market_transparent_button(node_name: String, value: String, action: Callable, active := false) -> Button:
	var button := Button.new(); button.name = node_name; button.text = value; button.focus_mode = Control.FOCUS_ALL; button.flat = true; button.add_theme_font_size_override("font_size", 12); button.add_theme_color_override("font_color", Color("f3d995") if active else Color("f4e6c8")); button.add_theme_stylebox_override("normal", StyleBoxEmpty.new()); button.add_theme_stylebox_override("hover", StyleBoxEmpty.new()); button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new()); button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new()); button.add_theme_stylebox_override("focus", _pack_style(Color(0, 0, 0, 0), Color("75d8dd"), 3))
	if action.is_valid(): button.pressed.connect(action)
	return button

func render_pack(main: Control, surface: Control, margin: Callable, heading: Callable) -> void:
	var pending: Dictionary = GameManager.profile.get("pending_pack_reveal", {}) if GameManager.profile.get("pending_pack_reveal", {}) is Dictionary else {}
	var cards: Array = (pending.get("cards", []) as Array).duplicate(); cards.append_array((pending.get("bonus_cards", []) as Array).duplicate())
	var hud := Control.new(); hud.name = "PackCompactHud"; hud.anchor_left = 0.12; hud.anchor_top = 0.022; hud.anchor_right = 0.88; hud.anchor_bottom = 0.072; surface.add_child(hud)
	_pack_hud_label(main, hud, "PackHudLevel", "Level %d" % int(GameManager.profile.get("level", 1)), Rect2(0.02, 0.0, 0.25, 1.0))
	_pack_hud_label(main, hud, "PackHudXp", "XP %d" % int(GameManager.profile.get("spool_xp", 0)), Rect2(0.37, 0.0, 0.25, 1.0))
	_pack_hud_label(main, hud, "PackHudCoins", "Coin %d" % int(GameManager.profile.get("forge_coins", 0)), Rect2(0.70, 0.0, 0.28, 1.0))
	var strip := PanelContainer.new(); strip.name = "PackReceiptPaperStrip"; strip.anchor_left = 0.105; strip.anchor_top = 0.647; strip.anchor_right = 0.895; strip.anchor_bottom = 0.718; strip.add_theme_stylebox_override("panel", _pack_style(Color("ead9b7"), Color("79582f"), 2)); surface.add_child(strip)
	var status: Label = main.label(_pack_status(pending), 13, Color("47331f")); status.name = "PackReceiptStatus"; status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; status.autowrap_mode = TextServer.AUTOWRAP_OFF; status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; strip.add_child(status)
	var docks := Control.new(); docks.name = "UnifiedPackRevealGrid"; docks.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); surface.add_child(docks)
	var dock_rects := [Rect2(0.085, 0.275, 0.255, 0.164), Rect2(0.372, 0.275, 0.255, 0.164), Rect2(0.660, 0.275, 0.255, 0.164), Rect2(0.180, 0.464, 0.255, 0.164), Rect2(0.565, 0.464, 0.255, 0.164)]
	for index in mini(5, cards.size()):
		var id := str(cards[index]); var card: Dictionary = RULES.card(id); var dock := Control.new(); dock.name = "PackReceiptDock%02d" % (index + 1); dock.clip_contents = true; _set_normalized_rect(dock, dock_rects[index]); docks.add_child(dock)
		var tile := _pack_tile(card); tile.name = "UnifiedPackCardView" + id.capitalize(); tile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); tile.offset_left = 8; tile.offset_top = 8; tile.offset_right = -8; tile.offset_bottom = -8; dock.add_child(tile)
	# The square lower-right plate carries the native label; the circular hardware
	# remains visible and is the transparent hit target below.
	var keep_label: Label = main.label("KEEP RECEIPT", 13, Color("f3d995")); keep_label.name = "PackKeepLabel"; keep_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; keep_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; keep_label.mouse_filter = Control.MOUSE_FILTER_IGNORE; keep_label.anchor_left = 0.650; keep_label.anchor_top = 0.804; keep_label.anchor_right = 0.890; keep_label.anchor_bottom = 0.845; surface.add_child(keep_label)
	var keep := _pack_physical_action("UnifiedPackRevealKeepCards", main._keep_unified_pack_cards); keep.anchor_left = 0.650; keep.anchor_top = 0.817; keep.anchor_right = 0.890; keep.anchor_bottom = 0.948; keep.custom_minimum_size = Vector2(56, 56); keep.tooltip_text = "Keep this committed receipt"; keep.accessibility_name = keep.tooltip_text; surface.add_child(keep)

func _set_normalized_rect(node: Control, rect: Rect2) -> void:
	node.anchor_left = rect.position.x; node.anchor_top = rect.position.y; node.anchor_right = rect.end.x; node.anchor_bottom = rect.end.y

func _pack_hud_label(main: Control, hud: Control, node_name: String, value: String, rect: Rect2) -> void:
	var label: Label = main.label(value, 13, Color("f4e7c9")); label.name = node_name; label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; label.autowrap_mode = TextServer.AUTOWRAP_OFF; label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; label.mouse_filter = Control.MOUSE_FILTER_IGNORE; _set_normalized_rect(label, rect); hud.add_child(label)

func _pack_status(pending: Dictionary) -> String:
	var pack_name := str(pending.get("pack_id", "pack")).replace("_", " ").capitalize() + " Pack"
	if bool(pending.get("starter_reward", false)):
		var rewards: Dictionary = GameManager.profile.get("starter_pack_rewards", {}) if GameManager.profile.get("starter_pack_rewards", {}) is Dictionary else {}
		# The receipt carries its own ordinal (`starter_opened`) in current saves;
		# older receipts only have the completed profile count, which needs +1.
		var completed := int(rewards.get("opened", 0)); var ordinal := int(pending.get("starter_opened", completed + 1)); var entitled := int(rewards.get("entitled", 0))
		if entitled > 0: return "%s · PACK %d/%d · COMMITTED" % [pack_name, clampi(ordinal, 1, entitled), entitled]
	return "%s · COMMITTED RECEIPT" % pack_name

func _pack_button(node_name: String, value: String, action: Callable) -> Button:
	var button := Button.new(); button.name = node_name; button.text = value; button.focus_mode = Control.FOCUS_ALL; button.add_theme_font_size_override("font_size", 14); button.add_theme_color_override("font_color", Color("f6e3b4")); button.add_theme_stylebox_override("normal", _pack_style(Color("26333b"), Color("b98b46"), 3)); button.add_theme_stylebox_override("hover", _pack_style(Color("3c4c4d"), Color("f0c76c"), 3)); button.add_theme_stylebox_override("pressed", _pack_style(Color("5a462e"), Color("f7d77b"), 3)); button.add_theme_stylebox_override("focus", _pack_style(Color("26333b"), Color("74d8df"), 4))
	if action.is_valid(): button.pressed.connect(action)
	return button

func _pack_physical_action(node_name: String, action: Callable) -> Button:
	var button := Button.new(); button.name = node_name; button.text = ""; button.focus_mode = Control.FOCUS_ALL; button.flat = true; button.add_theme_stylebox_override("normal", StyleBoxEmpty.new()); button.add_theme_stylebox_override("hover", StyleBoxEmpty.new()); button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new()); button.add_theme_stylebox_override("focus", _pack_style(Color(0, 0, 0, 0), Color("74d8df"), 4))
	if action.is_valid(): button.pressed.connect(action)
	return button

func _pack_style(fill: Color, edge: Color, width := 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = fill; style.border_color = edge; style.set_border_width_all(width); style.corner_radius_top_left = 8; style.corner_radius_top_right = 8; style.corner_radius_bottom_left = 8; style.corner_radius_bottom_right = 8; style.content_margin_left = 4; style.content_margin_right = 4; style.content_margin_top = 2; style.content_margin_bottom = 2; return style

func _pack_tile(card: Dictionary) -> Button:
	var tile := _pack_button("PackReceiptTile", "", Callable()); tile.tooltip_text = "%s · committed pack receipt" % str(card.get("name", "Card")); tile.accessibility_name = tile.tooltip_text; tile.focus_mode = Control.FOCUS_NONE; tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name := Label.new(); name.name = "PackTileName"; name.text = str(card.get("name", "Card")); name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; name.autowrap_mode = TextServer.AUTOWRAP_OFF; name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; name.add_theme_font_size_override("font_size", 11); name.add_theme_color_override("font_color", Color("f4e6c8")); name.mouse_filter = Control.MOUSE_FILTER_IGNORE; name.anchor_left = 0.06; name.anchor_top = 0.03; name.anchor_right = 0.76; name.anchor_bottom = 0.18; tile.add_child(name)
	var cost := Label.new(); cost.name = "PackTileCost"; cost.text = "%dF" % int(card.get("cost", 0)); cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; cost.add_theme_font_size_override("font_size", 9); cost.add_theme_color_override("font_color", Color("f3d995")); cost.mouse_filter = Control.MOUSE_FILTER_IGNORE; cost.anchor_left = 0.77; cost.anchor_top = 0.04; cost.anchor_right = 0.95; cost.anchor_bottom = 0.18; tile.add_child(cost)
	var art := TextureRect.new(); art.name = "PackTileCatalogArt"; art.texture = UNIFIED_CARD_VIEW.art_for_definition(card); art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; art.mouse_filter = Control.MOUSE_FILTER_IGNORE; art.anchor_left = 0.12; art.anchor_top = 0.20; art.anchor_right = 0.88; art.anchor_bottom = 0.75; tile.add_child(art)
	var cue := Label.new(); cue.name = "PackTileCue"; cue.text = "PERSISTED"; cue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; cue.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; cue.autowrap_mode = TextServer.AUTOWRAP_OFF; cue.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; cue.add_theme_font_size_override("font_size", 8); cue.add_theme_color_override("font_color", Color("b9e2d4")); cue.add_theme_stylebox_override("normal", _pack_style(Color("223339"), Color("587e77"), 1)); cue.mouse_filter = Control.MOUSE_FILTER_IGNORE; cue.anchor_left = 0.07; cue.anchor_top = 0.80; cue.anchor_right = 0.93; cue.anchor_bottom = 0.95; tile.add_child(cue)
	return tile
