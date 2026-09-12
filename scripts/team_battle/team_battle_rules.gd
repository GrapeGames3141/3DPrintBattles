class_name TeamBattleRules
extends RefCounted

## Deterministic M1 authority.  This module has no persistence, UI callback, RNG,
## or catalog side effect: callers receive either an unchanged failure or a checked
## next State plus an internal presentation receipt.

const Data := preload("res://scripts/team_battle/team_battle_data.gd")
const State := preload("res://scripts/team_battle/team_battle_state.gd")
const BattleProjection := preload("res://scripts/team_battle/team_battle_projection.gd")

const PLAN_KEYS := [
	"expected_revision",
	"fabrication_id",
	"support_copy_id",
	"equipment_target_id",
	"swap_id",
]
const VIEW_KEYS := [
	"view_schema",
	"viewer",
	"cycle",
	"revision",
	"result",
	"roster_count",
	"filament_cap",
	"own",
	"opponent",
]
const SEAT_ORDER := ["player", "rival"]


static func validate_plan(state: Variant, seat_id: String, plan: Variant, test_1v1: bool = false) -> Dictionary:
	var opening_result := _restore_opening(state, test_1v1)
	if not bool(opening_result.get("ok", false)):
		return opening_result
	var opening: Dictionary = opening_result.state
	if not str(opening.result).is_empty():
		return _failure("Battle is already settled.")
	if seat_id not in SEAT_ORDER:
		return _failure("Plan seat is invalid.")
	var seat: Dictionary = opening.seats[seat_id]
	return _validate_plan_for_seat(seat, seat_id, int(opening.cycle), int(opening.revision), int(opening.filament_cap), plan)


static func run_cycle(state: Variant, player_plan: Variant, rival_plan: Variant, test_1v1: bool = false) -> Dictionary:
	var opening_result := _restore_opening(state, test_1v1)
	if not bool(opening_result.get("ok", false)):
		return opening_result
	var opening: Dictionary = opening_result.state
	if not str(opening.result).is_empty():
		return _failure("Battle is already settled.")

	var player_checked := _validate_plan_for_seat(
		opening.seats.player,
		"player",
		int(opening.cycle),
		int(opening.revision),
		int(opening.filament_cap),
		player_plan
	)
	if not bool(player_checked.get("ok", false)):
		return player_checked
	var rival_checked := _validate_plan_for_seat(
		opening.seats.rival,
		"rival",
		int(opening.cycle),
		int(opening.revision),
		int(opening.filament_cap),
		rival_plan
	)
	if not bool(rival_checked.get("ok", false)):
		return rival_checked

	var candidate: Dictionary = State.deep_clone(opening)
	var receipt := {
		"receipt_schema": 1,
		"cycle": int(opening.cycle),
		"opening_revision": int(opening.revision),
		"final_revision": -1,
		"opening_state": State.deep_clone(opening),
		"stages": [],
		"final_state": {},
	}
	var surge_seats := {"player": false, "rival": false}
	var queue_events := []
	for seat_id in SEAT_ORDER:
		var checked: Dictionary = player_checked if seat_id == "player" else rival_checked
		var commit_error := _commit_plan(candidate, seat_id, checked.normalized, surge_seats, queue_events)
		if not commit_error.is_empty():
			return _failure("Atomic commit failed: %s" % commit_error)
	_stage(receipt, "Queue", queue_events, candidate)

	var print_events := _describe_head_work(candidate)
	_stage(receipt, "Print", print_events, candidate)
	var awaken_events := _advance_one_work(candidate)
	_stage(receipt, "Awaken", awaken_events, candidate)
	var enter_fit_events := _complete_work(candidate)
	_stage(receipt, "Enter/Fit", enter_fit_events, candidate)

	var swap_events := _resolve_swaps(candidate, player_checked.normalized, rival_checked.normalized)
	_stage(receipt, "Swap", swap_events, candidate)
	var spell_events := _resolve_spells(candidate, player_checked.normalized, rival_checked.normalized)
	_stage(receipt, "Spell", spell_events, candidate)
	var lock_events := _lock_attacks(candidate, surge_seats)
	_stage(receipt, "AttackLock", lock_events.events, candidate)
	var damage_events := _apply_damage(candidate, lock_events.locks)
	_stage(receipt, "Damage", damage_events, candidate)
	var trait_events := _resolve_traits(candidate, lock_events.locks)
	_stage(receipt, "Traits", trait_events, candidate)
	var defeat_events := _mark_defeats(candidate)
	_stage(receipt, "Defeat", defeat_events, candidate)
	var replace_events := _replace_ready_members(candidate)
	_stage(receipt, "Replace", replace_events, candidate)

	var terminal_events := _settle_result(candidate)
	if str(candidate.result).is_empty():
		_stage(receipt, "Result", terminal_events, candidate)
		var plan_events := []
		_open_next_plan(candidate, plan_events)
		_stage(receipt, "Plan", plan_events, candidate)
	else:
		_finalize_terminal(candidate)
		_stage(receipt, "Result", terminal_events, candidate)

	var restored_candidate := _restore_opening(candidate, test_1v1)
	if not bool(restored_candidate.get("ok", false)):
		return _failure("Resolved State failed validation: %s" % str(restored_candidate.get("error", "unknown error")))
	var settled: Dictionary = restored_candidate.state
	receipt.final_revision = int(settled.revision)
	receipt.final_state = State.deep_clone(settled)
	return {"ok": true, "state": settled, "receipt": receipt}


static func view_for_seat(state: Variant, seat_id: String, test_1v1: bool = false) -> Dictionary:
	var restored := _restore_opening(state, test_1v1)
	if not bool(restored.get("ok", false)):
		return restored
	if seat_id not in SEAT_ORDER:
		return _failure("View seat is invalid.")
	return BattleProjection.project_state(restored.state, seat_id)


static func check_view_plan(view: Variant, plan: Variant) -> Dictionary:
	var view_result := _validate_private_view(view)
	if not bool(view_result.get("ok", false)):
		return view_result
	var checked_view: Dictionary = view_result.view
	return _validate_plan_for_seat(
		checked_view.own,
		str(checked_view.viewer),
		int(checked_view.cycle),
		int(checked_view.revision),
		int(checked_view.filament_cap),
		plan
	)


static func eligible_equipment_targets(view: Variant, card_id: String, fabrication_id: String = "") -> Array:
	var view_result := _validate_private_view(view)
	if not bool(view_result.get("ok", false)):
		return []
	if not Data.is_support_eligible(card_id) or card_id not in ["standard_full_suit", "iron_gem"]:
		return []
	var checked_view: Dictionary = view_result.view
	return _eligible_targets_for_seat(checked_view.own, fabrication_id)


static func project_receipt(receipt: Variant, seat_id: String) -> Dictionary:
	if not receipt is Dictionary or seat_id not in SEAT_ORDER:
		return _failure("Receipt projection input is invalid.")
	if not _has_exact_keys(receipt, ["receipt_schema", "cycle", "opening_revision", "final_revision", "opening_state", "stages", "final_state"]):
		return _failure("Receipt schema is invalid.")
	if not _is_strict_integer(receipt.receipt_schema) or int(receipt.receipt_schema) != 1:
		return _failure("Receipt schema version is invalid.")
	if not receipt.has("opening_state") or not receipt.opening_state is Dictionary:
		return _failure("Receipt opening state is missing.")
	if not receipt.has("stages") or not receipt.stages is Array:
		return _failure("Receipt stages are missing.")
	var projected_stages := []
	for stage_value in receipt.stages:
		if not stage_value is Dictionary:
			return _failure("Receipt stage is invalid.")
		var stage: Dictionary = stage_value
		if not stage.has("name") or not stage.name is String or not stage.name in ["Queue", "Print", "Awaken", "Enter/Fit", "Swap", "Spell", "AttackLock", "Damage", "Traits", "Defeat", "Replace", "Result", "Plan"] or not stage.has("events") or not stage.events is Array or not stage.has("snapshot") or not stage.snapshot is Dictionary:
			return _failure("Receipt stage shape is invalid.")
		if not _has_exact_keys(stage, ["name", "events", "snapshot"]):
			return _failure("Receipt stage has an unknown field.")
		var events_result := BattleProjection.project_events(stage.events)
		if not bool(events_result.get("ok", false)):
			return events_result
		var snapshot_result := BattleProjection.project_state(stage.snapshot, seat_id)
		if not bool(snapshot_result.get("ok", false)):
			return snapshot_result
		projected_stages.append({
			"name": stage.name,
			"events": events_result.events,
			"snapshot": snapshot_result.view,
		})
	var opening_result := BattleProjection.project_state(receipt.opening_state, seat_id)
	if not bool(opening_result.get("ok", false)):
		return opening_result
	var final_result := BattleProjection.project_state(receipt.get("final_state", {}), seat_id)
	if not bool(final_result.get("ok", false)):
		return final_result
	for key in ["cycle", "opening_revision", "final_revision"]:
		if not _is_strict_integer(receipt.get(key, -1)):
			return _failure("Receipt scalar %s is invalid." % key)
	return {
		"ok": true,
		"receipt": {
			"receipt_schema": 1,
			"cycle": receipt.get("cycle", -1),
			"opening_revision": receipt.get("opening_revision", -1),
			"final_revision": receipt.get("final_revision", -1),
			"opening": opening_result.view,
			"stages": projected_stages,
			"final": final_result.view,
		},
	}


static func _restore_opening(state: Variant, test_1v1: bool) -> Dictionary:
	if test_1v1:
		return State.restore_test_1v1(state)
	return State.restore(state)


static func _stage(receipt: Dictionary, name: String, events: Array, snapshot: Dictionary) -> void:
	receipt.stages.append({
		"name": name,
		"events": events.duplicate(true),
		"snapshot": State.deep_clone(snapshot),
	})


static func _validate_private_view(view_value: Variant) -> Dictionary:
	if not view_value is Dictionary or not _has_exact_keys(view_value, VIEW_KEYS):
		return _failure("View schema is invalid.")
	var view: Dictionary = view_value
	if not _is_strict_integer(view.view_schema) or int(view.view_schema) != 1:
		return _failure("View schema version is invalid.")
	if not view.viewer is String or view.viewer not in SEAT_ORDER:
		return _failure("View viewer is invalid.")
	if not view.result is String or not str(view.result).is_empty():
		return _failure("View is already settled.")
	if not _is_strict_integer(view.roster_count) or int(view.roster_count) not in [1, 3]:
		return _failure("View roster count is invalid.")
	if not _is_strict_integer(view.cycle) or int(view.cycle) < 1 or not _is_strict_integer(view.revision) or int(view.revision) < 0:
		return _failure("View cycle or revision is invalid.")
	if int(view.cycle) != int(view.revision) + 1:
		return _failure("View cycle and revision are inconsistent.")
	if not _is_strict_integer(view.filament_cap) or int(view.filament_cap) != Data.FILAMENT_CAP:
		return _failure("View filament cap is invalid.")
	if not view.own is Dictionary or not view.opponent is Dictionary:
		return _failure("View seats are invalid.")
	if str(view.own.get("seat_id", "")) != str(view.viewer):
		return _failure("View own seat does not match its viewer.")
	var private_seat := State.validate_private_seat(view.own, str(view.viewer), view.roster_count, view.revision)
	if not bool(private_seat.get("ok", false)):
		return private_seat
	var opponent_id := "rival" if str(view.viewer) == "player" else "player"
	var opponent_public := BattleProjection.validate_opponent_public(view.opponent, opponent_id, int(view.roster_count), int(view.revision))
	if not bool(opponent_public.get("ok", false)):
		return opponent_public
	return {"ok": true, "view": view}


static func _validate_plan_for_seat(seat: Dictionary, seat_id: String, cycle: int, revision: int, filament_cap: int, plan_value: Variant) -> Dictionary:
	var parsed := _parse_plan(plan_value, revision)
	if not bool(parsed.get("ok", false)):
		return parsed
	var plan: Dictionary = parsed.plan
	var fabrication_id := str(plan.fabrication_id)
	var support_copy_id := str(plan.support_copy_id)
	var equipment_target_id := str(plan.equipment_target_id)
	var swap_id := str(plan.swap_id)
	var has_support := not support_copy_id.is_empty()
	var has_swap := not swap_id.is_empty()
	var has_explicit_fabrication := not fabrication_id.is_empty()
	if has_support and has_swap:
		return _failure("Support and swap cannot be combined.")
	if not has_support and not equipment_target_id.is_empty():
		return _failure("Equipment target requires an equipment Support copy.")

	var support_copy := {}
	var support_card_id := ""
	var support_definition := {}
	if has_support:
		support_copy = _copy_by_id(seat.hand, support_copy_id)
		if support_copy.is_empty():
			return _failure("Selected Support copy is not in the visible hand.")
		support_card_id = str(support_copy.card_id)
		support_definition = Data.support_definition(support_card_id)
		if support_definition.is_empty():
			return _failure("Selected Support card is not eligible.")
	if not has_support and not equipment_target_id.is_empty():
		return _failure("Equipment target cannot be supplied without equipment.")

	var selected_fabrication := fabrication_id
	var default_reason := ""
	var default_candidate := ""
	var requires_default := _field_is_empty(seat)
	if has_explicit_fabrication:
		if not _is_unspent_member(seat, fabrication_id):
			return _failure("Selected fabrication must be an Unspent roster identity.")
	elif requires_default:
		default_candidate = _highest_priority_with_status(seat, State.STATUS_UNSPENT)
		if not default_candidate.is_empty():
			selected_fabrication = default_candidate
			default_reason = "required_empty_field_default"

	if has_swap:
		if str(seat.active_member_id).is_empty() or not _is_ready_member(seat, swap_id):
			return _failure("Swap must select a living Ready reserve while an Active companion exists.")
	if not has_swap and not swap_id.is_empty():
		return _failure("Swap selection is invalid.")

	var aid_gain := 0
	var support_cost := 0
	var support_work := 0
	var support_effect := 0
	var equipment_job := false
	if has_support:
		aid_gain = int(support_definition.get("aid", 0))
		support_cost = int(support_definition.get("cost", 0))
		support_work = int(support_definition.get("work", 0))
		support_effect = int(support_definition.get("effect", 0))
		equipment_job = str(support_definition.get("kind", "")) in ["armor", "gem"]
		if equipment_job:
			if equipment_target_id.is_empty():
				return _failure("Equipment Support requires a locked target.")
			var eligible_targets := _eligible_targets_for_seat(seat, selected_fabrication)
			if equipment_target_id not in eligible_targets:
				return _failure("Equipment target is not Active, Ready, Printing, or same-Plan fabrication.")
		elif not equipment_target_id.is_empty():
			return _failure("Only Suit and Gem accept an equipment target.")

	var fabrication_cost: int = Data.FABRICATION_COST if not selected_fabrication.is_empty() else 0
	var job_count: int = (1 if not selected_fabrication.is_empty() else 0) + (1 if equipment_job else 0)
	var opening_filament: int = int(seat.filament)
	var available_filament: int = min(filament_cap, opening_filament + aid_gain)
	var total_cost: int = fabrication_cost + support_cost
	var capacity_ok: bool = seat.fifo.size() + job_count <= Data.FIFO_CAPACITY
	var resource_ok: bool = total_cost <= available_filament
	var no_choice: bool = not has_explicit_fabrication and not has_support and equipment_target_id.is_empty() and not has_swap
	if not capacity_ok or not resource_ok:
		if not default_candidate.is_empty() and no_choice:
			selected_fabrication = ""
			job_count = 0
			fabrication_cost = 0
			total_cost = 0
			default_reason = "default_capacity_blocked" if not capacity_ok else "default_need_filament"
		else:
			return _failure("Complete Plan is blocked by %s." % ("FIFO capacity" if not capacity_ok else "filament"))

	var new_jobs := []
	if not selected_fabrication.is_empty():
		new_jobs.append({
			"kind": "companion",
			"member_identity_id": selected_fabrication,
			"target_identity_id": "",
			"destination_state": "Active" if str(seat.active_member_id).is_empty() else "Ready",
		})
	if equipment_job:
		var forecast_target := _member_by_identity(seat, equipment_target_id)
		new_jobs.append({
			"kind": "equipment",
			"member_identity_id": "",
			"target_identity_id": equipment_target_id,
			"card_id": support_card_id,
			"destination_state": "Fizzle" if forecast_target.is_empty() or str(forecast_target.status) == State.STATUS_DEFEATED else "Fit",
		})
	var head_before := {}
	if not seat.fifo.is_empty():
		var existing_head := _head_forecast(seat, seat.fifo[0])
		if not existing_head.is_empty():
			head_before = existing_head.head_before.duplicate(true)
			head_before["destination_state"] = existing_head.destination_state
	var one_work_completion: Dictionary = head_before.duplicate(true)
	if one_work_completion.is_empty() and not new_jobs.is_empty():
		one_work_completion = new_jobs[0].duplicate(true)
	var normalized := {
		"expected_revision": revision,
		"fabrication_id": selected_fabrication,
		"support_copy_id": support_copy_id,
		"support_card_id": support_card_id,
		"equipment_target_id": equipment_target_id,
		"swap_id": swap_id,
		"default_fabrication": not default_candidate.is_empty(),
		"default_reason": default_reason,
		"total_cost": total_cost,
		"aid_gain": aid_gain,
		"support_work": support_work,
		"support_effect": support_effect,
		"equipment_job": equipment_job,
	}
	var forecast := {
		"opening_filament": opening_filament,
		"aid_gain": aid_gain,
		"available_filament": available_filament,
		"complete_cost": total_cost,
		"post_spend_filament": available_filament - total_cost,
		"next_regeneration": min(filament_cap, available_filament - total_cost + Data.FILAMENT_REGEN),
		"new_jobs": new_jobs,
		"head_before": head_before,
		"one_work_completion": one_work_completion,
		"default_fabrication_reason": default_reason,
		"equipment_target_id": equipment_target_id,
		"swap_id": swap_id,
		"hidden_rival_choice_uncertainty": true,
	}
	var public_plan := {
		"expected_revision": revision,
		"fabrication_id": selected_fabrication,
		"support_copy_id": support_copy_id,
		"equipment_target_id": equipment_target_id,
		"swap_id": swap_id,
	}
	return {"ok": true, "plan": public_plan, "normalized": normalized, "forecast": forecast}


static func _parse_plan(plan_value: Variant, revision: int) -> Dictionary:
	if not plan_value is Dictionary:
		return _failure("Plan must be a dictionary.")
	var plan: Dictionary = plan_value
	for key in plan.keys():
		if key not in PLAN_KEYS:
			return _failure("Plan has an unknown key: %s" % str(key))
	if not plan.has("expected_revision") or not _is_strict_integer(plan.expected_revision):
		return _failure("Plan expected_revision must be an integer.")
	if int(plan.expected_revision) != revision:
		return _failure("Plan expected_revision is stale.")
	var normalized := {"expected_revision": revision}
	for key in ["fabrication_id", "support_copy_id", "equipment_target_id", "swap_id"]:
		var value: Variant = plan.get(key, "")
		if not value is String:
			return _failure("Plan %s must be a string." % key)
		normalized[key] = value
	return {"ok": true, "plan": normalized}


static func _commit_plan(state: Dictionary, seat_id: String, normalized: Dictionary, surge_seats: Dictionary, events: Array) -> String:
	var seat: Dictionary = state.seats[seat_id]
	var support_copy_id := str(normalized.support_copy_id)
	var support_card_id := str(normalized.support_card_id)
	var selected_copy := {}
	if not support_copy_id.is_empty():
		selected_copy = _remove_copy(seat.hand, support_copy_id)
		if selected_copy.is_empty():
			return "Support copy disappeared before commit."
	var available_filament: int = min(int(state.filament_cap), int(seat.filament) + int(normalized.aid_gain))
	seat.filament = available_filament - int(normalized.total_cost)
	if not selected_copy.is_empty():
		if bool(normalized.equipment_job):
			pass
		else:
			seat.discard.append(selected_copy)
			if support_card_id == "forge_surge":
				surge_seats[seat_id] = true
			var event_type: String = "printer_aid" if support_card_id in ["raw_filament", "heated_spool"] else "support_played"
			events.append({"type": event_type, "seat": seat_id, "card_id": support_card_id, "gain": int(normalized.aid_gain)})

	var selected_fabrication := str(normalized.fabrication_id)
	if not selected_fabrication.is_empty():
		var companion_job := {
			"job_id": "%s:job:%d:companion" % [seat_id, int(state.cycle)],
			"kind": "companion",
			"created_cycle": int(state.cycle),
		"work_total": 1,
		"work_remaining": 1,
			"member_identity_id": selected_fabrication,
		}
		seat.fifo.append(companion_job)
		var member := _member_by_identity(seat, selected_fabrication)
		if member.is_empty():
			return "Fabrication identity disappeared before commit."
		member.status = State.STATUS_PRINTING
		events.append({"type": "fabrication_queued", "seat": seat_id, "member_identity_id": selected_fabrication})
	if bool(normalized.equipment_job):
		if selected_copy.is_empty():
			return "Equipment copy disappeared before commit."
		var equipment_job := {
			"job_id": "%s:job:%d:equipment" % [seat_id, int(state.cycle)],
			"kind": "equipment",
			"created_cycle": int(state.cycle),
		"work_total": int(normalized.support_work),
		"work_remaining": int(normalized.support_work),
			"target_identity_id": str(normalized.equipment_target_id),
			"card_copy": selected_copy,
		}
		seat.fifo.append(equipment_job)
		events.append({"type": "equipment_queued", "seat": seat_id, "card_id": support_card_id, "target_identity_id": str(normalized.equipment_target_id)})
	return ""


static func _describe_head_work(state: Dictionary) -> Array:
	var events := []
	for seat_id in SEAT_ORDER:
		var seat: Dictionary = state.seats[seat_id]
		if seat.fifo.is_empty():
			continue
		var head: Dictionary = seat.fifo[0]
		var presentation := _head_forecast(seat, head)
		var event := {
			"type": "print_work",
			"seat": seat_id,
			"head_before": presentation.head_before,
			"work_before": int(head.work_remaining),
			"work_after": max(0, int(head.work_remaining) - 1),
			"work_total": int(head.work_total),
			"kind": str(head.kind),
			"member_identity_id": str(presentation.member_identity_id),
			"target_identity_id": str(presentation.target_identity_id),
			"destination_state": str(presentation.destination_state),
		}
		events.append(event)
	return events


static func _advance_one_work(state: Dictionary) -> Array:
	var events := []
	for seat_id in SEAT_ORDER:
		var seat: Dictionary = state.seats[seat_id]
		if seat.fifo.is_empty():
			continue
		var head: Dictionary = seat.fifo[0]
		head.work_remaining = max(0, int(head.work_remaining) - 1)
		if str(head.kind) == "companion":
			events.append({
				"type": "awaken_ready",
				"seat": seat_id,
				"member_identity_id": str(head.member_identity_id),
				"work_remaining": int(head.work_remaining),
			})
	return events


static func _complete_work(state: Dictionary) -> Array:
	var events := []
	for seat_id in SEAT_ORDER:
		var seat: Dictionary = state.seats[seat_id]
		if seat.fifo.is_empty():
			continue
		var head: Dictionary = seat.fifo[0]
		if int(head.work_remaining) != 0:
			continue
		seat.fifo.pop_front()
		if str(head.kind) == "companion":
			var member := _member_by_identity(seat, str(head.member_identity_id))
			if not member.is_empty() and member.status == State.STATUS_PRINTING:
				if str(seat.active_member_id).is_empty():
					member.status = State.STATUS_ACTIVE
					seat.active_member_id = member.identity_id
				else:
					member.status = State.STATUS_READY
				_sync_ready_ids(seat)
				events.append({"type": "companion_entered", "seat": seat_id, "member_identity_id": member.identity_id, "status": member.status})
		else:
			var target := _member_by_identity(seat, str(head.target_identity_id))
			var card_copy: Dictionary = head.card_copy
			var card_id := str(card_copy.card_id)
			seat.discard.append(card_copy)
			if target.is_empty() or target.status == State.STATUS_DEFEATED:
				events.append({"type": "equipment_fizzled", "seat": seat_id, "card_id": card_id, "target_identity_id": str(head.target_identity_id)})
			else:
				var support_definition := Data.support_definition(card_id)
				if card_id == "standard_full_suit":
					target.armor = int(support_definition.get("effect", 0))
					target.armor_slot = true
				elif card_id == "iron_gem":
					target.gem_slot = true
				events.append({"type": "equipment_fit", "seat": seat_id, "card_id": card_id, "target_identity_id": target.identity_id})
	return events


static func _resolve_swaps(state: Dictionary, player_plan: Dictionary, rival_plan: Dictionary) -> Array:
	var events := []
	for seat_id in SEAT_ORDER:
		var plan: Dictionary = player_plan if seat_id == "player" else rival_plan
		var swap_id := str(plan.swap_id)
		if swap_id.is_empty():
			continue
		var seat: Dictionary = state.seats[seat_id]
		var outgoing := _member_by_identity(seat, str(seat.active_member_id))
		var incoming := _member_by_identity(seat, swap_id)
		if outgoing.is_empty() or incoming.is_empty():
			continue
		outgoing.status = State.STATUS_READY
		incoming.status = State.STATUS_ACTIVE
		seat.active_member_id = incoming.identity_id
		_sync_ready_ids(seat)
		events.append({"type": "swap", "seat": seat_id, "active_member_id": incoming.identity_id, "reserve_member_id": outgoing.identity_id})
	return events


static func _resolve_spells(state: Dictionary, player_plan: Dictionary, rival_plan: Dictionary) -> Array:
	var events := []
	for seat_id in SEAT_ORDER:
		var plan: Dictionary = player_plan if seat_id == "player" else rival_plan
		var card_id := str(plan.support_card_id)
		if card_id == "forge_surge":
			events.append({"type": "surge_armed", "seat": seat_id, "card_id": card_id})
	return events


static func _lock_attacks(state: Dictionary, surge_seats: Dictionary) -> Dictionary:
	var locks := []
	var events := []
	var beat_id := "%d:1" % int(state.cycle)
	for seat_id in SEAT_ORDER:
		var opposing_seat_id := "rival" if seat_id == "player" else "player"
		var own: Dictionary = state.seats[seat_id]
		var opponent: Dictionary = state.seats[opposing_seat_id]
		var source := _member_by_identity(own, str(own.active_member_id))
		var target := _member_by_identity(opponent, str(opponent.active_member_id))
		if source.is_empty() or target.is_empty() or source.status != State.STATUS_ACTIVE or target.status != State.STATUS_ACTIVE:
			events.append({"type": "hold", "seat": seat_id, "beat_id": beat_id})
			continue
		var landed_before := int(source.landed_attacks)
		var landed_after := landed_before + 1
		var base_attack := int(Data.member_stats(str(source.member_id)).attack)
		if bool(source.gem_slot):
			base_attack += int(Data.support_definition("iron_gem").get("effect", 0))
		var locked_damage := base_attack
		if bool(surge_seats.get(seat_id, false)):
			var surge_definition := Data.support_definition("forge_surge")
			locked_damage = (locked_damage * int(surge_definition.get("numerator", 0))) / int(surge_definition.get("denominator", 1))
		if str(source.member_id) == "cinderpaw" and landed_after % Data.TRAIT_LANDED_INTERVAL == 0:
			locked_damage += Data.CINDERPAW_TRAIT_DAMAGE
		locked_damage = max(Data.MINIMUM_HIT, locked_damage)
		source.landed_attacks = landed_after
		var lock := {
			"seat": seat_id,
			"source_identity_id": source.identity_id,
			"target_identity_id": target.identity_id,
			"damage": locked_damage,
			"landed_before": landed_before,
			"landed_after": landed_after,
			"beat_id": beat_id,
		}
		locks.append(lock)
		events.append({"type": "attack_locked", "seat": seat_id, "source_identity_id": source.identity_id, "target_identity_id": target.identity_id, "damage": locked_damage, "landed_after": landed_after, "beat_id": beat_id})
	return {"locks": locks, "events": events}


static func _apply_damage(state: Dictionary, locks: Array) -> Array:
	var events := []
	for lock_value in locks:
		var lock: Dictionary = lock_value
		var target_seat_id := "rival" if str(lock.seat) == "player" else "player"
		var target_seat: Dictionary = state.seats[target_seat_id]
		var target := _member_by_identity(target_seat, str(lock.target_identity_id))
		if target.is_empty():
			continue
		var hp_before := int(target.hp)
		var armor_before := int(target.armor)
		var absorbed: int = min(armor_before, int(lock.damage))
		target.armor = armor_before - absorbed
		target.hp = max(0, hp_before - (int(lock.damage) - absorbed))
		events.append({"type": "damage", "seat": target_seat_id, "target_identity_id": target.identity_id, "beat_id": lock.beat_id, "hp_before": hp_before, "hp_after": int(target.hp), "armor_before": armor_before, "armor_after": int(target.armor), "damage": int(lock.damage)})
	return events


static func _resolve_traits(state: Dictionary, locks: Array) -> Array:
	var events := []
	for lock_value in locks:
		var lock: Dictionary = lock_value
		if int(lock.landed_after) % Data.TRAIT_LANDED_INTERVAL != 0:
			continue
		var seat_id := str(lock.seat)
		var seat: Dictionary = state.seats[seat_id]
		var source := _member_by_identity(seat, str(lock.source_identity_id))
		if source.is_empty() or source.status != State.STATUS_ACTIVE:
			continue
		var member_id := str(source.member_id)
		if member_id == "voltwig":
			var before_filament := int(seat.filament)
			seat.filament = min(int(state.filament_cap), before_filament + Data.VOLTWIG_TRAIT_FILAMENT)
			events.append({"type": "trait_filament", "seat": seat_id, "source_identity_id": source.identity_id, "filament_before": before_filament, "filament_after": int(seat.filament)})
			continue
		if int(source.hp) <= 0:
			continue
		if member_id == "aquafin":
			var base_hp := int(Data.member_stats(member_id).hp)
			var before_hp := int(source.hp)
			source.hp = min(base_hp, before_hp + Data.AQUAFIN_TRAIT_HEAL)
			events.append({"type": "trait_heal", "seat": seat_id, "source_identity_id": source.identity_id, "hp_before": before_hp, "hp_after": int(source.hp)})
		elif member_id == "mossmunk":
			var before_armor := int(source.armor)
			source.armor = min(Data.ARMOR_CAP, before_armor + Data.MOSSMUNK_TRAIT_ARMOR)
			events.append({"type": "trait_armor", "seat": seat_id, "source_identity_id": source.identity_id, "armor_before": before_armor, "armor_after": int(source.armor)})
	return events


static func _mark_defeats(state: Dictionary) -> Array:
	var events := []
	for seat_id in SEAT_ORDER:
		var seat: Dictionary = state.seats[seat_id]
		for member_value in seat.members:
			var member: Dictionary = member_value
			if member.status != State.STATUS_DEFEATED and int(member.hp) <= 0:
				member.status = State.STATUS_DEFEATED
				member.hp = 0
				if str(seat.active_member_id) == str(member.identity_id):
					seat.active_member_id = ""
				events.append({"type": "defeat", "seat": seat_id, "member_identity_id": member.identity_id})
		_sync_ready_ids(seat)
	return events


static func _replace_ready_members(state: Dictionary) -> Array:
	var events := []
	for seat_id in SEAT_ORDER:
		var seat: Dictionary = state.seats[seat_id]
		if not str(seat.active_member_id).is_empty():
			continue
		var replacement_id := _highest_priority_with_status(seat, State.STATUS_READY)
		if replacement_id.is_empty():
			continue
		var replacement := _member_by_identity(seat, replacement_id)
		replacement.status = State.STATUS_ACTIVE
		seat.active_member_id = replacement.identity_id
		_sync_ready_ids(seat)
		events.append({"type": "replacement", "seat": seat_id, "member_identity_id": replacement.identity_id})
	return events


static func _settle_result(state: Dictionary) -> Array:
	var player_defeated := _all_defeated(state.seats.player)
	var rival_defeated := _all_defeated(state.seats.rival)
	if player_defeated and rival_defeated:
		state.result = "Draw"
	elif rival_defeated:
		state.result = "Win"
	elif player_defeated:
		state.result = "Loss"
	else:
		state.result = ""
	if str(state.result).is_empty():
		return []
	return [{"type": "terminal", "result": state.result}]


static func _open_next_plan(state: Dictionary, events: Array) -> void:
	state.revision = int(state.revision) + 1
	state.cycle = int(state.cycle) + 1
	for seat_id in SEAT_ORDER:
		var seat: Dictionary = state.seats[seat_id]
		var before_filament := int(seat.filament)
		seat.filament = min(int(state.filament_cap), before_filament + Data.FILAMENT_REGEN)
		var drawn := _draw_one(seat)
		events.append({"type": "plan_open", "seat": seat_id, "filament_before": before_filament, "filament_after": int(seat.filament), "drawn": drawn})


static func _finalize_terminal(state: Dictionary) -> void:
	state.revision = int(state.revision) + 1
	state.cycle = int(state.revision)
	state.terminal_receipt = {
		"id": "terminal:%d:%d" % [int(state.seed), int(state.cycle)],
		"result": state.result,
		"cycle": int(state.cycle),
		"revision": int(state.revision),
	}


static func _draw_one(seat: Dictionary) -> bool:
	if seat.hand.size() >= Data.HAND_SIZE or seat.draw_pile.is_empty():
		return false
	seat.hand.append(seat.draw_pile.pop_front())
	return true


## A single descriptor is shared by plan forecast and Print-stage receipts.  It
## names both the head's stable identity and its likely completion disposition.
static func _head_forecast(seat: Dictionary, job_value: Variant) -> Dictionary:
	var projected := BattleProjection.public_job_from_private(job_value)
	if not bool(projected.get("ok", false)):
		return {}
	var job: Dictionary = projected.job
	var member_identity_id := ""
	var target_identity_id := ""
	var destination_state := ""
	if str(job.kind) == "companion":
		member_identity_id = str(job.member_identity_id)
		destination_state = "Active" if str(seat.active_member_id).is_empty() else "Ready"
	else:
		target_identity_id = str(job.target_identity_id)
		var target := _member_by_identity(seat, target_identity_id)
		destination_state = "Fizzle" if target.is_empty() or str(target.status) == State.STATUS_DEFEATED else "Fit"
	return {
		"head_before": job,
		"member_identity_id": member_identity_id,
		"target_identity_id": target_identity_id,
		"destination_state": destination_state,
	}


static func _eligible_targets_for_seat(seat: Dictionary, fabrication_id: String) -> Array:
	var result := []
	var active_id := str(seat.get("active_member_id", ""))
	if not active_id.is_empty():
		result.append(active_id)
	for identity_value in seat.get("priority", []):
		var identity := str(identity_value)
		var member := _member_by_identity(seat, identity)
		if not member.is_empty() and member.status == State.STATUS_READY:
			result.append(identity)
	for identity_value in seat.get("priority", []):
		var identity := str(identity_value)
		var member := _member_by_identity(seat, identity)
		var same_plan_printing: bool = identity == fabrication_id and not member.is_empty() and member.status == State.STATUS_UNSPENT
		if not member.is_empty() and (member.status == State.STATUS_PRINTING or same_plan_printing):
			result.append(identity)
	return result


static func _field_is_empty(seat: Dictionary) -> bool:
	return str(seat.active_member_id).is_empty() and seat.ready_member_ids.is_empty()


static func _highest_priority_with_status(seat: Dictionary, status: String) -> String:
	for identity_value in seat.priority:
		var identity := str(identity_value)
		var member := _member_by_identity(seat, identity)
		if not member.is_empty() and str(member.status) == status:
			return identity
	return ""


static func _is_unspent_member(seat: Dictionary, identity: String) -> bool:
	var member := _member_by_identity(seat, identity)
	return not member.is_empty() and str(member.status) == State.STATUS_UNSPENT


static func _is_ready_member(seat: Dictionary, identity: String) -> bool:
	var member := _member_by_identity(seat, identity)
	return not member.is_empty() and str(member.status) == State.STATUS_READY


static func _member_by_identity(seat: Dictionary, identity: String) -> Dictionary:
	for member_value in seat.members:
		var member: Dictionary = member_value
		if str(member.identity_id) == identity:
			return member
	return {}


static func _copy_by_id(copies: Array, copy_id: String) -> Dictionary:
	for copy_value in copies:
		var copy: Dictionary = copy_value
		if str(copy.copy_id) == copy_id:
			return copy
	return {}


static func _remove_copy(copies: Array, copy_id: String) -> Dictionary:
	for index in copies.size():
		var copy: Dictionary = copies[index]
		if str(copy.copy_id) == copy_id:
			return copies.pop_at(index)
	return {}


static func _sync_ready_ids(seat: Dictionary) -> void:
	var ready_ids := []
	for identity_value in seat.priority:
		var identity := str(identity_value)
		var member := _member_by_identity(seat, identity)
		if not member.is_empty() and member.status == State.STATUS_READY:
			ready_ids.append(identity)
	seat.ready_member_ids = ready_ids


static func _all_defeated(seat: Dictionary) -> bool:
	for member_value in seat.members:
		var member: Dictionary = member_value
		if member.status != State.STATUS_DEFEATED:
			return false
	return true


static func _has_exact_keys(record: Dictionary, expected: Array) -> bool:
	if record.size() != expected.size():
		return false
	for key in record.keys():
		if key not in expected:
			return false
	return true


static func _is_strict_integer(value: Variant) -> bool:
	return value is int and not (value is bool) and value >= -State.MAX_SAFE_JSON_INTEGER and value <= State.MAX_SAFE_JSON_INTEGER


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "error": message}
