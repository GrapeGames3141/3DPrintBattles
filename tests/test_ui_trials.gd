extends Node

## Public unified Trial UI regression: the retired legacy trial navigation is
## intentionally not a compatibility surface. Exercise the visible battle menu,
## lock response, launch adapter, and deferred settlement path instead.
const MAIN := preload("res://scenes/main.tscn")
const UNIFIED_RULES := preload("res://scripts/core/unified_rules.gd")
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

func has_scroll_container(node: Node) -> bool:
	if node is ScrollContainer: return true
	for child in node.get_children():
		if has_scroll_container(child): return true
	return false

func new_unified_profile() -> Dictionary:
	var profile := UNIFIED_RULES.new_profile()
	profile = UNIFIED_RULES.choose_starter(profile, "cinderpaw").profile
	return UNIFIED_RULES.print_starter(profile).profile

func _ready() -> void:
	# Exercise the shipped onboarding/Forge path, rather than only constructing a
	# completed profile. This catches fresh-profile reads from retired 0.7 keys.
	GameManager.profile = UNIFIED_RULES.new_profile()
	var onboarding_main := MAIN.instantiate()
	add_child(onboarding_main)
	await get_tree().process_frame
	onboarding_main.pending_starter_id = "cinderpaw"
	onboarding_main.confirm_starter()
	await get_tree().process_frame
	onboarding_main.begin_printer()
	onboarding_main.advance_printer_for_test(ArcaneForgeSequence.PRINT_COMPLETE_BPS)
	onboarding_main.skip_printer()
	onboarding_main.return_to_printer_station()
	await get_tree().process_frame
	var onboarding_progress := onboarding_main.find_child("WorkshopHudProgress", true, false) as ProgressBar
	require(GameManager.has_selected_starter() and onboarding_main.screen == "workshop" and onboarding_main.find_child("WorkshopProgressInstrument", true, false) != null and onboarding_progress != null and tree_has_text(onboarding_main, "SPOOL LEVEL") and not GameManager.profile.has("xp") and not GameManager.profile.has("coins"), "fresh v3 onboarding chooses and prints a starter through the Forge before Workshop renders without retired state")
	var main = onboarding_main
	require(GameManager.has_selected_starter() and main.screen == "workshop" and main.find_child("WorkshopProgressInstrument", true, false) != null and main.find_child("WorkshopHudProgress", true, false) is ProgressBar and tree_has_text(main, "SPOOL LEVEL"), "a clean v3 profile can choose and print a starter before rendering Workshop without legacy fields")
	require(main.get_script().resource_path == "res://scripts/ui/main.gd", "main.tscn ships the established Arcane Foundry controller")
	for route in [["shop", "unified_market", "Foundry Market"], ["archive", "unified_library", "BLUEPRINT ARCHIVE"], ["deck", "unified_deck", "BLUEPRINT ARCHIVE"], ["calibration", "unified_upgrades", "Printer Upgrade Grid"]]:
		main.navigate_to(str(route[0]))
		await get_tree().process_frame
		require(main.screen == str(route[1]) and tree_has_text(main, str(route[2])), "workshop route %s opens its current unified Foundry surface" % str(route[0]))
	main.navigate_to("workshop")
	await get_tree().process_frame
	# Tier progression remains an authoritative lock rather than a retired legacy
	# navigation callback.
	main.screen = "battle"
	main.render()
	await get_tree().process_frame
	main.start_mode("trial_element_bench")
	await get_tree().process_frame
	require(main.battle == null and main.toast.contains("earlier Workshop Trial"), "locked Trial tier refuses launch through the public unified UI")
	main.start_mode("trial_first_layers")
	await get_tree().process_frame
	require(main.battle != null and str(main.battle_settlement_context.get("source_id", "")) == "first_layers_1", "First Layers launches the authored first encounter through the unified UI")
	require(main.battle != null and int(main.battle.player(1).filament) == 200 and int(main.battle.player(1).filament_max) == 400 and str(main.battle_mode) == "trial", "Trial UI launches the v3 rival filament economy and arena mode")
	require(not has_scroll_container(main) and tree_has_text(main, "Foundry Battle") and tree_has_text(main, "Hand 1 / 1"), "shipped unified battle uses a no-scroll Foundry shell with a paged hand")
	if main.battle != null:
		main.battle.finished = true
		main.battle.winner = 0
		main.battle.turn = 8
		main.render()
		await get_tree().process_frame
		await get_tree().process_frame
	require("first_layers_1" in GameManager.profile.get("solo_campaign", {}).get("completed_encounter_ids", []), "unified Trial victory settles the authored first-clear reward once")
	require(main.battle_settlement_finished and main.toast == "Result saved.", "deferred UI settlement records the result before offering return")
	# A normal encounter clear does not skip the authored tier-boss gate. A fresh
	# public launch therefore remains locked until that gate is cleared.
	main.battle = null
	main.screen = "battle"
	main.render()
	await get_tree().process_frame
	main.start_mode("trial_element_bench")
	await get_tree().process_frame
	require(main.battle == null and main.toast.contains("earlier Workshop Trial"), "single encounter settlement retains the authored boss gate for the next Trial tier")
	main.queue_free()
	await get_tree().process_frame
	if failures.is_empty(): print("PASS: unified Trial menu locks, launches, and settles authored encounters")
	call_deferred("finish")

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
