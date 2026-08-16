class_name AIOpponent
extends RefCounted
## Deterministic legal-first solo policy. Scores are fixed integer heuristics;
## no gameplay RNG is introduced by difficulty choices.
const BATTLE_CATALOG := preload("res://scripts/battle/battle_catalog.gd")
const CARD_RULES := preload("res://scripts/battle/support_card_rules.gd")

static func choose_intent(state: BattleState, difficulty: String = "Apprentice") -> Dictionary:
	var setup_error := state.validation_error(true)
	if not setup_error.is_empty() or state.finished or state.active_player != 1: return {"type":"end_turn"}
	# The opening winner may only defend or yield; choose the defensive legal option.
	if state.turn == 1 and state.opening_player == 1: return {"type":"defend"}
	var candidates := _legal_candidates(state)
	if candidates.is_empty(): return {"type":"end_turn"}
	if difficulty == "Apprentice": return _choose_apprentice(state, candidates)
	return _choose_scored(state, candidates, difficulty == "Master")

static func _choose_apprentice(state: BattleState, candidates: Array) -> Dictionary:
	var unit := state.active_unit(1)
	if int(unit.get("hp", 0)) * 3 <= int(unit.get("max_hp", 1)):
		var recovery: Dictionary = {}
		var recovery_score := -999999
		for candidate in candidates:
			if str(candidate.get("type", "")) != "card": continue
			var card: Dictionary = BATTLE_CATALOG.support_card(str(candidate.get("card_id", "")))
			var restores := false
			for effect in CARD_RULES.normalized_effects(card):
				if str(effect.get("effect", "")) in ["heal", "shield"]: restores = true; break
			if not restores: continue
			var score := CARD_RULES.ai_utility(state, 1, card)
			if score > recovery_score:
				recovery_score = score
				recovery = candidate
		if not recovery.is_empty(): return recovery
	for candidate in candidates:
		if str(candidate.get("type", "")) == "attack": return candidate
	for candidate in candidates:
		if str(candidate.get("type", "")) == "defend": return candidate
	return candidates[0]

static func _choose_scored(state: BattleState, candidates: Array, master: bool) -> Dictionary:
	var best: Dictionary = {"type":"end_turn"}
	var best_score := -999999
	for candidate in candidates:
		var score := _score_candidate(state, candidate, master)
		# Stable list order is the deterministic tie-breaker.
		if score > best_score:
			best_score = score
			best = candidate
	return best

static func _score_candidate(state: BattleState, candidate: Dictionary, master: bool) -> int:
	var unit := state.active_unit(1)
	var foe := state.active_unit(0)
	var type := str(candidate.get("type", ""))
	var health_missing: int = maxi(0, int(unit.get("max_hp", 0)) - int(unit.get("hp", 0)))
	var incoming_basic: int = BattleRules.estimate_damage(foe, unit, false)
	match type:
		"attack", "ability":
			var damage: int = BattleRules.estimate_damage(unit, foe, type == "ability")
			var score: int = damage * 10
			if damage >= int(foe.get("hp", 0)): score += 10000
			if type == "ability":
				score += _signature_utility(unit, foe, state, master)
				# Spending scarce filament is only worthwhile when the signature has a payoff.
				score -= int(unit.get("ability_cost", 0)) * 3
			elif BATTLE_CATALOG.element_multiplier(str(unit.get("element", "")), str(foe.get("element", ""))) >= 150:
				score += 12
			return score
		"card":
			var card: Dictionary = BATTLE_CATALOG.support_card(str(candidate.get("card_id", "")))
			var card_score := CARD_RULES.ai_utility(state, 1, card) * 7
			if int(unit.get("hp", 0)) * 3 <= int(unit.get("max_hp", 1)):
				card_score += CARD_RULES.ai_utility(state, 1, card) * 3
				for effect in CARD_RULES.normalized_effects(card):
					if str(effect.get("effect", "")) in ["heal", "shield"]: card_score += 1000
			return card_score + (10 if master else 0)
		"switch":
			var candidate_unit: Dictionary = state.players[1].team[int(candidate.get("index", -1))]
			var delta: int = BATTLE_CATALOG.element_multiplier(str(candidate_unit.get("element", "")), str(foe.get("element", ""))) - BATTLE_CATALOG.element_multiplier(str(unit.get("element", "")), str(foe.get("element", "")))
			return delta * 2 + (120 if int(unit.get("hp", 0)) * 3 <= int(unit.get("max_hp", 1)) else 0)
		"defend": return 30 + (100 if incoming_basic >= int(unit.get("hp", 0)) else 0)
		"end_turn": return 0
	return -100

static func _signature_utility(unit: Dictionary, foe: Dictionary, state: BattleState, master: bool) -> int:
	var score := 0
	for raw_effect in BATTLE_CATALOG.signature_for_creature(str(unit.get("id", ""))).get("effects", []):
		if not raw_effect is Dictionary: continue
		var amount: int = int(raw_effect.get("amount", 0))
		match str(raw_effect.get("effect", "")):
			"heal": score += mini(maxi(0, int(unit.get("max_hp", 0)) - int(unit.get("hp", 0))), amount) * 7
			"shield": score += amount * 5
			"filament": score += amount * 4
			"attack_buff": score += amount * 5
			"debuff": score += amount * 6
			"cleanse": score += 60 if int(unit.get("attack_debuff", 0)) > 0 or int(unit.get("ability_lock_turns", 0)) > 0 else 4
			"switch_discount": score += amount * 3 if _best_switch(state) >= 0 else 1
			"ability_lock": score += amount * (8 if master else 5)
	return score

static func _legal_candidates(state: BattleState) -> Array:
	var result: Array = [{"type":"attack"}, {"type":"defend"}, {"type":"end_turn"}]
	var unit := state.active_unit(1)
	var filament: int = int(state.players[1].get("filament", 0))
	if _can_ability(unit, filament): result.append({"type":"ability"})
	for card_id in state.players[1].get("hand", []):
		var card := BATTLE_CATALOG.support_card(str(card_id))
		if CARD_RULES.legality_reason(state, 1, card).is_empty():
			result.append({"type":"card","card_id":str(card_id)})
	for index in state.players[1].get("team", []).size():
		if index == int(state.players[1].get("active", 0)): continue
		var candidate: Dictionary = state.players[1].team[index]
		var cost: int = maxi(0, int(candidate.get("cost", 0)) - int(state.players[1].get("switch_discount", 0)))
		if int(candidate.get("hp", 0)) > 0 and filament >= cost: result.append({"type":"switch","index":index})
	return result

static func _can_ability(unit: Dictionary, filament: int) -> bool:
	return not bool(unit.get("cooling", false)) and int(unit.get("cooldown_remaining", 0)) == 0 and int(unit.get("ability_lock_turns", 0)) == 0 and filament >= int(unit.get("ability_cost", 99))

static func _best_switch(state: BattleState) -> int:
	var active := state.active_unit(1)
	var foe := state.active_unit(0)
	for index in state.players[1].team.size():
		if index == int(state.players[1].active): continue
		var candidate: Dictionary = state.players[1].team[index]
		var cost: int = maxi(0, int(candidate.cost) - int(state.players[1].get("switch_discount", 0)))
		if int(candidate.hp) > 0 and int(state.players[1].filament) >= cost and BATTLE_CATALOG.element_multiplier(str(candidate.element), str(foe.element)) > BATTLE_CATALOG.element_multiplier(str(active.element), str(foe.element)): return index
	return -1
