extends Node

const TITLE_SCENE := preload("res://UI/TitleScreen.tscn")

var _current: Node = null
var _workshop_theme: Theme

func _ready() -> void:
	_workshop_theme = UiTheme.build_workshop_theme()
	_ensure_folders_exist()
	SaveSystem.migrate_legacy_if_needed()
	UnitDatabase.load_units("res://Data/units.json")
	_show_intro_video()

func _ensure_folders_exist() -> void:
	for p in [
		"user://Saves",
	]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(p))
	# res://Assets/Prints/<unit_id>/ is documented in Assets/Prints/README.txt — folders created when adding art.

func _set_screen(screen: Node) -> void:
	if _current != null:
		_current.queue_free()
	_current = screen
	if screen is Control:
		(screen as Control).theme = _workshop_theme
	add_child(_current)


func _show_intro_video() -> void:
	var intro: Control = preload("res://UI/IntroVideoScreen.gd").new() as Control
	intro.finished_to_landing.connect(_show_workshop_landing, CONNECT_ONE_SHOT)
	_set_screen(intro)


func _show_workshop_landing() -> void:
	var land: Control = preload("res://UI/WorkshopLandingScreen.gd").new() as Control
	land.go_title.connect(_show_title)
	land.open_team.connect(_on_landing_open_team)
	land.open_shop.connect(_on_landing_open_shop)
	_set_screen(land)


func _on_landing_open_team() -> void:
	if not SaveSystem.has_save():
		EventBus.request_toast.emit("Use the door first — Continue or New Game.")
		return
	_prep_session_from_disk()
	_show_team()


func _on_landing_open_shop() -> void:
	if not SaveSystem.has_save():
		EventBus.request_toast.emit("Use the door first — Continue or New Game.")
		return
	_prep_session_from_disk()
	_show_shop()


func _on_title_open_shop() -> void:
	_on_landing_open_shop()


func _on_title_open_team() -> void:
	_on_landing_open_team()


func _on_title_open_quests() -> void:
	if not SaveSystem.has_save():
		EventBus.request_toast.emit("Continue or New Game first.")
		return
	_prep_session_from_disk()
	_show_quests()


func _prep_session_from_disk() -> void:
	GameState.load_from_save(SaveSystem.load_save())
	_apply_local_settings_to_game_state()
	AudioSettings.apply_from_game_state()
	GameState.session_active = true


func _show_title() -> void:
	GameState.session_active = false
	AudioSettings.apply_from_local_settings()
	var title: Control = TITLE_SCENE.instantiate() as Control
	title.continue_pressed.connect(_on_continue)
	title.new_game_confirmed.connect(_on_new_game)
	title.quit_pressed.connect(_on_quit)
	title.open_shop_pressed.connect(_on_title_open_shop)
	title.open_team_pressed.connect(_on_title_open_team)
	title.open_quests_pressed.connect(_on_title_open_quests)
	_set_screen(title)

func _show_hub() -> void:
	var hub: Control = preload("res://Hub/HubScreen.gd").new() as Control
	hub.open_battle.connect(_on_open_battle)
	hub.open_shop.connect(_on_open_shop)
	hub.open_team.connect(_on_open_team)
	hub.open_terrarium.connect(_show_terrarium)
	hub.open_archive.connect(_show_archive)
	hub.open_quests.connect(_show_quests)
	hub.open_overworld.connect(_show_overworld)
	hub.open_trade.connect(_show_trade)
	hub.back_to_title.connect(_show_title)
	_set_screen(hub)
	if not bool(GameState.progress.get("starter_chosen", false)):
		_show_starter_choice()

func _show_battle() -> void:
	var battle: Control = preload("res://Battle/BattleScreen.gd").new() as Control
	battle.exit_to_hub.connect(_on_exit_battle_to_hub)
	_set_screen(battle)


func _on_exit_battle_to_hub() -> void:
	GameState.battle_mode = GameRules.BATTLE_MODE_STANDARD
	_show_hub()

func _show_shop() -> void:
	var shop: Control = preload("res://Hub/ShopScreen.gd").new() as Control
	shop.back.connect(_show_hub)
	_set_screen(shop)

func _show_team() -> void:
	var team: Control = preload("res://Hub/TeamScreen.gd").new() as Control
	team.back.connect(_show_hub)
	_set_screen(team)

func _show_terrarium() -> void:
	var sc: Control = preload("res://Hub/TerrariumScreen.gd").new() as Control
	sc.back.connect(_show_hub)
	_set_screen(sc)

func _show_archive() -> void:
	var sc: Control = preload("res://Hub/ArchiveScreen.gd").new() as Control
	sc.back.connect(_show_hub)
	_set_screen(sc)

func _show_quests() -> void:
	var sc: Control = preload("res://Hub/QuestScreen.gd").new() as Control
	sc.back.connect(_show_hub)
	_set_screen(sc)

func _show_overworld() -> void:
	var sc: Control = preload("res://Hub/OverworldScreen.gd").new() as Control
	sc.back.connect(_show_hub)
	sc.request_practice_battle.connect(_on_overworld_practice_battle)
	sc.request_mid_battle.connect(_on_overworld_mid_battle)
	sc.request_boss_battle.connect(_on_overworld_boss_battle)
	_set_screen(sc)

func _show_trade() -> void:
	var sc: Control = preload("res://Hub/TradeScreen.gd").new() as Control
	sc.back.connect(_show_hub)
	_set_screen(sc)

func _show_starter_choice() -> void:
	var starter: Control = preload("res://Hub/StarterChoiceScreen.gd").new() as Control
	starter.back.connect(_show_hub)
	starter.starter_chosen.connect(_on_starter_chosen)
	_set_screen(starter)

func _on_continue() -> void:
	GameState.load_from_save(SaveSystem.load_save())
	_apply_local_settings_to_game_state()
	AudioSettings.apply_from_game_state()
	GameState.session_active = true
	_show_hub()

func _on_new_game() -> void:
	SaveSystem.create_new_save()
	GameState.load_from_save(SaveSystem.load_save())
	_apply_local_settings_to_game_state()
	AudioSettings.apply_from_game_state()
	GameState.session_active = true
	_show_hub()

func _on_quit() -> void:
	get_tree().quit()

func _apply_local_settings_to_game_state() -> void:
	var ls: Dictionary = SaveSystem.load_local_settings()
	for k in ["music", "sfx"]:
		if ls.has(k):
			GameState.settings[k] = bool(ls[k])

func _on_open_battle() -> void:
	if not _can_start_battle_or_toast():
		return
	GameState.battle_mode = GameRules.BATTLE_MODE_STANDARD
	_show_battle()

func _on_open_shop() -> void:
	_show_shop()

func _on_open_team() -> void:
	_show_team()


func _on_overworld_practice_battle() -> void:
	_on_open_battle()


func _on_overworld_mid_battle() -> void:
	if not _can_start_battle_or_toast():
		return
	GameState.battle_mode = GameRules.BATTLE_MODE_MID
	_show_battle()


func _on_overworld_boss_battle() -> void:
	if not _can_start_battle_or_toast():
		return
	GameState.battle_mode = GameRules.BATTLE_MODE_BOSS
	_show_battle()


func _can_start_battle_or_toast() -> bool:
	var starter_ok: bool = bool(GameState.progress.get("starter_chosen", false))
	var team_n: int = GameState.active_team.size()
	if GameRules.can_enter_battle(starter_ok, team_n):
		return true
	if not starter_ok:
		EventBus.request_toast.emit("Choose your starter first.")
	else:
		EventBus.request_toast.emit("Your team is empty — open Team Manager and add at least one unit.")
	return false

func _on_starter_chosen(unit_id: String) -> void:
	GameState.progress["starter_chosen"] = true
	if GameState.active_team.is_empty():
		# Starter rule: grant physical unit to battle, but do NOT grant blueprint.
		GameState.active_team.append(unit_id)
	if GameState.session_active:
		SaveSystem.write_save(GameState.to_save())
	_show_hub()
