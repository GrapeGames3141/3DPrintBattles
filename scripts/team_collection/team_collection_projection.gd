class_name TeamCollectionProjection
extends RefCounted

## Read-only M2 ownership projection. It deliberately reads only the relevant v3
## ownership fields and the additive team_prototype prototype_state; it never repairs or
## normalizes the surrounding profile.

const Data := preload("res://scripts/team_battle/team_battle_data.gd")

const NAMESPACE_KEY := "team_prototype"
const NAMESPACE_VERSION := 1
const MAX_SAFE_INTEGER := 9007199254740991
const MAX_V3_SCHEMA := 31
const STARTERS := ["cinderpaw", "aquafin", "voltwig"]
const MEMBERS := ["cinderpaw", "aquafin", "voltwig", "mossmunk"]
const SUPPORTS := ["raw_filament", "heated_spool", "standard_full_suit", "iron_gem", "forge_surge"]
const LICENSE_IDS := ["cinderpaw", "aquafin", "voltwig", "mossmunk", "standard_full_suit", "iron_gem"]
const ACTIONS := ["choose_starter", "begin_starter_print", "complete_starter_print", "acknowledge_grant", "apply_loadout"]
const GUARANTEES := {
	"cinderpaw": ["aquafin", "mossmunk"],
	"aquafin": ["voltwig", "mossmunk"],
	"voltwig": ["cinderpaw", "mossmunk"],
}
const NAMESPACE_KEYS := ["version", "revision", "starter_id", "voucher", "licenses", "prints", "support_grants", "grant_receipt", "saved_loadout", "requests"]
const VOUCHER_KEYS := ["state", "print_id", "receipt_id"]
const PRINT_KEYS := ["instance_id", "blueprint_id", "source"]
const RECEIPT_KEYS := ["receipt_id", "starter_id", "print_id", "support", "guarantees"]
const LOADOUT_KEYS := ["team", "priority", "kit"]
const REQUEST_KEYS := ["action", "payload", "expected_revision", "fingerprint", "result"]


static func project(raw_profile: Variant) -> Dictionary:
	if not raw_profile is Dictionary:
		return _failure("Collection profile must be a Dictionary.")
	var profile: Dictionary = raw_profile
	var schema_error := _validate_top_schema(profile)
	if not schema_error.is_empty():
		return _failure(schema_error)
	var raw_result := _project_raw_ownership(profile)
	if not bool(raw_result.get("ok", false)):
		return raw_result
	var namespace_result: Dictionary = _project_namespace(profile[NAMESPACE_KEY]) if profile.has(NAMESPACE_KEY) else {"ok": true, "exists": false, "prototype_state": new_namespace()}
	if not bool(namespace_result.get("ok", false)):
		return namespace_result
	var prototype_state: Dictionary = namespace_result.prototype_state
	var receipt_error := _validate_receipt_missing_only(prototype_state)
	if not receipt_error.is_empty():
		return _failure(receipt_error)
	var licenses := {}
	var printed := {}
	var support_counts := {}
	var sources := {}
	var license_sources := {}
	for license_id in LICENSE_IDS:
		var raw_license: bool = bool(raw_result.licenses[license_id])
		var namespace_license: bool = bool(prototype_state.licenses.get(license_id, false))
		licenses[license_id] = raw_license or namespace_license
		license_sources[license_id] = "raw" if raw_license else ("prototype_state" if namespace_license else "none")
	for member_id in MEMBERS:
		var print_total := int(raw_result.printed_counts[member_id]) + _namespace_print_count(prototype_state, member_id)
		if print_total > MAX_SAFE_INTEGER:
			return _failure("Effective Printed count exceeds the safe integer range.")
		printed[member_id] = print_total
		sources[member_id] = {
			"license": str(license_sources[member_id]),
			"printed_raw": int(raw_result.printed_counts[member_id]),
			"printed_namespace": _namespace_print_count(prototype_state, member_id),
		}
	for support_id in SUPPORTS:
		var support_total := int(raw_result.support_counts[support_id]) + int(prototype_state.support_grants[support_id])
		if support_total > MAX_SAFE_INTEGER:
			return _failure("Effective Support count exceeds the safe integer range.")
		support_counts[support_id] = support_total
	var relevant := {
		"schema_version": profile.get("schema_version", null),
		"raw_blueprint_facts": raw_result.blueprint_facts,
		"raw_card_facts": raw_result.card_facts,
		"raw_print_facts": raw_result.print_facts,
		"namespace_revision": int(prototype_state.revision),
		"namespace_licenses": prototype_state.licenses,
		"namespace_prints": prototype_state.prints,
		"namespace_support_grants": prototype_state.support_grants,
	}
	var fingerprint_result := _fingerprint(relevant)
	if not bool(fingerprint_result.get("ok", false)):
		return fingerprint_result
	var ownership := {
		"ok": true,
		"namespace_exists": bool(namespace_result.exists),
		"prototype_state": prototype_state,
		"namespace_revision": int(prototype_state.revision),
		"fingerprint": fingerprint_result.fingerprint,
		"licenses": licenses,
		"printed_counts": printed,
		"support_counts": support_counts,
		"sources": sources,
		"license_sources": license_sources,
		"first_session_state": str(prototype_state.voucher.state),
		"saved_loadout": prototype_state.saved_loadout,
		"recommended_team": _recommended_team(str(prototype_state.starter_id)),
		"recommended_kit": recommended_kit_counts(),
	}
	if not prototype_state.saved_loadout.is_empty():
		var saved_result := validate_loadout(prototype_state.saved_loadout.team, prototype_state.saved_loadout.priority, prototype_state.saved_loadout.kit, ownership)
		if not bool(saved_result.get("ok", false)):
			return _failure("team_prototype saved loadout is invalid against effective ownership.")
	return ownership


static func new_namespace() -> Dictionary:
	var licenses := {}
	var support_grants := {}
	for license_id in LICENSE_IDS:
		licenses[license_id] = false
	for support_id in SUPPORTS:
		support_grants[support_id] = 0
	return {
		"version": NAMESPACE_VERSION,
		"revision": 0,
		"starter_id": "",
		"voucher": {"state": "none", "print_id": "", "receipt_id": ""},
		"licenses": licenses,
		"prints": {},
		"support_grants": support_grants,
		"grant_receipt": {},
		"saved_loadout": {},
		"requests": {},
	}


static func recommended_kit_counts() -> Dictionary:
	var counts := {}
	for support_id in SUPPORTS:
		counts[support_id] = 0
	for support_id in Data.recommended_kit():
		counts[support_id] = int(counts[support_id]) + 1
	return counts


static func validate_loadout(team: Variant, priority: Variant, kit: Variant, ownership: Dictionary) -> Dictionary:
	if not team is Array or team.size() != 3:
		return _failure("Team must contain exactly three companions.")
	if not priority is Array or priority.size() != 3:
		return _failure("Team priority must contain exactly three companions.")
	var team_ids := {}
	for member_value in team:
		if not member_value is String or member_value not in MEMBERS or team_ids.has(member_value):
			return _failure("Team must contain three distinct eligible companions.")
		if int(ownership.printed_counts[member_value]) <= 0:
			return _failure("Team companion is not effectively Printed.")
		team_ids[member_value] = true
	var priority_ids := {}
	for priority_value in priority:
		if not priority_value is String or not team_ids.has(priority_value) or priority_ids.has(priority_value):
			return _failure("Team priority must be the exact Team permutation.")
		priority_ids[priority_value] = true
	if not kit is Dictionary or kit.size() != SUPPORTS.size():
		return _failure("Support Kit must contain only the five eligible Support counts.")
	var total := 0
	for support_id in SUPPORTS:
		if not kit.has(support_id) or not _is_safe_integer(kit[support_id]) or int(kit[support_id]) < 0:
			return _failure("Support Kit counts must be nonnegative whole numbers.")
		var count := int(kit[support_id])
		if count > int(ownership.support_counts[support_id]):
			return _failure("Support Kit uses more copies than effectively owned.")
		total += count
	for unknown_key in kit.keys():
		if not unknown_key is String or unknown_key not in SUPPORTS:
			return _failure("Support Kit contains an ineligible Support.")
	if total != 15:
		return _failure("Support Kit must contain exactly fifteen cards.")
	return {"ok": true, "team": team.duplicate(), "priority": priority.duplicate(), "kit": kit.duplicate(true)}


static func _project_raw_ownership(profile: Dictionary) -> Dictionary:
	var blueprints: Dictionary = {}
	var cards: Dictionary = {}
	var printed_models: Dictionary = {}
	for field in ["owned_blueprints", "owned_cards", "printed_models"]:
		if profile.has(field) and not profile[field] is Dictionary:
			return _failure("Relevant ownership field %s must be a Dictionary." % field)
	if profile.has("owned_blueprints"):
		blueprints = profile.owned_blueprints
	if profile.has("owned_cards"):
		cards = profile.owned_cards
	if profile.has("printed_models"):
		printed_models = profile.printed_models
	var raw_licenses := {}
	var printed_counts := {}
	var support_counts := {}
	var blueprint_facts := {}
	var card_facts := {}
	var print_facts := {}
	for license_id in LICENSE_IDS:
		var blueprint_value: Variant = blueprints.get(license_id, false)
		if blueprints.has(license_id) and not blueprint_value is bool:
			return _failure("Relevant blueprint ownership must be Boolean.")
		var card_value: Variant = cards.get(license_id, 0)
		if cards.has(license_id) and (not _is_safe_integer(card_value) or int(card_value) < 0):
			return _failure("Relevant License ownership count is invalid.")
		raw_licenses[license_id] = bool(blueprint_value) or int(card_value) > 0
		blueprint_facts[license_id] = bool(blueprint_value)
		card_facts[license_id] = int(card_value)
	for member_id in MEMBERS:
		printed_counts[member_id] = 0
	for support_id in SUPPORTS:
		var support_value: Variant = cards.get(support_id, 0)
		if cards.has(support_id) and (not _is_safe_integer(support_value) or int(support_value) < 0):
			return _failure("Relevant Support ownership count is invalid.")
		support_counts[support_id] = int(support_value)
		card_facts[support_id] = int(support_value)
	for instance_key in printed_models.keys():
		var record_value: Variant = printed_models[instance_key]
		if not record_value is Dictionary:
			continue
		var record: Dictionary = record_value
		if not record.has("blueprint_id"):
			continue
		if not record.blueprint_id is String:
			continue
		if record.blueprint_id in MEMBERS:
			if not instance_key is String or instance_key.is_empty():
				return _failure("Relevant printed model instance key is invalid.")
			printed_counts[record.blueprint_id] = int(printed_counts[record.blueprint_id]) + 1
			print_facts[instance_key] = record.blueprint_id
	return {"ok": true, "licenses": raw_licenses, "printed_counts": printed_counts, "support_counts": support_counts, "blueprint_facts": blueprint_facts, "card_facts": card_facts, "print_facts": print_facts}


static func _project_namespace(namespace_value: Variant) -> Dictionary:
	if namespace_value == null:
		return _failure("team_prototype prototype_state cannot be null.")
	if not namespace_value is Dictionary:
		return _failure("team_prototype prototype_state must be a Dictionary.")
	var prototype_state: Dictionary = namespace_value
	if not _has_exact_keys(prototype_state, NAMESPACE_KEYS):
		return _failure("team_prototype prototype_state keys are invalid.")
	if not _is_safe_integer(prototype_state.version) or int(prototype_state.version) != NAMESPACE_VERSION or not _is_safe_integer(prototype_state.revision) or int(prototype_state.revision) < 0:
		return _failure("team_prototype prototype_state version or revision is invalid.")
	if not prototype_state.starter_id is String or (not prototype_state.starter_id.is_empty() and prototype_state.starter_id not in STARTERS):
		return _failure("team_prototype starter binding is invalid.")
	var voucher_error := _validate_voucher(prototype_state.voucher, str(prototype_state.starter_id))
	if not voucher_error.is_empty():
		return _failure(voucher_error)
	var licenses_error := _validate_boolean_map(prototype_state.licenses, LICENSE_IDS, "team_prototype licenses")
	if not licenses_error.is_empty():
		return _failure(licenses_error)
	var support_error := _validate_count_map(prototype_state.support_grants, SUPPORTS, "team_prototype Support grants")
	if not support_error.is_empty():
		return _failure(support_error)
	var prints_error := _validate_namespace_prints(prototype_state.prints)
	if not prints_error.is_empty():
		return _failure(prints_error)
	var receipt_error := _validate_receipt(prototype_state.grant_receipt, prototype_state)
	if not receipt_error.is_empty():
		return _failure(receipt_error)
	var loadout_error := _validate_saved_loadout_shape(prototype_state.saved_loadout)
	if not loadout_error.is_empty():
		return _failure(loadout_error)
	var request_error := _validate_requests(prototype_state.requests, int(prototype_state.revision))
	if not request_error.is_empty():
		return _failure(request_error)
	var consistency_error := _validate_namespace_consistency(prototype_state)
	if not consistency_error.is_empty():
		return _failure(consistency_error)
	var normalized_result := _normalize_relevant_json(prototype_state)
	if not bool(normalized_result.get("ok", false)) or not normalized_result.value is Dictionary:
		return _failure("team_prototype namespace cannot be canonically normalized.")
	return {"ok": true, "exists": true, "prototype_state": normalized_result.value}


static func _validate_voucher(value: Variant, starter_id: String) -> String:
	if not value is Dictionary or not _has_exact_keys(value, VOUCHER_KEYS):
		return "team_prototype voucher schema is invalid."
	var voucher: Dictionary = value
	if not voucher.state is String or not voucher.print_id is String or not voucher.receipt_id is String:
		return "team_prototype voucher values are invalid."
	if starter_id.is_empty():
		return "team_prototype prototype_state has no starter binding." if voucher.state != "none" or not voucher.print_id.is_empty() or not voucher.receipt_id.is_empty() else ""
	if voucher.state not in ["available", "printing", "settled", "acknowledged"]:
		return "team_prototype voucher state is invalid."
	if voucher.state == "available" and (not voucher.print_id.is_empty() or not voucher.receipt_id.is_empty()):
		return "Available voucher cannot contain print or receipt IDs."
	if voucher.state == "printing" and (voucher.print_id.is_empty() or not voucher.receipt_id.is_empty()):
		return "Printing voucher requires only its pending print ID."
	if voucher.state in ["settled", "acknowledged"] and (voucher.print_id.is_empty() or voucher.receipt_id.is_empty()):
		return "Settled voucher requires print and receipt IDs."
	return ""


static func _validate_boolean_map(value: Variant, expected: Array, label: String) -> String:
	if not value is Dictionary or not _has_exact_keys(value, expected):
		return "%s keys are invalid." % label
	for key in expected:
		if not value[key] is bool:
			return "%s values must be Boolean." % label
	return ""


static func _validate_count_map(value: Variant, expected: Array, label: String) -> String:
	if not value is Dictionary or not _has_exact_keys(value, expected):
		return "%s keys are invalid." % label
	for key in expected:
		if not _is_safe_integer(value[key]) or int(value[key]) < 0:
			return "%s values must be nonnegative whole numbers." % label
	return ""


static func _validate_namespace_prints(value: Variant) -> String:
	if not value is Dictionary:
		return "team_prototype prints must be a Dictionary."
	for print_id in value.keys():
		if not print_id is String or print_id.is_empty() or not value[print_id] is Dictionary:
			return "team_prototype print record is invalid."
		var record: Dictionary = value[print_id]
		if not _is_derived_id(print_id) or not _has_exact_keys(record, PRINT_KEYS) or str(record.instance_id) != print_id or not record.blueprint_id is String or record.blueprint_id not in MEMBERS or not record.source is String or record.source not in ["guarantee", "voucher"]:
			return "team_prototype print record schema is invalid."
	return ""


static func _validate_receipt(value: Variant, prototype_state: Dictionary) -> String:
	if value is Dictionary and value.is_empty():
		return "" if str(prototype_state.voucher.state) in ["none", "available", "printing"] else "Settled voucher requires a grant receipt."
	if not value is Dictionary or not _has_exact_keys(value, RECEIPT_KEYS):
		return "team_prototype grant receipt schema is invalid."
	var receipt: Dictionary = value
	if not _is_derived_id(receipt.receipt_id) or receipt.receipt_id != prototype_state.voucher.receipt_id or receipt.starter_id != prototype_state.starter_id or receipt.print_id != prototype_state.voucher.print_id:
		return "team_prototype grant receipt identity is invalid."
	if not receipt.support is Dictionary or not _has_exact_keys(receipt.support, SUPPORTS):
		return "team_prototype grant receipt Support is invalid."
	for support_id in SUPPORTS:
		var fact_value: Variant = receipt.support[support_id]
		if not fact_value is Dictionary or not _has_exact_keys(fact_value, ["existing", "delta", "final"]):
			return "team_prototype grant receipt Support fact is invalid."
		if not _is_safe_integer(fact_value.existing) or not _is_safe_integer(fact_value.delta) or not _is_safe_integer(fact_value.final) or int(fact_value.existing) < 0 or int(fact_value.delta) < 0 or int(fact_value.final) != int(fact_value.existing) + int(fact_value.delta):
			return "team_prototype grant receipt Support arithmetic is invalid."
	if not receipt.guarantees is Array or receipt.guarantees != GUARANTEES[str(prototype_state.starter_id)]:
		return "team_prototype grant receipt guarantees are invalid."
	if not prototype_state.prints.has(receipt.print_id) or str(prototype_state.prints[receipt.print_id].blueprint_id) != str(prototype_state.starter_id):
		return "team_prototype grant receipt starter print is invalid."
	return ""


static func _validate_receipt_missing_only(prototype_state: Dictionary) -> String:
	var voucher_state := str(prototype_state.voucher.state)
	if voucher_state not in ["settled", "acknowledged"]:
		return ""
	var receipt: Dictionary = prototype_state.grant_receipt
	for support_id in SUPPORTS:
		var fact: Dictionary = receipt.support[support_id]
		var existing: int = int(fact.existing)
		var target: int = int(recommended_kit_counts()[support_id])
		var expected_delta: int = max(0, target - existing)
		if int(fact.delta) != expected_delta or int(fact.final) != existing + expected_delta:
			return "team_prototype grant receipt is not the immutable missing-only Support top-up."
	return ""


static func _validate_saved_loadout_shape(value: Variant) -> String:
	if value is Dictionary and value.is_empty():
		return ""
	if not value is Dictionary or not _has_exact_keys(value, LOADOUT_KEYS):
		return "team_prototype saved loadout schema is invalid."
	if not value.team is Array or not value.priority is Array or not value.kit is Dictionary:
		return "team_prototype saved loadout values are invalid."
	return ""


static func _validate_requests(value: Variant, prototype_revision: int) -> String:
	if not value is Dictionary:
		return "team_prototype request history must be a Dictionary."
	if value.size() != prototype_revision:
		return "team_prototype request history must match namespace revision."
	var seen_revisions := {}
	for request_id in value.keys():
		if not _is_stable_id(request_id) or not value[request_id] is Dictionary:
			return "team_prototype request record is invalid."
		var record: Dictionary = value[request_id]
		if not _has_exact_keys(record, REQUEST_KEYS) or not record.action is String or record.action not in ACTIONS or not record.payload is Dictionary or not _is_safe_integer(record.expected_revision) or int(record.expected_revision) < 0 or not _valid_hash(record.fingerprint) or not record.result is Dictionary:
			return "team_prototype request record schema is invalid."
		var payload_error := validate_action_payload(str(record.action), record.payload)
		if not payload_error.is_empty() or not _validate_request_result(record.action, request_id, record.result).is_empty() or not _is_safe_integer(record.result.revision) or int(record.result.revision) != int(record.expected_revision) + 1 or int(record.result.revision) > prototype_revision or seen_revisions.has(int(record.result.revision)):
			return "team_prototype request record values are invalid."
		seen_revisions[int(record.result.revision)] = true
	for revision in range(1, prototype_revision + 1):
		if not seen_revisions.has(revision):
			return "team_prototype request history has a revision gap."
	return ""


static func _validate_request_result(action: String, request_id: String, value: Variant) -> String:
	if not value is Dictionary:
		return "Collection request result must be a Dictionary."
	var result: Dictionary = value
	var expected: Array = ["action", "request_id", "revision"]
	match action:
		"choose_starter":
			expected.append_array(["starter_id", "voucher", "guarantees", "recommended_team"])
		"begin_starter_print":
			expected.append_array(["starter_id", "print_id", "voucher"])
		"complete_starter_print":
			expected.append_array(["starter_id", "print_id", "receipt_id", "support", "voucher"])
		"acknowledge_grant":
			expected.append_array(["receipt_id", "voucher"])
		"apply_loadout":
			expected.append("saved_loadout")
	if not _has_exact_keys(result, expected) or str(result.action) != action or str(result.request_id) != request_id:
		return "Collection request result identity or keys are invalid."
	if action == "choose_starter":
		if not result.starter_id is String or result.starter_id not in STARTERS or str(result.voucher) != "available" or not result.guarantees is Array or result.guarantees.size() != 3 or not result.recommended_team is Array or result.recommended_team != _recommended_team(str(result.starter_id)):
			return "Starter request result is invalid."
		var expected_members: Array = _recommended_team(str(result.starter_id))
		for index in result.guarantees.size():
			var guarantee: Variant = result.guarantees[index]
			if not guarantee is Dictionary or not _has_exact_keys(guarantee, ["member_id", "license_added", "preprinted_added", "already_printed"]) or str(guarantee.member_id) != str(expected_members[index]) or not guarantee.license_added is bool or not guarantee.preprinted_added is bool or not guarantee.already_printed is bool:
				return "Starter request guarantee result is invalid."
	if action == "begin_starter_print":
		if not result.starter_id is String or result.starter_id not in STARTERS or not _is_derived_id(result.print_id) or str(result.voucher) != "printing":
			return "Starter-print request result is invalid."
	if action == "complete_starter_print":
		if not result.starter_id is String or result.starter_id not in STARTERS or not _is_derived_id(result.print_id) or not _is_derived_id(result.receipt_id) or str(result.voucher) != "settled" or not result.support is Dictionary or not _has_exact_keys(result.support, SUPPORTS):
			return "Starter-completion request result is invalid."
	if action == "acknowledge_grant" and (not _is_derived_id(result.receipt_id) or str(result.voucher) != "acknowledged"):
		return "Grant acknowledgement request result is invalid."
	if action == "apply_loadout" and _validate_static_loadout(result.saved_loadout) != "":
		return "Loadout Apply request result is invalid."
	return ""


static func _validate_static_loadout(value: Variant) -> String:
	if not value is Dictionary or value.is_empty() or not _has_exact_keys(value, LOADOUT_KEYS):
		return "Loadout schema is invalid."
	var loadout: Dictionary = value
	if not loadout.team is Array or not loadout.priority is Array or not loadout.kit is Dictionary:
		return "Loadout values are invalid."
	if loadout.team.size() != 3 or loadout.priority.size() != 3 or loadout.kit.size() != SUPPORTS.size():
		return "Loadout cardinality is invalid."
	var team_ids := {}
	for member_id in loadout.team:
		if not member_id is String or member_id not in MEMBERS or team_ids.has(member_id):
			return "Loadout Team is invalid."
		team_ids[member_id] = true
	var priority_ids := {}
	for member_id in loadout.priority:
		if not member_id is String or not team_ids.has(member_id) or priority_ids.has(member_id):
			return "Loadout priority is invalid."
		priority_ids[member_id] = true
	var total := 0
	for support_id in SUPPORTS:
		if not loadout.kit.has(support_id) or not _is_safe_integer(loadout.kit[support_id]) or int(loadout.kit[support_id]) < 0:
			return "Loadout Kit is invalid."
		total += int(loadout.kit[support_id])
	for support_id in loadout.kit.keys():
		if not support_id is String or support_id not in SUPPORTS:
			return "Loadout Kit contains an ineligible Support."
	return "" if total == 15 else "Loadout Kit must contain fifteen cards."


static func _validate_namespace_consistency(prototype_state: Dictionary) -> String:
	var starter_id := str(prototype_state.starter_id)
	if starter_id.is_empty():
		if not prototype_state.prints.is_empty() or not prototype_state.grant_receipt.is_empty() or not prototype_state.saved_loadout.is_empty() or not prototype_state.requests.is_empty():
			return "Starterless prototype_state cannot contain grants, prints, loadouts, or requests."
		for license_id in LICENSE_IDS:
			if bool(prototype_state.licenses[license_id]):
				return "Starterless prototype_state cannot contain licenses."
		for support_id in SUPPORTS:
			if int(prototype_state.support_grants[support_id]) != 0:
				return "Starterless prototype_state cannot contain Support grants."
		return ""
	var guarantee_ids: Array = GUARANTEES[starter_id]
	var voucher_state := str(prototype_state.voucher.state)
	var history_error := _validate_history_matches_voucher(prototype_state, voucher_state)
	if not history_error.is_empty():
		return history_error
	if voucher_state in ["available", "printing"]:
		if not prototype_state.grant_receipt.is_empty() or not prototype_state.saved_loadout.is_empty():
			return "Uncompleted voucher cannot contain a receipt or saved loadout."
		for support_id in SUPPORTS:
			if int(prototype_state.support_grants[support_id]) != 0:
				return "Uncompleted voucher cannot contain Support grants."
	var voucher_print_id := str(prototype_state.voucher.print_id)
	var voucher_print_count := 0
	var guarantee_print_counts := {}
	for member_id in guarantee_ids:
		guarantee_print_counts[member_id] = 0
	for print_id in prototype_state.prints.keys():
		var print_record: Dictionary = prototype_state.prints[print_id]
		if str(print_record.source) == "voucher":
			voucher_print_count += 1
			if print_id != voucher_print_id or str(print_record.blueprint_id) != starter_id:
				return "Voucher print must be the bound starter exactly once."
		elif str(print_record.source) == "guarantee":
			if str(print_record.blueprint_id) not in guarantee_ids:
				return "Guaranteed print does not match the bound starter mapping."
			guarantee_print_counts[str(print_record.blueprint_id)] = int(guarantee_print_counts[str(print_record.blueprint_id)]) + 1
			if int(guarantee_print_counts[str(print_record.blueprint_id)]) > 1:
				return "Each guaranteed companion may receive at most one namespaced print."
		else:
			return "team_prototype print source is invalid."
	if voucher_state in ["available", "printing"] and voucher_print_count != 0:
		return "Voucher print cannot exist before completion."
	if voucher_state in ["settled", "acknowledged"] and voucher_print_count != 1:
		return "Settled voucher requires exactly one starter print."
	if voucher_state in ["settled", "acknowledged"]:
		var receipt: Dictionary = prototype_state.grant_receipt
		for support_id in SUPPORTS:
			if int(prototype_state.support_grants[support_id]) != int(receipt.support[support_id].delta):
				return "Support grants must equal the immutable receipt deltas."
	return ""


static func _validate_history_matches_voucher(prototype_state: Dictionary, voucher_state: String) -> String:
	var requests: Dictionary = prototype_state.requests
	var revision: int = int(prototype_state.revision)
	var records_by_revision := {}
	var request_ids_by_revision := {}
	for request_id in requests.keys():
		var record: Dictionary = requests[request_id]
		var record_revision: int = int(record.result.revision)
		records_by_revision[record_revision] = record
		request_ids_by_revision[record_revision] = str(request_id)
	var actions: Array = []
	for expected_revision in range(1, revision + 1):
		if not records_by_revision.has(expected_revision):
			return "Starter request history has a revision gap."
		actions.append(str(records_by_revision[expected_revision].action))
	if actions.is_empty() or str(actions[0]) != "choose_starter":
		return "Bound starter requires choose_starter as the first request."
	if actions.count("choose_starter") != 1 or actions.count("begin_starter_print") > 1 or actions.count("complete_starter_print") > 1 or actions.count("acknowledge_grant") > 1:
		return "Starter request history contains an impossible repeated transition."
	var begin_index := actions.find("begin_starter_print")
	var complete_index := actions.find("complete_starter_print")
	var acknowledge_index := actions.find("acknowledge_grant")
	if begin_index >= 0 and begin_index != 1:
		return "Starter-print request must follow starter choice."
	if complete_index >= 0 and (begin_index < 0 or complete_index <= begin_index):
		return "Starter completion must follow starter-print begin."
	if acknowledge_index >= 0 and (complete_index < 0 or acknowledge_index <= complete_index):
		return "Grant acknowledgement must follow completion."
	for index in actions.size():
		if str(actions[index]) == "apply_loadout" and (complete_index < 0 or index <= complete_index):
			return "Loadout Apply must follow starter completion."
	var choose_record: Dictionary = records_by_revision[1]
	if str(choose_record.payload.starter_id) != str(prototype_state.starter_id) or str(choose_record.result.starter_id) != str(prototype_state.starter_id):
		return "Starter request payload and result must match the bound starter."
	if begin_index >= 0:
		var begin_record: Dictionary = records_by_revision[begin_index + 1]
		var expected_print_id := "tp-voucher-%s" % str(request_ids_by_revision[begin_index + 1])
		if str(begin_record.result.starter_id) != str(prototype_state.starter_id) or str(begin_record.result.print_id) != expected_print_id or str(begin_record.result.print_id) != str(prototype_state.voucher.print_id):
			return "Starter-print request result must match the bound starter and voucher print ID."
	if complete_index >= 0:
		var complete_record: Dictionary = records_by_revision[complete_index + 1]
		var expected_receipt_id := "tp-receipt-%s" % str(request_ids_by_revision[complete_index + 1])
		if str(complete_record.payload.print_id) != str(prototype_state.voucher.print_id) or str(complete_record.result.starter_id) != str(prototype_state.starter_id) or str(complete_record.result.print_id) != str(prototype_state.voucher.print_id) or str(complete_record.result.receipt_id) != expected_receipt_id or str(complete_record.result.receipt_id) != str(prototype_state.voucher.receipt_id) or complete_record.result.support != prototype_state.grant_receipt.support:
			return "Starter-completion result must match the immutable voucher receipt."
	if acknowledge_index >= 0:
		var acknowledge_record: Dictionary = records_by_revision[acknowledge_index + 1]
		if str(acknowledge_record.payload.receipt_id) != str(prototype_state.voucher.receipt_id) or str(acknowledge_record.result.receipt_id) != str(prototype_state.voucher.receipt_id):
			return "Grant acknowledgement result must match the immutable receipt."
	var latest_apply := {}
	for record_value in requests.values():
		var record: Dictionary = record_value
		if str(record.action) == "apply_loadout":
			if record.payload != record.result.saved_loadout or _validate_static_loadout(record.payload) != "":
				return "Loadout Apply payload and result must be the same valid loadout."
			if latest_apply.is_empty() or int(record.result.revision) > int(latest_apply.result.revision):
				latest_apply = record
	if not latest_apply.is_empty() and latest_apply.result.saved_loadout != prototype_state.saved_loadout:
		return "Latest Loadout Apply result must match the current saved loadout."
	match voucher_state:
		"available":
			if actions.size() != 1:
				return "Available voucher request history is invalid."
		"printing":
			if actions.size() != 2 or begin_index != 1:
				return "Printing voucher request history is invalid."
		"settled":
			if complete_index < 0 or acknowledge_index >= 0:
				return "Settled voucher request history is invalid."
		"acknowledged":
			if complete_index < 0 or acknowledge_index < 0:
				return "Acknowledged voucher request history is invalid."
	return ""


static func _namespace_print_count(prototype_state: Dictionary, member_id: String) -> int:
	var count := 0
	for record_value in prototype_state.prints.values():
		var record: Dictionary = record_value
		if str(record.blueprint_id) == member_id:
			count += 1
	return count


static func _recommended_team(starter_id: String) -> Array:
	if starter_id.is_empty():
		return []
	return [starter_id] + GUARANTEES[starter_id].duplicate()


static func _validate_top_schema(profile: Dictionary) -> String:
	if not profile.has("schema_version"):
		return ""
	if not _is_safe_integer(profile.schema_version) or int(profile.schema_version) <= 0 or int(profile.schema_version) > MAX_V3_SCHEMA:
		return "Top-level schema_version is unsupported."
	return ""


static func _fingerprint(value: Dictionary) -> Dictionary:
	var normalized := _normalize_relevant_json(value)
	if not bool(normalized.get("ok", false)):
		return normalized
	return {"ok": true, "fingerprint": JSON.stringify(normalized.value).sha256_text()}


static func canonical_json(value: Variant) -> Dictionary:
	var normalized := _normalize_relevant_json(value)
	if not bool(normalized.get("ok", false)):
		return normalized
	return {"ok": true, "value": normalized.value, "json": JSON.stringify(normalized.value)}


static func validate_action_payload(action: String, payload: Variant) -> String:
	if action not in ACTIONS or not payload is Dictionary:
		return "Collection action payload is invalid."
	var expected := []
	match action:
		"choose_starter":
			expected = ["starter_id"]
		"begin_starter_print":
			expected = []
		"complete_starter_print":
			expected = ["print_id"]
		"acknowledge_grant":
			expected = ["receipt_id"]
		"apply_loadout":
			expected = ["team", "priority", "kit"]
	if not _has_exact_keys(payload, expected):
		return "Collection action payload shape is invalid."
	if action == "choose_starter" and not payload.starter_id is String:
		return "Starter ID is invalid."
	if action == "complete_starter_print" and (not payload.print_id is String or payload.print_id.is_empty()):
		return "Print ID is invalid."
	if action == "acknowledge_grant" and (not payload.receipt_id is String or payload.receipt_id.is_empty()):
		return "Receipt ID is invalid."
	return ""


static func _normalize_relevant_json(value: Variant) -> Dictionary:
	if value == null or value is bool or value is String:
		return {"ok": true, "value": value}
	if _is_safe_integer(value):
		return {"ok": true, "value": int(value)}
	if value is Array:
		var array := []
		for item in value:
			var result := _normalize_relevant_json(item)
			if not bool(result.get("ok", false)):
				return result
			array.append(result.value)
		return {"ok": true, "value": array}
	if value is Dictionary:
		var keys := []
		for key in value.keys():
			if not key is String:
				return _failure("Relevant Dictionary key is invalid.")
			keys.append(key)
		keys.sort()
		var output := {}
		for key in keys:
			var result := _normalize_relevant_json(value[key])
			if not bool(result.get("ok", false)):
				return result
			output[key] = result.value
		return {"ok": true, "value": output}
	return _failure("Relevant value is not JSON-compatible.")


static func _is_safe_integer(value: Variant) -> bool:
	if value is bool:
		return false
	if value is int:
		return value >= -MAX_SAFE_INTEGER and value <= MAX_SAFE_INTEGER
	if value is float:
		return is_finite(value) and floor(value) == value and value >= -MAX_SAFE_INTEGER and value <= MAX_SAFE_INTEGER
	return false


static func _valid_hash(value: Variant) -> bool:
	if not value is String or value.length() != 64:
		return false
	for index in value.length():
		var character: String = value.substr(index, 1)
		if not (character >= "0" and character <= "9") and not (character >= "a" and character <= "f"):
			return false
	return true


static func _is_stable_id(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length() > 96:
		return false
	for index in value.length():
		var character: String = value.substr(index, 1)
		if not (character.to_lower() >= "a" and character.to_lower() <= "z") and not (character >= "0" and character <= "9") and character not in ["_", "-"]:
			return false
	return true


static func _is_derived_id(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length() > 128:
		return false
	for index in value.length():
		var character: String = value.substr(index, 1)
		if not (character.to_lower() >= "a" and character.to_lower() <= "z") and not (character >= "0" and character <= "9") and character not in ["_", "-"]:
			return false
	return true


static func _has_exact_keys(value: Dictionary, expected: Array) -> bool:
	if value.size() != expected.size():
		return false
	for key in value.keys():
		if key not in expected:
			return false
	return true


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "error": message}
