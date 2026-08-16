extends Node
const MAIN := preload("res://scenes/main.tscn")
var failures: Array[String] = []
func require(value: bool, message: String) -> void:
	if not value: failures.append(message); push_error(message)
func _ready() -> void:
	var profile: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "cinderpaw").profile
	profile.coins = 9999
	for card in Catalog.SUPPORT_CARDS: profile.support_cards[str(card.id)] = 2
	GameManager.profile = profile
	var main := MAIN.instantiate(); add_child(main); await get_tree().process_frame
	main.screen = "archive"; main.render(); await get_tree().process_frame
	require(main.find_child("CardArchiveGallery", true, false) != null and main.find_child("ArchiveFilterAll", true, false) is Button and main.find_child("ArchiveFilterOwned", true, false) is Button, "archive navigation, gallery and filters render")
	main.card_archive_owned_only = true; main.render(); await get_tree().process_frame
	var archive_card := main.find_child("ArchiveCard*", true, false) as Button; require(archive_card != null and archive_card.custom_minimum_size.y >= 48 and archive_card.focus_mode == Control.FOCUS_ALL, "archive card is touch/controller actionable")
	main.show_card_archive_detail(Catalog.support_card("raw_filament")); await get_tree().process_frame
	main.show_card_archive_detail(Catalog.support_card("quick_patch")); await get_tree().process_frame
	require(_named_count(main, "CardArchiveDetail") == 1 and main.find_child("CardArchiveDetail", true, false).get_child(0).text.contains("Quick Patch"), "archive replaces detail with one current panel")
	main.screen = "deck"; main.deck_draft = GameManager.active_deck_cards(); main.deck_draft.pop_back(); main.render(); await get_tree().process_frame
	var copies_before: int = main.deck_draft.count("arcane_spark")
	var deck_card := _card_with_tooltip(main, "Arcane Spark")
	require(deck_card != null, "Arcane Spark visual deck card exists")
	if deck_card != null: deck_card.emit_signal("pressed")
	await get_tree().process_frame
	require(main.deck_selected_card_id == "arcane_spark" and main.deck_draft.count("arcane_spark") == copies_before and main.find_child("DeckSelectedCardTray", true, false) != null, "deck card tap selects without mutating draft")
	var add_selected := main.find_child("DeckSelectedAdd", true, false) as Button; add_selected.emit_signal("pressed"); await get_tree().process_frame
	require(main.deck_draft.count("arcane_spark") == copies_before + 1, "selected tray explicitly adds")
	var remove_selected := main.find_child("DeckSelectedRemove", true, false) as Button; remove_selected.emit_signal("pressed"); await get_tree().process_frame
	require(main.deck_draft.count("arcane_spark") == copies_before and main.deck_selected_card_id == "arcane_spark", "selected tray removes and stable ID survives render")
	main.screen = "shop"; main.render(); await get_tree().process_frame
	var has_shop_card := false
	for offer in GameManager.daily_shop(main.shop_day_key):
		if str(offer.get("kind", "")) == "support_card": has_shop_card = main.find_child("ShopCard%s" % str(offer.item_id).capitalize(), true, false) != null
	var shop_preview := main.find_child("ShopCardRaw_filament", true, false) as Button
	require(has_shop_card and (shop_preview == null or shop_preview.focus_mode == Control.FOCUS_NONE), "shop support-card visual offer is decorative")
	main.battle = BattleState.create(["cinderpaw"], ["mossmunk"], 3, 3, 2); main.battle.players[0].hand = ["final_pass"]; main.battle.players[0].filament = 0; main.screen = "battle"; main.battle_secondary_open = true; main.battle_secondary_tab = "hand"; main.render(); await get_tree().process_frame
	var disabled := main.find_child("BattleCard*", true, false) as Button; require(disabled != null and disabled.disabled and main.find_child("BattleHandGrid", true, false) != null, "solo hand shows disabled card and count grid")
	main.battle.players[0].hand = ["raw_filament"]; main.battle.players[0].filament = 3; main.submit_battle_card("raw_filament"); require(main.battle.players[0].discard.has("raw_filament"), "solo hand play moves card to discard")
	main.start_local_vs(); await get_tree().process_frame
	var hidden := main.find_child("LocalHiddenCardBack", true, false) as Button
	require(hidden != null and hidden.focus_mode == Control.FOCUS_NONE and hidden.mouse_filter == Control.MOUSE_FILTER_IGNORE, "local versus hides private hand behind noninteractive card back")
	main.local_ready_seat = main.local_authority.state.active_player; main.render(); await get_tree().process_frame
	require(main.find_child("LocalRevealedCardGrid", true, false) != null and main.find_child("LocalHiddenCardBack", true, false) == null, "local versus reveals visual cards only after ready")
	if failures.is_empty(): print("PASS: support-card archive/deck/shop/solo/local UI regression")
	call_deferred("finish")
func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)

func _named_count(root: Node, node_name: String) -> int:
	var total := 1 if root.name == node_name else 0
	for child in root.get_children(): total += _named_count(child, node_name)
	return total

func _card_with_tooltip(root: Node, text: String) -> Button:
	for candidate in root.find_children("*", "Button", true, false):
		if candidate is Button and str(candidate.tooltip_text).contains(text): return candidate as Button
	return null
