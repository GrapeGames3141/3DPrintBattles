extends Node

const MAIN := preload("res://scenes/main.tscn")
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	var profile: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "cinderpaw").profile
	profile["coins"] = 500
	var blueprint := ProgressionRules.purchase_creature_blueprint(profile, "mossmunk")
	profile = blueprint["profile"]
	var printed := ProgressionRules.print_creature(profile, "mossmunk")
	profile = printed["profile"]
	profile["team"] = [str(profile["creatures"][0].get("instance_id", "")), str(profile["creatures"][1].get("instance_id", ""))]
	GameManager.profile = ProfileRules.migrate(profile)
	var main := MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame
	get_viewport().size = Vector2i(576, 1024)
	main.size = Vector2(576, 1024)
	main.screen = "proving"
	main.render()
	await get_tree().process_frame
	require(main.find_child("OpenWorkshopTrials", true, false) != null and tree_has_text(main, "Daily Training"), "Proving Door separates Daily Training from Workshop Trials")
	main.navigate_to("trials")
	await get_tree().process_frame
	var scroll := find_named(main, "TouchFirstScroll") as ScrollContainer
	require(scroll != null and scroll.scroll_deadzone <= 8 and scroll.follow_focus and scroll.get_v_scroll_bar().custom_minimum_size.x >= 28.0, "long Trial screen uses touch-first scrolling with a visible wide focus-follow scrollbar")
	var first := find_named(main, "TrialStartfirst_layers_1") as Button
	var second := find_named(main, "TrialStartfirst_layers_2") as Button
	require(first != null and not first.disabled and second != null and second.disabled, "first encounter starts unlocked and later encounters stay locked")
	if first != null: first.emit_signal("pressed")
	await get_tree().process_frame
	require(main.screen == "battle" and main.battle_mode == "trial" and main.trial_encounter_id == "first_layers_1" and main.battle != null and str(main.battle.active_unit(1).get("id", "")) == "mossmunk" and main.battle_ai_difficulty == "Apprentice", "trial start creates its fixed opponent, spool, and AI battle")
	var revision_before: int = int(GameManager.profile.get("revision", 0))
	if main.battle != null:
		main.battle.finished = true
		main.battle.winner = 0
		main.battle.turn = 8
	main.finish_battle()
	await get_tree().process_frame
	require(main.screen == "trials" and "first_layers_1" in GameManager.profile.get("solo_campaign", {}).get("completed_encounter_ids", []) and int(GameManager.creature_mastery(str(GameManager.profile["team"][0]))) == 3 and int(GameManager.profile.get("revision", 0)) == revision_before + 1, "victory returns to trials with one atomic first-clear reward plus saved-team mastery")
	var replay_revision: int = int(GameManager.profile.get("revision", 0))
	require(GameManager.claim_campaign_victory("first_layers_1", 99) and int(GameManager.profile.get("revision", 0)) == replay_revision, "worse completed replay creates no duplicate reward or revision")
	main.screen = "collection"; main.render(); await get_tree().process_frame
	require(tree_has_text(main, "Mastery"), "Collection presents per-instance mastery")
	main.screen = "team"; main.render(); await get_tree().process_frame
	require(tree_has_button_text(main, "Mastery"), "Team Builder presents per-instance mastery")
	main.screen = "trials"; main.render(); await get_tree().process_frame
	var locked_control := find_named(main, "TrialStartfirst_layers_2") as Control
	var rect := locked_control.get_global_rect() if locked_control != null else Rect2()
	require(rect.size.y >= 44.0 and rect.position.x >= 0.0 and rect.end.x <= 576.0, "portrait trial action remains touch-safe and in bounds")
	# Phone symptom: a current-schema profile can retain only a raw catalog alias
	# with no instance ID, a species team ref, and a missing active deck. Start
	# must build a temporary match without persisting a repair.
	var stale_profile := GameManager.profile.duplicate(true)
	stale_profile["creatures"] = [{"id":"cinderpaw"}]
	stale_profile["team"] = [{"species":"cinderpaw"}]
	stale_profile["active_deck_id"] = "missing-review-deck"
	stale_profile["decks"] = []
	var stale_before: Dictionary = stale_profile.duplicate(true)
	GameManager.profile = stale_profile
	main.screen = "trials"; main.render(); await get_tree().process_frame
	require(tree_has_text(main, "Legacy owned prints will be used temporarily") and find_named(main, "EditCurrentTrialTeam") != null, "Trials exposes a temporary legacy lineup preview and touch-safe Team Builder route")
	main.start_trial("first_layers_1")
	await get_tree().process_frame
	require(main.screen == "battle" and main.battle != null and str(main.battle.active_unit(0).get("id", "")) == "cinderpaw", "migrated review profile launches Warm Nozzle using a temporary owned-team repair")
	require(tree_has_text(main, "Lineup notice:") and tree_has_text(main, "temporarily uses"), "temporary repair message remains visible after Battle render instead of a discarded toast")
	require(GameManager.profile == stale_before, "temporary Warm Nozzle repair leaves the legacy profile deeply unchanged")
	main.queue_free()
	await get_tree().process_frame
	if failures.is_empty(): print("PASS: Workshop Trial navigation, locks, victory return, and mastery UI")
	call_deferred("finish")

func tree_has_text(node: Node, fragment: String) -> bool:
	if node is Label and (node as Label).text.contains(fragment): return true
	for child in node.get_children():
		if tree_has_text(child, fragment): return true
	return false

func tree_has_button_text(node: Node, fragment: String) -> bool:
	if node is Button and (node as Button).text.contains(fragment): return true
	for child in node.get_children():
		if tree_has_button_text(child, fragment): return true
	return false

func find_named(node: Node, expected: String) -> Node:
	if str(node.name) == expected: return node
	for child in node.get_children():
		var found := find_named(child, expected)
		if found != null: return found
	return null

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
