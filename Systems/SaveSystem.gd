extends Node

## Single local profile (industry-standard: one adventure per device for MVP).
## Legacy `slot_*.json` files are migrated once from slot 1 if present.

const SAVE_DIR := "user://Saves"
const PROFILE_PATH := SAVE_DIR + "/profile.json"
const LOCAL_SETTINGS_PATH := SAVE_DIR + "/local_settings.json"

const LEGACY_SLOT_1 := SAVE_DIR + "/slot_1.json"


func _local_settings_default() -> Dictionary:
	return {"music": true, "sfx": true}


func migrate_legacy_if_needed() -> void:
	if has_save():
		return
	if not FileAccess.file_exists(LEGACY_SLOT_1):
		return
	var legacy: Dictionary = _read_json_file(LEGACY_SLOT_1)
	if legacy.is_empty():
		return
	write_save(legacy)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(LEGACY_SLOT_1))


func has_save() -> bool:
	return FileAccess.file_exists(PROFILE_PATH)


func create_new_save() -> void:
	var ls: Dictionary = load_local_settings()
	var save: Dictionary = {
		"coins": GameRules.NEW_SAVE_STARTING_COINS,
		"owned_blueprints": [],
		"active_team": [],
		"printer_upgrades": {"filament_cap": GameRules.DEFAULT_FILAMENT_CAP},
		"progress": {
			"starter_chosen": false,
			"battles_won": 0,
			"quest_math_bonus_claimed": false,
			"quests_claimed": {"add": false, "sub": false, "geo": false}
		},
		"settings": {
			"music": bool(ls.get("music", true)),
			"sfx": bool(ls.get("sfx", true))
		},
		"shop_last_refresh_unix": 0,
		"shop_offer_ids": []
	}
	write_save(save)


func load_save() -> Dictionary:
	return _read_json_file(PROFILE_PATH)


func write_save(data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	var f: FileAccess = FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data, "\t"))


func delete_save() -> void:
	if FileAccess.file_exists(PROFILE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE_PATH))


func load_local_settings() -> Dictionary:
	var d: Dictionary = _read_json_file(LOCAL_SETTINGS_PATH)
	if d.is_empty():
		return _local_settings_default()
	var out: Dictionary = _local_settings_default()
	for k in out.keys():
		if d.has(k):
			out[k] = bool(d[k])
	return out


func write_local_settings(settings: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	var f: FileAccess = FileAccess.open(LOCAL_SETTINGS_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(settings, "\t"))


func _read_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var json: JSON = JSON.new()
	var err: Error = json.parse(f.get_as_text())
	if err != OK:
		return {}
	var raw: Variant = json.data
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	return raw as Dictionary
