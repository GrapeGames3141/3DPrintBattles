class_name AIOpponent
extends RefCounted
## Deterministic legal-first solo policy. Scores are fixed integer heuristics;
## no gameplay RNG is introduced by difficulty choices.
const BATTLE_CATALOG := preload("res://scripts/battle/battle_catalog.gd")
const CARD_RULES := preload("res://scripts/battle/support_card_rules.gd")

static func choose_intent(state: BattleState, difficulty: String = "Apprentice") -> Dictionary:
	return choose_intent_for(state, 1, difficulty)

## Simulation seam: callers may evaluate either seat while the public rival
## wrapper above keeps the existing battle UI contract intact.
static func choose_intent_for(state: BattleState, player_index: int, difficulty: String = "Apprentice") -> Dictionary:
	if player_index != 1:
		# The combat AI's deterministic scoring is oriented to the rival seat. A
		# mirrored snapshot makes simulations legal without changing runtime rules.
		var mirrored := BattleState.from_snapshot(state.serialize())
		mirrored.players = [state.players[1].duplicate(true), state.players[0].duplicate(true)]
		mirrored.active_player = 1 - state.active_player
		mirrored.opening_player = 1 - state.opening_player
		mirrored.finished = state.finished
		return choose_intent(mirrored, difficulty)
	var setup_error := state.validation_error(true)
	if not setup_error.is_empty() or state.finished or state.active_player != 1: return {"type":"end_turn"}
	# Both seats get one setup action before attacks/signatures unlock. The
	# deterministic policy yields first, then braces second, reducing first-seat
	# advantage without granting either side an offensive opening.
	if state.turn == 1: return {"type":"end_turn"}
	if state.turn == 2: return {"type":"defend"}
	var candidates := _legal_candidates(state)
	if candidates.is_empty(): return {"type":"end_turn"}
	# Support cards do not consume a turn, so the action log is the stable
	# termination budget rather than turn count.
	if state.log.size() >= 100: return _choose_finish_pressure(state, candidates)
	if difficulty == "Apprentice":
		# Apprentice deliberately follows a readable, signature-first cadence;
		# Craftsman uses the scored card/switch policy and Master adds lookahead.
		return _choose_apprentice(state, candidates)
	if difficulty == "Master" and str(state.players[1].get("tactics", "")) == "overdrive":
		# A successful card application moves the card into this seat's discard.
		# That authoritative battle state permits exactly one Overdrive setup card
		# without letting an intent chooser mutate the match while merely previewing.
		if (state.players[1].get("discard", []) as Array).is_empty():
			var setup_card := _best_overdrive_card(state, candidates)
			if not setup_card.is_empty(): return setup_card
	return _choose_scored(state, candidates, difficulty == "Master")

static func _best_overdrive_card(state: BattleState, candidates: Array) -> Dictionary:
	# The named, visible Overdrive tactic spends an immediately useful setup
	# card before the normal Master attack evaluation. Cards keep their ordinary
	# legality and do not consume a turn, so this is a policy cadence, not a stat
	# modifier or combat-rule exception.
	var best: Dictionary = {}
	var best_score := 0
	for candidate in candidates:
		if str(candidate.get("type", "")) != "card": continue
		var card: Dictionary = BATTLE_CATALOG.support_card(str(candidate.get("card_id", "")))
		var score := 0
		for effect in CARD_RULES.normalized_effects(card):
			match str(effect.get("effect", "")):
				"attack_buff": score += int(effect.get("amount", 0)) * 20
				"filament": score += int(effect.get("amount", 0)) * 8
				"draw": score += int(effect.get("amount", 0)) * 5
				"cooldown": score += int(effect.get("amount", 0)) * 3
		if score > best_score:
			best_score = score
			best = candidate
	return best

static func _choose_finish_pressure(state: BattleState, candidates: Array) -> Dictionary:
	var unit := state.active_unit(1); var foe := state.active_unit(0)
	var best: Dictionary = {"type":"attack"}; var score := -1
	for candidate in candidates:
		var type := str(candidate.get("type", ""))
		if not type in ["attack", "ability"]: continue
		var value := BattleRules.estimate_damage(unit, foe, type == "ability")
		if value > score: score = value; best = candidate
	return best

static func _choose_apprentice(state: BattleState, candidates: Array) -> Dictionary:
	var unit := state.active_unit(1)
	var foe := state.active_unit(0)
	# The novice preserves a readable self-repair instinct before spending its
	# signature when it is already in the danger zone.
	if int(unit.get("hp", 0)) * 3 <= int(unit.get("max_hp", 1)):
		var recovery := _best_recovery_card(state, candidates)
		if not recovery.is_empty(): return recovery
	# Apprentice has no counter-switch/lookahead, but understands its own printed
	# signature: use it for extra damage or a visible recovery/resource payoff.
	for candidate in candidates:
		if str(candidate.get("type", "")) != "ability": continue
		var signature: Dictionary = BATTLE_CATALOG.signature_for_creature(str(unit.get("id", "")))
		var useful := BattleRules.estimate_damage(unit, foe, true) > BattleRules.estimate_damage(unit, foe, false)
		for effect in signature.get("effects", []):
			if effect is Dictionary and str(effect.get("effect", "")) in ["heal", "shield", "filament", "attack_buff"]: useful = true
		if useful: return candidate
	for candidate in candidates:
		if str(candidate.get("type", "")) == "attack": return candidate
	for candidate in candidates:
		if str(candidate.get("type", "")) == "defend": return candidate
	return candidates[0]

static func _best_recovery_card(state: BattleState, candidates: Array) -> Dictionary:
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
	return recovery

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
			if master: score += 35
			return score
		"card":
			var card: Dictionary = BATTLE_CATALOG.support_card(str(candidate.get("card_id", "")))
			var card_score := CARD_RULES.ai_utility(state, 1, card) * 7
			if int(unit.get("hp", 0)) * 3 <= int(unit.get("max_hp", 1)):
				card_score += CARD_RULES.ai_utility(state, 1, card) * 3
				for effect in CARD_RULES.normalized_effects(card):
					if str(effect.get("effect", "")) in ["heal", "shield"]: card_score += 1000
			return card_score - (20 if master else 0)
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
