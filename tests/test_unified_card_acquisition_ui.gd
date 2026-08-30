extends Node

## Current v3.2 acquisition UI coverage. This stays on the Foundry surfaces and
## verifies the permanently-linked creature card/blueprint rule through the
## same transition the Card Shop uses.
const MAIN := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")
const CARD_VIEW := preload("res://scripts/ui/unified_card_view.gd")
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _count_card_views(node: Node) -> int:
	var total := 1 if node.get_script() == CARD_VIEW else 0
	for child in node.get_children(): total += _count_card_views(child)
	return total

func _count_archive_cards(node: Node) -> int:
	return node.find_children("ArchiveBlueprintCard*", "Button", true, false).size()

func _tree_has_text(node: Node, fragment: String) -> bool:
	if node is Label and fragment in (node as Label).text: return true
	for child in node.get_children():
		if _tree_has_text(child, fragment): return true
	return false

func _profile() -> Dictionary:
	var profile := RULES.new_profile()
	profile.forge_coins = 1200
	profile = RULES.choose_starter(profile, "cinderpaw").profile
	return RULES.print_starter(profile).profile

func _current_creature_offer() -> Dictionary:
	for offer in (GameManager.market_snapshot().get("cards", []) as Array):
		var card_id := str(offer.get("id", ""))
		if not Catalog.creature(card_id).is_empty(): return offer
	return {}

func _ready() -> void:
	GameManager.profile = _profile()
	var main := MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame

	# Use current market stock and the authoritative GameManager facade, instead
	# of a retired fixed day key or pre-v3 blueprint/discovered fields.
	var offer := _current_creature_offer()
	require(not offer.is_empty(), "fixture finds a current Card Shop creature offer")
	main.screen = "unified_market"
	main.unified_market_tab = "cards"
	main.render()
	await get_tree().process_frame
	require(_count_card_views(main) >= 0 and main.find_child("UnifiedMarketScroll", true, false) != null, "current Foundry Card Shop renders inside its responsive market surface")
	var creature_id := str(offer.get("id", ""))
	var before_cards := int(GameManager.profile.get("owned_cards", {}).get(creature_id, 0))
	var buy := GameManager.buy_market_card_v3(creature_id)
	await get_tree().process_frame
	require(bool(buy.get("ok", false)) and int(GameManager.profile.get("owned_cards", {}).get(creature_id, 0)) == before_cards + 1 and bool(GameManager.profile.get("owned_blueprints", {}).get(creature_id, false)), "current Card Shop creature grant adds its card copy and permanently linked printable blueprint")

	main.screen = "unified_library"
	main.render()
	await get_tree().process_frame
	require(_count_archive_cards(main) > 0 and main.find_child("ArchiveBookShell", true, false) != null and main.find_child("ArchiveBookCardGrid", true, false) != null, "Collection renders owned cards in the native archive book")
	main.screen = "unified_deck"
	main.render()
	await get_tree().process_frame
	require(_count_archive_cards(main) > 0 and main.find_child("ArchiveBookShell", true, false) != null and main.find_child("ArchiveDeckClipboard", true, false) != null and main.find_child("SaveActiveDeck", true, false) is Button, "Deck Builder renders owned cards and real deck controls in the native archive book")

	# The feedback Deck route must initialize from persisted state once, including
	# a deliberately empty (or later cleared) pre-print array. It cannot use an
	# empty Array as a proxy for first render or it can erase a valid loadout.
	var varied_deck := GameManager.active_deck_cards()
	var first_support := -1
	var second_support := -1
	for index in varied_deck.size():
		if str(RULES.card(str(varied_deck[index])).get("type", "")) != "creature":
			if first_support < 0: first_support = index
			elif second_support < 0:
				second_support = index
				break
	RULES.grant_card(GameManager.profile, "aquafin")
	RULES.grant_card(GameManager.profile, "voltwig")
	if first_support >= 0 and second_support >= 0:
		var original_first := str(varied_deck[first_support])
		var original_second := str(varied_deck[second_support])
		var owned: Dictionary = GameManager.profile.get("owned_cards", {})
		owned[original_first] = int(owned.get(original_first, 0)) - 1
		owned[original_second] = int(owned.get(original_second, 0)) - 1
		varied_deck[first_support] = "aquafin"
		varied_deck[second_support] = "voltwig"
		require(RULES.deck_reason(GameManager.profile, varied_deck).is_empty() and GameManager.save_unified_deck(varied_deck), "fixture saves a legal four-creature active deck for Deck Builder draft coverage")
	GameManager.profile.preprints = ["cinderpaw"]
	main.feedback_deck_draft_initialized = false
	main.screen = "unified_deck"
	main.render()
	await get_tree().process_frame
	require(main.unified_preprint_draft == ["cinderpaw"] and main.find_child("ArchivePrePrintVoltwig", true, false) is Button, "Deck Builder first entry loads a saved pre-print and exposes every active-draft creature, including the fourth unique creature")
	main.unified_preprint_draft.clear()
	main.render()
	await get_tree().process_frame
	var voltwig_pick := main.find_child("ArchivePrePrintVoltwig", true, false) as Button
	require(main.unified_preprint_draft.is_empty() and voltwig_pick != null, "an intentionally cleared feedback pre-print draft is not silently reloaded on render")
	if voltwig_pick != null:
		voltwig_pick.pressed.emit()
		await get_tree().process_frame
		require("voltwig" in main.unified_preprint_draft, "the legal creature beyond the old three-entry clipboard slice remains selectable")

	# The physical archive's inspector remains truthful to v3 cards: creatures
	# have BEND rather than a retired Attack 0 placeholder, while support cards
	# show their actual card data without creature zeroes.
	main.screen = "unified_library"
	main.unified_inspector_id = "cinderpaw"
	main.unified_inspector_tab = "stats"
	main.render()
	await get_tree().process_frame
	require(_tree_has_text(main, "BEND") and not _tree_has_text(main, "ATK 0"), "creature archive inspector reports real HP/BEND/print data rather than a nonexistent Attack 0")
	var support_id := "raw_filament"
	main.unified_inspector_id = support_id
	main.unified_inspector_tab = "stats"
	main.render()
	await get_tree().process_frame
	require(_tree_has_text(main, "Cost") and not _tree_has_text(main, "HP 0"), "support archive inspector reports truthful support fields without creature zeroes")

	# Open the first entitlement through the UI. Every Keep action must immediately
	# open the next one until all three exactly-once Basic rewards are exhausted.
	main._open_next_starter_pack()
	await get_tree().process_frame
	var reveal := main.find_child("UnifiedPackReveal", true, false) as Control
	require(main.screen == "unified_library" and reveal != null and reveal.is_visible_in_tree() and _count_card_views(reveal) > 0 and int(GameManager.profile.get("starter_pack_rewards", {}).get("opened", 0)) == 1, "first starter reward opens as a visible Collection reveal")
	main._keep_unified_pack_cards()
	await get_tree().process_frame
	reveal = main.find_child("UnifiedPackReveal", true, false) as Control
	require(reveal != null and reveal.is_visible_in_tree() and int(GameManager.profile.get("starter_pack_rewards", {}).get("opened", 0)) == 2 and bool(GameManager.profile.get("pending_pack_reveal", {}).get("starter_reward", false)), "keeping starter pack 1 automatically opens starter pack 2")
	main._keep_unified_pack_cards()
	await get_tree().process_frame
	reveal = main.find_child("UnifiedPackReveal", true, false) as Control
	require(reveal != null and reveal.is_visible_in_tree() and int(GameManager.profile.get("starter_pack_rewards", {}).get("opened", 0)) == 3 and bool(GameManager.profile.get("pending_pack_reveal", {}).get("starter_reward", false)), "keeping starter pack 2 automatically opens starter pack 3")
	main._keep_unified_pack_cards()
	await get_tree().process_frame
	var owned_after_rewards: Dictionary = (GameManager.profile.get("owned_cards", {}) as Dictionary).duplicate(true)
	var pending_after_rewards: Dictionary = (GameManager.profile.get("pending_pack_reveal", {}) as Dictionary).duplicate(true)
	require(main.screen == "unified_library" and main.find_child("UnifiedPackReveal", true, false) == null and int(GameManager.profile.get("starter_pack_rewards", {}).get("opened", 0)) == 3 and pending_after_rewards.is_empty(), "keeping starter pack 3 clears the reveal and leaves the player in Collection")
	var fourth := GameManager.claim_next_starter_pack()
	require(not bool(fourth.get("ok", false)) and GameManager.profile.get("owned_cards", {}) == owned_after_rewards and GameManager.profile.get("pending_pack_reveal", {}) == pending_after_rewards and int(GameManager.profile.get("starter_pack_rewards", {}).get("opened", 0)) == 3, "no fourth starter pack can change cards, pending state, or the three-pack receipt count")

	main.queue_free()
	await get_tree().process_frame
	if failures.is_empty(): print("PASS: unified card acquisition and three-pack Collection reveal chain")
	get_tree().quit(0 if failures.is_empty() else 1)
