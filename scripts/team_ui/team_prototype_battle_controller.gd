class_name TeamPrototypeBattleController
extends RefCounted
## UI-side MatchSession adapter. It owns local selections, frozen request envelopes,
## and the viewer-safe receipt cursor; Rules and persistence remain authoritative.

const Rules := preload("res://scripts/team_battle/team_battle_rules.gd")

var runtime: Variant = null
var match_view: Dictionary = {}
var player_view: Dictionary = {}
var receipt: Dictionary = {}
var cursor := 0
var stage_count := 0
var local_plan: Dictionary = {}
var envelopes: Dictionary = {}
var last_error := ""
var presentation_elapsed := 0.0
var presentation_complete := false
var presentation_paused := false
var _lifecycle_paused := false
var _write_failure_paused := false
var _receipt_identity := ""
var _stage_cache: Dictionary = {}

const STAGE_SECONDS := {
	"Queue":0.25, "Print":1.60, "Awaken":0.55, "Enter/Fit":0.75,
	"Swap":0.60, "Spell":0.40, "AttackLock":0.25, "Damage":0.55,
	"Traits":0.30, "Defeat":0.40, "Replace":0.65,
}


func configure(value: Variant) -> void:
	runtime = value
	refresh()


func refresh() -> Dictionary:
	if runtime == null:
		return _failure("Battle runtime is unavailable.")
	var outer: Dictionary = runtime.view()
	match_view = outer.get("match", {}).duplicate(true)
	player_view = match_view.get("player", {}).duplicate(true)
	var pending: Dictionary = runtime.pending_receipt()
	if not bool(pending.get("ok", false)):
		receipt = {}
		cursor = 0
		stage_count = 0
		_receipt_identity = ""
		_stage_cache = {}
		_write_failure_paused = true
		_sync_presentation_pause()
		last_error = str(pending.get("error", "Receipt projection is unavailable."))
		return _failure(last_error)
	receipt = pending.get("receipt", {}).duplicate(true)
	cursor = int(pending.get("cursor", 0))
	stage_count = int(pending.get("stage_count", 0))
	var receipt_identity := "%s|%s|%d" % [match_id(), receipt_request_id(), cursor]
	if receipt_identity != _receipt_identity:
		_receipt_identity = receipt_identity
		presentation_elapsed = 0.0
		presentation_complete = false
		_cache_current_stage()
	# A durable Run opens the next Plan at a new revision. Keep a local draft only
	# while it still names the same authority boundary; stale card/fabrication IDs
	# must never be carried into that next cycle.
	if not player_view.is_empty() and (local_plan.is_empty() or int(local_plan.get("expected_revision", -1)) != int(player_view.get("revision", -2))):
		_reset_plan()
	return {"ok": not player_view.is_empty() or not match_view.is_empty()}


func can_start() -> bool:
	return bool(match_view.get("can_start", false))


func has_current() -> bool:
	return bool(match_view.get("has_current", false))


func resume_label() -> String:
	if not has_current():
		return "START BATTLE"
	return "RESUME RESULT" if _terminal_pending() else "RESUME BATTLE"


func start_or_resume() -> Dictionary:
	if runtime == null:
		return _failure("Battle runtime is unavailable.")
	if bool(match_view.get("resume", false)):
		refresh()
		return {"ok": true, "resume": true, "match_id": match_id()}
	if not can_start():
		return _failure("Apply a valid Team and Support Kit first.")
	var envelope: Dictionary = _envelope("start", {
		"expected_sequence": int(match_view.get("next_match_sequence", 1)),
		"seed": (int(match_view.get("next_match_sequence", 1)) - 1) % 2147483648,
	})
	var result: Dictionary = runtime.start(str(envelope.id), int(envelope.payload.expected_sequence), int(envelope.payload.seed))
	if bool(result.get("ok", false)):
		envelopes.erase("start")
		last_error = ""
		refresh()
	else:
		last_error = str(result.get("error", "Start could not be saved."))
	return result


func set_fabrication(identity_id: String) -> void:
	if str(local_plan.get("fabrication_id", "")) == identity_id:
		local_plan["fabrication_id"] = ""
	else:
		local_plan["fabrication_id"] = identity_id
	clear_unaccepted_run()


func set_swap(identity_id: String) -> void:
	if str(local_plan.get("swap_id", "")) == identity_id:
		local_plan["swap_id"] = ""
	else:
		local_plan["swap_id"] = identity_id
		local_plan["support_copy_id"] = ""
		local_plan["equipment_target_id"] = ""
	clear_unaccepted_run()


func set_support(copy_id: String) -> void:
	if str(local_plan.get("support_copy_id", "")) == copy_id:
		local_plan["support_copy_id"] = ""
		local_plan["equipment_target_id"] = ""
	else:
		local_plan["support_copy_id"] = copy_id
		local_plan["swap_id"] = ""
		local_plan["equipment_target_id"] = ""
	clear_unaccepted_run()


func set_equipment_target(identity_id: String) -> void:
	local_plan["equipment_target_id"] = identity_id
	clear_unaccepted_run()


func clear_plan() -> void:
	_reset_plan()
	clear_unaccepted_run()


func checked_plan() -> Dictionary:
	if player_view.is_empty():
		return _failure("No player Plan is available.")
	local_plan["expected_revision"] = int(player_view.get("revision", -1))
	return Rules.check_view_plan(player_view, local_plan)


func equipment_targets() -> Array:
	# Equipment is provisional until the player chooses one authoritative target.
	# Validate a target-free baseline so Rules can expose an explicit/default
	# fabrication target rather than rejecting the modal before it exists.
	var baseline := local_plan.duplicate(true)
	baseline["support_copy_id"] = ""
	baseline["equipment_target_id"] = ""
	baseline["swap_id"] = ""
	baseline["expected_revision"] = int(player_view.get("revision", -1))
	var checked: Dictionary = Rules.check_view_plan(player_view, baseline)
	if not bool(checked.get("ok", false)):
		return []
	var copy_id := str(local_plan.get("support_copy_id", ""))
	var card_id := _card_id_for_copy(copy_id)
	if card_id.is_empty():
		return []
	return Rules.eligible_equipment_targets(player_view, card_id, str(checked.plan.get("fabrication_id", "")))


func run_cycle() -> Dictionary:
	if not has_current() or player_view.is_empty():
		return _failure("Start or resume a match before running a cycle.")
	# A successful Run immediately creates a durable receipt. Ignore duplicated
	# physical taps until that receipt has finished; never reinterpret the same tap
	# as a next-cycle request or turn playback into a false save failure.
	if cursor < stage_count:
		return _failure("Finish the current presentation before running another Cycle.")
	var checked: Dictionary = checked_plan()
	if not bool(checked.get("ok", false)):
		last_error = str(checked.get("error", "Review this Plan before running."))
		return checked
	var plan: Dictionary = checked.plan.duplicate(true)
	var envelope: Dictionary = _envelope("run", {"match_id": match_id(), "plan": plan})
	var result: Dictionary = runtime.run_cycle(str(envelope.payload.match_id), str(envelope.id), envelope.payload.plan)
	if bool(result.get("ok", false)):
		envelopes.erase("run")
		last_error = ""
		refresh()
	else:
		last_error = str(result.get("error", "Run Cycle could not be saved."))
	return result


func current_stage() -> Dictionary:
	return _stage_cache.duplicate(true)


func cached_stage() -> Dictionary:
	# Shell updates the passive compositor every frame. It must consume this immutable
	# controller-owned cache rather than deep-copying a receipt snapshot per frame.
	return _stage_cache


func stage_identity() -> String:
	return _receipt_identity


func previous_stage_snapshot() -> Dictionary:
	# Presentation transitions need only the immediately preceding projected state
	# (for example a Ready reserve's registered source root). This is a route-boundary
	# copy, never a per-frame authority read.
	if cursor <= 0:
		return receipt.get("opening", {}).duplicate(true)
	var stages: Array = receipt.get("stages", [])
	var previous := cursor - 1
	if previous >= 0 and previous < stages.size() and stages[previous] is Dictionary:
		return (stages[previous] as Dictionary).get("snapshot", {}).duplicate(true)
	return {}


func previous_stage() -> Dictionary:
	# Attack contact is represented by the immediately preceding AttackLock receipt
	# plus the current Damage receipt. Expose that immutable boundary record once;
	# the passive visual never polls Runtime or rebuilds receipt snapshots per frame.
	if cursor <= 0:
		return {}
	var stages: Array = receipt.get("stages", [])
	var previous := cursor - 1
	if previous >= 0 and previous < stages.size() and stages[previous] is Dictionary:
		return (stages[previous] as Dictionary).duplicate(true)
	return {}


func acknowledge_stage() -> Dictionary:
	if not has_current() or cursor >= stage_count:
		return _failure("No receipt stage is waiting.")
	var request_id := receipt_request_id()
	if request_id.is_empty():
		return _failure("Receipt identity is unavailable.")
	var result: Dictionary = runtime.acknowledge(match_id(), request_id, cursor)
	if bool(result.get("ok", false)):
		last_error = ""
		_write_failure_paused = false
		_sync_presentation_pause()
		refresh()
	else:
		last_error = str(result.get("error", "Progress could not be saved."))
		_write_failure_paused = true
		_sync_presentation_pause()
	return result


func skip_to_result() -> Dictionary:
	# Generic skip consumes Result. Never call it at, or past, the visible terminal
	# Result stage; Continue alone owns that final cursor acknowledgement.
	var result_index := _terminal_result_stage_index()
	if result_index >= 0:
		# The terminal Result must remain visible. Advance only one existing receipt
		# cursor at a time using its canonical Run request; generic skip is forbidden
		# anywhere in a terminal receipt because it consumes Result as well.
		var advances := 0
		while cursor < result_index and advances < stage_count:
			var prior_cursor := cursor
			var acknowledgement := acknowledge_stage()
			if not bool(acknowledgement.get("ok", false)):
				return acknowledgement
			if cursor <= prior_cursor:
				_write_failure_paused = true
				_sync_presentation_pause()
				return _failure("Receipt cursor did not advance.")
			advances += 1
		if cursor == result_index:
			return {"ok":true, "result_ready":true, "acknowledged":advances}
		return _failure("Result receipt boundary is unavailable.")
	if not has_current():
		return _failure("No receipt is active.")
	var request_id := receipt_request_id()
	if request_id.is_empty():
		return _failure("Receipt identity is unavailable.")
	var result: Dictionary = runtime.skip(match_id(), request_id, cursor)
	if bool(result.get("ok", false)):
		last_error = ""
		_write_failure_paused = false
	else:
		last_error = str(result.get("error", "Skip could not be saved."))
		_write_failure_paused = true
	_sync_presentation_pause()
	# A Store failure can occur after a durable partial cursor write. Always reload
	# its accepted cursor before exposing Retry, while retaining the failure latch.
	var refreshed := refresh()
	if not bool(refreshed.get("ok", false)) and last_error.is_empty():
		last_error = str(refreshed.get("error", "Receipt projection is unavailable."))
	return result


func retry_stage() -> Dictionary:
	if last_error.is_empty():
		return _failure("No paused receipt stage needs retry.")
	_write_failure_paused = false
	_sync_presentation_pause()
	var result := acknowledge_stage()
	if not bool(result.get("ok", false)):
		presentation_paused = true
	return result


func set_presentation_paused(value: bool, preserve_elapsed := false) -> void:
	_lifecycle_paused = value
	if value and not preserve_elapsed:
		# Do not accumulate hidden background time or replay a large foreground gap.
		presentation_elapsed = 0.0
	# Resuming clears only the lifecycle pause. A durable cursor failure remains
	# latched by _write_failure_paused until its explicit Retry succeeds.
	_sync_presentation_pause()


func advance_presentation(delta: float, reduced_motion: bool) -> Dictionary:
	if presentation_paused or not has_current() or cursor >= stage_count:
		return {"changed":false, "complete":presentation_complete}
	var stage: Dictionary = _stage_cache
	if stage.is_empty():
		return {"changed":false, "complete":false}
	var stage_name := str(stage.get("name", ""))
	if stage_name == "Result":
		var terminal := false
		for event_value in stage.get("events", []):
			if event_value is Dictionary and str(event_value.get("type", "")) == "terminal":
				terminal = true
				break
		if terminal:
			presentation_complete = true
			return {"changed":false, "complete":true}
		var nonterminal_result := acknowledge_stage()
		return {"changed":bool(nonterminal_result.get("ok", false)), "complete":bool(nonterminal_result.get("ok", false)), "error":str(nonterminal_result.get("error", ""))}
	if (stage.get("events", []) as Array).is_empty() or stage_name == "Plan":
		var empty_result := acknowledge_stage()
		return {"changed":bool(empty_result.get("ok", false)), "complete":bool(empty_result.get("ok", false)), "error":str(empty_result.get("error", ""))}
	var duration := _stage_duration(stage)
	presentation_elapsed = minf(presentation_elapsed + minf(maxf(delta, 0.0), 0.10), duration)
	if presentation_elapsed < duration:
		return {"changed":false, "complete":false}
	presentation_complete = true
	var persisted := acknowledge_stage()
	return {"changed":bool(persisted.get("ok", false)), "complete":true, "error":str(persisted.get("error", ""))}


func stage_progress_bps(reduced_motion: bool) -> int:
	var stage: Dictionary = _stage_cache
	if stage.is_empty():
		return 0
	var duration := _stage_duration(stage)
	var progress := clampi(roundi(10000.0 * presentation_elapsed / maxf(duration, 0.001)), 0, 10000)
	if reduced_motion and str(stage.get("name", "")) == "Print":
		return clampi(int(floori(float(progress) / 2500.0)) * 2500, 0, 10000)
	return progress


func result_receipt() -> Dictionary:
	return runtime.current_result() if runtime != null else {}


func match_id() -> String:
	return str(match_view.get("current_match_id", ""))


func receipt_request_id() -> String:
	return str((match_view.get("presentation", {}) as Dictionary).get("request_id", ""))


func clear_unaccepted_run() -> void:
	if envelopes.has("run"):
		envelopes.erase("run")
		last_error = ""


func _reset_plan() -> void:
	local_plan = {
		"expected_revision": int(player_view.get("revision", -1)),
		"fabrication_id": "",
		"support_copy_id": "",
		"equipment_target_id": "",
		"swap_id": "",
	}


func _card_id_for_copy(copy_id: String) -> String:
	for copy_value in player_view.get("own", {}).get("hand", []):
		if copy_value is Dictionary and str(copy_value.get("copy_id", "")) == copy_id:
			return str(copy_value.get("card_id", ""))
	return ""


func _terminal_pending() -> bool:
	return not str(player_view.get("result", "")).is_empty() and cursor < stage_count


func _terminal_result_stage_index() -> int:
	var stages: Array = receipt.get("stages", [])
	for index in stages.size():
		if stages[index] is Dictionary and str((stages[index] as Dictionary).get("name", "")) == "Result":
			for event_value in (stages[index] as Dictionary).get("events", []):
				if event_value is Dictionary and str(event_value.get("type", "")) == "terminal":
					return index
	return -1


func _cache_current_stage() -> void:
	_stage_cache = {}
	var stages: Array = receipt.get("stages", [])
	if cursor >= 0 and cursor < stages.size() and stages[cursor] is Dictionary:
		_stage_cache = (stages[cursor] as Dictionary).duplicate(true)


func _stage_duration(stage: Dictionary) -> float:
	if str(stage.get("name", "")) == "Enter/Fit":
		var has_companion_entry := false
		var has_equipment := false
		for event_value in stage.get("events", []):
			if not event_value is Dictionary:
				continue
			var event_type := str(event_value.get("type", ""))
			has_companion_entry = has_companion_entry or event_type == "companion_entered"
			has_equipment = has_equipment or event_type in ["equipment_fit", "equipment_fizzled"]
		if has_equipment and not has_companion_entry:
			return 0.45
	return float(STAGE_SECONDS.get(str(stage.get("name", "")), 0.30))


func _sync_presentation_pause() -> void:
	presentation_paused = _lifecycle_paused or _write_failure_paused


func _envelope(key: String, payload: Dictionary) -> Dictionary:
	var existing: Variant = envelopes.get(key, {})
	if existing is Dictionary and not existing.is_empty():
		return existing
	var envelope := {"id": _new_request_id(key), "payload": payload.duplicate(true)}
	envelopes[key] = envelope
	return envelope


func _new_request_id(kind: String) -> String:
	return "battle-ui-%s-%d-%s" % [kind, Time.get_unix_time_from_system(), Crypto.new().generate_random_bytes(16).hex_encode()]


func _failure(message: String) -> Dictionary:
	return {"ok": false, "error": message}
