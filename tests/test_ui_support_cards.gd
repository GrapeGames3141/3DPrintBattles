extends Node
const MAIN := preload("res://scenes/main.tscn")
var failures: Array[String] = []
func require(value: bool, message: String) -> void:
	if not value: failures.append(message); push_error(message)

func horizontally_centered(child: Control, host: Control) -> bool:
	if child == null or host == null: return false
	var child_center := child.get_global_rect().get_center().x
	var host_center := host.get_global_rect().get_center().x
	return absf(child_center - host_center) <= 2.0

func _ready() -> void:
	var profile: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "cinderpaw").profile
	profile.coins = 9999
	for card in Catalog.SUPPORT_CARDS: profile.support_cards[str(card.id)] = 2
	GameManager.profile = profile
	var main := MAIN.instantiate(); add_child(main); await get_tree().process_frame
	var portrait := Vector2i(576, 1024)
	get_viewport().size = portrait; main.size = Vector2(portrait)
	main.screen = "archive"; main.render(); await get_tree().process_frame
	var archive_gallery := main.find_child("CardArchiveGallery", true, false) as GridContainer
	var archive_host := main.find_child("CardArchiveGalleryHost", true, false) as CenterContainer
	require(archive_gallery != null and main.find_child("ArchiveFilterAll", true, false) is Button and main.find_child("ArchiveFilterOwned", true, false) is Button, "archive navigation, gallery and filters render")
	require(horizontally_centered(archive_gallery, archive_host), "portrait archive gallery centers its authored two-column card bounds within the Foundry host")
	main.card_archive_owned_only = true; main.render(); await get_tree().process_frame
	var archive_card := main.find_child("ArchiveCard*", true, false) as Button; require(archive_card != null and archive_card.custom_minimum_size.y >= 48 and archive_card.focus_mode == Control.FOCUS_ALL, "archive card is touch/controller actionable")
	_require_card_front(archive_card, false, false, "archive full card")
	main.show_card_archive_detail(Catalog.support_card("raw_filament")); await get_tree().process_frame
	main.show_card_archive_detail(Catalog.support_card("quick_patch")); await get_tree().process_frame
	require(_named_count(main, "CardArchiveDetail") == 1 and main.find_child("CardArchiveDetail", true, false).get_child(0).text.contains("Quick Patch"), "archive replaces detail with one current panel")
	main.screen = "deck"; main.deck_draft = GameManager.active_deck_cards(); main.deck_draft.pop_back(); main.render(); await get_tree().process_frame
	var deck_gallery := main.find_child("DeckCardGallery", true, false) as GridContainer
	var deck_host := main.find_child("DeckCardGalleryHost", true, false) as CenterContainer
	require(horizontally_centered(deck_gallery, deck_host), "portrait deck gallery centers its authored two-column card bounds within the Foundry host")
	var copies_before: int = main.deck_draft.count("arcane_spark")
	var deck_card := _card_with_tooltip(main, "Arcane Spark")
	require(deck_card != null, "Arcane Spark visual deck card exists")
	_require_card_front(deck_card, false, false, "deck gallery card")
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
	if shop_preview != null: _require_card_front(shop_preview, false, true, "shop preview")
	main.battle = BattleState.create(["cinderpaw"], ["mossmunk"], 3, 3, 2); main.battle.players[0].hand = ["final_pass", "coolant", "raw_filament", "arcane_spark"]; main.battle.players[0].filament = 0; main.screen = "battle"; main.battle_secondary_open = true; main.battle_secondary_tab = "hand"; main.render(); await get_tree().process_frame
	var disabled := main.find_child("BattleCard*", true, false) as Button; require(disabled != null and disabled.disabled and main.find_child("BattleHandGrid", true, false) != null, "solo hand shows disabled card and count grid")
	_require_card_front(disabled, true, false, "disabled battle card")
	var carousel := main.find_child("BattleHandCarousel", true, false) as ScrollContainer
	var hand_grid := main.find_child("BattleHandGrid", true, false) as GridContainer
	var touch_scroll := main.find_child("BattleSecondaryScroll", true, false) as ScrollContainer
	require(carousel != null and hand_grid != null and touch_scroll != null and hand_grid.get_child_count() == 4 and carousel.custom_minimum_size.y >= 225 and carousel.get_global_rect().size.y >= 48 and hand_grid.custom_minimum_size.x > carousel.get_global_rect().size.x, "portrait hand retains four 2:3 cards in a bounded horizontal carousel within touch scrolling")
	for card in hand_grid.get_children(): _require_card_front(card as Button, false, false, "portrait hand card")
	main.battle.players[0].hand = ["raw_filament"]; main.battle.players[0].filament = 3; main.submit_battle_card("raw_filament"); require(main.battle.players[0].discard.has("raw_filament"), "solo hand play moves card to discard")
	main.start_local_vs(); await get_tree().process_frame
	var hidden := main.find_child("LocalHiddenCardBack", true, false) as Button
	require(hidden != null and hidden.focus_mode == Control.FOCUS_NONE and hidden.mouse_filter == Control.MOUSE_FILTER_IGNORE, "local versus hides private hand behind noninteractive card back")
	_require_card_front(hidden, false, true, "hidden local card", true)
	main.local_ready_seat = main.local_authority.state.active_player; main.render(); await get_tree().process_frame
	require(main.find_child("LocalRevealedCardGrid", true, false) != null and main.find_child("LocalHiddenCardBack", true, false) == null, "local versus reveals visual cards only after ready")
	var revealed := main.find_child("LocalCard*", true, false) as Button
	_require_card_front(revealed, false, false, "revealed local card")
	# Landscape retains the portrait card silhouette and a reachable carousel.
	var landscape := Vector2i(1280, 720)
	get_viewport().size = landscape; main.size = Vector2(landscape)
	main.battle = BattleState.create(["cinderpaw"], ["mossmunk"], 3, 3, 2); main.battle.players[0].hand = ["final_pass", "coolant", "raw_filament", "arcane_spark"]; main.battle_secondary_open = true; main.battle_secondary_tab = "hand"; main.screen = "battle"; main.render(); await get_tree().process_frame
	carousel = main.find_child("BattleHandCarousel", true, false) as ScrollContainer; hand_grid = main.find_child("BattleHandGrid", true, false) as GridContainer
	touch_scroll = main.find_child("BattleSecondaryScroll", true, false) as ScrollContainer
	require(carousel != null and hand_grid != null and touch_scroll != null and hand_grid.get_child_count() == 4 and carousel.get_global_rect().size.y >= 48, "landscape hand carousel remains reachable through touch scrolling")
	for card in hand_grid.get_children(): _require_card_front(card as Button, false, false, "landscape hand card")
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

func _require_card_front(card: Button, disabled := false, decorative := false, context := "card", hidden := false) -> void:
	if card == null:
		require(false, context + " exists")
		return
	var ratio := card.custom_minimum_size.x / maxf(1.0, card.custom_minimum_size.y)
	require(is_equal_approx(ratio, 2.0 / 3.0) and card.custom_minimum_size.y >= 48.0, context + " uses a 2:3 touch-safe card silhouette")
	var rect := card.get_global_rect()
	var rendered_ratio := rect.size.x / maxf(1.0, rect.size.y)
	require(rect.size.y >= 48.0 and absf(rendered_ratio - (2.0 / 3.0)) <= 0.03, context + " retains the 2:3 silhouette after host layout")
	require(card.text.is_empty(), context + " leaves native Button text empty")
	require(card.focus_mode == (Control.FOCUS_NONE if decorative else Control.FOCUS_ALL), context + " preserves expected controller focus policy")
	if hidden:
		require(card.find_child("CardBackArt", true, false) != null and card.find_child("CardTitlePlate", true, false) == null and card.tooltip_text == "Hidden support card", context + " is private, art-only and has no redundant plaque")
		return
	for field in ["CardInsetBorder", "CardTitlePlate", "CardTitle", "CardCostBadge", "CardArtAspect", "CardArtWindow", "CardArt", "CardMetadataStrip", "CardRarityPip", "CardRarityRole", "CardRulesPanel", "CardTargetRail", "CardTargetFooter"]:
		require(card.find_child(field, true, false) != null, context + " has required " + field)
	var title := card.find_child("CardTitle", true, false) as Label
	var cost := card.find_child("CardCostBadge", true, false) as Label
	var metadata := card.find_child("CardMetadataStrip", true, false) as Control
	var pip := card.find_child("CardRarityPip", true, false) as Control
	var role := card.find_child("CardRarityRole", true, false) as Label
	var rules := card.find_child("CardRulesPanel", true, false) as Label
	var target_rail := card.find_child("CardTargetRail", true, false) as Control
	var target := card.find_child("CardTargetFooter", true, false) as Label
	var art := card.find_child("CardArt", true, false) as TextureRect
	var art_window := card.find_child("CardArtWindow", true, false) as Control
	require(title != null and title.visible and not title.text.is_empty() and rules != null and rules.visible and not rules.text.is_empty() and target != null and target.visible and target.text.begins_with("Target:"), context + " visibly renders title, exact rules, and target")
	var outer := card.get_theme_stylebox("normal") as StyleBoxFlat
	require(outer != null and outer.border_width_left == 1 and outer.border_width_top == 1 and outer.corner_radius_top_left <= 5, context + " uses the thin clipped manufactured outer seam")
	require(cost != null and cost.text.ends_with("F") and not cost.text.contains(" F") and is_equal_approx(cost.custom_minimum_size.x, cost.custom_minimum_size.y) and cost.custom_minimum_size.x <= 23.0, context + " integrates a compact circular spool-cost token in the title rail")
	require(metadata != null and pip != null and pip.custom_minimum_size.x <= 6.0 and target_rail != null and target != null and target.is_ancestor_of(target_rail) == false and target_rail.is_ancestor_of(target), context + " separates rarity into a small metadata pip and places target copy in a footer rail")
	require(role != null and role.autowrap_mode == TextServer.AUTOWRAP_OFF and role.get_global_rect().size.x >= 24.0 and role.get_global_rect().size.y >= 8.0, context + " keeps a readable compact rarity/category label on the metadata rail")
	var ownership := card.find_child("CardOwnershipCount", true, false) as Label
	if ownership != null: require(target_rail != null and target_rail.is_ancestor_of(ownership) and ownership.text.begins_with("Owned:"), context + " keeps ownership count subordinate in the target rail")
	require(art != null and art.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED and art_window != null and art_window.get_global_rect().size.y >= 48.0 and absf(art_window.get_global_rect().size.x / maxf(1.0, art_window.get_global_rect().size.y) - 1.5) <= 0.03, context + " contains full landscape atlas art in an exact 3:2 framed window")
	if art != null and art.texture is AtlasTexture:
		var region := art.texture as AtlasTexture
		var source_size := region.atlas.get_size()
		require(is_equal_approx(region.region.size.x, source_size.x / 4.0) and is_equal_approx(region.region.size.y, source_size.y / 2.0) and absf(region.region.size.x / region.region.size.y - 1.5) <= 0.001, context + " uses one complete landscape 4x2 atlas cell without crop")
	if disabled:
		var banner := card.find_child("CardLegalityBanner", true, false) as Label
		require(banner != null and banner.visible and not banner.text.is_empty() and card.disabled, context + " shows a readable legality banner")
