extends Node

const MAIN := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	var main_source := (MAIN.instantiate().get_script() as GDScript).source_code
	require(not main_source.contains("func render_battle_action_dock") and not main_source.contains("func render_battle_secondary"), "Battle dock and tactical panel builders belong to BattleViewComponent")
	require(main_source.contains("func printer_blueprint_ids") and main_source.contains("func select_printer_blueprint"), "Main retains Printer compatibility facades")
	var profile: Dictionary = RULES.new_profile()
	profile = RULES.choose_starter(profile, "cinderpaw").profile
	profile = RULES.print_starter(profile).profile
	RULES.grant_card(profile, "mossmunk")
	profile.forge_coins = 500
	GameManager.profile = profile
	var main := MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame
	main.open_printer_picker()
	await get_tree().process_frame
	require(main.screen == "printer" and main.printer_blueprint_ids().has("mossmunk") and main.find_child("PrinterBlueprintCardMossmunk", true, false) != null and main.find_child("PrinterBlueprintSelector", true, false) != null, "BlueprintTrayView owns the integrated learned-blueprint cards")
	main.select_printer_blueprint("mossmunk")
	await get_tree().process_frame
	require(main.printer_blueprint_selected_id == "mossmunk", "select_printer_blueprint facade preserves Main-owned selection")
	main.queue_free()
	if failures.is_empty(): print("PASS: refactor ownership facades")
	call_deferred("finish")

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
