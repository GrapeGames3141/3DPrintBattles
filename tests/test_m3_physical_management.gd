extends Node

const MAIN := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")
const MANIFEST := preload("res://scripts/core/runtime_asset_manifest.gd")
const MATRIX_PATH := "res://tests/m3_capture_matrix.json"
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if value: return
	failures.append(message)
	push_error(message)

func _ready() -> void:
	var matrix: Variant = JSON.parse_string(FileAccess.get_file_as_string(MATRIX_PATH))
	require(matrix is Dictionary and (matrix.get("standard", []) as Array).size() == 51 and (matrix.get("synthetic_tall", []) as Array).size() == 2, "M3 capture contract declares exactly 51 standard rows including the complete native Title/navigation proofs, plus two tall fixtures.")
	if matrix is Dictionary:
		var matrix_ids: Array = []
		for entry in (matrix.get("standard", []) as Array) + (matrix.get("synthetic_tall", []) as Array):
			if entry is Dictionary: matrix_ids.append(str((entry as Dictionary).get("id", "")))
			require(entry is Dictionary and entry.has("route") and entry.has("fixture_inputs") and entry.has("expected_profile_revision") and entry.has("expected_mutation_count") and entry.has("source_concept") and entry.has("output_pattern"), "Each M3 capture row carries truthful fixture, mutation, concept, and output metadata.")
		require("M3-NV-01" in matrix_ids and "M3-NV-02" in matrix_ids and "M3-NV-03" in matrix_ids and "M3-NV-04" in matrix_ids and "M3-NV-05" in matrix_ids and "M3-AX-03" in matrix_ids, "M3 capture contract includes the completed, confirmation, fresh, settings-round-trip, and accessible Title/navigation proofs.")
	# The bootstrap reads --qa-save-root before this test scene mounts. Reuse that
	# fresh directory instead of reconfiguring to historical shared M3 evidence.
	var root := SaveService.profile_path.get_base_dir().replace("\\", "/")
	require(not root.is_empty() and root != "user:", "M3 management fixture requires a pre-autoload isolated SaveService profile directory.")
	DirAccess.make_dir_recursive_absolute(root)
	SaveService.configure_test_paths(root)
	GameManager.save_compatibility = {"compatible":true, "state":"ready", "message":""}
	var profile := RULES.new_profile()
	profile.forge_coins = 900
	profile = RULES.choose_starter(profile, "cinderpaw").profile
	profile = RULES.print_starter(profile).profile
	GameManager.profile = profile
	var main := MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame
	main.screen = "unified_library"; main.render(); await get_tree().process_frame
	var archive_hud := main.find_child("ArchiveNavyArchHud", true, false)
	var archive_header := main.find_child("ArchiveParchmentHeader", true, false) as Control
	var aperture := main.find_child("ArchiveSixCardApertures", true, false) as Control
	var archive_grid := main.find_child("ArchiveBookCardGrid", true, false)
	var archive_rail := main.find_child("ArchiveMetalCategoryRail", true, false) as ScrollContainer
	var archive_wells := main.find_child("ArchiveLowerPhysicalWells", true, false)
	require(archive_hud != null and archive_header != null and aperture != null and archive_grid != null and archive_rail != null and archive_wells != null, "M3 Collection mounts its navy arch HUD, parchment header, clipped six-card aperture, category rail, and physical wells.")
	var archive_back := main.find_child("ArchiveArchBack", true, false) as Button
	require(is_instance_valid(archive_back) and archive_back.text == "Back" and archive_back.custom_minimum_size.x >= 48.0 and archive_back.custom_minimum_size.y >= 48.0 and archive_back.tooltip_text.contains("Workshop"), "Archive HUD provides a labeled accessible 48px return target.")
	var coin_hud := main.find_child("ArchiveHudCoins", true, false) as Label
	require(is_instance_valid(coin_hud) and coin_hud.text.begins_with("Coin ") and coin_hud.autowrap_mode == TextServer.AUTOWRAP_OFF and coin_hud.custom_minimum_size.x >= 112.0, "Archive HUD keeps the one-line Coin cell wide enough at the 576px reference.")
	var first_well := main.find_child("ArchiveCardWell01", true, false) as Control
	require(archive_grid.get_child_count() == 6 and aperture.clip_contents and is_instance_valid(first_well) and archive_header.anchor_bottom <= first_well.anchor_top, "Archive page seats exactly six cards below the compact header inside clipped authored wells.")
	var well_rects: Array[Rect2] = []
	for index in 6:
		var well := main.find_child("ArchiveCardWell%02d" % (index + 1), true, false) as Control
		require(is_instance_valid(well) and well.clip_contents, "Archive card well %d is an individually clipped physical recess." % (index + 1))
		if is_instance_valid(well): well_rects.append(Rect2(Vector2(well.anchor_left * 576.0, well.anchor_top * 1024.0), Vector2((well.anchor_right - well.anchor_left) * 576.0, (well.anchor_bottom - well.anchor_top) * 1024.0)))
	var unique_wells := {}
	for rect in well_rects: unique_wells["%.0f,%.0f" % [rect.position.x, rect.position.y]] = true
	var measured_wells_ok := well_rects.size() == 6 and unique_wells.size() == 6
	if measured_wells_ok: measured_wells_ok = well_rects[0].position.x >= 108.0 and well_rects[1].position.x >= 298.0 and well_rects[5].end.y <= 752.0
	require(measured_wells_ok, "Archive six wells occupy distinct measured 576px recess positions without crossing the drawer.")
	var rail_previous := main.find_child("ArchiveCategoryRailPrevious", true, false) as Button
	var rail_next := main.find_child("ArchiveCategoryRailNext", true, false) as Button
	require(is_instance_valid(archive_rail) and archive_rail.clip_contents and archive_rail.get_h_scroll_bar().modulate.a == 0.0 and archive_rail.get_h_scroll_bar().mouse_filter == Control.MOUSE_FILTER_IGNORE and is_instance_valid(rail_previous) and is_instance_valid(rail_next) and rail_previous.custom_minimum_size.x >= 48.0 and rail_next.custom_minimum_size.x >= 48.0, "Archive categories hide the generic scrollbar and use 48px brass physical rail shuttles.")
	for category_name in ["All", "Creatures", "Filament", "Spells", "Equipment", "Traps", "Upgrades"]:
		var tab := main.find_child("ArchiveCategory" + category_name.trim_suffix("s"), true, false) as Button
		if category_name == "Creatures": tab = main.find_child("ArchiveCategoryCreature", true, false) as Button
		if category_name == "Spells": tab = main.find_child("ArchiveCategorySpell", true, false) as Button
		if category_name == "Traps": tab = main.find_child("ArchiveCategoryTrap", true, false) as Button
		require(is_instance_valid(tab) and tab.custom_minimum_size.y >= 48.0, "Archive exposes %s as a 48px physical category tab." % category_name)
	var upgrade_tab := main.find_child("ArchiveCategoryUpgrade", true, false) as Button
	if is_instance_valid(upgrade_tab): upgrade_tab.grab_focus()
	await get_tree().process_frame
	require(is_instance_valid(upgrade_tab) and archive_rail.scroll_horizontal > 0, "Keyboard/controller focus on an offscreen archive tab scrolls the clipped rail into view.")
	var rocker := main.find_child("ArchivePageRocker", true, false) as Control
	var previous_page := main.find_child("ArchivePagePrevious", true, false) as Button
	var next_page := main.find_child("ArchivePageNext", true, false) as Button
	require(is_instance_valid(rocker) and rocker.get_child_count() == 2 and previous_page.get_parent() == rocker and next_page.get_parent() == rocker and previous_page.custom_minimum_size.x >= 48.0 and next_page.custom_minimum_size.x >= 48.0, "Archive page controls are two 48px zones inside the authored round rocker.")
	var owned_rect := main.find_child("ArchiveWellOwned", true, false) as Control
	var printable_rect := main.find_child("ArchiveWellPrintable", true, false) as Control
	var clear_rect := main.find_child("ArchiveWellClear", true, false) as Control
	require(is_instance_valid(owned_rect) and is_instance_valid(printable_rect) and is_instance_valid(clear_rect) and int(owned_rect.anchor_left * 576.0) in range(142, 145) and int(printable_rect.anchor_left * 576.0) in range(276, 279) and int(clear_rect.anchor_left * 576.0) in range(411, 414), "Owned, Printable, and Clear map one-to-one to the three authored rectangular wells.")
	for well_name in ["Owned", "Printable", "Clear", "ArchivePagePrevious", "ArchivePageNext"]:
		var well := main.find_child("ArchiveWell" + well_name if well_name in ["Owned", "Printable", "Clear"] else well_name, true, false) as Button
		require(is_instance_valid(well) and well.custom_minimum_size.y >= 48.0, "Archive lower well %s meets the touch target minimum." % well_name)
	main.set_meta("m3_archive_page", 1); main.render(); await get_tree().process_frame
	var second_page := main.find_child("ArchiveBookCardGrid", true, false)
	require(second_page != null and second_page.get_child_count() == 6, "Archive pagination retains six centered card apertures on later pages.")
	var scaled_settings: Dictionary = GameManager.profile.get("settings", {}).duplicate(true)
	scaled_settings["text_scale_bps"] = 15000
	GameManager.profile["settings"] = scaled_settings
	main.render(); await get_tree().process_frame
	archive_header = main.find_child("ArchiveParchmentHeader", true, false) as Control
	first_well = main.find_child("ArchiveCardWell01", true, false) as Control
	coin_hud = main.find_child("ArchiveHudCoins", true, false) as Label
	require(is_instance_valid(archive_header) and is_instance_valid(first_well) and archive_header.anchor_bottom <= first_well.anchor_top and is_instance_valid(coin_hud) and coin_hud.autowrap_mode == TextServer.AUTOWRAP_OFF, "Archive header, wells, and HUD retain separate single-line bands at 150% text.")
	main.set_meta("m3_archive_page", 0); main.render(); await get_tree().process_frame
	var cinder_tile := main.find_child("ArchiveBlueprintCardCinderpaw", true, false) as Button
	var cinder_blueprint := cinder_tile.find_child("ArchiveTileBlueprintCard", true, false) as TextureRect if is_instance_valid(cinder_tile) else null
	require(is_instance_valid(cinder_tile) and is_instance_valid(cinder_blueprint) and cinder_blueprint.texture != null and cinder_blueprint.material == null, "M3 Collection seats the complete preserve-color creature blueprint card rather than a filtered text-only or raw-print tile.")
	main.unified_inspector_id = "cinderpaw"; main.render(); await get_tree().process_frame
	var archive_detail := main.find_child("M3ArchiveDetailApertures", true, false) as Control
	var archive_detail_card := main.find_child("ArchiveDetailBlueprintCard", true, false) as TextureRect
	var archive_detail_facts := main.find_child("ArchiveDetailFacts", true, false) as Control
	require(is_instance_valid(archive_detail) and main.find_child("ArchiveBookCardGrid", true, false) == null and is_instance_valid(archive_detail_card) and archive_detail_card.texture != null and is_instance_valid(archive_detail_facts) and archive_detail_facts.get_child_count() == 4 and main.find_child("ArchiveDetailClose", true, false) != null and main.find_child("ArchiveDetailOpenDeck", true, false) != null and main.find_child("ArchivePrintBlueprint", true, false) != null, "CO-02 exclusively seats one selected blueprint, four native fact sockets, and its real Close/Deck/Forge controls without an active CO-01 grid below it.")
	var first_fact := main.find_child("ArchiveDetailFact1", true, false) as Label
	require(is_instance_valid(first_fact) and first_fact.anchor_left >= 0.14 and first_fact.anchor_right <= 0.86 and first_fact.clip_text, "CO-03 keeps native ledger facts inset from the right-page divider at both portrait widths.")
	main.unified_inspector_id = ""; main.render(); await get_tree().process_frame
	var before := GameManager.profile.duplicate(true)
	main.set_archive_filter("creature")
	require(GameManager.profile == before, "Archive filtering is zero mutation.")
	main.screen = "unified_deck"; main.render(); await get_tree().process_frame
	require(main.find_child("M3DeckWorkbench", true, false) != null and main.find_child("M3PrePrintClamps", true, false) != null and main.find_child("SavePrePrintLoadout", true, false) != null, "M3 Deck mounts three native pre-print clamps and save control.")
	var deck_reason := RULES.deck_reason(GameManager.profile, main.unified_deck_draft)
	var deck_hud_coin := main.find_child("DeckHudCoins", true, false) as Label
	var deck_folio := main.find_child("DeckTopEightCardFolio", true, false) as Control
	var deck_art := main.find_child("DeckCardCatalogArt", true, false) as TextureRect
	var deck_slots := main.find_child("ArchiveDeckSlots", true, false) as Control
	var deck_tray := main.find_child("M3OwnedCardRack", true, false) as ScrollContainer
	var deck_inspector := main.find_child("DeckPhysicalInspector", true, false) as Control
	var deck_clamps := main.find_child("M3PrePrintClamps", true, false) as Control
	var deck_owned_tray := main.find_child("DeckOwnedArtTray", true, false) as Control
	var save_deck := main.find_child("SaveActiveDeck", true, false) as Button
	var save_preprint := main.find_child("SavePrePrintLoadout", true, false) as Button
	var deck_legality := main.find_child("DeckLegalityStatus", true, false) as Label
	var deck_inspector_sheet := main.find_child("DeckInspectorLooseParchment", true, false) as Panel
	var active_deck_medallion: Label = null
	for medallion_variant in deck_slots.get_children() if is_instance_valid(deck_slots) else []:
		var medallion := medallion_variant as Label
		if is_instance_valid(medallion) and medallion.text == "FORGE": active_deck_medallion = medallion
	var active_deck_pick := main.find_child("ArchiveDeckSlotForge", true, false) as Button
	var physical_keycaps := is_instance_valid(save_deck) and is_instance_valid(save_preprint) and save_deck.get_theme_stylebox("normal") is StyleBoxTexture and save_preprint.get_theme_stylebox("normal") is StyleBoxTexture
	require(main.unified_deck_draft.size() >= 40 and deck_reason.is_empty() and is_instance_valid(save_deck) and not save_deck.disabled and physical_keycaps and is_instance_valid(deck_hud_coin) and deck_hud_coin.autowrap_mode == TextServer.AUTOWRAP_OFF and deck_hud_coin.custom_minimum_size.x >= 112.0 and main.find_child("DeckDynamicLegalityPlate", true, false) == null and is_instance_valid(active_deck_medallion) and is_instance_valid(active_deck_pick) and active_deck_pick.custom_minimum_size.y >= 56.0 and str(active_deck_pick.get_meta("deck_legality_text", "")).contains("40 · LEGAL") and is_instance_valid(deck_legality) and deck_legality.text == "40\nLEGAL" and deck_legality.accessibility_name.contains("40 cards") and main.find_child("DeckInspectorCount", true, false) == null and is_instance_valid(deck_inspector_sheet) and deck_inspector_sheet.clip_contents, "M3 Deck keeps the visible Forge caption on its actual cream face while retaining separate accessible full-size slot targets and a readable contained legality fact.")
	var deck_xp := main.find_child("DeckHudXp", true, false) as Label
	require(is_instance_valid(deck_xp) and deck_xp.anchor_right < 0.56 and deck_xp.autowrap_mode == TextServer.AUTOWRAP_OFF, "M3 Deck keeps the XP HUD clear of the centered clipboard crest.")
	require(is_instance_valid(deck_folio) and deck_folio.clip_contents and deck_folio.get_child_count() <= 8 and is_instance_valid(deck_art) and deck_art.texture != null and is_instance_valid(deck_slots) and int(deck_slots.anchor_left * 576.0) >= 428 and int(deck_slots.anchor_right * 576.0) <= 540, "M3 Deck seats up to eight exact-art representative cards in the top folio and all three slot medallions in the authored right rail.")
	require(is_instance_valid(deck_tray) and deck_tray.clip_contents and deck_tray.get_v_scroll_bar().modulate.a == 0.0 and is_instance_valid(deck_inspector) and is_instance_valid(deck_clamps) and deck_clamps.get_child_count() >= 3 and is_instance_valid(deck_owned_tray) and deck_owned_tray.clip_contents and deck_owned_tray.get_child_count() <= 5, "M3 Deck uses clipped physical occurrence, inspector, clamp, and exact five-cell owned-art trays without generic scrollbars.")
	for node_name in ["DeckMinusCinderpaw", "DeckPlusCinderpaw", "DeckOccurrencePrevious", "DeckOccurrenceNext", "DeckOwnedPrevious", "DeckOwnedNext"]:
		var deck_target := main.find_child(node_name, true, false) as Button
		require(is_instance_valid(deck_target) and deck_target.custom_minimum_size.x >= 48.0 and deck_target.custom_minimum_size.y >= 48.0, "M3 Deck physical target %s meets the 48px minimum." % node_name)
	var occurrence_plate := main.find_child("DeckOccurrencePlateCinderpaw", true, false) as Panel
	var occurrence_copy := main.find_child("DeckOccurrenceCopyCinderpaw", true, false) as Label
	var occurrence_select := main.find_child("DeckSelectCinderpaw", true, false) as Button
	require(is_instance_valid(occurrence_plate) and is_instance_valid(occurrence_copy) and is_instance_valid(occurrence_select) and occurrence_copy.mouse_filter == Control.MOUSE_FILTER_IGNORE and occurrence_copy.text.contains("Cinderpaw") and occurrence_copy.anchor_left >= 0.22 and occurrence_copy.anchor_right <= 0.78 and occurrence_copy.anchor_top >= 0.10 and occurrence_copy.anchor_bottom >= 0.80 and occurrence_copy.vertical_alignment == VERTICAL_ALIGNMENT_CENTER and occurrence_select.get_theme_stylebox("normal") is StyleBoxFlat, "M3 Deck centers each occurrence title in the uninterrupted lane between its +/- owners.")
	var first_clamp := main.find_child("PrePrintClamp1", true, false) as Button
	var first_clamp_label := main.find_child("PrePrintClampLabel1", true, false) as Label
	require(is_instance_valid(first_clamp) and first_clamp.custom_minimum_size.x >= 56.0 and is_instance_valid(first_clamp_label) and first_clamp_label.text.begins_with("Clamp 1\n") and first_clamp_label.text.contains("Empty") and first_clamp_label.autowrap_mode == TextServer.AUTOWRAP_OFF and first_clamp_label.anchor_bottom - first_clamp_label.anchor_top >= 0.28 and not first_clamp.disabled and first_clamp.tooltip_text.contains("Place"), "M3 Deck exposes an eligible empty clamp as a visible two-line 56px reachable physical placement action with a native reason.")
	var bottom_deck_tile := main.find_child("DeckOwnedCardCinderpaw", true, false) as Button
	require(is_instance_valid(bottom_deck_tile) and bottom_deck_tile.tooltip_text.contains("Cinderpaw") and bottom_deck_tile.accessibility_name.contains("Cinderpaw"), "M3 Deck exposes the full owned-tray card name through native tooltip and accessibility text when its compact visible label ellipsizes.")
	var owned_cards: Array = []
	for definition in RULES.all_cards():
		if int(GameManager.profile.get("owned_cards", {}).get(str(definition.get("id", "")), 0)) > 0: owned_cards.append(definition)
	var owned_page_count := maxi(1, ceili(owned_cards.size() / 5.0))
	if owned_page_count > 1:
		var owned_next := main.find_child("DeckOwnedNext", true, false) as Button
		require(is_instance_valid(owned_next) and not owned_next.disabled, "M3 Deck exposes a live next-page owner when more than five owned cards exist.")
		owned_next.emit_signal("pressed"); await get_tree().process_frame
		require(int(main.get_meta("m3_deck_owned_page", 0)) == 1, "M3 Deck owned-card next action advances the registered five-cell page.")
	for owned_page in owned_page_count:
		main.set_meta("m3_deck_owned_page", owned_page); main.render(); await get_tree().process_frame
		var expected_owned: Array = owned_cards.slice(owned_page * 5, mini(owned_cards.size(), owned_page * 5 + 5))
		for expected_variant in expected_owned:
			var expected_id := str((expected_variant as Dictionary).get("id", ""))
			require(main.find_child("DeckOwnedCard" + expected_id.capitalize(), true, false) is Button, "M3 Deck page %d retains an inspectable owned-card target for %s." % [owned_page + 1, expected_id])
	main.set_meta("m3_deck_owned_page", 0); main.render(); await get_tree().process_frame
	main.unified_preprint_draft.append("cinderpaw")
	require(main._m3_deck_is_dirty(), "M3 deck dirty state includes unsaved Pre-Print changes.")
	main._m3_request_deck_exit(); await get_tree().process_frame
	var dirty_docket := main.find_child("M3DeckDirtyPrompt", true, false) as Panel
	var dirty_title := main.find_child("M3DeckDirtyTitle", true, false) as Label
	var dirty_save := main.find_child("M3DeckDirtySave", true, false) as Button
	var dirty_discard := main.find_child("M3DeckDirtyDiscard", true, false) as Button
	var dirty_stay := main.find_child("M3DeckDirtyStay", true, false) as Button
	require(is_instance_valid(dirty_docket) and dirty_docket.z_index >= 80 and dirty_docket.mouse_filter == Control.MOUSE_FILTER_STOP and dirty_docket.get_theme_stylebox("panel") is StyleBoxFlat and is_instance_valid(dirty_title) and dirty_title.get_theme_color("font_color") == Color("f3e5c9") and is_instance_valid(dirty_save) and is_instance_valid(dirty_discard) and is_instance_valid(dirty_stay) and dirty_save.text == "SAVE" and dirty_discard.text == "DISCARD" and dirty_stay.text == "STAY" and dirty_save.custom_minimum_size.x >= 48.0 and dirty_discard.custom_minimum_size.x >= 48.0 and dirty_stay.custom_minimum_size.x >= 48.0, "M8 Dirty Deck Back opens one opaque, input-blocking navy docket with pale readable SAVE, DISCARD, and STAY physical decisions.")
	main._m3_resolve_dirty_deck("discard")
	main.screen = "unified_market"; main.render(); await get_tree().process_frame
	require(main.find_child("M3SupplyCabinet", true, false) != null and main.find_child("V3MarketTabs", true, false) != null and not main.m3_market_snapshot.is_empty(), "M3 Market prepares a frozen native snapshot on entry.")
	var market_hud_coin := main.find_child("MarketHudCoins", true, false) as Label
	var market_cubbies := main.find_child("MarketOfferCubbies", true, false) as Control
	var market_receipt := main.find_child("MarketFrozenReceiptStrip", true, false) as Control
	var market_purchase := main.find_child("MarketPurchaseSelected", true, false) as Button
	var market_art := main.find_child("MarketOfferCatalogArt", true, false) as TextureRect
	var market_page_well := main.find_child("MarketCategoryPageWell", true, false) as Control
	var market_revision_label := main.find_child("MarketFrozenRevision", true, false) as Label
	var market_consequence_receipt := main.find_child("MarketConsequenceReceipt", true, false) as Control
	var market_consequence_copy := main.find_child("MarketReceiptConsequence", true, false) as Label
	require(is_instance_valid(market_hud_coin) and market_hud_coin.autowrap_mode == TextServer.AUTOWRAP_OFF and market_hud_coin.custom_minimum_size.x >= 112.0 and is_instance_valid(market_cubbies) and market_cubbies.get_child_count() == 6 and is_instance_valid(market_art) and market_art.texture != null and is_instance_valid(market_receipt) and is_instance_valid(market_purchase) and market_purchase.custom_minimum_size.x >= 56.0 and market_purchase.get_theme_stylebox("pressed") is StyleBoxFlat and is_instance_valid(market_page_well) and int(market_page_well.anchor_top * 1024.0) in range(546, 551) and is_instance_valid(market_revision_label) and market_revision_label.text.begins_with("Blueprints · FROZEN REV") and main.find_child("MarketSelectedCategory", true, false) == null and is_instance_valid(market_consequence_receipt) and market_consequence_receipt.clip_contents and int(market_consequence_receipt.anchor_left * 576.0) in range(193, 196) and int(market_consequence_receipt.anchor_top * 1024.0) in range(819, 822) and int(market_consequence_receipt.anchor_bottom * 1024.0) in range(871, 874) and is_instance_valid(market_consequence_copy) and market_consequence_copy.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART and market_consequence_copy.text.contains("blueprint license"), "M3 Market keeps the upper long well to route/revision only, clips the full dark-ink consequence to the parchment strip, and gives its transparent physical purchase lever a distinct pressed state.")
	for node_name in ["MarketTabBlueprints", "MarketTabCards", "MarketTabPacks", "MarketTabUpgrades", "MarketTabCosmetics"]:
		var market_tab_button := main.find_child(node_name, true, false) as Button
		require(is_instance_valid(market_tab_button) and market_tab_button.custom_minimum_size.x >= 48.0 and market_tab_button.custom_minimum_size.y >= 48.0 and int(market_tab_button.get_parent().anchor_top * 1024.0) in range(653, 658), "M3 Market selector %s is a 48px target in the authored five-position bank." % node_name)
	var market_plans := main.find_child("MarketTabBlueprints", true, false) as Button
	require(is_instance_valid(market_plans) and market_plans.text == "Plans" and market_plans.tooltip_text.contains("Blueprints") and market_plans.accessibility_name.contains("Blueprints"), "M3 Market keeps the concise Plans tab visually while exposing Blueprints in native tooltip and accessibility text.")
	var selected_occurrences := 0
	for market_tile_variant in main.find_children("MarketOffer*Slot*", "Button", true, false):
		var market_tile := market_tile_variant as Button
		if bool(market_tile.get_meta("market_offer_selected", false)): selected_occurrences += 1
	require(selected_occurrences == 1, "M3 Market marks exactly one stable visible offer occurrence selected, independent of catalog id repetition.")
	var blueprint_offers: Array = main.m3_market_snapshot.get("blueprints", []) as Array
	if not blueprint_offers.is_empty() and blueprint_offers[0] is Dictionary:
		var repeated_offer: Dictionary = (blueprint_offers[0] as Dictionary).duplicate(true)
		main.m3_market_snapshot["blueprints"] = [repeated_offer.duplicate(true), repeated_offer.duplicate(true)]
		main.unified_market_tab = "blueprints"; main.set_meta("m3_market_selected_offer_key", ""); main.render(); await get_tree().process_frame
		var repeated_tiles: Array = main.find_children("MarketOffer*Slot*", "Button", true, false)
		if repeated_tiles.size() == 2:
			(repeated_tiles[1] as Button).emit_signal("pressed"); await get_tree().process_frame
			var repeated_selected := 0
			for repeated_tile_variant in main.find_children("MarketOffer*Slot*", "Button", true, false):
				if bool((repeated_tile_variant as Button).get_meta("market_offer_selected", false)): repeated_selected += 1
			require(repeated_selected == 1 and str(main.get_meta("m3_market_selected_offer_key", "")).ends_with(":001"), "M3 Market keys repeated catalog offers by stable visible slot, so selecting the second occurrence never selects both.")
	var market_revision := int(GameManager.profile.get("revision", 0)); main.render(); await get_tree().process_frame
	require(int(GameManager.profile.get("revision", 0)) == market_revision, "M3 Market rerender does not reprepare or mutate its snapshot.")
	main._m3_request_market_purchase("packs", "basic", 100, "Persist one receipt before reveal."); await get_tree().process_frame
	var market_confirm := main.find_child("M3MarketConfirm", true, false) as Control
	var market_submit := main.find_child("M3MarketConfirmPurchase", true, false) as Button
	var market_cancel := main.find_child("M3MarketCancelPurchase", true, false) as Button
	require(is_instance_valid(market_confirm) and market_confirm.get_parent() == main.find_child("MarketPurchaseBay", true, false) and is_instance_valid(market_submit) and market_submit.custom_minimum_size.x >= 56.0 and market_submit.custom_minimum_size.y >= 56.0 and is_instance_valid(market_cancel) and market_cancel.text == "CANCEL ORDER" and market_cancel.custom_minimum_size.x >= 48.0 and market_cancel.custom_minimum_size.y >= 48.0 and int(GameManager.profile.get("revision", 0)) == market_revision, "M8 Market seats separated exact CONFIRM and CANCEL ORDER decisions in the enlarged physical purchase bay without a preview mutation.")
	main._m3_cancel_market_purchase()
	main.screen = "m3_result"; main.m3_result_state = "committed"; main.m3_result_receipt = {"result":"victory", "mode":"daily", "coins":37.0, "xp":12.0, "spool_gained":1.0, "drop":"cinderpaw", "first_clear":true}; main.render(); await get_tree().process_frame
	var receipt_facts := main.find_child("M3ResultAuthoritativeValues", true, false) as Control
	var result_continue := main.find_child("ResultContinue", true, false) as Button
	var result_status := main.find_child("M3ResultSettlementStatus", true, false) as Label
	var result_drop := main.find_child("M3ResultDropBlueprintCard", true, false) as TextureRect
	var result_xp := main.find_child("ResultHudXp", true, false) as Label
	var result_bay_value := main.find_child("M3ResultBayValue", true, false) as Label
	require(is_instance_valid(receipt_facts) and receipt_facts.get_child_count() == 5 and is_instance_valid(result_status) and result_status.text == "VICTORY · SETTLEMENT RECORDED" and result_status.anchor_bottom < (main.find_child("M3ResultBay01", true, false) as Control).anchor_top and is_instance_valid(result_drop) and result_drop.texture != null and is_instance_valid(result_xp) and result_xp.text.begins_with("XP ") and is_instance_valid(result_bay_value) and result_bay_value.text == "37", "M3 Result seats truthful victory/settlement receipt bays with native exact drop art and integer-formatted values at 150% text.")
	require(is_instance_valid(result_continue) and result_continue.custom_minimum_size.x >= 56.0 and result_continue.anchor_top >= 0.78 and result_continue.anchor_left <= 0.08 and result_continue.get_theme_stylebox("normal") is StyleBoxEmpty and not result_continue.disabled and main.find_child("ResultRetry", true, false) == null, "M3 Result uses a transparent physical Continue hit region over the lower dial and hides Retry outside persistence error.")
	main.m3_result_state = "error"; main.render(); await get_tree().process_frame
	var result_retry := main.find_child("ResultRetry", true, false) as Button
	result_continue = main.find_child("ResultContinue", true, false) as Button
	require(is_instance_valid(result_retry) and result_retry.custom_minimum_size.x >= 56.0 and is_instance_valid(result_continue) and result_continue.disabled, "M3 Result exposes Retry only in a physical secondary well after a persistence error.")
	main.screen = "settings"; main.settings_return_screen = "title"; main.render(); await get_tree().process_frame
	require(main.find_child("M3SettingsInstrument", true, false) != null and main.find_child("SettingsApply", true, false) != null, "M3 Settings uses the approved instrument with native Apply.")
	var settings_hud_coin := main.find_child("SettingsHudCoins", true, false) as Label
	var settings_text_plate := main.find_child("SettingsTextScalePlate", true, false) as Control
	var settings_text_dial := main.find_child("SettingsTextScaleDial", true, false) as Control
	var settings_preview := main.find_child("SettingsLivePreviewPlate", true, false) as Control
	var settings_preview_content := main.find_child("SettingsLivePreviewContent", true, false) as Control
	var settings_cancel := main.find_child("SettingsCancel", true, false) as Button
	var settings_apply := main.find_child("SettingsApply", true, false) as Button
	require(is_instance_valid(settings_hud_coin) and settings_hud_coin.autowrap_mode == TextServer.AUTOWRAP_OFF and settings_hud_coin.custom_minimum_size.x >= 112.0 and is_instance_valid(settings_text_plate) and is_instance_valid(settings_text_dial) and int(settings_text_plate.anchor_left * 576.0) in range(126, 130) and int(settings_text_dial.anchor_left * 576.0) >= 312 and int(settings_text_dial.anchor_right * 576.0) >= 498 and is_instance_valid(settings_preview) and is_instance_valid(settings_cancel) and settings_cancel.text == "BACK TO\nTITLE" and settings_cancel.get_theme_color("font_color") == Color("f3e5c9") and settings_cancel.get_theme_color("font_focus_color") == Color("ffffff") and is_instance_valid(settings_apply) and settings_cancel.custom_minimum_size.x >= 56.0 and settings_apply.custom_minimum_size.x >= 56.0 and settings_cancel.anchor_bottom <= 1.0 and settings_apply.anchor_bottom <= 1.0, "M8 Settings seats a pale caller-specific two-line Back control on the dark bottom dial alongside bounded 56px Apply action in ST-01 wells.")
	for node_name in ["SettingsText10000", "SettingsText12500", "SettingsText15000", "SettingsLowermaster_bps", "SettingsRaisemaster_bps", "SettingsHighContrast", "SettingsReducedMotion", "SettingsLowermusic_bps", "SettingsRaisemusic_bps", "SettingsLowersfx_bps", "SettingsRaisesfx_bps"]:
		var settings_target := main.find_child(node_name, true, false) as Button
		require(is_instance_valid(settings_target) and settings_target.custom_minimum_size.x >= 48.0 and settings_target.custom_minimum_size.y >= 48.0, "M3 Settings native control %s meets the 48px touch minimum." % node_name)
	for node_name in ["SettingsLowermaster_bps", "SettingsLowermusic_bps", "SettingsRaisemusic_bps", "SettingsLowersfx_bps", "SettingsRaisesfx_bps", "SettingsHighContrast", "SettingsReducedMotion"]:
		var light_surface_target := main.find_child(node_name, true, false) as Button
		require(is_instance_valid(light_surface_target) and light_surface_target.get_theme_color("font_color") == Color("47331f"), "M3 Settings uses dark native glyph/value contrast on the light parchment control %s." % node_name)
	var master_raise := main.find_child("SettingsRaisemaster_bps", true, false) as Button
	require(is_instance_valid(master_raise) and master_raise.get_theme_color("font_color") == Color("f3d995") and master_raise.custom_minimum_size.x >= 48.0, "M3 Settings keeps only the Master Volume plus pale on its navy dial while its paired parchment minus remains dark.")
	var preview_music := main.find_child("SettingsPreviewMusic", true, false) as Control
	var preview_sfx := main.find_child("SettingsPreviewSfx", true, false) as Control
	var settings_master_title := main.find_child("SettingsMasterVolumeRow", true, false) as Control
	var settings_music_value := main.find_child("SettingsPreviewMusicValue", true, false) as Label
	var settings_sfx_value := main.find_child("SettingsPreviewSfxValue", true, false) as Label
	var preview_height := (settings_preview.anchor_bottom - settings_preview.anchor_top) * 1024.0 if is_instance_valid(settings_preview) else 0.0
	var music_world_top := settings_preview.anchor_top * 1024.0 + preview_music.anchor_top * preview_height if is_instance_valid(settings_preview) and is_instance_valid(preview_music) else 0.0
	var sfx_world_top := settings_preview.anchor_top * 1024.0 + preview_sfx.anchor_top * preview_height if is_instance_valid(settings_preview) and is_instance_valid(preview_sfx) else 0.0
	require(is_instance_valid(settings_preview_content) and settings_preview_content.get_parent() == settings_preview and is_instance_valid(preview_music) and is_instance_valid(preview_sfx) and preview_music.anchor_bottom <= preview_sfx.anchor_top and int(music_world_top) in range(752, 763) and int(sfx_world_top) in range(809, 820) and is_instance_valid(settings_music_value) and is_instance_valid(settings_sfx_value) and is_instance_valid(settings_master_title) and settings_cancel.get_theme_stylebox("pressed") is StyleBoxFlat and settings_apply.get_theme_stylebox("pressed") is StyleBoxFlat, "M3 Settings uses one non-container preview content layer with distinct sample, Music, and SFX bands plus independent native audio values and physical pressed feedback on exposed bottom hardware.")
	var accepted_settings: Dictionary = (GameManager.profile.get("settings", {}) as Dictionary).duplicate(true)
	var settings_back := main.find_child("UnifiedFoundryWorkshopReturn", true, false) as Button
	require(is_instance_valid(settings_back) and settings_back.tooltip_text.contains("Title") and settings_back.accessibility_name.contains("Title"), "M3 Settings Back exposes its Title caller in native tooltip and accessibility text.")
	main._m3_set_setting("text_scale_bps", 15000); main._m3_cancel_settings()
	require(main.screen == "title" and GameManager.profile.get("settings", {}) == accepted_settings, "M3 Settings Cancel returns to its Title caller and discards only the local draft.")
	var starter_one := GameManager.claim_next_starter_pack()
	require(bool(starter_one.get("ok", false)) and bool(GameManager.profile.get("pending_pack_reveal", {}).get("starter_reward", false)), "Starter pack one is committed before the M3 reveal.")
	var receipt_before_keep := (GameManager.profile.get("pending_pack_reveal", {}) as Dictionary).duplicate(true)
	main.screen = "unified_library"; main.render(); await get_tree().process_frame
	var reveal_grid := main.find_child("UnifiedPackRevealGrid", true, false)
	var first_pack_card := main.find_child("UnifiedPackCardView" + str((receipt_before_keep.get("cards", []) as Array)[0]).capitalize(), true, false) as Button
	var keep_pack := main.find_child("UnifiedPackRevealKeepCards", true, false) as Button
	var pack_xp := main.find_child("PackHudXp", true, false) as Label
	var pack_status := main.find_child("PackReceiptStatus", true, false) as Label
	var pack_cue := main.find_child("PackTileOwnershipFacts", true, false) as Label
	var creature_pack_cue: Label = null
	for receipt_card_variant in (receipt_before_keep.get("cards", []) as Array):
		var receipt_card_id := str(receipt_card_variant)
		if str(RULES.card(receipt_card_id).get("type", "")) != "creature": continue
		var creature_tile := main.find_child("UnifiedPackCardView" + receipt_card_id.capitalize(), true, false) as Button
		if is_instance_valid(creature_tile):
			creature_pack_cue = creature_tile.find_child("PackTileOwnershipFacts", true, false) as Label
			break
	require(main.find_child("M3PhysicalPackPlate", true, false) != null and main.find_child("ArchiveBookCardGrid", true, false) == null and main.find_child("ArchiveArchBack", true, false) == null and reveal_grid != null and reveal_grid.get_child_count() == 5, "A pending pack exclusively owns the RW-02 plate and leaves no Archive controls or hit targets underneath.")
	require(is_instance_valid(first_pack_card) and first_pack_card.find_child("PackTileCatalogArt", true, false) is TextureRect and is_instance_valid(keep_pack) and keep_pack.custom_minimum_size.x >= 56.0 and keep_pack.anchor_top >= 0.80 and keep_pack.get_theme_stylebox("normal") is StyleBoxEmpty and is_instance_valid(pack_xp) and pack_xp.text.begins_with("XP ") and is_instance_valid(pack_status) and pack_status.text.contains("Basic Pack") and pack_status.text.contains("PACK 1/3") and is_instance_valid(pack_cue) and is_instance_valid(creature_pack_cue) and creature_pack_cue.text.contains("Cards") and creature_pack_cue.text.contains("License") and creature_pack_cue.text.contains("Models"), "M3 Pack seats persisted exact-art docks with truthful pack progress, complete HUD, and three separate native card-copy, license, and printed-model facts.")
	var receipt_cards: Array = receipt_before_keep.get("cards", []) as Array
	var pack_order_ok := receipt_cards.size() == 5
	for index in mini(5, receipt_cards.size()):
		var dock := main.find_child("PackReceiptDock%02d" % (index + 1), true, false) as Control
		if not is_instance_valid(dock) or dock.find_child("UnifiedPackCardView" + str(receipt_cards[index]).capitalize(), true, false) == null: pack_order_ok = false
	require(pack_order_ok, "Pack receipt docks preserve the persisted five-card order and block all non-Keep navigation.")
	var kept_one := GameManager.claim_pending_pack_reveal_result()
	require(bool(kept_one.get("ok", false)) and GameManager.profile.get("pending_pack_reveal", {}).is_empty() and receipt_before_keep.get("cards", []) == kept_one.get("cards", []).slice(0, receipt_before_keep.get("cards", []).size()), "Keep clears only the committed pending receipt after persistence.")
	var starter_two := GameManager.claim_next_starter_pack()
	var kept_two := GameManager.claim_pending_pack_reveal_result() if bool(starter_two.get("ok", false)) else {}
	var starter_three := GameManager.claim_next_starter_pack()
	var kept_three := GameManager.claim_pending_pack_reveal_result() if bool(starter_three.get("ok", false)) else {}
	var fourth := GameManager.claim_next_starter_pack()
	require(bool(starter_two.get("ok", false)) and bool(kept_two.get("ok", false)) and bool(starter_three.get("ok", false)) and bool(kept_three.get("ok", false)) and not bool(fourth.get("ok", false)), "M3 preserves starter packs 1→2→3 and blocks a fourth.")
	var corrupt_root := "E:/AI Projects/games/3d print battler/build/task-state/m3-runtime-20260831/corrupt-recovery"
	DirAccess.make_dir_recursive_absolute(corrupt_root)
	SaveService.configure_test_paths(corrupt_root)
	var corrupt := FileAccess.open(SaveService.profile_path, FileAccess.WRITE)
	corrupt.store_string("{ this is intentionally invalid JSON"); corrupt.close()
	GameManager._initialize_loaded_profile(SaveService.load_profile())
	require(GameManager.is_save_read_only() and str(SaveService.recovery_status) == "corrupt_primary", "Corrupt primary enters M3 read-only recovery without overwriting evidence.")
	main.screen = "workshop"; main.render(); await get_tree().process_frame
	require(main.find_child("RecoveryNewMaker", true, false) != null and not main.m3_recovery_new_maker_confirm, "Corrupt recovery exposes a separate first-step New Maker confirmation.")
	var recovery_top := main.find_child("RecoveryTopPlate", true, false) as Control
	var recovery_copy := main.find_child("RecoveryPlayerExplanation", true, false) as Label
	var recovery_rows_ok := true
	for index in 3:
		if main.find_child("RecoveryLedgerRow%d" % (index + 1), true, false) == null: recovery_rows_ok = false
	var recovery_new_maker := main.find_child("RecoveryNewMaker", true, false) as Button
	var recovery_row_one := main.find_child("RecoveryLedgerRow1", true, false) as Control
	var recovery_row_two := main.find_child("RecoveryLedgerRow2", true, false) as Control
	var recovery_row_three := main.find_child("RecoveryLedgerRow3", true, false) as Control
	require(is_instance_valid(recovery_top) and is_instance_valid(recovery_copy) and not recovery_copy.text.contains("corrupt_primary") and not recovery_copy.text.contains("Capture recovery fixture") and recovery_rows_ok and is_instance_valid(recovery_new_maker) and recovery_new_maker.custom_minimum_size.x >= 56.0 and is_instance_valid(recovery_row_one) and is_instance_valid(recovery_row_two) and is_instance_valid(recovery_row_three) and int(recovery_row_one.anchor_top * 1024.0) in range(548, 552) and int(recovery_row_two.anchor_top * 1024.0) in range(617, 620) and int(recovery_row_three.anchor_top * 1024.0) in range(685, 688), "M3 Recovery uses calm native copy and three centered ledger rows with a 56px two-step New Maker action.")
	main._m3_request_new_maker_recovery(); await get_tree().process_frame
	var recovery_confirm := main.find_child("RecoveryNewMaker", true, false) as Button
	require(is_instance_valid(recovery_confirm) and recovery_confirm.text == "CONFIRM NEW MAKER" and FileAccess.file_exists(SaveService.profile_path), "First recovery step does not replace the corrupt save.")
	main._m3_confirm_new_maker_recovery(); await get_tree().process_frame
	var preserved := false
	for file_name in DirAccess.get_files_at(corrupt_root):
		if file_name.begins_with("profile.corrupt-"): preserved = true
	require(not GameManager.is_save_read_only() and FileAccess.file_exists(SaveService.profile_path) and preserved, "Second recovery confirmation preserves corrupt evidence before committing a clean New Maker snapshot.")
	var backup_root := "E:/AI Projects/games/3d print battler/build/task-state/m3-runtime-20260831/backup-recovery"
	DirAccess.make_dir_recursive_absolute(backup_root)
	SaveService.configure_test_paths(backup_root)
	var recovered_profile := RULES.new_profile(); recovered_profile.forge_coins = 77
	var backup_file := FileAccess.open(SaveService.profile_backup_path, FileAccess.WRITE)
	backup_file.store_string(JSON.stringify(recovered_profile)); backup_file.close()
	var broken_primary := FileAccess.open(SaveService.profile_path, FileAccess.WRITE)
	broken_primary.store_string("{ broken primary"); broken_primary.close()
	GameManager._initialize_loaded_profile(SaveService.load_profile())
	require(GameManager.is_save_read_only() and str(SaveService.recovery_status) == "backup_recovered", "Validated backup enters explicit read-only acknowledgement instead of writable gameplay.")
	var recovered_revision := int(GameManager.profile.get("revision", 0))
	var acknowledged := GameManager.acknowledge_backup_recovery()
	require(bool(acknowledged.get("ok", false)) and not GameManager.is_save_read_only() and int(GameManager.profile.get("revision", 0)) == recovered_revision, "Backup acknowledgement preserves revision while safely promoting the recovered snapshot.")
	require(GameManager.save_settings({"text_scale_bps":12500}), "A post-acknowledgement settings mutation persists successfully.")
	var race_root := "E:/AI Projects/games/3d print battler/build/task-state/m3-runtime-20260831/backup-race"
	DirAccess.make_dir_recursive_absolute(race_root)
	SaveService.configure_test_paths(race_root)
	var race_backup := FileAccess.open(SaveService.profile_backup_path, FileAccess.WRITE)
	race_backup.store_string(JSON.stringify(recovered_profile)); race_backup.close()
	var race_broken := FileAccess.open(SaveService.profile_path, FileAccess.WRITE)
	race_broken.store_string("{ broken primary"); race_broken.close()
	GameManager._initialize_loaded_profile(SaveService.load_profile())
	var race_primary := RULES.new_profile(); race_primary.forge_coins = 999
	var race_primary_file := FileAccess.open(SaveService.profile_path, FileAccess.WRITE)
	race_primary_file.store_string(JSON.stringify(race_primary)); race_primary_file.close()
	var race_ack := GameManager.acknowledge_backup_recovery()
	require(bool(race_ack.get("ok", false)) and bool(race_ack.get("resumed_primary", false)) and int(GameManager.profile.get("forge_coins", 0)) == 999, "Backup acknowledgement rereads storage and never overwrites a newly valid authoritative primary.")
	var future_profile := RULES.new_profile(); future_profile.schema_version = 999
	GameManager._initialize_loaded_profile(future_profile)
	main.screen = "workshop"; main.render(); await get_tree().process_frame
	var future_copy := main.find_child("RecoveryPlayerExplanation", true, false) as Label
	var saved_schema_fact := main.find_child("RecoveryLedgerRow1", true, false) as Control
	var current_schema_fact := main.find_child("RecoveryLedgerRow2", true, false) as Control
	var saved_schema_value := saved_schema_fact.get_child(1) as Label if is_instance_valid(saved_schema_fact) and saved_schema_fact.get_child_count() > 1 else null
	var current_schema_value := current_schema_fact.get_child(1) as Label if is_instance_valid(current_schema_fact) and current_schema_fact.get_child_count() > 1 else null
	var protection_fact := main.find_child("RecoveryLedgerRow3", true, false) as Control
	var protection_value := protection_fact.get_child(1) as Label if is_instance_valid(protection_fact) and protection_fact.get_child_count() > 1 else null
	var preservation_receipt := main.find_child("RecoveryPreservationReceipt", true, false) as Control
	var preservation_copy := main.find_child("RecoveryPreservationCopy", true, false) as Label
	var recovery_state_indicator := main.find_child("RecoveryStateIndicator", true, false) as Label
	require(GameManager.is_save_read_only() and is_instance_valid(future_copy) and future_copy.text.contains("newer PrintForge version") and not future_copy.text.contains("future_schema") and main.find_child("RecoveryBack", true, false) == null and main.find_child("RecoverySafeBack", true, false) == null and main.find_child("RecoveryNewMaker", true, false) == null and main.find_child("RecoveryAcknowledgeBackup", true, false) == null and is_instance_valid(saved_schema_value) and saved_schema_value.text == "999" and is_instance_valid(current_schema_value) and current_schema_value.text == str(GameManager.save_compatibility.get("supported_schema", "—")) and is_instance_valid(protection_value) and protection_value.text == "Read-only" and is_instance_valid(preservation_receipt) and preservation_receipt.clip_contents and int(preservation_receipt.anchor_left * 576.0) in range(144, 147) and int(preservation_receipt.anchor_top * 1024.0) in range(419, 422) and int(preservation_receipt.anchor_bottom * 1024.0) in range(519, 522) and is_instance_valid(preservation_copy) and preservation_copy.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART and preservation_copy.text == "Saved record preserved · No changes made" and is_instance_valid(recovery_state_indicator) and recovery_state_indicator.get_theme_color("font_color") == Color("47331f"), "Future-version recovery keeps only truthful state-specific actions; no false Back control promises navigation that read-only recovery would block.")
	var invalid_backup_root := "E:/AI Projects/games/3d print battler/build/task-state/m3-runtime-20260831/invalid-backup-only"
	DirAccess.make_dir_recursive_absolute(invalid_backup_root)
	SaveService.configure_test_paths(invalid_backup_root)
	var invalid_backup := FileAccess.open(SaveService.profile_backup_path, FileAccess.WRITE)
	invalid_backup.store_string("{ invalid backup"); invalid_backup.close()
	GameManager._initialize_loaded_profile(SaveService.load_profile())
	require(GameManager.is_save_read_only() and str(SaveService.recovery_status) == "corrupt_backup" and GameManager.profile.is_empty(), "Invalid-backup-only remains recoverable evidence, never a silent clean-install profile.")
	require(MANIFEST.validation_errors().is_empty(), "M3 promoted masters pass runtime manifest validation.")
	main.queue_free()
	await get_tree().process_frame
	if failures.is_empty(): print("PASS: M3 physical management routes, frozen market, settings draft, and asset package")
	get_tree().quit(0 if failures.is_empty() else 1)
