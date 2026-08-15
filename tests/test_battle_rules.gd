extends Node

var failures: Array[String] = []

func require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	var state := BattleState.create(["cinderpaw","aquafin","voltwig"],["mossmunk","stoneback","galehopper"],3,3,2)
	require(state.active_player == 0, "coin flip seed should choose player")
	require(state.opening_player == 0, "opening player is retained")
	require(state.players[0].hand.size() == 4 and state.players[0].deck.size() == 11, "starter loadout deals four cards from a fifteen-card deck")
	require(state.players[0].hand.count("raw_filament") == 4, "starter loadout has deterministic opening hand")
	var before: int = int(state.active_unit(1).hp)
	var result := BattleRules.apply_intent(state, 0, {"type":"attack"})
	require(not result.ok, "coin-flip winner cannot attack on opening turn")
	require(state.active_unit(1).hp == before, "blocked opening attack deals no damage")
	result = BattleRules.apply_intent(state, 0, {"type":"ability"})
	require(not result.ok, "coin-flip winner cannot use offensive ability on opening turn")
	result = BattleRules.apply_intent(state, 0, {"type":"defend"})
	require(result.ok, "defend must be legal")
	require(state.players[0].team[0].shield == 4, "defend grants shield")
	require(state.active_player == 1 and state.players[1].filament == 3, "turn refill uses integer allowance")
	result = BattleRules.apply_intent(state, 1, {"type":"end_turn"})
	require(result.ok and state.active_player == 0, "opponent can end turn")
	result = BattleRules.apply_intent(state, 0, {"type":"attack"})
	require(result.ok, "basic attack is legal after opening turn")
	require(state.active_unit(1).hp < before, "attack deals damage after opening turn")
	require(Catalog.element_multiplier("Water", "Fire") == 150, "water/fire chart")
	state = BattleState.create(["cinderpaw","aquafin","voltwig"],["mossmunk","stoneback","galehopper"],3,3,3)
	result = AIOpponent.choose_intent(state, "Craftsman")
	require(result.type == "defend", "AI opens with defend when it wins the coin flip")
	require(BattleRules.apply_intent(state, 1, result).ok and state.active_player == 0, "AI opening intent advances the match")
	state = BattleState.create(["cinderpaw","aquafin","voltwig"],["mossmunk","stoneback","galehopper"],3,3,3)
	state.turn = 2
	state.active_player = 0
	state.players[0].team[0].hp = 0
	BattleRules._defeat(state, 0)
	require(state.players[0].active == 1 and state.active_unit(0).cooling, "forced replacement enters Cooling")
	result = BattleRules.apply_intent(state, 0, {"type":"attack"})
	require(result.ok, "a Cooling forced replacement may basic attack")
	state = BattleState.create(["cinderpaw","aquafin","voltwig"],["mossmunk","stoneback","galehopper"],3,3,3)
	state.turn = 2
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
	require(Catalog.ARMOR.size() == 7, "launch armor count")
	require(Catalog.SUPPORT_CARDS.size() == 30, "launch support card count")
	require(total_weight == 10000, "rarity shop weights are 10,000 basis points")
	if failures.is_empty(): print("PASS: battle rules, starter deck, cards, switching, catalog counts, and weights")
	call_deferred("_finish")

func _finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
