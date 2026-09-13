class_name TeamPrototypeStore
extends RefCounted

## Explicit-path prototype persistence. This is deliberately separate from the v3
## SaveService journal and never derives a player path on its own.

const CollectionProjection := preload("res://scripts/team_collection/team_collection_projection.gd")
const Ledger := preload("res://scripts/team_runtime/team_match_ledger.gd")
const MatchSession := preload("res://scripts/team_runtime/team_match_session.gd")

const KINDS := ["profile", "ledger", "cursor"]

var _paths := {}
var _values := {"profile": {}, "ledger": null, "cursor": null}
var _exists := {"profile": false, "ledger": false, "cursor": false}
var _generations := {"profile": {}, "ledger": {}, "cursor": {}}
var _recovery := ""
var _fault: Callable = Callable()


static func open(profile_path: Variant, compatibility: Variant, fault: Callable = Callable()) -> Dictionary:
	if not MatchSession._compatibility_is_ready(compatibility):
		return _failure("Profile compatibility is not ready.")
	var paths_result := _derive_paths(profile_path)
	if not bool(paths_result.get("ok", false)):
		return paths_result
	var store: Variant = load("res://scripts/team_runtime/team_prototype_store.gd").new()
	store._paths = paths_result.paths
	store._fault = fault
	var loaded: Dictionary = store._load_all()
	if not bool(loaded.get("ok", false)):
		return loaded
	return {
		"ok": true,
		"store": store,
		"profile": store.profile_value(),
		"ledger_exists": store.ledger_exists(),
		"ledger": store.ledger_value(),
		"cursor": store.cursor_value(),
		"recovery": store.recovery_state(),
		"clean_install": store.is_clean_install(),
		"paths": store.paths(),
	}


func paths() -> Dictionary:
	return _paths.duplicate(true)


func recovery_state() -> String:
	return _recovery


func is_recovery() -> bool:
	return not _recovery.is_empty()


func is_clean_install() -> bool:
	return not is_recovery() and not bool(_exists.profile) and not bool(_exists.ledger) and not bool(_exists.cursor)


func profile_value() -> Dictionary:
	return _values.profile.duplicate(true)


func ledger_exists() -> bool:
	return bool(_exists.ledger)


func ledger_value() -> Variant:
	return _values.ledger.duplicate(true) if _values.ledger is Dictionary else _values.ledger


func cursor_value() -> Variant:
	return _values.cursor.duplicate(true) if _values.cursor is Dictionary else _values.cursor


func generations_match(kinds: Array) -> bool:
	if is_recovery():
		return false
	for kind_value in kinds:
		var kind := str(kind_value)
		if kind not in KINDS or not _generation_matches(kind):
			return false
	return true


func commit_profile(candidate: Variant) -> bool:
	return _commit("profile", candidate, Callable(self, "_validate_profile"))


func commit_ledger(candidate: Variant, required_generations: Array = []) -> bool:
	return _commit("ledger", candidate, Callable(self, "_validate_ledger"), required_generations)


func commit_cursor(candidate: Variant, required_generations: Array = []) -> bool:
	return _commit("cursor", candidate, Callable(self, "_validate_cursor"), required_generations)


func _load_all() -> Dictionary:
	var profile := _read_entry("profile", Callable(self, "_validate_profile"))
	var ledger := _read_entry("ledger", Callable(self, "_validate_ledger"))
	var cursor := _read_entry("cursor", Callable(self, "_validate_cursor"))
	for result in [profile, ledger, cursor]:
		if str(result.status) == "corrupt" or str(result.status) == "null" or str(result.status) == "future":
			_recovery = "%s_%s" % [str(result.kind), str(result.status)]
			return _publish_loaded(profile, ledger, cursor)
	var any_temporary := false
	var any_backup := false
	for kind in KINDS:
		any_temporary = any_temporary or FileAccess.file_exists(str(_paths[kind].tmp))
		any_backup = any_backup or FileAccess.file_exists(str(_paths[kind].backup))
		if FileAccess.file_exists(str(_paths[kind].tmp)):
			_recovery = "%s_temporary_evidence" % kind
			return _publish_loaded(profile, ledger, cursor)
		if FileAccess.file_exists(str(_paths[kind].backup_stage)) or FileAccess.file_exists(str(_paths[kind].restore)):
			_recovery = "%s_staging_evidence" % kind
			return _publish_loaded(profile, ledger, cursor)
		var result: Dictionary = {"profile": profile, "ledger": ledger, "cursor": cursor}[kind]
		if kind != "profile" and not bool(result.exists) and (FileAccess.file_exists(str(_paths[kind].tmp)) or FileAccess.file_exists(str(_paths[kind].backup))):
			_recovery = "%s_sidecar_evidence" % kind
			return _publish_loaded(profile, ledger, cursor)
	var profile_backup := _read_path(str(_paths.profile.backup), Callable(self, "_validate_profile"))
	if str(profile.status) != "valid" and str(profile_backup.status) == "valid":
		_recovery = "profile_backup_read_only"
		return _publish_loaded(profile, ledger, cursor)
	if bool(cursor.exists) and not bool(ledger.exists):
		_recovery = "cursor_orphan"
		return _publish_loaded(profile, ledger, cursor)
	if not bool(profile.exists) and (bool(ledger.exists) or bool(cursor.exists) or any_temporary or any_backup):
		_recovery = "orphaned_prototype_evidence"
		return _publish_loaded(profile, ledger, cursor)
	if not bool(profile.exists) and not any_temporary and not any_backup and not bool(ledger.exists) and not bool(cursor.exists):
		return _publish_loaded(profile, ledger, cursor)
	return _publish_loaded(profile, ledger, cursor)


func _publish_loaded(profile: Dictionary, ledger: Dictionary, cursor: Dictionary) -> Dictionary:
	if str(profile.status) == "valid":
		_values.profile = profile.value.duplicate(true)
		_exists.profile = true
		_generations.profile = profile.generation.duplicate(true)
	else:
		_values.profile = {}
		_exists.profile = false
		_generations.profile = profile.generation.duplicate(true)
	if str(ledger.status) == "valid":
		_values.ledger = ledger.value.duplicate(true)
		_exists.ledger = true
		_generations.ledger = ledger.generation.duplicate(true)
	else:
		_values.ledger = null
		_exists.ledger = false
		_generations.ledger = ledger.generation.duplicate(true)
	if str(cursor.status) == "valid":
		_values.cursor = cursor.value.duplicate(true)
		_exists.cursor = true
		_generations.cursor = cursor.generation.duplicate(true)
	else:
		_values.cursor = null
		_exists.cursor = false
		_generations.cursor = cursor.generation.duplicate(true)
	return {"ok": true}


func _commit(kind: String, candidate: Variant, validator: Callable, required_generations: Array = []) -> bool:
	var read_set := [kind]
	for dependency in required_generations:
		if dependency not in read_set:
			read_set.append(dependency)
	if is_recovery() or kind not in KINDS or not validator.is_valid() or not generations_match(read_set):
		return false
	if not _validator_accepts(validator, candidate):
		return false
	var canonical := _canonical_json(candidate)
	if not bool(canonical.get("ok", false)):
		return false
	var text := str(canonical.text)
	var path_set: Dictionary = _paths[kind]
	if FileAccess.file_exists(str(path_set.tmp)) and not _preserve_stale_temp(kind):
		return false
	if not _allow("temp_open", kind) or not _write_text(str(path_set.tmp), text):
		return false
	if not _allow("temp_write", kind):
		return false
	var temporary := _read_path(str(path_set.tmp), validator)
	if not _allow("temp_validate", kind) or str(temporary.status) != "valid" or str(temporary.canonical) != text:
		return false
	var previous_text := ""
	var had_primary := bool(_exists[kind])
	if had_primary:
		var prior := _read_path(str(path_set.primary), validator)
		if str(prior.status) != "valid":
			_recovery = "%s_primary_changed" % kind
			return false
		previous_text = str(prior.raw)
		if not _replace_backup(kind, previous_text, validator):
			return false
	if not _allow("primary_promotion", kind):
		return false
	if not generations_match(read_set):
		return false
	if had_primary and DirAccess.remove_absolute(str(path_set.primary)) != OK:
		return false
	if DirAccess.rename_absolute(str(path_set.tmp), str(path_set.primary)) != OK:
		if had_primary and not _restore_previous(kind, previous_text, validator):
			_recovery = "%s_rollback_failed" % kind
		return false
	var promoted := _read_path(str(path_set.primary), validator)
	if not _allow("post_read", kind) or str(promoted.status) != "valid" or str(promoted.canonical) != text:
		if not had_primary:
			if DirAccess.rename_absolute(str(path_set.primary), str(path_set.tmp)) != OK:
				_recovery = "%s_promotion_uncertain" % kind
			else:
				_recovery = "%s_temporary_evidence" % kind
		elif not _restore_previous(kind, previous_text, validator):
			_recovery = "%s_rollback_failed" % kind
		return false
	_values[kind] = promoted.value.duplicate(true)
	_exists[kind] = true
	_generations[kind] = promoted.generation.duplicate(true)
	return true


func _replace_backup(kind: String, previous_text: String, validator: Callable) -> bool:
	if not _allow("backup", kind):
		return false
	var path_set: Dictionary = _paths[kind]
	var staging := str(path_set.backup_stage)
	if FileAccess.file_exists(staging) and not _preserve_stale_path(staging, "backup-stage"):
		return false
	if not _write_text(staging, previous_text):
		return false
	var staged := _read_path(staging, validator)
	if str(staged.status) != "valid" or str(staged.raw) != previous_text:
		return false
	if FileAccess.file_exists(str(path_set.backup)) and DirAccess.remove_absolute(str(path_set.backup)) != OK:
		return false
	if DirAccess.rename_absolute(staging, str(path_set.backup)) != OK:
		return false
	var backup := _read_path(str(path_set.backup), validator)
	return str(backup.status) == "valid" and str(backup.raw) == previous_text


func _preserve_stale_temp(kind: String) -> bool:
	return _preserve_stale_path(str(_paths[kind].tmp), "temporary")


func _preserve_stale_path(path: String, label: String) -> bool:
	var generation := _generation_for_path(path)
	if not bool(generation.exists):
		return true
	var prefix := "%s.%s.failed-%s" % [path, label, str(generation.sha256).substr(0, 12)]
	for index in range(0, 1024):
		var evidence := "%s-%d" % [prefix, index]
		if not FileAccess.file_exists(evidence):
			return DirAccess.rename_absolute(path, evidence) == OK
	return false


func _restore_previous(kind: String, previous_text: String, validator: Callable) -> bool:
	if not _allow("rollback", kind):
		return false
	var path_set: Dictionary = _paths[kind]
	var staging := str(path_set.restore)
	if FileAccess.file_exists(staging) or not _write_text(staging, previous_text):
		return false
	var staged := _read_path(staging, validator)
	if str(staged.status) != "valid" or str(staged.raw) != previous_text:
		return false
	if FileAccess.file_exists(str(path_set.primary)) and DirAccess.remove_absolute(str(path_set.primary)) != OK:
		return false
	if DirAccess.rename_absolute(staging, str(path_set.primary)) != OK:
		return false
	var restored := _read_path(str(path_set.primary), validator)
	if str(restored.status) != "valid" or str(restored.raw) != previous_text:
		return false
	_values[kind] = restored.value.duplicate(true)
	_exists[kind] = true
	_generations[kind] = restored.generation.duplicate(true)
	return true


func _generation_matches(kind: String) -> bool:
	var current := _generation_for_path(str(_paths[kind].primary))
	return JSON.stringify(current) == JSON.stringify(_generations[kind])


func _read_entry(kind: String, validator: Callable) -> Dictionary:
	var result := _read_path(str(_paths[kind].primary), validator)
	result["kind"] = kind
	return result


func _read_path(path: String, validator: Callable) -> Dictionary:
	var generation := _generation_for_path(path)
	if not bool(generation.exists):
		return {"exists": false, "status": "missing", "value": null, "raw": "", "canonical": "", "generation": generation}
	var text := FileAccess.get_file_as_string(path)
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return {"exists": true, "status": "corrupt", "value": null, "raw": text, "canonical": "", "generation": generation}
	var value: Variant = parser.data
	if value == null:
		return {"exists": true, "status": "null", "value": null, "raw": text, "canonical": "null", "generation": generation}
	if not _validator_accepts(validator, value):
		return {"exists": true, "status": "future" if _is_future_like(value) else "corrupt", "value": null, "raw": text, "canonical": "", "generation": generation}
	var canonical := _canonical_json(value)
	if not bool(canonical.get("ok", false)):
		return {"exists": true, "status": "corrupt", "value": null, "raw": text, "canonical": "", "generation": generation}
	return {"exists": true, "status": "valid", "value": canonical.value, "raw": text, "canonical": canonical.text, "generation": generation}


func _validate_profile(value: Variant) -> bool:
	return bool(CollectionProjection.project(value).get("ok", false))


func _validate_ledger(value: Variant) -> bool:
	return bool(Ledger.normalize(value, true).get("ok", false))


func _validate_cursor(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var expected := ["match_id", "authority_revision", "request_id", "receipt_hash", "next_cursor"]
	if value.size() != expected.size():
		return false
	for key in expected:
		if not value.has(key):
			return false
	return value.match_id is String and Ledger._valid_id(str(value.match_id)) and value.request_id is String and Ledger._valid_id(str(value.request_id)) and value.receipt_hash is String and value.receipt_hash.length() == 64 and value.receipt_hash.is_valid_hex_number() and _safe_nonnegative(value.authority_revision) and _safe_nonnegative(value.next_cursor)


func _validator_accepts(validator: Callable, value: Variant) -> bool:
	var accepted: Variant = validator.call(value)
	return accepted is bool and bool(accepted)


func _allow(stage: String, kind: String) -> bool:
	if not _fault.is_valid():
		return true
	var accepted: Variant = _fault.call(stage, kind)
	return accepted is bool and bool(accepted)


func _write_text(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.flush()
	var error := file.get_error()
	file.close()
	return error == OK


func _generation_for_path(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"exists": false, "bytes": 0, "sha256": ""}
	var bytes := FileAccess.get_file_as_bytes(path)
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(bytes)
	return {"exists": true, "bytes": bytes.size(), "sha256": hash.finish().hex_encode()}


func _is_future_like(value: Variant) -> bool:
	if value is Dictionary and _whole_number(value.get("version", null)) and int(value.version) > Ledger.VERSION:
		return true
	return value is Dictionary and _whole_number(value.get("schema_version", null)) and int(value.schema_version) > CollectionProjection.MAX_V3_SCHEMA


static func _derive_paths(profile_path: Variant) -> Dictionary:
	if not profile_path is String or str(profile_path).is_empty():
		return _failure("Prototype profile path is invalid.")
	var primary := ProjectSettings.globalize_path(str(profile_path))
	if not primary.is_absolute_path() or primary.get_extension().to_lower() != "json" or primary.get_file() == ".json":
		return _failure("Prototype profile path must be an absolute JSON file.")
	var parent := primary.get_base_dir()
	if parent.is_empty() or not DirAccess.dir_exists_absolute(parent):
		return _failure("Prototype profile directory is unavailable.")
	var stem := primary.get_basename()
	return {"ok": true, "paths": {
		"profile": _path_set(primary),
		"ledger": _path_set("%s.team-match.json" % stem),
		"cursor": _path_set("%s.team-cursor.json" % stem),
	}}


static func _path_set(primary: String) -> Dictionary:
	var stem := primary.get_basename()
	var backup := "%s.backup.json" % stem
	return {
		"primary": primary,
		"tmp": "%s.tmp.json" % stem,
		"backup": backup,
		"backup_stage": "%s.stage" % backup,
		"restore": "%s.restore" % primary,
	}


static func _canonical_json(value: Variant) -> Dictionary:
	var text := JSON.stringify(value)
	var parser := JSON.new()
	if parser.parse(text) != OK or parser.data == null:
		return _failure("Prototype value is not JSON-compatible.")
	return {"ok": true, "value": parser.data, "text": JSON.stringify(parser.data)}


static func _safe_nonnegative(value: Variant) -> bool:
	return _whole_number(value) and int(value) >= 0 and int(value) <= 9007199254740991


static func _whole_number(value: Variant) -> bool:
	return (value is int and not value is bool) or (value is float and is_finite(value) and floor(value) == value)


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "error": message}
