class_name TeamCollectionSession
extends RefCounted

## Transactional M2 collection authority. All persistence is injected and receives a
## deep candidate profile; this module has no save-service, GameManager, UI, or art
## dependency.

const CollectionProjection := preload("res://scripts/team_collection/team_collection_projection.gd")

const ACTIONS := ["choose_starter", "begin_starter_print", "complete_starter_print", "acknowledge_grant", "apply_loadout"]

var _profile: Dictionary = {}
var _persist: Callable = Callable()


static func create(raw_profile: Variant, persist: Callable) -> Dictionary:
	if not persist.is_valid():
		return _failure("Collection persistence callback is invalid.")
	var projection := CollectionProjection.project(raw_profile)
	if not bool(projection.get("ok", false)):
		return projection
	var session: Variant = load("res://scripts/team_collection/team_collection_session.gd").new()
	session._profile = raw_profile.duplicate(true)
	session._persist = persist
	return {"ok": true, "session": session, "projection": projection}


func snapshot() -> Dictionary:
	return _profile.duplicate(true)


func project() -> Dictionary:
	return CollectionProjection.project(_profile)


func request(action: Variant, request_id: Variant, expected_revision: Variant, ownership_fingerprint: Variant, payload: Variant) -> Dictionary:
	if not action is String or action not in ACTIONS or not _valid_id(request_id):
		return _failure("Collection action or request identity is invalid.")
	if not CollectionProjection._is_safe_integer(expected_revision) or int(expected_revision) < 0 or not CollectionProjection._valid_hash(ownership_fingerprint) or not payload is Dictionary:
		return _failure("Collection request freshness or payload is invalid.")
	var canonical_payload_result := CollectionProjection.canonical_json(payload)
	if not bool(canonical_payload_result.get("ok", false)):
		return canonical_payload_result
	var canonical_value: Variant = canonical_payload_result.get("value", null)
	if not canonical_value is Dictionary:
		return _failure("Collection payload canonicalization failed.")
	var canonical_payload: Dictionary = canonical_value
	var current := CollectionProjection.project(_profile)
	if not bool(current.get("ok", false)):
		return current
	var prototype_state: Dictionary = current.prototype_state
	var existing: Dictionary = prototype_state.requests.get(request_id, {})
	if not existing.is_empty():
		if _same_request(existing, action, canonical_payload, int(expected_revision), ownership_fingerprint):
			return {"ok": true, "duplicate": true, "result": existing.result.duplicate(true)}
		return _failure("Collection request ID was reused with different input.")
	if int(expected_revision) != int(current.namespace_revision) or ownership_fingerprint != str(current.fingerprint):
		return _failure("Collection request is stale.")
	var payload_error := CollectionProjection.validate_action_payload(action, canonical_payload)
	if not payload_error.is_empty():
		return _failure(payload_error)
	var candidate: Dictionary = _profile.duplicate(true)
	var candidate_namespace: Dictionary = current.prototype_state.duplicate(true)
	candidate[CollectionProjection.NAMESPACE_KEY] = candidate_namespace
	var transition := _apply_action(action, request_id, canonical_payload, current, candidate_namespace)
	if not bool(transition.get("ok", false)):
		return transition
	candidate_namespace.revision = int(candidate_namespace.revision) + 1
	var result: Dictionary = transition.result
	result["action"] = action
	result["request_id"] = request_id
	result["revision"] = int(candidate_namespace.revision)
	candidate_namespace.requests[request_id] = {
		"action": action,
		"payload": canonical_payload.duplicate(true),
		"expected_revision": int(expected_revision),
		"fingerprint": ownership_fingerprint,
		"result": result.duplicate(true),
	}
	var candidate_projection := CollectionProjection.project(candidate)
	if not bool(candidate_projection.get("ok", false)):
		return candidate_projection
	if not _persist_candidate(candidate):
		return _failure("Collection persistence rejected the candidate.")
	_profile = candidate
	return {"ok": true, "duplicate": false, "result": result.duplicate(true), "projection": candidate_projection}


func preview_loadout(team: Variant, priority: Variant, kit: Variant) -> Dictionary:
	var ownership := CollectionProjection.project(_profile)
	if not bool(ownership.get("ok", false)):
		return ownership
	var checked := CollectionProjection.validate_loadout(team, priority, kit, ownership)
	if not bool(checked.get("ok", false)):
		return checked
	return {
		"ok": true,
		"before": ownership.saved_loadout.duplicate(true),
		"draft": {"team": checked.team, "priority": checked.priority, "kit": checked.kit},
		"writes": 0,
	}


func _apply_action(action: String, request_id: String, payload: Dictionary, current: Dictionary, prototype_state: Dictionary) -> Dictionary:
	match action:
		"choose_starter":
			return _choose_starter(request_id, payload, current, prototype_state)
		"begin_starter_print":
			return _begin_starter_print(request_id, current, prototype_state)
		"complete_starter_print":
			return _complete_starter_print(request_id, payload, current, prototype_state)
		"acknowledge_grant":
			return _acknowledge_grant(payload, prototype_state)
		"apply_loadout":
			return _apply_loadout(payload, current, prototype_state)
	return _failure("Collection action is unsupported.")


func _choose_starter(request_id: String, payload: Dictionary, current: Dictionary, prototype_state: Dictionary) -> Dictionary:
	if not str(prototype_state.starter_id).is_empty() or str(prototype_state.voucher.state) != "none":
		return _failure("Starter binding is already immutable.")
	var starter_id := str(payload.starter_id)
	if starter_id not in CollectionProjection.STARTERS:
		return _failure("Starter choice is ineligible.")
	prototype_state.starter_id = starter_id
	prototype_state.voucher = {"state": "available", "print_id": "", "receipt_id": ""}
	var guarantees := []
	var entitlement_ids: Array = [starter_id] + CollectionProjection.GUARANTEES[starter_id]
	for member_id in entitlement_ids:
		var license_added := not bool(current.licenses[member_id])
		if license_added:
			prototype_state.licenses[member_id] = true
		var print_added := false
		if member_id != starter_id and int(current.printed_counts[member_id]) <= 0:
			var print_id := "tp-grant-%s-%s" % [request_id, member_id]
			if _print_id_collides(print_id, prototype_state):
				return _failure("Guaranteed print ID collides.")
			prototype_state.prints[print_id] = {"instance_id": print_id, "blueprint_id": member_id, "source": "guarantee"}
			print_added = true
		guarantees.append({"member_id": member_id, "license_added": license_added, "preprinted_added": print_added, "already_printed": int(current.printed_counts[member_id]) > 0})
	return {"ok": true, "result": {"starter_id": starter_id, "voucher": "available", "guarantees": guarantees, "recommended_team": [starter_id] + CollectionProjection.GUARANTEES[starter_id].duplicate()}}


func _begin_starter_print(request_id: String, _current: Dictionary, prototype_state: Dictionary) -> Dictionary:
	if str(prototype_state.voucher.state) != "available":
		return _failure("Starter voucher is not available.")
	var print_id := "tp-voucher-%s" % request_id
	if _print_id_collides(print_id, prototype_state):
		return _failure("Starter voucher print ID collides.")
	prototype_state.voucher = {"state": "printing", "print_id": print_id, "receipt_id": ""}
	return {"ok": true, "result": {"starter_id": prototype_state.starter_id, "print_id": print_id, "voucher": "printing"}}


func _complete_starter_print(request_id: String, payload: Dictionary, current: Dictionary, prototype_state: Dictionary) -> Dictionary:
	if str(prototype_state.voucher.state) != "printing" or str(payload.print_id) != str(prototype_state.voucher.print_id):
		return _failure("Starter print completion is stale or invalid.")
	var print_id := str(prototype_state.voucher.print_id)
	if prototype_state.prints.has(print_id):
		return _failure("Starter voucher print already exists.")
	var starter_id := str(prototype_state.starter_id)
	prototype_state.prints[print_id] = {"instance_id": print_id, "blueprint_id": starter_id, "source": "voucher"}
	var support_receipt := {}
	for support_id in CollectionProjection.SUPPORTS:
		var existing: int = int(current.support_counts[support_id])
		var target: int = int(CollectionProjection.recommended_kit_counts()[support_id])
		var delta: int = max(0, target - existing)
		prototype_state.support_grants[support_id] = int(prototype_state.support_grants[support_id]) + delta
		if support_id in ["standard_full_suit", "iron_gem"] and delta > 0 and not bool(current.licenses[support_id]):
			prototype_state.licenses[support_id] = true
		support_receipt[support_id] = {"existing": existing, "delta": delta, "final": existing + delta}
	var receipt_id := "tp-receipt-%s" % request_id
	if not prototype_state.grant_receipt.is_empty() or not str(prototype_state.voucher.receipt_id).is_empty():
		return _failure("Starter grant receipt already exists.")
	prototype_state.grant_receipt = {
		"receipt_id": receipt_id,
		"starter_id": starter_id,
		"print_id": print_id,
		"support": support_receipt,
		"guarantees": CollectionProjection.GUARANTEES[starter_id].duplicate(),
	}
	prototype_state.voucher = {"state": "settled", "print_id": print_id, "receipt_id": receipt_id}
	return {"ok": true, "result": {"starter_id": starter_id, "print_id": print_id, "receipt_id": receipt_id, "support": support_receipt.duplicate(true), "voucher": "settled"}}


func _acknowledge_grant(payload: Dictionary, prototype_state: Dictionary) -> Dictionary:
	if str(prototype_state.voucher.state) != "settled" or str(payload.receipt_id) != str(prototype_state.voucher.receipt_id):
		return _failure("Grant receipt acknowledgement is stale or invalid.")
	prototype_state.voucher.state = "acknowledged"
	return {"ok": true, "result": {"receipt_id": prototype_state.voucher.receipt_id, "voucher": "acknowledged"}}


func _apply_loadout(payload: Dictionary, current: Dictionary, prototype_state: Dictionary) -> Dictionary:
	if str(prototype_state.voucher.state) not in ["settled", "acknowledged"] or prototype_state.grant_receipt.is_empty():
		return _failure("Loadout Apply requires a settled starter grant receipt.")
	var checked := CollectionProjection.validate_loadout(payload.team, payload.priority, payload.kit, current)
	if not bool(checked.get("ok", false)):
		return checked
	prototype_state.saved_loadout = {"team": checked.team, "priority": checked.priority, "kit": checked.kit}
	return {"ok": true, "result": {"saved_loadout": prototype_state.saved_loadout.duplicate(true)}}

func _print_id_collides(print_id: String, prototype_state: Dictionary) -> bool:
	if prototype_state.prints.has(print_id):
		return true
	var raw_prints: Variant = _profile.get("printed_models", {})
	return raw_prints is Dictionary and raw_prints.has(print_id)


func _persist_candidate(candidate: Dictionary) -> bool:
	if not _persist.is_valid():
		return false
	var stored: Variant = _persist.call(candidate.duplicate(true))
	return stored is bool and bool(stored)


static func _same_request(record: Dictionary, action: String, payload: Dictionary, expected_revision: int, fingerprint: String) -> bool:
	var stored_payload := CollectionProjection.canonical_json(record.payload)
	var incoming_payload := CollectionProjection.canonical_json(payload)
	return bool(stored_payload.get("ok", false)) and bool(incoming_payload.get("ok", false)) and str(record.action) == action and str(stored_payload.json) == str(incoming_payload.json) and int(record.expected_revision) == expected_revision and str(record.fingerprint) == fingerprint


static func _valid_id(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length() > 96:
		return false
	for index in value.length():
		var character: String = value.substr(index, 1)
		if not (character.to_lower() >= "a" and character.to_lower() <= "z") and not (character >= "0" and character <= "9") and character not in ["_", "-"]:
			return false
	return true


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "error": message}
