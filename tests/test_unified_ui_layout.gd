extends Node

## Accessibility/UI contract: M2 changes only the battle assertions below; the
## retained tail continues to exercise Market, archive, deck, packs and onboarding.

const MAIN := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")
const STATE := preload("res://scripts/battle/unified_battle_state.gd")
var failures: Array[String] = []
var configured_root := ""

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _legal_profile() -> Dictionary:
	var profile := RULES.ensure(ProfileRules.new_profile())
	profile = RULES.choose_starter(profile, "cinderpaw").profile
	profile = RULES.print_starter(profile).profile
	profile.settings = {"text_scale_bps":15000,"high_contrast":true,"reduced_motion":true}
	return profile

func _button_named(node: Node, fragment: String) -> Button:
	if node is Button and fragment.to_lower() in (node as Button).text.to_lower(): return node as Button
	for child in node.get_children():
		var found := _button_named(child, fragment)
		if found != null: return found
	return null

func _within_viewport(control: Control, viewport: Vector2) -> bool:
	if control == null or not control.is_visible_in_tree(): return false
	var rect := control.get_global_rect()
	return rect.position.x >= 0.0 and rect.position.y >= 0.0 and rect.end.x <= viewport.x and rect.end.y <= viewport.y

func _configure_isolated_save_paths() -> void:
	configured_root = SaveService.profile_path.get_base_dir()
	if not configured_root.replace("\\", "/").contains("/build/evidence/"):
		require(false, "Unified UI layout test requires pre-autoload E: build/evidence QA storage; refusing fixture writes outside it.")
		return
	var root := configured_root.path_join("m2-unified-layout")
	DirAccess.make_dir_recursive_absolute(root)
	SaveService.configure_test_paths(root)

func _exercise(viewport: Vector2) -> void:
	GameManager.profile = _legal_profile()
	var subviewport := SubViewport.new()
	subviewport.size = Vector2i(viewport); subviewport.size_2d_override = Vector2i(viewport); subviewport.size_2d_override_stretch = true; subviewport.disable_3d = true; add_child(subviewport)
	var canvas := Control.new(); canvas.size = viewport; subviewport.add_child(canvas)
	var main := MAIN.instantiate(); var deck: Array = GameManager.active_deck_cards()
	main.battle = STATE.create(deck, deck, 81); main.battle.starting_seat = 0; main.battle.active_seat = 0; main.battle.phase = "main"; main.battle.player(0).hand = ["cinderpaw"]
	main.battle_mode = "daily_training"; main.screen = "unified_battle"; main.unified_battle_coordinator.configure(main.battle, 0); canvas.add_child(main); main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().process_frame; await get_tree().process_frame
	var stage := main.find_child("PhysicalBattlefieldStage", true, false) as Control
	var lever := main.find_child("UnifiedRunCycleLever", true, false) as Button
	require(stage != null and _within_viewport(stage, viewport), "Physical battle chassis fills the usable surface at %s." % viewport)
	# M2 is intentionally portrait-only; landscape remains an unsupported review
	# fixture for the pre-existing non-battle route regressions below.
	if viewport.y > viewport.x:
		require(lever != null and lever.custom_minimum_size.y >= 56.0 and _within_viewport(lever, viewport), "Plan exposes one in-bounds 56px Run Cycle lever at %s." % viewport)
	require(main.find_child("UnifiedBattlePrimaryAction", true, false) == null and main.find_child("UnifiedBattlePhaseActions", true, false) == null, "Retired manual phase controls are absent at %s." % viewport)
	var card := main.find_child("UnifiedHandCinderpaw", true, false) as Button
	require(card != null and not card.disabled, "Owned hand card remains native and playable in Plan at %s." % viewport)
	if card != null: card.emit_signal("pressed"); await get_tree().process_frame
	main._submit_unified_intent({"type":"play_card","card_id":"cinderpaw"}); main.unified_battle_coordinator.acknowledge_presentation(main.unified_battle_coordinator.generation); await get_tree().process_frame
	require(main.battle.player(0).queue.size() == 1, "Plan card action queues through checked authority at %s." % viewport)
	lever = main.find_child("UnifiedRunCycleLever", true, false) as Button
	if lever != null: lever.emit_signal("pressed"); await get_tree().process_frame
	require(str(main.battle.phase) != "main", "Run Cycle advances without exposing phase buttons at %s." % viewport)
	main.unified_battle_coordinator.acknowledge_presentation(main.unified_battle_coordinator.generation)
	main.battle.pending = {"kind":"place","seat":0,"unit":STATE._unit(RULES.card("cinderpaw"))}; main.render(); await get_tree().process_frame
	var placement_count := 0
	for slot in 3:
		for mode in ["Attack", "Defense"]:
			var placement := main.find_child("UnifiedPendingPlaceSlot%d%s" % [slot + 1, mode], true, false) as Button
			if placement != null and placement.custom_minimum_size.y >= 48.0: placement_count += 1
	require(placement_count == 6, "Required placement is contextual through six physical anchor mode choices at %s." % viewport)
	main.battle.pending = {"kind":"attach","seat":0,"card_id":"standard_full_suit","holding_index":0}; main.battle.player(0).slots = [STATE._unit(RULES.card("cinderpaw")), null, null]; main.render(); await get_tree().process_frame
	var attachment := main.find_child("UnifiedPendingAttachSlot1", true, false) as Button
	require(attachment != null and attachment.custom_minimum_size.y >= 48.0, "Required attachment is contextual at its compatible physical anchor at %s." % viewport)

	main.screen = "unified_market"
	main.unified_market_tab = "blueprints"
	main.render()
	await get_tree().process_frame
	var market_return := main.find_child("UnifiedFoundryWorkshopReturn", true, false) as Button
	var market_cabinet := main.find_child("M3SupplyCabinet", true, false) as Control
	var market_tabs := main.find_child("V3MarketTabs", true, false) as Control
	var market_cubbies := main.find_child("MarketOfferCubbies", true, false) as Control
	var market_page_well := main.find_child("MarketCategoryPageWell", true, false) as Control
	var market_previous := main.find_child("MarketPagePrevious", true, false) as Button
	var market_next := main.find_child("MarketPageNext", true, false) as Button
	var market_indicator := main.find_child("MarketPageIndicator", true, false) as Label
	require(market_return != null and _within_viewport(market_return, viewport), "Foundry Market exposes a visible first-fold Workshop return at %s." % viewport)
	if market_return != null:
		require(market_return.focus_mode != Control.FOCUS_NONE and not market_return.disabled, "Foundry Market Workshop return is keyboard-focusable at %s." % viewport)
		market_return.grab_focus()
		await get_tree().process_frame
		require(market_return.has_focus(), "Foundry Market Workshop return receives keyboard focus at %s." % viewport)
	require(market_cabinet != null and market_tabs != null and market_cubbies != null and market_page_well != null and market_previous != null and market_next != null and market_indicator != null and _within_viewport(market_cabinet, viewport) and _within_viewport(market_tabs, viewport) and _within_viewport(market_cubbies, viewport) and _within_viewport(market_page_well, viewport) and _within_viewport(market_previous, viewport) and _within_viewport(market_next, viewport) and _within_viewport(market_indicator, viewport), "Foundry Market uses the bounded M3 physical cabinet, selector bank, six-cubby owner, and page shuttle at %s." % viewport)
	var market_selector_buttons: Array[Button] = []
	if market_tabs != null:
		for tab in market_tabs.get_children():
			if tab is Button: market_selector_buttons.append(tab as Button)
	require(market_selector_buttons.size() == 5, "Foundry Market exposes exactly five physical category selectors at %s." % viewport)
	for tab in market_selector_buttons:
		var tab_rect := tab.get_global_rect()
		require(tab.focus_mode != Control.FOCUS_NONE and _within_viewport(tab, viewport) and tab_rect.size.x >= 48.0 and tab_rect.size.y >= 48.0, "Every Foundry Market category selector is focusable and has an actual 48px touch target at %s." % viewport)
	var first_page_keys: Array[String] = []
	var visible_cubby_count := 0
	if market_cubbies != null:
		visible_cubby_count = market_cubbies.get_child_count()
		for cubby in market_cubbies.get_children():
			require(cubby is Control and _within_viewport(cubby as Control, viewport), "Every visible Market cubby stays inside the cabinet viewport at %s." % viewport)
			if cubby.get_child_count() > 0:
				var tile := cubby.get_child(0) as Control
				if tile != null: first_page_keys.append(str(tile.get_meta("market_offer_slot_key", "")))
	require(visible_cubby_count <= 6, "Foundry Market shows no more than six offers in its authored cubbies at %s." % viewport)
	var current_page := int(main.get_meta("m3_market_page", 0))
	require(market_indicator != null and market_indicator.text.begins_with("PAGE %d/" % (current_page + 1)), "Foundry Market page indicator truthfully names the bounded visible page at %s." % viewport)
	if market_next != null and not market_next.disabled:
		market_next.emit_signal("pressed")
		await get_tree().process_frame
		var next_cubbies := main.find_child("MarketOfferCubbies", true, false) as Control
		var next_indicator := main.find_child("MarketPageIndicator", true, false) as Label
		var next_keys: Array[String] = []
		var next_cubby_count := 0
		if next_cubbies != null:
			next_cubby_count = next_cubbies.get_child_count()
			for cubby in next_cubbies.get_children():
				require(cubby is Control and _within_viewport(cubby as Control, viewport), "Market next-page cubbies stay bounded at %s." % viewport)
				if cubby.get_child_count() > 0:
					var tile := cubby.get_child(0) as Control
					if tile != null: next_keys.append(str(tile.get_meta("market_offer_slot_key", "")))
		require(next_cubby_count <= 6, "Market next page remains a six-cubby page at %s." % viewport)
		require(int(main.get_meta("m3_market_page", 0)) == 1 and next_indicator != null and next_indicator.text.begins_with("PAGE 2/") and next_keys != first_page_keys, "An enabled Market Next control advances to a distinct bounded second page at %s." % viewport)
	else:
		require(market_previous != null and market_previous.disabled and market_next != null and market_next.disabled, "Single-page Market inventory disables both physical paging ends at %s." % viewport)
	if market_return != null:
		market_return.emit_signal("pressed")
		await get_tree().process_frame
		require(main.screen == "workshop", "Foundry Market Workshop return navigates to Workshop at %s." % viewport)
	main.screen = "unified_deck"
	main.render()
	await get_tree().process_frame
	var deck_return := main.find_child("UnifiedFoundryWorkshopReturn", true, false) as Button
	var deck_workbench := main.find_child("M3DeckWorkbench", true, false) as Control
	var deck_folio := main.find_child("DeckTopEightCardFolio", true, false) as Control
	var deck_inspector := main.find_child("DeckPhysicalInspector", true, false) as Control
	var deck_slots := main.find_child("ArchiveDeckSlots", true, false) as Control
	var deck_clamps := main.find_child("M3PrePrintClamps", true, false) as Control
	var save_deck := main.find_child("SaveActiveDeck", true, false) as Button
	var save_preprints := main.find_child("SavePrePrintLoadout", true, false) as Button
	require(deck_workbench != null and deck_folio != null and deck_inspector != null and deck_slots != null and deck_clamps != null and deck_return != null and save_deck != null and save_preprints != null and _within_viewport(deck_workbench, viewport) and _within_viewport(deck_folio, viewport) and _within_viewport(deck_inspector, viewport) and _within_viewport(deck_slots, viewport) and _within_viewport(deck_clamps, viewport), "Deck Builder uses the M3 workbench, folio, physical inspector, fixed slots, and three-clamp surface at %s." % viewport)
	for action in [deck_return, save_deck, save_preprints]:
		var action_rect: Rect2 = action.get_global_rect() if action != null else Rect2()
		require(action != null and action.focus_mode != Control.FOCUS_NONE and _within_viewport(action, viewport) and action_rect.size.x >= 48.0 and action_rect.size.y >= 48.0, "Deck physical action remains visible, focusable, and at least 48px at %s." % viewport)
	if save_deck != null and save_preprints != null:
		var save_rect := save_deck.get_global_rect(); var preprint_rect := save_preprints.get_global_rect()
		require(save_rect.size.x >= 56.0 and save_rect.size.y >= 56.0 and preprint_rect.size.x >= 56.0 and preprint_rect.size.y >= 56.0, "Deck Save and Pre-Print actions retain their physical 56px guarantees at %s." % viewport)
	if deck_return != null:
		deck_return.grab_focus()
		await get_tree().process_frame
		require(deck_return.has_focus(), "Deck Builder Workshop return receives keyboard focus at %s." % viewport)
		deck_return.emit_signal("pressed")
		await get_tree().process_frame
		require(main.screen == "workshop", "Deck Builder Workshop return navigates to Workshop at %s." % viewport)
	var reveal_source: Dictionary = GameManager.profile.duplicate(true)
	reveal_source.forge_coins = 1000
	var five_card_pack := RULES.buy_pack(reveal_source, "forge", PackedByteArray([1, 2, 3, 4, 5, 6, 7, 8]))
	require(bool(five_card_pack.get("ok", false)) and (five_card_pack.get("payload", {}).get("cards", []) as Array).size() == 5, "Responsive fixture creates a deterministic five-card Forge Pack at %s." % viewport)
	if bool(five_card_pack.get("ok", false)):
		GameManager.profile = five_card_pack.profile
		main.unified_reveal_page = 0
		main.unified_market_tab = "packs"
		main._m3_open_pending_pack("unified_market")
		await get_tree().process_frame
		var pack_plate := main.find_child("M3PhysicalPackPlate", true, false) as Control
		var reveal_grid := main.find_child("UnifiedPackRevealGrid", true, false) as Control
		var keep_cards := main.find_child("UnifiedPackRevealKeepCards", true, false) as Button
		var reveal_cards: Array = []
		if reveal_grid != null: reveal_cards = reveal_grid.find_children("UnifiedPackCardView*", "Button", true, false)
		var pack_docks: Array[Control] = []
		for index in 5:
			var dock := main.find_child("PackReceiptDock%02d" % (index + 1), true, false) as Control
			if dock != null: pack_docks.append(dock)
		require(pack_plate != null and pack_plate.get_global_rect().position.is_equal_approx(Vector2.ZERO) and pack_plate.get_global_rect().size.is_equal_approx(viewport) and reveal_grid != null and _within_viewport(reveal_grid, viewport), "Five-card pack receipt exclusively fills the M3 physical plate at %s." % viewport)
		require(pack_docks.size() == 5 and reveal_cards.size() == 5 and main.find_child("UnifiedPackRevealPager", true, false) == null, "Five-card pack receipt exposes exactly five docked native cards without a pager at %s." % viewport)
		for dock in pack_docks:
			require(_within_viewport(dock, viewport), "Every physical pack receipt dock fits the viewport at %s." % viewport)
		for reveal_card in reveal_cards:
			require(reveal_card is Control and _within_viewport(reveal_card as Control, viewport), "Every five-card reveal card fits inside the viewport at %s." % viewport)
		var keep_rect := keep_cards.get_global_rect() if keep_cards != null else Rect2()
		require(keep_cards != null and _within_viewport(keep_cards, viewport) and keep_rect.size.x >= 56.0 and keep_rect.size.y >= 56.0, "Five-card receipt Keep action fits its physical 56px target at %s." % viewport)
		require(main.find_child("ArchiveBookCardGrid", true, false) == null and main.find_child("ArchiveArchBack", true, false) == null, "Pending pack receipt leaves no Archive grid or navigation targets underneath at %s." % viewport)
		var original_cards := ["cinderpaw", "aquafin", "voltwig"]
		var original_bonus_cards := ["mossmunk", "frostling"]
		GameManager.profile.pending_pack_reveal = {"pack_id":"bonus-fixture", "cards":original_cards.duplicate(), "bonus_cards":original_bonus_cards.duplicate(), "receipt":"ui-bonus-fixture"}
		var pending_before_rerender: Dictionary = GameManager.profile.pending_pack_reveal.duplicate(true)
		main.render()
		await get_tree().process_frame
		var first_bonus_grid := main.find_child("UnifiedPackRevealGrid", true, false) as Control
		var first_bonus_count := first_bonus_grid.find_children("UnifiedPackCardView*", "Button", true, false).size() if first_bonus_grid != null else 0
		main.render()
		await get_tree().process_frame
		var second_bonus_grid := main.find_child("UnifiedPackRevealGrid", true, false) as Control
		var second_bonus_count := second_bonus_grid.find_children("UnifiedPackCardView*", "Button", true, false).size() if second_bonus_grid != null else 0
		var persisted_pending: Dictionary = GameManager.profile.get("pending_pack_reveal", {})
		require(persisted_pending == pending_before_rerender and persisted_pending.get("cards", []) == original_cards and persisted_pending.get("bonus_cards", []) == original_bonus_cards and str(persisted_pending.get("receipt", "")) == "ui-bonus-fixture" and first_bonus_count == 5 and second_bonus_count == 5, "Re-rendering a bonus-card physical receipt preserves its exact pending cards, bonus cards, receipt, and five displayed cards at %s." % viewport)
	# Feedback-pass contracts: battle omits the Workshop HUD, onboarding remains a
	# portrait carousel, and archive/deck routes use their physical M3 owners.
	main.screen = "unified_battle"
	main.render()
	await get_tree().process_frame
	require(main.find_child("WorkshopHud", true, false) == null, "Battle intentionally omits the Workshop HUD at %s." % viewport)
	GameManager.profile = RULES.new_profile()
	main.screen = "onboarding"
	main.render()
	await get_tree().process_frame
	var starter_schematics := main.find_children("StarterBlueprintSchematic", "TextureRect", true, false)
	var starter_inspect := main.find_child("StarterInspectFocused", true, false) as Button
	require(starter_schematics.size() == 1 and main.find_child("StarterCarouselCard", true, false) != null and main.find_child("StarterPrevious", true, false) != null and main.find_child("StarterNext", true, false) != null and main.find_child("StarterBlueprintTitle", true, false) != null and main.find_child("WorkshopHud", true, false) == null, "Portrait starter ceremony renders one focused carousel card with native paging and no post-selection HUD at %s." % viewport)
	require(starter_inspect != null and starter_inspect.focus_mode != Control.FOCUS_NONE and starter_inspect.custom_minimum_size.y >= 48.0, "Starter schematic itself exposes a separate 48px touch-safe Inspect action at %s." % viewport)
	if starter_inspect != null:
		starter_inspect.emit_signal("pressed")
		await get_tree().process_frame
		require(main.find_child("StarterCardInspector", true, false) != null and main.pending_starter_id.is_empty(), "Inspecting a starter opens its schematic without selecting it at %s." % viewport)
		var inspect_select := main.find_child("StarterInspectorSelect", true, false) as Button
		if inspect_select != null: inspect_select.emit_signal("pressed")
		await get_tree().process_frame
		require(main.find_child("StarterCardInspector", true, false) == null and main.pending_starter_id == "cinderpaw", "Starter inspector select closes the modal and updates the pending blueprint at %s." % viewport)
		main.show_starter_inspector("cinderpaw")
		await get_tree().process_frame
		var starter_modal := main.find_child("StarterCardInspector", true, false) as Control
		var starter_close := main.find_child("StarterInspectorClose", true, false) as Button
		require(starter_modal != null and starter_close != null and starter_close.focus_mode != Control.FOCUS_NONE and starter_modal.is_ancestor_of(starter_close), "Starter inspector installs a modal-owned focus target instead of leaving interaction behind it at %s." % viewport)
		var escape_event := InputEventKey.new(); escape_event.pressed = true; escape_event.keycode = KEY_ESCAPE
		main._unhandled_key_input(escape_event)
		await get_tree().process_frame
		require(main.find_child("StarterCardInspector", true, false) == null and main.screen == "onboarding", "Escape closes the starter inspector before leaving its ceremony at %s." % viewport)
		main.show_starter_inspector("cinderpaw")
		await get_tree().process_frame
		var inspect_close := main.find_child("StarterInspectorClose", true, false) as Button
		if inspect_close != null: inspect_close.emit_signal("pressed")
		await get_tree().process_frame
		require(main.find_child("StarterCardInspector", true, false) == null and main.pending_starter_id == "cinderpaw", "Starter inspector close preserves the pending selection at %s." % viewport)
	GameManager.profile = _legal_profile()
	main.screen = "workshop"
	main.workshop_view = "overview"
	main.render()
	await get_tree().process_frame
	var workshop_progress := main.find_child("WorkshopHudProgress", true, false) as ProgressBar
	require(main.find_child("WorkshopProgressInstrument", true, false) != null and workshop_progress != null and _within_viewport(workshop_progress, viewport) and "Spool Level" in workshop_progress.tooltip_text, "Workshop overview exposes the compact real XP instrument inside the viewport at %s." % viewport)
	main.screen = "unified_library"
	main.render()
	await get_tree().process_frame
	await get_tree().process_frame
	var archive_progress := main.find_child("ArchiveHudXp", true, false) as Label
	var archive_filters := main.find_child("ArchiveLowerPhysicalWells", true, false) as Control
	var archive_owned_well := main.find_child("ArchiveWellOwned", true, false) as Button
	var archive_printable_well := main.find_child("ArchiveWellPrintable", true, false) as Button
	var archive_clear_well := main.find_child("ArchiveWellClear", true, false) as Button
	var archive_first_card := main.find_child("ArchiveBlueprintCardCinderpaw", true, false) as Button
	var archive_creature_art := archive_first_card.find_child("ArchiveTileBlueprintCard", true, false) as TextureRect if archive_first_card != null else null
	var archive_hud := main.find_child("ArchiveNavyArchHud", true, false) as Control
	var archive_header := main.find_child("ArchiveParchmentHeader", true, false) as Control
	var archive_apertures := main.find_child("ArchiveSixCardApertures", true, false) as Control
	var archive_rail := main.find_child("ArchiveMetalCategoryRail", true, false) as Control
	var archive_grid := main.find_child("ArchiveBookCardGrid", true, false) as Control
	require(main.find_child("WorkshopHud", true, false) == null and main.find_child("FoundryHudProgress", true, false) == null and archive_hud != null and archive_header != null and archive_apertures != null and archive_rail != null and archive_filters != null and archive_grid != null and archive_progress != null and archive_owned_well != null and archive_printable_well != null and archive_clear_well != null and _within_viewport(archive_hud, viewport) and _within_viewport(archive_header, viewport) and _within_viewport(archive_apertures, viewport) and _within_viewport(archive_rail, viewport) and _within_viewport(archive_filters, viewport) and _within_viewport(archive_grid, viewport) and _within_viewport(archive_progress, viewport) and archive_first_card != null and _within_viewport(archive_first_card, viewport) and archive_creature_art != null and archive_creature_art.texture != null, "Collection uses the physical Archive HUD/header/apertures/category rail/filter wells/grid with a native blueprint card and no legacy Workshop/Foundry HUD at %s." % viewport)
	for well in [archive_owned_well, archive_printable_well, archive_clear_well]:
		var well_rect: Rect2 = well.get_global_rect() if well != null else Rect2()
		require(well != null and well.focus_mode != Control.FOCUS_NONE and _within_viewport(well, viewport) and well_rect.size.x >= 48.0 and well_rect.size.y >= 48.0, "Archive physical filter wells are in-bounds, focusable, and 48px at %s." % viewport)
	var archive_before_filter := GameManager.profile.duplicate(true)
	main.set_archive_filter("support")
	await get_tree().process_frame
	require(main.unified_archive_filter == "support" and int(main.get_meta("m3_archive_page", 0)) == 0 and GameManager.profile == archive_before_filter, "Archive filters reset physical pagination without mutating the profile at %s." % viewport)
	main.set_archive_filter("all")
	await get_tree().process_frame
	archive_first_card = main.find_child("ArchiveBlueprintCardCinderpaw", true, false) as Button
	if archive_first_card != null:
		archive_first_card.emit_signal("pressed")
		await get_tree().process_frame
		var archive_modal := main.find_child("M3ArchiveDetailApertures", true, false) as Control
		var archive_close := main.find_child("ArchiveDetailClose", true, false) as Button
		var close_rect := archive_close.get_global_rect() if archive_close != null else Rect2()
		require(archive_modal != null and main.find_child("ArchiveBookCardGrid", true, false) == null and archive_close != null and archive_close.focus_mode != Control.FOCUS_NONE and close_rect.size.x >= 48.0 and close_rect.size.y >= 48.0 and archive_modal.is_ancestor_of(archive_close), "Collection card replaces the CO-01 grid with M3 detail apertures and a modal-owned 48px Close target at %s." % viewport)
		var archive_escape := InputEventKey.new(); archive_escape.pressed = true; archive_escape.keycode = KEY_ESCAPE
		main._unhandled_key_input(archive_escape)
		await get_tree().process_frame
		require(main.find_child("M3ArchiveDetailApertures", true, false) == null and main.screen == "unified_library", "Escape closes the physical archive detail before leaving Collection at %s." % viewport)
	main.screen = "unified_deck"
	main.render()
	await get_tree().process_frame
	deck_workbench = main.find_child("M3DeckWorkbench", true, false) as Control
	deck_folio = main.find_child("DeckTopEightCardFolio", true, false) as Control
	deck_inspector = main.find_child("DeckPhysicalInspector", true, false) as Control
	deck_slots = main.find_child("ArchiveDeckSlots", true, false) as Control
	deck_clamps = main.find_child("M3PrePrintClamps", true, false) as Control
	save_deck = main.find_child("SaveActiveDeck", true, false) as Button
	save_preprints = main.find_child("SavePrePrintLoadout", true, false) as Button
	deck_return = main.find_child("UnifiedFoundryWorkshopReturn", true, false) as Button
	require(deck_workbench != null and deck_folio != null and deck_inspector != null and deck_slots != null and deck_clamps != null and save_deck != null and save_preprints != null and deck_return != null, "Deck Builder retains the M3 workbench physical owners instead of the retired generic clipboard at %s." % viewport)
	GameManager.profile = RULES.choose_starter(RULES.new_profile(), "cinderpaw").profile
	main.open_printer("cinderpaw")
	await get_tree().process_frame
	var starter_stage := main.find_child("ForgeContinuityChamber", true, false) as Control
	var starter_facts := main.find_child("ForgeBlueprintCartridgeAperture", true, false) as Control
	var starter_aperture := main.find_child("ForgeContinuityChamberAperture", true, false) as Control
	var starter_begin := main.find_child("BeginCreaturePrint", true, false) as Control
	var starter_back := main.find_child("ArcaneForgeBack", true, false) as Control
	var starter_fact_rect := starter_facts.get_global_rect() if starter_facts != null else Rect2()
	var starter_begin_rect := starter_begin.get_global_rect() if starter_begin != null else Rect2()
	var starter_back_rect := starter_back.get_global_rect() if starter_back != null else Rect2()
	require(not main.is_portrait_layout() or (main.find_child("ForgeContinuityStation", true, false) != null and starter_stage != null and starter_aperture != null and starter_facts != null and main.find_child("FeedbackForgeStage", true, false) == null and main.find_child("ArcaneForgeStage", true, false) == null and starter_begin != null and starter_back != null and _within_viewport(starter_aperture, viewport) and _within_viewport(starter_begin, viewport) and _within_viewport(starter_back, viewport) and starter_aperture.get_global_rect().end.x < starter_fact_rect.position.x and not starter_fact_rect.intersects(starter_begin_rect) and not starter_fact_rect.intersects(starter_back_rect) and not starter_begin_rect.intersects(starter_back_rect)), "Portrait starter-selected Forge keeps the attached enclosed chamber, external docked blueprint, and separate physical print/back plates at %s." % viewport)
	main.printer_sequence.phase = ArcaneForgeSequence.PRINTING
	main.printer_sequence.progress_bps = 6000
	main.render()
	await get_tree().process_frame
	await get_tree().process_frame
	var forge_layer := main.find_child("ForgeLayerInstrument", true, false) as Label
	var forge_state := main.find_child("ForgeStateInstrument", true, false) as Label
	var forge_coins := main.find_child("ForgeActionStatus", true, false) as Label
	require(forge_layer != null and _within_viewport(forge_layer, viewport) and forge_state != null and _within_viewport(forge_state, viewport) and forge_coins != null and _within_viewport(forge_coins, viewport), "Active Forge keeps native layer, phase/ETA, and coin instruments in their authored wells at %s." % viewport)
	# The image-led early returns must never bypass compatibility recovery.
	var prior_profile := GameManager.profile.duplicate(true)
	var prior_compatibility := GameManager.save_compatibility.duplicate(true)
	GameManager.profile = RULES.new_profile()
	GameManager.save_compatibility = {"compatible":false, "state":"future_schema", "message":"A newer build created this profile."}
	var read_only_profile := GameManager.profile.duplicate(true)
	var read_only_revision := int(GameManager.profile.get("revision", -1))
	main.screen = "workshop"
	main.workshop_view = "overview"
	main.render()
	await get_tree().process_frame
	var recovery := main.find_child("M3RecoveryLedger", true, false) as Control
	var recovery_title := main.find_child("RecoveryPlayerTitle", true, false) as Label
	var recovery_explanation := main.find_child("RecoveryPlayerExplanation", true, false) as Label
	var recovery_protection := main.find_child("RecoveryProtectionIndicator", true, false) as Label
	var ceremony_found := false
	for candidate in main.find_children("*", "Label", true, false):
		if (candidate as Label).text.contains("AWAKENING CEREMONY"): ceremony_found = true
	var forbidden_actions := ["TitleContinue", "TitleNewMaker", "TitleSettings", "TitleConfirmNewMaker", "TitleCancelNewMaker", "RecoveryBack"]
	var no_navigation := true
	for action_name in forbidden_actions:
		no_navigation = no_navigation and main.find_child(action_name, true, false) == null
	require(recovery != null and recovery_title != null and recovery_title.text == "NEWER WORKSHOP RECORD" and recovery_explanation != null and recovery_explanation.text.to_lower().contains("newer printforge") and recovery_explanation.text.to_lower().contains("update") and recovery_protection != null and recovery_protection.text.contains("READ-ONLY") and not ceremony_found and no_navigation and main.find_child("WorkshopFullBleed", true, false) == null and GameManager.profile == read_only_profile and int(GameManager.profile.get("revision", -1)) == read_only_revision, "Read-only compatibility uses the physical recovery ledger with truthful newer-version/read-only copy, no onboarding/navigation or mutation, and no Workshop visual route at %s." % viewport)
	GameManager.profile = prior_profile
	GameManager.save_compatibility = prior_compatibility
	main.queue_free()
	await get_tree().process_frame
	subviewport.queue_free()
	await get_tree().process_frame

func _ready() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ui/main.gd")
	var focus_source := source.substr(source.find("func focus_first_button"))
	require(focus_source.find("StarterCardInspector") >= 0 and focus_source.find("StarterCardInspector") < focus_source.find("for node in find_children"), "Modal focus priority is evaluated before generic route traversal.")
	_configure_isolated_save_paths()
	if not failures.is_empty():
		get_tree().quit(1)
		return
	for viewport in [Vector2(576, 1024), Vector2(720, 1280)]:
		await _exercise(viewport)
	if failures.is_empty(): print("PASS: v3 battle accessibility and responsive handoff matrix")
	SaveService.configure_test_paths(configured_root)
	get_tree().quit(0 if failures.is_empty() else 1)
