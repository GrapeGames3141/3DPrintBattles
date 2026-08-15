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
	var moss_blueprint: Dictionary = ProgressionRules.purchase_creature_blueprint(profile, "mossmunk")
	require(bool(moss_blueprint.get("ok", false)), "battle fixture learns a healthy bench blueprint")
	profile = moss_blueprint.get("profile", profile)
	var moss_print: Dictionary = ProgressionRules.print_creature(profile, "mossmunk")
	require(bool(moss_print.get("ok", false)), "battle fixture prints a healthy bench creature")
	profile = moss_print.get("profile", profile)
	profile.team = [str(profile.creatures[0].instance_id), str(profile.creatures[1].instance_id)]
	GameManager.profile = profile
	var main := MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame
	for size in [Vector2i(1280, 720), Vector2i(576, 1024), Vector2i(720, 1280)]:
		get_viewport().size = size
		main.size = Vector2(size)
		main.screen = "battle"
		main.battle_secondary_open = false
		main.battle = BattleState.create(GameManager.current_team_loadout(), ["mossmunk"], GameManager.filament_cap(), 3, 2, GameManager.active_deck_cards())
		main.render()
		# The dock is constructed synchronously: even before container settling it
		# must advertise a nonzero, touch-safe action grid rather than becoming an
		# empty Android first frame.
		var initial_grid := main.find_child("BattleActionGrid", true, false) as GridContainer
		require(initial_grid != null and initial_grid.custom_minimum_size.y >= (104.0 if size.y > size.x else 48.0), "BattleActionGrid has an explicit pre-settle height at %s" % size)
		for control_name in ["BattleActionBasicAttack", "BattleActionSignatureAbility", "BattleActionDefend", "BattleActionEndTurn"]:
			var initial_control := main.find_child(control_name, true, false) as Button
			require(initial_control != null and not initial_control.text.is_empty() and initial_control.custom_minimum_size.y >= 48.0, "%s has a pre-settle readable 48px contract at %s" % [control_name, size])
		await get_tree().process_frame
		await get_tree().process_frame
		var frame := main.find_child("BattleFullscreenPanel", true, false) as PanelContainer
		var content := main.find_child("BattleFullscreenContent", true, false) as VBoxContainer
		var grid := main.find_child("BattleActionGrid", true, false) as GridContainer
		require(main.find_child("BattleActionDock", true, false) != null, "BattleActionDock is present before detail rows at %s" % size)
		require(frame != null and content != null and frame.custom_minimum_size.y >= 420.0 and frame.get_global_rect().size.y > 0.0, "battle uses an explicit non-collapsing full-height frame at %s (frame %s)" % [size, frame.get_global_rect() if frame != null else Rect2()])
		require(frame != null and frame.get_global_rect().end.y >= float(size.y) * 0.85 and frame.get_global_rect().end.y <= float(size.y), "battle composition reaches the lower visible viewport at %s (frame %s)" % [size, frame.get_global_rect() if frame != null else Rect2()])
		require(grid != null and grid.columns == (2 if size.y > size.x else 4), "BattleActionGrid uses the responsive column count at %s" % size)
		require(grid != null and grid.custom_minimum_size.y >= (104.0 if size.y > size.x else 48.0) and grid.get_global_rect().size.y >= (104.0 if size.y > size.x else 48.0), "BattleActionGrid retains a real visible height at %s (rect %s)" % [size, grid.get_global_rect() if grid != null else Rect2()])
		for control_name in ["BattleActionBasicAttack", "BattleActionSignatureAbility", "BattleActionDefend", "BattleActionEndTurn"]:
			var control := main.find_child(control_name, true, false) as Button
			var rect := control.get_global_rect() if control != null else Rect2()
			require(control != null and not control.text.is_empty() and rect.size.x > 0.0 and rect.size.y >= 48.0 and rect.position.x >= 0.0 and rect.position.y >= 0.0 and rect.end.x <= float(size.x) and rect.end.y <= float(size.y), "%s is visible with readable text and a 48px target on first render at %s (rect %s)" % [control_name, size, rect])
		var secondary := main.find_child("BattleSecondaryToggle", true, false) as Button
		require(secondary != null and secondary.custom_minimum_size.y >= 48.0 and secondary.get_global_rect().size.y >= 48.0 and secondary.get_global_rect().end.y <= float(size.y), "Bench and Hand expander is visible on first render at %s" % size)
		if secondary != null:
			secondary.emit_signal("pressed")
			await get_tree().process_frame
			var bench := main.find_child("BattleBenchGrid", true, false) as GridContainer
			require(bench != null and bench.get_child_count() > 0 and bench.get_global_rect().end.y <= float(size.y), "expanded Bench has a reachable switch at %s (rect %s)" % [size, bench.get_global_rect() if bench != null else Rect2()])
			var hand_tab := main.find_child("BattleSecondaryHandTab", true, false) as Button
			if hand_tab != null:
				hand_tab.emit_signal("pressed")
				await get_tree().process_frame
			var hand := main.find_child("BattleHandGrid", true, false) as GridContainer
			require(hand != null and hand.get_child_count() > 0 and hand.get_global_rect().end.y <= float(size.y), "expanded Hand has reachable cards at %s (rect %s)" % [size, hand.get_global_rect() if hand != null else Rect2()])
			var concede_tab := main.find_child("BattleSecondaryConcedeTab", true, false) as Button
			if concede_tab != null:
				concede_tab.emit_signal("pressed")
				await get_tree().process_frame
			var concede := main.find_child("BattleActionConcede", true, false) as Button
			require(concede != null and concede.get_global_rect().end.y <= float(size.y), "expanded Concede control is reachable at %s (rect %s)" % [size, concede.get_global_rect() if concede != null else Rect2()])
			var before_log: int = main.battle.log.size()
			main.intent({"type":"defend"})
			await get_tree().process_frame
			require(main.battle.log.size() > before_log, "expanded battle submits a legal core action at %s" % size)
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
