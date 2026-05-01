extends Node

var _current: Node = null

func _ready() -> void:
	_ensure_folders_exist()
	UnitDatabase.load_units("res://Data/units.json")
	_show_title()

func _ensure_folders_exist() -> void:
	for p in [
		"user://Saves",
	]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(p))

func _set_screen(screen: Node) -> void:
	if _current != null:
		_current.queue_free()
	_current = screen
	add_child(_current)

func _show_title() -> void:
	var title := preload("res://UI/Title/TitleScreen.gd").new()
	title.start_new_game.connect(_on_start_new_game)
	title.continue_game.connect(_on_continue_game)
	title.delete_slot.connect(_on_delete_slot)
	_set_screen(title)

func _show_hub() -> void:
	var hub := preload("res://Hub/HubScreen.gd").new()
	hub.open_battle.connect(_on_open_battle)
	hub.open_shop.connect(_on_open_shop)
	hub.open_team.connect(_on_open_team)
	hub.back_to_title.connect(_show_title)
	_set_screen(hub)

func _show_battle() -> void:
	var battle := preload("res://Battle/BattleScreen.gd").new()
	battle.exit_to_hub.connect(_show_hub)
	_set_screen(battle)

func _on_start_new_game(slot: int) -> void:
	SaveSystem.create_new_slot(slot)
	GameState.active_slot = slot
	GameState.load_from_save(SaveSystem.load_slot(slot))
	_show_hub()

func _on_continue_game(slot: int) -> void:
	GameState.active_slot = slot
	GameState.load_from_save(SaveSystem.load_slot(slot))
	_show_hub()

func _on_delete_slot(slot: int) -> void:
	SaveSystem.delete_slot(slot)
	_show_title()

func _on_open_battle() -> void:
	_show_battle()

func _on_open_shop() -> void:
	EventBus.request_toast.emit("Shop (MVP) not wired yet.")

func _on_open_team() -> void:
	EventBus.request_toast.emit("Team Manager (MVP) not wired yet.")

