extends Node

const CollectionSession := preload("res://scripts/team_collection/team_collection_session.gd")
const CollectionProjection := preload("res://scripts/team_collection/team_collection_projection.gd")
const MatchSession := preload("res://scripts/team_runtime/team_match_session.gd")
const Bot := preload("res://scripts/team_battle/team_battle_bot.gd")

var failures: Array[String] = []
var require_count := 0
var groups := 0
var ledger_writes: Array = []
var cursor_writes: Array = []
var reject_ledger := false
var reject_terminal_write := false
var reject_cursor_after := -1


func require(value: bool, message: String) -> void:
	require_count += 1
	if not value:
		failures.append(message)
		push_error(message)


func _ready() -> void:
	_test_creation_and_start_idempotency()
	_test_run_cursor_and_store_rollback()
	_test_ledger_rejection_surface()
	_test_real_terminal_reward_settlement()
	_test_sequence_two_fixed_outcomes()
	_test_collection_refresh_and_weak_lifetime()
	require(groups == 6, "all match-session test groups reach completion")
	print("TEAM_MATCH_SESSION requires=%d failures=%d" % [require_count, failures.size()])
	print("TEAM_MATCH_SESSION failures=%d" % failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)


func _profile() -> Dictionary:
	return {"schema_version": 31, "owned_blueprints": {}, "owned_cards": {}, "printed_models": {}}


func _collection_store(candidate: Dictionary) -> bool:
	return true


func _make_applied_profile(starter_id: String = "cinderpaw") -> Dictionary:
	var created := CollectionSession.create(_profile(), Callable(self, "_collection_store"))
	if not bool(created.get("ok", false)):
		return {}
	var collection: Variant = created.session
	for action_value in [
		["choose_starter", "m2-choose", {"starter_id": starter_id}],
		["begin_starter_print", "m2-begin", {}],
	]:
		var projection: Dictionary = collection.project()
		var requested: Variant = collection.request(action_value[0], action_value[1], projection.namespace_revision, projection.fingerprint, action_value[2])
		if not bool(requested.get("ok", false)):
			return {}
	var begun_projection: Dictionary = collection.project()
	var begin_record: Dictionary = begun_projection.prototype_state.requests["m2-begin"].result
	var completed: Variant = collection.request("complete_starter_print", "m2-complete", begun_projection.namespace_revision, begun_projection.fingerprint, {"print_id": str(begin_record.print_id)})
	if not bool(completed.get("ok", false)):
		return {}
	var ownership: Dictionary = collection.project()
	var team: Array = [starter_id] + CollectionProjection.GUARANTEES[starter_id].duplicate()
	var applied: Variant = collection.request("apply_loadout", "m2-apply", ownership.namespace_revision, ownership.fingerprint, {"team": team, "priority": team.duplicate(), "kit": CollectionProjection.recommended_kit_counts()})
	return collection.snapshot() if bool(applied.get("ok", false)) else {}


func _persist_ledger(candidate: Dictionary) -> bool:
	if reject_ledger:
		return false
	if reject_terminal_write and not str(candidate.get("current", {}).get("authority", {}).get("result", "")).is_empty():
		return false
	ledger_writes.append(candidate.duplicate(true))
	return true


func _persist_cursor(candidate: Dictionary) -> bool:
	if reject_cursor_after >= 0 and cursor_writes.size() >= reject_cursor_after:
		return false
	cursor_writes.append(candidate.duplicate(true))
	return true


func _persist_nonliteral(candidate: Dictionary) -> Variant:
	return 1


func _new_session(profile: Dictionary, ledger_exists: bool = false, ledger: Variant = null, cursor: Variant = null) -> Dictionary:
	ledger_writes.clear()
	cursor_writes.clear()
	reject_ledger = false
	reject_terminal_write = false
	reject_cursor_after = -1
	return MatchSession.create(profile, "ready", ledger_exists, ledger, cursor, Callable(self, "_persist_ledger"), Callable(self, "_persist_cursor"))


func _start(session: Variant, request_id: String, seed: int = 0) -> Dictionary:
	var projection: Dictionary = CollectionProjection.project(_make_applied_profile())
	return session.start(request_id, int(session.snapshot().next_match_sequence), projection.namespace_revision, projection.fingerprint, seed)


func _test_creation_and_start_idempotency() -> void:
	var applied := _make_applied_profile()
	require(not applied.is_empty(), "Applied collection fixture completes")
	var missing := _new_session(applied)
	require(bool(missing.get("ok", false)) and ledger_writes.is_empty(), "missing ledger creates read-only empty in-memory match ledger")
	if not bool(missing.get("ok", false)):
		return
	var session: Variant = missing.session
	var raw_before := JSON.stringify(applied)
	var projection: Dictionary = CollectionProjection.project(applied)
	var started: Variant = session.start("match-start-0", 1, projection.namespace_revision, projection.fingerprint, 0)
	require(bool(started.get("ok", false)) and ledger_writes.size() == 1, "Start persists one atomic Coordinator and history ledger")
	if bool(started.get("ok", false)):
		require(JSON.stringify(applied) == raw_before, "Start never mutates the caller-owned raw profile")
		require(started.start.rival_priority == ["cinderpaw", "aquafin", "mossmunk"] and bool(started.start.tutorial_opening), "seed residue zero maps the fixed rival priority and tutorial opening")
		var duplicate: Variant = session.start("match-start-0", 1, projection.namespace_revision, projection.fingerprint, 0)
		require(bool(duplicate.get("ok", false)) and bool(duplicate.duplicate) and ledger_writes.size() == 1, "exact historical Start replay is zero-write")
		var changed: Variant = session.start("match-start-0", 1, projection.namespace_revision, projection.fingerprint, 1)
		require(not bool(changed.get("ok", false)), "changed Start request identity rejects")
		var blocked: Variant = session.start("match-start-1", 2, projection.namespace_revision, projection.fingerprint, 1)
		require(not bool(blocked.get("ok", false)), "unfinished match blocks replacement Start")
	var rejected := _new_session(applied)
	if bool(rejected.get("ok", false)):
		reject_ledger = true
		var rollback: Variant = rejected.session.start("rollback-start", 1, projection.namespace_revision, projection.fingerprint, 1)
		require(not bool(rollback.get("ok", false)) and int(rejected.session.snapshot().next_match_sequence) == 1 and rejected.session.snapshot().current.is_empty(), "failed Start store leaves sequence and current authority unchanged")
	var nonliteral_created := MatchSession.create(applied, "ready", false, null, null, Callable(self, "_persist_nonliteral"), Callable(self, "_persist_cursor"))
	if bool(nonliteral_created.get("ok", false)):
		var nonliteral_start: Variant = nonliteral_created.session.start("nonliteral-start", 1, projection.namespace_revision, projection.fingerprint, 1)
		require(not bool(nonliteral_start.get("ok", false)) and int(nonliteral_created.session.snapshot().next_match_sequence) == 1, "only literal Boolean true publishes a Start ledger candidate")
	groups += 1


func _test_run_cursor_and_store_rollback() -> void:
	var applied := _make_applied_profile()
	var made := _new_session(applied)
	require(bool(made.get("ok", false)), "run fixture creates")
	if not bool(made.get("ok", false)):
		return
	var session: Variant = made.session
	var projection: Dictionary = CollectionProjection.project(applied)
	var started: Variant = session.start("run-start", 1, projection.namespace_revision, projection.fingerprint, 1)
	require(bool(started.get("ok", false)), "run fixture Start succeeds")
	if not bool(started.get("ok", false)):
		return
	var player_view: Dictionary = session.view().player
	var player_plan := {
		"expected_revision": int(player_view.revision),
		"fabrication_id": "",
		"support_copy_id": "",
		"equipment_target_id": "",
		"swap_id": "",
	}
	var failed_run := _new_session(applied)
	if bool(failed_run.get("ok", false)):
		var failed_start: Variant = failed_run.session.start("run-rollback-start", 1, projection.namespace_revision, projection.fingerprint, 1)
		if bool(failed_start.get("ok", false)):
			var before_run := JSON.stringify(failed_run.session.snapshot())
			reject_ledger = true
			var rejected_run: Variant = failed_run.session.run_cycle(str(failed_start.match_id), "run-rollback", player_plan)
			require(not bool(rejected_run.get("ok", false)) and JSON.stringify(failed_run.session.snapshot()) == before_run, "failed nonterminal Run store leaves authority and ledger unchanged")
			reject_ledger = false
			var retry_run: Variant = failed_run.session.run_cycle(str(failed_start.match_id), "run-rollback", player_plan)
			require(bool(retry_run.get("ok", false)), "identical nonterminal Run retries after rejected store")
	var ledger_before_primary_run := ledger_writes.size()
	var run: Variant = session.run_cycle(str(started.match_id), "run-one", player_plan)
	require(bool(run.get("ok", false)) and ledger_writes.size() == ledger_before_primary_run + 1, "Run stores both Plans and next authority in one ledger write")
	if bool(run.get("ok", false)):
		var replay: Variant = session.run_cycle(str(started.match_id), "run-one", player_plan.duplicate(true))
		require(bool(replay.get("ok", false)) and ledger_writes.size() == ledger_before_primary_run + 1, "duplicate Run uses stored rival Plan and is zero-write")
		var changed_plan: Dictionary = player_plan.duplicate(true)
		changed_plan.expected_revision = int(changed_plan.expected_revision) + 1
		var changed: Variant = session.run_cycle(str(started.match_id), "run-one", changed_plan)
		require(not bool(changed.get("ok", false)), "changed duplicate Run payload rejects")
		var ack: Variant = session.acknowledge(str(started.match_id), "run-one", 0)
		require(bool(ack.get("ok", false)) and cursor_writes.size() == 1 and ledger_writes.size() == ledger_before_primary_run + 1, "acknowledgement writes only current small cursor checkpoint")
		var saved_json: Variant = JSON.parse_string(JSON.stringify(session.snapshot()))
		var cursor_json: Variant = JSON.parse_string(JSON.stringify(cursor_writes[0]))
		var reload := MatchSession.create(applied, "ready", true, saved_json, cursor_json, Callable(self, "_persist_ledger"), Callable(self, "_persist_cursor"))
		require(bool(reload.get("ok", false)) and int(reload.session.view().presentation.cursor) == 1, "JSON-equivalent current ledger and matching cursor restore the same pending receipt")
		var invalid_cursor: Dictionary = cursor_json.duplicate(true)
		invalid_cursor.authority_revision = int(invalid_cursor.authority_revision) + 1
		var rejected_reload := MatchSession.create(applied, "ready", true, session.snapshot(), invalid_cursor, Callable(self, "_persist_ledger"), Callable(self, "_persist_cursor"))
		require(not bool(rejected_reload.get("ok", false)), "invalid current cursor fails closed on reload")
		var altered_origin: Dictionary = saved_json.duplicate(true)
		altered_origin.current.origin_state.seed = int(altered_origin.current.origin_state.seed) + 1
		require(not bool(MatchSession.create(applied, "ready", true, altered_origin, cursor_json, Callable(self, "_persist_ledger"), Callable(self, "_persist_cursor")).get("ok", false)), "valid-shaped Coordinator origin modified from immutable Start rejects")
		reject_cursor_after = cursor_writes.size() + 2
		var partial_skip: Variant = session.skip(str(started.match_id), "run-one", 1)
		require(not bool(partial_skip.get("ok", false)) and int(session.view().presentation.cursor) == 3 and ledger_writes.size() == ledger_before_primary_run + 1, "failed later Skip preserves two successfully persisted cursor advances without a ledger write")
		var pending: Dictionary = session.pending_receipt()
		require(bool(pending.get("ok", false)) and JSON.stringify(pending).find("rival:card:") < 0, "pending receipt exposes only the player projection")
	groups += 1


func _test_ledger_rejection_surface() -> void:
	var applied := _make_applied_profile()
	var null_ledger := _new_session(applied, true, null)
	require(not bool(null_ledger.get("ok", false)), "present null ledger fails closed")
	var future := {"version": 2, "next_match_sequence": 1, "current": {}, "starts": {}, "rewards": {}, "coins": 0, "xp": 0}
	var future_ledger := _new_session(applied, true, future)
	require(not bool(future_ledger.get("ok", false)), "future ledger version fails closed")
	var malformed_cursor := _new_session(applied, false, null, {"wrong": true})
	require(not bool(malformed_cursor.get("ok", false)), "cursor without a current match fails closed")
	var version_bool := {"version": true, "next_match_sequence": 1, "current": {}, "starts": {}, "rewards": {}, "coins": 0, "xp": 0}
	require(not bool(_new_session(applied, true, version_bool).get("ok", false)), "Boolean ledger version never coerces to version one")
	var version_string := {"version": "1", "next_match_sequence": 1, "current": {}, "starts": {}, "rewards": {}, "coins": 0, "xp": 0}
	require(not bool(_new_session(applied, true, version_string).get("ok", false)), "String ledger version never coerces to version one")
	var current_without_start := {"version": 1, "next_match_sequence": 1, "current": {"match_id": "tp-match-1"}, "starts": {}, "rewards": {}, "coins": 0, "xp": 0}
	require(not bool(_new_session(applied, true, current_without_start).get("ok", false)), "current ledger without Start history fails without an index error")
	var production_compat := {"compatible": true, "state": "ready", "schema_version": 31, "supported_schema": 31, "message": ""}
	require(bool(MatchSession.create(applied, production_compat, false, null, null, Callable(self, "_persist_ledger"), Callable(self, "_persist_cursor")).get("ok", false)), "literal production compatibility dictionary is accepted")
	var contradictory_compat := {"compatible": true, "state": "future", "message": ""}
	require(not bool(MatchSession.create(applied, contradictory_compat, false, null, null, Callable(self, "_persist_ledger"), Callable(self, "_persist_cursor")).get("ok", false)), "contradictory compatibility dictionary rejects")
	groups += 1


func _test_real_terminal_reward_settlement() -> void:
	var applied := _make_applied_profile()
	var made := _new_session(applied)
	require(bool(made.get("ok", false)), "terminal fixture creates")
	if not bool(made.get("ok", false)):
		return
	var session: Variant = made.session
	var projection: Dictionary = CollectionProjection.project(applied)
	var started: Variant = session.start("terminal-start", 1, projection.namespace_revision, projection.fingerprint, 2)
	require(bool(started.get("ok", false)), "terminal fixture starts")
	if not bool(started.get("ok", false)):
		return
	var terminal := false
	var terminal_store_rejected := false
	var final_request_id := ""
	var final_player_plan: Dictionary = {}
	reject_terminal_write = true
	for cycle in range(1, 80):
		var state_view: Dictionary = session.view().player
		if not str(state_view.result).is_empty():
			terminal = true
			break
		var chosen: Dictionary = Bot.choose_plan(state_view)
		var player_plan: Dictionary = chosen.get("plan", {
			"expected_revision": int(state_view.revision),
			"fabrication_id": "",
			"support_copy_id": "",
			"equipment_target_id": "",
			"swap_id": "",
		})
		final_request_id = "terminal-run-%d" % cycle
		final_player_plan = player_plan.duplicate(true)
		var run: Variant = session.run_cycle(str(started.match_id), final_request_id, player_plan)
		if not bool(run.get("ok", false)):
			terminal_store_rejected = true
			require(session.current_result().is_empty(), "failed terminal store leaves reward wallet unchanged")
			reject_terminal_write = false
			run = session.run_cycle(str(started.match_id), final_request_id, player_plan)
			require(bool(run.get("ok", false)), "same terminal request retries after rejected store")
			if not bool(run.get("ok", false)):
				break
		var skipped: Variant = session.skip(str(started.match_id), final_request_id, int(run.cursor))
		if not bool(skipped.get("ok", false)):
			require(false, "terminal fixture Skip remains legal: %s" % str(skipped.get("error", "unknown error")))
			break
	var result_view: Dictionary = session.view().player
	terminal = terminal or not str(result_view.result).is_empty()
	require(terminal_store_rejected, "terminal store rejection is exercised before exactly-once settlement")
	require(terminal, "real production session reaches a terminal authority through Rules")
	if terminal:
		var ledger: Dictionary = session.snapshot()
		var reward: Dictionary = ledger.rewards.get(str(started.match_id), {})
		var expected: Array = {"Win": [30, 40], "Loss": [10, 20], "Draw": [20, 30]}.get(str(result_view.result), [])
		require(not reward.is_empty() and reward.result == result_view.result and int(reward.coins) == int(expected[0]) and int(reward.xp) == int(expected[1]), "terminal Run stores the fixed result reward atomically")
		var writes_before := ledger_writes.size()
		var cursor_writes_before := cursor_writes.size()
		var wallet_before := JSON.stringify(session.current_result())
		var replay: Variant = session.run_cycle(str(started.match_id), final_request_id, final_player_plan)
		require(bool(replay.get("ok", false)) and ledger_writes.size() == writes_before and cursor_writes.size() == cursor_writes_before and JSON.stringify(session.current_result()) == wallet_before, "exact final Run duplicate preserves its receipt, wallet, and write counts")
		var terminal_view: Dictionary = session.view()
		require(bool(terminal_view.has_current) and not bool(terminal_view.resume) and bool(terminal_view.can_start), "presented terminal match is historical New Battle state, not Resume")
		var historical: Dictionary = session.historical_result(str(started.match_id))
		require(bool(historical.get("ok", false)) and historical.reward == reward, "checked historical result lookup returns the settled immutable receipt")
	groups += 1


func _play_to_terminal(session: Variant, match_id: String, prefix: String) -> String:
	for cycle in range(1, 80):
		var player_view: Dictionary = session.view().player
		if not str(player_view.result).is_empty():
			return str(player_view.result)
		var chosen: Dictionary = Bot.choose_plan(player_view)
		if not bool(chosen.get("ok", false)):
			return ""
		var run: Variant = session.run_cycle(match_id, "%s-run-%d" % [prefix, cycle], chosen.plan)
		if not bool(run.get("ok", false)):
			return ""
		var skipped: Variant = session.skip(match_id, "%s-run-%d" % [prefix, cycle], int(run.cursor))
		if not bool(skipped.get("ok", false)):
			return ""
	return ""


func _test_sequence_two_fixed_outcomes() -> void:
	for fixture in [
		{"seed": 0, "result": "Win"},
		{"seed": 14, "result": "Loss"},
		{"seed": 44, "result": "Draw"},
	]:
		var applied := _make_applied_profile("voltwig" if int(fixture.seed) == 44 else "cinderpaw")
		var made := _new_session(applied)
		require(bool(made.get("ok", false)), "sequence-two %s fixture creates" % fixture.result)
		if not bool(made.get("ok", false)):
			continue
		var session: Variant = made.session
		var projection: Dictionary = CollectionProjection.project(applied)
		var first: Variant = session.start("%s-first" % fixture.result.to_lower(), 1, projection.namespace_revision, projection.fingerprint, 2)
		var first_result := _play_to_terminal(session, str(first.get("match_id", "")), "%s-first" % fixture.result.to_lower()) if bool(first.get("ok", false)) else ""
		require(not first_result.is_empty(), "sequence-one completes before %s ordinary fixture" % fixture.result)
		if first_result.is_empty():
			continue
		var second: Variant = session.start("%s-second" % fixture.result.to_lower(), 2, projection.namespace_revision, projection.fingerprint, int(fixture.seed))
		var actual := _play_to_terminal(session, str(second.get("match_id", "")), "%s-second" % fixture.result.to_lower()) if bool(second.get("ok", false)) else ""
		require(actual == str(fixture.result), "accepted ordinary seed %d settles real %s" % [int(fixture.seed), str(fixture.result)])
		if actual == str(fixture.result):
			var reward: Dictionary = session.current_result()
			require(reward.result == actual and int(reward.coins) == int({"Win": 30, "Loss": 10, "Draw": 20}[actual]) and int(reward.xp) == int({"Win": 40, "Loss": 20, "Draw": 30}[actual]), "%s terminal ledger has exact fixed reward deltas" % actual)
			var old_replay: Variant = session.start("%s-first" % fixture.result.to_lower(), 1, projection.namespace_revision, projection.fingerprint, 2)
			require(bool(old_replay.get("ok", false)) and bool(old_replay.duplicate) and str(old_replay.match_id) == str(first.match_id) and str(session.view().current_match_id) == str(second.match_id), "old Start replay retains its original match identity without replacing current")
	groups += 1


func _test_collection_refresh_and_weak_lifetime() -> void:
	var initial_profile := _make_applied_profile("cinderpaw")
	var made := _new_session(initial_profile)
	require(bool(made.get("ok", false)), "collection-refresh fixture creates")
	if not bool(made.get("ok", false)):
		return
	var session: Variant = made.session
	var initial_projection: Dictionary = CollectionProjection.project(initial_profile)
	var first: Variant = session.start("refresh-first", 1, initial_projection.namespace_revision, initial_projection.fingerprint, 2)
	require(bool(first.get("ok", false)), "collection refresh fixture starts an active frozen match")
	if not bool(first.get("ok", false)):
		return
	var current_before := JSON.stringify(session.snapshot().current)
	var collection_created := CollectionSession.create(initial_profile, Callable(self, "_collection_store"))
	var future_profile := {}
	if bool(collection_created.get("ok", false)):
		var collection: Variant = collection_created.session
		var collection_projection: Dictionary = collection.project()
		var reordered := ["aquafin", "cinderpaw", "mossmunk"]
		var applied_change: Variant = collection.request("apply_loadout", "refresh-apply", collection_projection.namespace_revision, collection_projection.fingerprint, {"team": ["cinderpaw", "aquafin", "mossmunk"], "priority": reordered, "kit": CollectionProjection.recommended_kit_counts()})
		if bool(applied_change.get("ok", false)):
			future_profile = collection.snapshot()
	require(not future_profile.is_empty(), "Collection applies a reordered valid next-match priority")
	var future_projection: Dictionary = CollectionProjection.project(future_profile)
	var refreshed: Variant = session.update_collection(future_profile, {"compatible": true, "state": "ready", "message": ""})
	require(bool(refreshed.get("ok", false)) and JSON.stringify(session.snapshot().current) == current_before, "future Applied Team refresh never mutates the active frozen current match")
	var first_result := _play_to_terminal(session, str(first.get("match_id", "")), "refresh-first")
	require(not first_result.is_empty(), "collection refresh fixture settles its frozen current match")
	if first_result.is_empty():
		return
	if bool(refreshed.get("ok", false)):
		var second: Variant = session.start("refresh-second", 2, future_projection.namespace_revision, future_projection.fingerprint, 0)
		require(bool(second.get("ok", false)) and second.start.player_priority == ["aquafin", "cinderpaw", "mossmunk"], "next Start uses the reordered Applied future priority")
	var lifetime_profile := _make_applied_profile()
	var lifetime_created := _new_session(lifetime_profile)
	require(bool(lifetime_created.get("ok", false)), "weak callback lifetime fixture creates")
	if bool(lifetime_created.get("ok", false)):
		var lifetime_session: Variant = lifetime_created.session
		var lifetime_projection: Dictionary = CollectionProjection.project(lifetime_profile)
		var lifetime_start: Variant = lifetime_session.start("weak-lifetime", 1, lifetime_projection.namespace_revision, lifetime_projection.fingerprint, 1)
		require(bool(lifetime_start.get("ok", false)), "weak callback fixture starts a Coordinator")
		var lifetime_ref: WeakRef = weakref(lifetime_session)
		lifetime_created = {}
		lifetime_session = null
		require(lifetime_ref.get_ref() == null, "Coordinator persistence proxy does not retain its owning MatchSession")
	groups += 1
