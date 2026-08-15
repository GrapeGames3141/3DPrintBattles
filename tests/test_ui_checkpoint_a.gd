extends Node

const MAIN := preload("res://scenes/main.tscn")

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	var profile: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "cinderpaw").profile
	profile.coins = 600
	GameManager.profile = profile
	var main := MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame
	require(main.screen == "workshop" and main.find_child("WorkshopMap", true, false) != null and get_viewport().gui_get_focus_owner() is Button, "workshop map has an accessible initial station focus")
	main._run_workshop_station("calibration")
	await get_tree().process_frame
	require(main.screen == "calibration", "Calibration Bench is reachable from the workshop tray")
	var revision: int = int(GameManager.profile.revision)
	var reward: int = GameManager.complete_workshop_job(72, "2026-08-15")
	require(reward == 22 and int(GameManager.profile.revision) == revision + 1, "Calibration Bench applies one atomic daily reward")
	main.navigate_to("workshop")
	main._run_workshop_station("yard")
	await get_tree().process_frame
	require(main.screen == "yard", "Print Yard is reachable from the workshop tray")
	var yard_xp: int = GameManager.visit_print_yard("2026-08-15")
	require(yard_xp > 0 and int(GameManager.profile.spool_level) >= 3, "Print Yard activity applies a nonzero progression reward")
	main.navigate_to("workshop")
	main._run_workshop_station("deck")
	await get_tree().process_frame
	require(main.screen == "deck", "named deck slots are reachable from the Assembly Workbench")
	main._run_workshop_station("armor")
	await get_tree().process_frame
	require(main.screen == "armor", "armor lifecycle is reachable from the Assembly Workbench")
	main.start_battle()
	await get_tree().process_frame
	main.toggle_battle_concede()
	require(main.battle_concede_armed, "solo concede requires a confirming action")
	main.cancel_battle_concede()
	require(not main.battle_concede_armed and not main.battle.finished, "solo concede can be cancelled before confirmation")
	main.toggle_battle_concede()
	main.intent({"type":"defend"})
	require(not main.battle_concede_armed, "a non-concede solo intent disarms concede before the rival turn")
	main.start_battle()
	await get_tree().process_frame
	main.toggle_battle_concede()
	main.toggle_battle_concede()
	require(main.battle != null and main.battle.finished and int(main.battle.winner) == 1, "confirmed solo concede resolves through BattleRules")
	main.start_local_vs()
	await get_tree().process_frame
	main.local_ready_seat = int(main.local_authority.state.active_player)
	main.render()
	main.toggle_local_concede()
	require(main.local_concede_armed, "local concede requires a confirming action")
	main.cancel_local_concede()
	require(not main.local_concede_armed, "local concede can be cancelled before confirmation")
	main.toggle_local_concede()
	main.submit_local_intent({"type":"defend"})
	require(not main.local_concede_armed and main.local_ready_seat == -1, "local non-concede intent disarms concede and returns to private handoff")
	main.navigate_to("settings")
	await get_tree().process_frame
	var escape := InputEventKey.new()
	escape.pressed = true
	escape.keycode = KEY_ESCAPE
	main._unhandled_key_input(escape)
	await get_tree().process_frame
	require(main.screen == "workshop" and get_viewport().gui_get_focus_owner() is Button, "Escape returns a workshop screen to the hub with deterministic focus")
	main.queue_free()
	if failures.is_empty(): print("PASS: checkpoint A workshop navigation and concede UI")
	call_deferred("finish")

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
