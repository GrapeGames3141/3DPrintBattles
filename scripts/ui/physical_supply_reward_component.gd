class_name PhysicalSupplyRewardComponent
extends RefCounted
## Owns native Pack Machine receipt docks over the shared M3 plate.

const RULES := preload("res://scripts/core/unified_rules.gd")
const UNIFIED_CARD_VIEW := preload("res://scripts/ui/unified_card_view.gd")
const CONTROLS := preload("res://scripts/ui/physical_control_family.gd")
const IMPRINT := preload("res://scripts/ui/physical_catalog_imprint.gd")
const NAVIGATION := preload("res://scripts/ui/physical_navigation_component.gd")

func render_market(main: Control, surface: Control, margin: Callable, heading: Callable, scroll: Callable) -> void:
	# MK-01 is a cabinet with six physical cubbies.  Browsing and selecting are
	# local presentation state; only the existing confirmation callback mutates.
	main._m3_prepare_market_once()
	var host := Control.new(); host.name = "M3SupplyCabinet"; host.mouse_filter = Control.MOUSE_FILTER_IGNORE; host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); surface.add_child(host)
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
	var rail := Control.new(); rail.name = "MarketCompactHud"; rail.anchor_left = 0.035; rail.anchor_top = 0.010; rail.anchor_right = 0.965; rail.anchor_bottom = 0.078; host.add_child(rail)
	var back := _market_button("UnifiedFoundryWorkshopReturn", "BACK", main.request_back); _set_normalized_rect(back, Rect2(0.0, 0.0, 0.16, 1.0)); NAVIGATION.configure_back(back, "Workshop"); back.add_theme_font_size_override("font_size", 14); _market_decision_ink(back); rail.add_child(back)
	for entry in [["MarketHudLevel", "Spool %d" % int(GameManager.profile.get("spool_level", 1)), Rect2(0.19, 0.08, 0.20, 0.84)], ["MarketHudXp", "XP %d" % int(GameManager.profile.get("spool_xp", 0)), Rect2(0.43, 0.08, 0.21, 0.84)], ["MarketHudCoins", "Coin %d" % int(GameManager.profile.get("forge_coins", 0)), Rect2(0.68, 0.08, 0.30, 0.84)]]:
		var label: Label = main.label(str(entry[1]), 12, Color("f3e5c9")); label.name = str(entry[0]); label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; label.autowrap_mode = TextServer.AUTOWRAP_OFF; label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; label.custom_minimum_size = Vector2(112, 48) if str(entry[0]) == "MarketHudCoins" else Vector2(64, 48); _set_normalized_rect(label, entry[2]); rail.add_child(label)

func _market_offers(snapshot: Dictionary, tab: String) -> Array:
	var offers: Array = []
	match tab:
		"packs":
			for id_variant in RULES.PACKS:
				var id := str(id_variant); var pack: Dictionary = snapshot.get("packs", {}).get(id, RULES.PACKS[id]); offers.append({"id":id, "name":"%s Pack" % id.capitalize(), "price":int(pack.get("effective_price", pack.get("price", 0))), "consequence":"Open one saved pack after this order is recorded."})
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
	var grid := Control.new(); grid.name = "MarketOfferCubbies"; grid.mouse_filter = Control.MOUSE_FILTER_IGNORE; grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); host.add_child(grid)
	var cubbies := [Rect2(0.105, 0.150, 0.245, 0.175), Rect2(0.377, 0.150, 0.245, 0.175), Rect2(0.650, 0.150, 0.245, 0.175), Rect2(0.105, 0.342, 0.245, 0.175), Rect2(0.377, 0.342, 0.245, 0.175), Rect2(0.650, 0.342, 0.245, 0.175)]
	for index in visible.size():
		var offer: Dictionary = visible[index]; var id := str(offer.get("id", "")); var slot_key := str(offer.get("slot_key", "")); var cubby := Control.new(); cubby.name = "MarketOfferCubby%02d" % (index + 1); cubby.clip_contents = true; _set_normalized_rect(cubby, cubbies[index]); grid.add_child(cubby)
		var tile := _market_offer_tile(offer, slot_key == selected_key); tile.name = "MarketOffer" + id.capitalize() + "Slot%02d" % (index + 1); tile.set_meta("market_offer_slot_key", slot_key); tile.set_meta("market_offer_selected", slot_key == selected_key); tile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); tile.offset_left = 8; tile.offset_top = 8; tile.offset_right = -8; tile.offset_bottom = -8; tile.pressed.connect(func(): main.set_meta("m3_market_selected_offer_key", slot_key); main.m3_market_confirmation.clear(); main.render()); cubby.add_child(tile)

func _market_page_shuttle(main: Control, host: Control, page: int, pages: int) -> void:
	var well := PanelContainer.new(); well.name = "MarketCategoryPageWell"; _set_normalized_rect(well, Rect2(0.080, 0.535, 0.385, 0.075)); well.add_theme_stylebox_override("panel", _pack_style(Color("172b3c"), Color("b88949"), 2)); host.add_child(well)
	# PanelContainer makes every direct child fill its content rect.  Keep one
	# positioned content layer so the two native arrows cannot become a single
	# giant opaque plate over the page label.
	var content := Control.new(); content.name = "MarketCategoryPageContent"; content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); well.add_child(content)
	var previous := _market_button("MarketPagePrevious", "‹", func(): main.set_meta("m3_market_page", maxi(0, page - 1)); main.render()); _set_normalized_rect(previous, Rect2(0.01, 0.03, 0.23, 0.94)); previous.add_theme_font_size_override("font_size", main.scaled_font(22)); previous.custom_minimum_size = Vector2(56, 56); previous.disabled = page <= 0; _market_decision_ink(previous); content.add_child(previous)
	var label: Label = main.label("PAGE %d/%d" % [page + 1, pages], 12, Color("fff0cf")); label.name = "MarketPageIndicator"; label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; label.autowrap_mode = TextServer.AUTOWRAP_OFF; _set_normalized_rect(label, Rect2(0.25, 0.05, 0.50, 0.90)); content.add_child(label)
	var next := _market_button("MarketPageNext", "›", func(): main.set_meta("m3_market_page", mini(pages - 1, page + 1)); main.render()); _set_normalized_rect(next, Rect2(0.76, 0.03, 0.23, 0.94)); next.add_theme_font_size_override("font_size", main.scaled_font(22)); next.custom_minimum_size = Vector2(56, 56); next.disabled = page >= pages - 1; _market_decision_ink(next); content.add_child(next)

func _market_selector_bank(main: Control, host: Control, tab: String) -> void:
	var bank := Control.new(); bank.name = "V3MarketTabs"; _set_normalized_rect(bank, Rect2(0.305, 0.640, 0.420, 0.125)); host.add_child(bank)
	# Levers remain the only hit owners. Their captions sit on this attached rail,
	# clear of both moving hardware and the receipt seam.
	var caption_rail := NinePatchRect.new(); caption_rail.name = "MarketCategoryCaptionRail"; caption_rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rail_source := ResourceLoader.load("res://assets/ui/physical_ui/live-correction-r1/controls/wide_parchment_tab/normal.png") as Texture2D
	caption_rail.texture = rail_source
	caption_rail.patch_margin_left = 16; caption_rail.patch_margin_right = 16
	caption_rail.patch_margin_top = 16; caption_rail.patch_margin_bottom = 16
	caption_rail.draw_center = true; caption_rail.clip_contents = true
	_set_normalized_rect(caption_rail, Rect2(172.0 / 576.0, 776.0 / 1024.0, 1024.0 / 576.0, 152.0 / 1024.0))
	caption_rail.scale = Vector2(0.25, 0.25)
	host.add_child(caption_rail)
	# The physical rail is authored at four-times resolution and is therefore
	# scaled down.  Keep native copy outside that decorative scale so its 12/18px
	# accessibility sizes remain readable instead of inheriting a .25 transform.
	var caption_ink := Control.new()
	caption_ink.name = "MarketCategoryCaptionInk"
	caption_ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption_ink.clip_contents = true
	_set_normalized_rect(caption_ink, Rect2(180.0 / 576.0, 776.0 / 1024.0, 240.0 / 576.0, 38.0 / 1024.0))
	host.add_child(caption_ink)
	# Five 48px selector columns cannot carry the long catalog names at 18px.
	# Keep their compact native nouns readable while tooltip/accessibility preserves
	# the full category name and the existing category IDs/callbacks stay unchanged.
	var entries := [["blueprints", "Plan", "Blueprints"], ["cards", "Card", "Cards"], ["packs", "Pack", "Card Packs"], ["upgrades", "Mod", "Printer Upgrades"], ["cosmetics", "Skin", "Cosmetics"]]
	for index in entries.size():
		var entry: Array = entries[index]
		var id := str(entry[0]); var visible_label := str(entry[1]); var spoken_label := str(entry[2])
		var button := _market_button("MarketTab" + id.capitalize(), "", func(): main.unified_market_tab = id; main.set_meta("m3_market_page", 0); main.set_meta("m3_market_selected_offer_key", ""); main.m3_market_confirmation.clear(); main.render(), id == tab)
		_set_normalized_rect(button, Rect2(index * 0.20, 0.06, 0.20, 1.20)); button.flat = false; button.custom_minimum_size = Vector2(48, 48); button.tooltip_text = "Browse %s" % spoken_label; button.accessibility_name = button.tooltip_text; bank.add_child(button)
		var caption: Label = main.label(visible_label, 12, Color("172b3c")); caption.name = "MarketTabCaption" + id.capitalize(); caption.mouse_filter = Control.MOUSE_FILTER_IGNORE; caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; caption.autowrap_mode = TextServer.AUTOWRAP_OFF; caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; caption.add_theme_color_override("font_color", Color.BLACK if bool(main.settings().get("high_contrast", false)) else Color("172b3c")); _set_normalized_rect(caption, Rect2(index * 0.20, 0.00, 0.20, 1.00)); caption_ink.add_child(caption)
		var underline := ColorRect.new()
		underline.name = "MarketTabInk" + id.capitalize() + "Underline"
		underline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var selected_color := Color.BLACK if bool(main.settings().get("high_contrast", false)) else Color("172b3c")
		var focus_color := Color.WHITE if bool(main.settings().get("high_contrast", false)) else Color("65e3ff")
		underline.color = selected_color if id == tab else Color(0, 0, 0, 0)
		_set_normalized_rect(underline, Rect2(index * 0.20 + 0.04, 34.0 / 38.0, 0.12, 2.0 / 38.0))
		caption_ink.add_child(underline)
		button.focus_entered.connect(func(): underline.color = focus_color)
		button.focus_exited.connect(func(): underline.color = selected_color if id == main.unified_market_tab else Color(0, 0, 0, 0))

func _market_detail_bays(main: Control, host: Control, offer: Dictionary) -> void:
	var detail := Control.new(); detail.name = "MarketSelectedOfferBay"; detail.clip_contents = true; _set_normalized_rect(detail, Rect2(0.032, 0.652, 0.260, 0.190)); host.add_child(detail)
	var purchase := Control.new(); purchase.name = "MarketPurchaseBay"; purchase.clip_contents = true; _set_normalized_rect(purchase, Rect2(0.690, 0.610, 0.275, 0.280)); host.add_child(purchase)
	if offer.is_empty():
		var empty: Label = main.label("No cabinet offer", 12, Color("f3e5c9")); empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; _set_normalized_rect(empty, Rect2(0.05, 0.35, 0.90, 0.25)); detail.add_child(empty); return
	var id := str(offer.get("id", "")); var card := RULES.card(id)
	var selected_header := Panel.new(); selected_header.name = "MarketSelectedHeaderSlip"; selected_header.mouse_filter = Control.MOUSE_FILTER_IGNORE; selected_header.add_theme_stylebox_override("panel", _pack_style(Color("f5e7c8"), Color("b88949"), 1)); _set_normalized_rect(selected_header, Rect2(0.04, 0.035, 0.92, 0.19)); detail.add_child(selected_header)
	var name: Label = main.label(str(offer.get("name", id)), 12, Color("172b3c")); name.name = "MarketSelectedOfferName"; _cream_ink(name); name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; name.autowrap_mode = TextServer.AUTOWRAP_OFF; name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; _set_normalized_rect(name, Rect2(0.05, 0.05, 0.90, 0.18)); detail.add_child(name)
	if not card.is_empty():
		var selected_slip := PanelContainer.new(); selected_slip.name = "MarketSelectedParchmentSlip"; selected_slip.mouse_filter = Control.MOUSE_FILTER_IGNORE; selected_slip.add_theme_stylebox_override("panel", _pack_style(Color("f5e7c8"), Color("b88949"), 1)); _set_normalized_rect(selected_slip, Rect2(0.12, 0.23, 0.76, 0.50)); detail.add_child(selected_slip)
		IMPRINT.add_catalog_art(detail, "MarketSelectedCatalogArt", card, Rect2(0.18, 0.27, 0.64, 0.46), UNIFIED_CARD_VIEW.art_for_definition(card))
	# The selected-offer state has one owner: the right navy purchase well.  Do not
	# repeat it on the lower-left frame where it crosses cabinet hardware.
	var confirmation: Dictionary = main.m3_market_confirmation if main.m3_market_confirmation is Dictionary else {}
	if not confirmation.is_empty():
		var confirm := Control.new(); confirm.name = "M3MarketConfirm"; confirm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); purchase.add_child(confirm)
		var title: Label = main.label("CONFIRM ORDER", 11, Color("f3e5c9")); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; _set_normalized_rect(title, Rect2(0.05, 0.04, 0.90, 0.17)); confirm.add_child(title)
		var copy: Label = main.label("%d coins\n%s" % [int(confirmation.get("price", 0)), str(confirmation.get("consequence", ""))], 9, Color("f3e5c9")); copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; _set_normalized_rect(copy, Rect2(0.06, 0.22, 0.88, 0.35)); confirm.add_child(copy)
		var submit := _market_button("M3MarketConfirmPurchase", "CONFIRM", main._m3_confirm_market_purchase, true); _set_normalized_rect(submit, Rect2(0.05, 0.54, 0.90, 0.25)); submit.custom_minimum_size = Vector2(56, 56); submit.disabled = main.m3_action_in_flight; submit.tooltip_text = "Confirm this exact market order"; submit.accessibility_name = submit.tooltip_text; _market_decision_ink(submit); confirm.add_child(submit)
		var cancel := _market_button("M3MarketCancelPurchase", "CANCEL ORDER", main.request_back); _set_normalized_rect(cancel, Rect2(0.05, 0.80, 0.90, 0.20)); cancel.custom_minimum_size = Vector2(48, 48); cancel.disabled = main.m3_action_in_flight; cancel.tooltip_text = "Order is being recorded. Please wait for this receipt." if main.m3_action_in_flight else "Cancel this order and remain in Market"; cancel.accessibility_name = cancel.tooltip_text; _market_decision_ink(cancel); confirm.add_child(cancel)
	else:
		# Price and availability share one centered instrument block on the right
		# purchase well, rather than two left-biased rows.
		var price: Label = main.label("%d COINS\n%s" % [int(offer.get("price", 0)), _market_offer_cue(id)], 12, Color("f3d995")); price.name = "MarketExactPrice"; price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; price.autowrap_mode = TextServer.AUTOWRAP_OFF; price.tooltip_text = "%d Forge Coins · %s" % [int(offer.get("price", 0)), _market_offer_cue(id)]; price.accessibility_name = price.tooltip_text; _set_normalized_rect(price, Rect2(0.288, 0.190, 0.669, 0.230)); purchase.add_child(price)
		# The lower-right square plate is the purchase affordance.  Keep the native
		# label and hit target inside that plate rather than below it on the cabinet.
		var buy := _market_button("MarketPurchaseSelected", "BUY", main._m3_request_market_purchase.bind(str(main.unified_market_tab), id, int(offer.get("price", 0)), str(offer.get("consequence", ""))), true); _set_normalized_rect(buy, Rect2(0.44, 0.50, 0.36, 0.23)); buy.custom_minimum_size = Vector2(56, 56); buy.add_theme_font_size_override("font_size", main.scaled_font(13)); buy.disabled = main.m3_action_in_flight; buy.tooltip_text = "Purchase %s for %d Forge Coins" % [str(offer.get("name", id)), int(offer.get("price", 0))]; buy.accessibility_name = buy.tooltip_text; _market_decision_ink(buy); purchase.add_child(buy)

func _market_receipt(main: Control, host: Control, tab: String, page: int, pages: int, offer: Dictionary) -> void:
	var strip := PanelContainer.new(); strip.name = "MarketFrozenReceiptStrip"; _set_normalized_rect(strip, Rect2(0.535, 0.535, 0.385, 0.075)); strip.add_theme_stylebox_override("panel", _pack_style(Color("ead9b7"), Color("79582f"), 2)); host.add_child(strip)
	var content := Control.new(); content.name = "MarketFrozenReceiptContent"; content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); strip.add_child(content)
	var label: Label = main.label("%s · FROZEN REV %d" % [tab.capitalize(), int(main.m3_market_revision)], 10, Color("47331f")); label.name = "MarketFrozenRevision"; _cream_ink(label); label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; label.autowrap_mode = TextServer.AUTOWRAP_OFF; label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; _set_normalized_rect(label, Rect2(0.02, 0.08, 0.96, 0.84)); content.add_child(label)

	# The emerging central paper carries the full consequence, leaving the upper
	# long well as a calm frozen-revision fact only.
	var receipt := Control.new(); receipt.name = "MarketConsequenceReceipt"; receipt.clip_contents = true; _set_normalized_rect(receipt, Rect2(0.337, 0.801, 0.335, 0.051)); host.add_child(receipt)
	var consequence: Label = main.label(str(offer.get("consequence", "No selected offer.")), 11, Color("47331f")); consequence.name = "MarketReceiptConsequence"; _cream_ink(consequence); consequence.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; consequence.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; consequence.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; _set_normalized_rect(consequence, Rect2(0.04, 0.08, 0.92, 0.84)); receipt.add_child(consequence)

func _cream_ink(label: Label) -> void:
	# Main.label turns broad high-contrast copy white. These are cream-paper facts,
	# so their semantic navy ink must be the final owner in every contrast mode.
	label.add_theme_color_override("font_color", Color("172b3c"))

func _market_offer_tile(offer: Dictionary, active: bool) -> Button:
	var tile := _market_button("MarketOfferTile", "", Callable(), active); tile.tooltip_text = "%s · %d Forge Coins" % [str(offer.get("name", "Offer")), int(offer.get("price", 0))]; tile.accessibility_name = tile.tooltip_text
	# The approved catalog pilots contain transparent light and dark inks. A native
	# warm-paper slip makes both readable without modifying the source artwork.
	tile.add_theme_stylebox_override("normal", _pack_style(Color("ead9b7f5"), Color("79582f"), 2))
	tile.add_theme_stylebox_override("hover", _pack_style(Color("fff0cf"), Color("1fb9d0"), 3))
	if active:
		var outline := Panel.new(); outline.name = "MarketOfferSelectedOutline"; outline.mouse_filter = Control.MOUSE_FILTER_IGNORE; outline.z_index = 4; outline.anchor_left = 0.01; outline.anchor_top = 0.01; outline.anchor_right = 0.99; outline.anchor_bottom = 0.99; outline.add_theme_stylebox_override("panel", _pack_style(Color(0, 0, 0, 0), Color("37d8ef"), 3)); tile.add_child(outline)
	var header_slip := Panel.new(); header_slip.name = "MarketOfferHeaderSlip"; header_slip.mouse_filter = Control.MOUSE_FILTER_IGNORE; header_slip.add_theme_stylebox_override("panel", _pack_style(Color("f5e7c8"), Color("b88949"), 1)); _set_normalized_rect(header_slip, Rect2(0.06, 0.035, 0.88, 0.17)); tile.add_child(header_slip)
	var name := Label.new(); name.name = "MarketOfferName"; name.text = str(offer.get("name", "Offer")); name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; name.autowrap_mode = TextServer.AUTOWRAP_OFF; name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; name.add_theme_font_size_override("font_size", 11); name.add_theme_color_override("font_color", Color("172b3c")); name.mouse_filter = Control.MOUSE_FILTER_IGNORE; name.z_index = 2; _set_normalized_rect(name, Rect2(0.06, 0.04, 0.88, 0.16)); tile.add_child(name)
	var card := RULES.card(str(offer.get("id", "")))
	if not card.is_empty():
		var art_slip := PanelContainer.new(); art_slip.name = "MarketOfferParchmentSlip"; art_slip.mouse_filter = Control.MOUSE_FILTER_IGNORE; art_slip.add_theme_stylebox_override("panel", _pack_style(Color("f5e7c8"), Color("b88949"), 1)); _set_normalized_rect(art_slip, Rect2(0.13, 0.20, 0.74, 0.54)); tile.add_child(art_slip)
		IMPRINT.add_catalog_art(tile, "MarketOfferCatalogArt", card, Rect2(0.17, 0.23, 0.66, 0.48), UNIFIED_CARD_VIEW.art_for_definition(card))
	var status_slip := Panel.new(); status_slip.name = "MarketOfferStatusSlip"; status_slip.mouse_filter = Control.MOUSE_FILTER_IGNORE; status_slip.add_theme_stylebox_override("panel", _pack_style(Color("f5e7c8"), Color("b88949"), 1)); _set_normalized_rect(status_slip, Rect2(0.06, 0.745, 0.88, 0.19)); tile.add_child(status_slip)
	var price := Label.new(); price.name = "MarketOfferPrice"; price.text = "%d FC" % int(offer.get("price", 0)); price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; price.add_theme_font_size_override("font_size", 10); price.add_theme_color_override("font_color", Color("172b3c")); price.mouse_filter = Control.MOUSE_FILTER_IGNORE; price.z_index = 2; _set_normalized_rect(price, Rect2(0.07, 0.76, 0.44, 0.16)); tile.add_child(price)
	var cue := Label.new(); cue.name = "MarketOfferCue"; cue.text = _market_offer_cue(str(offer.get("id", ""))); cue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; cue.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; cue.autowrap_mode = TextServer.AUTOWRAP_OFF; cue.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; cue.add_theme_font_size_override("font_size", 9); cue.add_theme_color_override("font_color", Color("47331f")); cue.mouse_filter = Control.MOUSE_FILTER_IGNORE; cue.z_index = 2; _set_normalized_rect(cue, Rect2(0.49, 0.76, 0.46, 0.16)); tile.add_child(cue)
	return tile

func _market_offer_cue(id: String) -> String:
	var card := RULES.card(id)
	if id in GameManager.profile.get("wishlist", []): return "PINNED"
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
	# Market master already owns every plate and recess.  These controls are
	# transparent semantic hit layers; only Back receives an explicit shared
	# hardware base through PhysicalNavigation.
	var button := Button.new(); button.name = node_name; button.text = value; button.focus_mode = Control.FOCUS_ALL; button.flat = true; button.add_theme_font_size_override("font_size", 12); CONTROLS.apply(button, "lever", active, true)
	button.add_theme_color_override("font_color", Color("fff0cf")); button.add_theme_color_override("font_hover_color", Color("ffffff")); button.add_theme_color_override("font_pressed_color", Color("ffe0a0")); button.add_theme_color_override("font_focus_color", Color("ffffff"))
	if action.is_valid(): button.pressed.connect(action)
	return button

func _market_decision_ink(button: Button) -> void:
	# Confirm/Cancel sit in dark cabinet hardware.  Explicit state colors avoid
	# inheriting parchment-dark ink from the shared control family at phone scale.
	button.add_theme_color_override("font_color", Color("f3e5c9"))
	button.add_theme_color_override("font_hover_color", Color("ffffff"))
	button.add_theme_color_override("font_pressed_color", Color("fff0bb"))
	button.add_theme_color_override("font_focus_color", Color("ffffff"))
	button.add_theme_color_override("font_disabled_color", Color("aaa69c"))

func _market_transparent_button(node_name: String, value: String, action: Callable, active := false) -> Button:
	var button := Button.new(); button.name = node_name; button.text = value; button.focus_mode = Control.FOCUS_ALL; button.flat = true; button.add_theme_font_size_override("font_size", 12); CONTROLS.apply(button, "lever", active, true)
	if action.is_valid(): button.pressed.connect(action)
	return button

func render_pack(main: Control, surface: Control, margin: Callable, heading: Callable) -> void:
	var pending: Dictionary = GameManager.profile.get("pending_pack_reveal", {}) if GameManager.profile.get("pending_pack_reveal", {}) is Dictionary else {}
	var cards: Array = (pending.get("cards", []) as Array).duplicate(); cards.append_array((pending.get("bonus_cards", []) as Array).duplicate())
	# Keep status copy clear of the final Back hardware on narrow portrait screens.
	var hud := Control.new(); hud.name = "PackCompactHud"; hud.mouse_filter = Control.MOUSE_FILTER_IGNORE; hud.anchor_left = 0.215; hud.anchor_top = 0.022; hud.anchor_right = 0.88; hud.anchor_bottom = 0.072; surface.add_child(hud)
	_pack_hud_label(main, hud, "PackHudLevel", "Spool %d" % int(GameManager.profile.get("spool_level", 1)), Rect2(0.02, 0.0, 0.25, 1.0))
	_pack_hud_label(main, hud, "PackHudXp", "XP %d" % int(GameManager.profile.get("spool_xp", 0)), Rect2(0.37, 0.0, 0.25, 1.0))
	_pack_hud_label(main, hud, "PackHudCoins", "Coin %d" % int(GameManager.profile.get("forge_coins", 0)), Rect2(0.70, 0.0, 0.28, 1.0))
	var strip := PanelContainer.new(); strip.name = "PackReceiptPaperStrip"; strip.anchor_left = 0.105; strip.anchor_top = 0.637; strip.anchor_right = 0.895; strip.anchor_bottom = 0.704; strip.add_theme_stylebox_override("panel", _pack_style(Color("ead9b7"), Color("79582f"), 2)); surface.add_child(strip)
	# PanelContainer owns its one direct content layer.  Keeping labels inside that
	# layer prevents its layout pass from moving the selected-card facts outside
	# the parchment strip on narrow portrait windows.
	var strip_content := Control.new(); strip_content.name = "PackReceiptFactsContent"; strip_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); strip.add_child(strip_content)
	var status: Label = main.label("", 13, Color("47331f")); status.name = "PackReceiptStatus"; _cream_ink(status); status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; status.clip_text = true; status.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); strip_content.add_child(status)
	var docks := Control.new(); docks.name = "UnifiedPackRevealGrid"; docks.mouse_filter = Control.MOUSE_FILTER_IGNORE; docks.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); surface.add_child(docks)
	var dock_rects := [Rect2(0.085, 0.275, 0.255, 0.164), Rect2(0.372, 0.275, 0.255, 0.164), Rect2(0.660, 0.275, 0.255, 0.164), Rect2(0.180, 0.464, 0.255, 0.164), Rect2(0.565, 0.464, 0.255, 0.164)]
	var pages := maxi(1, ceili(cards.size() / 5.0)); main.unified_reveal_page = clampi(main.unified_reveal_page, 0, pages - 1)
	var page_cards := cards.slice(main.unified_reveal_page * 5, mini(cards.size(), (main.unified_reveal_page + 1) * 5))
	for index in page_cards.size():
		var id := str(page_cards[index]); var card: Dictionary = RULES.card(id); var dock := Control.new(); dock.name = "PackReceiptDock%02d" % (index + 1); dock.mouse_filter = Control.MOUSE_FILTER_IGNORE; dock.clip_contents = true; _set_normalized_rect(dock, dock_rects[index]); docks.add_child(dock)
		var tile := _pack_tile(main, card, id == main.m3_pack_inspector_id); tile.name = "UnifiedPackCardView" + id.capitalize(); tile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); tile.offset_left = 8; tile.offset_top = 8; tile.offset_right = -8; tile.offset_bottom = -8; dock.add_child(tile)
	var page_strip := PanelContainer.new(); page_strip.name = "PackReceiptPageStrip"; page_strip.anchor_left = 0.115; page_strip.anchor_top = 0.710; page_strip.anchor_right = 0.885; page_strip.anchor_bottom = 0.745; page_strip.add_theme_stylebox_override("panel", _pack_style(Color("ead9b7"), Color("79582f"), 1)); surface.add_child(page_strip)
	var page_content := Control.new(); page_content.name = "PackReceiptPageContent"; page_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); page_strip.add_child(page_content)
	# The dedicated rail must retain PAGE n/m at 150% instead of competing with
	# receipt prose. Full committed-pack context remains available to native a11y.
	var page_copy: Label = main.label(_pack_progress_copy(pending, main.unified_reveal_page + 1, pages, cards.size()), 12, Color("47331f")); page_copy.name = "UnifiedPackRevealPageCount"; _cream_ink(page_copy); page_copy.tooltip_text = "%s · %d cards · page %d of %d" % [_pack_status(pending), cards.size(), main.unified_reveal_page + 1, pages]; page_copy.accessibility_name = page_copy.tooltip_text; page_copy.mouse_filter = Control.MOUSE_FILTER_IGNORE; page_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; page_copy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; page_copy.autowrap_mode = TextServer.AUTOWRAP_OFF; page_copy.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; page_copy.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); page_content.add_child(page_copy)
	if pages > 1:
		var previous := _pack_button("UnifiedPackRevealPrevious", "‹", func(): main._m3_set_pack_presentation(maxi(0, main.unified_reveal_page - 1), main.m3_pack_inspector_id)); _set_normalized_rect(previous, Rect2(0.105, 0.750, 0.17, 0.062)); previous.custom_minimum_size = Vector2(56, 56); CONTROLS.apply(previous, "square"); previous.add_theme_font_size_override("font_size", main.scaled_font(22)); previous.disabled = main.unified_reveal_page <= 0; surface.add_child(previous)
		var next := _pack_button("UnifiedPackRevealNext", "›", func(): main._m3_set_pack_presentation(mini(pages - 1, main.unified_reveal_page + 1), main.m3_pack_inspector_id)); _set_normalized_rect(next, Rect2(0.725, 0.750, 0.17, 0.062)); next.custom_minimum_size = Vector2(56, 56); CONTROLS.apply(next, "square"); next.add_theme_font_size_override("font_size", main.scaled_font(22)); next.disabled = main.unified_reveal_page >= pages - 1; surface.add_child(next)
	if not main.m3_pack_inspector_id.is_empty():
		var inspected: Dictionary = RULES.card(main.m3_pack_inspector_id)
		if not inspected.is_empty():
			status.text = _pack_inspector_facts(inspected)
			status.tooltip_text = "%s · %s" % [status.text, str(inspected.get("rules_text", inspected.get("description", "")))]
	# The square lower-right plate carries the native label; the circular hardware
	# remains visible and is the transparent hit target below.
	# Main.label applies the player's text scale. Keep this design size unscaled
	# here so the physical pack label stays contained at the 150% accessibility mode.
	var keep_label: Label = main.label("KEEP CARDS", 12, Color("f3d995")); keep_label.name = "PackKeepLabel"; keep_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; keep_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; keep_label.autowrap_mode = TextServer.AUTOWRAP_OFF; keep_label.mouse_filter = Control.MOUSE_FILTER_IGNORE; _set_normalized_rect(keep_label, Rect2(392.0 / 576.0, 933.0 / 1024.0, 130.0 / 576.0, 31.0 / 1024.0)); surface.add_child(keep_label)
	var keep := _pack_physical_action("UnifiedPackRevealKeepCards", main._keep_unified_pack_cards); _set_normalized_rect(keep, Rect2(381.0 / 576.0, 843.0 / 1024.0, 151.0 / 576.0, 137.0 / 1024.0)); keep.custom_minimum_size = Vector2(56, 56); keep.tooltip_text = "Keep this committed receipt"; keep.accessibility_name = keep.tooltip_text; surface.add_child(keep)
	var caller := str(main.m3_pack_return_context.get("caller", main.m3_pack_return_screen)).capitalize()
	var back := _pack_button("UnifiedPackRevealBack", "BACK", main.request_back); _set_normalized_rect(back, Rect2(0.020, 0.014, 0.170, 0.066)); NAVIGATION.configure_back(back, caller, Vector2(72, 56)); CONTROLS.apply(back, "wide"); surface.add_child(back)

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

func _pack_progress_copy(pending: Dictionary, page: int, pages: int, card_count: int) -> String:
	# This is deliberately shorter than the committed-receipt sentence so the
	# physical paper rail retains both receipt identity and page progress at 150%.
	var identity := str(pending.get("pack_id", "pack")).replace("_", " ").to_upper()
	if bool(pending.get("starter_reward", false)):
		var rewards: Dictionary = GameManager.profile.get("starter_pack_rewards", {}) if GameManager.profile.get("starter_pack_rewards", {}) is Dictionary else {}
		var completed := int(rewards.get("opened", 0))
		var ordinal := int(pending.get("starter_opened", completed + 1))
		var entitled := int(rewards.get("entitled", 0))
		identity = "FOUNDER %d/%d" % [clampi(ordinal, 1, maxi(1, entitled)), maxi(1, entitled)]
	return "%s · PAGE %d/%d · %d CARDS" % [identity, page, pages, card_count]

func _pack_button(node_name: String, value: String, action: Callable) -> Button:
	var button := Button.new(); button.name = node_name; button.text = value; button.focus_mode = Control.FOCUS_ALL; button.add_theme_font_size_override("font_size", 14); CONTROLS.apply(button, "binding")
	if action.is_valid(): button.pressed.connect(action)
	return button

func _pack_physical_action(node_name: String, action: Callable) -> Button:
	var button := Button.new(); button.name = node_name; button.text = ""; button.focus_mode = Control.FOCUS_ALL; button.flat = true; button.add_theme_stylebox_override("normal", StyleBoxEmpty.new()); button.add_theme_stylebox_override("hover", StyleBoxEmpty.new()); button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new()); button.add_theme_stylebox_override("focus", _pack_style(Color(0, 0, 0, 0), Color("74d8df"), 4))
	if action.is_valid(): button.pressed.connect(action)
	return button

func _pack_style(fill: Color, edge: Color, width := 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = fill; style.border_color = edge; style.set_border_width_all(width); style.corner_radius_top_left = 8; style.corner_radius_top_right = 8; style.corner_radius_bottom_left = 8; style.corner_radius_bottom_right = 8; style.content_margin_left = 4; style.content_margin_right = 4; style.content_margin_top = 2; style.content_margin_bottom = 2; return style

func _pack_tile(main: Control, card: Dictionary, selected: bool) -> Button:
	var tile := _pack_button("PackReceiptTile", "", func(): main._m3_set_pack_presentation(main.unified_reveal_page, str(card.get("id", "")))); tile.tooltip_text = "%s · inspect committed pack card" % str(card.get("name", "Card")); tile.accessibility_name = tile.tooltip_text
	# Every transparent v2 blueprint ink sits on the same warm paper slip used by
	# Market. Source RGB stays untouched; only the native card facts use dark ink.
	var slip := Panel.new(); slip.name = "PackTileParchmentSlip"; slip.mouse_filter = Control.MOUSE_FILTER_IGNORE; slip.anchor_left = 0.045; slip.anchor_top = 0.025; slip.anchor_right = 0.955; slip.anchor_bottom = 0.975; slip.add_theme_stylebox_override("panel", _pack_style(Color("ead9b7"), Color("79582f"), 2)); tile.add_child(slip)
	if selected:
		var outline := Panel.new(); outline.name = "PackTileSelectedOutline"; outline.mouse_filter = Control.MOUSE_FILTER_IGNORE; outline.anchor_left = 0.01; outline.anchor_top = 0.01; outline.anchor_right = 0.99; outline.anchor_bottom = 0.99; outline.z_index = 4; outline.add_theme_stylebox_override("panel", _pack_style(Color(0, 0, 0, 0), Color("37d8ef"), 3)); tile.add_child(outline)
	var ink := Color("47331f")
	var name := Label.new(); name.name = "PackTileName"; name.text = str(card.get("name", "Card")); name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; name.autowrap_mode = TextServer.AUTOWRAP_OFF; name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; name.add_theme_font_size_override("font_size", main.scaled_font(13)); name.add_theme_color_override("font_color", ink); name.mouse_filter = Control.MOUSE_FILTER_IGNORE; name.z_index = 2; name.anchor_left = 0.06; name.anchor_top = 0.03; name.anchor_right = 0.74; name.anchor_bottom = 0.19; tile.add_child(name)
	var cost := Label.new(); cost.name = "PackTileCost"; cost.text = "%dF" % int(card.get("cost", 0)); cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; cost.add_theme_font_size_override("font_size", main.scaled_font(10)); cost.add_theme_color_override("font_color", ink); cost.mouse_filter = Control.MOUSE_FILTER_IGNORE; cost.z_index = 2; cost.anchor_left = 0.76; cost.anchor_top = 0.04; cost.anchor_right = 0.95; cost.anchor_bottom = 0.19; tile.add_child(cost)
	IMPRINT.add_catalog_art(tile, "PackTileCatalogArt", card, Rect2(0.12, 0.20, 0.76, 0.52), UNIFIED_CARD_VIEW.art_for_definition(card))
	return tile

func _pack_tile_facts(card: Dictionary) -> String:
	var id := str(card.get("id", ""))
	if str(card.get("type", "")) != "creature": return "PERSISTED"
	# Keep these three persisted truths separate.  A rendered blueprint image is
	# never evidence of ownership, a permanent license, or a printed model.
	return "Cards %d\nLicense %s\nModels %d" % [int(GameManager.profile.get("owned_cards", {}).get(id, 0)), "permanent" if RULES.has_printable_blueprint(GameManager.profile, id) else "none", _printed_model_count(id)]

func _pack_inspector_facts(card: Dictionary) -> String:
	var id := str(card.get("id", ""))
	if str(card.get("type", "")) != "creature": return "%s · %d filament\n%s" % [str(card.get("name", id)), int(card.get("cost", 0)), str(card.get("rules_text", card.get("description", "Stored support effect.")))]
	return "%s · Cards %d · License %s\nModels %d" % [str(card.get("name", id)), int(GameManager.profile.get("owned_cards", {}).get(id, 0)), "permanent" if RULES.has_printable_blueprint(GameManager.profile, id) else "none", _printed_model_count(id)]

func _printed_model_count(creature_id: String) -> int:
	var count := 0
	for raw_model in GameManager.profile.get("printed_models", {}).values():
		if raw_model is Dictionary and str((raw_model as Dictionary).get("blueprint_id", "")) == creature_id: count += 1
	return count
