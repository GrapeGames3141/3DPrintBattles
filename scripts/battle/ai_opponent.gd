class_name AIOpponent
extends RefCounted

static func choose_intent(state: BattleState, difficulty: String = "Apprentice") -> Dictionary:
	var unit := state.active_unit(1)
	var foe := state.active_unit(0)
	if state.turn == 1 and state.opening_player == 1:
		return {"type":"defend"}
	if unit.hp <= 9:
		for card in state.players[1].hand:
			if card == "quick_patch" or card == "coolant": return {"type":"card","card_id":card}
	if difficulty != "Apprentice" and unit.cooldown_remaining == 0 and state.players[1].filament >= unit.ability_cost: return {"type":"ability"}
	if foe.hp <= unit.attack + 5: return {"type":"attack"}
	return {"type":"attack"}
