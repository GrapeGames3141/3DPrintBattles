extends Node

const CollectionProjection := preload("res://scripts/team_collection/team_collection_projection.gd")
const CollectionSession := preload("res://scripts/team_collection/team_collection_session.gd")

var failures: Array[String] = []
var requires := 0
var groups := 0
var writes: Array = []
var reject_write := false


func require(value: bool, message: String) -> void:
	requires += 1
	if not value:
		failures.append(message)
		push_error(message)


func _ready() -> void:
	_test_projection_and_starter_mappings()
	_test_voucher_completion_and_idempotency()
	_test_fail_closed_projection_and_store_rollback()
	_test_explicit_loadout_apply()
	_test_atomic_persistence_and_source_preservation()
	_test_canonical_duplicates_freshness_and_json_restore()
	_test_strict_namespace_history_and_raw_validation()
	_test_loadout_failure_matrix()
	_test_support_topups_collisions_and_callback_isolation()
	_test_remaining_malformed_namespace_cases()
	require(groups == 10, "all Collection groups reach their end marker")
	print("TEAM_COLLECTION groups=%d/10 requires=%d failures=%d" % [groups, requires, failures.size()])
	if groups == 10:
		print("TEAM_COLLECTION failures=%d" % failures.size())
	get_tree().quit(0 if groups == 10 and failures.is_empty() else 1)


func _persist(candidate: Dictionary) -> bool:
	if reject_write:
		return false
	candidate["callback_mutation"] = true
	writes.append(candidate.duplicate(true))
	return true


func _profile() -> Dictionary:
	return {
		"schema_version": 31,
		"legacy_revision": 777,
		"coins": 123,
		"owned_blueprints": {},
		"owned_cards": {},
		"printed_models": {},
		"legacy_nested": {"keep": [1, true, "unchanged"]},
	}


func _json_clone(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value))


func _same_outside_prototype(before: Dictionary, after: Dictionary) -> bool:
	var left: Dictionary = before.duplicate(true)
	var right: Dictionary = after.duplicate(true)
	left.erase(CollectionProjection.NAMESPACE_KEY)
	right.erase(CollectionProjection.NAMESPACE_KEY)
	return JSON.stringify(left) == JSON.stringify(right)


func _restore_snapshot(snapshot: Dictionary) -> Dictionary:
	var parsed: Variant = _json_clone(snapshot)
	if not parsed is Dictionary:
		return {"ok": false}
	return _new_session(parsed)


func _new_session(profile: Dictionary) -> Dictionary:
	writes.clear()
	reject_write = false
	return CollectionSession.create(profile, Callable(self, "_persist"))


func _request(session: Variant, action: String, request_id: String, payload: Dictionary) -> Dictionary:
	var ownership: Dictionary = session.project()
	if not bool(ownership.get("ok", false)):
		return ownership
	return session.request(action, request_id, ownership.namespace_revision, ownership.fingerprint, payload)


func _choose_begin_complete(session: Variant, starter_id: String, prefix: String) -> Dictionary:
	var chosen: Dictionary = _request(session, "choose_starter", "%s-choose" % prefix, {"starter_id": starter_id})
	if not bool(chosen.get("ok", false)):
		return chosen
	var begun: Dictionary = _request(session, "begin_starter_print", "%s-begin" % prefix, {})
	if not bool(begun.get("ok", false)):
		return begun
	return _request(session, "complete_starter_print", "%s-complete" % prefix, {"print_id": begun.result.print_id})


func _test_projection_and_starter_mappings() -> void:
	var missing_ownership: Dictionary = {"schema_version": 31, "legacy_revision": 11, "legacy_nested": {"keep": "missing ownership remains absent"}}
	var missing_projection: Dictionary = CollectionProjection.project(missing_ownership)
	require(bool(missing_projection.get("ok", false)) and int(missing_projection.printed_counts.cinderpaw) == 0 and not missing_projection.namespace_exists, "missing raw ownership fields project as empty without inserting team_prototype")
	var preprinted_common: Dictionary = _profile()
	preprinted_common.printed_models["historic-aqua"] = {"blueprint_id": "aquafin", "source": "historic"}
	var preprinted_session: Dictionary = _new_session(preprinted_common)
	require(bool(preprinted_session.get("ok", false)), "preprinted-common fixture creates")
	if bool(preprinted_session.get("ok", false)):
		var preprinted_choice: Dictionary = _request(preprinted_session.session, "choose_starter", "preprinted-common", {"starter_id": "cinderpaw"})
		require(bool(preprinted_choice.get("ok", false)), "preprinted common still accepts its mapped starter binding")
		if bool(preprinted_choice.get("ok", false)):
			var preprinted_state: Dictionary = preprinted_session.session.project()
			require(bool(preprinted_state.licenses.aquafin) and int(preprinted_state.printed_counts.aquafin) == 1 and int(preprinted_state.prototype_state.prints.size()) == 1, "already Printed common receives only its missing License while the other common receives one guarantee print")
	var license_only: Dictionary = _profile()
	license_only.owned_blueprints["cinderpaw"] = true
	var license_only_session: Dictionary = _new_session(license_only)
	require(bool(license_only_session.get("ok", false)), "license-only chosen-starter fixture creates")
	if bool(license_only_session.get("ok", false)):
		var license_only_completed: Dictionary = _choose_begin_complete(license_only_session.session, "cinderpaw", "license-only")
		require(bool(license_only_completed.get("ok", false)) and int(license_only_session.session.project().printed_counts.cinderpaw) == 1, "chosen starter License-only ownership still receives exactly one visible voucher print")
	for starter_id in CollectionProjection.STARTERS:
		var source := _profile()
		var made: Dictionary = _new_session(source)
		require(bool(made.get("ok", false)), "%s empty ownership creates a read-only session" % starter_id)
		if not bool(made.get("ok", false)):
			continue
		var before: Dictionary = made.session.snapshot()
		require(JSON.stringify(before) == JSON.stringify(source) and writes.is_empty(), "%s create/projection performs no write" % starter_id)
		var chosen: Dictionary = _request(made.session, "choose_starter", "%s-choose" % starter_id, {"starter_id": starter_id})
		require(bool(chosen.get("ok", false)), "%s starter binding persists once" % starter_id)
		if bool(chosen.get("ok", false)):
			var expected_team: Array = [starter_id] + CollectionProjection.GUARANTEES[starter_id]
			require(chosen.result.recommended_team == expected_team and writes.size() == 1, "%s receipt maps starter plus exactly its two commons" % starter_id)
			var ownership: Dictionary = made.session.project()
			for member_id in expected_team:
				require(bool(ownership.licenses[member_id]), "%s mapping grants the required License for %s" % [starter_id, member_id])
			for common_id in CollectionProjection.GUARANTEES[starter_id]:
				require(int(ownership.printed_counts[common_id]) == 1, "%s mapping grants one missing preprint for %s" % [starter_id, common_id])
	groups += 1


func _test_voucher_completion_and_idempotency() -> void:
	var profile := _profile()
	profile.owned_blueprints["cinderpaw"] = true
	profile.printed_models["historic-cinder"] = {"blueprint_id": "cinderpaw", "source": "starter"}
	profile.owned_cards = {"raw_filament": 1, "heated_spool": 2, "standard_full_suit": 5, "iron_gem": 3, "forge_surge": 7}
	var made: Dictionary = _new_session(profile)
	require(bool(made.get("ok", false)), "preowned starter fixture creates")
	if not bool(made.get("ok", false)):
		return
	var completed: Dictionary = _choose_begin_complete(made.session, "cinderpaw", "voucher")
	require(bool(completed.get("ok", false)), "voucher print completion persists starter print and missing-only Support grants")
	if bool(completed.get("ok", false)):
		var ownership: Dictionary = made.session.project()
		require(int(ownership.printed_counts["cinderpaw"]) == 2, "already Printed chosen starter still receives exactly one visible voucher print")
		require(int(ownership.support_counts["raw_filament"]) == 3 and int(ownership.support_counts["heated_spool"]) == 2 and int(ownership.support_counts["standard_full_suit"]) == 5 and int(ownership.support_counts["iron_gem"]) == 3 and int(ownership.support_counts["forge_surge"]) == 7, "Support top-up adds only positive missing deficits and never reduces excess")
		var duplicate: Dictionary = made.session.request("complete_starter_print", "voucher-complete", 2, "0".repeat(64), {"print_id": completed.result.print_id})
		require(not bool(duplicate.get("ok", false)), "changed duplicate identity rejects before a second print or top-up")
		var receipt_id := str(completed.result.receipt_id)
		var ack: Dictionary = _request(made.session, "acknowledge_grant", "voucher-ack", {"receipt_id": receipt_id})
		require(bool(ack.get("ok", false)) and str(made.session.project().first_session_state) == "acknowledged", "grant acknowledgement advances only durable presentation state")
	groups += 1


func _test_fail_closed_projection_and_store_rollback() -> void:
	require(not bool(CollectionSession.create(_profile(), Callable()).get("ok", false)), "invalid persistence callback rejects session creation without a write path")
	var null_namespace := _profile()
	null_namespace[CollectionProjection.NAMESPACE_KEY] = null
	require(not bool(CollectionProjection.project(null_namespace).get("ok", false)), "present null namespace fails closed")
	var future_schema := _profile()
	future_schema.schema_version = 32
	require(not bool(CollectionProjection.project(future_schema).get("ok", false)), "future top-level schema fails closed")
	var invalid_count := _profile()
	invalid_count.owned_cards["raw_filament"] = true
	require(not bool(CollectionProjection.project(invalid_count).get("ok", false)), "Boolean relevant Support count fails closed")
	var unrelated_malformed := _profile()
	unrelated_malformed.printed_models["legacy-bad"] = 17
	require(bool(CollectionProjection.project(unrelated_malformed).get("ok", false)), "unrelated malformed historical print remains structurally ignored")
	var made: Dictionary = _new_session(_profile())
	require(bool(made.get("ok", false)), "rollback fixture creates")
	if bool(made.get("ok", false)):
		var before := JSON.stringify(made.session.snapshot())
		reject_write = true
		var rejected: Dictionary = _request(made.session, "choose_starter", "rollback-choose", {"starter_id": "aquafin"})
		require(not bool(rejected.get("ok", false)) and JSON.stringify(made.session.snapshot()) == before, "store rejection leaves the complete source snapshot unpublished")
		reject_write = false
	groups += 1


func _test_explicit_loadout_apply() -> void:
	var made: Dictionary = _new_session(_profile())
	require(bool(made.get("ok", false)), "loadout fixture creates")
	if not bool(made.get("ok", false)):
		return
	var completed: Dictionary = _choose_begin_complete(made.session, "cinderpaw", "loadout")
	require(bool(completed.get("ok", false)), "loadout fixture reaches settled grant")
	if not bool(completed.get("ok", false)):
		return
	var team := ["cinderpaw", "aquafin", "mossmunk"]
	var kit: Dictionary = CollectionProjection.recommended_kit_counts()
	var preview: Dictionary = made.session.preview_loadout(team, team, kit)
	require(bool(preview.get("ok", false)) and int(preview.writes) == 0, "valid Team and Kit preview is read-only")
	var before_apply := JSON.stringify(made.session.snapshot())
	var invalid: Dictionary = _request(made.session, "apply_loadout", "loadout-invalid", {"team": ["cinderpaw", "cinderpaw", "mossmunk"], "priority": team, "kit": kit})
	require(not bool(invalid.get("ok", false)) and JSON.stringify(made.session.snapshot()) == before_apply, "duplicate Team Apply rejects atomically")
	var applied: Dictionary = _request(made.session, "apply_loadout", "loadout-apply", {"team": team, "priority": team, "kit": kit})
	require(bool(applied.get("ok", false)) and made.session.project().saved_loadout.team == team, "explicit valid Apply saves Team, priority, and fifteen-card Kit together")
	groups += 1


func _test_atomic_persistence_and_source_preservation() -> void:
	var actions := ["choose_starter", "begin_starter_print", "complete_starter_print", "acknowledge_grant", "apply_loadout"]
	for action in actions:
		var source: Dictionary = _profile()
		var made: Dictionary = _new_session(source)
		require(bool(made.get("ok", false)), "%s rollback fixture creates" % action)
		if not bool(made.get("ok", false)):
			continue
		var session: Variant = made.session
		var payload: Dictionary = {}
		if action != "choose_starter":
			var chosen: Dictionary = _request(session, "choose_starter", "%s-choose" % action, {"starter_id": "cinderpaw"})
			require(bool(chosen.get("ok", false)), "%s rollback fixture chooses starter" % action)
		if action in ["complete_starter_print", "acknowledge_grant", "apply_loadout"]:
			var begun: Dictionary = _request(session, "begin_starter_print", "%s-begin" % action, {})
			require(bool(begun.get("ok", false)), "%s rollback fixture begins voucher" % action)
			payload = {"print_id": str(begun.result.print_id)} if action == "complete_starter_print" else payload
		if action in ["acknowledge_grant", "apply_loadout"]:
			var completed: Dictionary = _request(session, "complete_starter_print", "%s-complete" % action, {"print_id": str(session.project().prototype_state.voucher.print_id)})
			require(bool(completed.get("ok", false)), "%s rollback fixture completes voucher" % action)
			payload = {"receipt_id": str(completed.result.receipt_id)} if action == "acknowledge_grant" else payload
		if action == "apply_loadout":
			var team: Array = ["cinderpaw", "aquafin", "mossmunk"]
			payload = {"team": team, "priority": team.duplicate(), "kit": CollectionProjection.recommended_kit_counts()}
		if action == "choose_starter":
			payload = {"starter_id": "cinderpaw"}
		var before: Dictionary = session.snapshot()
		var writes_before: int = writes.size()
		reject_write = true
		var rejected: Dictionary = _request(session, action, "%s-reject" % action, payload)
		reject_write = false
		require(not bool(rejected.get("ok", false)) and JSON.stringify(session.snapshot()) == JSON.stringify(before) and writes.size() == writes_before, "%s store rejection is fully atomic" % action)
		var accepted: Dictionary = _request(session, action, "%s-accept" % action, payload)
		require(bool(accepted.get("ok", false)) and _same_outside_prototype(source, session.snapshot()), "%s accepted transition preserves every original top-level field outside team_prototype" % action)
	groups += 1


func _test_canonical_duplicates_freshness_and_json_restore() -> void:
	var source: Dictionary = _profile()
	var made: Dictionary = _new_session(source)
	require(bool(made.get("ok", false)), "canonical duplicate fixture creates")
	if not bool(made.get("ok", false)):
		groups += 1
		return
	var session: Variant = made.session
	var choose_fingerprint: String = str(session.project().fingerprint)
	var chosen: Dictionary = _request(session, "choose_starter", "canon-choose", {"starter_id": "cinderpaw"})
	require(bool(chosen.get("ok", false)), "canonical fixture chooses starter")
	var choose_snapshot: Dictionary = session.snapshot()
	var restored_choose: Dictionary = _restore_snapshot(choose_snapshot)
	require(bool(restored_choose.get("ok", false)), "available voucher JSON restore validates")
	if bool(restored_choose.get("ok", false)):
		var restored_writes_before: int = writes.size()
		var choose_duplicate: Dictionary = restored_choose.session.request("choose_starter", "canon-choose", 0, choose_fingerprint, {"starter_id": "cinderpaw"})
		require(bool(choose_duplicate.get("ok", false)) and bool(choose_duplicate.duplicate) and choose_duplicate.result == chosen.result and writes.size() == restored_writes_before, "exact original starter request replays immutable result with zero writes after JSON restore")
	var begun: Dictionary = _request(session, "begin_starter_print", "canon-begin", {})
	require(bool(begun.get("ok", false)), "canonical fixture begins voucher")
	var restored_printing: Dictionary = _restore_snapshot(session.snapshot())
	require(bool(restored_printing.get("ok", false)), "printing voucher JSON restore validates")
	var begin_duplicate: Dictionary = session.request("begin_starter_print", "canon-begin", 1, str(chosen.projection.fingerprint), {})
	require(bool(begin_duplicate.get("ok", false)) and bool(begin_duplicate.duplicate) and begin_duplicate.result == begun.result, "pending voucher Begin duplicate returns its original immutable result")
	var begin_mismatch: Dictionary = session.request("begin_starter_print", "canon-begin", 0, str(chosen.projection.fingerprint), {})
	require(not bool(begin_mismatch.get("ok", false)), "Begin request identity rejects changed original revision")
	var completion_revision: int = int(session.project().namespace_revision)
	var completion_fingerprint: String = str(session.project().fingerprint)
	var completion_payload: Dictionary = {"print_id": str(begun.result.print_id)}
	var completed: Dictionary = session.request("complete_starter_print", "canon-complete", completion_revision, completion_fingerprint, completion_payload)
	require(bool(completed.get("ok", false)), "canonical fixture completes voucher")
	var restored_settled: Dictionary = _restore_snapshot(session.snapshot())
	require(bool(restored_settled.get("ok", false)), "settled grant JSON restore validates")
	var team: Array = ["cinderpaw", "aquafin", "mossmunk"]
	var kit: Dictionary = CollectionProjection.recommended_kit_counts()
	var applied: Dictionary = _request(session, "apply_loadout", "canon-apply", {"kit": kit, "priority": team.duplicate(), "team": team})
	require(bool(applied.get("ok", false)), "canonical payload accepts sorted-key-equivalent Apply")
	var writes_before_duplicate: int = writes.size()
	var completed_duplicate: Dictionary = session.request("complete_starter_print", "canon-complete", completion_revision, completion_fingerprint, completion_payload.duplicate(true))
	require(bool(completed_duplicate.get("ok", false)) and bool(completed_duplicate.duplicate) and completed_duplicate.result == completed.result and writes.size() == writes_before_duplicate, "completion duplicate remains immutable after later Apply")
	var changed_duplicate: Dictionary = session.request("complete_starter_print", "canon-complete", completion_revision, completion_fingerprint, {"print_id": "different"})
	require(not bool(changed_duplicate.get("ok", false)), "request identity with changed payload rejects")
	var externally_changed: Dictionary = session.snapshot()
	externally_changed.owned_cards["raw_filament"] = 1
	var restored_changed: Dictionary = _restore_snapshot(externally_changed)
	require(bool(restored_changed.get("ok", false)), "later raw ownership changes do not invalidate a frozen receipt")
	if bool(restored_changed.get("ok", false)):
		var raw_duplicate: Dictionary = restored_changed.session.request("complete_starter_print", "canon-complete", completion_revision, completion_fingerprint, completion_payload)
		require(bool(raw_duplicate.get("ok", false)) and bool(raw_duplicate.duplicate) and writes.is_empty(), "original completion duplicate stays zero-write after later raw Support acquisition")
		var stale_new_request: Dictionary = restored_changed.session.request("acknowledge_grant", "canon-stale", completion_revision, completion_fingerprint, {"receipt_id": str(completed.result.receipt_id)})
		require(not bool(stale_new_request.get("ok", false)), "new request with a stale raw-ownership fingerprint rejects")
	var acknowledge_revision: int = int(session.project().namespace_revision)
	var acknowledge_fingerprint: String = str(session.project().fingerprint)
	var acknowledge_payload: Dictionary = {"receipt_id": str(completed.result.receipt_id)}
	var acknowledged: Dictionary = session.request("acknowledge_grant", "canon-ack", acknowledge_revision, acknowledge_fingerprint, acknowledge_payload)
	require(bool(acknowledged.get("ok", false)) and bool(_restore_snapshot(session.snapshot()).get("ok", false)), "acknowledged durable state JSON restore validates")
	var acknowledge_duplicate: Dictionary = session.request("acknowledge_grant", "canon-ack", acknowledge_revision, acknowledge_fingerprint, acknowledge_payload.duplicate(true))
	require(bool(acknowledge_duplicate.get("ok", false)) and bool(acknowledge_duplicate.duplicate) and acknowledge_duplicate.result == acknowledged.result, "acknowledgement duplicate is zero-grant immutable replay")
	var acknowledge_mismatch: Dictionary = session.request("acknowledge_grant", "canon-ack", acknowledge_revision, acknowledge_fingerprint, {"receipt_id": "tp-receipt-other"})
	require(not bool(acknowledge_mismatch.get("ok", false)), "acknowledgement request identity rejects a different receipt payload")
	var fingerprint_a: String = str(CollectionProjection.project(_profile()).fingerprint)
	var changed_card_profile: Dictionary = _profile()
	changed_card_profile.owned_cards["cinderpaw"] = 2
	var fingerprint_b: String = str(CollectionProjection.project(changed_card_profile).fingerprint)
	var changed_instance_profile: Dictionary = _profile()
	changed_instance_profile.printed_models["one"] = {"blueprint_id": "aquafin"}
	var fingerprint_c: String = str(CollectionProjection.project(changed_instance_profile).fingerprint)
	require(fingerprint_a != fingerprint_b and fingerprint_a != fingerprint_c, "relevant raw count and raw instance identity both change freshness fingerprint")
	groups += 1


func _test_strict_namespace_history_and_raw_validation() -> void:
	var base: Dictionary = _profile()
	var made: Dictionary = _new_session(base)
	require(bool(made.get("ok", false)), "strict schema fixture creates")
	if not bool(made.get("ok", false)):
		groups += 1
		return
	var session: Variant = made.session
	var chosen: Dictionary = _request(session, "choose_starter", "strict-choose", {"starter_id": "cinderpaw"})
	require(bool(chosen.get("ok", false)), "strict schema fixture binds starter")
	var available: Dictionary = session.snapshot()
	var invalid_available: Dictionary = available.duplicate(true)
	invalid_available.team_prototype.support_grants.raw_filament = 1
	require(not bool(CollectionProjection.project(invalid_available).get("ok", false)), "available voucher cannot contain Support grants")
	var invalid_loadout: Dictionary = available.duplicate(true)
	invalid_loadout.team_prototype.saved_loadout = {"team": ["cinderpaw", "aquafin", "mossmunk"], "priority": ["cinderpaw", "aquafin", "mossmunk"], "kit": CollectionProjection.recommended_kit_counts()}
	require(not bool(CollectionProjection.project(invalid_loadout).get("ok", false)), "available voucher cannot contain a saved loadout")
	var duplicate_guarantee: Dictionary = available.duplicate(true)
	duplicate_guarantee.team_prototype.prints["tp-grant-second-aquafin"] = {"instance_id": "tp-grant-second-aquafin", "blueprint_id": "aquafin", "source": "guarantee"}
	require(not bool(CollectionProjection.project(duplicate_guarantee).get("ok", false)), "duplicate namespaced guarantee print rejects")
	var future_history: Dictionary = available.duplicate(true)
	future_history.team_prototype.revision = 2
	require(not bool(CollectionProjection.project(future_history).get("ok", false)), "revision and request-history count mismatch rejects")
	var gap_history: Dictionary = available.duplicate(true)
	gap_history.team_prototype.requests["strict-gap"] = gap_history.team_prototype.requests["strict-choose"].duplicate(true)
	gap_history.team_prototype.requests["strict-gap"].result.request_id = "strict-gap"
	gap_history.team_prototype.requests["strict-gap"].result.revision = 3
	gap_history.team_prototype.revision = 3
	require(not bool(CollectionProjection.project(gap_history).get("ok", false)), "request-history revision gaps reject")
	var malformed_result: Dictionary = available.duplicate(true)
	malformed_result.team_prototype.requests["strict-choose"].result["unknown"] = true
	require(not bool(CollectionProjection.project(malformed_result).get("ok", false)), "unknown request result fields reject")
	var overlong_request: Dictionary = available.duplicate(true)
	var old_record: Dictionary = overlong_request.team_prototype.requests["strict-choose"]
	overlong_request.team_prototype.requests.erase("strict-choose")
	overlong_request.team_prototype.requests["x".repeat(97)] = old_record
	old_record.result.request_id = "x".repeat(97)
	require(not bool(CollectionProjection.project(overlong_request).get("ok", false)), "request ID over ninety-six characters rejects")
	var malformed_delta: Dictionary = _profile()
	var delta_made: Dictionary = _new_session(malformed_delta)
	var delta_completed: Dictionary = _choose_begin_complete(delta_made.session, "cinderpaw", "delta")
	require(bool(delta_completed.get("ok", false)), "missing-only receipt corruption fixture settles")
	if bool(delta_completed.get("ok", false)):
		var invalid_delta: Dictionary = delta_made.session.snapshot()
		invalid_delta.team_prototype.grant_receipt.support.raw_filament = {"existing": 0, "delta": 500, "final": 500}
		invalid_delta.team_prototype.support_grants.raw_filament = 500
		require(not bool(CollectionProjection.project(invalid_delta).get("ok", false)), "historical receipt delta must be the exact missing-only top-up")
	var raw_bad_blueprint: Dictionary = _profile()
	raw_bad_blueprint.owned_blueprints["aquafin"] = 1
	require(not bool(CollectionProjection.project(raw_bad_blueprint).get("ok", false)), "relevant raw blueprint type rejects")
	var raw_bad_print: Dictionary = _profile()
	raw_bad_print.printed_models[7] = {"blueprint_id": "aquafin"}
	require(not bool(CollectionProjection.project(raw_bad_print).get("ok", false)), "relevant raw printed instance key rejects")
	var unrelated: Dictionary = _profile()
	unrelated.printed_models["legacy"] = {"blueprint_id": "not-eligible", "nested": {"anything": true}}
	require(bool(CollectionProjection.project(unrelated).get("ok", false)), "unrelated raw printed record remains ignored and preserved")
	groups += 1


func _test_loadout_failure_matrix() -> void:
	var made: Dictionary = _new_session(_profile())
	require(bool(made.get("ok", false)), "loadout failure fixture creates")
	if not bool(made.get("ok", false)):
		groups += 1
		return
	var session: Variant = made.session
	var completed: Dictionary = _choose_begin_complete(session, "cinderpaw", "matrix")
	require(bool(completed.get("ok", false)), "loadout failure fixture settles")
	if not bool(completed.get("ok", false)):
		groups += 1
		return
	var team: Array = ["cinderpaw", "aquafin", "mossmunk"]
	var kit: Dictionary = CollectionProjection.recommended_kit_counts()
	var before: Dictionary = session.snapshot()
	var four_team: Dictionary = _request(session, "apply_loadout", "matrix-four", {"team": ["cinderpaw", "aquafin", "mossmunk", "voltwig"], "priority": team, "kit": kit})
	require(not bool(four_team.get("ok", false)) and JSON.stringify(session.snapshot()) == JSON.stringify(before), "four-member Team Apply rejects atomically")
	var unprinted_team: Dictionary = _request(session, "apply_loadout", "matrix-unprinted", {"team": ["cinderpaw", "aquafin", "voltwig"], "priority": ["cinderpaw", "aquafin", "voltwig"], "kit": kit})
	require(not bool(unprinted_team.get("ok", false)), "unprinted eligible companion cannot enter Team")
	var duplicate_print_attempt: Dictionary = _request(session, "apply_loadout", "matrix-duplicate", {"team": ["cinderpaw", "cinderpaw", "mossmunk"], "priority": team, "kit": kit})
	require(not bool(duplicate_print_attempt.get("ok", false)), "multiple printed instances cannot bypass Team identity uniqueness")
	var wrong_priority: Dictionary = _request(session, "apply_loadout", "matrix-priority", {"team": team, "priority": ["cinderpaw", "aquafin", "aquafin"], "kit": kit})
	require(not bool(wrong_priority.get("ok", false)), "Team priority must remain an exact permutation")
	var short_kit: Dictionary = kit.duplicate(true)
	short_kit.raw_filament = 2
	var invalid_kit: Dictionary = _request(session, "apply_loadout", "matrix-kit", {"team": team, "priority": team, "kit": short_kit})
	require(not bool(invalid_kit.get("ok", false)), "short Support Kit rejects")
	var ineligible_kit: Dictionary = kit.duplicate(true)
	ineligible_kit.erase("forge_surge")
	ineligible_kit["legacy_trap"] = 4
	var trapped: Dictionary = _request(session, "apply_loadout", "matrix-trap", {"team": team, "priority": team, "kit": ineligible_kit})
	require(not bool(trapped.get("ok", false)), "ineligible Support Kit entry rejects")
	var current: Dictionary = session.project()
	var stale: Dictionary = session.request("apply_loadout", "matrix-stale", int(current.namespace_revision) - 1, str(current.fingerprint), {"team": team, "priority": team, "kit": kit})
	require(not bool(stale.get("ok", false)), "stale namespace revision rejects without applying draft")
	var preview_before: Dictionary = session.snapshot()
	var preview: Dictionary = session.preview_loadout(team, team, kit)
	require(bool(preview.get("ok", false)) and int(preview.writes) == 0 and JSON.stringify(session.snapshot()) == JSON.stringify(preview_before), "preview, Back, and Cancel require no collection mutation")
	groups += 1


func _test_support_topups_collisions_and_callback_isolation() -> void:
	var cases := [
		{"name": "zero", "cards": {}, "expected": {"raw_filament": 3, "heated_spool": 2, "standard_full_suit": 3, "iron_gem": 3, "forge_surge": 4}},
		{"name": "partial", "cards": {"raw_filament": 2, "heated_spool": 1, "standard_full_suit": 1, "iron_gem": 0, "forge_surge": 3}, "expected": {"raw_filament": 1, "heated_spool": 1, "standard_full_suit": 2, "iron_gem": 3, "forge_surge": 1}},
		{"name": "exact", "cards": CollectionProjection.recommended_kit_counts(), "expected": {"raw_filament": 0, "heated_spool": 0, "standard_full_suit": 0, "iron_gem": 0, "forge_surge": 0}},
		{"name": "excess", "cards": {"raw_filament": 9, "heated_spool": 8, "standard_full_suit": 7, "iron_gem": 6, "forge_surge": 5}, "expected": {"raw_filament": 0, "heated_spool": 0, "standard_full_suit": 0, "iron_gem": 0, "forge_surge": 0}},
	]
	for case_value in cases:
		var case_data: Dictionary = case_value
		var profile: Dictionary = _profile()
		profile.owned_cards = case_data.cards.duplicate(true)
		var made: Dictionary = _new_session(profile)
		require(bool(made.get("ok", false)), "%s Support fixture creates" % str(case_data.name))
		if not bool(made.get("ok", false)):
			continue
		var completed: Dictionary = _choose_begin_complete(made.session, "cinderpaw", "topup-%s" % str(case_data.name))
		require(bool(completed.get("ok", false)), "%s Support fixture completes once" % str(case_data.name))
		if bool(completed.get("ok", false)):
			for support_id in CollectionProjection.SUPPORTS:
				require(int(completed.result.support[support_id].delta) == int(case_data.expected[support_id]), "%s computes exactly the frozen missing-only %s delta" % [str(case_data.name), support_id])
			require(not made.session.snapshot().has("callback_mutation"), "%s callback receives an isolated candidate copy" % str(case_data.name))
	var collision_profile: Dictionary = _profile()
	collision_profile.printed_models["tp-grant-collision-aquafin"] = {"blueprint_id": "legacy-unrelated"}
	var collision: Dictionary = _new_session(collision_profile)
	require(bool(collision.get("ok", false)), "raw collision fixture creates")
	if bool(collision.get("ok", false)):
		var before_collision: Dictionary = collision.session.snapshot()
		var rejected_choose: Dictionary = _request(collision.session, "choose_starter", "collision", {"starter_id": "cinderpaw"})
		require(not bool(rejected_choose.get("ok", false)) and JSON.stringify(collision.session.snapshot()) == JSON.stringify(before_collision), "raw printed-model collision rejects guaranteed instance without publication")
	var voucher_collision_profile: Dictionary = _profile()
	voucher_collision_profile.printed_models["tp-voucher-voucher-collision-begin"] = {"blueprint_id": "cinderpaw"}
	var voucher_collision: Dictionary = _new_session(voucher_collision_profile)
	require(bool(voucher_collision.get("ok", false)), "voucher collision fixture creates")
	if bool(voucher_collision.get("ok", false)):
		var collision_choice: Dictionary = _request(voucher_collision.session, "choose_starter", "voucher-collision", {"starter_id": "cinderpaw"})
		require(bool(collision_choice.get("ok", false)), "voucher collision fixture chooses before print")
		var before_begin: Dictionary = voucher_collision.session.snapshot()
		var rejected_begin: Dictionary = _request(voucher_collision.session, "begin_starter_print", "voucher-collision-begin", {})
		require(not bool(rejected_begin.get("ok", false)) and JSON.stringify(voucher_collision.session.snapshot()) == JSON.stringify(before_begin), "raw printed-model collision rejects voucher print without consuming it")
	groups += 1


func _test_remaining_malformed_namespace_cases() -> void:
	var malformed_unknown: Dictionary = _profile()
	malformed_unknown[CollectionProjection.NAMESPACE_KEY] = CollectionProjection.new_namespace()
	malformed_unknown.team_prototype.extra = true
	require(not bool(CollectionProjection.project(malformed_unknown).get("ok", false)), "unknown namespace key fails closed")
	var malformed_version: Dictionary = _profile()
	malformed_version[CollectionProjection.NAMESPACE_KEY] = CollectionProjection.new_namespace()
	malformed_version.team_prototype.version = 2
	require(not bool(CollectionProjection.project(malformed_version).get("ok", false)), "unknown namespace version fails closed")
	var pregrant_loadout: Dictionary = _profile()
	pregrant_loadout[CollectionProjection.NAMESPACE_KEY] = CollectionProjection.new_namespace()
	pregrant_loadout.team_prototype.saved_loadout = {"team": ["cinderpaw", "aquafin", "mossmunk"], "priority": ["cinderpaw", "aquafin", "mossmunk"], "kit": CollectionProjection.recommended_kit_counts()}
	require(not bool(CollectionProjection.project(pregrant_loadout).get("ok", false)), "starterless saved loadout fails closed")
	var made: Dictionary = _new_session(_profile())
	require(bool(made.get("ok", false)), "malformed completed-history fixture creates")
	if bool(made.get("ok", false)):
		var completed: Dictionary = _choose_begin_complete(made.session, "cinderpaw", "malformed")
		require(bool(completed.get("ok", false)), "malformed completed-history fixture settles")
		if bool(completed.get("ok", false)):
			var snapshot: Dictionary = made.session.snapshot()
			var missing_result: Dictionary = snapshot.duplicate(true)
			missing_result.team_prototype.requests["malformed-complete"].result.erase("support")
			require(not bool(CollectionProjection.project(missing_result).get("ok", false)), "missing action result field fails closed")
			var wrong_result_id: Dictionary = snapshot.duplicate(true)
			wrong_result_id.team_prototype.requests["malformed-complete"].result.request_id = "not-the-record-key"
			require(not bool(CollectionProjection.project(wrong_result_id).get("ok", false)), "mismatched action-result request identity fails closed")
			var state_disagreement: Dictionary = snapshot.duplicate(true)
			state_disagreement.team_prototype.voucher.state = "available"
			state_disagreement.team_prototype.voucher.print_id = ""
			state_disagreement.team_prototype.voucher.receipt_id = ""
			require(not bool(CollectionProjection.project(state_disagreement).get("ok", false)), "request history and current voucher state must agree")
			var receipt_result_disagreement: Dictionary = snapshot.duplicate(true)
			receipt_result_disagreement.team_prototype.requests["malformed-complete"].result.receipt_id = "tp-receipt-other"
			require(not bool(CollectionProjection.project(receipt_result_disagreement).get("ok", false)), "completion result must retain the durable receipt identity")
	var printing_made: Dictionary = _new_session(_profile())
	if bool(printing_made.get("ok", false)):
		var printing_choice: Dictionary = _request(printing_made.session, "choose_starter", "printing-choose", {"starter_id": "cinderpaw"})
		var printing_begin: Dictionary = _request(printing_made.session, "begin_starter_print", "printing-begin", {})
		require(bool(printing_choice.get("ok", false)) and bool(printing_begin.get("ok", false)), "printing-history disagreement fixture reaches pending voucher")
		var wrong_pending_id: Dictionary = printing_made.session.snapshot()
		wrong_pending_id.team_prototype.voucher.print_id = "tp-voucher-different"
		require(not bool(CollectionProjection.project(wrong_pending_id).get("ok", false)), "pending voucher print identity must match its Begin request")
	var apply_made: Dictionary = _new_session(_profile())
	if bool(apply_made.get("ok", false)):
		var apply_completed: Dictionary = _choose_begin_complete(apply_made.session, "cinderpaw", "history-apply")
		var history_team: Array = ["cinderpaw", "aquafin", "mossmunk"]
		var history_apply: Dictionary = _request(apply_made.session, "apply_loadout", "history-apply-save", {"team": history_team, "priority": history_team.duplicate(), "kit": CollectionProjection.recommended_kit_counts()})
		require(bool(apply_completed.get("ok", false)) and bool(history_apply.get("ok", false)), "Apply-history corruption fixture reaches saved loadout")
		if bool(history_apply.get("ok", false)):
			var corrupt_apply_payload: Dictionary = apply_made.session.snapshot()
			corrupt_apply_payload.team_prototype.requests["history-apply-save"].payload.priority = ["aquafin", "cinderpaw", "mossmunk"]
			require(not bool(CollectionProjection.project(corrupt_apply_payload).get("ok", false)), "historical Apply payload must equal its immutable result")
			var empty_apply_payload: Dictionary = apply_made.session.snapshot()
			empty_apply_payload.team_prototype.requests["history-apply-save"].payload = {}
			require(not bool(CollectionProjection.project(empty_apply_payload).get("ok", false)), "empty historical Apply payload fails closed without dereference")
			var empty_apply_result: Dictionary = apply_made.session.snapshot()
			empty_apply_result.team_prototype.requests["history-apply-save"].result.saved_loadout = {}
			require(not bool(CollectionProjection.project(empty_apply_result).get("ok", false)), "empty historical Apply result fails closed without dereference")
			var corrupt_saved_loadout: Dictionary = apply_made.session.snapshot()
			corrupt_saved_loadout.team_prototype.saved_loadout.priority = ["aquafin", "cinderpaw", "mossmunk"]
			require(not bool(CollectionProjection.project(corrupt_saved_loadout).get("ok", false)), "current saved loadout must equal the latest historical Apply")
			var corrupt_choose_guarantees: Dictionary = apply_made.session.snapshot()
			corrupt_choose_guarantees.team_prototype.requests["history-apply-choose"].result.guarantees[1].member_id = "voltwig"
			require(not bool(CollectionProjection.project(corrupt_choose_guarantees).get("ok", false)), "starter guarantees retain their typed mapped order in request history")
	var float_schema: Dictionary = _profile()
	float_schema.schema_version = 31.5
	require(not bool(CollectionProjection.project(float_schema).get("ok", false)), "fractional top-level schema fails closed")
	var bool_schema: Dictionary = _profile()
	bool_schema.schema_version = true
	require(not bool(CollectionProjection.project(bool_schema).get("ok", false)), "Boolean top-level schema fails closed")
	groups += 1
