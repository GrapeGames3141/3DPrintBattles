extends Node
## Focused v3.1 authority regression suite. UI and legacy 0.7 tests deliberately
## live elsewhere; this verifies the canonical v3 state without presentation.
const RULES := preload("res://scripts/core/unified_rules.gd")
const STATE := preload("res://scripts/battle/unified_battle_state.gd")
const BATTLE := preload("res://scripts/battle/unified_battle_rules.gd")
const AI := preload("res://scripts/battle/unified_ai_opponent.gd")
const REVIEW_RULES := preload("res://scripts/core/review_build_rules.gd")
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func deck_cards(profile: Dictionary, deck_id: String) -> Array:
	for deck in profile.get("decks", []):
		if deck is Dictionary and str(deck.get("id", "")) == deck_id:
			return (deck.get("cards", []) as Array).duplicate()
	return []

func deck_count(profile: Dictionary, deck_id: String) -> int:
	var count := 0
	for deck in profile.get("decks", []):
		if deck is Dictionary and str(deck.get("id", "")) == deck_id: count += 1
	return count

func _ready() -> void:
	var profile := RULES.ensure({"onboarding":{"state":"choose_starter","starter_id":""},"coins":10000})
	var clean_profile := RULES.new_profile()
	require(not clean_profile.has("coins") and not clean_profile.has("xp") and not clean_profile.has("daily_job_count"), "new v3 profiles contain no retired 0.7 economy or Workshop-job fields")
	var review_floor := REVIEW_RULES.apply_coin_floor(clean_profile, true)
	require(bool(review_floor.ok) and int(review_floor.profile.get("forge_coins", 0)) == REVIEW_RULES.REVIEW_COIN_FLOOR and not review_floor.profile.has("coins"), "review build floor applies to Forge Coins without restoring retired coins")
	var selected := RULES.choose_starter(profile, "cinderpaw")
	var printed := RULES.print_starter(selected.profile)
	require(bool(selected.ok) and int(selected.profile.owned_cards.get("cinderpaw", 0)) == 1 and RULES.has_printable_blueprint(selected.profile, "cinderpaw"), "starter choice grants its first creature card and permanent printable blueprint")
	require(bool(printed.ok) and printed.profile.decks[0].cards.size() == 40 and RULES.deck_reason(printed.profile, printed.profile.decks[0].cards).is_empty(), "starter is a legal 40-card owned deck")
	var authored_starter := deck_cards(printed.profile, "starter-deck")
	# v3.2 migrates both historical ownership directions without touching an
	# existing deck or printed-model record. Creature dismantling keeps the license.
	var bridge := RULES.ensure({"onboarding":{"state":"starter_selected","starter_id":"cinderpaw"},"owned_cards":{"aquafin":2},"owned_blueprints":{"voltwig":true},"decks":[{"id":"custom","cards":["aquafin"]}],"printed_models":{"old":{"blueprint_id":"aquafin"}}})
	var bridge_reensured := RULES.ensure(bridge)
	require(RULES.has_printable_blueprint(bridge, "aquafin") and int(bridge.owned_cards.get("voltwig", 0)) == 1 and bridge.decks[0].cards == ["aquafin"] and str(bridge.printed_models.old.blueprint_id) == "aquafin" and bridge_reensured == bridge, "two-way creature ownership migration is value-stable on a second ensure and preserves deck/model records")
	var final_copy_profile := RULES.ensure({"onboarding":{"state":"starter_selected","starter_id":"cinderpaw"},"owned_cards":{"aquafin":1},"owned_blueprints":{"aquafin":true},"decks":[]})
	var dismantled := RULES.dismantle_card(final_copy_profile, "aquafin", 1)
	require(bool(dismantled.ok) and int(dismantled.profile.owned_cards.get("aquafin", 0)) == 0 and RULES.has_printable_blueprint(dismantled.profile, "aquafin"), "dismantling the final creature copy with no deck dependency keeps its permanent printable blueprint")
	var aquafin_selected := RULES.choose_starter(RULES.ensure({"onboarding":{"state":"choose_starter","starter_id":""}}), "aquafin")
	var aquafin_printed := RULES.print_starter(aquafin_selected.profile)
	var aquafin_deck := deck_cards(aquafin_printed.profile, "starter-deck")
	require(bool(aquafin_printed.ok) and aquafin_deck.count("aquafin") == 12 and aquafin_deck.count("mossmunk") == 8 and aquafin_deck.count("cinderpaw") == 0 and RULES.deck_reason(aquafin_printed.profile, aquafin_deck).is_empty(), "non-Cinder starter maps to twelve chosen copies and eight Mossmunk copies")
	var legacy_complete := RULES.ensure({"onboarding":{"state":"complete","starter_id":"cinderpaw"},"owned_cards":{"cinderpaw":12,"mossmunk":8},"owned_blueprints":{"cinderpaw":true,"mossmunk":true},"decks":[{"id":"starter-deck","name":"Forge Deck","cards":authored_starter}]})
	require(int(legacy_complete.starter_pack_rewards.entitled) == 0 and int(legacy_complete.starter_pack_rewards.opened) == 0, "completed legacy profiles receive no retroactive starter-pack entitlement")
	var reward_profile: Dictionary = printed.profile.duplicate(true)
	require(int(reward_profile.starter_pack_rewards.entitled) == 3 and int(reward_profile.starter_pack_rewards.opened) == 0 and bool(reward_profile.newcomer_claims.get("basic_pack", false)), "first print replaces the free Newcomer Basic pack with three starter rewards")
	for reward_number in 3:
		var starter_pack := RULES.claim_next_starter_pack(reward_profile, PackedByteArray([reward_number + 1, 9, 7]))
		require(bool(starter_pack.ok) and int(starter_pack.payload.starter_opened) == reward_number + 1 and (starter_pack.payload.cards as Array).size() == 5 and int(starter_pack.profile.pack_pity.get("basic", 0)) == reward_number + 1 and str(starter_pack.profile.pending_pack_reveal.receipt) == "starter-basic-%d" % (reward_number + 1), "starter pack %d is a persisted normal five-card Basic reveal and advances normal pity" % (reward_number + 1))
		var reloaded_reward := RULES.ensure(starter_pack.profile)
		require(reloaded_reward.pending_pack_reveal == starter_pack.profile.pending_pack_reveal and reloaded_reward.owned_cards == starter_pack.profile.owned_cards and int(reloaded_reward.starter_pack_rewards.opened) == reward_number + 1, "starter pack %d survives reload without duplicate card ownership" % (reward_number + 1))
		reward_profile = RULES.clear_pack_reveal(reloaded_reward).profile
	var no_fourth := RULES.claim_next_starter_pack(reward_profile, PackedByteArray([4, 9, 7]))
	require(not bool(no_fourth.ok) and int(reward_profile.starter_pack_rewards.opened) == 3, "starter rewards stop after exactly three exactly-once Basic packs")
	var stale_starter: Dictionary = RULES.new_profile()
	stale_starter.onboarding = {"state":"complete", "starter_id":"cinderpaw"}
	stale_starter.owned_cards = {"cinderpaw":7, "raw_filament":1}
	stale_starter.decks = [{"id":"starter-deck", "name":"Forge Deck", "cards":authored_starter.slice(0, 15)}, {"id":"deck-slot-2", "name":"Queue Deck", "cards":[]}, {"id":"deck-slot-3", "name":"Arcane Deck", "cards":[]}]
	stale_starter.active_deck_id = "starter-deck"
	var repaired_starter := RULES.ensure(stale_starter)
	var repaired_cards := deck_cards(repaired_starter, "starter-deck")
	var ownership_exact := int(repaired_starter.owned_cards.get("cinderpaw", 0)) == 12 and int(repaired_starter.owned_cards.get("raw_filament", 0)) == 4
	for card_id in authored_starter:
		if str(card_id) == "cinderpaw" or str(card_id) == "raw_filament": continue
		ownership_exact = ownership_exact and int(repaired_starter.owned_cards.get(str(card_id), 0)) == authored_starter.count(card_id)
	require(repaired_cards.size() == 40 and RULES.deck_reason(repaired_starter, repaired_cards).is_empty() and deck_count(repaired_starter, "starter-deck") == 1 and repaired_starter.decks.size() == 3 and ownership_exact, "a completed stale 15-card starter with pre-created empty slots repairs to the authored 40-card Forge Deck")
	var repaired_again := RULES.ensure(repaired_starter)
	require(repaired_again == repaired_starter and int(repaired_again.get("revision", -1)) == int(repaired_starter.get("revision", -2)), "starter repair is idempotent and does not change revisions or add duplicate ownership")
	var custom_active: Dictionary = printed.profile.duplicate(true)
	var custom_cards := authored_starter.duplicate()
	custom_active.decks = [{"id":"deck-slot-2", "name":"Queue Deck", "cards":custom_cards}]
	custom_active.active_deck_id = "deck-slot-2"
	var custom_preserved := RULES.ensure(custom_active)
	require(deck_cards(custom_preserved, "deck-slot-2") == custom_cards and str(custom_preserved.active_deck_id) == "deck-slot-2" and RULES.deck_reason(custom_preserved, deck_cards(custom_preserved, "starter-deck")).is_empty(), "missing starter repair preserves a different legal active deck while restoring Forge Deck")
	var invalid_active: Dictionary = printed.profile.duplicate(true)
	invalid_active.active_deck_id = "deck-slot-2"
	var active_repaired := RULES.ensure(invalid_active)
	require(str(active_repaired.active_deck_id) == "starter-deck", "an absent or illegal active deck falls back to the repaired Forge Deck")
	require(str(printed.profile.onboarding.get("state", "")) == "complete" and printed.profile.printed_models.has("starter-cinderpaw"), "v3 onboarding completes without retired starter instances")
	var starter_equipment: Array = []
	for card_id in printed.profile.decks[0].cards:
		if str(RULES.card(str(card_id)).get("type", "")) == "equipment": starter_equipment.append(card_id)
	require(printed.profile.decks[0].cards.size() == 40 and printed.profile.decks[0].cards.count("cinderpaw") == 12 and printed.profile.decks[0].cards.count("mossmunk") == 8 and starter_equipment == ["standard_full_suit","reinforced_full_suit","iron_gem","filament_ring"], "new starter deck is 12 selected starter, 8 Mossmunk, and the established 20 non-creature cards")
	var equipment_ids: Array = []; var equipment_slots: Array = []; var armor_values: Array = []
	for definition in RULES.all_cards():
		if str(definition.get("type", "")) == "equipment":
			equipment_ids.append(str(definition.id))
			equipment_slots.append(str(definition.get("equipment_slot", "")))
			if str(definition.get("equipment_slot", "")) == "armor": armor_values.append(int(definition.get("armor_hp", 0)))
	var normalized_equipment := true
	for equipment_id in ["standard_full_suit","reinforced_full_suit","arcane_full_suit","masterwork_full_suit","legendary_full_suit","iron_gem","ember_gem","frost_gem","storm_gem","arcane_gem","filament_ring"]: normalized_equipment = normalized_equipment and equipment_ids.has(equipment_id)
	var ring_definition := RULES.card("filament_ring")
	require(normalized_equipment and equipment_ids.size() == 11 and equipment_slots.count("armor") == 5 and equipment_slots.count("gem") == 5 and equipment_slots.count("battle_effect") == 1 and armor_values == [8,14,20,28,36] and int(ring_definition.print_turns) == 0 and int(ring_definition.print_ticks) == 0 and not equipment_ids.has("helm") and not equipment_ids.has("chest_plate") and not equipment_ids.has("leg_guards") and not equipment_ids.has("full_suit") and not equipment_ids.has("arcane_plate") and not equipment_ids.has("iron_claw"), "catalog has exactly five full suit tiers, five gems, and a zero-timer Ring battle effect")
	var migrated := RULES.ensure({"onboarding":{"state":"complete"},"owned_cards":{"helm":1,"chest_plate":2,"leg_guards":3,"iron_claw":1,"tidal_core":1,"arcane_sigil":1},"owned_blueprints":{"helm":true},"printed_models":{"old-model":{"blueprint_id":"helm"}},"pending_pack_reveal":{"cards":["helm","iron_claw"],"bonus_cards":["arcane_sigil"],"receipt":"immutable-receipt"},"decks":[{"id":"starter-deck","name":"Forge Deck","cards":["helm","chest_plate","leg_guards","iron_claw"]}],"preprints":["helm"],"wishlist":["helm","iron_claw"]})
	require(int(migrated.owned_cards.get("standard_full_suit", 0)) == 1 and int(migrated.owned_cards.get("reinforced_full_suit", 0)) == 5 and int(migrated.owned_cards.get("iron_gem", 0)) == 1 and int(migrated.owned_cards.get("frost_gem", 0)) == 1 and int(migrated.owned_cards.get("arcane_gem", 0)) == 1 and not migrated.owned_cards.has("helm") and RULES.deck_reason(migrated, deck_cards(migrated, "starter-deck")).is_empty() and str(migrated.preprints[0]) == "standard_full_suit" and str(migrated.wishlist[1]) == "iron_gem" and str(migrated.printed_models["old-model"].blueprint_id) == "standard_full_suit" and migrated.pending_pack_reveal.cards == ["standard_full_suit","iron_gem"] and migrated.pending_pack_reveal.bonus_cards == ["arcane_gem"] and str(migrated.pending_pack_reveal.receipt) == "immutable-receipt", "v3 equipment aliases normalize live references while invalid completed starter decks repair to the authored deck without changing receipt identities")
	GameManager.profile = printed.profile.duplicate(true)
	require(GameManager.has_selected_starter(), "GameManager uses v3 onboarding completion rather than retired starter_instance_id")
	require(printed.profile.get("owned_blueprints", {}).has("cinderpaw") and printed.profile.get("printed_models", {}).has("starter-cinderpaw"), "blueprint and Workshop model ownership remain explicit")
	var preprint := RULES.save_preprints(printed.profile, ["cinderpaw"])
	require(bool(preprint.ok), "one base Pre-Print selection is legal")
	var state := STATE.create(printed.profile.decks[0].cards, printed.profile.decks[0].cards, 11, [], [], ["cinderpaw"])
	require(state.phase == "draw" and int(state.player(0).printer.hp) == 2000 and int(state.player(0).filament) == 200 and int(state.player(0).filament_max) == 400, "state begins with v3 printer, phase, and filament values")
	require(state.player(0).slots[0] != null and str(state.player(0).slots[0].mode) == "defense" and not bool(state.player(0).slots[0].ready), "pre-print deploys as a first-turn defender")
	var invalid_before := state.serialize()
	var invalid := BATTLE.apply_intent(state, 1 - state.active_seat, {"type":"advance_phase"})
	require(not bool(invalid.ok) and state.serialize() == invalid_before, "wrong-seat intents reject without mutating snapshots")
	var active := state.active_seat
	BATTLE.apply_intent(state, active, {"type":"advance_phase"})
	require(state.phase == "main", "Draw advances into Main")
	state.player(active).hand = ["cinderpaw", "speed_spool", "raw_filament"]
	var queue := BATTLE.apply_intent(state, active, {"type":"play_card","card_id":"cinderpaw"})
	require(bool(queue.ok) and state.player(active).queue.size() == 1 and int(state.player(active).filament) == 130, "creatures pay filament and enter the FIFO queue")
	var cancelled := BATTLE.apply_intent(state, active, {"type":"cancel_queue","queue_index":0})
	require(bool(cancelled.ok) and int(cancelled.refund) == 35 and int(state.player(active).filament) == 165, "queue cancellation refunds floor half the original cost")
	state.player(active).hand.append("cinderpaw")
	BATTLE.apply_intent(state, active, {"type":"play_card","card_id":"cinderpaw"})
	BATTLE.apply_intent(state, active, {"type":"play_card","card_id":"speed_spool"})
	BATTLE.apply_intent(state, active, {"type":"advance_phase"})
	BATTLE.apply_intent(state, active, {"type":"advance_phase"})
	if not state.pending.is_empty(): BATTLE.apply_intent(state, active, {"type":"place_completed","slot":1,"mode":"attack"})
	require(state.player(active).slots[1] != null and str(state.player(active).slots[1].mode) == "attack", "completed prints request placement and become attack-ready")
	state.phase = "attack"
	state.turn = 2
	state.player(active).slots[1].attacked = false
	for slot in 3: state.player(1 - active).slots[slot] = null
	var direct := BATTLE.apply_intent(state, active, {"type":"attack","slot":1,"target":-1})
	require(bool(direct.ok) and int(state.player(1 - active).printer.hp) < 2000, "direct attacks only damage the exposed printer")
	var gear_state := STATE.create(printed.profile.decks[0].cards, printed.profile.decks[0].cards, 17)
	gear_state.active_seat = 0
	gear_state.phase = "main"
	gear_state.player(0).slots[0] = STATE._unit(RULES.card("cinderpaw"))
	gear_state.player(0).hand = ["standard_full_suit"]
	BATTLE.apply_intent(gear_state, 0, {"type":"play_card","card_id":"standard_full_suit","target":0})
	BATTLE.apply_intent(gear_state, 0, {"type":"advance_phase"})
	BATTLE.apply_intent(gear_state, 0, {"type":"advance_phase"})
	require(int(gear_state.player(0).slots[0].armor_hp) == 8 and str(gear_state.player(0).slots[0].equipment.armor.card_id) == "standard_full_suit", "full-suit equipment tracks armor HP ahead of creature HP")
	var public_view := gear_state.public_snapshot(1)
	require(not public_view.players[0].has("hand") and int(public_view.players[0].hand_count) == gear_state.player(0).hand.size(), "opponent public snapshots redact hand details")
	var ai_state := STATE.create(printed.profile.decks[0].cards, printed.profile.decks[0].cards, 23)
	AI.take_turn(ai_state, ai_state.active_seat)
	require(ai_state.revision > 0, "AI issues canonical legal intents")
	var pack := RULES.buy_pack(printed.profile, "forge", PackedByteArray([1,2,3]))
	require(bool(pack.ok) and not pack.profile.pending_pack_reveal.is_empty() and (pack.payload.cards as Array).size() == 5, "pack grants are persisted before reveal")
	var expiry_stamp := 1724284800
	var expired_newcomer: Dictionary = RULES.new_profile(); expired_newcomer.forge_coins = 1000; expired_newcomer.newcomer_started_at = expiry_stamp - 8 * 86400
	var stale_free_basic := RULES.buy_pack(expired_newcomer, "basic", PackedByteArray([3,2,1]), expiry_stamp, "workshop", {}, 0)
	require(not bool(stale_free_basic.ok) and bool(stale_free_basic.get("price_changed", false)) and stale_free_basic.profile == RULES.ensure(expired_newcomer) and int(stale_free_basic.effective_price) > 0, "expired Newcomer free-Basic confirmation rejects before coins, RNG, cards, receipt, or expiry state mutate")
	var matching_basic := RULES.buy_pack(expired_newcomer, "basic", PackedByteArray([3,2,1]), expiry_stamp, "workshop", {}, int(stale_free_basic.effective_price))
	require(bool(matching_basic.ok) and int(matching_basic.payload.get("effective_price", stale_free_basic.effective_price)) == int(stale_free_basic.effective_price) and not matching_basic.profile.pending_pack_reveal.is_empty(), "matching frozen effective pack price succeeds through the existing receipt path")
	var economy: Dictionary = printed.profile.duplicate(true)
	economy.forge_coins = 50000
	var market := RULES.market_snapshot(economy, 1724284800)
	require((market.blueprints as Array).size() == 12 and (market.cards as Array).size() == 10 and not (market.daily_deal as Dictionary).is_empty(), "five-shop market snapshot has 12 blueprints, 10 typed cards, and a daily deal")
	var blueprint_id := ""
	for offer in market.blueprints:
		if not economy.owned_blueprints.has(str(offer.get("id", ""))): blueprint_id = str(offer.get("id", "")); break
	var blueprint := RULES.buy_blueprint(economy, blueprint_id, 1724284800)
	require(bool(blueprint.ok) and RULES.has_printable_blueprint(blueprint.profile, blueprint_id) and int(blueprint.profile.owned_cards.get(blueprint_id, 0)) == 1, "Blueprint Stall grants a printable creature blueprint and exactly one card")
	var before_models: int = int((blueprint.profile.get("printed_models", {}) as Dictionary).size()); var workshop_print := RULES.print_workshop_model(blueprint.profile, blueprint_id, "workshop-model-receipt")
	var workshop_repeat := RULES.print_workshop_model(workshop_print.profile, blueprint_id, "workshop-model-receipt")
	require(bool(workshop_print.ok) and workshop_print.profile.printed_models.size() == before_models + 1 and int(workshop_print.payload.price) == int(RULES.WORKSHOP_PRINT_COSTS.get(str(RULES.card(blueprint_id).get("rarity", "common")), 20)) and bool(workshop_repeat.payload.duplicate) and int(workshop_print.profile.owned_cards.get(blueprint_id, 0)) == int(blueprint.profile.owned_cards.get(blueprint_id, 0)), "Workshop printing spends catalog cost, creates only a model record, and journals a receipt")
	var listed_card := str((market.cards as Array)[0].get("id", ""))
	var shop_card := RULES.buy_market_card_at(economy, listed_card, 1724284800)
	require(bool(shop_card.ok) and int(shop_card.profile.owned_cards.get(listed_card, 0)) > int(economy.owned_cards.get(listed_card, 0)), "typed 48-hour Card Shop grants card copies")
	var wished := RULES.set_wishlist(economy, listed_card, true)
	require(bool(wished.ok) and (wished.profile.wishlist as Array).size() == 1, "wishlist accepts catalog items up to its cap")
	var forward_epochs := RULES.advance_market_epochs(economy, 1724457600, "2026-08-23")
	var rollback_epochs := RULES.advance_market_epochs(forward_epochs.profile, 1724284800, "2026-08-21")
	require(int(rollback_epochs.profile.market_epochs.blueprint) == int(forward_epochs.profile.market_epochs.blueprint) and int(rollback_epochs.profile.market_epochs.card) == int(forward_epochs.profile.market_epochs.card), "persisted market epochs reject clock rollback")
	var newcomer := RULES.market_snapshot(RULES.new_profile(), 1724284800)
	require((newcomer.newcomer.get("blueprints", []) as Array).size() == 3, "Newcomer Shelf explicitly offers three Common blueprints")
	var pity_profile: Dictionary = printed.profile.duplicate(true); pity_profile.forge_coins = 50000; pity_profile.pack_pity = {"basic":50}
	var basic_pity := RULES.buy_pack(pity_profile, "basic", PackedByteArray([9,8,7]))
	var basic_rare_count := 0
	for id in (basic_pity.payload.bonus_cards as Array): if RULES._rarity_index(str(RULES.card(str(id)).get("rarity", "common"))) >= RULES._rarity_index("rare"): basic_rare_count += 1
	require(bool(basic_pity.ok) and (basic_pity.payload.bonus_cards as Array).size() == 5 and basic_rare_count >= 1 and int(basic_pity.profile.pack_pity.basic) == 0, "Basic Pack 51 grants a separate five-card Rare Reward Pack with one Rare+")
	var ordinary_basic := RULES.buy_pack(printed.profile, "basic", PackedByteArray([4,5,6]))
	var basic_pool_ok := true
	for id in (ordinary_basic.payload.cards as Array): basic_pool_ok = basic_pool_ok and RULES._rarity_index(str(RULES.card(str(id)).get("rarity", "common"))) <= RULES._rarity_index("uncommon")
	require(basic_pool_ok, "ordinary Basic Packs use only the Common–Uncommon pool")
	var pack_requirements := {"forge":[1,"rare",false],"arcane":[2,"rare",false],"primordial":[1,"epic",false],"champion":[3,"epic",true]}
	for pack_id in pack_requirements:
		var opened := RULES.buy_pack(printed.profile, str(pack_id), PackedByteArray([int(str(pack_id).length()), 17]))
		var minimum_count := 0; var legendary_count := 0
		for id in (opened.payload.cards as Array):
			var rarity_index := RULES._rarity_index(str(RULES.card(str(id)).get("rarity", "common")))
			if rarity_index >= RULES._rarity_index(str(pack_requirements[pack_id][1])): minimum_count += 1
			if rarity_index >= RULES._rarity_index("legendary"): legendary_count += 1
		require(bool(opened.ok) and minimum_count >= int(pack_requirements[pack_id][0]) and (not bool(pack_requirements[pack_id][2]) or legendary_count >= 1), "%s replaces lowest pulls to meet its guarantee" % str(pack_id).capitalize())
	var emergency_state := STATE.create(printed.profile.decks[0].cards, printed.profile.decks[0].cards, 99)
	emergency_state.active_seat = 0; emergency_state.phase = "main"; emergency_state.player(0).filament = 200; emergency_state.player(0).hand = ["emergency_reprint_upgrade"]; emergency_state.player(0).graveyard = ["cinderpaw"]
	var install := BATTLE.apply_intent(emergency_state, 0, {"type":"play_card","card_id":"emergency_reprint_upgrade"})
	var reprint := BATTLE.apply_intent(emergency_state, 0, {"type":"upgrade_reprint","graveyard_index":0})
	require(str(RULES.card("emergency_reprint_spell").get("type", "")) == "spell" and str(RULES.card("emergency_reprint_upgrade").get("type", "")) == "upgrade" and bool(install.ok) and bool(reprint.ok) and int(emergency_state.player(0).emergency_reprints) == 0 and bool(emergency_state.player(0).queue[0].get("reprint", false)), "Emergency Reprint spell and upgrade have distinct IDs and a deterministic installed charge intent")
	var status_state := STATE.create(printed.profile.decks[0].cards, printed.profile.decks[0].cards, 101)
	status_state.player(0).slots[0] = STATE._unit(RULES.card("cinderpaw")); status_state.player(1).slots[0] = STATE._unit(RULES.card("aquafin"))
	BATTLE._apply_gem_on_hit({"equipment":{"gem":{"effect":"ember_gem_burn"}}}, status_state.player(1).slots[0])
	var hp_before_burn := int(status_state.player(1).slots[0].hp); BATTLE._draw_start(status_state, 1); BATTLE._draw_start(status_state, 1)
	require(int(status_state.player(1).slots[0].hp) == hp_before_burn - 20, "Ember Gem deals ten damage on each of exactly two owner Draws")
	BATTLE._apply_gem_on_hit({"equipment":{"gem":{"effect":"frost_gem_lock"}}}, status_state.player(1).slots[0])
	status_state.phase = "main"; status_state.active_seat = 1
	require(not bool(BATTLE.apply_intent(status_state, 1, {"type":"switch_mode","slot":0,"mode":"defense"}).ok), "Frost Gem blocks the target’s next mode change before status expiry")
	BATTLE._apply_gem_on_hit({"equipment":{"gem":{"effect":"storm_gem_lock","used":false}}}, status_state.player(1).slots[0])
	status_state.phase = "attack"; status_state.player(1).slots[0].mode = "attack"; status_state.player(1).slots[0].ready = true; status_state.player(1).slots[0].attacked = false
	require(not bool(BATTLE.apply_intent(status_state, 1, {"type":"attack","slot":0,"target":0}).ok), "Storm Gem blocks the target’s next Attack Phase before status expiry")
	var gem_state := STATE.create(printed.profile.decks[0].cards, printed.profile.decks[0].cards, 107)
	gem_state.player(0).slots[0] = STATE._unit(RULES.card("cinderpaw")); gem_state.player(1).slots[0] = STATE._unit(RULES.card("aquafin"))
	BATTLE._attach_card(gem_state.player(0).slots[0], RULES.card("arcane_gem")); gem_state.player(1).slots[0].armor_hp = 50
	var base_hp_before_gem_hit := int(gem_state.player(1).slots[0].hp); var gem_damage := BATTLE._damage(gem_state.player(0).slots[0], gem_state.player(1).slots[0])
	BATTLE._damage_unit(gem_state, 1, 0, gem_damage, str(gem_state.player(0).slots[0].equipment.gem.effect) == "arcane_gem_drill")
	require(str(gem_state.player(0).slots[0].equipment.gem.card_id) == "arcane_gem" and int(gem_state.player(1).slots[0].armor_hp) == 50 and int(gem_state.player(1).slots[0].hp) < base_hp_before_gem_hit, "Arcane Gem occupies the gem slot and deterministically bypasses armor HP")
	var staging_state := STATE.create(printed.profile.decks[0].cards, printed.profile.decks[0].cards, 111)
	staging_state.active_seat = 0; staging_state.phase = "draw"
	for slot in 3: staging_state.player(0).slots[slot] = STATE._unit(RULES.card("cinderpaw"))
	staging_state.player(0).staging = [STATE._unit(RULES.card("aquafin"))]
	BATTLE._destroy(staging_state, 0, 1)
	require(staging_state.player(0).slots[1] == null, "staging never auto-enters without a legal mode decision")
	BATTLE.apply_intent(staging_state, 0, {"type":"advance_phase"})
	require(str(staging_state.pending.get("kind", "")) == "place" and bool(BATTLE.apply_intent(staging_state, 0, {"type":"place_completed","slot":1,"mode":"defense"}).ok), "the oldest staged creature pauses for placement and a chosen mode")
	var holding_state := STATE.create(printed.profile.decks[0].cards, printed.profile.decks[0].cards, 121)
	holding_state.active_seat = 0; holding_state.phase = "draw"; holding_state.player(0).slots[0] = STATE._unit(RULES.card("cinderpaw")); holding_state.player(0).holding = [{"card_id":"standard_full_suit","target":-1}]
	BATTLE.apply_intent(holding_state, 0, {"type":"advance_phase"})
	require(str(holding_state.pending.get("kind", "")) == "attach" and bool(BATTLE.apply_intent(holding_state, 0, {"type":"attach_completed","slot":0}).ok) and int(holding_state.player(0).slots[0].armor_hp) == 8, "held full suits receive an attach path when a compatible slot exists")
	var ring_state := STATE.create(printed.profile.decks[0].cards, printed.profile.decks[0].cards, 125)
	ring_state.active_seat = 0; ring_state.phase = "main"; ring_state.player(0).slots[0] = STATE._unit(RULES.card("cinderpaw")); ring_state.player(0).hand = ["filament_ring"]
	var ring_play := BATTLE.apply_intent(ring_state, 0, {"type":"play_card","card_id":"filament_ring"})
	BATTLE._destroy(ring_state, 0, 0); ring_state.player(0).scrap.clear(); var filament_before_ring_collect := int(ring_state.player(0).filament); BATTLE._collect(ring_state, 0)
	var ring_public := ring_state.public_snapshot(1)
	require(bool(ring_play.ok) and bool(ring_state.player(0).filament_ring_active) and bool(ring_public.players[0].filament_ring_active) and ring_state.player(0).queue.is_empty() and ring_state.player(0).graveyard.has("filament_ring") and int(ring_state.player(0).filament) == filament_before_ring_collect + 20, "Filament Ring resolves immediately, remains public after creature destruction, and grants twenty filament during Collect")
	ring_state.player(0).hand = ["filament_ring"]; ring_state.phase = "main"
	var ring_reject_before := ring_state.serialize(); var ring_reject := BATTLE.apply_intent(ring_state, 0, {"type":"play_card","card_id":"filament_ring"})
	require(not bool(ring_reject.ok) and ring_state.serialize() == ring_reject_before, "a second active Filament Ring rejects without mutating the battle snapshot")
	var active_ring_ai_state := STATE.create(printed.profile.decks[0].cards, printed.profile.decks[0].cards, 127)
	active_ring_ai_state.active_seat = 1; active_ring_ai_state.phase = "main"; active_ring_ai_state.player(1).filament_ring_active = true; active_ring_ai_state.player(1).hand = ["filament_ring"]
	AI.take_turn(active_ring_ai_state, 1)
	require(active_ring_ai_state.active_seat == 0 and active_ring_ai_state.player(1).hand == ["filament_ring"], "AI ignores an already active battle effect and advances instead of retrying it")
	var rival_opening_attack := STATE.create(printed.profile.decks[0].cards, printed.profile.decks[0].cards, 129)
	rival_opening_attack.starting_seat = 1; rival_opening_attack.active_seat = 1; rival_opening_attack.turn = 1; rival_opening_attack.phase = "attack"
	rival_opening_attack.player(1).slots[0] = STATE._unit(RULES.card("cinderpaw")); rival_opening_attack.player(1).slots[0].ready = true
	var player_hp_before_opening := int(rival_opening_attack.player(0).printer.hp)
	var opening_outcome := AI.take_turn(rival_opening_attack, 1)
	require(str(opening_outcome.get("status", "")) == "complete" and rival_opening_attack.active_seat == 0 and int(rival_opening_attack.player(0).printer.hp) == player_hp_before_opening and (opening_outcome.get("presentation_trace", []) as Array).is_empty(), "rival starting turn one skips its forbidden attack and legally returns control without emitting a false combat receipt")
	var rival_trace_state := STATE.create(printed.profile.decks[0].cards, printed.profile.decks[0].cards, 132)
	rival_trace_state.starting_seat = 0; rival_trace_state.active_seat = 1; rival_trace_state.turn = 2; rival_trace_state.phase = "attack"
	rival_trace_state.player(1).slots[0] = STATE._unit(RULES.card("cinderpaw")); rival_trace_state.player(1).slots[0].ready = true
	rival_trace_state.player(0).slots[0] = STATE._unit(RULES.card("aquafin"))
	var traced_outcome := AI.take_turn(rival_trace_state, 1)
	var trace: Array = traced_outcome.get("presentation_trace", []) as Array
	var attack_receipt: Dictionary = trace[0] if not trace.is_empty() else {}
	require(not trace.is_empty() and str(attack_receipt.get("kind", "")) == "attack" and int(attack_receipt.get("actor", -1)) == 1 and attack_receipt.has("left") and attack_receipt.has("right") and not attack_receipt.has("hand"), "AI returns replayable public attack receipts without private hand data")
	var rival_pending_attach := STATE.create(printed.profile.decks[0].cards, printed.profile.decks[0].cards, 130)
	rival_pending_attach.starting_seat = 1; rival_pending_attach.active_seat = 1; rival_pending_attach.turn = 1; rival_pending_attach.phase = "print"
	rival_pending_attach.player(1).slots[0] = STATE._unit(RULES.card("cinderpaw")); rival_pending_attach.player(1).slots[0].hp = 99; rival_pending_attach.player(1).slots[0].equipment.armor = {"card_id":"standard_full_suit"}
	rival_pending_attach.player(1).slots[1] = STATE._unit(RULES.card("aquafin")); rival_pending_attach.player(1).holding = [{"card_id":"standard_full_suit","target":0}]
	rival_pending_attach.pending = {"kind":"attach","seat":1,"card_id":"standard_full_suit","holding_index":0}
	var attach_outcome := AI.take_turn(rival_pending_attach, 1)
	require(str(attach_outcome.get("status", "")) == "complete" and rival_pending_attach.active_seat == 0 and rival_pending_attach.player(1).holding.is_empty() and str((rival_pending_attach.player(1).slots[1].equipment.armor as Dictionary).get("card_id", "")) == "standard_full_suit", "AI resolves a held full suit onto the deterministic compatible creature instead of retrying an occupied slot")
	var ability_state := STATE.create(printed.profile.decks[0].cards, printed.profile.decks[0].cards, 131)
	ability_state.player(0).slots[0] = STATE._unit(RULES.card("aquafin")); ability_state.player(1).slots[0] = STATE._unit(RULES.card("cinderpaw")); ability_state.player(0).slots[0].hp -= 10
	BATTLE._resolve_attack_ability(ability_state, 0, 0, 0)
	require(int(ability_state.player(0).slots[0].hp) == int(ability_state.player(0).slots[0].base_hp) - 2 and int(ability_state.player(0).slots[0].ability_cooldown) == int(RULES.card("aquafin").get("ability_cooldown", 0)), "catalog-authored attack-trigger abilities resolve deterministic signature effects and cooldowns")
	var quests := RULES.daily_quests(economy, "2026-08-21")
	var rerolled := RULES.reroll_daily_quest(quests.profile, "2026-08-21", 0)
	var progressed := RULES.record_quest_progress(rerolled.profile, "2026-08-21", str((rerolled.profile.quest_state.quests as Array)[0].get("objective", "")), 10)
	var quest_claim := RULES.claim_daily_quest(progressed.profile, "2026-08-21", str((progressed.profile.quest_state.quests as Array)[0].get("id", "")))
	require(bool(quests.ok) and (quests.payload.quests as Array).size() == 3 and bool(rerolled.ok) and bool(quest_claim.ok), "daily quests generate, reroll once, and issue chest rewards")
	var academy := RULES.academy_three_star_reward(economy, "academy-receipt", PackedByteArray([1]))
	var academy_again := RULES.academy_three_star_reward(academy.profile, "academy-receipt", PackedByteArray([1]))
	require(bool(academy.ok) and bool(academy_again.payload.duplicate), "Academy three-star reward uses an exactly-once receipt")
	var season_profile: Dictionary = economy.duplicate(true); season_profile.season.xp = 50000; season_profile.sparks = 1200
	var paid := RULES.buy_paid_season(season_profile)
	var season_free := RULES.claim_season_level(paid.profile, 5, false, 1724284800)
	var season_paid := RULES.claim_season_level(season_free.profile, 5, true, 1724284800)
	require(bool(paid.ok) and bool(season_free.ok) and bool(season_paid.ok), "50-level Season Track claims free and paid rewards without exclusive gameplay cards")
	var expired := RULES.claim_season_level(season_paid.profile, 6, false, int(season_paid.profile.season.ends_at) + 1)
	require(not bool(expired.ok), "expired Seasons reject reward claims")
	var spool_profile := RULES.new_profile(); spool_profile.spool_level = 1; spool_profile.spool_xp = 0
	var spool_first := RULES.grant_spool_xp(spool_profile, 100); var spool_many := RULES.grant_spool_xp(spool_profile, 500)
	require(int(spool_first.level) == 2 and int(spool_many.level) >= 3 and int(spool_profile.spool_level) <= 100, "Spool XP uses the level-times-100 curve and supports multi-level grants")
	var sparks := RULES.fake_store_purchase(economy, "fake-order", "forge_boost")
	var cosmetic := RULES.buy_cosmetic(sparks.profile, "copper_classic", "sparks")
	require(bool(sparks.ok) and bool(cosmetic.ok) and bool(cosmetic.profile.cosmetics.get("copper_classic", false)), "fake storefront grants Sparks and cosmetics remain non-gameplay inventory")
	if failures.is_empty(): print("PASS: v3.1 battle, deck, market, rewards, currency, pack, and redaction rules")
	get_tree().quit(0 if failures.is_empty() else 1)
