extends Node

## Acquisition coverage stays transaction-oriented while asserting the current M3
## physical owners rather than the retired generic Market, Archive, and Pack shells.
const MAIN := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _profile() -> Dictionary:
	var profile: Dictionary = RULES.new_profile()
	profile.forge_coins = 1200
	profile = RULES.choose_starter(profile, "cinderpaw").profile
	return RULES.print_starter(profile).profile

func _current_creature_offer() -> Dictionary:
	for offer_variant in (GameManager.market_snapshot().get("cards", []) as Array):
		if offer_variant is Dictionary:
			var offer: Dictionary = offer_variant
			if not Catalog.creature(str(offer.get("id", ""))).is_empty():
				return offer
	return {}

func _pack_grid_ok(main) -> bool:
	var plate := main.find_child("M3PhysicalPackPlate", true, false) as Control
	var grid := main.find_child("UnifiedPackRevealGrid", true, false) as Control
	var cards: Array = main.find_children("UnifiedPackCardView*", "Button", true, false)
	return plate != null and grid != null and grid.get_child_count() == 5 and cards.size() == 5

func _ready() -> void:
	GameManager.profile = _profile()
	var main := MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame

	# Market browsing is presentation-only; the existing GameManager purchase
	# facade remains the atomic acquisition authority.
	var offer := _current_creature_offer()
	require(not offer.is_empty(), "fixture finds a current Card Shop creature offer")
	main.screen = "unified_market"
	main.unified_market_tab = "cards"
	main.render()
	await get_tree().process_frame
	var cubbies := main.find_child("MarketOfferCubbies", true, false) as Control
	var offer_buttons: Array = main.find_children("MarketOffer*Slot*", "Button", true, false)
	require(main.find_child("M3SupplyCabinet", true, false) != null and cubbies != null and not offer_buttons.is_empty(), "Current Market uses M3SupplyCabinet cubbies with visible physical offer Buttons.")
	var creature_id := str(offer.get("id", ""))
	var before_cards := int(GameManager.profile.get("owned_cards", {}).get(creature_id, 0))
	var buy := GameManager.buy_market_card_v3(creature_id)
	await get_tree().process_frame
	require(bool(buy.get("ok", false)) and int(GameManager.profile.get("owned_cards", {}).get(creature_id, 0)) == before_cards + 1 and bool(GameManager.profile.get("owned_blueprints", {}).get(creature_id, false)), "Market creature purchase adds exactly one owned card and its permanent blueprint license.")

	main.screen = "unified_library"
	main.render()
	await get_tree().process_frame
	var archive_cards: Array = main.find_children("ArchiveBlueprintCard*", "Button", true, false)
	require(main.find_child("ArchiveNavyArchHud", true, false) != null and main.find_child("ArchiveBookCardGrid", true, false) != null and not archive_cards.is_empty(), "Collection uses the physical archive HUD, six-card grid, and native ArchiveBlueprintCard controls.")

	main.screen = "unified_deck"
	main.render()
	await get_tree().process_frame
	require(main.find_child("M3DeckWorkbench", true, false) != null and main.find_child("ArchiveDeckSlots", true, false) != null and main.find_child("DeckOwnedArtTray", true, false) != null and main.find_child("SaveActiveDeck", true, false) is Button, "Deck Builder uses its physical workbench, fixed deck slots, owned-art tray, and real Save control.")

	# Save an active legal four-creature deck. This retains the fourth unique
	# creature in the physical owned tray without changing any deck rule.
	var varied_deck: Array = GameManager.active_deck_cards()
	var first_support := -1
	var second_support := -1
	for index in varied_deck.size():
		if str(RULES.card(str(varied_deck[index])).get("type", "")) != "creature":
			if first_support < 0:
				first_support = index
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
		require(RULES.deck_reason(GameManager.profile, varied_deck).is_empty() and GameManager.save_unified_deck(varied_deck), "Fixture saves a legal four-creature active deck before workbench pre-print coverage.")
	GameManager.profile.preprints = ["cinderpaw"]
	main.m3_deck_loaded_slot_id = ""
	main.screen = "unified_deck"
	main.render()
	await get_tree().process_frame
	require(main.unified_preprint_draft == ["cinderpaw"] and main.find_child("DeckOwnedCardVoltwig", true, false) is Button, "Physical Deck initialization loads persisted Cinderpaw pre-print once and exposes fourth unique Voltwig in the owned tray.")
	main.unified_preprint_draft.clear()
	main.render()
	await get_tree().process_frame
	var voltwig_pick := main.find_child("DeckOwnedCardVoltwig", true, false) as Button
	require(main.unified_preprint_draft.is_empty() and voltwig_pick != null, "Clearing the physical pre-print draft remains cleared on rerender rather than silently reloading persistence.")
	if voltwig_pick != null:
		voltwig_pick.emit_signal("pressed")
		await get_tree().process_frame
		var empty_clamp: Button = null
		for clamp_variant in main.find_children("PrePrintClamp*", "Button", true, false):
			var clamp := clamp_variant as Button
			if clamp != null and not clamp.disabled and clamp.tooltip_text.begins_with("Place"):
				empty_clamp = clamp
				break
		require(empty_clamp != null, "Selected Voltwig exposes an available empty physical Pre-Print clamp.")
		if empty_clamp != null:
			empty_clamp.emit_signal("pressed")
			await get_tree().process_frame
			require("voltwig" in main.unified_preprint_draft, "Pressing the selected empty Pre-Print clamp adds Voltwig through the ordered draft method.")

	# Archive detail owns one CO-02 surface. Creature facts are exact native
	# rules, while support facts must not fabricate creature stat zeroes.
	main.screen = "unified_library"
	main.unified_inspector_id = "cinderpaw"
	main.render()
	await get_tree().process_frame
	var cinder := RULES.card("cinderpaw")
	var expected_creature_fact := "HP %d · B%d · %dF" % [int(cinder.get("hp", 0)), int(cinder.get("bend", 0)), int(cinder.get("cost", 0))]
	var print_fact := main.find_child("ArchiveDetailFact4", true, false) as Label
	require(main.find_child("M3ArchiveDetailApertures", true, false) != null and main.find_child("ArchiveDetailFacts", true, false) != null and print_fact != null and print_fact.text.contains(expected_creature_fact) and not print_fact.text.contains("ATK"), "Creature archive detail uses CO-02 fact wells with truthful HP/BEND/filament print facts and no retired Attack stat.")
	main.unified_inspector_id = "raw_filament"
	main.render()
	await get_tree().process_frame
	var support_facts := main.find_child("ArchiveDetailNativeFacts", true, false) as Label
	require(support_facts != null and support_facts.text.contains("Owned copies") and support_facts.text.contains("Filament") and support_facts.text.contains("filament") and not support_facts.text.contains("HP 0") and not support_facts.text.contains("ATK 0"), "Support archive detail reports owned/type/cost/rules facts without fabricated creature zeroes.")

	# Keep drives the persisted 1→2→3 starter receipt chain. Each intermediate
	# render remains the exclusive five-dock M3 Pack plate; after the third Keep,
	# Collection returns and no fourth claim changes cards or pending state.
	main.unified_inspector_id = ""
	main.render()
	await get_tree().process_frame
	main._open_next_starter_pack()
	await get_tree().process_frame
	require(main.screen == "unified_library" and _pack_grid_ok(main) and bool(GameManager.profile.get("pending_pack_reveal", {}).get("starter_reward", false)) and int(GameManager.profile.get("starter_pack_rewards", {}).get("opened", 0)) == 1, "Starter pack 1 opens as a persisted five-dock physical receipt.")
	main._keep_unified_pack_cards()
	await get_tree().process_frame
	require(_pack_grid_ok(main) and bool(GameManager.profile.get("pending_pack_reveal", {}).get("starter_reward", false)) and int(GameManager.profile.get("starter_pack_rewards", {}).get("opened", 0)) == 2, "Keeping pack 1 opens persisted starter pack 2 in the same physical receipt owner.")
	main._keep_unified_pack_cards()
	await get_tree().process_frame
	require(_pack_grid_ok(main) and bool(GameManager.profile.get("pending_pack_reveal", {}).get("starter_reward", false)) and int(GameManager.profile.get("starter_pack_rewards", {}).get("opened", 0)) == 3, "Keeping pack 2 opens persisted starter pack 3 in the same physical receipt owner.")
	main._keep_unified_pack_cards()
	await get_tree().process_frame
	var owned_after_rewards: Dictionary = (GameManager.profile.get("owned_cards", {}) as Dictionary).duplicate(true)
	var pending_after_rewards: Dictionary = (GameManager.profile.get("pending_pack_reveal", {}) as Dictionary).duplicate(true)
	require(main.find_child("M3PhysicalPackPlate", true, false) == null and main.find_child("UnifiedPackRevealGrid", true, false) == null and main.find_child("ArchiveBookCardGrid", true, false) != null and pending_after_rewards.is_empty(), "Keeping pack 3 clears pending receipt and restores physical Collection grid.")
	var fourth := GameManager.claim_next_starter_pack()
	require(not bool(fourth.get("ok", false)) and GameManager.profile.get("owned_cards", {}) == owned_after_rewards and GameManager.profile.get("pending_pack_reveal", {}) == pending_after_rewards and int(GameManager.profile.get("starter_pack_rewards", {}).get("opened", 0)) == 3, "No fourth starter claim mutates cards, pending receipt, or the three-pack count.")

	main.queue_free()
	await get_tree().process_frame
	if failures.is_empty():
		print("PASS: M3 physical acquisition, deck pre-print, archive facts, and starter receipt chain")
	get_tree().quit(0 if failures.is_empty() else 1)
