class_name TeamBattleCoordinator
extends RefCounted

## Receipt-safe M1 session boundary. Rules remains the sole combat authority;
## this object publishes only viewer projections and persists no player files.

const State := preload("res://scripts/team_battle/team_battle_state.gd")
const Rules := preload("res://scripts/team_battle/team_battle_rules.gd")

const SCHEMA_VERSION := 1
const SNAPSHOT_KEYS := ["schema", "match_id", "test_1v1", "origin_state", "authority", "records", "presentation"]
const RECORD_KEYS := ["request_id", "player_plan", "rival_plan", "input_hash", "receipt", "receipt_hash"]
const PRESENTATION_KEYS := ["request_id", "cursor"]
const NONTERMINAL_STAGES := ["Queue", "Print", "Awaken", "Enter/Fit", "Swap", "Spell", "AttackLock", "Damage", "Traits", "Defeat", "Replace", "Result", "Plan"]
const TERMINAL_STAGES := ["Queue", "Print", "Awaken", "Enter/Fit", "Swap", "Spell", "AttackLock", "Damage", "Traits", "Defeat", "Replace", "Result"]

var _match_id := ""
var _test_1v1 := false
var _origin_state: Dictionary = {}
var _authority: Dictionary = {}
var _records: Array = []
var _presentation := {"request_id": "", "cursor": 0}
var _persist: Callable = Callable()


static func create(initial_state: Variant, match_id: String, persist: Callable, test_1v1: bool = false) -> Dictionary:
	if not persist.is_valid():
		return _failure("Coordinator persistence callback is invalid.")
	if not _valid_id(match_id):
		return _failure("Match ID is invalid.")
	var restored := _restore_state(initial_state, test_1v1)
	if not bool(restored.get("ok", false)):
		return restored
	if int(restored.state.revision) != 0:
		return _failure("Coordinator Start requires revision zero.")
	var coordinator: Variant = load("res://scripts/team_battle/team_battle_coordinator.gd").new()
	coordinator._match_id = match_id
	coordinator._test_1v1 = test_1v1
	coordinator._origin_state = State.deep_clone(restored.state)
	coordinator._authority = State.deep_clone(restored.state)
	coordinator._persist = persist
	var candidate: Dictionary = coordinator.snapshot()
	if not coordinator._persist_snapshot("start", candidate):
		return _failure("Persistence rejected Coordinator Start.")
	return {"ok": true, "coordinator": coordinator}


static func restore(snapshot_value: Variant, cursor_checkpoint: Variant, persist: Callable, test_1v1: bool = false) -> Dictionary:
	if not persist.is_valid():
		return _failure("Coordinator persistence callback is invalid.")
	var normalized := _normalize_json(snapshot_value)
	if not bool(normalized.get("ok", false)) or not normalized.value is Dictionary:
		return _failure("Coordinator snapshot is not canonical JSON.")
	var snapshot: Dictionary = normalized.value
	if not _has_exact_keys(snapshot, SNAPSHOT_KEYS) or not _is_integer(snapshot.get("schema", -1)) or int(snapshot.schema) != SCHEMA_VERSION:
		return _failure("Coordinator snapshot schema is invalid.")
	if not snapshot.match_id is String or not _valid_id(snapshot.match_id) or not snapshot.test_1v1 is bool or bool(snapshot.test_1v1) != test_1v1:
		return _failure("Coordinator snapshot identity is invalid.")
	var origin_result := _restore_state(snapshot.origin_state, test_1v1)
	var authority_result := _restore_state(snapshot.authority, test_1v1)
	if not bool(origin_result.get("ok", false)) or not bool(authority_result.get("ok", false)):
		return _failure("Coordinator State snapshot is invalid.")
	if int(origin_result.state.revision) != 0 or not snapshot.records is Array:
		return _failure("Coordinator origin or records are invalid.")
	var coordinator: Variant = load("res://scripts/team_battle/team_battle_coordinator.gd").new()
	coordinator._match_id = snapshot.match_id
	coordinator._test_1v1 = test_1v1
	coordinator._origin_state = State.deep_clone(origin_result.state)
	coordinator._authority = State.deep_clone(authority_result.state)
	coordinator._persist = persist
	var records_result: Dictionary = coordinator._validate_records(snapshot.records)
	if not bool(records_result.get("ok", false)):
		return records_result
	coordinator._records = records_result.records
	if coordinator._records.is_empty():
		if JSON.stringify(coordinator._authority) != JSON.stringify(coordinator._origin_state):
			return _failure("Empty Coordinator authority must equal origin State.")
	else:
		var final_record: Dictionary = coordinator._records.back()
		if JSON.stringify(final_record.receipt.final_state) != JSON.stringify(coordinator._authority):
			return _failure("Coordinator authority does not match the final receipt.")
	if not snapshot.presentation is Dictionary or not _has_exact_keys(snapshot.presentation, PRESENTATION_KEYS):
		return _failure("Coordinator presentation reference is invalid.")
	var presentation_result: Dictionary = coordinator._validated_presentation(snapshot.presentation)
	if not bool(presentation_result.get("ok", false)):
		return presentation_result
	coordinator._presentation = presentation_result.presentation
	var overlay_result: Dictionary = coordinator._apply_checkpoint(cursor_checkpoint)
	if not bool(overlay_result.get("ok", false)):
		return overlay_result
	return {"ok": true, "coordinator": coordinator}


func request(match_id: String, request_id: String, player_plan: Variant, rival_plan: Variant) -> Dictionary:
	if match_id != _match_id or not _valid_id(request_id):
		return _failure("Match or request ID is invalid.")
	var input_normalized := _normalize_json({"player_plan": player_plan, "rival_plan": rival_plan})
	if not bool(input_normalized.get("ok", false)) or not input_normalized.value is Dictionary:
		return _failure("Request Plans are not canonical JSON.")
	var stored_inputs: Dictionary = input_normalized.value
	var input_hash_result := _hash_value(stored_inputs)
	var input_hash := str(input_hash_result.hash)
	var existing := _record_by_id(request_id)
	if not existing.is_empty():
		if str(existing.input_hash) != input_hash:
			return _failure("Request ID was reused with different Plans.")
		return _request_response(existing, _cursor_for_request(request_id))
	if is_busy():
		return _failure("Presentation receipt is still pending.")
	if not str(_authority.result).is_empty():
		return _failure("Terminal authority rejects further requests.")
	var player_checked := Rules.validate_plan(_authority, "player", player_plan, _test_1v1)
	var rival_checked := Rules.validate_plan(_authority, "rival", rival_plan, _test_1v1)
	if not bool(player_checked.get("ok", false)) or not bool(rival_checked.get("ok", false)):
		return _failure("Request Plans are invalid against the same authority snapshot.")
	var resolved := Rules.run_cycle(_authority, player_checked.plan, rival_checked.plan, _test_1v1)
	if not bool(resolved.get("ok", false)):
		return resolved
	var receipt_hash_result := _hash_value(resolved.receipt)
	if not bool(receipt_hash_result.get("ok", false)):
		return _failure("Rules receipt is not canonical JSON.")
	for viewer in ["player", "rival"]:
		var projected := Rules.project_receipt(resolved.receipt, viewer)
		if not bool(projected.get("ok", false)):
			return _failure("Rules receipt cannot produce a safe viewer projection.")
	var record := {
		"request_id": request_id,
		"player_plan": stored_inputs.player_plan,
		"rival_plan": stored_inputs.rival_plan,
		"input_hash": input_hash,
		"receipt": State.deep_clone(resolved.receipt),
		"receipt_hash": receipt_hash_result.hash,
	}
	var candidate_records := _records.duplicate(true)
	candidate_records.append(record)
	var candidate_presentation := {"request_id": request_id, "cursor": 0}
	var candidate_snapshot := _snapshot_with(State.deep_clone(resolved.state), candidate_records, candidate_presentation)
	if not _persist_snapshot("run", candidate_snapshot):
		return _failure("Persistence rejected Coordinator Run.")
	_authority = State.deep_clone(resolved.state)
	_records = candidate_records
	_presentation = candidate_presentation
	return _request_response(record, 0)


func acknowledge(match_id: String, request_id: String, expected_cursor: Variant) -> Dictionary:
	if match_id != _match_id or not _valid_id(request_id) or not _is_integer(expected_cursor) or int(expected_cursor) < 0:
		return _failure("Acknowledgement identity is invalid.")
	var cursor := int(expected_cursor)
	var record := _record_by_id(request_id)
	if record.is_empty():
		return _failure("Acknowledgement request is unknown.")
	if request_id != str(_presentation.request_id):
		return {"ok": true, "ignored": true, "cursor": record.receipt.stages.size()}
	var stage_count: int = record.receipt.stages.size()
	var current := int(_presentation.cursor)
	if cursor < current or (cursor == stage_count and current == stage_count):
		return {"ok": true, "ignored": true, "cursor": current}
	if cursor != current or current >= stage_count:
		return _failure("Acknowledgement cursor is invalid.")
	var next_cursor := current + 1
	var payload := _cursor_payload(request_id, str(record.receipt_hash), next_cursor)
	if not _persist_snapshot("cursor", payload):
		return _failure("Persistence rejected Coordinator cursor.")
	_presentation.cursor = next_cursor
	return {"ok": true, "cursor": next_cursor, "stage_count": stage_count}


func skip(match_id: String, request_id: String, expected_cursor: Variant) -> Dictionary:
	if not _is_integer(expected_cursor) or match_id != _match_id or request_id != str(_presentation.request_id) or int(expected_cursor) != int(_presentation.cursor):
		return _failure("Skip cursor is invalid.")
	var record := _record_by_id(request_id)
	if record.is_empty():
		return _failure("Skip request is unknown.")
	var stage_count: int = record.receipt.stages.size()
	while int(_presentation.cursor) < stage_count:
		var advanced := acknowledge(match_id, request_id, int(_presentation.cursor))
		if not bool(advanced.get("ok", false)):
			return advanced
	return {"ok": true, "cursor": int(_presentation.cursor), "stage_count": stage_count}


func view(viewer: String) -> Dictionary:
	return Rules.view_for_seat(_authority, viewer, _test_1v1)


func viewer_receipt(request_id: String, viewer: String) -> Dictionary:
	var record := _record_by_id(request_id)
	if record.is_empty():
		return _failure("Receipt request is unknown.")
	return Rules.project_receipt(record.receipt, viewer)


func snapshot() -> Dictionary:
	return _snapshot_with(_authority, _records, _presentation)


func is_busy() -> bool:
	if str(_presentation.request_id).is_empty():
		return false
	var record := _record_by_id(str(_presentation.request_id))
	return not record.is_empty() and int(_presentation.cursor) < record.receipt.stages.size()


func _validate_records(records_value: Array) -> Dictionary:
	var prior: Dictionary = _origin_state
	var result := []
	var ids := {}
	for record_value in records_value:
		if not record_value is Dictionary:
			return _failure("Coordinator record is invalid.")
		var record: Dictionary = record_value
		if not _has_exact_keys(record, RECORD_KEYS) or not record.request_id is String or not _valid_id(record.request_id) or ids.has(record.request_id):
			return _failure("Coordinator record identity is invalid.")
		var input_hash_result := _hash_value({"player_plan": record.player_plan, "rival_plan": record.rival_plan})
		var receipt_hash_result := _hash_value(record.receipt)
		if not bool(input_hash_result.get("ok", false)) or not bool(receipt_hash_result.get("ok", false)) or str(record.input_hash) != str(input_hash_result.hash) or str(record.receipt_hash) != str(receipt_hash_result.hash):
			return _failure("Coordinator record hash is invalid.")
		var player_checked := Rules.validate_plan(prior, "player", record.player_plan, _test_1v1)
		var rival_checked := Rules.validate_plan(prior, "rival", record.rival_plan, _test_1v1)
		if not bool(player_checked.get("ok", false)) or not bool(rival_checked.get("ok", false)):
			return _failure("Coordinator record Plan is invalid for its opening State.")
		var receipt_result := _validate_receipt_envelope(record.receipt, prior)
		if not bool(receipt_result.get("ok", false)):
			return receipt_result
		for viewer in ["player", "rival"]:
			var projected := Rules.project_receipt(record.receipt, viewer)
			if not bool(projected.get("ok", false)):
				return _failure("Coordinator record receipt is invalid.")
		prior = State.deep_clone(receipt_result.final_state)
		ids[record.request_id] = true
		result.append(State.deep_clone(record))
	return {"ok": true, "records": result}


func _validated_presentation(value: Dictionary) -> Dictionary:
	if not value.request_id is String or not _is_integer(value.cursor) or int(value.cursor) < 0:
		return _failure("Coordinator presentation values are invalid.")
	if str(value.request_id).is_empty():
		if int(value.cursor) != 0 or not _records.is_empty():
			return _failure("Coordinator empty presentation is invalid.")
		return {"ok": true, "presentation": {"request_id": "", "cursor": 0}}
	var record := _record_by_id(value.request_id)
	if record.is_empty() or _records.is_empty() or str(_records.back().request_id) != str(value.request_id) or int(value.cursor) > record.receipt.stages.size():
		return _failure("Coordinator presentation cursor is invalid.")
	return {"ok": true, "presentation": {"request_id": value.request_id, "cursor": int(value.cursor)}}


func _apply_checkpoint(checkpoint_value: Variant) -> Dictionary:
	if checkpoint_value == null:
		return {"ok": true}
	var normalized := _normalize_json(checkpoint_value)
	if not bool(normalized.get("ok", false)) or not normalized.value is Dictionary:
		return _failure("Cursor checkpoint is invalid.")
	var checkpoint: Dictionary = normalized.value
	if not _has_exact_keys(checkpoint, ["match_id", "authority_revision", "request_id", "receipt_hash", "next_cursor"]):
		return _failure("Cursor checkpoint schema is invalid.")
	if not _checkpoint_envelope_is_valid(checkpoint):
		return _failure("Cursor checkpoint values are invalid.")
	if checkpoint.match_id != _match_id or checkpoint.request_id != str(_presentation.request_id):
		return {"ok": true}
	if int(checkpoint.authority_revision) != int(_authority.revision):
		return _failure("Cursor checkpoint revision is invalid.")
	var record := _record_by_id(checkpoint.request_id)
	if record.is_empty() or checkpoint.receipt_hash != record.receipt_hash or int(checkpoint.next_cursor) < 0 or int(checkpoint.next_cursor) > record.receipt.stages.size():
		return _failure("Cursor checkpoint does not match the current receipt.")
	_presentation.cursor = max(int(_presentation.cursor), int(checkpoint.next_cursor))
	return {"ok": true}


func _request_response(record: Dictionary, cursor: int) -> Dictionary:
	return {"ok": true, "request_id": record.request_id, "cursor": cursor, "stage_count": record.receipt.stages.size(), "receipt_hash": record.receipt_hash}


func _cursor_payload(request_id: String, receipt_hash: String, next_cursor: int) -> Dictionary:
	return {"match_id": _match_id, "authority_revision": int(_authority.revision), "request_id": request_id, "receipt_hash": receipt_hash, "next_cursor": next_cursor}


func _snapshot_with(authority: Dictionary, records: Array, presentation: Dictionary) -> Dictionary:
	return {
		"schema": SCHEMA_VERSION,
		"match_id": _match_id,
		"test_1v1": _test_1v1,
		"origin_state": State.deep_clone(_origin_state),
		"authority": State.deep_clone(authority),
		"records": records.duplicate(true),
		"presentation": presentation.duplicate(true),
	}


func _persist_snapshot(kind: String, payload: Dictionary) -> bool:
	if not _persist.is_valid():
		return false
	var persisted: Variant = _persist.call(kind, State.deep_clone(payload))
	return persisted is bool and bool(persisted)


func _record_by_id(request_id: String) -> Dictionary:
	for record_value in _records:
		var record: Dictionary = record_value
		if str(record.request_id) == request_id:
			return record
	return {}


func _cursor_for_request(request_id: String) -> int:
	if request_id == str(_presentation.request_id):
		return int(_presentation.cursor)
	var record := _record_by_id(request_id)
	return record.receipt.stages.size() if not record.is_empty() else 0


static func _restore_state(value: Variant, test_1v1: bool) -> Dictionary:
	return State.restore_test_1v1(value) if test_1v1 else State.restore(value)


static func _hash_value(value: Variant) -> Dictionary:
	var normalized := _normalize_json(value)
	if not bool(normalized.get("ok", false)):
		return normalized
	return {"ok": true, "hash": JSON.stringify(normalized.value).sha256_text()}


static func _normalize_json(value: Variant) -> Dictionary:
	if value == null or value is bool or value is String:
		return {"ok": true, "value": value}
	if value is int and not value is bool:
		if value < -State.MAX_SAFE_JSON_INTEGER or value > State.MAX_SAFE_JSON_INTEGER:
			return _failure("JSON integer is outside the safe range.")
		return {"ok": true, "value": int(value)}
	if value is float:
		if not is_finite(value) or floor(value) != value or value < -State.MAX_SAFE_JSON_INTEGER or value > State.MAX_SAFE_JSON_INTEGER:
			return _failure("JSON number is not a safe whole integer.")
		return {"ok": true, "value": int(value)}
	if value is Array:
		var array := []
		for entry in value:
			var entry_result := _normalize_json(entry)
			if not bool(entry_result.get("ok", false)):
				return entry_result
			array.append(entry_result.value)
		return {"ok": true, "value": array}
	if value is Dictionary:
		var dictionary: Dictionary = value
		var keys := []
		for key in dictionary.keys():
			if not key is String:
				return _failure("JSON Dictionary key is not a String.")
			keys.append(key)
		keys.sort()
		var output := {}
		for key in keys:
			var item_result := _normalize_json(dictionary[key])
			if not bool(item_result.get("ok", false)):
				return item_result
			output[key] = item_result.value
		return {"ok": true, "value": output}
	return _failure("Value is not JSON-compatible.")


static func _valid_id(value: String) -> bool:
	if value.is_empty() or value.length() > 96:
		return false
	for index in value.length():
		var character := value.substr(index, 1)
		if not (character.to_lower() >= "a" and character.to_lower() <= "z") and not (character >= "0" and character <= "9") and character not in ["_", "-"]:
			return false
	return true


static func _is_integer(value: Variant) -> bool:
	return value is int and not (value is bool)


func _validate_receipt_envelope(receipt_value: Variant, prior: Dictionary) -> Dictionary:
	if not receipt_value is Dictionary:
		return _failure("Coordinator receipt is invalid.")
	var receipt: Dictionary = receipt_value
	var expected_keys := ["receipt_schema", "cycle", "opening_revision", "final_revision", "opening_state", "stages", "final_state"]
	if not _has_exact_keys(receipt, expected_keys):
		return _failure("Coordinator receipt schema is invalid.")
	if not _is_integer(receipt.receipt_schema) or int(receipt.receipt_schema) != 1:
		return _failure("Coordinator receipt version is invalid.")
	if not _is_integer(receipt.cycle) or not _is_integer(receipt.opening_revision) or not _is_integer(receipt.final_revision):
		return _failure("Coordinator receipt revision fields are invalid.")
	if int(receipt.cycle) != int(prior.cycle) or int(receipt.opening_revision) != int(prior.revision):
		return _failure("Coordinator receipt opening chain is invalid.")
	if not receipt.opening_state is Dictionary or JSON.stringify(receipt.opening_state) != JSON.stringify(prior):
		return _failure("Coordinator receipt opening State is invalid.")
	if not receipt.stages is Array or not _receipt_stages_are_well_formed(receipt.stages, prior):
		return _failure("Coordinator receipt stages are malformed.")
	if not _receipt_stage_order_is_valid(receipt):
		return _failure("Coordinator receipt stage order is invalid.")
	var final_result := _restore_state(receipt.final_state, _test_1v1)
	if not bool(final_result.get("ok", false)):
		return _failure("Coordinator receipt final State is invalid.")
	var final_state: Dictionary = final_result.state
	if int(final_state.seed) != int(prior.seed) or int(final_state.roster_count) != int(prior.roster_count):
		return _failure("Coordinator receipt changed seed or roster shape.")
	if int(receipt.final_revision) != int(final_state.revision) or int(final_state.revision) != int(prior.revision) + 1:
		return _failure("Coordinator receipt revision chain is invalid.")
	var final_stage: Dictionary = receipt.stages.back()
	if not final_stage.snapshot is Dictionary or JSON.stringify(final_stage.snapshot) != JSON.stringify(receipt.final_state):
		return _failure("Coordinator final stage does not equal final State.")
	return {"ok": true, "final_state": final_state}


static func _checkpoint_envelope_is_valid(checkpoint: Dictionary) -> bool:
	if not checkpoint.match_id is String or not _valid_id(checkpoint.match_id):
		return false
	if not checkpoint.request_id is String or not _valid_id(checkpoint.request_id):
		return false
	if not checkpoint.receipt_hash is String or not _valid_hash(checkpoint.receipt_hash):
		return false
	if not _is_integer(checkpoint.authority_revision) or int(checkpoint.authority_revision) < 0:
		return false
	return _is_integer(checkpoint.next_cursor) and int(checkpoint.next_cursor) >= 0


static func _valid_hash(value: String) -> bool:
	if value.length() != 64:
		return false
	for index in value.length():
		var character := value.substr(index, 1)
		if not (character >= "0" and character <= "9") and not (character >= "a" and character <= "f"):
			return false
	return true


static func _receipt_stage_order_is_valid(receipt: Dictionary) -> bool:
	var final_state: Variant = receipt.get("final_state", {})
	if not final_state is Dictionary:
		return false
	var expected: Array = TERMINAL_STAGES if not str(final_state.get("result", "")).is_empty() else NONTERMINAL_STAGES
	if receipt.stages.size() != expected.size():
		return false
	for index in expected.size():
		var stage_value: Variant = receipt.stages[index]
		if not stage_value is Dictionary or str(stage_value.get("name", "")) != str(expected[index]):
			return false
	return true


static func _receipt_stages_are_well_formed(stages: Array, prior: Dictionary) -> bool:
	for stage_value in stages:
		if not stage_value is Dictionary:
			return false
		var stage: Dictionary = stage_value
		if not _has_exact_keys(stage, ["name", "events", "snapshot"]):
			return false
		if not stage.name is String or not stage.events is Array or not stage.snapshot is Dictionary:
			return false
		if not _stage_snapshot_preserves_match_shape(stage.snapshot, prior):
			return false
	return true


static func _stage_snapshot_preserves_match_shape(snapshot: Dictionary, prior: Dictionary) -> bool:
	if not snapshot.has("seed") or not snapshot.has("roster_count"):
		return false
	if not _is_integer(snapshot.seed) or not _is_integer(snapshot.roster_count):
		return false
	return int(snapshot.seed) == int(prior.seed) and int(snapshot.roster_count) == int(prior.roster_count)


static func _has_exact_keys(value: Dictionary, expected: Array) -> bool:
	if value.size() != expected.size():
		return false
	for key in value.keys():
		if key not in expected:
			return false
	return true


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "error": message}
