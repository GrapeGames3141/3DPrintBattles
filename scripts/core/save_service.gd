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

func configure_unified_playtest_paths() -> void:
	# v3 is a clean namespace: it never opens or migrates the 0.7 playtest save.
	profile_path = "user://printforge_v3_profile.json"
	profile_temp_path = "user://printforge_v3_profile.tmp.json"
	profile_backup_path = "user://printforge_v3_profile.backup.json"
	profile_backup_temp_path = "user://printforge_v3_profile.backup.tmp.json"
	journal_path = "user://printforge_v3_journal.jsonl"
	recovery_status = "primary"

func configure_test_paths(root: String) -> void:
	profile_path = root.path_join("profile.json")
	profile_temp_path = root.path_join("profile.tmp.json")
	profile_backup_path = root.path_join("profile.backup.json")
	profile_backup_temp_path = root.path_join("profile.backup.tmp.json")
	journal_path = root.path_join("journal.jsonl")
	recovery_status = "primary"; session_events.clear()

func reset_paths() -> void:
	profile_path = PROFILE_PATH; profile_temp_path = PROFILE_TEMP_PATH; profile_backup_path = PROFILE_BACKUP_PATH; profile_backup_temp_path = PROFILE_BACKUP_TEMP_PATH; journal_path = JOURNAL_PATH
	recovery_status = "primary"; session_events.clear()

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
