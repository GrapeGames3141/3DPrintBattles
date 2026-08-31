extends Node

## Accessibility/UI contract: M2 changes only the battle assertions below; the
## retained tail continues to exercise Market, archive, deck, packs and onboarding.

const MAIN := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")
const STATE := preload("res://scripts/battle/unified_battle_state.gd")
var failures: Array[String] = []

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
	var root := "E:/AI Projects/games/3d print battler/tmp/m2-unified-layout"
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
	var market_tabs := main.find_child("V3MarketTabs", true, false) as GridContainer
	var market_scroll := main.find_child("UnifiedMarketScroll", true, false) as ScrollContainer
	require(market_return != null and _within_viewport(market_return, viewport), "Foundry Market exposes a visible first-fold Workshop return at %s." % viewport)
	if market_return != null:
		require(market_return.focus_mode != Control.FOCUS_NONE and not market_return.disabled, "Foundry Market Workshop return is keyboard-focusable at %s." % viewport)
		market_return.grab_focus()
		await get_tree().process_frame
		require(market_return.has_focus(), "Foundry Market Workshop return receives keyboard focus at %s." % viewport)
	require(market_tabs != null and market_tabs.columns == (2 if viewport.y > viewport.x else 5) and _within_viewport(market_tabs, viewport), "Foundry Market uses an in-bounds responsive tab grid at %s." % viewport)
	if market_tabs != null:
		for tab in market_tabs.get_children():
			require(tab is Button and _within_viewport(tab as Control, viewport), "Every Foundry Market tab remains touch-reachable at %s." % viewport)
	require(market_scroll != null and _within_viewport(market_scroll, viewport) and market_scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED, "Foundry Market long content is contained by an in-bounds vertical scroll region at %s." % viewport)
	if market_scroll != null:
		var market_max_scroll := market_scroll.get_v_scroll_bar().max_value
		market_scroll.scroll_vertical = int(market_max_scroll)
		await get_tree().process_frame
		require(market_max_scroll > 0.0 and market_scroll.scroll_vertical > 0, "Foundry Market lower inventory content is reachable by scrolling at %s." % viewport)
	if market_return != null:
		market_return.emit_signal("pressed")
		await get_tree().process_frame
		require(main.screen == "workshop", "Foundry Market Workshop return navigates to Workshop at %s." % viewport)
	main.screen = "unified_deck"
	main.render()
	await get_tree().process_frame
	var deck_return := main.find_child("UnifiedFoundryWorkshopReturn", true, false) as Button
	require(deck_return != null and _within_viewport(deck_return, viewport), "Deck Builder exposes the shared visible first-fold Workshop return at %s." % viewport)
	if deck_return != null:
		require(deck_return.focus_mode != Control.FOCUS_NONE and not deck_return.disabled, "Deck Builder Workshop return is keyboard-focusable at %s." % viewport)
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
		main.screen = "unified_market"
		main.unified_market_tab = "packs"
		main.render()
		await get_tree().process_frame
		var reveal := main.find_child("UnifiedPackReveal", true, false) as Control
		var reveal_grid := main.find_child("UnifiedPackRevealGrid", true, false) as GridContainer
		var keep_cards := main.find_child("UnifiedPackRevealKeepCards", true, false) as Button
		var reveal_cards := reveal.find_children("UnifiedPackCardView*", "Button", true, false) if reveal != null else []
		require(reveal != null and reveal.get_global_rect().position.is_equal_approx(Vector2.ZERO) and reveal.get_global_rect().size.is_equal_approx(viewport), "Five-card pack reveal modal covers the viewport at %s." % viewport)
		require(reveal_cards.size() == 5 and main.find_child("UnifiedPackRevealPager", true, false) == null, "Five-card pack reveal shows all five cards without a pager at %s." % viewport)
		require(reveal_grid != null and reveal_grid.columns == (3 if viewport.y > viewport.x else 5) and _within_viewport(reveal_grid, viewport), "Five-card pack reveal uses an in-bounds responsive card grid at %s." % viewport)
		for reveal_card in reveal_cards:
			require(reveal_card is Control and _within_viewport(reveal_card as Control, viewport), "Every five-card reveal card fits inside the viewport at %s." % viewport)
		require(keep_cards != null and _within_viewport(keep_cards, viewport), "Five-card reveal Keep cards action fits inside the viewport at %s." % viewport)
		var original_cards := ["cinderpaw", "aquafin", "voltwig"]
		var original_bonus_cards := ["mossmunk", "frostling"]
		GameManager.profile.pending_pack_reveal = {"pack_id":"bonus-fixture", "cards":original_cards.duplicate(), "bonus_cards":original_bonus_cards.duplicate(), "receipt":"ui-bonus-fixture"}
		main.render()
		await get_tree().process_frame
		var first_bonus_reveal := main.find_child("UnifiedPackReveal", true, false) as Control
		var first_bonus_count := first_bonus_reveal.find_children("UnifiedPackCardView*", "Button", true, false).size() if first_bonus_reveal != null else 0
		main.render()
		await get_tree().process_frame
		var second_bonus_reveal := main.find_child("UnifiedPackReveal", true, false) as Control
		var second_bonus_count := second_bonus_reveal.find_children("UnifiedPackCardView*", "Button", true, false).size() if second_bonus_reveal != null else 0
		var persisted_pending: Dictionary = GameManager.profile.get("pending_pack_reveal", {})
		require(persisted_pending.get("cards", []) == original_cards and persisted_pending.get("bonus_cards", []) == original_bonus_cards and first_bonus_count == 5 and second_bonus_count == 5, "Re-rendering a bonus-card reveal preserves its pending receipt and displayed total at %s." % viewport)
	# Feedback-pass contracts: battle omits the Workshop HUD, onboarding uses raw
	# blueprint art, and archive/deck routes share the book shell at every layout.
	main.screen = "unified_battle"
	main.render()
	await get_tree().process_frame
	require(main.find_child("WorkshopHud", true, false) == null, "Battle intentionally omits the Workshop HUD at %s." % viewport)
	GameManager.profile = RULES.new_profile()
	main.screen = "onboarding"
	main.render()
	await get_tree().process_frame
	var starter_schematics := main.find_children("StarterBlueprintSchematic", "TextureRect", true, false)
	var starter_inspect: Button
	if viewport.y > viewport.x:
		require(starter_schematics.size() == 1 and main.find_child("StarterCarouselCard", true, false) != null and main.find_child("StarterPrevious", true, false) != null and main.find_child("StarterNext", true, false) != null and main.find_child("StarterBlueprintTitle", true, false) != null and main.find_child("WorkshopHud", true, false) == null, "Portrait starter ceremony renders one focused carousel card with native paging and no post-selection HUD at %s." % viewport)
		starter_inspect = main.find_child("StarterInspectFocused", true, false) as Button
	else:
		require(starter_schematics.size() == 3 and starter_schematics.all(func(schematic): return (schematic as TextureRect).material != null) and main.find_child("StarterPager", true, false) == null and main.find_child("StarterBlueprintTitle", true, false) != null and main.find_child("WorkshopHud", true, false) == null, "Legacy landscape starter ceremony keeps all three technical blueprint cards at %s." % viewport)
		starter_inspect = main.find_child("StarterInspectCinderpaw", true, false) as Button
	require(starter_inspect != null and starter_inspect.focus_mode != Control.FOCUS_NONE and starter_inspect.custom_minimum_size.y >= (48.0 if viewport.y > viewport.x else 44.0), "Starter schematic itself exposes a separate touch-safe Inspect action at %s." % viewport)
	if starter_inspect != null:
		starter_inspect.emit_signal("pressed")
		await get_tree().process_frame
		require(main.find_child("StarterCardInspector", true, false) != null and main.pending_starter_id.is_empty(), "Inspecting a starter opens its schematic without selecting it at %s." % viewport)
		var inspect_select := main.find_child("StarterInspectorSelect", true, false) as Button if viewport.y > viewport.x else _button_named(main, "Select this blueprint")
		if inspect_select != null: inspect_select.emit_signal("pressed")
		await get_tree().process_frame
		require(main.find_child("StarterCardInspector", true, false) == null and main.pending_starter_id == "cinderpaw", "Starter inspector select closes the modal and updates the pending blueprint at %s." % viewport)
		main.show_starter_inspector("cinderpaw")
		await get_tree().process_frame
		var starter_modal := main.find_child("StarterCardInspector", true, false) as Control
		var starter_close := main.find_child("StarterInspectorClose", true, false) as Button if viewport.y > viewport.x else _button_named(main, "Close")
		require(starter_modal != null and starter_close != null and starter_close.focus_mode != Control.FOCUS_NONE and starter_modal.is_ancestor_of(starter_close), "Starter inspector installs a modal-owned focus target instead of leaving interaction behind it at %s." % viewport)
		var escape_event := InputEventKey.new(); escape_event.pressed = true; escape_event.keycode = KEY_ESCAPE
		main._unhandled_key_input(escape_event)
		await get_tree().process_frame
		require(main.find_child("StarterCardInspector", true, false) == null and main.screen == "onboarding", "Escape closes the starter inspector before leaving its ceremony at %s." % viewport)
		main.show_starter_inspector("cinderpaw")
		await get_tree().process_frame
		var inspect_close := main.find_child("StarterInspectorClose", true, false) as Button if viewport.y > viewport.x else _button_named(main, "Close")
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
	var archive_progress := main.find_child("ArchiveHudProgress", true, false) as ProgressBar
	var archive_filters := main.find_child("ArchiveBookFilters", true, false) as Control
	var archive_first_card := main.find_child("ArchiveBlueprintCardCinderpaw", true, false) as Control
	var archive_creature_art := main.find_child("ArchiveBlueprintSchematicArt", true, false) as TextureRect
	require(main.find_child("WorkshopHud", true, false) == null and main.find_child("FoundryHudProgress", true, false) == null and main.find_child("ArchiveBookShell", true, false) != null and main.find_child("ArchiveBookTabs", true, false) != null and archive_filters != null and main.find_child("ArchiveFilterAll", true, false) != null and main.find_child("ArchiveFilterCreatures", true, false) != null and main.find_child("ArchiveFilterSupport", true, false) != null and main.find_child("ArchiveBookCardGrid", true, false) != null and archive_progress != null and _within_viewport(archive_progress, viewport) and archive_first_card != null and _within_viewport(archive_first_card, viewport) and archive_creature_art != null and archive_creature_art.material != null and (viewport.y <= viewport.x or archive_filters.get_global_rect().end.x <= archive_first_card.get_global_rect().position.x), "Collection uses visible native blueprint cards, a compact HUD, attached filters, and no legacy framed HUD at %s." % viewport)
	main.set_archive_filter("support")
	await get_tree().process_frame
	require(main.unified_archive_filter == "support" and main.unified_page == 0, "Archive filters reset pagination at %s." % viewport)
	main.set_archive_filter("all")
	await get_tree().process_frame
	archive_first_card = main.find_child("ArchiveBlueprintCardCinderpaw", true, false) as Button
	if archive_first_card != null:
		archive_first_card.emit_signal("pressed")
		await get_tree().process_frame
		var archive_modal := main.find_child("UnifiedCardInspector", true, false) as Control
		var archive_close := _button_named(main, "Close")
		require(archive_modal != null and main.unified_inspector_tab == "card" and archive_close != null and archive_close.focus_mode != Control.FOCUS_NONE and archive_modal.is_ancestor_of(archive_close), "Collection card opens the card-tab inspector with a modal-owned focus target at %s." % viewport)
		var archive_escape := InputEventKey.new(); archive_escape.pressed = true; archive_escape.keycode = KEY_ESCAPE
		main._unhandled_key_input(archive_escape)
		await get_tree().process_frame
		require(main.find_child("UnifiedCardInspector", true, false) == null and main.screen == "unified_library", "Escape closes the archive inspector before leaving Collection at %s." % viewport)
	main.screen = "unified_deck"
	main.render()
	await get_tree().process_frame
	require(main.find_child("ArchiveBookShell", true, false) != null and main.find_child("ArchiveDeckClipboard", true, false) != null and main.find_child("ArchiveDeckSlots", true, false) != null and main.find_child("SaveActiveDeck", true, false) != null, "Deck Builder keeps real deck controls inside the archive-book clipboard at %s." % viewport)
	GameManager.profile = RULES.choose_starter(RULES.new_profile(), "cinderpaw").profile
	main.open_printer("cinderpaw")
	await get_tree().process_frame
	var starter_stage := main.find_child("FirstPrintEmptyBedProof", true, false) as Control
	var starter_facts := main.find_child("FirstPrintDockedBlueprint", true, false) as Control
	var starter_begin := main.find_child("BeginCreaturePrint", true, false) as Control
	var starter_back := main.find_child("ArcaneForgeBack", true, false) as Control
	var starter_fact_rect := starter_facts.get_global_rect() if starter_facts != null else Rect2()
	var starter_begin_rect := starter_begin.get_global_rect() if starter_begin != null else Rect2()
	var starter_back_rect := starter_back.get_global_rect() if starter_back != null else Rect2()
	require(not main.is_portrait_layout() or (main.find_child("FirstPrintR2PhysicalPlate", true, false) != null and starter_stage != null and starter_facts != null and main.find_child("FeedbackForgeStage", true, false) == null and main.find_child("ArcaneForgeStage", true, false) == null and starter_begin != null and starter_back != null and _within_viewport(starter_begin, viewport) and _within_viewport(starter_back, viewport) and starter_stage.get_global_rect().end.x < starter_fact_rect.position.x and not starter_fact_rect.intersects(starter_begin_rect) and not starter_fact_rect.intersects(starter_back_rect) and not starter_begin_rect.intersects(starter_back_rect)), "Portrait starter-selected Forge keeps an empty physical bed, external docked blueprint, and separate physical print/back plates at %s." % viewport)
	main.printer_sequence.phase = ArcaneForgeSequence.PRINTING
	main.printer_sequence.progress_bps = 6000
	main.render()
	await get_tree().process_frame
	await get_tree().process_frame
	var forge_heading := main.find_child("ForgeActiveHeading", true, false) as Control
	var forge_coins := main.find_child("ForgeCoinBadge", true, false) as Control
	var forge_progress := main.find_child("PrinterProgressBar", true, false) as ProgressBar
	require(forge_heading != null and _within_viewport(forge_heading, viewport) and forge_coins != null and _within_viewport(forge_coins, viewport) and forge_progress != null and _within_viewport(forge_progress, viewport) and forge_progress.value > 0.0, "Active Forge keeps the bright top readout, real coin badge, and numeric layer progress in bounds at %s." % viewport)
	# The image-led early returns must never bypass compatibility recovery.
	var prior_profile := GameManager.profile.duplicate(true)
	var prior_compatibility := GameManager.save_compatibility.duplicate(true)
	GameManager.profile = RULES.new_profile()
	GameManager.save_compatibility = {"compatible":false, "state":"future_schema", "message":"A newer build created this profile."}
	main.screen = "workshop"
	main.workshop_view = "overview"
	main.render()
	await get_tree().process_frame
	require(main.find_child("ReadOnlyCompatibilityHeader", true, false) != null and main.find_child("WorkshopFullBleed", true, false) == null, "Read-only compatibility keeps Workshop on the recovery shell instead of entering the visual route at %s." % viewport)
	GameManager.profile = prior_profile
	GameManager.save_compatibility = prior_compatibility
	main.queue_free()
	await get_tree().process_frame
	subviewport.queue_free()
	await get_tree().process_frame

func _ready() -> void:
	var source := (MAIN.instantiate().get_script() as GDScript).source_code
	var focus_source := source.substr(source.find("func focus_first_button"))
	require(focus_source.find("StarterCardInspector") >= 0 and focus_source.find("StarterCardInspector") < focus_source.find("for node in find_children"), "Modal focus priority is evaluated before generic route traversal.")
	_configure_isolated_save_paths()
	for viewport in [Vector2(1280, 720), Vector2(576, 1024), Vector2(720, 1280)]:
		await _exercise(viewport)
	if failures.is_empty(): print("PASS: v3 battle accessibility and responsive handoff matrix")
	get_tree().quit(0 if failures.is_empty() else 1)
