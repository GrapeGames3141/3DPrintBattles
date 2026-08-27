class_name UnifiedAIOpponent
extends RefCounted
const RULES := preload("res://scripts/core/unified_rules.gd")
const BATTLE := preload("res://scripts/battle/unified_battle_rules.gd")
## Deterministic, legal intent-only AI. It sees public queues and field state,
## but never opponent hands or face-down trap identities.
static func take_turn(state: UnifiedBattleState, seat: int) -> Dictionary:
	var safety := 0
	var progressed := false
	while not state.finished and state.active_seat == seat and safety < 32:
		safety += 1
		var intent: Dictionary = {}
		var optional_action := false
		if not state.pending.is_empty():
			if str(state.pending.get("kind", "")) == "place": intent = {"type":"place_completed","slot":_open(state.player(seat)),"mode":"attack"}
			elif str(state.pending.get("kind", "")) == "attach":
				var held_card := RULES.card(str(state.pending.get("card_id", "")))
				intent = {"type":"attach_completed","slot":_best_friend(state.player(seat), str(held_card.get("equipment_slot", "")))}
			else: return _result("stalled", safety, progressed, "Unknown pending print decision.")
		else:
			match state.phase:
				"draw": intent = {"type":"advance_phase"}
				"main":
					intent = _main_intent(state,seat)
					optional_action = not intent.is_empty()
					if intent.is_empty(): intent = {"type":"advance_phase"}
				"print": intent = {"type":"advance_phase"}
				"attack":
					intent = _attack_intent(state,seat)
					optional_action = not intent.is_empty()
					if intent.is_empty(): intent = {"type":"advance_phase"}
				"collect":
					if state.player(seat).hand.size() > 8: intent = {"type":"discard_overflow","card_ids":state.player(seat).hand.slice(0,state.player(seat).hand.size()-8)}
					else: intent = {"type":"advance_phase"}
				_: return _result("stalled", safety, progressed, "Unknown battle phase.")
		var result: Dictionary = BATTLE.apply_intent(state, seat, intent)
		if bool(result.get("ok", false)):
			progressed = true
			continue
		# Playing a card and attacking are optional. A stale or otherwise rejected
		# choice must not consume the entire safety budget; deterministically end the
		# phase instead. Pending decisions and required overflow discards remain a
		# real stall so the caller can surface a recoverable result.
		if optional_action:
			var advance: Dictionary = BATTLE.apply_intent(state, seat, {"type":"advance_phase"})
			if bool(advance.get("ok", false)):
				progressed = true
				continue
		return _result("stalled", safety, progressed, str(result.get("error", "AI intent was rejected.")))
	if state.finished or state.active_seat != seat: return _result("complete", safety, progressed)
	return _result("exhausted" if progressed else "stalled", safety, progressed, "AI turn safety budget exhausted." if progressed else "AI made no legal progress.")

static func _result(status: String, steps: int, progressed: bool, error: String = "") -> Dictionary:
	return {"status":status,"steps":steps,"progressed":progressed,"error":error}
static func _main_intent(state: UnifiedBattleState, seat: int) -> Dictionary:
	var p := state.player(seat)
	for id in p.hand:
		var def := RULES.card(str(id)); var kind := str(def.get("type", ""))
		if kind == "upgrade" and int(p.upgrade_plays) == 0: return {"type":"play_card","card_id":str(id)}
		if kind == "filament": return {"type":"play_card","card_id":str(id)}
		var queue_cap: int = 3 + p.installed_upgrades.count("dual_queue") * 2
		if kind == "creature" and p.queue.size() < queue_cap and int(def.filament_cost) <= int(p.filament): return {"type":"play_card","card_id":str(id)}
		var equipment_slot := str(def.get("equipment_slot", ""))
		if kind == "equipment" and equipment_slot == "battle_effect" and not bool(p.get(BATTLE.battle_effect_key(def), false)) and int(def.filament_cost) <= int(p.filament): return {"type":"play_card","card_id":str(id)}
		if kind == "equipment" and equipment_slot != "battle_effect" and int(def.filament_cost) <= int(p.filament):
			# Prefer an empty matching slot so the print attaches immediately. If every
			# matching slot is occupied, keep the former holding behavior by targeting
			# the best existing companion; the rules will retain it for a later attach.
			var target := _best_friend(p, equipment_slot)
			if target < 0: target = _best_friend(p)
			if target >= 0: return {"type":"play_card","card_id":str(id),"target":target}
		if kind == "trap": return {"type":"play_card","card_id":str(id)}
	return {}
static func _attack_intent(state: UnifiedBattleState, seat: int) -> Dictionary:
	if state.turn == 1 and seat == state.starting_seat: return {}
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
static func _best_friend(p: Dictionary, equipment_slot: String = "") -> int:
	var chosen := -1; var hp := -1
	for index in 3:
		if p.slots[index] == null: continue
		if not equipment_slot.is_empty() and not (p.slots[index].get("equipment", {}).get(equipment_slot, {}) as Dictionary).is_empty(): continue
		if int(p.slots[index].hp) > hp: chosen = index; hp = int(p.slots[index].hp)
	return chosen
