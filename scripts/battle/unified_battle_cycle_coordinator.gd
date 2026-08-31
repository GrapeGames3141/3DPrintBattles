class_name UnifiedBattleCycleCoordinator
extends RefCounted
## Checked, one-intent orchestration around UnifiedBattleRules.  The rules keep
## canonical revision ownership; this class deliberately has no mutation path.

const BATTLE := preload("res://scripts/battle/unified_battle_rules.gd")
const AI := preload("res://scripts/battle/unified_ai_opponent.gd")

var state: UnifiedBattleState
var viewer_seat := 0
var generation := 0
var in_flight := false
var presentation_active := false
var cycle_active := false
var last_error := ""
var transient_focus := -2
var _attack_cursor := 0
var _receipt_serial := 0

func configure(next_state: UnifiedBattleState, next_viewer := 0) -> void:
	invalidate_generation()
	state = next_state
	viewer_seat = next_viewer
	last_error = ""
	transient_focus = -2

func invalidate_generation() -> void:
	generation += 1
	in_flight = false
	presentation_active = false
	cycle_active = false
	_attack_cursor = 0

func public_snapshot() -> Dictionary:
	return {} if state == null else state.public_snapshot(viewer_seat)

## The physical shell must never read the authority directly.  Hot-seat callers
## select the viewer only after the privacy handoff, while AI games always use
## seat zero.  This deliberately returns the same redacted shape as the normal
## public snapshot rather than exposing a second presentation data model.
func public_snapshot_for(next_viewer_seat: int) -> Dictionary:
	return {} if state == null else state.public_snapshot(next_viewer_seat)

func recover(full_snapshot: Dictionary, next_viewer := 0) -> void:
	configure(UnifiedBattleState.from_snapshot(full_snapshot), next_viewer)

func envelope(seat: int, intent: Dictionary) -> Dictionary:
	return {"seat":seat, "expected_revision":int(state.revision) if state != null else -1, "intent":intent.duplicate(true)}

func submit_checked(request: Dictionary, token := -1) -> Dictionary:
	if state == null: return _reject("No battle authority is available.")
	if token >= 0 and token != generation: return _reject("This battle presentation has expired.")
	if in_flight: return _reject("The prior battle action is still resolving.")
	if presentation_active: return _reject("Wait for the current battle presentation.")
	if int(request.get("seat", -1)) != int(state.active_seat): return _reject("It is the other printer's turn.")
	if int(request.get("expected_revision", -1)) != int(state.revision): return _reject("This battle view is out of date.")
	var intent: Dictionary = request.get("intent", {}) if request.get("intent", {}) is Dictionary else {}
	if intent.is_empty(): return _reject("Choose a battle action.")
	var before := state.serialize()
	in_flight = true
	var result: Dictionary = BATTLE.apply_intent(state, int(request.seat), intent)
	in_flight = false
	if not bool(result.get("ok", false)):
		# Rules reject without mutation. Preserve this explicit assertion point for
		# callers/tests rather than fabricating a retry.
		if before != state.serialize(): push_error("Unified rules mutated a rejected intent.")
		return _reject(str(result.get("error", "That action is not legal.")))
	var receipt := _presentation_after(int(request.seat), intent, before, result)
	presentation_active = not receipt.is_empty()
	return {"ok":true, "result":result, "receipt":receipt, "snapshot":public_snapshot(), "revision":int(state.revision), "generation":generation}

func acknowledge_presentation(token: int) -> bool:
	if token != generation: return false
	presentation_active = false
	return true

func enter_plan_if_needed(seat: int) -> Dictionary:
	if state == null or state.finished or seat != state.active_seat or not state.pending.is_empty(): return _reject("Plan entry is not available.")
	if state.phase == "main": return {"ok":true, "snapshot":public_snapshot(), "revision":state.revision}
	if state.phase != "draw": return _reject("Wait for the current cycle to reach Plan.")
	return submit_checked(envelope(seat, {"type":"advance_phase"}), generation)

func start_run_cycle(seat: int) -> Dictionary:
	if state == null or state.finished or seat != state.active_seat or state.phase != "main" or not state.pending.is_empty(): return _reject("Run Cycle is available only during a settled Plan.")
	if cycle_active or in_flight or presentation_active: return _reject("Run Cycle is already resolving.")
	# Every user pull owns a fresh callback generation.  Do not call
	# invalidate_generation() here: transient focus is a Plan-only presentation
	# choice and belongs to the cycle that is just starting.
	generation += 1
	in_flight = false
	presentation_active = false
	cycle_active = true
	_attack_cursor = 0
	var started := advance_run_cycle(seat, generation)
	if not bool(started.get("ok", false)): cycle_active = false
	return started

func advance_run_cycle(seat: int, token: int) -> Dictionary:
	if token != generation: return _reject("This Run Cycle has expired.")
	if state == null: cycle_active = false; return _reject("No battle authority is available.")
	if state.finished:
		cycle_active = false
		transient_focus = -2
		return {"ok":true, "complete":true, "snapshot":public_snapshot(), "revision":int(state.revision), "generation":generation}
	if not state.pending.is_empty(): return {"ok":true, "paused":true, "reason":str(state.pending.get("kind", "decision")), "snapshot":public_snapshot(), "generation":generation}
	if state.phase == "main" or state.phase == "print" or state.phase == "attack":
		if state.phase == "attack":
			var attack := _next_attack(seat)
			if not attack.is_empty(): return _cycle_step(submit_checked(envelope(seat, attack), token))
		return _cycle_step(submit_checked(envelope(seat, {"type":"advance_phase"}), token))
	if state.phase == "collect":
		var hand: Array = state.player(seat).get("hand", [])
		if hand.size() > 8: return {"ok":true, "paused":true, "reason":"overflow", "snapshot":public_snapshot(), "generation":generation}
		return _cycle_step(submit_checked(envelope(seat, {"type":"advance_phase"}), token))
	if state.phase == "draw": cycle_active = false; transient_focus = -2; return {"ok":true, "complete":true, "snapshot":public_snapshot(), "generation":generation}
	cycle_active = false
	return _reject("Unknown battle phase.")

func _cycle_step(result: Dictionary) -> Dictionary:
	# A standard phase/attack rejection cannot safely keep an automated cycle
	# alive. Required decisions intentionally bypass this helper so their owner can
	# correct a choice and retry without losing the pending authority state.
	if not bool(result.get("ok", false)): cycle_active = false
	return result

func submit_required_decision(seat: int, intent: Dictionary, token: int) -> Dictionary:
	if token != generation or state == null: return _reject("That required decision has expired.")
	if str(intent.get("type", "")) == "discard_overflow":
		if state.phase != "collect" or seat != state.active_seat or (state.player(seat).get("hand", []) as Array).size() <= 8: return _reject("Overflow discard is not currently required.")
		return submit_checked(envelope(seat, intent), token)
	if state.pending.is_empty(): return _reject("That required decision has expired.")
	return submit_checked(envelope(seat, intent), token)

func next_ai_intent(seat: int) -> Dictionary:
	return AI.next_legal_intent(state, seat) if state != null else {}

func _next_attack(seat: int) -> Dictionary:
	var foe: Dictionary = state.player(1 - seat)
	var target := -1
	for slot in 3:
		if foe.slots[slot] != null: target = slot; break
	if transient_focus >= 0 and transient_focus < 3 and foe.slots[transient_focus] != null: target = transient_focus
	for slot in range(_attack_cursor, 3):
		_attack_cursor = slot + 1
		var unit = state.player(seat).slots[slot]
		if unit != null and str(unit.get("mode", "")) == "attack" and bool(unit.get("ready", false)) and not bool(unit.get("attacked", false)) and int(unit.get("statuses", {}).get("attack_lock", 0)) <= 0 and not (state.turn == 1 and seat == state.starting_seat):
			return {"type":"attack", "slot":slot, "target":target}
	return {}

func _presentation_after(seat: int, intent: Dictionary, before: Dictionary, result: Dictionary) -> Dictionary:
	var kind := ""
	match str(intent.get("type", "")):
		"attack": kind = "attack"
		"advance_phase": if str(before.get("phase", "")) == "print": kind = "print"
		"place_completed": kind = "deploy"
		"play_card", "activate_ability", "switch_mode": kind = "card"
	if kind.is_empty(): return {}
	_receipt_serial += 1
	var receipt := {"kind":kind, "actor":seat, "source_slot":int(intent.get("slot", -1)), "target_slot":int(intent.get("target", -2)), "generation":generation, "serial":_receipt_serial, "revision":int(state.revision)}
	var before_players: Array = before.get("players", []) if before.get("players", []) is Array else []
	var before_actor: Dictionary = before_players[seat] if seat < before_players.size() and before_players[seat] is Dictionary else {}
	if kind == "attack":
		var source_slot := int(intent.get("slot", -1)); var target_slot := int(intent.get("target", -2))
		var before_foe: Dictionary = before_players[1 - seat] if 1 - seat < before_players.size() and before_players[1 - seat] is Dictionary else {}
		var source = _slot(before_actor, source_slot); var target = _slot(before_foe, target_slot)
		var after_target = state.player(1 - seat).slots[target_slot] if target_slot >= 0 and target_slot < 3 else null
		var before_printer: Dictionary = before_foe.get("printer", {}) if before_foe.get("printer", {}) is Dictionary else {}
		var after_printer: Dictionary = state.player(1 - seat).get("printer", {})
		receipt["source"] = _public_unit(source); receipt["target"] = _public_unit(target); receipt["target_after"] = _public_unit(after_target)
		# Rules own damage semantics, including armor absorption and printer hits.
		receipt["damage"] = int(result.get("damage", 0))
		receipt["armor_before"] = int((target as Dictionary).get("armor_hp", 0)) if target is Dictionary else 0
		receipt["armor_after"] = int((after_target as Dictionary).get("armor_hp", 0)) if after_target is Dictionary else 0
		receipt["defeated"] = target_slot >= 0 and after_target == null; receipt["printer_target"] = target_slot < 0
		receipt["printer_hp_before"] = int(before_printer.get("hp", 0)); receipt["printer_hp_after"] = int(after_printer.get("hp", 0))
	if kind == "print":
		var queue_before: Array = before_actor.get("queue", []) if before_actor.get("queue", []) is Array else []
		var queue_after: Array = state.player(seat).get("queue", [])
		var head_before: Dictionary = queue_before[0] if not queue_before.is_empty() and queue_before[0] is Dictionary else {}
		var head_after: Dictionary = queue_after[0] if not queue_after.is_empty() and queue_after[0] is Dictionary else {}
		var head_id := str(head_before.get("card_id", "")); var same_head := not queue_after.is_empty() and queue_before.size() == queue_after.size() and str(head_after.get("card_id", "")) == head_id and int(head_after.get("remaining", 0)) <= int(head_before.get("remaining", 0))
		var completed_count := maxi(0, queue_before.size() - queue_after.size())
		# Duplicate card ids are common: identity alone cannot tell whether the FIFO
		# head survived. Count loss is authoritative; same-size means progress only.
		receipt["card_id"] = head_id; receipt["remaining_before"] = int(head_before.get("remaining", 0)); receipt["remaining_after"] = int(head_after.get("remaining", 0)) if same_head else 0; receipt["completed"] = completed_count > 0 or (not same_head and queue_before.size() == queue_after.size() and not queue_after.is_empty()); receipt["completed_count"] = completed_count; receipt["pending"] = str(state.pending.get("kind", "")); receipt["queue_count_before"] = queue_before.size(); receipt["queue_count_after"] = queue_after.size()
	if kind == "deploy":
		var pending: Dictionary = before.get("pending", {}) if before.get("pending", {}) is Dictionary else {}
		var target_slot := int(intent.get("slot", -1))
		receipt["card_id"] = str((pending.get("unit", {}) as Dictionary).get("card_id", "")); receipt["target_slot"] = target_slot; receipt["mode"] = str(intent.get("mode", "attack")); receipt["unit"] = _public_unit(state.player(seat).slots[target_slot] if target_slot >= 0 and target_slot < 3 else null)
	return receipt

func _slot(player: Dictionary, slot: int):
	var slots: Array = player.get("slots", []) if player.get("slots", []) is Array else []
	return slots[slot] if slot >= 0 and slot < slots.size() else null

func set_transient_focus(slot: int) -> void:
	transient_focus = slot if slot >= 0 and slot < 3 else -2

func _public_unit(unit) -> Dictionary:
	if not (unit is Dictionary): return {}
	return {"card_id":str((unit as Dictionary).get("card_id", "")), "name":str((unit as Dictionary).get("name", "")), "hp":int((unit as Dictionary).get("hp", 0)), "armor_hp":int((unit as Dictionary).get("armor_hp", 0))}

func _reject(message: String) -> Dictionary:
	last_error = message
	return {"ok":false, "error":message, "snapshot":public_snapshot(), "revision":int(state.revision) if state != null else -1, "generation":generation}
