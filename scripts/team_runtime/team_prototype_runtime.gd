class_name TeamPrototypeRuntime
extends RefCounted

## Thin file-backed facade. Collection and Match remain the only transition
## authorities; this object owns generation checks and explicit-path callbacks.

const Store := preload("res://scripts/team_runtime/team_prototype_store.gd")
const CollectionSession := preload("res://scripts/team_collection/team_collection_session.gd")
const CollectionProjection := preload("res://scripts/team_collection/team_collection_projection.gd")
const MatchSession := preload("res://scripts/team_runtime/team_match_session.gd")

class PersistProxy extends RefCounted:
	var _owner: WeakRef

	func _init(owner: TeamPrototypeRuntime) -> void:
		_owner = weakref(owner)

	func profile(candidate: Dictionary) -> bool:
		var owner: Variant = _owner.get_ref()
		return owner != null and owner._persist_profile(candidate)

	func ledger(candidate: Dictionary) -> bool:
		var owner: Variant = _owner.get_ref()
		return owner != null and owner._persist_ledger(candidate)

	func cursor(candidate: Dictionary) -> bool:
		var owner: Variant = _owner.get_ref()
		return owner != null and owner._persist_cursor(candidate)

var _store: Variant = null
var _collection: Variant = null
var _match: Variant = null
var _profile: Dictionary = {}
var _compatibility: Variant = null
var _proxy: PersistProxy = null
var _recovery := ""
var _last_error := ""


static func open(profile_path: Variant, compatibility: Variant, fault: Callable = Callable()) -> Dictionary:
	var opened: Dictionary = Store.open(profile_path, compatibility, fault)
	if not bool(opened.get("ok", false)):
		return opened
	var runtime: Variant = load("res://scripts/team_runtime/team_prototype_runtime.gd").new()
	runtime._store = opened.store
	runtime._profile = opened.profile.duplicate(true)
	runtime._compatibility = compatibility.duplicate(true) if compatibility is Dictionary else compatibility
	runtime._recovery = str(opened.recovery)
	if not runtime._recovery.is_empty():
		return {"ok": true, "runtime": runtime, "recovery": runtime._recovery}
	runtime._proxy = PersistProxy.new(runtime)
	var created_collection: Dictionary = CollectionSession.create(runtime._profile, Callable(runtime._proxy, "profile"))
	if not bool(created_collection.get("ok", false)):
		return _failure("Collection session could not open.")
	runtime._collection = created_collection.session
	var created_match: Dictionary = MatchSession.create(runtime._profile, compatibility, bool(opened.ledger_exists), opened.ledger, opened.cursor, Callable(runtime._proxy, "ledger"), Callable(runtime._proxy, "cursor"))
	if not bool(created_match.get("ok", false)):
		return _failure("Match session could not open.")
	runtime._match = created_match.session
	return {"ok": true, "runtime": runtime, "recovery": ""}


func close() -> void:
	_match = null
	_collection = null
	_proxy = null
	_store = null


func is_recovery() -> bool:
	return not _recovery.is_empty() or (_store != null and _store.is_recovery())


func view() -> Dictionary:
	var output := {
		"ok": true,
		"recovery": _effective_recovery(),
		"last_error": _last_error,
		"can_mutate": not is_recovery() and _collection != null and _match != null,
	}
	if _collection != null:
		output["collection"] = collection_view()
	if _match != null:
		output["match"] = _match.view()
	return output


func collection_view() -> Dictionary:
	if _collection == null:
		return _failure("No active collection session.")
	var projection: Dictionary = _collection.project()
	if not bool(projection.get("ok", false)):
		return _failure("Collection projection is invalid.")
	var prototype: Dictionary = projection.prototype_state
	return {
		"ok": true,
		"namespace_revision": int(projection.namespace_revision),
		"fingerprint": str(projection.fingerprint),
		"licenses": projection.licenses.duplicate(true),
		"printed_counts": projection.printed_counts.duplicate(true),
		"support_counts": projection.support_counts.duplicate(true),
		"recommended_team": projection.recommended_team.duplicate(),
		"recommended_kit": projection.recommended_kit.duplicate(true),
		"starter_id": str(prototype.starter_id),
		"voucher": prototype.voucher.duplicate(true),
		"grant_receipt": prototype.grant_receipt.duplicate(true),
		"saved_loadout": projection.saved_loadout.duplicate(true),
		"first_session_state": str(projection.first_session_state),
	}


func settings_view() -> Dictionary:
	var raw: Variant = _profile.get("team_prototype_settings", {})
	var settings: Dictionary = raw.duplicate(true) if raw is Dictionary else {}
	var stored_scale: Variant = settings.get("text_scale_bps", 10000)
	var scale := 10000
	if (stored_scale is int or stored_scale is float) and not stored_scale is bool and int(stored_scale) in [10000, 15000] and float(stored_scale) == float(int(stored_scale)):
		scale = int(stored_scale)
	var stored_high_contrast: Variant = settings.get("high_contrast", false)
	var stored_reduced_motion: Variant = settings.get("reduced_motion", false)
	return {
		"ok": true,
		"text_scale_bps": scale,
		"high_contrast": stored_high_contrast if stored_high_contrast is bool else false,
		"reduced_motion": stored_reduced_motion if stored_reduced_motion is bool else false,
	}


func apply_settings(draft: Variant) -> Dictionary:
	if not _can_mutate() or not draft is Dictionary:
		return _failure("Settings are unavailable.")
	var text_scale: Variant = draft.get("text_scale_bps", null)
	if not text_scale is int or int(text_scale) not in [10000, 15000] or not draft.get("high_contrast", null) is bool or not draft.get("reduced_motion", null) is bool:
		return _failure("Settings draft is invalid.")
	var candidate := _profile.duplicate(true)
	var existing: Variant = candidate.get("team_prototype_settings", {})
	var merged: Dictionary = existing.duplicate(true) if existing is Dictionary else {}
	merged["text_scale_bps"] = int(text_scale)
	merged["high_contrast"] = bool(draft.high_contrast)
	merged["reduced_motion"] = bool(draft.reduced_motion)
	candidate["team_prototype_settings"] = merged
	var current := settings_view()
	if int(current.text_scale_bps) == int(text_scale) and bool(current.high_contrast) == bool(draft.high_contrast) and bool(current.reduced_motion) == bool(draft.reduced_motion):
		return {"ok": true, "settings": current, "duplicate": true}
	if not _persist_profile(candidate):
		return _failure("Settings could not be saved.")
	var recreated_collection := CollectionSession.create(_profile, Callable(_proxy, "profile"))
	if not bool(recreated_collection.get("ok", false)):
		return _failure("Settings saved but Collection refresh failed.")
	_collection = recreated_collection.session
	var recreated_match := MatchSession.create(_profile, _compatibility, _store.ledger_exists(), _store.ledger_value(), _store.cursor_value(), Callable(_proxy, "ledger"), Callable(_proxy, "cursor"))
	if not bool(recreated_match.get("ok", false)):
		return _failure("Settings saved but Match refresh failed.")
	_match = recreated_match.session
	return {"ok": true, "settings": settings_view()}


func preview_loadout(team: Variant, priority: Variant, kit: Variant) -> Dictionary:
	if _collection == null:
		return _failure("No active collection session.")
	return _collection.preview_loadout(team, priority, kit)


func collection_request(action: Variant, request_id: Variant, payload: Variant) -> Dictionary:
	if not _can_mutate():
		return _failure("Prototype runtime is read-only.")
	var projection: Dictionary = _collection.project()
	if not bool(projection.get("ok", false)):
		return _failure("Collection projection is invalid.")
	var expected_revision := int(projection.namespace_revision)
	var fingerprint := str(projection.fingerprint)
	if request_id is String:
		var prior: Variant = projection.prototype_state.get("requests", {}).get(str(request_id), {})
		if prior is Dictionary and not prior.is_empty():
			expected_revision = int(prior.get("expected_revision", expected_revision))
			fingerprint = str(prior.get("fingerprint", fingerprint))
	var result: Dictionary = _collection.request(action, request_id, expected_revision, fingerprint, payload)
	if not bool(result.get("ok", false)):
		_last_error = str(result.get("error", "Collection request failed."))
		return result
	_profile = _collection.snapshot()
	var refreshed: Dictionary = _match.update_collection(_profile, _compatibility)
	if not bool(refreshed.get("ok", false)):
		_last_error = str(refreshed.get("error", "Match collection refresh failed."))
		return _failure(_last_error)
	_last_error = ""
	return result


func start(request_id: Variant, expected_sequence: Variant, seed: Variant) -> Dictionary:
	if not _can_mutate():
		return _failure("Prototype runtime is read-only.")
	var prior_start: Variant = _match.snapshot().get("starts", {}).get(str(request_id), {})
	if prior_start is Dictionary and not prior_start.is_empty():
		return _match.start(request_id, expected_sequence, int(prior_start.collection_revision), str(prior_start.fingerprint), seed)
	if not _store.generations_match(["profile", "ledger"]):
		return _failure("Profile or match ledger changed outside this runtime; reload is required.")
	var projection: Dictionary = _collection.project()
	if not bool(projection.get("ok", false)):
		return _failure("Collection projection is invalid.")
	var result: Dictionary = _match.start(request_id, expected_sequence, projection.namespace_revision, projection.fingerprint, seed)
	_last_error = "" if bool(result.get("ok", false)) else str(result.get("error", "Start failed."))
	return result


func run_cycle(match_id: Variant, request_id: Variant, player_plan: Variant) -> Dictionary:
	if not _can_mutate():
		return _failure("Prototype runtime is read-only.")
	var result: Dictionary = _match.run_cycle(match_id, request_id, player_plan)
	_last_error = "" if bool(result.get("ok", false)) else str(result.get("error", "Run failed."))
	return result


func acknowledge(match_id: Variant, request_id: Variant, cursor: Variant) -> Dictionary:
	if not _can_mutate():
		return _failure("Prototype runtime is read-only.")
	var result: Dictionary = _match.acknowledge(match_id, request_id, cursor)
	_last_error = "" if bool(result.get("ok", false)) else str(result.get("error", "Acknowledgement failed."))
	return result


func skip(match_id: Variant, request_id: Variant, cursor: Variant) -> Dictionary:
	if not _can_mutate():
		return _failure("Prototype runtime is read-only.")
	var result: Dictionary = _match.skip(match_id, request_id, cursor)
	_last_error = "" if bool(result.get("ok", false)) else str(result.get("error", "Skip failed."))
	return result


func pending_receipt() -> Dictionary:
	return _match.pending_receipt() if _match != null else _failure("No active match session.")


func current_result() -> Dictionary:
	return _match.current_result() if _match != null else {}


func historical_result(match_id: Variant) -> Dictionary:
	return _match.historical_result(match_id) if _match != null else _failure("No active match session.")


func _persist_profile(candidate: Dictionary) -> bool:
	if _store == null or not _store.commit_profile(candidate):
		return false
	_profile = candidate.duplicate(true)
	return true


func _persist_ledger(candidate: Dictionary) -> bool:
	if _store == null:
		return false
	var current: Dictionary = _match.snapshot()
	var dependencies: Array = []
	if candidate.get("starts", {}).size() != current.get("starts", {}).size():
		dependencies.append("profile")
	return _store.commit_ledger(candidate, dependencies)


func _persist_cursor(candidate: Dictionary) -> bool:
	if _store == null or not _store.generations_match(["ledger", "cursor"]):
		return false
	return _store.commit_cursor(candidate, ["ledger"])


func _can_mutate() -> bool:
	return not is_recovery() and _store != null and _collection != null and _match != null


func _effective_recovery() -> String:
	if not _recovery.is_empty():
		return _recovery
	return _store.recovery_state() if _store != null else ""


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "error": message}
