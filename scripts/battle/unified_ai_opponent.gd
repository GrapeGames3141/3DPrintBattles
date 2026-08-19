class_name UnifiedAIOpponent
extends RefCounted
const RULES := preload("res://scripts/core/unified_rules.gd")
const BATTLE_RULES := preload("res://scripts/battle/unified_battle_rules.gd")

## Deterministic local opponent: it makes only public authority intents.
static func take_turn(state: UnifiedBattleState, seat: int) -> void:
	if state.finished or state.active_seat != seat: return
	var p := state.player(seat)
	if state.phase == "play":
		for id in p.hand.duplicate():
			var card := RULES.card(str(id))
			if int(card.get("cost", 0)) > int(p.filament): continue
			var intent := {"type":"play_card","card_id":str(id),"slot":_first_open_slot(p),"target":_first_ready_slot(p)}
			if bool(BATTLE_RULES.apply_intent(state, seat, intent).get("ok", false)): break
		BATTLE_RULES.apply_intent(state, seat, {"type":"advance_phase"})
	if state.phase == "attack":
		for index in 3:
			if p.slots[index] != null and bool(p.slots[index].get("ready", false)):
				BATTLE_RULES.apply_intent(state, seat, {"type":"attack","slot":index,"target":_first_ready_slot(state.player(1-seat))})
		BATTLE_RULES.apply_intent(state, seat, {"type":"advance_phase"})
	if state.phase == "collect":
		BATTLE_RULES.apply_intent(state, seat, {"type":"collect","pile":0})
		BATTLE_RULES.apply_intent(state, seat, {"type":"advance_phase"})

static func _first_open_slot(player: Dictionary) -> int:
	for index in 3:
		if player.slots[index] == null: return index
	return -1
static func _first_ready_slot(player: Dictionary) -> int:
	for index in 3:
		if player.slots[index] != null: return index
	return -1
