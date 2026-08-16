extends Node

const MAIN := preload("res://scenes/main.tscn")

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func tree_has_text(node: Node, fragment: String) -> bool:
	if node is Label and (node as Label).text.contains(fragment): return true
	for child in node.get_children():
		if tree_has_text(child, fragment): return true
	return false

func _ready() -> void:
	var profile: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "cinderpaw").profile
	profile.coins = 600
	GameManager.profile = profile
	var main := MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame
	# This scenario asserts player-turn Bench and concede controls.  Keep the
	# repeatable training seed fixed rather than deriving it from today's date.
	main.shop_day_key = "2026-08-15"
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
	# A touch-style card mutation must retain its bound card ID without pulling
	# focus back to the first deck slot after the synchronous redraw.
	main._focus_after_render = false
	var raw_before: int = main.deck_draft.count("raw_filament")
	main.change_deck_draft("raw_filament", false)
	await get_tree().process_frame
	var focus_owner := get_viewport().gui_get_focus_owner()
	require(main.deck_draft.count("raw_filament") == raw_before - 1 and focus_owner == null, "touch-style deck draft rerender keeps the intended stable card ID and leaves keyboard focus untouched")
	main._run_workshop_station("armor")
	await get_tree().process_frame
	require(main.screen == "armor" and tree_has_text(main, "Step 1 - Acquire blueprints") and tree_has_text(main, "Step 2 - Print learned armor") and tree_has_text(main, "Step 3 - Equip, move, or remove"), "armor lifecycle is reachable through explicit acquisition, printing, and fitting steps")
	# Exercise the stable bound team callbacks with three actual owned prints.
	GameManager.learn_blueprint("mossmunk")
	GameManager.print_creature("mossmunk")
	GameManager.learn_blueprint("aquafin")
	GameManager.print_creature("aquafin")
	var starter_id := str(GameManager.profile.onboarding.starter_instance_id)
	var moss_id := str(GameManager.profile.creatures[1].instance_id)
	var aqua_id := str(GameManager.profile.creatures[2].instance_id)
	# Exercise the Armor Workbench's stable named handlers through the full
	# acquire -> print -> equip -> unequip/reassign lifecycle.
	var armor_definition_id := str(Catalog.ARMOR[0].get("id", ""))
	require(GameManager.learn_armor_blueprint(armor_definition_id), "armor workbench fixture learns one catalog blueprint")
	main.print_armor_blueprint(armor_definition_id)
	await get_tree().process_frame
	require(main.screen == "printer" and GameManager.profile.armor.is_empty(), "armor Forge preview is transaction-safe before printing")
	main.begin_printer()
	main.advance_printer_for_test(7000)
	await get_tree().process_frame
	var armor_instance_id := str(GameManager.profile.armor[0].get("armor_instance_id", ""))
	main.equip_or_move_armor(starter_id, armor_instance_id)
	await get_tree().process_frame
	var starter_record: Dictionary = GameManager.profile.creatures[0]
	var armor_record: Dictionary = GameManager.profile.armor[0]
	require(str(starter_record.get("armor_id", "")) == armor_definition_id and str(armor_record.get("equipped_to", "")) == starter_id, "Armor Workbench handler equips the printed armor to its named creature")
	main.unequip_armor_from(starter_id)
	main.equip_or_move_armor(moss_id, armor_instance_id)
	await get_tree().process_frame
	armor_record = GameManager.profile.armor[0]
	require(str(GameManager.profile.creatures[1].get("armor_id", "")) == armor_definition_id and str(armor_record.get("equipped_to", "")) == moss_id, "Armor Workbench handler reassigns a concrete armor instance without closure drift")
	main.navigate_to("team")
	await get_tree().process_frame
	main.toggle_team_draft_member(moss_id)
	main.toggle_team_draft_member(aqua_id)
	main.save_team_draft()
	await get_tree().process_frame
	require(GameManager.profile.team == [starter_id, moss_id, aqua_id] and GameManager.current_team_loadout().size() == 3, "team builder saves three distinct bound instance IDs through stable callbacks")
	main.start_battle()
	await get_tree().process_frame
	main.battle_secondary_open = true
	main.battle_secondary_tab = "bench"
	main.render()
	await get_tree().process_frame
	var bench := main.find_child("BattleBenchGrid", true, false) as GridContainer
	require(main.battle != null and main.battle.players[0].team.size() == 3 and bench != null and bench.get_child_count() == 2, "three-member saved team creates two healthy Bench switches")
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
