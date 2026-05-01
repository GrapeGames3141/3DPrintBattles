extends Node

const SAVE_DIR := "user://Saves"

func slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, slot]

func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))

func create_new_slot(slot: int) -> void:
	var save := {
		"coins": 25,
		"owned_blueprints": [],
		"active_team": [],
		"printer_upgrades": {"filament_cap": 3},
		"progress": {"starter_chosen": false, "battles_won": 0},
		"settings": {"music": true, "sfx": true}
	}
	write_slot(slot, save)

func load_slot(slot: int) -> Dictionary:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text := f.get_as_text()
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		return {}
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data

func write_slot(slot: int, data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	var path := slot_path(slot)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data, "\t"))

func delete_slot(slot: int) -> void:
	var path := slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

