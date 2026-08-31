class_name UnifiedAIOpponent
extends RefCounted
const RULES := preload("res://scripts/core/unified_rules.gd")
const BATTLE := preload("res://scripts/battle/unified_battle_rules.gd")
## Deterministic, legal intent-only AI. It sees public queues and field state,
## but never opponent hands or face-down trap identities.
static func next_legal_intent(state: UnifiedBattleState, seat: int) -> Dictionary:
	if state == null or state.finished or state.active_seat != seat: return {}
	if not state.pending.is_empty():
		if str(state.pending.get("kind", "")) == "place": return {"type":"place_completed","slot":_open(state.player(seat)),"mode":"attack"}
		if str(state.pending.get("kind", "")) == "attach":
			var held := RULES.card(str(state.pending.get("card_id", "")))
			return {"type":"attach_completed","slot":_best_friend(state.player(seat), str(held.get("equipment_slot", "")))}
		return {}
	match state.phase:
		"draw", "print": return {"type":"advance_phase"}
		"main":
			var main := _main_intent(state, seat)
			return main if not main.is_empty() else {"type":"advance_phase"}
		"attack":
			var attack := _attack_intent(state, seat)
			return attack if not attack.is_empty() else {"type":"advance_phase"}
		"collect":
			var hand: Array = state.player(seat).get("hand", [])
			return {"type":"discard_overflow","card_ids":hand.slice(0, hand.size() - 8)} if hand.size() > 8 else {"type":"advance_phase"}
	return {}
static func take_turn(state: UnifiedBattleState, seat: int) -> Dictionary:
	var safety := 0
	var progressed := false
	# Public-only visual receipts. They are captured before authority mutates an
	# accepted intent, so a destroyed defender can still be shown in the replay.
	# No hand, deck, trap identity, or private choice is included.
	var presentation_trace: Array = []
	while not state.finished and state.active_seat == seat and safety < 32:
		safety += 1
		var intent: Dictionary = {}
		var optional_action := false
		if not state.pending.is_empty():
			if str(state.pending.get("kind", "")) == "place": intent = {"type":"place_completed","slot":_open(state.player(seat)),"mode":"attack"}
			elif str(state.pending.get("kind", "")) == "attach":
				var held_card := RULES.card(str(state.pending.get("card_id", "")))
				intent = {"type":"attach_completed","slot":_best_friend(state.player(seat), str(held_card.get("equipment_slot", "")))}
			else: return _result("stalled", safety, progressed, "Unknown pending print decision.", presentation_trace)
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
				_: return _result("stalled", safety, progressed, "Unknown battle phase.", presentation_trace)
		var presentation := _presentation_before_intent(state, seat, intent)
		var result: Dictionary = BATTLE.apply_intent(state, seat, intent)
		if bool(result.get("ok", false)):
			progressed = true
			if not presentation.is_empty(): presentation_trace.append(presentation)
			continue
		# Playing a card and attacking are optional. A stale or otherwise rejected
		# choice must not consume the entire safety budget; deterministically end the
		# phase instead. Pending decisions and required overflow discards remain a
		# real stall so the caller can surface a recoverable result.
		if optional_action:
			var advance_presentation := _presentation_before_intent(state, seat, {"type":"advance_phase"})
			var advance: Dictionary = BATTLE.apply_intent(state, seat, {"type":"advance_phase"})
			if bool(advance.get("ok", false)):
				progressed = true
				if not advance_presentation.is_empty(): presentation_trace.append(advance_presentation)
				continue
		return _result("stalled", safety, progressed, str(result.get("error", "AI intent was rejected.")), presentation_trace)
	if state.finished or state.active_seat != seat: return _result("complete", safety, progressed, "", presentation_trace)
	return _result("exhausted" if progressed else "stalled", safety, progressed, "AI turn safety budget exhausted." if progressed else "AI made no legal progress.", presentation_trace)

static func _result(status: String, steps: int, progressed: bool, error: String = "", presentation_trace: Array = []) -> Dictionary:
	return {"status":status,"steps":steps,"progressed":progressed,"error":error,"presentation_trace":presentation_trace}

static func _presentation_before_intent(state: UnifiedBattleState, seat: int, intent: Dictionary) -> Dictionary:
	var kind := ""
	var source = null
	var target = null
	match str(intent.get("type", "")):
		"attack":
			kind = "attack"
			var source_slot := int(intent.get("slot", -1))
			var target_slot := int(intent.get("target", -2))
			if source_slot >= 0 and source_slot < 3: source = state.player(seat).slots[source_slot]
			if target_slot >= 0 and target_slot < 3: target = state.player(1 - seat).slots[target_slot]
		"advance_phase":
			if str(state.phase) != "print": return {}
			kind = "print"
			var queue: Array = state.player(seat).get("queue", [])
			if not queue.is_empty():
				var card_id := str((queue[0] as Dictionary).get("card_id", ""))
				if str(RULES.card(card_id).get("type", "")) == "creature": source = {"card_id":card_id}
	if kind.is_empty(): return {}
	return _presentation_pair(state, seat, kind, source, target)

static func _presentation_pair(state: UnifiedBattleState, actor: int, kind: String, source, target) -> Dictionary:
	var left = _first_unit(state.player(0))
	var right = _first_unit(state.player(1))
	if actor == 0:
		if source != null: left = source
		if target != null: right = target
	else:
		if source != null: right = source
		if target != null: left = target
	return {"kind":kind,"actor":actor,"left":_public_stage_unit(left),"right":_public_stage_unit(right)}

static func _first_unit(player: Dictionary):
	for unit in player.get("slots", []):
		if unit != null: return unit
	return null

static func _public_stage_unit(unit) -> Dictionary:
	if not (unit is Dictionary): return {}
	return {"id":str((unit as Dictionary).get("card_id", ""))}
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
