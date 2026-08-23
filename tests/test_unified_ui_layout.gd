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
	require(main.find_child("UnifiedLocalHandoff", true, false) != null, "Hot-seat privacy handoff renders at %s." % viewport)
	require(main.find_child("UnifiedBattleHandGrid", true, false) == null, "Hidden hand is omitted during hot-seat handoff at %s." % viewport)
	require(_button_named(main, "Ready Player") != null, "Handoff has an explicit ready action at %s." % viewport)
	main.unified_local_handoff = false
	main.render()
	await get_tree().process_frame
	require(main.find_child("UnifiedBattleHandGrid", true, false) != null, "Owner hand renders after handoff at %s." % viewport)
	require(main.find_child("UnifiedBattlePhaseActions", true, false) != null, "Explicit phase controls render at %s." % viewport)
	require(_button_named(main, "Advance phase") != null, "Phase advance is keyboard-focusable button at %s." % viewport)
	require(main.is_portrait_layout() == (viewport.y > viewport.x), "Battle component detects orientation at %s." % viewport)
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
	main.queue_free()
	await get_tree().process_frame
	subviewport.queue_free()
	await get_tree().process_frame

func _ready() -> void:
	for viewport in [Vector2(1280, 720), Vector2(576, 1024)]:
		await _exercise(viewport)
	if failures.is_empty(): print("PASS: v3 battle accessibility and responsive handoff matrix")
	get_tree().quit(0 if failures.is_empty() else 1)
