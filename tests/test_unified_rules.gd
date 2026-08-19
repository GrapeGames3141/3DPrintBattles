extends Node
const RULES := preload("res://scripts/core/unified_rules.gd")
const STATE := preload("res://scripts/battle/unified_battle_state.gd")
const BATTLE := preload("res://scripts/battle/unified_battle_rules.gd")
const AI := preload("res://scripts/battle/unified_ai_opponent.gd")
# Compile the interaction shell in this focused suite so target-picker syntax
# cannot regress independently of the authoritative rules.
const UNIFIED_MAIN := preload("res://scripts/ui/unified_main.gd")
var failures: Array[String] = []
func require(value: bool, message: String) -> void:
	if not value: failures.append(message); push_error(message)
func _tree_has_text(node: Node, needle: String) -> bool:
	if node is Label and needle in (node as Label).text: return true
	for child in node.get_children():
		if _tree_has_text(child, needle): return true
	return false
func _has_scroll_container(node: Node) -> bool:
	if node is ScrollContainer: return true
	for child in node.get_children():
		if _has_scroll_container(child): return true
	return false
func _content_fits_viewport(shell: Control) -> bool:
	if shell.get_child_count() == 0: return false
	# render() retires the preceding responsive page with queue_free(), so the
	# newest root is the final child during this same-frame focused UI test.
	var content := shell.get_child(shell.get_child_count() - 1) as Control
	return content != null and content.get_combined_minimum_size().y <= shell.size.y
func _layout_measurements(shell: Control) -> String:
	if shell.get_child_count() == 0: return ""
	var content := shell.get_child(shell.get_child_count() - 1) as Control
	var parts: Array[String] = []
	for child in content.get_children():
		if child is Control: parts.append("%s=%s" % [child.get_class(), (child as Control).get_combined_minimum_size()])
	return ", ".join(parts)
func _ready() -> void:
	print("UNIFIED_TEST phase=ready")
	var fresh := RULES.ensure({"schema_version":Catalog.SCHEMA_VERSION,"catalog_version":Catalog.CATALOG_VERSION,"coins":180,"xp":0,"creatures":[],"support_cards":{},"decks":[],"onboarding":{"state":"choose_starter","starter_id":"","starter_instance_id":""}})
	print("UNIFIED_TEST phase=ensure")
	var selected := RULES.choose_starter(fresh, "cinderpaw")
	print("UNIFIED_TEST phase=starter")
	require(bool(selected.ok) and int(selected.profile.owned_cards.cinderpaw) == 3 and str(selected.profile.onboarding.state) == "starter_selected", "starter grants blue card x3 before printing")
	var printed := RULES.print_starter(selected.profile)
	require(bool(printed.ok) and str(printed.profile.onboarding.state) == "complete" and int(printed.profile.coins) == int(selected.profile.coins), "starter print is free and gates completion")
	var bought := RULES.buy_pack(printed.profile, "pack_3", PackedByteArray([1,2,3,4,5,6,7,8]))
	print("UNIFIED_TEST phase=pack")
	require(bool(bought.ok) and int(bought.profile.coins) == int(printed.profile.coins) - 60 and (bought.payload.cards as Array).size() == 3 and not bought.profile.pending_pack_reveal.is_empty(), "pack purchase is charged and persisted before reveal")
	var blocked_pack := RULES.buy_pack(bought.profile, "pack_3", PackedByteArray([8,7,6,5,4,3,2,1]))
	require(not bool(blocked_pack.ok) and blocked_pack.profile == bought.profile, "pending pack reveal blocks a second pack without overwriting cards or charging coins")
	var creature_pack: Dictionary = {}
	for entropy_head in 256:
		var candidate := RULES.buy_pack(printed.profile, "pack_3", PackedByteArray([entropy_head,1,2,3,4,5,6,7]))
		if not bool(candidate.ok): continue
		for candidate_id in candidate.payload.cards:
			if str(RULES.card(str(candidate_id)).get("type", "")) == "creature": creature_pack = candidate; break
		if not creature_pack.is_empty(): break
	var packed_creature := ""
	for candidate_id in creature_pack.get("payload", {}).get("cards", []):
		if str(RULES.card(str(candidate_id)).get("type", "")) == "creature": packed_creature = str(candidate_id); break
	require(not packed_creature.is_empty() and packed_creature in creature_pack.profile.blueprints and packed_creature in creature_pack.profile.discovered and creature_pack.profile.get("creatures", []).size() == printed.profile.get("creatures", []).size(), "deterministic creature pack unlocks blueprint and Forgedex without printing")
	var migration_seed := ProfileRules.new_profile()
	migration_seed.owned_cards = {"geargecko":1}
	migration_seed.blueprints = []
	migration_seed.discovered = []
	var repaired_ownership := RULES.ensure(migration_seed)
	require("geargecko" in repaired_ownership.blueprints and "geargecko" in repaired_ownership.discovered, "ensure repairs legacy blueprint and Forgedex records from owned creature cards")
	var market_day := ""
	var market_card := ""
	var offers: Array = []
	for day_number in range(1, 80):
		var candidate_day := "2026-08-%02d" % day_number
		var candidate_offers := RULES.market_offers(candidate_day)
		for offer in candidate_offers:
			if str(RULES.card(str(offer.get("id", ""))).get("type", "")) == "creature":
				market_day = candidate_day; market_card = str(offer.get("id", "")); offers = candidate_offers; break
		if not market_card.is_empty(): break
	var market_before: Dictionary = printed.profile.duplicate(true)
	market_before.coins = 500
	market_before.card_xp[market_card] = 7
	market_before.card_builds[market_card] = ["power_a"]
	var single := RULES.buy_market_card(market_before, market_card, market_day)
	require(bool(single.ok) and int(single.profile.owned_cards.get(market_card, 0)) == int(market_before.owned_cards.get(market_card, 0)) + 1 and int(single.profile.card_xp.get(market_card, 0)) == 7 and single.profile.card_builds.get(market_card, []) == ["power_a"] and market_card in single.profile.blueprints and market_card in single.profile.discovered and single.profile.get("creatures", []).size() == market_before.get("creatures", []).size(), "market creature single grants ownership, blueprint, and Forgedex without XP/build or print side effects")
	var unavailable := RULES.buy_market_card(market_before, "not_on_shelf", market_day)
	require(not bool(unavailable.ok) and unavailable.profile == market_before, "market rejects a card outside the current purchasable offers atomically")
	var cards: Array = printed.profile.decks[0].cards.duplicate()
	require(RULES.deck_reason(printed.profile, cards).is_empty(), "starter deck is unified legal")
	var printer_xp: Dictionary = printed.profile.duplicate(true); printer_xp.forge_xp = 500
	var upgraded := RULES.apply_printer_nodes(printer_xp, ["spool_5", "spool_7"])
	var reset := RULES.respec_printer(upgraded.profile)
	require(bool(reset.ok) and int(reset.profile.forge_xp) == 500 and reset.profile.printer_nodes.is_empty(), "printer respec refunds every purchased node")
	var card_xp: Dictionary = printed.profile.duplicate(true); card_xp.card_xp.cinderpaw = 20
	var locked := RULES.build_card(card_xp, "cinderpaw", "power_b")
	var tier_a := RULES.build_card(card_xp, "cinderpaw", "power_a")
	var tier_b := RULES.build_card(tier_a.profile, "cinderpaw", "power_b")
	var card_reset := RULES.respec_card(tier_b.profile, "cinderpaw")
	require(not bool(locked.ok) and bool(tier_b.ok) and int(card_reset.profile.card_xp.cinderpaw) == 20, "tier-B needs tier-A and card respec refunds XP")
	var state := STATE.create(cards, cards, 11)
	print("UNIFIED_TEST phase=state")
	require(state.phase == "play" and state.player(0).slots.size() == 3 and int(state.player(0).printer.durability) == 100, "battle initializes phase, three slots, and printer")
	state.players[0].hand = ["swiftweave_suit"]; state.players[0].filament = 3
	var before_invalid := state.serialize()
	var invalid_equipment := BATTLE.apply_intent(state, 0, {"type":"play_card","card_id":"swiftweave_suit","target":-1})
	require(not bool(invalid_equipment.ok) and state.serialize() == before_invalid, "invalid equipment target rejects atomically")
	var target_state := STATE.create(cards, cards, 31)
	target_state.phase = "attack"
	target_state.players[0].slots[0] = {"card_id":"cinderpaw","name":"Cinderpaw","hp":4,"attack":3,"cost":1,"guard":0,"ready":true}
	target_state.players[1].slots[0] = {"card_id":"cinderpaw","name":"Guard A","hp":4,"attack":1,"cost":1,"guard":0,"ready":true}
	target_state.players[1].slots[1] = {"card_id":"cinderpaw","name":"Guard B","hp":5,"attack":1,"cost":1,"guard":0,"ready":true}
	var before_missing_attack := target_state.serialize()
	var missing_attack_target := BATTLE.apply_intent(target_state, 0, {"type":"attack","slot":0})
	require(not bool(missing_attack_target.ok) and target_state.serialize() == before_missing_attack, "attack without an explicit target rejects without selecting first enemy")
	var chosen_attack_target := BATTLE.apply_intent(target_state, 0, {"type":"attack","slot":0,"target":1})
	require(bool(chosen_attack_target.ok) and int(target_state.player(1).slots[0].hp) == 4 and int(target_state.player(1).slots[1].hp) == 2, "attack damages only the explicitly selected enemy slot")
	var spell_state := STATE.create(cards, cards, 37)
	spell_state.players[0].hand = ["bed_jam"]
	spell_state.players[0].filament = 3
	var before_missing_spell := spell_state.serialize()
	var missing_spell_target := BATTLE.apply_intent(spell_state, 0, {"type":"play_card","card_id":"bed_jam"})
	require(not bool(missing_spell_target.ok) and spell_state.serialize() == before_missing_spell, "targeted spell requires an explicit printer target atomically")
	var chosen_spell_target := BATTLE.apply_intent(spell_state, 0, {"type":"play_card","card_id":"bed_jam","target":-1})
	require(bool(chosen_spell_target.ok) and int(spell_state.player(1).printer.slow) == 1, "targeted spell applies only after printer target is chosen")
	require(bool(BATTLE.apply_intent(state, 0, {"type":"advance_phase"}).ok) and state.phase == "attack", "phase advance works")
	# A rival turn must be fully authority-driven through play, attack, and collect.
	var ai_state := STATE.create(cards, cards, 19)
	require(bool(BATTLE.apply_intent(ai_state, 0, {"type":"advance_phase"}).ok), "player enters attack")
	require(bool(BATTLE.apply_intent(ai_state, 0, {"type":"advance_phase"}).ok), "player enters collect")
	require(bool(BATTLE.apply_intent(ai_state, 0, {"type":"advance_phase"}).ok) and ai_state.active_seat == 1, "player ends turn")
	AI.take_turn(ai_state, 1)
	require(ai_state.active_seat == 0 and ai_state.phase == "play", "AI completes Play, Attack, and Collect through unified intents")
	require(RULES.all_cards().size() == 80, "catalog exposes eighty unified cards")
	require(not ResourceLoader.exists("res://scripts/ui/unified_main.gd") == false, "unified no-scroll shell is present")
	var settled := RULES.settle_unified_battle(printed.profile, "test-result", ["cinderpaw"], true, 3, 5)
	var replay := RULES.settle_unified_battle(settled.profile, "test-result", ["cinderpaw"], true, 3, 5)
	require(bool(settled.ok) and bool(replay.payload.duplicate) and int(replay.profile.workshop_filament) == int(settled.profile.workshop_filament), "unified settlement persists once and is idempotent")
	var snapshot := STATE.create(cards, cards, 23, ["calibrated_rails","heated_bed"], [], {"cinderpaw":["power_a"]})
	require(int(snapshot.player(0).printer.durability) == 110 and snapshot.player(0).card_builds.has("cinderpaw"), "battle captures printer and card builds at launch")
	var adapter_profile := RULES.ensure(ProfileRules.new_profile())
	adapter_profile.coins = 180
	adapter_profile = RULES.choose_starter(adapter_profile, "cinderpaw").profile
	adapter_profile = RULES.print_starter(adapter_profile).profile
	GameManager.profile = adapter_profile.duplicate(true)
	var daily_day := "2026-08-18"
	var contracts := GameManager.prepare_daily_training(daily_day)
	var daily_launch := GameManager.create_unified_daily_battle(str(contracts[0].get("id", "")), daily_day, 77) if not contracts.is_empty() else {"ok":false}
	var daily_repeat := GameManager.create_unified_daily_battle(str(contracts[0].get("id", "")), daily_day, 77) if not contracts.is_empty() else {"ok":false}
	require(bool(daily_launch.get("ok", false)) and str(daily_launch.get("settlement_context", {}).get("mode", "")) == "daily" and str(daily_launch.get("settlement_context", {}).get("day_key", "")) == daily_day and int(daily_launch.get("seed", 0)) == int(daily_repeat.get("seed", -1)), "daily launch consumes frozen contract data with deterministic seed and settlement identity")
	var daily_settlement := GameManager.settle_unified_mode_battle(daily_launch.get("settlement_context", {}), daily_launch.get("battle", null), true) if bool(daily_launch.get("ok", false)) else {"ok":false}
	var daily_duplicate := GameManager.settle_unified_mode_battle(daily_launch.get("settlement_context", {}), daily_launch.get("battle", null), true) if bool(daily_launch.get("ok", false)) else {"ok":false}
	require(bool(daily_settlement.get("ok", false)) and bool(daily_settlement.get("payload", {}).get("reward_claim", {}).get("first_clear", false)) and bool(daily_duplicate.get("payload", {}).get("duplicate", false)), "daily reward claim and unified settlement are exactly once")
	GameManager.profile = adapter_profile.duplicate(true)
	GameManager.prepare_daily_training(daily_day)
	var lost_launch := GameManager.create_unified_daily_battle(str(contracts[0].get("id", "")), daily_day, 77)
	var lost_result := GameManager.settle_unified_mode_battle(lost_launch.get("settlement_context", {}), lost_launch.get("battle", null), false)
	var win_launch := GameManager.create_unified_daily_battle(str(contracts[0].get("id", "")), daily_day, 77)
	var win_result := GameManager.settle_unified_mode_battle(win_launch.get("settlement_context", {}), win_launch.get("battle", null), true)
	require(bool(lost_result.get("ok", false)) and bool(win_result.get("payload", {}).get("reward_claim", {}).get("first_clear", false)) and str(lost_launch.get("settlement_context", {}).get("result_id", "")) != str(win_launch.get("settlement_context", {}).get("result_id", "")), "loss and later win have distinct result ids while the authored reward remains first-clear")
	var built_snapshot := STATE.create(cards, cards, 29, [], [], {"cinderpaw":["power_a","power_b","tempo_a","tempo_b","utility_a","utility_b"]})
	built_snapshot.players[0].hand = ["cinderpaw"]
	built_snapshot.players[0].filament = 5
	BATTLE.apply_intent(built_snapshot, 0, {"type":"play_card","card_id":"cinderpaw","slot":0})
	BATTLE.apply_intent(built_snapshot, 0, {"type":"advance_phase"})
	BATTLE.apply_intent(built_snapshot, 0, {"type":"advance_phase"})
	BATTLE.apply_intent(built_snapshot, 0, {"type":"advance_phase"})
	require(built_snapshot.player(0).slots[0] != null and int(built_snapshot.player(0).slots[0].attack) == int(RULES.card("cinderpaw").attack) + 5 and int(built_snapshot.player(0).slots[0].hp) == int(RULES.card("cinderpaw").hp) + 10 and int(built_snapshot.player(0).slots[0].guard) == 1, "all creature A/B build effects apply from immutable launch snapshot")
	GameManager.profile = adapter_profile.duplicate(true)
	var trial_launch := GameManager.create_unified_trial_battle("first_layers_1", 91)
	require(bool(trial_launch.get("ok", false)) and str(trial_launch.get("settlement_context", {}).get("source_id", "")) == "first_layers_1" and int(trial_launch.get("battle", null).player(1).spool_cap) == 3, "trial launch consumes authored encounter identity, team, and spool setup")
	var presented: Dictionary = {}
	var arrival_key := UNIFIED_MAIN._arrival_key(23, 0, 1, "cinderpaw")
	require(UNIFIED_MAIN.consume_arrival(presented, arrival_key) and not UNIFIED_MAIN.consume_arrival(presented, arrival_key), "arrival presentation consumes each printer-to-slot event once")
	require(UNIFIED_MAIN.arrival_duration(false) > 0.0 and is_zero_approx(UNIFIED_MAIN.arrival_duration(true)), "reduced motion makes print arrival instant")
	# The compact shell remains a component/presentation seam only. Shipped UI
	# navigation, layout and Trial settlement are exercised through main.tscn in
	# test_ui_trials and test_ui_workshop_nav; do not instantiate it as the game.
	if failures.is_empty(): print("PASS: unified onboarding, packs, deck validation, and battle setup")
	call_deferred("_finish")
func _finish() -> void: get_tree().quit(0 if failures.is_empty() else 1)
