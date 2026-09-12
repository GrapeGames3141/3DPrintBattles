extends Node

const Data := preload("res://scripts/team_battle/team_battle_data.gd")
const State := preload("res://scripts/team_battle/team_battle_state.gd")
const Rules := preload("res://scripts/team_battle/team_battle_rules.gd")
const Bot := preload("res://scripts/team_battle/team_battle_bot.gd")
const Coordinator := preload("res://scripts/team_battle/team_battle_coordinator.gd")

var failures: Array[String] = []
var require_count := 0
var completed_groups := 0
var writes: Array = []
var reject_cursor_number := -1
var cursor_writes := 0
var reject_kind := ""


func require(value: bool, message: String) -> void:
	require_count += 1
	if not value:
		failures.append(message)
		push_error(message)


func _ready() -> void:
	_test_start_request_and_privacy()
	_test_cursor_and_partial_skip()
	_test_restore_json_round_trips()
	_test_duplicate_and_transaction_failures()
	_test_terminal_round_trip()
	_test_checkpoint_and_trace_equivalence()
	_test_full_session_trace_equivalence()
	require(completed_groups == 7, "all Coordinator groups reach their end marker")
	print("TEAM_BATTLE_COORDINATOR groups=%d/7 requires=%d failures=%d" % [completed_groups, require_count, failures.size()])
	if completed_groups == 7:
		print("TEAM_BATTLE_COORDINATOR failures=%d" % failures.size())
	get_tree().quit(0 if completed_groups == 7 and failures.is_empty() else 1)


func _persist(kind: String, payload: Dictionary) -> bool:
	if kind == reject_kind:
		return false
	if kind == "cursor":
		cursor_writes += 1
		if reject_cursor_number == cursor_writes:
			return false
	writes.append({"kind": kind, "payload": payload.duplicate(true)})
	return true


func _truthy_persist(_kind: String, _payload: Dictionary) -> Dictionary:
	return {"not": "a boolean"}


func _initial(seed: int = 41) -> Dictionary:
	return State.create_production(
		["cinderpaw", "aquafin", "mossmunk"],
		["cinderpaw", "aquafin", "mossmunk"],
		Data.recommended_kit(), Data.recommended_kit(), seed, true
	)


func _new_coordinator(seed: int, match_id: String) -> Dictionary:
	writes.clear()
	reject_cursor_number = -1
	cursor_writes = 0
	reject_kind = ""
	var made := _initial(seed)
	if not bool(made.get("ok", false)):
		return made
	return Coordinator.create(made.state, match_id, Callable(self, "_persist"))


func _bot_plans(coordinator: Variant) -> Dictionary:
	var player_view: Dictionary = coordinator.view("player")
	var rival_view: Dictionary = coordinator.view("rival")
	if not bool(player_view.get("ok", false)) or not bool(rival_view.get("ok", false)):
		return {"ok": false}
	var player_plan := Bot.choose_plan(player_view.view)
	var rival_plan := Bot.choose_plan(rival_view.view)
	if not bool(player_plan.get("ok", false)) or not bool(rival_plan.get("ok", false)):
		return {"ok": false}
	return {"ok": true, "player": player_plan.plan, "rival": rival_plan.plan}


func _request(coordinator: Variant, request_id: String) -> Dictionary:
	var plans := _bot_plans(coordinator)
	if not bool(plans.get("ok", false)):
		return plans
	return coordinator.request("match-a", request_id, plans.player, plans.rival)


func _complete_by_acknowledgement(coordinator: Variant, request_id: String, match_id: String = "match-a") -> Dictionary:
	while coordinator.is_busy():
		var cursor := int(coordinator.snapshot().presentation.cursor)
		var advanced: Dictionary = coordinator.acknowledge(match_id, request_id, cursor)
		if not bool(advanced.get("ok", false)):
			return advanced
	return {"ok": true, "snapshot": coordinator.snapshot()}


func _receipt_from_snapshot(snapshot: Dictionary) -> Dictionary:
	if not snapshot.records is Array or snapshot.records.is_empty():
		return {}
	var record: Dictionary = snapshot.records.back()
	return record.receipt if record.receipt is Dictionary else {}


func _test_start_request_and_privacy() -> void:
	var created := _new_coordinator(41, "match-a")
	require(bool(created.get("ok", false)), "Coordinator Start accepts revision-zero production State")
	if not bool(created.get("ok", false)):
		return
	var coordinator = created.coordinator
	require(writes.size() == 1 and writes[0].kind == "start", "Start persists one complete snapshot before publication")
	var opened := _request(coordinator, "request-1")
	require(bool(opened.get("ok", false)) and coordinator.is_busy(), "Run publishes one pending ordered receipt")
	if bool(opened.get("ok", false)):
		require(not bool(_request(coordinator, "request-pending").get("ok", false)), "pending receipt blocks a second Run")
		require(writes.size() == 2 and writes[1].kind == "run", "Run persists one complete candidate snapshot before publication")
		var player_receipt: Dictionary = coordinator.viewer_receipt("request-1", "player")
		var serialized := JSON.stringify(player_receipt)
		require(bool(player_receipt.get("ok", false)) and not serialized.contains("rival:card:"), "viewer receipt redacts rival private Support copy IDs")
		var player_view: Dictionary = coordinator.view("player")
		require(bool(player_view.get("ok", false)) and not JSON.stringify(player_view.view).contains("rival:card:"), "view exposes only private own and public opponent fields")
	completed_groups += 1


func _test_cursor_and_partial_skip() -> void:
	var created := _new_coordinator(42, "match-a")
	require(bool(created.get("ok", false)), "cursor fixture creates")
	if not bool(created.get("ok", false)):
		return
	var coordinator = created.coordinator
	var opened := _request(coordinator, "request-1")
	require(bool(opened.get("ok", false)), "cursor fixture Run resolves")
	if not bool(opened.get("ok", false)):
		return
	var unknown: Dictionary = coordinator.acknowledge("match-a", "request-unknown", 0)
	require(not bool(unknown.get("ok", false)), "unknown acknowledgement request rejects")
	var future: Dictionary = coordinator.acknowledge("match-a", "request-1", 1)
	require(not bool(future.get("ok", false)), "future acknowledgement cursor rejects before its stage is current")
	var stale: Dictionary = coordinator.acknowledge("match-a", "request-1", -1)
	require(not bool(stale.get("ok", false)), "negative cursor rejects")
	var first: Dictionary = coordinator.acknowledge("match-a", "request-1", 0)
	require(bool(first.get("ok", false)) and int(first.cursor) == 1, "exact cursor acknowledgement advances one stage with a small write")
	var duplicate: Dictionary = coordinator.acknowledge("match-a", "request-1", 0)
	require(bool(duplicate.get("ok", false)) and bool(duplicate.ignored), "older duplicate acknowledgement is ignored without a write")
	reject_cursor_number = 3
	var partial: Dictionary = coordinator.skip("match-a", "request-1", 1)
	require(not bool(partial.get("ok", false)) and int(coordinator.snapshot().presentation.cursor) == 2, "Skip retains its first persisted acknowledgement when the second Skip write fails")
	reject_cursor_number = -1
	var resumed: Dictionary = coordinator.skip("match-a", "request-1", 2)
	require(bool(resumed.get("ok", false)) and not coordinator.is_busy(), "Skip resumes from the persisted cursor without rerunning Rules")
	var historical: Dictionary = coordinator.acknowledge("match-a", "request-1", 0)
	require(bool(historical.get("ok", false)) and bool(historical.get("ignored", false)), "stale completed acknowledgement is a no-op")
	completed_groups += 1


func _test_terminal_round_trip() -> void:
	writes.clear()
	reject_kind = ""
	var made := State.create_test_1v1("cinderpaw", "cinderpaw", Data.recommended_kit(), Data.recommended_kit(), 51, true)
	require(bool(made.get("ok", false)), "terminal 1v1 fixture creates")
	if not bool(made.get("ok", false)):
		return
	for seat_id in ["player", "rival"]:
		var seat: Dictionary = made.state.seats[seat_id]
		var member: Dictionary = seat.members[0]
		member.status = State.STATUS_ACTIVE
		member.hp = 7
		seat.active_member_id = member.identity_id
		seat.ready_member_ids = []
	var created := Coordinator.create(made.state, "match-terminal", Callable(self, "_persist"), true)
	require(bool(created.get("ok", false)), "terminal coordinator creates")
	if bool(created.get("ok", false)):
		var plan: Dictionary = {"expected_revision": 0, "fabrication_id": "", "support_copy_id": "", "equipment_target_id": "", "swap_id": ""}
		var terminal: Dictionary = created.coordinator.request("match-terminal", "terminal-request", plan, plan)
		require(bool(terminal.get("ok", false)) and str(created.coordinator.view("player").view.result) == "Draw", "terminal Run settles Draw exactly once")
		var terminal_json: Variant = JSON.parse_string(JSON.stringify(created.coordinator.snapshot()))
		require(bool(Coordinator.restore(terminal_json, null, Callable(self, "_persist"), true).get("ok", false)), "terminal receipt JSON round trip preserves final stage and authority")
		require(not bool(created.coordinator.request("match-terminal", "terminal-next", plan, plan).get("ok", false)), "terminal coordinator rejects a second transition")
	completed_groups += 1


func _test_restore_json_round_trips() -> void:
	var created := _new_coordinator(43, "match-a")
	require(bool(created.get("ok", false)), "restore fixture creates")
	if not bool(created.get("ok", false)):
		return
	var coordinator = created.coordinator
	var opened := _request(coordinator, "request-1")
	require(bool(opened.get("ok", false)), "restore fixture Run resolves")
	if not bool(opened.get("ok", false)):
		return
	var queue_ack: Dictionary = coordinator.acknowledge("match-a", "request-1", 0)
	require(bool(queue_ack.get("ok", false)) and int(queue_ack.cursor) == 1, "Queue acknowledgement reaches the pending Print cursor")
	var print_json: Variant = JSON.parse_string(JSON.stringify(coordinator.snapshot()))
	var restored_print := Coordinator.restore(print_json, null, Callable(self, "_persist"))
	require(bool(restored_print.get("ok", false)) and int(restored_print.coordinator.snapshot().presentation.cursor) == 1, "JSON round trip restores the true pending Print cursor without replaying Rules")
	for cursor in range(1, 7):
		var advanced: Dictionary = coordinator.acknowledge("match-a", "request-1", cursor)
		require(bool(advanced.get("ok", false)), "Damage-roundtrip cursor advance %d persists" % cursor)
	var damage_json: Variant = JSON.parse_string(JSON.stringify(coordinator.snapshot()))
	var restored_damage := Coordinator.restore(damage_json, null, Callable(self, "_persist"))
	require(bool(restored_damage.get("ok", false)) and int(restored_damage.coordinator.snapshot().presentation.cursor) == 7, "JSON round trip restores an intermediate Damage-era cursor")
	completed_groups += 1


func _test_duplicate_and_transaction_failures() -> void:
	var failed_start_state := _initial(40)
	reject_kind = "start"
	var failed_start := Coordinator.create(failed_start_state.state, "match-a", Callable(self, "_persist"))
	require(not bool(failed_start.get("ok", false)), "Start persistence rejection publishes no Coordinator")
	reject_kind = ""
	var truthy_start := Coordinator.create(failed_start_state.state, "match-a", Callable(self, "_truthy_persist"))
	require(not bool(truthy_start.get("ok", false)), "Start rejects a truthy non-boolean persistence response")
	var created := _new_coordinator(44, "match-a")
	require(bool(created.get("ok", false)), "duplicate fixture creates")
	if not bool(created.get("ok", false)):
		return
	var coordinator = created.coordinator
	var plans := _bot_plans(coordinator)
	require(bool(plans.get("ok", false)), "duplicate fixture produces two checked Bot Plans")
	if not bool(plans.get("ok", false)):
		return
	var before_failed_run := JSON.stringify(coordinator.snapshot())
	reject_kind = "run"
	var failed_run: Dictionary = coordinator.request("match-a", "request-failed", plans.player, plans.rival)
	require(not bool(failed_run.get("ok", false)) and JSON.stringify(coordinator.snapshot()) == before_failed_run, "Run persistence rejection leaves authority and presentation unpublished")
	reject_kind = ""
	var first: Dictionary = coordinator.request("match-a", "request-1", plans.player, plans.rival)
	var writes_after_first := writes.size()
	var duplicate: Dictionary = coordinator.request("match-a", "request-1", plans.player, plans.rival)
	require(bool(first.get("ok", false)) and bool(duplicate.get("ok", false)) and writes.size() == writes_after_first, "same request ID and input is idempotent without a second Rules or store transition")
	var changed_player: Dictionary = plans.player.duplicate(true)
	changed_player.fabrication_id = ""
	require(not bool(coordinator.request("match-a", "request-1", changed_player, plans.rival).get("ok", false)), "same request ID with different Plans rejects")
	var malformed_snapshot: Dictionary = coordinator.snapshot()
	malformed_snapshot["unknown"] = true
	require(not bool(Coordinator.restore(malformed_snapshot, null, Callable(self, "_persist")).get("ok", false)), "unknown snapshot fields fail closed")
	var write_count_before_invalid_restore := writes.size()
	require(not bool(Coordinator.restore(coordinator.snapshot(), null, Callable()).get("ok", false)) and writes.size() == write_count_before_invalid_restore, "restore rejects an invalid persistence callback without writing")
	var minimal_created := _new_coordinator(45, "match-a")
	require(bool(minimal_created.get("ok", false)), "minimal Plan restore fixture creates")
	if bool(minimal_created.get("ok", false)):
		var minimal: Dictionary = {"expected_revision": 0}
		var minimal_request: Dictionary = minimal_created.coordinator.request("match-a", "request-minimal", minimal, minimal)
		require(bool(minimal_request.get("ok", false)), "minimal accepted Plans are retained without filling omitted optional keys")
		if bool(minimal_request.get("ok", false)):
			var minimal_json: Variant = JSON.parse_string(JSON.stringify(minimal_created.coordinator.snapshot()))
			require(bool(Coordinator.restore(minimal_json, null, Callable(self, "_persist")).get("ok", false)), "JSON restore hashes the original minimal Plan shape rather than normalized defaults")
	completed_groups += 1


func _full_session_trace(mode: String) -> Dictionary:
	var match_id := "match-full-%s" % mode
	var created := _new_coordinator(47, match_id)
	if not bool(created.get("ok", false)):
		return created
	var coordinator = created.coordinator
	var receipt_hashes := []
	var cycle_count := 0
	var started_usec := Time.get_ticks_usec()
	var run_total_usec := 0
	var run_max_usec := 0
	var acknowledge_max_usec := 0
	var restore_total_usec := 0
	while str(coordinator.snapshot().authority.result).is_empty() and cycle_count < 500:
		var plans := _bot_plans(coordinator)
		if not bool(plans.get("ok", false)):
			return {"ok": false, "error": "Full-session Bot plan failed."}
		var request_id := "cycle-%d" % (cycle_count + 1)
		var run_started_usec := Time.get_ticks_usec()
		var opened: Dictionary = coordinator.request(match_id, request_id, plans.player, plans.rival)
		var run_elapsed_usec := Time.get_ticks_usec() - run_started_usec
		run_total_usec += run_elapsed_usec
		run_max_usec = max(run_max_usec, run_elapsed_usec)
		if not bool(opened.get("ok", false)):
			return opened
		receipt_hashes.append(str(opened.receipt_hash))
		if mode == "skip":
			var skipped: Dictionary = coordinator.skip(match_id, request_id, 0)
			if not bool(skipped.get("ok", false)):
				return skipped
		elif mode == "resume":
			var first_ack_started_usec := Time.get_ticks_usec()
			var first: Dictionary = coordinator.acknowledge(match_id, request_id, 0)
			acknowledge_max_usec = max(acknowledge_max_usec, Time.get_ticks_usec() - first_ack_started_usec)
			if not bool(first.get("ok", false)):
				return first
			var json_snapshot: Variant = JSON.parse_string(JSON.stringify(coordinator.snapshot()))
			var restore_started_usec := Time.get_ticks_usec()
			var restored := Coordinator.restore(json_snapshot, null, Callable(self, "_persist"))
			restore_total_usec += Time.get_ticks_usec() - restore_started_usec
			if not bool(restored.get("ok", false)):
				return restored
			coordinator = restored.coordinator
			var resumed: Dictionary = coordinator.skip(match_id, request_id, int(coordinator.snapshot().presentation.cursor))
			if not bool(resumed.get("ok", false)):
				return resumed
		else:
			while coordinator.is_busy():
				var cursor := int(coordinator.snapshot().presentation.cursor)
				var acknowledge_started_usec := Time.get_ticks_usec()
				var acknowledged: Dictionary = coordinator.acknowledge(match_id, request_id, cursor)
				acknowledge_max_usec = max(acknowledge_max_usec, Time.get_ticks_usec() - acknowledge_started_usec)
				if not bool(acknowledged.get("ok", false)):
					return acknowledged
		cycle_count += 1
	var elapsed_usec := Time.get_ticks_usec() - started_usec
	var final_snapshot: Dictionary = coordinator.snapshot()
	return {
		"ok": str(final_snapshot.authority.result) != "",
		"snapshot": final_snapshot,
		"receipt_hashes": receipt_hashes,
		"cycles": cycle_count,
		"elapsed_usec": elapsed_usec,
		"run_total_usec": run_total_usec,
		"run_max_usec": run_max_usec,
		"acknowledge_max_usec": acknowledge_max_usec,
		"restore_total_usec": restore_total_usec,
		"serialized_bytes": JSON.stringify(final_snapshot).to_utf8_buffer().size(),
	}


func _test_full_session_trace_equivalence() -> void:
	var normal := _full_session_trace("normal")
	var reduced := _full_session_trace("reduced")
	var skipped := _full_session_trace("skip")
	var resumed := _full_session_trace("resume")
	require(bool(normal.get("ok", false)) and bool(reduced.get("ok", false)) and bool(skipped.get("ok", false)) and bool(resumed.get("ok", false)), "four real 3v3 Coordinator sessions reach terminal authority")
	if bool(normal.get("ok", false)) and bool(reduced.get("ok", false)) and bool(skipped.get("ok", false)) and bool(resumed.get("ok", false)):
		require(int(normal.cycles) < 500 and int(normal.cycles) == int(reduced.cycles) and int(normal.cycles) == int(skipped.cycles) and int(normal.cycles) == int(resumed.cycles), "full-session modes share a bounded cycle trace")
		require(JSON.stringify(normal.receipt_hashes) == JSON.stringify(reduced.receipt_hashes) and JSON.stringify(normal.receipt_hashes) == JSON.stringify(skipped.receipt_hashes) and JSON.stringify(normal.receipt_hashes) == JSON.stringify(resumed.receipt_hashes), "full-session modes preserve ordered receipt hashes")
		require(JSON.stringify(normal.snapshot.authority) == JSON.stringify(reduced.snapshot.authority) and JSON.stringify(normal.snapshot.authority) == JSON.stringify(skipped.snapshot.authority) and JSON.stringify(normal.snapshot.authority) == JSON.stringify(resumed.snapshot.authority), "full-session modes preserve the exact terminal State")
		require(int(normal.snapshot.presentation.cursor) == int(reduced.snapshot.presentation.cursor) and int(normal.snapshot.presentation.cursor) == int(skipped.snapshot.presentation.cursor) and int(normal.snapshot.presentation.cursor) == int(resumed.snapshot.presentation.cursor), "full-session modes finish at the same receipt cursor")
		print("TEAM_BATTLE_COORDINATOR session_metrics seed=47 cycles=%d bytes=%d normal_usec=%d reduced_usec=%d skip_usec=%d resume_usec=%d run_sum_usec=%d run_max_usec=%d ack_max_usec=%d restore_sum_usec=%d" % [int(normal.cycles), int(normal.serialized_bytes), int(normal.elapsed_usec), int(reduced.elapsed_usec), int(skipped.elapsed_usec), int(resumed.elapsed_usec), int(normal.run_total_usec), int(normal.run_max_usec), int(normal.acknowledge_max_usec), int(resumed.restore_total_usec)])
	completed_groups += 1


func _test_checkpoint_and_trace_equivalence() -> void:
	var created := _new_coordinator(46, "match-a")
	require(bool(created.get("ok", false)), "checkpoint fixture creates")
	if not bool(created.get("ok", false)):
		return
	var coordinator = created.coordinator
	var first := _request(coordinator, "request-1")
	require(bool(first.get("ok", false)), "checkpoint fixture first Run resolves")
	if not bool(first.get("ok", false)):
		return
	var receipt_hash := str(first.receipt_hash)
	var old_overlay := {
		"match_id": "match-a",
		"authority_revision": 1,
		"request_id": "request-1",
		"receipt_hash": receipt_hash,
		"next_cursor": 1,
	}
	var completed := _complete_by_acknowledgement(coordinator, "request-1")
	require(bool(completed.get("ok", false)), "normal acknowledgement trace completes")
	if not bool(completed.get("ok", false)):
		return
	var normal_snapshot: Dictionary = completed.snapshot
	var restored_old := Coordinator.restore(normal_snapshot, old_overlay, Callable(self, "_persist"))
	require(bool(restored_old.get("ok", false)) and int(restored_old.coordinator.snapshot().presentation.cursor) == int(normal_snapshot.presentation.cursor), "old valid current-receipt overlay cannot reduce a completed cursor")
	var corrupt_overlay := old_overlay.duplicate(true)
	corrupt_overlay.next_cursor = 999
	require(not bool(Coordinator.restore(normal_snapshot, corrupt_overlay, Callable(self, "_persist")).get("ok", false)), "out-of-range current overlay rejects")
	var typed_overlay := old_overlay.duplicate(true)
	typed_overlay.authority_revision = true
	require(not bool(Coordinator.restore(normal_snapshot, typed_overlay, Callable(self, "_persist")).get("ok", false)), "typed malformed current overlay rejects")
	var second := _request(coordinator, "request-2")
	require(bool(second.get("ok", false)), "next Run opens after the completed receipt")
	if bool(second.get("ok", false)):
		var newer_snapshot: Dictionary = coordinator.snapshot()
		var ignored_old := Coordinator.restore(newer_snapshot, old_overlay, Callable(self, "_persist"))
		require(bool(ignored_old.get("ok", false)) and int(ignored_old.coordinator.snapshot().presentation.cursor) == 0, "well-formed older receipt overlay is ignored after a newer Run")
		var current_overlay := {
			"match_id": "match-a",
			"authority_revision": int(newer_snapshot.authority.revision),
			"request_id": "request-2",
			"receipt_hash": str(second.receipt_hash),
			"next_cursor": 1,
		}
		var restored_current := Coordinator.restore(newer_snapshot, current_overlay, Callable(self, "_persist"))
		require(bool(restored_current.get("ok", false)) and int(restored_current.coordinator.snapshot().presentation.cursor) == 1, "valid current overlay advances the stored cursor monotonically")
	var reordered := normal_snapshot.duplicate(true)
	var reordered_record: Dictionary = reordered.records[0]
	var reordered_stages: Array = reordered_record.receipt.stages
	var first_stage: Dictionary = reordered_stages[0]
	reordered_stages[0] = reordered_stages[1]
	reordered_stages[1] = first_stage
	var reordered_hash := Coordinator._hash_value(reordered_record.receipt)
	if bool(reordered_hash.get("ok", false)):
		reordered_record.receipt_hash = reordered_hash.hash
	require(not bool(Coordinator.restore(reordered, null, Callable(self, "_persist")).get("ok", false)), "stage reorder rejects even when its receipt hash is recomputed")
	var missing_snapshot := normal_snapshot.duplicate(true)
	var missing_snapshot_record: Dictionary = missing_snapshot.records[0]
	var missing_snapshot_stage: Dictionary = missing_snapshot_record.receipt.stages.back()
	missing_snapshot_stage.erase("snapshot")
	var missing_snapshot_hash := Coordinator._hash_value(missing_snapshot_record.receipt)
	if bool(missing_snapshot_hash.get("ok", false)):
		missing_snapshot_record.receipt_hash = missing_snapshot_hash.hash
	require(not bool(Coordinator.restore(missing_snapshot, null, Callable(self, "_persist")).get("ok", false)), "missing final snapshot rejects without a nested-stage error")
	var altered_stage_seed := normal_snapshot.duplicate(true)
	var altered_seed_record: Dictionary = altered_stage_seed.records[0]
	var altered_seed_stage: Dictionary = altered_seed_record.receipt.stages[0]
	altered_seed_stage.snapshot.seed = int(altered_seed_stage.snapshot.seed) + 1
	var altered_seed_hash := Coordinator._hash_value(altered_seed_record.receipt)
	if bool(altered_seed_hash.get("ok", false)):
		altered_seed_record.receipt_hash = altered_seed_hash.hash
	require(not bool(Coordinator.restore(altered_stage_seed, null, Callable(self, "_persist")).get("ok", false)), "transient stage seed mismatch rejects even when its receipt hash is recomputed")
	var corrupt_hash := normal_snapshot.duplicate(true)
	var corrupt_record: Dictionary = corrupt_hash.records[0]
	corrupt_record.receipt_hash = "0".repeat(64)
	require(not bool(Coordinator.restore(corrupt_hash, null, Callable(self, "_persist")).get("ok", false)), "corrupt receipt hash rejects before a record can restore")
	var revision_jump := normal_snapshot.duplicate(true)
	var jumped_record: Dictionary = revision_jump.records[0]
	jumped_record.receipt.final_revision = int(jumped_record.receipt.final_revision) + 1
	var jumped_hash := Coordinator._hash_value(jumped_record.receipt)
	if bool(jumped_hash.get("ok", false)):
		jumped_record.receipt_hash = jumped_hash.hash
	require(not bool(Coordinator.restore(revision_jump, null, Callable(self, "_persist")).get("ok", false)), "receipt revision jump rejects even when its receipt hash is recomputed")

	var skip_created := _new_coordinator(46, "match-a")
	var resume_created := _new_coordinator(46, "match-a")
	var reduced_created := _new_coordinator(46, "match-a")
	require(bool(skip_created.get("ok", false)) and bool(resume_created.get("ok", false)) and bool(reduced_created.get("ok", false)), "trace-equivalence coordinators create")
	if bool(skip_created.get("ok", false)) and bool(resume_created.get("ok", false)) and bool(reduced_created.get("ok", false)):
		var skipped_opened := _request(skip_created.coordinator, "request-1")
		var resumed_opened := _request(resume_created.coordinator, "request-1")
		var reduced_opened := _request(reduced_created.coordinator, "request-1")
		require(bool(skipped_opened.get("ok", false)) and bool(resumed_opened.get("ok", false)) and bool(reduced_opened.get("ok", false)), "skip, resume, and reduced traces start from the same authority")
		if bool(skipped_opened.get("ok", false)) and bool(resumed_opened.get("ok", false)) and bool(reduced_opened.get("ok", false)):
			var skipped: Dictionary = skip_created.coordinator.skip("match-a", "request-1", 0)
			var reduced := _complete_by_acknowledgement(reduced_created.coordinator, "request-1")
			var resume_prefix: Dictionary = resume_created.coordinator.acknowledge("match-a", "request-1", 0)
			var resume_snapshot: Variant = JSON.parse_string(JSON.stringify(resume_created.coordinator.snapshot()))
			var restored_resume := Coordinator.restore(resume_snapshot, null, Callable(self, "_persist"))
			var resumed := {"ok": false}
			if bool(restored_resume.get("ok", false)):
				resumed = restored_resume.coordinator.skip("match-a", "request-1", int(restored_resume.coordinator.snapshot().presentation.cursor))
			require(bool(skipped.get("ok", false)) and bool(reduced.get("ok", false)) and bool(resume_prefix.get("ok", false)) and bool(restored_resume.get("ok", false)) and bool(resumed.get("ok", false)), "normal, reduced, skip, and resume playback modes complete their receipt")
			var skipped_snapshot: Dictionary = skip_created.coordinator.snapshot()
			var reduced_snapshot: Dictionary = reduced_created.coordinator.snapshot()
			var resumed_snapshot: Dictionary = restored_resume.coordinator.snapshot() if bool(restored_resume.get("ok", false)) else {}
			require(JSON.stringify(normal_snapshot.authority) == JSON.stringify(skipped_snapshot.authority) and JSON.stringify(normal_snapshot.authority) == JSON.stringify(reduced_snapshot.authority) and JSON.stringify(normal_snapshot.authority) == JSON.stringify(resumed_snapshot.authority), "normal, reduced, skip, and resume traces preserve identical final authority")
			require(JSON.stringify(_receipt_from_snapshot(normal_snapshot)) == JSON.stringify(_receipt_from_snapshot(skipped_snapshot)) and JSON.stringify(_receipt_from_snapshot(normal_snapshot)) == JSON.stringify(_receipt_from_snapshot(reduced_snapshot)) and JSON.stringify(_receipt_from_snapshot(normal_snapshot)) == JSON.stringify(_receipt_from_snapshot(resumed_snapshot)), "normal, reduced, skip, and resume traces preserve identical receipt authority")
	completed_groups += 1
