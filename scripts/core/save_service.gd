extends Node
## Versioned local profile plus append-only idempotent synchronization journal.
const PROFILE_PATH := "user://printforge_profile.json"
const JOURNAL_PATH := "user://printforge_offline_journal.jsonl"

func load_profile() -> Dictionary:
	if not FileAccess.file_exists(PROFILE_PATH): return {}
	var file := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

func commit_snapshot(profile: Dictionary) -> void:
	var file := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Profile storage is unavailable; running without local persistence.")
		return
	file.store_string(JSON.stringify(profile))

func append_event(kind: String, payload: Dictionary, revision: int) -> void:
	var operation_id := "%s-%s-%s" % [revision, kind, Time.get_ticks_msec()]
	var row := {"operation_id":operation_id,"kind":kind,"payload":payload,"revision":revision,"timestamp":Time.get_unix_time_from_system(),"schema_version":Catalog.SCHEMA_VERSION}
	var file := FileAccess.open(JOURNAL_PATH, FileAccess.READ_WRITE)
	if file == null:
		push_warning("Offline journal storage is unavailable; event was not persisted.")
		return
	file.seek_end()
	file.store_line(JSON.stringify(row))

func commit_mutation(profile: Dictionary, kind: String, payload: Dictionary, revision: int) -> void:
	# One public mutation path keeps journal and snapshot ordering together.
	append_event(kind, payload, revision)
	commit_snapshot(profile)

func pending_events() -> Array:
	if not FileAccess.file_exists(JOURNAL_PATH): return []
	var result: Array = []
	var file := FileAccess.open(JOURNAL_PATH, FileAccess.READ)
	while not file.eof_reached():
		var row = JSON.parse_string(file.get_line())
		if row is Dictionary: result.append(row)
	return result
