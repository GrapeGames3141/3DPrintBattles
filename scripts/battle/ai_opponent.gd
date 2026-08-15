class_name AIOpponent
extends RefCounted
## Deterministic, legal-first solo opponent policy.

static func choose_intent(state: BattleState, difficulty: String = "Apprentice") -> Dictionary:
	var unit := state.active_unit(1)
	var foe := state.active_unit(0)
	if state.turn == 1 and state.opening_player == 1: return {"type":"defend"}
	var hand: Array = state.players[1].hand
	var filament: int = int(state.players[1].filament)
	var heal := _first_affordable(hand, filament, ["quick_patch", "coolant", "repair_drone", "flux_tape"])
	if int(unit.hp) * 3 <= int(unit.max_hp) and not heal.is_empty(): return {"type":"card","card_id":heal}
	if difficulty != "Apprentice":
		var lethal_ability: int = _ability_damage(unit, foe)
		if _can_ability(unit, filament) and lethal_ability >= int(foe.hp): return {"type":"ability"}
		if int(foe.hp) <= _basic_damage(unit, foe): return {"type":"attack"}
		if _can_ability(unit, filament) and difficulty == "Master" and Catalog.element_multiplier(str(unit.element), str(foe.element)) >= 150: return {"type":"ability"}
		var shield := _first_affordable(hand, filament, ["reinforced_layer", "dense_infill", "safety_brace", "spark_guard", "anchor_bolt"])
		if int(unit.hp) * 2 <= int(unit.max_hp) and not shield.is_empty(): return {"type":"card","card_id":shield}
		var switch_index := _best_switch(state)
		if switch_index >= 0: return {"type":"switch","index":switch_index}
		if _can_ability(unit, filament): return {"type":"ability"}
	if int(foe.hp) <= _basic_damage(unit, foe): return {"type":"attack"}
	return {"type":"attack"}

static func _first_affordable(hand: Array, filament: int, ids: Array) -> String:
	for card_id in hand:
		if not card_id in ids: continue
		var card := Catalog.support_card(str(card_id))
		if not card.is_empty() and filament >= int(card.cost): return str(card_id)
	return ""

static func _can_ability(unit: Dictionary, filament: int) -> bool:
	return not bool(unit.get("cooling", false)) and int(unit.get("cooldown_remaining", 0)) == 0 and int(unit.get("ability_lock_turns", 0)) == 0 and filament >= int(unit.get("ability_cost", 99))

static func _basic_damage(unit: Dictionary, foe: Dictionary) -> int:
	var scaled: int = (maxi(1, int(unit.attack) + int(unit.get("attack_buff", 0)) - int(unit.get("attack_debuff", 0))) * Catalog.element_multiplier(str(unit.element), str(foe.element))) / 100
	var post_armor: int = maxi(1, scaled - int(foe.get("armor", 0)))
	return maxi(0, post_armor - int(foe.get("shield", 0)))

static func _ability_damage(unit: Dictionary, foe: Dictionary) -> int:
	return _basic_damage({"attack":int(unit.attack) + 5,"attack_buff":int(unit.get("attack_buff",0)),"attack_debuff":int(unit.get("attack_debuff",0)),"element":unit.element}, foe)

static func _best_switch(state: BattleState) -> int:
	var active := state.active_unit(1)
	var foe := state.active_unit(0)
	for index in state.players[1].team.size():
		if index == int(state.players[1].active): continue
		var candidate: Dictionary = state.players[1].team[index]
		var cost: int = maxi(0, int(candidate.cost) - int(state.players[1].get("switch_discount", 0)))
		if int(candidate.hp) > 0 and int(state.players[1].filament) >= cost and Catalog.element_multiplier(str(candidate.element), str(foe.element)) > Catalog.element_multiplier(str(active.element), str(foe.element)): return index
	return -1
