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
	require(_count_card_views(main) > 0 and main.find_child("ArchiveBookShell", true, false) != null, "Collection renders owned cards in the archive book")
	main.screen = "unified_deck"
	main.render()
	await get_tree().process_frame
	require(_count_card_views(main) > 0 and main.find_child("ArchiveBookShell", true, false) != null, "Deck Builder renders owned cards in the archive book")

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
