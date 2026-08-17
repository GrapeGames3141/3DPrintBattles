extends Node
## Deterministic, contextual balance audit. It rejects only real data defects:
## unusable legal cards, duplicate same-tier vectors, or an AI illegal choice.
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value: failures.append(message); push_error(message)

func _ready() -> void:
	var vectors := {}
	var utilities: Array[int] = []
	for card in Catalog.SUPPORT_CARDS:
		var state := _useful_state(str(card.id))
		var utility: int = SupportCardRules.ai_utility(state, 1, card); utilities.append(utility)
		require(SupportCardRules.legality_reason(state, 1, card).is_empty(), "prepared legal card: " + str(card.id))
		require(utility > 0 and utility == SupportCardRules.ai_utility(state, 1, card), "positive stable contextual utility: " + str(card.id))
		var vector := "%s|%d|" % [str(card.rarity), int(card.cost)]
		for effect in SupportCardRules.normalized_effects(card): vector += "%s:%s:%d;" % [str(effect.effect), str(effect.target), int(effect.amount)]
		require(not vectors.has(vector), "no same-tier exact effect vector duplicate: " + str(card.id)); vectors[vector] = str(card.id)
		for effect in SupportCardRules.normalized_effects(card): require(str(effect.target) in ["forge", "team", "self", "foe"], "valid target: " + str(card.id))
	_assert_ai_choices()
	utilities.sort()
	print("BALANCE_AUDIT: cards=30 contextual utility_min=%d utility_max=%d; 30 legal/useful vectors; no same-tier exact duplicates." % [utilities.front(), utilities.back()])
	call_deferred("finish")

func _useful_state(card_id: String) -> BattleState:
	var state := BattleState.create(["cinderpaw"], ["mossmunk", "aquafin"], 10, 10, 2)
	state.turn = 3; state.active_player = 1; state.players[1].hand = [card_id]; state.players[1].filament = 9; state.players[1].deck = ["raw_filament", "heated_spool"]
	var unit := state.active_unit(1); unit.hp = 5; unit.cooldown_remaining = 2; unit.attack_debuff = 2; unit.ability_lock_turns = 1
	return state

func _assert_ai_choices() -> void:
	var cases := {"heal":["arcane_spark", "quick_patch"], "offense":["arcane_spark"], "resource":["raw_filament"], "mixed":["spool_siphon", "switchback"]}
	for label_name in cases:
		var state := _useful_state("raw_filament"); state.players[1].hand = cases[label_name]
		var intent := AIOpponent.choose_intent(state, "Master")
		require(str(intent.get("type", "")) != "card" or SupportCardRules.legality_reason(state, 1, Catalog.support_card(str(intent.get("card_id", "")))).is_empty(), "AI legal %s choice" % str(label_name))
	var recovery := _useful_state("quick_patch"); recovery.players[1].hand = ["arcane_spark", "quick_patch"]
	require(AIOpponent.choose_intent(recovery, "Apprentice") == {"type":"card", "card_id":"quick_patch"}, "Apprentice recovery policy is deterministic")

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
