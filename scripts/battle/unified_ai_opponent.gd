class_name UnifiedAIOpponent
extends RefCounted
const RULES := preload("res://scripts/core/unified_rules.gd")
const BATTLE := preload("res://scripts/battle/unified_battle_rules.gd")
## Deterministic, legal intent-only AI. It sees public queues and field state,
## but never opponent hands or face-down trap identities.
static func take_turn(state: UnifiedBattleState, seat: int) -> void:
	var safety := 0
	while not state.finished and state.active_seat == seat and safety < 32:
		safety += 1
		if not state.pending.is_empty():
			if str(state.pending.get("kind", "")) == "place": BATTLE.apply_intent(state,seat,{"type":"place_completed","slot":_open(state.player(seat)),"mode":"attack"})
			else: BATTLE.apply_intent(state,seat,{"type":"attach_completed","slot":_best_friend(state.player(seat))})
			continue
		match state.phase:
			"draw": BATTLE.apply_intent(state,seat,{"type":"advance_phase"})
			"main":
				var intent := _main_intent(state,seat)
				if intent.is_empty(): BATTLE.apply_intent(state,seat,{"type":"advance_phase"})
				else: BATTLE.apply_intent(state,seat,intent)
			"print": BATTLE.apply_intent(state,seat,{"type":"advance_phase"})
			"attack":
				var attack := _attack_intent(state,seat)
				if attack.is_empty(): BATTLE.apply_intent(state,seat,{"type":"advance_phase"})
				else: BATTLE.apply_intent(state,seat,attack)
			"collect":
				if state.player(seat).hand.size() > 8: BATTLE.apply_intent(state,seat,{"type":"discard_overflow","card_ids":state.player(seat).hand.slice(0,state.player(seat).hand.size()-8)})
				else: BATTLE.apply_intent(state,seat,{"type":"advance_phase"})
static func _main_intent(state: UnifiedBattleState, seat: int) -> Dictionary:
	var p := state.player(seat)
	for id in p.hand:
		var def := RULES.card(str(id)); var kind := str(def.get("type", ""))
		if kind == "upgrade" and int(p.upgrade_plays) == 0: return {"type":"play_card","card_id":str(id)}
		if kind == "filament": return {"type":"play_card","card_id":str(id)}
		var queue_cap: int = 3 + p.installed_upgrades.count("dual_queue") * 2
		if kind == "creature" and p.queue.size() < queue_cap and int(def.filament_cost) <= int(p.filament): return {"type":"play_card","card_id":str(id)}
		if kind == "equipment" and _best_friend(p) >= 0 and int(def.filament_cost) <= int(p.filament): return {"type":"play_card","card_id":str(id),"target":_best_friend(p)}
		if kind == "trap": return {"type":"play_card","card_id":str(id)}
	return {}
static func _attack_intent(state: UnifiedBattleState, seat: int) -> Dictionary:
	var foe := state.player(1-seat); var target := -1
	for index in 3: if foe.slots[index] != null: target = index; break
	for index in 3:
		var unit = state.player(seat).slots[index]
		if unit != null and str(unit.mode) == "attack" and bool(unit.ready) and not bool(unit.attacked): return {"type":"attack","slot":index,"target":target}
	return {}
static func _open(p: Dictionary) -> int:
	for index in 3:
		if p.slots[index] == null: return index
	return -1
static func _best_friend(p: Dictionary) -> int:
	var chosen := -1; var hp := -1
	for index in 3: if p.slots[index] != null and int(p.slots[index].hp) > hp: chosen = index; hp = int(p.slots[index].hp)
	return chosen
