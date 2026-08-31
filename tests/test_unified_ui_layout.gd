extends Node

## Accessibility/UI contract for the shipped v3 screen. It deliberately tests
## control semantics and hot-seat privacy rather than obsolete 0.7 fixed-layout
## geometry; the battle component responds to portrait/landscape itself.
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
	var root := "user://printforge-validation/unified-ui-layout"
	if OS.get_name() == "Windows" and DirAccess.dir_exists_absolute("E:/"):
		root = "E:/CodexCache/printforge-validation/unified-ui-layout"
		var create_error := DirAccess.make_dir_recursive_absolute(root)
		require(create_error == OK or DirAccess.dir_exists_absolute(root), "Creates the isolated Windows UI-layout save directory.")
	else:
		var absolute_root := ProjectSettings.globalize_path(root)
		var create_error := DirAccess.make_dir_recursive_absolute(absolute_root)
		require(create_error == OK or DirAccess.dir_exists_absolute(absolute_root), "Creates the isolated cross-platform UI-layout save directory.")
	SaveService.configure_test_paths(root)

func _exercise(viewport: Vector2) -> void:
	GameManager.profile = _legal_profile()
	var subviewport := SubViewport.new()
	subviewport.size = Vector2i(viewport)
	subviewport.size_2d_override = Vector2i(viewport)
	subviewport.size_2d_override_stretch = true
	subviewport.disable_3d = true
	add_child(subviewport)
	var canvas := Control.new()
	canvas.position = Vector2.ZERO
	canvas.size = viewport
	subviewport.add_child(canvas)
	var main := MAIN.instantiate()
	var deck: Array = GameManager.active_deck_cards()
	main.battle = STATE.create(deck, deck, 81)
	main.battle_mode = "local"
	main.unified_local_handoff = true
	main.screen = "unified_battle"
	canvas.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().process_frame
	await get_tree().process_frame
	require(main.get_script().resource_path == "res://scripts/ui/main.gd", "Shipped battle shell is main.gd at %s." % viewport)
	require(main.find_child("UnifiedBattleHeading", true, false) != null, "Battle heading renders at %s." % viewport)
	var initial_stage := main.find_child("UnifiedBattleSpriteStage", true, false) as Control
	require(initial_stage != null and _within_viewport(initial_stage, viewport), "Unified arena mounts an in-bounds persistent sprite stage at %s." % viewport)
	require(main.find_child("UnifiedLocalHandoff", true, false) != null, "Hot-seat privacy handoff renders at %s." % viewport)
	require(main.find_child("UnifiedBattleHandGrid", true, false) == null, "Hidden hand is omitted during hot-seat handoff at %s." % viewport)
	require(main.find_child("UnifiedBattlePrimaryAction", true, false) == null, "Hot-seat handoff exposes no phase-advance control at %s." % viewport)
	require(_button_named(main, "Ready Player") != null, "Handoff has an explicit ready action at %s." % viewport)
	main.unified_local_handoff = false
	main.render()
	await get_tree().process_frame
	require(main.find_child("UnifiedBattleHandGrid", true, false) != null, "Owner hand renders after handoff at %s." % viewport)
	var local_primary := main.find_child("UnifiedBattlePrimaryAction", true, false) as Button
	require(local_primary != null and _within_viewport(local_primary, viewport), "Phase-specific action is visible in the battle first fold at %s." % viewport)
	if local_primary != null:
		require(local_primary.focus_mode != Control.FOCUS_NONE and not local_primary.disabled, "Phase-specific action is keyboard-focusable at %s." % viewport)
	require(main.is_portrait_layout() == (viewport.y > viewport.x), "Battle component detects orientation at %s." % viewport)
	# Exercise the human Main Phase path directly. The controlled opening hand makes
	# the card selection and FIFO queue assertion deterministic at both layouts.
	main.battle = STATE.create(deck, deck, 81)
	main.battle.starting_seat = 0
	main.battle.active_seat = 0
	main.battle.turn = 1
	main.battle.phase = "draw"
	main.battle.player(0).hand = ["cinderpaw"]
	main.battle.player(0).deck = []
	main.battle.player(0).filament = 200
	main.battle_mode = "daily_training"
	main.unified_ai_pending = false
	main.unified_local_handoff = false
	main.unified_selected_card_id = ""
	main.screen = "unified_battle"
	main.render()
	await get_tree().process_frame
	var begin_main := main.find_child("UnifiedBattlePrimaryAction", true, false) as Button
	var opening_card := main.find_child("UnifiedHandCinderpaw", true, false) as Button
	require(begin_main != null and begin_main.text == "Begin Main" and _within_viewport(begin_main, viewport), "Draw phase exposes an in-bounds Begin Main action at %s." % viewport)
	require(opening_card != null and opening_card.disabled and "Main Phase" in opening_card.tooltip_text and "70F" in opening_card.text, "Draw phase shows the actual filament cost and explains disabled hand cards at %s." % viewport)
	if begin_main != null:
		begin_main.emit_signal("pressed")
		await get_tree().process_frame
	require(str(main.battle.phase) == "main", "Begin Main advances the deterministic battle to Main at %s." % viewport)
	opening_card = main.find_child("UnifiedHandCinderpaw", true, false) as Button
	require(opening_card != null and not opening_card.disabled and _within_viewport(opening_card, viewport), "Main Phase exposes an in-bounds playable hand card at %s." % viewport)
	if opening_card != null:
		opening_card.emit_signal("pressed")
		await get_tree().process_frame
	var picker := main.find_child("UnifiedPlayTargetPicker", true, false) as Control
	var selected_card := main.find_child("UnifiedSelectedHandCard", true, false) as Control
	var queue_creature := main.find_child("UnifiedPlayQueueCreature", true, false) as Button
	require(picker != null and _within_viewport(picker, viewport), "Selected card target/action picker remains in the viewport at %s." % viewport)
	require(selected_card != null and _within_viewport(selected_card, viewport), "Selected hand card is visibly named at %s." % viewport)
	require(queue_creature != null and _within_viewport(queue_creature, viewport) and queue_creature.focus_mode != Control.FOCUS_NONE, "Queue action is visible and keyboard/touch reachable at %s." % viewport)
	if queue_creature != null:
		queue_creature.emit_signal("pressed")
		await get_tree().process_frame
	require(not main.battle.player(0).hand.has("cinderpaw") and main.battle.player(0).queue.size() == 1 and int(main.battle.player(0).filament) == 130, "Queueing a selected creature consumes the hand card and its actual filament cost at %s." % viewport)
	# Resolve Printing can stop on a completed creature. That mandatory choice must
	# replace the invalid phase action and conceal optional hand/attack controls.
	main.battle = STATE.create(deck, deck, 81)
	main.battle.starting_seat = 0
	main.battle.active_seat = 0
	main.battle.turn = 1
	main.battle.phase = "print"
	main.battle.player(0).slots = [null, null, null]
	main.battle.player(0).queue = [{"card_id":"cinderpaw", "remaining":1, "target":-1, "cost":70}]
	main.battle_mode = "daily_training"
	main.unified_ai_pending = false
	main.unified_selected_card_id = ""
	main.render()
	await get_tree().process_frame
	var resolve_printing := main.find_child("UnifiedBattlePrimaryAction", true, false) as Button
	require(resolve_printing != null and resolve_printing.text == "Resolve Printing", "Print phase exposes Resolve Printing before a completed print decision at %s." % viewport)
	if resolve_printing != null:
		resolve_printing.emit_signal("pressed")
	var print_stage := main.find_child("UnifiedBattleSpriteStage", true, false)
	require(int(main.unified_battle_presentation.get("token", 0)) > 0 and str(main.unified_battle_presentation.get("kind", "")) == "print" and print_stage == initial_stage, "Accepted Print resolution advances the persistent stage through a print receipt at %s." % viewport)
	await get_tree().process_frame
	var pending_panel := main.find_child("UnifiedPendingPrintDecision", true, false) as Control
	var pending_choices := main.find_child("UnifiedPendingPlaceChoices", true, false) as GridContainer
	require(str(main.battle.pending.get("kind", "")) == "place", "Resolve Printing creates the pending placement state at %s." % viewport)
	require(main.find_child("UnifiedBattlePrimaryAction", true, false) == null and main.find_child("UnifiedBattleHandGrid", true, false) == null and main.find_child("UnifiedAttackTargetPicker", true, false) == null, "Pending placement hides the invalid phase, hand, and attack controls at %s." % viewport)
	require(pending_panel != null and _within_viewport(pending_panel, viewport), "Pending placement panel is visible in bounds at %s." % viewport)
	var pending_place_buttons: Array = pending_choices.get_children() if pending_choices != null else []
	require(pending_place_buttons.size() == 6, "Every open field slot has Attack and Defense placement choices at %s." % viewport)
	for choice in pending_place_buttons:
		require(choice is Button and _within_viewport(choice as Control, viewport) and (choice as Button).focus_mode != Control.FOCUS_NONE and (choice as Button).custom_minimum_size.y >= 44.0 and not (choice as Button).accessibility_name.is_empty(), "Pending placement choice is in-bounds and accessible at %s." % viewport)
	var place_slot_one_attack := main.find_child("UnifiedPendingPlaceSlot1Attack", true, false) as Button
	if place_slot_one_attack != null:
		place_slot_one_attack.emit_signal("pressed")
		await get_tree().process_frame
	require(main.battle.pending.is_empty() and main.battle.player(0).slots[0] != null and str(main.battle.player(0).slots[0].get("card_id", "")) == "cinderpaw", "Selecting a pending placement clears it and places the completed creature at %s." % viewport)
	# Equipment waiting in holding uses the same mandatory decision surface and
	# only offers occupied creatures with the matching gear slot still empty.
	main.battle = STATE.create(deck, deck, 81)
	main.battle.starting_seat = 0
	main.battle.active_seat = 0
	main.battle.turn = 1
	main.battle.phase = "print"
	main.battle.player(0).slots = [STATE._unit(RULES.card("cinderpaw")), null, null]
	main.battle.player(0).holding = [{"card_id":"standard_full_suit", "target":0}]
	main.battle.pending = {"kind":"attach", "seat":0, "card_id":"standard_full_suit", "holding_index":0}
	main.render()
	await get_tree().process_frame
	var attach_panel := main.find_child("UnifiedPendingPrintDecision", true, false) as Control
	var attach_slot_one := main.find_child("UnifiedPendingAttachSlot1", true, false) as Button
	require(attach_panel != null and _within_viewport(attach_panel, viewport) and attach_slot_one != null and _within_viewport(attach_slot_one, viewport) and attach_slot_one.focus_mode != Control.FOCUS_NONE and attach_slot_one.custom_minimum_size.y >= 44.0 and not attach_slot_one.accessibility_name.is_empty(), "Pending equipment offers an accessible legal attachment choice at %s." % viewport)
	if attach_slot_one != null:
		attach_slot_one.emit_signal("pressed")
		await get_tree().process_frame
	require(main.battle.pending.is_empty() and main.battle.player(0).holding.is_empty() and not (main.battle.player(0).slots[0].get("equipment", {}).get("armor", {}) as Dictionary).is_empty(), "Selecting a pending attachment clears it and equips the compatible creature at %s." % viewport)
	# Battle authority may remove the defender immediately; the stage receipt must
	# still retain the accepted pre-action attacker and defender snapshots.
	main.battle = STATE.create(deck, deck, 82)
	main.battle.starting_seat = 1
	main.battle.active_seat = 0
	main.battle.turn = 2
	main.battle.phase = "attack"
	main.battle.player(0).slots[0] = STATE._unit(RULES.card("cinderpaw"))
	main.battle.player(0).slots[0].ready = true
	main.battle.player(1).slots[0] = STATE._unit(RULES.card("aquafin"))
	main.battle.player(1).slots[0].hp = 1
	var attack_token_before := int(main.unified_battle_presentation.get("token", 0))
	main._submit_unified_intent({"type":"attack", "slot":0, "target":0})
	require(int(main.unified_battle_presentation.get("token", 0)) == attack_token_before + 1 and str(main.unified_battle_presentation.get("kind", "")) == "attack" and str((main.unified_battle_presentation.get("left", {}) as Dictionary).get("id", "")) == "cinderpaw" and str((main.unified_battle_presentation.get("right", {}) as Dictionary).get("id", "")) == "aquafin", "Accepted player attacks create a pre-resolution stage receipt at %s." % viewport)
	var attack_token := int(main.unified_battle_presentation.get("token", 0))
	main._settle_unified_battle_presentation(attack_token)
	await get_tree().process_frame
	require(str(main.unified_battle_presentation.get("kind", "")) == "" and (main.unified_battle_presentation.get("right", {}) as Dictionary).is_empty(), "Settled attack presentation returns to the live board after a defeated defender at %s." % viewport)
	main._settle_unified_battle_presentation(attack_token - 1)
	require(str(main.unified_battle_presentation.get("kind", "")) == "", "Stale presentation timers cannot alter the newer settled token at %s." % viewport)
	# Rival turns are public-board-only until the deferred AI finishes. The player
	# must never receive a phase button or a view of the rival's private hand.
	main.battle = STATE.create(deck, deck, 81)
	main.battle.starting_seat = 1
	main.battle.active_seat = 1
	main.battle.turn = 1
	main.battle.phase = "attack"
	main.battle.player(1).slots[0] = STATE._unit(RULES.card("cinderpaw"))
	main.battle.player(1).slots[0].ready = true
	main.battle_mode = "daily_training"
	main.unified_ai_pending = true
	main.unified_selected_card_id = ""
	main.render()
	await get_tree().process_frame
	require(main.find_child("UnifiedBattlePrimaryAction", true, false) == null and main.find_child("UnifiedBattleHandGrid", true, false) == null, "Pending non-local rival turn exposes neither controls nor the rival hand at %s." % viewport)
	await main._run_unified_ai()
	await get_tree().process_frame
	require(int(main.battle.active_seat) == 0 and not main.unified_ai_pending and main.find_child("UnifiedBattlePrimaryAction", true, false) != null and main.find_child("UnifiedBattleHandGrid", true, false) != null, "A rival-first turn skips its forbidden opening attack and returns interactive control instead of leaving calculating-only UI at %s." % viewport)
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
