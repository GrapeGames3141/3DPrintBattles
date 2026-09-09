class_name UnifiedBattleCycleCoordinator
extends RefCounted
## Checked, one-intent orchestration around UnifiedBattleRules.  The rules keep
## canonical revision ownership; this class deliberately has no mutation path.

const BATTLE := preload("res://scripts/battle/unified_battle_rules.gd")
const AI := preload("res://scripts/battle/unified_ai_opponent.gd")
const RULES := preload("res://scripts/core/unified_rules.gd")

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

func recover(full_snapshot: Dictionary, next_viewer := 0) -> Dictionary:
	## Recovery is transactional: an invalid snapshot leaves the configured live
	## authority untouched so callers can offer a safe resume error instead.
	var recovery := UnifiedBattleState.recover_snapshot(full_snapshot)
	if not bool(recovery.get("ok", false)): return {"ok":false, "error":str(recovery.get("error", "Battle recovery failed."))}
	var restored := UnifiedBattleState.from_snapshot(full_snapshot)
	if restored == null: return {"ok":false, "error":"Battle recovery failed."}
	configure(restored, next_viewer)
	return {"ok":true, "adapted":bool(recovery.get("adapted", false)), "snapshot":public_snapshot()}

func public_next_cycle_forecast() -> Dictionary:
	## Read-only public guidance. It never substitutes for a checked intent and
	## intentionally exposes only already-public queues/fields, never hand, deck,
	## or a face-down trap identity.
	if state == null: return {"available":false, "reason":"No battle authority is available."}
	if in_flight or presentation_active or cycle_active: return {"available":false, "reason":"Forecast waits for the current cycle receipt.", "revision":int(state.revision)}
	if state.finished or not state.pending.is_empty() or state.phase != "main": return {"available":false, "reason":"Forecast is available during a settled Plan.", "revision":int(state.revision)}
	var actor := int(state.active_seat)
	var print_heads: Array = []
	var completions: Array = []
	var player := state.player(actor)
	var queue: Array = player.get("queue", []) if player.get("queue", []) is Array else []
	var print_paused := int(player.get("queue_paused", 0)) > 0
	if not queue.is_empty():
		var head: Dictionary = queue[0] if queue[0] is Dictionary else {}
		print_heads.append({"seat":actor, "job_id":str(head.get("job_id", "")), "card_id":str(head.get("card_id", "")), "remaining":int(head.get("remaining", 0))})
		var work := 0 if print_paused else BATTLE.print_speed(player)
		for item in queue:
			if not item is Dictionary or work <= 0: break
			var remaining := int(item.get("remaining", 0))
			if remaining > work: break
			work -= remaining
			completions.append({"seat":actor, "job_id":str(item.get("job_id", "")), "card_id":str(item.get("card_id", ""))})
	# Forecast exactly the public queue plus the public field.  Complete every
	# known creature within the available work budget and seat it in the same
	# leftmost anchor order as authority, then derive the visible Attack order.
	var forecast_slots: Array = state.player(actor).get("slots", []).duplicate(true)
	for completion in completions:
		var card := RULES.card(str((completion as Dictionary).get("card_id", "")))
		if str(card.get("type", "")) != "creature": continue
		var forecast_slot := _first_open_slot({"slots":forecast_slots})
		if forecast_slot >= 0:
			var queued_job: Dictionary = {}
			for item in queue:
				if item is Dictionary and str((item as Dictionary).get("job_id", "")) == str((completion as Dictionary).get("job_id", "")):
					queued_job = item
					break
			forecast_slots[forecast_slot] = {"card_id":str(card.get("id", "")), "job_id":str((completion as Dictionary).get("job_id", "")), "mode":str(queued_job.get("mode", "attack")), "ready":true, "attacked":false, "statuses":{}, "after_deploy":true}
	var attacks: Array = []
	for slot in 3:
		var unit = forecast_slots[slot]
		if unit == null or str(unit.get("mode", "")) != "attack" or not bool(unit.get("ready", false)) or bool(unit.get("attacked", false)) or int(unit.get("statuses", {}).get("attack_lock", 0)) > 0 or state.turn == 1 and actor == state.starting_seat: continue
		var forecast := {"slot":slot, "card_id":str(unit.get("card_id", ""))}
		if bool(unit.get("after_deploy", false)):
			forecast["job_id"] = str(unit.get("job_id", ""))
			forecast["after_deploy"] = true
		attacks.append(forecast)
	var focus_priority := transient_focus if transient_focus >= 0 and transient_focus < 3 and state.player(1 - actor).slots[transient_focus] != null else -1
	return {"available":true, "revision":int(state.revision), "actor":actor, "print_heads":print_heads, "expected_completions":completions, "print_paused":print_paused, "friendly_attack_order":attacks, "target_priority":"focus defender" if focus_priority >= 0 else "leftmost defender, then printer", "focus_slot":focus_priority, "hidden_interrupt_possible":not state.player(1 - actor).get("trap", {}).is_empty(), "qualification":"Expected only; a hidden interrupt may alter a known action."}

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
	var before_players: Array = before.get("players", []) if before.get("players", []) is Array else []
	var before_actor: Dictionary = before_players[seat] if seat < before_players.size() and before_players[seat] is Dictionary else {}
	var kind := ""
	match str(intent.get("type", "")):
		"attack": kind = "attack"
		"advance_phase": if str(before.get("phase", "")) == "print": kind = "print"
		"place_completed": kind = "deploy"
		"play_card", "activate_ability", "switch_mode": kind = "card"
	var deployments := _deployment_events(before)
	var produces_print_work := (str(intent.get("type", "")) == "advance_phase" and str(before.get("phase", "")) == "print") or str(intent.get("type", "")) == "attach_completed" or (str(intent.get("type", "")) == "play_card" and str(intent.get("card_id", "")) == "heated_spool")
	var print_events := _print_events(seat, before_actor) if produces_print_work else []
	if kind.is_empty() and deployments.is_empty() and print_events.is_empty(): return {}
	if str(intent.get("type", "")) == "attach_completed" and not print_events.is_empty(): kind = "fitting"
	if kind.is_empty(): kind = "deploy"
	_receipt_serial += 1
	# print_events own chamber work. deployments own field arrival. They share a
	# job_id but never duplicate a "deployed" event, so presentation has one
	# awakening/walk owner for every completed creature.
	var receipt := {"kind":kind, "actor":seat, "source_slot":int(intent.get("slot", -1)), "target_slot":int(intent.get("target", -2)), "generation":generation, "serial":_receipt_serial, "revision":int(state.revision), "print_events":print_events, "deployments":deployments}
	if kind == "attack":
		var source_slot := int(intent.get("slot", -1)); var target_slot := int(intent.get("target", -2))
		var before_foe: Dictionary = before_players[1 - seat] if 1 - seat < before_players.size() and before_players[1 - seat] is Dictionary else {}
		var source = _slot(before_actor, source_slot); var target = _slot(before_foe, target_slot)
		var after_target = state.player(1 - seat).slots[target_slot] if target_slot >= 0 and target_slot < 3 else null
		var target_survived := _same_unit_identity(target, after_target)
		var before_printer: Dictionary = before_foe.get("printer", {}) if before_foe.get("printer", {}) is Dictionary else {}
		var after_printer: Dictionary = state.player(1 - seat).get("printer", {})
		receipt["source"] = _public_unit(source); receipt["target"] = _public_unit(target); receipt["target_after"] = _public_unit(after_target) if target_survived else {}; receipt["replacement"] = _public_unit(after_target) if target_slot >= 0 and not target_survived else {}
		# Rules own damage semantics, including armor absorption and printer hits.
		receipt["damage"] = int(result.get("damage", 0))
		receipt["armor_before"] = int((target as Dictionary).get("armor_hp", 0)) if target is Dictionary else 0
		receipt["armor_after"] = int((after_target as Dictionary).get("armor_hp", 0)) if target_survived and after_target is Dictionary else 0
		receipt["defeated"] = target_slot >= 0 and target is Dictionary and not target_survived; receipt["printer_target"] = target_slot < 0
		receipt["printer_hp_before"] = int(before_printer.get("hp", 0)); receipt["printer_hp_after"] = int(after_printer.get("hp", 0))
	if kind == "deploy":
		var pending: Dictionary = before.get("pending", {}) if before.get("pending", {}) is Dictionary else {}
		var target_slot := int(intent.get("slot", -1))
		receipt["card_id"] = str((pending.get("unit", {}) as Dictionary).get("card_id", "")); receipt["target_slot"] = target_slot; receipt["mode"] = str(intent.get("mode", "attack")); receipt["unit"] = _public_unit(state.player(seat).slots[target_slot] if target_slot >= 0 and target_slot < 3 else null)
	return receipt

func _slot(player: Dictionary, slot: int):
	var slots: Array = player.get("slots", []) if player.get("slots", []) is Array else []
	return slots[slot] if slot >= 0 and slot < slots.size() else null

func _first_open_slot(player: Dictionary) -> int:
	for slot in 3:
		if _slot(player, slot) == null: return slot
	return -1

func _same_unit_identity(before_unit, after_unit) -> bool:
	if not (before_unit is Dictionary) or not (after_unit is Dictionary): return false
	var before_job_id := str((before_unit as Dictionary).get("job_id", ""))
	var after_job_id := str((after_unit as Dictionary).get("job_id", ""))
	if not before_job_id.is_empty() or not after_job_id.is_empty(): return before_job_id == after_job_id and not before_job_id.is_empty()
	return str((before_unit as Dictionary).get("card_id", "")) == str((after_unit as Dictionary).get("card_id", ""))

func set_transient_focus(slot: int) -> void:
	transient_focus = slot if slot >= 0 and slot < 3 else -2

func _public_unit(unit) -> Dictionary:
	if not (unit is Dictionary): return {}
	return {"card_id":str((unit as Dictionary).get("card_id", "")), "job_id":str((unit as Dictionary).get("job_id", "")), "name":str((unit as Dictionary).get("name", "")), "hp":int((unit as Dictionary).get("hp", 0)), "armor_hp":int((unit as Dictionary).get("armor_hp", 0))}

func _print_events(seat: int, before_actor: Dictionary) -> Array:
	var queue_before: Array = before_actor.get("queue", []) if before_actor.get("queue", []) is Array else []
	var queue_after: Array = state.player(seat).get("queue", []) if state.player(seat).get("queue", []) is Array else []
	var after_jobs := {}
	for item in queue_after:
		if item is Dictionary: after_jobs[str((item as Dictionary).get("job_id", ""))] = item
	var events: Array = []
	for item in queue_before:
		if not (item is Dictionary): continue
		var job: Dictionary = item
		var job_id := str(job.get("job_id", ""))
		var card_id := str(job.get("card_id", ""))
		var total_work := int(RULES.card(card_id).get("print_turns", 1))
		if after_jobs.has(job_id):
			var after_job: Dictionary = after_jobs[job_id]
			if int(after_job.get("remaining", 0)) < int(job.get("remaining", 0)): events.append({"event":"partial", "seat":seat, "job_id":job_id, "card_id":card_id, "remaining_before":int(job.get("remaining", 0)), "remaining_after":int(after_job.get("remaining", 0)), "total_work":total_work})
		else:
			events.append(_print_completion_event(seat, job, before_actor, total_work))
	return events

func _print_completion_event(seat: int, job: Dictionary, before_actor: Dictionary, total_work: int) -> Dictionary:
	var card_id := str(job.get("card_id", ""))
	var event := {"event":"complete", "seat":seat, "job_id":str(job.get("job_id", "")), "card_id":card_id, "remaining_before":int(job.get("remaining", 0)), "remaining_after":0, "total_work":total_work}
	var card := RULES.card(card_id)
	if str(card.get("type", "")) == "equipment":
		for held in state.player(seat).get("holding", []):
			if held is Dictionary and str((held as Dictionary).get("job_id", "")) == str(job.get("job_id", "")):
				event["event"] = "fitting" if str(state.pending.get("kind", "")) == "attach" else "held"
				return event
	# Cards may share an ID. Only the stable job identity can tell whether this
	# exact work item reached field/staging/holding or was consumed by an interrupt.
	if not _job_visible_after(seat, str(job.get("job_id", ""))): event["event"] = "interrupted"
	return event

func _job_visible_after(seat: int, job_id: String) -> bool:
	if job_id.is_empty(): return false
	var player := state.player(seat)
	for unit in player.get("slots", []):
		if unit is Dictionary and str((unit as Dictionary).get("job_id", "")) == job_id: return true
	for staged in player.get("staging", []):
		if not (staged is Dictionary): continue
		var staged_unit = (staged as Dictionary).get("unit", staged)
		if staged_unit is Dictionary and str((staged_unit as Dictionary).get("job_id", (staged as Dictionary).get("job_id", ""))) == job_id: return true
	for held in player.get("holding", []):
		if held is Dictionary and str((held as Dictionary).get("job_id", "")) == job_id: return true
	return false

func _deployment_events(before: Dictionary) -> Array:
	var events: Array = []
	var before_players: Array = before.get("players", []) if before.get("players", []) is Array else []
	for seat in 2:
		var before_player: Dictionary = before_players[seat] if seat < before_players.size() and before_players[seat] is Dictionary else {}
		var known_jobs := {}
		for unit in before_player.get("slots", []):
			if unit is Dictionary and not str((unit as Dictionary).get("job_id", "")).is_empty(): known_jobs[str((unit as Dictionary).get("job_id", ""))] = true
		for slot in 3:
			var unit = state.player(seat).slots[slot]
			if unit == null: continue
			var job_id := str(unit.get("job_id", ""))
			if not job_id.is_empty() and not known_jobs.has(job_id): events.append({"event":"deployed", "seat":seat, "job_id":job_id, "card_id":str(unit.get("card_id", "")), "slot":slot})
	return events

func _reject(message: String) -> Dictionary:
	last_error = message
	return {"ok":false, "error":message, "snapshot":public_snapshot(), "revision":int(state.revision) if state != null else -1, "generation":generation}
