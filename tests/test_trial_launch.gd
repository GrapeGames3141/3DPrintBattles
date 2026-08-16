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

func team_ids(state: BattleState) -> Array[String]:
	var ids: Array[String] = []
	if state == null or state.players.is_empty(): return ids
	for unit in state.players[0].get("team", []):
		if unit is Dictionary: ids.append(str(unit.get("id", "")))
	return ids

func _ready() -> void:
	# This follows the actual Team Builder callbacks used on phone, rather than
	# assigning a pre-normalized team directly. The profile also carries an
	# equipped armor and ordinary current-save fields.
	var profile: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "cinderpaw").get("profile", {})
	profile["coins"] = 5000
	for creature_id in ["brambleowl", "verdantitan"]:
		var learned: Dictionary = ProgressionRules.purchase_creature_blueprint(profile, creature_id)
		profile = learned.get("profile", profile)
		var printed: Dictionary = ProgressionRules.print_creature(profile, creature_id)
		profile = printed.get("profile", profile)
	var armor_id: String = str(Catalog.ARMOR[0].get("id", ""))
	var learned_armor: Dictionary = ProgressionRules.learn_armor_blueprint(profile, armor_id)
	profile = learned_armor.get("profile", profile)
	var printed_armor: Dictionary = ProgressionRules.print_armor(profile, armor_id)
	profile = printed_armor.get("profile", profile)
	var bramble_instance: String = str(profile.get("creatures", [])[1].get("instance_id", ""))
	var armor_instance: String = str(profile.get("armor", [])[0].get("armor_instance_id", ""))
	var equipped: Dictionary = ProgressionRules.reassign_armor(profile, bramble_instance, armor_instance)
	profile = equipped.get("profile", profile)
	GameManager.profile = profile
	var main := MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame
	main.navigate_to("team")
	await get_tree().process_frame
	main.toggle_team_draft_member(bramble_instance)
	await get_tree().process_frame
	var verdant_instance: String = str(GameManager.profile.get("creatures", [])[2].get("instance_id", ""))
	main.toggle_team_draft_member(verdant_instance)
	await get_tree().process_frame
	main.save_team_draft()
	await get_tree().process_frame
	var expected_ids: Array[String] = ["cinderpaw", "brambleowl", "verdantitan"]
	var preview: Dictionary = SoloBattleFactory.preview(GameManager.profile)
	var preview_ids: Array[String] = []
	for entry in preview.get("team", []): preview_ids.append(str(entry.get("creature_id", "")))
	require(preview_ids == expected_ids and not bool(preview.get("temporary_repair", true)), "authoritative Team Builder save produces the exact canonical preview order")
	main.navigate_to("trials")
	await get_tree().process_frame
	require(tree_has_text(main, "Trial lineup: Cinderpaw, Brambleowl, Verdantitan"), "Trials displays the same canonical lineup that launch will use")
	var before_launch: Dictionary = GameManager.profile.duplicate(true)
	main.start_trial("first_layers_1")
	await get_tree().process_frame
	require(main.screen == "battle" and main.battle != null and team_ids(main.battle) == expected_ids, "actual Team Builder save starts Warm Nozzle with Cinderpaw, Brambleowl, and Verdantitan in order")
	require(main.battle != null and str(main.battle.players[0].get("team", [])[1].get("armor_id", "")) == armor_id, "current owned armor survives the canonical dictionary launch")
	require(GameManager.profile == before_launch, "trial launch does not mutate inventory, saved team, deck, armor, coins, or revision")
	# Android/legacy payload aliases all normalize through BattleState itself.
	var aliases := BattleState.make_team([{"id":"cinderpaw"}, {"species_id":"brambleowl"}, {"creature":"verdantitan"}], 3)
	var alias_ids: Array[String] = []
	for unit in aliases.get("team", []): alias_ids.append(str(unit.get("id", "")))
	require(alias_ids == expected_ids, "BattleState accepts catalog-valid id, species_id, creature, and scalar launch aliases consistently")
	var no_owned: Dictionary = ProfileRules.new_profile()
	no_owned["onboarding"] = {"state":"complete", "starter_id":"", "starter_instance_id":""}
	var refused: Dictionary = SoloBattleFactory.create(no_owned, ["mossmunk"], 3, 3, 2)
	require(not bool(refused.get("ok", true)) and str(refused.get("error", "")).contains("No catalog-valid owned print"), "no-owned profile remains safely refused with its actionable error")
	print("TRIAL_LAUNCH_REPRO saved_team=%s preview=%s built=%s armor=%s" % [GameManager.profile.get("team", []), preview_ids, team_ids(main.battle), armor_id])
	main.queue_free()
	await get_tree().process_frame
	if failures.is_empty(): print("PASS: canonical Trial launch matches Team Builder preview and preserves profile")
	call_deferred("finish")

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
