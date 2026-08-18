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

func new_unified_profile() -> Dictionary:
	var profile := UNIFIED_RULES.ensure(ProfileRules.new_profile())
	profile = UNIFIED_RULES.choose_starter(profile, "cinderpaw").profile
	return UNIFIED_RULES.print_starter(profile).profile

func _ready() -> void:
	GameManager.profile = new_unified_profile()
	var main := MAIN.instantiate()
	add_child(main)
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
	require(main.battle != null and int(main.battle.player(1).spool_cap) == 3 and str(main.battle_mode) == "trial_first_layers", "Trial UI preserves authored rival spool and arena mode")
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
