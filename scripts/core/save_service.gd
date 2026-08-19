extends Node
## Versioned local profile plus append-only idempotent synchronization journal.
const PROFILE_PATH := "user://printforge_profile.json"
const PROFILE_TEMP_PATH := "user://printforge_profile.tmp.json"
const PROFILE_BACKUP_PATH := "user://printforge_profile.backup.json"
const PROFILE_BACKUP_TEMP_PATH := "user://printforge_profile.backup.tmp.json"
const JOURNAL_PATH := "user://printforge_offline_journal.jsonl"
var session_events: Array = []
var recovery_status := "primary"
var profile_path := PROFILE_PATH
var profile_temp_path := PROFILE_TEMP_PATH
var profile_backup_path := PROFILE_BACKUP_PATH
var profile_backup_temp_path := PROFILE_BACKUP_TEMP_PATH
var journal_path := JOURNAL_PATH

func configure_unified_playtest_paths() -> void:
	# This branch never opens a production profile, including on desktop where a
	# package identity is not available to distinguish user:// folders.
	profile_path = "user://printforge_unified_playtest_profile.json"
	profile_temp_path = "user://printforge_unified_playtest_profile.tmp.json"
	profile_backup_path = "user://printforge_unified_playtest_profile.backup.json"
	profile_backup_temp_path = "user://printforge_unified_playtest_profile.backup.tmp.json"
	journal_path = "user://printforge_unified_playtest_journal.jsonl"
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
	recovery_status = "new_profile"; return {}

func commit_snapshot(profile: Dictionary) -> void:
	var file := FileAccess.open(profile_temp_path, FileAccess.WRITE)
	if file == null:
		push_warning("Profile storage is unavailable; running without local persistence.")
		return
	file.store_string(JSON.stringify(profile))
	file.flush(); file.close()
	if _read_profile(profile_temp_path).is_empty():
		push_warning("Profile temp snapshot failed validation; previous snapshot remains intact.")
		return
	var directory := DirAccess.open(profile_path.get_base_dir())
	if directory == null: return
	if FileAccess.file_exists(profile_path):
		if directory.copy(profile_path, profile_backup_temp_path) != OK or _read_profile(profile_backup_temp_path).is_empty():
			push_warning("Profile backup could not be validated; primary snapshot remains intact.")
			return
		if FileAccess.file_exists(profile_backup_path): directory.remove(profile_backup_path)
		if directory.rename(profile_backup_temp_path, profile_backup_path) != OK:
			push_warning("Profile backup could not be promoted; primary snapshot remains intact.")
			return
		if directory.remove(profile_path) != OK:
			push_warning("Primary snapshot could not be replaced; backup is preserved.")
			return
	if directory.rename(profile_temp_path, profile_path) != OK:
		# Keep the temp and backup intact rather than overwriting the last valid snapshot.
		push_warning("Profile snapshot was not promoted; the previous backup is preserved.")
	else: recovery_status = "primary"

func append_event(kind: String, payload: Dictionary, revision: int) -> void:
	var operation_id := "%s-%s-%s" % [revision, kind, Time.get_ticks_msec()]
	var row := {"operation_id":operation_id,"kind":kind,"payload":payload,"revision":revision,"timestamp":Time.get_unix_time_from_system(),"schema_version":Catalog.SCHEMA_VERSION}
	# READ_WRITE will not create a first journal on Godot desktop builds; WRITE_READ does.
	var mode := FileAccess.READ_WRITE if FileAccess.file_exists(journal_path) else FileAccess.WRITE_READ
	var file := FileAccess.open(journal_path, mode)
	if file == null:
		session_events.append(row)
		push_warning("Offline journal storage is unavailable; event was not persisted.")
		return
	file.seek_end()
	file.store_line(JSON.stringify(row))

func commit_mutation(profile: Dictionary, kind: String, payload: Dictionary, revision: int) -> void:
	# One public mutation path keeps journal and snapshot ordering together.
	append_event(kind, payload, revision)
	commit_snapshot(profile)

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
