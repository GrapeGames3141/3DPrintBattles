extends Node

var failures: Array[String] = []

func require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	var state := BattleState.create(["cinderpaw","aquafin","voltwig"],["mossmunk","stoneback","galehopper"],3,3,2)
	var canonical_unit: Dictionary = state.active_unit(0)
	require(str(canonical_unit.get("id", "")) == "cinderpaw" and str(canonical_unit.get("name", "")) == "Cinderpaw" and str(canonical_unit.get("element", "")) == "Fire" and int(canonical_unit.get("hp", 0)) == 34 and int(canonical_unit.get("attack", 0)) == 9 and str(canonical_unit.get("ability", "")) == "Ember Pounce", "normalization preserves fresh catalog battle values")
	require(state.active_player == 0, "coin flip seed should choose player")
	require(state.opening_player == 0, "opening player is retained")
	require(state.players[0].hand.size() == 4 and state.players[0].deck.size() == 11, "starter loadout deals four cards from a fifteen-card deck")
	var suited_unit: Dictionary = BattleState.normalize_unit({"creature_id":"cinderpaw", "health":44, "suit_id":"reinforced", "core_id":"storm"})
	require(int(suited_unit.get("hp", 0)) == 44 and int(suited_unit.get("max_hp", 0)) == 48 and int(suited_unit.get("speed", 0)) == 8 and int(suited_unit.get("armor", -1)) == 1 and str(suited_unit.get("suit_name", "")) == "Reinforced Full Suit", "full suit and valid Core derive catalog combat defaults without clamping health")
	var legacy_snapshot: Dictionary = state.serialize().duplicate(true)
	legacy_snapshot.players[0].team[0] = {"creature_id":"cinderpaw", "health":34}
	var restored := BattleState.from_snapshot(legacy_snapshot)
	var restored_before: Dictionary = restored.serialize().duplicate(true)
	var restored_unit: Dictionary = restored.active_unit(0)
	require(str(restored_unit.get("name", "")) == "Cinderpaw" and int(restored_unit.get("attack", 0)) == 9 and restored.serialize() == restored_before, "snapshot restore normalizes legacy unit once and active_unit is side-effect-free")
	var malformed_restore := BattleState.from_snapshot({"players":"not-an-array", "log":42})
	require(malformed_restore.players.is_empty() and malformed_restore.log.is_empty() and malformed_restore.active_unit(0).is_empty(), "snapshot restore rejects malformed player and log containers safely")
	var armored_state := BattleState.create(["cinderpaw"],["mossmunk"],3,3,2)
	var armored_snapshot: Dictionary = armored_state.serialize().duplicate(true)
	armored_snapshot.players[0].team[0] = {"creature_id":"cinderpaw", "health":44, "suit_id":"standard", "core_id":"ember"}
	armored_snapshot.turn = 3; armored_snapshot.active_player = 0; armored_snapshot.opening_player = 1
	armored_state = BattleState.from_snapshot(armored_snapshot)
	var armored_attack := BattleRules.apply_intent(armored_state, 0, {"type":"attack"})
	require(armored_attack.ok and int(armored_state.active_unit(0).get("attack", 0)) == 11 and int(armored_state.active_unit(1).get("hp", 0)) < int(armored_state.active_unit(1).get("max_hp", 0)), "normalized full-suit/Core unit still has legal catalog attack moves")
	var tide_state := BattleState.create([{"creature_id":"cinderpaw", "suit_id":"standard", "core_id":"tide"}], ["mossmunk"], 3, 3, 2)
	require(int(tide_state.active_unit(0).get("shield", 0)) == 4, "Tide Core starts battle with exactly 4 Shield")
	var invalid_core_state := BattleState.create([{"creature_id":"cinderpaw", "core_id":"ember"}], ["mossmunk"], 3, 3, 2)
	require(str(invalid_core_state.active_unit(0).get("core_id", "")) == "", "a Core without a valid suit cannot grant battle effects")
	var verdant_state := BattleState.create([{"creature_id":"cinderpaw", "suit_id":"standard", "core_id":"verdant"}], ["mossmunk"], 3, 3, 2)
	verdant_state.turn = 3; verdant_state.active_player = 1; verdant_state.active_unit(0).hp = 20; verdant_state.active_unit(1).attack = 1
	var verdant_hit := BattleRules.apply_intent(verdant_state, 1, {"type":"attack"})
	require(verdant_hit.ok and int(verdant_state.players[0].team[0].get("hp", 0)) == 23 and not bool(verdant_state.players[0].team[0].get("verdant_ready", true)), "Verdant heals 4 once when damage drops it below half health")
	verdant_state.active_player = 1
	BattleRules.apply_intent(verdant_state, 1, {"type":"attack"})
	require(int(verdant_state.players[0].team[0].get("hp", 0)) == 22, "Verdant does not heal a second time")
	require(state.players[0].hand.count("raw_filament") == 4, "starter loadout has deterministic opening hand")
	var before: int = int(state.active_unit(1).hp)
	var result := BattleRules.apply_intent(state, 0, {"type":"attack"})
	require(not result.ok and str(result.get("error", "")).contains("setup round"), "setup round blocks the first seat attack")
	require(state.active_unit(1).hp == before, "blocked setup attack deals no damage")
	result = BattleRules.apply_intent(state, 0, {"type":"ability"})
	require(not result.ok, "setup round blocks the first seat signature ability")
	var invalid_state := BattleState.create([], ["mossmunk"], 3, 3, 2)
	var invalid_result := BattleRules.apply_intent(invalid_state, 0, {"type":"attack"})
	require(not bool(invalid_result.get("ok", false)) and str(invalid_result.get("error", "")).contains("invalid player team"), "invalid team preflight reports setup before opening-turn restrictions")
	result = BattleRules.apply_intent(state, 0, {"type":"defend"})
	require(result.ok, "defend must be legal")
	require(state.players[0].team[0].shield == 4, "defend grants shield")
	require(state.active_player == 1 and state.players[1].filament == 3, "turn refill uses integer allowance")
	result = BattleRules.apply_intent(state, 1, {"type":"attack"})
	require(not result.ok and str(result.get("error", "")).contains("setup round"), "second setup seat cannot attack on turn two")
	result = BattleRules.apply_intent(state, 1, {"type":"defend"})
	require(result.ok and int(result.get("shield", 0)) == 8 and state.active_player == 0, "second setup seat receives the visible 8-shield reply guard")
	result = BattleRules.apply_intent(state, 0, {"type":"attack"})
	require(result.ok, "basic attack is legal after both setup actions")
	require(state.active_unit(1).hp < before, "attack deals damage after symmetric setup")
	require(Catalog.element_multiplier("Water", "Fire") == 150, "water/fire chart")
	state = BattleState.create(["cinderpaw","aquafin","voltwig"],["mossmunk","stoneback","galehopper"],3,3,3)
	result = AIOpponent.choose_intent(state, "Craftsman")
	require(result.type == "end_turn", "AI yields during the first setup action")
	require(BattleRules.apply_intent(state, 1, result).ok and state.active_player == 0, "AI setup intent advances the match")
	state = BattleState.create(["cinderpaw","aquafin","voltwig"],["mossmunk","stoneback","galehopper"],3,3,3)
	state.turn = 3
	state.active_player = 0
	state.players[0].team[0].hp = 0
	BattleRules._defeat(state, 0)
	require(state.players[0].active == 1 and state.active_unit(0).cooling, "forced replacement enters Cooling")
	result = BattleRules.apply_intent(state, 0, {"type":"attack"})
	require(result.ok, "a Cooling forced replacement may basic attack")
	state = BattleState.create(["cinderpaw","aquafin","voltwig"],["mossmunk","stoneback","galehopper"],3,3,3)
	state.turn = 3
	state.active_player = 1
	state.active_unit(0).shield = 100
	var shielded_hp: int = int(state.active_unit(0).hp)
	result = BattleRules.apply_intent(state, 1, {"type":"attack"})
	require(result.ok and int(result.damage) == 0 and state.active_unit(0).hp == shielded_hp, "shield absorbs post-armor damage to zero")
	state = BattleState.create(["cinderpaw","aquafin","voltwig"],["mossmunk","stoneback","galehopper"],3,3,2)
	state.players[0].hand = ["hot_swap", "filament_snare", "soft_reset"]
	result = BattleRules.apply_intent(state, 0, {"type":"hot_swap"})
	require(not result.ok, "unknown card intent is rejected")
	result = BattleRules.apply_intent(state, 0, {"type":"card","card_id":"hot_swap"})
	require(result.ok, "hand card must resolve")
	require(state.players[0].switch_discount == 3, "switch discount is applied")
	result = BattleRules.apply_intent(state, 0, {"type":"switch","index":1})
	require(result.ok and state.players[0].active == 1, "legal bench switch is available")
	require(state.players[0].switch_discount == 0, "switch discount is consumed by a successful switch")
	state = BattleState.create(["cinderpaw","aquafin","voltwig"],["mossmunk","stoneback","galehopper"],3,3,2)
	state.players[0].hand = ["filament_snare", "soft_reset"]
	result = BattleRules.apply_intent(state, 0, {"type":"card","card_id":"filament_snare"})
	require(result.ok and state.active_unit(1).attack_debuff == 2 and state.active_unit(1).ability_lock_turns == 1, "debuff cards apply attack and ability lock")
	state.active_unit(0).attack_debuff = 4
	state.active_unit(0).ability_lock_turns = 2
	state.players[0].filament = 3
	result = BattleRules.apply_intent(state, 0, {"type":"card","card_id":"soft_reset"})
	require(result.ok and state.active_unit(0).attack_debuff == 0 and state.active_unit(0).ability_lock_turns == 0, "cleanse cards remove active debuffs")
	var effects: Dictionary = {}
	for card in Catalog.SUPPORT_CARDS: effects[str(card.effect)] = true
	for effect in effects:
		require(effect in BattleRules.IMPLEMENTED_CARD_EFFECTS, "every support-card effect has a rule: %s" % effect)
	var total_weight: int = 0
	for rarity in Catalog.RARITIES: total_weight += int(rarity.weight_bps)
	require(Catalog.CREATURES.size() == 24, "launch creature count")
	require(Catalog.SUITS.size() == 5 and Catalog.CORE_BLUEPRINTS.size() == 5, "launch full-suit and Core counts")
	require(Catalog.SUPPORT_CARDS.size() == 30, "launch support card count")
	require(total_weight == 10000, "rarity shop weights are 10,000 basis points")
	var battle_state_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://scripts/battle/battle_state.gd"))
	var runtime_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://scripts/battle/battle_unit_runtime.gd"))
	require(not battle_state_source.contains("ArmorCoreDefinitions") and not runtime_source.contains("ArmorCoreDefinitions"), "battle runtime uses preloaded Core definitions without singleton timing")
	if failures.is_empty(): print("PASS: battle rules, suits, Cores, starter deck, cards, switching, catalog counts, and weights")
	call_deferred("_finish")

func _finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
