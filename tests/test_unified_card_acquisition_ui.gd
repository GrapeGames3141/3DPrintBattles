extends Node

const MAIN := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")
const CARD_VIEW := preload("res://scripts/ui/unified_card_view.gd")
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _has_scroll(node: Node) -> bool:
	if node is ScrollContainer: return true
	for child in node.get_children():
		if _has_scroll(child): return true
	return false

func _count_card_views(node: Node) -> int:
	var total := 1 if node.get_script() == CARD_VIEW else 0
	for child in node.get_children(): total += _count_card_views(child)
	return total

func _has_text(node: Node, text: String) -> bool:
	if node is Label and text in (node as Label).text: return true
	for child in node.get_children():
		if _has_text(child, text): return true
	return false

func _catalog_creature_offer() -> Dictionary:
	for day_number in range(1, 80):
		var day := "2026-08-%02d" % day_number
		for offer in RULES.market_offers(day):
			var card_id := str(offer.get("id", ""))
			if not Catalog.creature(card_id).is_empty(): return {"day":day,"id":card_id}
	return {}

func _profile() -> Dictionary:
	var profile := RULES.ensure(ProfileRules.new_profile())
	profile.coins = 1200
	profile = RULES.choose_starter(profile, "cinderpaw").profile
	return RULES.print_starter(profile).profile

func _ready() -> void:
	GameManager.profile = _profile()
	var main := MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame
	var offer := _catalog_creature_offer()
	require(not offer.is_empty(), "fixture finds a deterministic offered catalog creature")
	main.shop_day_key = str(offer.get("day", ""))
	main.screen = "unified_market"
	main.render()
	await get_tree().process_frame
	require(not _has_scroll(main) and _count_card_views(main) > 0, "market renders clickable 2:3 UnifiedCardView cards without a scrollbar")
	main._buy_unified_market_card(str(offer.get("id", "")))
	await get_tree().process_frame
	var creature_id := str(offer.get("id", ""))
	require(creature_id in GameManager.profile.blueprints and creature_id in GameManager.profile.discovered and _has_text(main, "Blueprint and Forgedex entry unlocked"), "market creature purchase visibly unlocks blueprint and Forgedex")
	main.screen = "unified_library"
	main.render()
	await get_tree().process_frame
	require(not _has_scroll(main) and _count_card_views(main) > 0, "owned-only Library uses UnifiedCardView cards")
	main.screen = "unified_deck"
	main.render()
	await get_tree().process_frame
	require(not _has_scroll(main) and _count_card_views(main) > 0, "Deck Builder uses UnifiedCardView cards")
	var codex_creatures: Array = []
	for definition in RULES.all_cards():
		if str(definition.get("type", "")) == "creature":
			codex_creatures.append(definition)
	main.unified_codex_page = int(codex_creatures.find_custom(func(definition: Dictionary) -> bool: return str(definition.get("id", "")) == creature_id) / 4)
	main.screen = "unified_forgedex"
	main.render()
	await get_tree().process_frame
	require(not _has_scroll(main) and _count_card_views(main) > 0 and _has_text(main, str(Catalog.creature(creature_id).get("name", ""))), "purchased creature is known in the responsive no-scroll Forgedex")
	main.screen = "unified_market"
	main.render()
	await get_tree().process_frame
	main._buy_unified_pack("pack_3")
	await get_tree().process_frame
	var reveal := main.find_child("UnifiedPackReveal", true, false) as Control
	require(reveal != null and reveal.is_visible_in_tree() and _count_card_views(reveal) > 0 and not _has_scroll(reveal), "pack purchase immediately opens a visible no-scroll card reveal")
	if reveal != null:
		var viewport := main.get_viewport().get_visible_rect().size
		require(reveal.get_global_rect().position.is_equal_approx(Vector2.ZERO) and reveal.get_global_rect().size.is_equal_approx(viewport), "pack reveal modal covers the viewport")
	main._keep_unified_pack_cards()
	await get_tree().process_frame
	require((GameManager.profile.get("pending_pack_reveal", {}) as Dictionary).is_empty() and main.find_child("UnifiedPackReveal", true, false) == null, "Keep cards clears persisted pending reveal and closes modal")
	main.queue_free()
	await get_tree().process_frame
	if failures.is_empty(): print("PASS: unified card acquisition, reveal, and Forgedex UI")
	get_tree().quit(0 if failures.is_empty() else 1)
