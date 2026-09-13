class_name TeamMatchSession
extends RefCounted

## Pure M2 lifecycle boundary.  Persistence is injected; no profile or file service
## is referenced here.  Coordinator remains the only Rules/receipt authority.

const CollectionProjection := preload("res://scripts/team_collection/team_collection_projection.gd")
const Coordinator := preload("res://scripts/team_battle/team_battle_coordinator.gd")
const State := preload("res://scripts/team_battle/team_battle_state.gd")
const Data := preload("res://scripts/team_battle/team_battle_data.gd")
const Bot := preload("res://scripts/team_battle/team_battle_bot.gd")
const Ledger := preload("res://scripts/team_runtime/team_match_ledger.gd")

class PersistProxy extends RefCounted:
	var _owner: WeakRef

	func _init(owner: TeamMatchSession) -> void:
		_owner = weakref(owner)

	func persist(kind: String, payload: Dictionary) -> bool:
		var owner: Variant = _owner.get_ref()
		return owner != null and owner._persist_coordinator(kind, payload)

var _profile: Dictionary = {}
var _collection: Dictionary = {}
var _ledger: Dictionary = {}
var _coordinator: Variant = null
var _persist_ledger: Callable = Callable()
var _persist_cursor: Callable = Callable()
var _pending_start: Dictionary = {}
var _current_reference := {"match_id": "", "request_id": "", "cursor": 0, "stage_count": 0, "authority_revision": 0}
var _persist_proxy: PersistProxy = null


static func create(raw_profile: Variant, compatibility: Variant, ledger_exists: bool, ledger_value: Variant, cursor: Variant, persist_ledger: Callable, persist_cursor: Callable) -> Dictionary:
	if not persist_ledger.is_valid() or not persist_cursor.is_valid():
		return _failure("Team-match persistence callbacks are invalid.")
	if not _compatibility_is_ready(compatibility):
		return _failure("Profile compatibility is not ready.")
	var collection := CollectionProjection.project(raw_profile)
	if not bool(collection.get("ok", false)):
		return _failure("Collection profile is invalid.")
	var normalized := Ledger.normalize(ledger_value, ledger_exists)
	if not bool(normalized.get("ok", false)):
		return normalized
	var session: Variant = load("res://scripts/team_runtime/team_match_session.gd").new()
	session._profile = raw_profile.duplicate(true)
	session._collection = collection.duplicate(true)
	session._ledger = normalized.ledger.duplicate(true)
	session._persist_ledger = persist_ledger
	session._persist_cursor = persist_cursor
	if not session._ledger.current.is_empty():
		var restored := Coordinator.restore(session._ledger.current, cursor, session._coordinator_persist_callable())
		if not bool(restored.get("ok", false)):
			return _failure("Current team match cannot be restored.")
		session._coordinator = restored.coordinator
		var authority: Dictionary = session._coordinator.snapshot().authority
		var match_id := str(session._ledger.current.match_id)
		var binding: Dictionary = session._current_start_binding(session._ledger.current)
		if binding.is_empty() or int(binding.sequence) != int(session._ledger.next_match_sequence) - 1 or not session._authority_matches_start(authority, binding):
			return _failure("Current match does not match its immutable Start record.")
		var origin_result := State.create_production(binding.player_priority, binding.rival_priority, binding.player_kit, binding.rival_kit, int(binding.seed), bool(binding.tutorial_opening))
		if not bool(origin_result.get("ok", false)) or JSON.stringify(session._ledger.current.origin_state) != JSON.stringify(origin_result.state):
			return _failure("Current Coordinator origin does not match its immutable Start.")
		if not str(authority.result).is_empty() and not session._ledger.rewards.has(match_id):
			return _failure("Terminal current match is missing its reward.")
		if str(authority.result).is_empty() and session._ledger.rewards.has(match_id):
			return _failure("Nonterminal current match has a reward.")
		if session._ledger.rewards.has(match_id) and not session._reward_matches_authority(session._ledger.rewards[match_id], authority):
			return _failure("Current terminal reward does not match authority.")
		session._refresh_reference(session._coordinator.snapshot())
	elif cursor != null:
		return _failure("Cursor exists without a current match.")
	return {"ok": true, "session": session}


func update_collection(raw_profile: Variant, compatibility: Variant) -> Dictionary:
	if not _compatibility_is_ready(compatibility):
		return _failure("Profile compatibility is not ready.")
	var projected := CollectionProjection.project(raw_profile)
	if not bool(projected.get("ok", false)):
		return _failure("Collection profile is invalid.")
	_profile = raw_profile.duplicate(true)
	_collection = projected.duplicate(true)
	return {"ok": true, "collection": _public_collection()}


func start(request_id: Variant, expected_sequence: Variant, collection_revision: Variant, fingerprint: Variant, seed: Variant) -> Dictionary:
	if not _valid_id(request_id) or not _safe_nonnegative(expected_sequence) or not _safe_nonnegative(collection_revision) or not fingerprint is String or not Ledger._valid_hash(str(fingerprint)) or not _safe_seed(seed):
		return _failure("Start request is invalid.")
	var input := {
		"request_id": str(request_id),
		"expected_sequence": int(expected_sequence),
		"collection_revision": int(collection_revision),
		"fingerprint": str(fingerprint),
		"seed": int(seed),
	}
	if _ledger.starts.has(str(request_id)):
		var historical: Dictionary = _ledger.starts[str(request_id)]
		if _same_start_input(historical, input):
			return {"ok": true, "duplicate": true, "start": historical.duplicate(true), "match_id": str(historical.match_id)}
		return _failure("Start request ID was reused with different input.")
	if _coordinator != null and not _can_replace_current():
		return _failure("Resume Battle is required before another Start.")
	if int(expected_sequence) != int(_ledger.next_match_sequence):
		return _failure("Start sequence is stale.")
	if int(collection_revision) != int(_collection.get("namespace_revision", -1)) or str(fingerprint) != str(_collection.get("fingerprint", "")):
		return _failure("Collection loadout is stale.")
	var loadout: Variant = _collection.get("saved_loadout", {})
	if not loadout is Dictionary or loadout.is_empty():
		return _failure("An Applied Team and Support Kit are required.")
	var loadout_check := CollectionProjection.validate_loadout(loadout.team, loadout.priority, loadout.kit, _collection)
	if not bool(loadout_check.get("ok", false)):
		return _failure("Saved Team loadout is invalid.")
	var sequence := int(_ledger.next_match_sequence)
	var player_priority: Array = loadout.priority.duplicate()
	var rival_priority := _rival_priority(int(seed))
	var player_kit := _expand_kit(loadout.kit)
	var rival_kit := Data.recommended_kit()
	if player_kit.size() != 15:
		return _failure("Saved Support Kit cannot expand to fifteen copies.")
	var start_record := {
		"request_id": str(request_id),
		"expected_sequence": sequence,
		"collection_revision": int(collection_revision),
		"fingerprint": str(fingerprint),
		"seed": int(seed),
		"match_id": "tp-match-%d" % sequence,
		"sequence": sequence,
		"tutorial_opening": sequence == 1,
		"player_priority": player_priority,
		"player_kit": player_kit,
		"rival_priority": rival_priority,
		"rival_kit": rival_kit,
	}
	var state_result := State.create_production(player_priority, rival_priority, player_kit, rival_kit, int(seed), bool(start_record.tutorial_opening))
	if not bool(state_result.get("ok", false)):
		return _failure("Production State creation failed.")
	_pending_start = start_record
	var created := Coordinator.create(state_result.state, str(start_record.match_id), _coordinator_persist_callable())
	_pending_start = {}
	if not bool(created.get("ok", false)):
		return _failure("Coordinator Start was not persisted.")
	_coordinator = created.coordinator
	return {"ok": true, "duplicate": false, "start": start_record.duplicate(true), "match_id": str(start_record.match_id)}


func run_cycle(match_id: Variant, request_id: Variant, player_plan: Variant) -> Dictionary:
	if _coordinator == null or not match_id is String or not request_id is String or match_id != _current_match_id() or not _valid_id(request_id):
		return _failure("Run identity is invalid or stale.")
	var snapshot: Dictionary = _coordinator.snapshot()
	var stored_rival := _rival_plan_for_request(snapshot, str(request_id))
	var rival_plan: Dictionary = {}
	if not stored_rival.is_empty():
		rival_plan = stored_rival
	else:
		if _coordinator.is_busy():
			return _failure("Presentation receipt is still pending.")
		var rival_view_result: Variant = _coordinator.view("rival")
		if not rival_view_result is Dictionary or not bool(rival_view_result.get("ok", false)):
			return _failure("Rival private view is invalid.")
		var chosen: Variant = Bot.choose_plan(rival_view_result.view)
		if not bool(chosen.get("ok", false)):
			return _failure("Rival policy could not choose a Plan.")
		rival_plan = chosen.plan
	var result: Variant = _coordinator.request(str(match_id), str(request_id), player_plan, rival_plan)
	if not bool(result.get("ok", false)):
		return result
	return result


func acknowledge(match_id: Variant, request_id: Variant, cursor: Variant) -> Dictionary:
	if _coordinator == null:
		return _failure("No current match exists.")
	return _coordinator.acknowledge(str(match_id), str(request_id), cursor)


func skip(match_id: Variant, request_id: Variant, cursor: Variant) -> Dictionary:
	if _coordinator == null:
		return _failure("No current match exists.")
	return _coordinator.skip(str(match_id), str(request_id), cursor)


func snapshot() -> Dictionary:
	return _ledger.duplicate(true)


func view() -> Dictionary:
	var has_current := _coordinator != null
	var authority: Dictionary = _ledger.current.get("authority", {})
	var terminal := has_current and not str(authority.get("result", "")).is_empty()
	var presentation_complete := int(_current_reference.cursor) >= int(_current_reference.stage_count)
	var output := {
		"wallet": {"coins": int(_ledger.coins), "xp": int(_ledger.xp)},
		"has_current": has_current,
		"resume": has_current and (not terminal or not presentation_complete),
		"can_start": not has_current or (terminal and presentation_complete and _ledger.rewards.has(_current_match_id())),
		"current_match_id": _current_match_id(),
		"history_count": _ledger.starts.size(),
		"next_match_sequence": int(_ledger.next_match_sequence),
	}
	if _coordinator != null:
		var player_view: Variant = _coordinator.view("player")
		if player_view is Dictionary and bool(player_view.get("ok", false)):
			output["player"] = player_view.view
		output["presentation"] = _current_reference.duplicate(true)
	return output


func pending_receipt() -> Dictionary:
	if _coordinator == null or str(_current_reference.request_id).is_empty():
		return {"ok": true, "receipt": {}, "cursor": int(_current_reference.cursor), "stage_count": int(_current_reference.stage_count)}
	var projected: Variant = _coordinator.viewer_receipt(str(_current_reference.request_id), "player")
	if not projected is Dictionary or not bool(projected.get("ok", false)):
		return _failure("Current player receipt projection is unavailable.")
	return {"ok": true, "receipt": projected.receipt, "cursor": int(_current_reference.cursor), "stage_count": int(_current_reference.stage_count)}


func current_result() -> Dictionary:
	var match_id := _current_match_id()
	return _ledger.rewards.get(match_id, {}).duplicate(true)


func historical_result(match_id: Variant) -> Dictionary:
	if not _valid_id(match_id):
		return _failure("Historical match identity is invalid.")
	# Start history is request-keyed, so match membership is checked explicitly.
	var found := false
	for start_value in _ledger.starts.values():
		if start_value is Dictionary and str(start_value.get("match_id", "")) == str(match_id):
			found = true
			break
	if not found:
		return _failure("Historical match is unknown.")
	return {"ok": true, "reward": _ledger.rewards.get(str(match_id), {}).duplicate(true)}


func _persist_coordinator(kind: String, payload: Dictionary) -> bool:
	if kind == "cursor":
		var cursor_result: Variant = _persist_cursor.call(payload.duplicate(true))
		if cursor_result is bool and bool(cursor_result):
			_current_reference.request_id = str(payload.request_id)
			_current_reference.cursor = int(payload.next_cursor)
			_current_reference.authority_revision = int(payload.authority_revision)
			return true
		return false
	if kind not in ["start", "run"]:
		return false
	var candidate := _ledger.duplicate(true)
	candidate.current = payload.duplicate(true)
	if kind == "start":
		if _pending_start.is_empty():
			return false
		candidate.starts[str(_pending_start.request_id)] = _pending_start.duplicate(true)
		candidate.next_match_sequence = int(candidate.next_match_sequence) + 1
	if kind == "run":
		var authority: Dictionary = payload.authority
		if not str(authority.result).is_empty():
			var reward_result := Ledger.reward_for_terminal(str(payload.match_id), authority)
			if not bool(reward_result.get("ok", false)):
				return false
			var reward: Dictionary = reward_result.reward
			if candidate.rewards.has(str(payload.match_id)):
				return false
			candidate.rewards[str(payload.match_id)] = reward
			candidate.coins = int(candidate.coins) + int(reward.coins)
			candidate.xp = int(candidate.xp) + int(reward.xp)
	var checked := Ledger.normalize(candidate, true)
	if not bool(checked.get("ok", false)):
		return false
	var persisted: Variant = _persist_ledger.call(candidate.duplicate(true))
	if not (persisted is bool and bool(persisted)):
		return false
	_ledger = candidate
	_refresh_reference(payload)
	return true


func _coordinator_persist_callable() -> Callable:
	if _persist_proxy == null:
		_persist_proxy = PersistProxy.new(self)
	return Callable(_persist_proxy, "persist")


func _can_replace_current() -> bool:
	var authority: Dictionary = _ledger.current.get("authority", {})
	if str(authority.get("result", "")).is_empty() or int(_current_reference.cursor) < int(_current_reference.stage_count):
		return false
	return _ledger.rewards.has(_current_match_id())


func _current_match_id() -> String:
	return str(_ledger.current.get("match_id", ""))


func _refresh_reference(snapshot: Dictionary) -> void:
	var presentation: Dictionary = snapshot.get("presentation", {})
	var record := {}
	for record_value in snapshot.get("records", []):
		if record_value is Dictionary and str(record_value.get("request_id", "")) == str(presentation.get("request_id", "")):
			record = record_value
			break
	_current_reference = {
		"match_id": str(snapshot.get("match_id", "")),
		"request_id": str(presentation.get("request_id", "")),
		"cursor": int(presentation.get("cursor", 0)),
		"stage_count": int(record.get("receipt", {}).get("stages", []).size()),
		"authority_revision": int(snapshot.get("authority", {}).get("revision", 0)),
	}


func _current_start_binding(snapshot: Dictionary) -> Dictionary:
	var match_id := str(snapshot.get("match_id", ""))
	for record_value in _ledger.starts.values():
		if record_value is Dictionary and str(record_value.get("match_id", "")) == match_id:
			return record_value
	return {}


func _authority_matches_start(authority: Dictionary, start: Dictionary) -> bool:
	if int(authority.get("seed", -1)) != int(start.seed):
		return false
	for seat_id in ["player", "rival"]:
		var seat: Dictionary = authority.get("seats", {}).get(seat_id, {})
		var expected_priority: Array = start.player_priority if seat_id == "player" else start.rival_priority
		var expected_kit: Array = start.player_kit if seat_id == "player" else start.rival_kit
		var member_ids := []
		for member_value in seat.get("members", []):
			if member_value is Dictionary:
				member_ids.append(str(member_value.get("member_id", "")))
		if member_ids != expected_priority or seat.get("original_kit", []) != expected_kit:
			return false
	return true


func _reward_matches_authority(reward: Dictionary, authority: Dictionary) -> bool:
	var expected := Ledger.reward_for_terminal(str(reward.get("match_id", "")), authority)
	return bool(expected.get("ok", false)) and JSON.stringify(expected.reward) == JSON.stringify(reward)


func _rival_plan_for_request(snapshot: Dictionary, request_id: String) -> Dictionary:
	for record_value in snapshot.get("records", []):
		if record_value is Dictionary and str(record_value.get("request_id", "")) == request_id:
			return record_value.get("rival_plan", {}).duplicate(true)
	return {}


func _public_collection() -> Dictionary:
	return {
		"namespace_revision": int(_collection.get("namespace_revision", -1)),
		"fingerprint": str(_collection.get("fingerprint", "")),
		"saved_loadout": _collection.get("saved_loadout", {}).duplicate(true),
	}


static func _rival_priority(seed: int) -> Array:
	var starter: String = CollectionProjection.STARTERS[seed % 3]
	return [starter] + CollectionProjection.GUARANTEES[starter].duplicate()


static func _expand_kit(counts: Dictionary) -> Array:
	var expanded := []
	for card_id in CollectionProjection.SUPPORTS:
		if not counts.has(card_id) or not _safe_nonnegative(counts[card_id]):
			return []
		for ignored in int(counts[card_id]):
			expanded.append(card_id)
	return expanded


static func _same_start_input(record: Dictionary, input: Dictionary) -> bool:
	for key in input.keys():
		if record.get(key, null) != input[key]:
			return false
	return true


static func _compatibility_is_ready(value: Variant) -> bool:
	if value is String:
		return value in ["ready", "compatible"]
	if not value is Dictionary:
		return false
	return value.get("compatible", null) is bool and bool(value.compatible) and value.get("state", null) is String and value.state == "ready" and value.get("message", null) is String


static func _safe_nonnegative(value: Variant) -> bool:
	return value is int and not value is bool and int(value) >= 0 and int(value) <= State.MAX_SAFE_JSON_INTEGER


static func _safe_seed(value: Variant) -> bool:
	return _safe_nonnegative(value) and int(value) <= State.MAX_SEED


static func _valid_id(value: Variant) -> bool:
	return value is String and Ledger._valid_id(value)


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "error": message}
