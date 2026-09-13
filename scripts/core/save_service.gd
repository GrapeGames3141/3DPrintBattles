extends Node
## Versioned local profile plus append-only idempotent synchronization journal.
const PROFILE_PATH := "user://printforge_profile.json"
const PROFILE_TEMP_PATH := "user://printforge_profile.tmp.json"
const PROFILE_BACKUP_PATH := "user://printforge_profile.backup.json"
const PROFILE_BACKUP_TEMP_PATH := "user://printforge_profile.backup.tmp.json"
const JOURNAL_PATH := "user://printforge_offline_journal.jsonl"
var session_events: Array = []
var recovery_status := "primary"
var last_commit_error := ""
var profile_path := PROFILE_PATH
var profile_temp_path := PROFILE_TEMP_PATH
var profile_backup_path := PROFILE_BACKUP_PATH
var profile_backup_temp_path := PROFILE_BACKUP_TEMP_PATH
var journal_path := JOURNAL_PATH
var pack_ui_session_path := "user://printforge_pack_ui_session.json"
var pack_ui_session_temp_path := "user://printforge_pack_ui_session.tmp.json"
var pack_ui_session_backup_path := "user://printforge_pack_ui_session.backup.json"

func configure_debug_qa_storage_from_command_line() -> Dictionary:
	# Autoloads start before a test scene can call `configure_test_paths`.  Keep
	# that debug-only bootstrap alongside the path authority so no runtime screen
	# reimplements validation or accidentally opens the maker's `user://` save.
	const PREFIX := "--qa-save-root="
	var requested: Array[String] = []
	for argument in OS.get_cmdline_user_args():
		var value := str(argument)
		if value.begins_with(PREFIX): requested.append(value.trim_prefix(PREFIX))
	if requested.is_empty(): return {"handled":false, "ok":true}
	if requested.size() != 1:
		return {"handled":true, "ok":false, "error":"QA storage accepts exactly one root."}
	if not OS.is_debug_build():
		return {"handled":true, "ok":false, "error":"QA storage is unavailable outside a debug build."}
	var root := requested[0].strip_edges().trim_prefix("\"").trim_suffix("\"").replace("\\", "/")
	var allowed_root := ProjectSettings.globalize_path("res://build/evidence/").replace("\\", "/").trim_suffix("/")
	if root.is_empty() or root.contains("..") or not root.is_absolute_path() or not root.begins_with(allowed_root + "/"):
		return {"handled":true, "ok":false, "error":"Rejected invalid QA storage root."}
	if DirAccess.make_dir_recursive_absolute(root) != OK:
		return {"handled":true, "ok":false, "error":"Could not prepare QA storage root."}
	configure_test_paths(root)
	return {"handled":true, "ok":true, "root":root}

func configure_unified_playtest_paths() -> void:
	# v3 is a clean namespace: it never opens or migrates the 0.7 playtest save.
	profile_path = "user://printforge_v3_profile.json"
	profile_temp_path = "user://printforge_v3_profile.tmp.json"
	profile_backup_path = "user://printforge_v3_profile.backup.json"
	profile_backup_temp_path = "user://printforge_v3_profile.backup.tmp.json"
	journal_path = "user://printforge_v3_journal.jsonl"
	_configure_pack_ui_session_paths()
	recovery_status = "primary"

func configure_test_paths(root: String) -> void:
	profile_path = root.path_join("profile.json")
	profile_temp_path = root.path_join("profile.tmp.json")
	profile_backup_path = root.path_join("profile.backup.json")
	profile_backup_temp_path = root.path_join("profile.backup.tmp.json")
	journal_path = root.path_join("journal.jsonl")
	_configure_pack_ui_session_paths()
	recovery_status = "primary"; session_events.clear()

func reset_paths() -> void:
	profile_path = PROFILE_PATH; profile_temp_path = PROFILE_TEMP_PATH; profile_backup_path = PROFILE_BACKUP_PATH; profile_backup_temp_path = PROFILE_BACKUP_TEMP_PATH; journal_path = JOURNAL_PATH
	_configure_pack_ui_session_paths()
	recovery_status = "primary"; session_events.clear()

func _configure_pack_ui_session_paths() -> void:
	# Keep the browsing sidecar adjacent to the configured profile authority. This
	# makes every test namespace isolated and prevents a global receipt cache from
	# crossing profile roots.
	var parent := profile_path.get_base_dir()
	var stem := profile_path.get_file().get_basename()
	pack_ui_session_path = parent.path_join("%s.pack_ui_session.json" % stem)
	pack_ui_session_temp_path = parent.path_join("%s.pack_ui_session.tmp.json" % stem)
	pack_ui_session_backup_path = parent.path_join("%s.pack_ui_session.backup.json" % stem)

func load_profile() -> Dictionary:
	var primary := _read_profile(profile_path)
	if not primary.is_empty(): recovery_status = "primary"; return primary
	var backup := _read_profile(profile_backup_path)
	if not backup.is_empty(): recovery_status = "backup_recovered"; return backup
	# A missing profile is a normal clean-install state.  A present but invalid
	# profile is evidence and must never be silently replaced by a new maker.
	if FileAccess.file_exists(profile_path): recovery_status = "corrupt_primary"
	elif FileAccess.file_exists(profile_backup_path): recovery_status = "corrupt_backup"
	else: recovery_status = "new_profile"
	return {}


func quiet_load_profile() -> Dictionary:
	# Prototype entry is intentionally read-only.  Unlike the legacy loader, it
	# distinguishes an absent profile from a valid literal `{}` and never repairs
	# or normalizes either primary or backup evidence while merely opening the UI.
	var primary := _quiet_profile_entry(profile_path)
	if str(primary.get("status", "")) == "valid":
		recovery_status = "primary"
		return {"status":"primary", "profile":(primary.get("profile", {}) as Dictionary).duplicate(true)}
	var backup := _quiet_profile_entry(profile_backup_path)
	if str(backup.get("status", "")) == "valid":
		recovery_status = "backup_recovered"
		return {"status":"backup_recovered", "profile":(backup.get("profile", {}) as Dictionary).duplicate(true)}
	if str(primary.get("status", "")) == "invalid":
		recovery_status = "corrupt_primary"
		return {"status":"corrupt_primary", "profile":{}}
	if str(backup.get("status", "")) == "invalid":
		recovery_status = "corrupt_backup"
		return {"status":"corrupt_backup", "profile":{}}
	recovery_status = "new_profile"
	return {"status":"missing", "profile":{}}

func commit_snapshot(profile: Dictionary) -> bool:
	last_commit_error = ""
	var file := FileAccess.open(profile_temp_path, FileAccess.WRITE)
	if file == null:
		last_commit_error = "Profile storage is unavailable."
		push_warning("Profile storage is unavailable; running without local persistence.")
		return false
	file.store_string(JSON.stringify(profile))
	file.flush(); file.close()
	if _read_profile(profile_temp_path).is_empty():
		last_commit_error = "Profile temp snapshot failed validation."
		push_warning("Profile temp snapshot failed validation; previous snapshot remains intact.")
		return false
	var directory := DirAccess.open(profile_path.get_base_dir())
	if directory == null:
		last_commit_error = "Profile directory is unavailable."
		return false
	if FileAccess.file_exists(profile_path):
		if directory.copy(profile_path, profile_backup_temp_path) != OK or _read_profile(profile_backup_temp_path).is_empty():
			last_commit_error = "Profile backup could not be validated."
			push_warning("Profile backup could not be validated; primary snapshot remains intact.")
			return false
		if FileAccess.file_exists(profile_backup_path): directory.remove(profile_backup_path)
		if directory.rename(profile_backup_temp_path, profile_backup_path) != OK:
			last_commit_error = "Profile backup could not be promoted."
			push_warning("Profile backup could not be promoted; primary snapshot remains intact.")
			return false
		if directory.remove(profile_path) != OK:
			last_commit_error = "Primary snapshot could not be replaced."
			push_warning("Primary snapshot could not be replaced; backup is preserved.")
			return false
	if directory.rename(profile_temp_path, profile_path) != OK:
		last_commit_error = "Profile snapshot was not promoted."
		# Keep the temp and backup intact rather than overwriting the last valid snapshot.
		push_warning("Profile snapshot was not promoted; the previous backup is preserved.")
		return false
	recovery_status = "primary"
	return true

func append_event(kind: String, payload: Dictionary, revision: int) -> bool:
	var operation_id := "%s-%s-%s" % [revision, kind, Time.get_ticks_msec()]
	var row := {"operation_id":operation_id,"kind":kind,"payload":payload,"revision":revision,"timestamp":Time.get_unix_time_from_system(),"schema_version":Catalog.SCHEMA_VERSION}
	# READ_WRITE will not create a first journal on Godot desktop builds; WRITE_READ does.
	var mode := FileAccess.READ_WRITE if FileAccess.file_exists(journal_path) else FileAccess.WRITE_READ
	var file := FileAccess.open(journal_path, mode)
	if file == null:
		session_events.append(row)
		push_warning("Offline journal storage is unavailable; event was not persisted.")
		# Snapshot persistence is already confirmed by commit_mutation. Retaining a
		# session journal is an intentional offline fallback, not a failed action.
		return true
	file.seek_end()
	file.store_line(JSON.stringify(row))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		# The validated snapshot is already durable. Keep the replay row in memory
		# rather than reporting a false rollback after a journal-only failure.
		session_events.append(row)
		last_commit_error = ""
		push_warning("Offline journal could not be written; this session retained the replay event.")
		return true
	return true

func preserve_corrupt_primary() -> bool:
	return preserve_invalid_save(profile_path)

func preserve_invalid_save(path: String) -> bool:
	if not FileAccess.file_exists(path): return true
	var evidence := "%s.corrupt-%d.json" % [path.get_basename(), Time.get_unix_time_from_system()]
	var directory := DirAccess.open(path.get_base_dir())
	if directory == null or directory.rename(path, evidence) != OK:
		last_commit_error = "The corrupt save could not be preserved."
		return false
	return FileAccess.file_exists(evidence)

func preserve_corrupt_recovery_evidence() -> bool:
	# Only use this after an explicit New Maker confirmation. A valid backup is
	# never moved by this path.
	return preserve_invalid_save(profile_path) and preserve_invalid_save(profile_backup_path)

func commit_mutation(profile: Dictionary, kind: String, payload: Dictionary, revision: int) -> bool:
	# Promote and validate the authority snapshot before writing the optional
	# replay journal. UI callers may only acknowledge a transition after this.
	if not commit_snapshot(profile): return false
	return append_event(kind, payload, revision)

func load_pack_ui_session(receipt: String) -> Dictionary:
	var session := _read_profile(pack_ui_session_path)
	if str(session.get("receipt", "")) != receipt: return {}
	var presentation: Variant = session.get("presentation", {})
	return presentation.duplicate(true) if presentation is Dictionary else {}

func save_pack_ui_session(receipt: String, presentation: Dictionary) -> bool:
	last_commit_error = ""
	var file := FileAccess.open(pack_ui_session_temp_path, FileAccess.WRITE)
	if file == null:
		last_commit_error = "Pack position could not be saved. The committed cards are safe."
		return false
	file.store_string(JSON.stringify({"receipt":receipt,"presentation":presentation.duplicate(true)}))
	file.flush()
	file.close()
	var verified := _read_profile(pack_ui_session_temp_path)
	if str(verified.get("receipt", "")) != receipt:
		last_commit_error = "Pack position could not be verified. The committed cards are safe."
		return false
	var directory := DirAccess.open(pack_ui_session_path.get_base_dir())
	if directory == null:
		last_commit_error = "Pack position storage is unavailable. The committed cards are safe."
		return false
	# Windows cannot rename over an existing file. Move the previous sidecar aside
	# first, restore it if promotion fails, and remove it only after verification.
	var moved_previous := false
	if FileAccess.file_exists(pack_ui_session_path):
		if FileAccess.file_exists(pack_ui_session_backup_path): directory.remove(pack_ui_session_backup_path)
		if directory.rename(pack_ui_session_path, pack_ui_session_backup_path) != OK:
			last_commit_error = "Pack position could not be replaced. The committed cards are safe."
			return false
		moved_previous = true
	if directory.rename(pack_ui_session_temp_path, pack_ui_session_path) != OK:
		if moved_previous: directory.rename(pack_ui_session_backup_path, pack_ui_session_path)
		last_commit_error = "Pack position could not be saved. The committed cards are safe."
		return false
	if moved_previous and FileAccess.file_exists(pack_ui_session_backup_path): directory.remove(pack_ui_session_backup_path)
	return true

func clear_pack_ui_session() -> void:
	if FileAccess.file_exists(pack_ui_session_path):
		var directory := DirAccess.open(pack_ui_session_path.get_base_dir())
		if directory != null: directory.remove(pack_ui_session_path)
	if FileAccess.file_exists(pack_ui_session_backup_path):
		var backup_directory := DirAccess.open(pack_ui_session_backup_path.get_base_dir())
		if backup_directory != null: backup_directory.remove(pack_ui_session_backup_path)

func pending_events() -> Array:
	if not FileAccess.file_exists(journal_path): return session_events.duplicate(true)
	var result: Array = []
	var file := FileAccess.open(journal_path, FileAccess.READ)
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty(): continue
		var row = JSON.parse_string(line)
		if row is Dictionary: result.append(row)
	for row in session_events: result.append(row.duplicate(true))
	return result

func acknowledge_events(up_to_revision: int) -> void:
	var kept: Array = []
	var seen := {}
	for row in pending_events():
		if int(row.get("revision", 0)) > up_to_revision and not seen.has(str(row.get("operation_id", ""))):
			seen[str(row.get("operation_id", ""))] = true; kept.append(row)
	var file := FileAccess.open(journal_path, FileAccess.WRITE)
	if file == null:
		session_events = kept.duplicate(true)
		return
	for row in kept: file.store_line(JSON.stringify(row))
	file.flush(); file.close()
	session_events.clear()

func _read_profile(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _quiet_profile_entry(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"status":"missing", "profile":{}}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"status":"invalid", "profile":{}}
	var text := file.get_as_text()
	file.close()
	var parser := JSON.new()
	if parser.parse(text) != OK or not parser.data is Dictionary:
		return {"status":"invalid", "profile":{}}
	return {"status":"valid", "profile":(parser.data as Dictionary).duplicate(true)}
