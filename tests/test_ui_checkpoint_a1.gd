extends Node

const MAIN := preload("res://scenes/main.tscn")

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	require(int(ProjectSettings.get_setting("display/window/size/viewport_width")) == 720 and int(ProjectSettings.get_setting("display/window/size/viewport_height")) == 720, "project uses a square 720 base viewport")
	require(str(ProjectSettings.get_setting("display/window/stretch/mode")) == "canvas_items" and str(ProjectSettings.get_setting("display/window/stretch/aspect")) == "expand", "project uses canvas_items expand stretching")
	var profile: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "cinderpaw").profile
	profile.coins = 500
	GameManager.profile = profile
	var main := MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame
	for size in [Vector2i(1280, 720), Vector2i(720, 1280)]:
		get_viewport().size = size
		main.screen = "battle"
		main.battle = BattleState.create(GameManager.current_team_loadout(), ["mossmunk"], GameManager.filament_cap(), 3, 2, GameManager.active_deck_cards())
		main.render()
		await get_tree().process_frame
		var grid := main.find_child("BattleActionGrid", true, false) as GridContainer
		require(grid != null and grid.columns == (2 if size.y > size.x else 5), "BattleActionGrid uses the responsive column count at %s" % size)
		for control_name in ["BattleActionBasicAttack", "BattleActionSignatureAbility", "BattleActionDefend", "BattleActionEndTurn", "BattleActionConcede"]:
			var control := main.find_child(control_name, true, false) as Button
			var rect := control.get_global_rect() if control != null else Rect2()
			require(control != null and rect.position.x >= 0.0 and rect.position.y >= 0.0 and rect.end.x <= float(size.x) and rect.end.y <= float(size.y), "%s is visible on first render at %s" % [control_name, size])
	main.screen = "local_vs"
	main.local_authority = LocalBattleAuthority.create(GameManager.current_team_loadout(), ["mossmunk"], GameManager.active_deck_cards(), 20260815)
	main.local_ready_seat = int(main.local_authority.state.active_player)
	main.render()
	await get_tree().process_frame
	var local_grid := main.find_child("LocalBattleActionGrid", true, false) as GridContainer
	require(local_grid != null and local_grid.columns == 2, "local-versus actions use a portrait-safe grid")
	main.queue_free()
	if failures.is_empty(): print("PASS: checkpoint A1 responsive battle action layout")
	call_deferred("finish")

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
