extends Node

const TITLE_SCENE := preload("res://UI/TitleScreen.tscn")

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
	var title = TITLE_SCENE.instantiate()
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
	if not bool(GameState.progress.get("starter_chosen", false)):
		_show_starter_choice()

func _show_battle() -> void:
	var battle := preload("res://Battle/BattleScreen.gd").new()
	battle.exit_to_hub.connect(_show_hub)
	_set_screen(battle)

func _show_shop() -> void:
	var shop := preload("res://Hub/ShopScreen.gd").new()
	shop.back.connect(_show_hub)
	_set_screen(shop)

func _show_team() -> void:
	var team := preload("res://Hub/TeamScreen.gd").new()
	team.back.connect(_show_hub)
	_set_screen(team)

func _show_starter_choice() -> void:
	var starter := preload("res://Hub/StarterChoiceScreen.gd").new()
	starter.back.connect(_show_hub)
	starter.starter_chosen.connect(_on_starter_chosen)
	_set_screen(starter)

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
	_show_shop()

func _on_open_team() -> void:
	_show_team()

func _on_starter_chosen(unit_id: String) -> void:
	GameState.progress["starter_chosen"] = true
	if GameState.active_team.is_empty():
		# Starter rule: grant physical unit to battle, but do NOT grant blueprint.
		GameState.active_team.append(unit_id)
	if GameState.active_slot >= 1:
		SaveSystem.write_slot(GameState.active_slot, GameState.to_save())
	_show_hub()
