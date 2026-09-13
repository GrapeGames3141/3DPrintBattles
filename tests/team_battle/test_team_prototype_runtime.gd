extends Node

const Store := preload("res://scripts/team_runtime/team_prototype_store.gd")
const Runtime := preload("res://scripts/team_runtime/team_prototype_runtime.gd")
const CollectionProjection := preload("res://scripts/team_collection/team_collection_projection.gd")
const Bot := preload("res://scripts/team_battle/team_battle_bot.gd")

class FaultBox extends RefCounted:
	var rejected_stage := ""
	var rejected_kind := ""
	var rejected_stages: Array = []
	var mutate_stage := ""
	var mutate_kind := ""
	var mutate_path := ""
	var mutate_text := ""
	var mutated := false

	func allow(stage: String, kind: String) -> bool:
		if not mutated and stage == mutate_stage and kind == mutate_kind and not mutate_path.is_empty():
			var file := FileAccess.open(mutate_path, FileAccess.WRITE)
			file.store_string(mutate_text)
			file.flush()
			file.close()
			mutated = true
		return kind != rejected_kind or (stage != rejected_stage and stage not in rejected_stages)

var failures: Array[String] = []
var require_count := 0
var groups := 0
var fixture_root := ""


func require(value: bool, message: String) -> void:
	require_count += 1
	if not value:
		failures.append(message)
		push_error(message)


func _ready() -> void:
	fixture_root = _adapter_fixture_root()
	_test_zero_write_and_recovery()
	_test_checked_atomic_store_faults()
	_test_collection_profile_boundary()
	_test_match_reload_reward_and_generations()
	_test_weak_disposal()
	require(groups == 5, "all adapter test groups complete")
	print("TEAM_PROTOTYPE_RUNTIME requires=%d groups=%d failures=%d" % [require_count, groups, failures.size()])
	print("TEAM_PROTOTYPE_RUNTIME failures=%d" % failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)


func _compatibility() -> Dictionary:
	return {"compatible": true, "state": "ready", "schema_version": 31, "supported_schema": 31, "message": ""}


func _profile() -> Dictionary:
	return {"schema_version": 31, "owned_blueprints": {}, "owned_cards": {}, "printed_models": {}, "preserve": "adapter-fixture"}


func _adapter_fixture_root() -> String:
	var qa_root := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--qa-save-root="):
			qa_root = argument.trim_prefix("--qa-save-root=")
	var root := qa_root.get_base_dir().path_join("adapter-fixtures")
	DirAccess.make_dir_recursive_absolute(root)
	return root


func _case_path(name: String) -> String:
	var directory := fixture_root.path_join(name)
	DirAccess.make_dir_recursive_absolute(directory)
	return directory.path_join("profile.json")


func _write_json(path: String, value: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value))
	file.flush()
	file.close()


func _write_text(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(value)
	file.flush()
	file.close()


func _text(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func _sidecar(path: String, suffix: String) -> String:
	return "%s.%s.json" % [path.get_basename(), suffix]


func _open_runtime(path: String, fault: Callable = Callable()) -> Dictionary:
	return Runtime.open(path, _compatibility(), fault)


func _applied_runtime(path: String, fault: Callable = Callable()) -> Dictionary:
	if not FileAccess.file_exists(path):
		_write_json(path, _profile())
	var opened := _open_runtime(path, fault)
	if not bool(opened.get("ok", false)) or not str(opened.get("recovery", "")).is_empty():
		return {}
	var runtime: Variant = opened.runtime
	var chosen: Dictionary = runtime.collection_request("choose_starter", "adapter-choose", {"starter_id": "cinderpaw"})
	if not bool(chosen.get("ok", false)):
		return {}
	var begun: Dictionary = runtime.collection_request("begin_starter_print", "adapter-begin", {})
	if not bool(begun.get("ok", false)):
		return {}
	var completed: Dictionary = runtime.collection_request("complete_starter_print", "adapter-complete", {"print_id": str(begun.result.print_id)})
	if not bool(completed.get("ok", false)):
		return {}
	var acknowledged: Dictionary = runtime.collection_request("acknowledge_grant", "adapter-ack", {"receipt_id": str(completed.result.receipt_id)})
	if not bool(acknowledged.get("ok", false)):
		return {}
	var team := ["cinderpaw", "aquafin", "mossmunk"]
	var applied: Dictionary = runtime.collection_request("apply_loadout", "adapter-apply", {"team": team, "priority": team, "kit": CollectionProjection.recommended_kit_counts()})
	return {"runtime": runtime, "applied": applied}


func _test_zero_write_and_recovery() -> void:
	var clean_path := _case_path("zero-open")
	var opened := _open_runtime(clean_path)
	require(bool(opened.get("ok", false)) and str(opened.get("recovery", "")).is_empty(), "missing explicit files open clean in memory")
	require(not FileAccess.file_exists(clean_path) and not FileAccess.file_exists(_sidecar(clean_path, "team-match")) and not FileAccess.file_exists(_sidecar(clean_path, "team-cursor")), "open performs zero file writes")
	var null_path := _case_path("null-profile")
	_write_text(null_path, "null")
	var null_open := _open_runtime(null_path)
	require(bool(null_open.get("ok", false)) and str(null_open.get("recovery", "")) == "profile_null", "present null profile is distinct read-only recovery")
	var future_path := _case_path("future-profile")
	_write_json(future_path, {"schema_version": 32})
	var future_open := _open_runtime(future_path)
	require(bool(future_open.get("ok", false)) and str(future_open.get("recovery", "")) == "profile_future", "future profile is read-only recovery")
	var backup_path := _case_path("backup-profile")
	_write_json("%s.backup.json" % backup_path.get_basename(), _profile())
	var backup_open := _open_runtime(backup_path)
	require(bool(backup_open.get("ok", false)) and str(backup_open.get("recovery", "")) == "profile_backup_read_only", "valid backup with missing primary stays read-only")
	var orphan_path := _case_path("orphan-ledger")
	_write_json(_sidecar(orphan_path, "team-match"), {"version": 1, "next_match_sequence": 1, "current": {}, "starts": {}, "rewards": {}, "coins": 0, "xp": 0})
	var orphan_open := _open_runtime(orphan_path)
	require(bool(orphan_open.get("ok", false)) and str(orphan_open.get("recovery", "")) == "orphaned_prototype_evidence", "missing profile with prototype sidecar is never paired to a clean install")
	var null_ledger_path := _case_path("null-ledger")
	_write_json(null_ledger_path, _profile())
	_write_text(_sidecar(null_ledger_path, "team-match"), "null")
	var null_ledger_open := _open_runtime(null_ledger_path)
	require(bool(null_ledger_open.get("ok", false)) and str(null_ledger_open.get("recovery", "")) == "ledger_null", "present null ledger is distinct recovery")
	var future_ledger_path := _case_path("future-ledger")
	_write_json(future_ledger_path, _profile())
	_write_json(_sidecar(future_ledger_path, "team-match"), {"version": 2})
	var future_ledger_open := _open_runtime(future_ledger_path)
	require(bool(future_ledger_open.get("ok", false)) and str(future_ledger_open.get("recovery", "")) == "ledger_future", "future ledger is distinct recovery")
	var bad_cursor_path := _case_path("bad-cursor")
	_write_json(bad_cursor_path, _profile())
	_write_json(_sidecar(bad_cursor_path, "team-cursor"), {"wrong": true})
	var bad_cursor_open := _open_runtime(bad_cursor_path)
	require(bool(bad_cursor_open.get("ok", false)) and str(bad_cursor_open.get("recovery", "")) == "cursor_corrupt", "malformed cursor rejects without reset")
	var backup_ledger_path := _case_path("backup-ledger")
	_write_json(backup_ledger_path, _profile())
	_write_json("%s.backup.json" % _sidecar(backup_ledger_path, "team-match").get_basename(), {"version": 1, "next_match_sequence": 1, "current": {}, "starts": {}, "rewards": {}, "coins": 0, "xp": 0})
	var backup_ledger_open := _open_runtime(backup_ledger_path)
	require(bool(backup_ledger_open.get("ok", false)) and str(backup_ledger_open.get("recovery", "")) == "ledger_sidecar_evidence", "sidecar backup without primary is read-only, not an empty ledger")
	var orphan_cursor_path := _case_path("orphan-cursor")
	_write_json(orphan_cursor_path, _profile())
	_write_json(_sidecar(orphan_cursor_path, "team-cursor"), {"match_id": "tp-match-1", "authority_revision": 1, "request_id": "run-1", "receipt_hash": "0".repeat(64), "next_cursor": 0})
	var orphan_cursor_open := _open_runtime(orphan_cursor_path)
	require(bool(orphan_cursor_open.get("ok", false)) and str(orphan_cursor_open.get("recovery", "")) == "cursor_orphan", "valid cursor without ledger/current is explicit recovery")
	var unsafe_open := Runtime.open(_case_path("unsafe-compat"), {"compatible": false, "state": "ready", "message": ""})
	require(not bool(unsafe_open.get("ok", false)), "unsafe compatibility rejects before creating sessions or files")
	groups += 1


func _test_checked_atomic_store_faults() -> void:
	for stage in ["temp_open", "temp_write", "temp_validate", "backup", "primary_promotion", "post_read"]:
		var path := _case_path("fault-%s" % stage)
		_write_json(path, _profile())
		var fault := FaultBox.new()
		fault.rejected_stage = stage
		fault.rejected_kind = "profile"
		var opened := Store.open(path, _compatibility(), Callable(fault, "allow"))
		require(bool(opened.get("ok", false)), "%s fault fixture opens" % stage)
		if not bool(opened.get("ok", false)):
			continue
		var before := _text(path)
		var candidate := _profile()
		candidate["fault_stage"] = stage
		require(not opened.store.commit_profile(candidate), "%s injected failure rejects profile commit" % stage)
		require(_text(path) == before, "%s failure preserves prior primary bytes" % stage)
	var rollback_path := _case_path("fault-rollback")
	_write_json(rollback_path, _profile())
	var rollback_fault := FaultBox.new()
	rollback_fault.rejected_stage = "rollback"
	rollback_fault.rejected_kind = "profile"
	var rollback_open := Store.open(rollback_path, _compatibility(), Callable(rollback_fault, "allow"))
	var rollback_candidate := _profile()
	rollback_candidate["fault_stage"] = "rollback"
	if bool(rollback_open.get("ok", false)):
		rollback_fault.rejected_stages = ["post_read", "rollback"]
		require(not rollback_open.store.commit_profile(rollback_candidate), "post-promotion failure rejects when rollback path is injected")
		require(not str(rollback_open.store.recovery_state()).is_empty(), "rollback failure leaves explicit recovery state")
	var first_path := _case_path("fault-first-promotion")
	var first_fault := FaultBox.new()
	first_fault.rejected_stage = "post_read"
	first_fault.rejected_kind = "profile"
	var first_open := Store.open(first_path, _compatibility(), Callable(first_fault, "allow"))
	if bool(first_open.get("ok", false)):
		require(not first_open.store.commit_profile(_profile()), "first promotion post-read failure is not accepted")
		require(not str(first_open.store.recovery_state()).is_empty(), "first promotion uncertainty freezes the open store")
		var first_reopen := _open_runtime(first_path)
		require(bool(first_reopen.get("ok", false)) and not str(first_reopen.get("recovery", "")).is_empty(), "first promotion failure remains recovery after reopen")
	var cursor_race_path := _case_path("cursor-promotion-race")
	_write_json(cursor_race_path, _profile())
	_write_json(_sidecar(cursor_race_path, "team-match"), {"version": 1, "next_match_sequence": 1, "current": {}, "starts": {}, "rewards": {}, "coins": 0, "xp": 0})
	var cursor_fault := FaultBox.new()
	cursor_fault.mutate_stage = "temp_validate"
	cursor_fault.mutate_kind = "cursor"
	cursor_fault.mutate_path = _sidecar(cursor_race_path, "team-match")
	cursor_fault.mutate_text = _text(cursor_fault.mutate_path) + "\n"
	var cursor_store_open := Store.open(cursor_race_path, _compatibility(), Callable(cursor_fault, "allow"))
	if bool(cursor_store_open.get("ok", false)):
		var cursor_candidate := {"match_id": "tp-match-1", "authority_revision": 1, "request_id": "run-1", "receipt_hash": "0".repeat(64), "next_cursor": 0}
		require(not cursor_store_open.store.commit_cursor(cursor_candidate, ["ledger"]) and cursor_fault.mutated and not FileAccess.file_exists(_sidecar(cursor_race_path, "team-cursor")), "ledger generation is rechecked inside cursor promotion")
	var retry_path := _case_path("repeat-failed-retry")
	_write_json(retry_path, _profile())
	var retry_fault := FaultBox.new()
	retry_fault.rejected_stage = "temp_write"
	retry_fault.rejected_kind = "profile"
	var retry_open := Store.open(retry_path, _compatibility(), Callable(retry_fault, "allow"))
	var retry_candidate := _profile()
	retry_candidate["retry"] = true
	if bool(retry_open.get("ok", false)):
		require(not retry_open.store.commit_profile(retry_candidate) and not retry_open.store.commit_profile(retry_candidate), "identical failed retries preserve each temporary attempt without publishing")
		retry_fault.rejected_stage = ""
		require(retry_open.store.commit_profile(retry_candidate), "later identical retry promotes after preserving failed evidence")
	var staging_path := _case_path("backup-stage-retry")
	_write_json(staging_path, _profile())
	var staging_open := Store.open(staging_path, _compatibility())
	if bool(staging_open.get("ok", false)):
		_write_text(str(staging_open.store.paths().profile.backup_stage), "stale backup staging evidence")
		var staging_candidate := _profile()
		staging_candidate["staging"] = true
		require(staging_open.store.commit_profile(staging_candidate) and not FileAccess.file_exists(str(staging_open.store.paths().profile.backup_stage)), "known failed backup staging rotates safely before a live retry")
	var restore_path := _case_path("restore-evidence")
	_write_json(restore_path, _profile())
	_write_text("%s.restore" % restore_path, "partial restore staging evidence")
	var restore_open := _open_runtime(restore_path)
	require(bool(restore_open.get("ok", false)) and str(restore_open.get("recovery", "")) == "profile_staging_evidence", "restore staging evidence blocks a fresh open")
	var promotion_race_path := _case_path("promotion-hook-race")
	_write_json(promotion_race_path, _profile())
	var promotion_fault := FaultBox.new()
	promotion_fault.mutate_stage = "primary_promotion"
	promotion_fault.mutate_kind = "profile"
	promotion_fault.mutate_path = promotion_race_path
	promotion_fault.mutate_text = JSON.stringify({"schema_version": 31, "owned_blueprints": {}, "owned_cards": {}, "printed_models": {}, "external": "promotion-hook"})
	var promotion_open := Store.open(promotion_race_path, _compatibility(), Callable(promotion_fault, "allow"))
	if bool(promotion_open.get("ok", false)):
		var promotion_candidate := _profile()
		promotion_candidate["candidate"] = true
		require(not promotion_open.store.commit_profile(promotion_candidate) and promotion_fault.mutated and JSON.parse_string(_text(promotion_race_path)).get("external", "") == "promotion-hook", "generation is rechecked immediately after the promotion hook")
	groups += 1


func _test_collection_profile_boundary() -> void:
	var path := _case_path("starter-boundary")
	var made := _applied_runtime(path)
	require(not made.is_empty() and bool(made.applied.get("ok", false)), "five explicit starter-to-Applied collection actions persist")
	if made.is_empty():
		return
	var runtime: Variant = made.runtime
	var projection: Dictionary = runtime.view().collection
	require(int(projection.namespace_revision) == 5 and not projection.saved_loadout.is_empty(), "Applied collection is projected without exposing raw request history")
	var duplicate_choose: Dictionary = runtime.collection_request("choose_starter", "adapter-choose", {"starter_id": "cinderpaw"})
	require(bool(duplicate_choose.get("ok", false)) and bool(duplicate_choose.get("duplicate", false)), "accepted collection request retries use immutable original freshness after later actions")
	var narrow: Dictionary = runtime.collection_view()
	require(bool(narrow.get("ok", false)) and int(narrow.printed_counts.cinderpaw) == 1 and int(narrow.support_counts.raw_filament) == 3 and str(narrow.voucher.state) == "acknowledged" and not narrow.has("requests"), "narrow collection view exposes voucher and ownership without raw request history")
	var preview: Dictionary = runtime.preview_loadout(["cinderpaw", "aquafin", "mossmunk"], ["cinderpaw", "aquafin", "mossmunk"], CollectionProjection.recommended_kit_counts())
	require(bool(preview.get("ok", false)) and int(preview.writes) == 0, "loadout preview delegates without a profile write")
	require(FileAccess.file_exists(path) and not FileAccess.file_exists(_sidecar(path, "team-match")) and not FileAccess.file_exists(_sidecar(path, "team-cursor")), "collection actions write only explicit profile primary")
	var raw: Dictionary = JSON.parse_string(_text(path))
	require(str(raw.preserve) == "adapter-fixture" and raw.has("team_prototype"), "profile write preserves unknown legacy fields while adding prototype namespace")
	groups += 1


func _test_match_reload_reward_and_generations() -> void:
	var stale_path := _case_path("stale-start")
	var stale_made := _applied_runtime(stale_path)
	require(not stale_made.is_empty(), "stale Start fixture reaches Applied loadout")
	if not stale_made.is_empty():
		var stale_runtime: Variant = stale_made.runtime
		var externally_changed: Dictionary = JSON.parse_string(_text(stale_path))
		externally_changed["external"] = "changed"
		_write_json(stale_path, externally_changed)
		var stale_start: Dictionary = stale_runtime.start("stale-start", 1, 2)
		require(not bool(stale_start.get("ok", false)) and not FileAccess.file_exists(_sidecar(stale_path, "team-match")), "external profile change rejects Start before ledger write")
	var start_race_path := _case_path("start-promotion-race")
	_write_json(start_race_path, _profile())
	var start_fault := FaultBox.new()
	start_fault.mutate_stage = "temp_validate"
	start_fault.mutate_kind = "ledger"
	start_fault.mutate_path = start_race_path
	start_fault.mutate_text = JSON.stringify({"schema_version": 31, "owned_blueprints": {}, "owned_cards": {}, "printed_models": {}, "external": "during-start"})
	var start_race_open := _open_runtime(start_race_path, Callable(start_fault, "allow"))
	if bool(start_race_open.get("ok", false)) and str(start_race_open.get("recovery", "")).is_empty():
		var race_runtime: Variant = start_race_open.runtime
		var race_choose: Dictionary = race_runtime.collection_request("choose_starter", "race-choose", {"starter_id": "cinderpaw"})
		var race_begin: Dictionary = race_runtime.collection_request("begin_starter_print", "race-begin", {})
		var race_complete: Dictionary = race_runtime.collection_request("complete_starter_print", "race-complete", {"print_id": str(race_begin.get("result", {}).get("print_id", ""))})
		var race_apply: Dictionary = race_runtime.collection_request("apply_loadout", "race-apply", {"team": ["cinderpaw", "aquafin", "mossmunk"], "priority": ["cinderpaw", "aquafin", "mossmunk"], "kit": CollectionProjection.recommended_kit_counts()})
		var race_start: Dictionary = race_runtime.start("race-start", 1, 2)
		require(bool(race_choose.get("ok", false)) and bool(race_begin.get("ok", false)) and bool(race_complete.get("ok", false)) and bool(race_apply.get("ok", false)) and not bool(race_start.get("ok", false)) and start_fault.mutated, "profile generation is rechecked inside Start promotion")
	var path := _case_path("match-reload")
	var made := _applied_runtime(path)
	require(not made.is_empty(), "match fixture reaches Applied loadout")
	if made.is_empty():
		return
	var runtime: Variant = made.runtime
	var profile_before_start := _text(path)
	var started: Dictionary = runtime.start("adapter-start", 1, 2)
	require(bool(started.get("ok", false)) and FileAccess.file_exists(_sidecar(path, "team-match")) and _text(path) == profile_before_start, "Start writes only ledger after rechecking profile and ledger generations")
	if not bool(started.get("ok", false)):
		return
	var match_id := str(started.match_id)
	var first_view: Dictionary = runtime.view().match.player
	var first_plan: Dictionary = Bot.choose_plan(first_view).plan
	var first_run: Dictionary = runtime.run_cycle(match_id, "adapter-run-1", first_plan)
	require(bool(first_run.get("ok", false)), "real Coordinator Run persists through ledger callback")
	if bool(first_run.get("ok", false)):
		var ack: Dictionary = runtime.acknowledge(match_id, "adapter-run-1", int(first_run.cursor))
		require(bool(ack.get("ok", false)) and FileAccess.file_exists(_sidecar(path, "team-cursor")), "cursor acknowledgement writes only cursor sidecar")
		var reloaded: Dictionary = _open_runtime(path)
		require(bool(reloaded.get("ok", false)) and str(reloaded.get("recovery", "")).is_empty() and bool(reloaded.runtime.view().match.resume), "ledger and cursor JSON reload resume the pending match")
		var externally_changed_ledger := _text(_sidecar(path, "team-match")) + "\n"
		_write_text(_sidecar(path, "team-match"), externally_changed_ledger)
		var stale_cursor: Dictionary = runtime.acknowledge(match_id, "adapter-run-1", int(ack.cursor))
		require(not bool(stale_cursor.get("ok", false)), "external ledger generation change rejects cursor sidecar write")
	var terminal_path := _case_path("terminal")
	var terminal_made := _applied_runtime(terminal_path)
	require(not terminal_made.is_empty(), "terminal fixture reaches Applied loadout")
	if terminal_made.is_empty():
		return
	var terminal_runtime: Variant = terminal_made.runtime
	var terminal_start: Dictionary = terminal_runtime.start("terminal-start", 1, 2)
	var final_request := ""
	var final_plan: Dictionary = {}
	var terminal := false
	if bool(terminal_start.get("ok", false)):
		for cycle in range(1, 80):
			var match_view: Dictionary = terminal_runtime.view().match.player
			if not str(match_view.result).is_empty():
				terminal = true
				break
			var chosen: Dictionary = Bot.choose_plan(match_view)
			final_request = "adapter-terminal-%d" % cycle
			final_plan = chosen.plan.duplicate(true)
			var run: Dictionary = terminal_runtime.run_cycle(str(terminal_start.match_id), final_request, final_plan)
			if not bool(run.get("ok", false)):
				break
			var skipped: Dictionary = terminal_runtime.skip(str(terminal_start.match_id), final_request, int(run.cursor))
			if not bool(skipped.get("ok", false)):
				break
		terminal = not str(terminal_runtime.view().match.player.result).is_empty()
	require(terminal, "one complete deterministic production match reaches terminal authority through synthetic files")
	if terminal:
		var reward_before := JSON.stringify(terminal_runtime.current_result())
		var replay: Dictionary = terminal_runtime.run_cycle(str(terminal_start.match_id), final_request, final_plan)
		require(bool(replay.get("ok", false)) and JSON.stringify(terminal_runtime.current_result()) == reward_before, "terminal replay is reward-once and zero-grant")
		var reload_terminal: Dictionary = _open_runtime(terminal_path)
		require(bool(reload_terminal.get("ok", false)) and JSON.stringify(reload_terminal.runtime.current_result()) == reward_before, "terminal reward survives reload only in ledger authority")
		var reordered := ["aquafin", "cinderpaw", "mossmunk"]
		var reapply: Dictionary = terminal_runtime.collection_request("apply_loadout", "terminal-reapply", {"team": reordered, "priority": reordered, "kit": CollectionProjection.recommended_kit_counts()})
		require(bool(reapply.get("ok", false)), "future Team Apply persists after terminal presentation")
		var old_start: Dictionary = terminal_runtime.start("terminal-start", 1, 2)
		require(bool(old_start.get("ok", false)) and bool(old_start.get("duplicate", false)) and str(old_start.match_id) == str(terminal_start.match_id), "historical Start retry remains original after a future Team Apply")
	groups += 1


func _test_weak_disposal() -> void:
	var path := _case_path("weak-disposal")
	var opened := _open_runtime(path)
	require(bool(opened.get("ok", false)), "weak callback fixture opens")
	if bool(opened.get("ok", false)):
		var runtime: Variant = opened.runtime
		var weak: WeakRef = weakref(runtime)
		runtime.close()
		opened = {}
		runtime = null
		require(weak.get_ref() == null, "runtime close releases weak callback owner without a persistence cycle")
	groups += 1
