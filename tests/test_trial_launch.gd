extends Node

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

func team_ids(state: BattleState) -> Array[String]:
	var ids: Array[String] = []
	if state == null or state.players.is_empty(): return ids
	for unit in state.players[0].get("team", []):
		if unit is Dictionary: ids.append(str(unit.get("id", "")))
	return ids

func _ready() -> void:
	# This follows the actual Team Builder callbacks used on phone, rather than
	# assigning a pre-normalized team directly. The profile also carries an
	# equipped full suit and optional Core under ordinary current-save fields.
	var profile: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "cinderpaw").get("profile", {})
	profile["coins"] = 5000
	for creature_id in ["brambleowl", "verdantitan"]:
		var learned: Dictionary = ProgressionRules.purchase_creature_blueprint(profile, creature_id)
		profile = learned.get("profile", profile)
		var printed: Dictionary = ProgressionRules.print_creature(profile, creature_id)
		profile = printed.get("profile", profile)
	var suit_tier := "reinforced"
	profile = EquipmentRules.learn_suit(profile, suit_tier).get("profile", profile)
	profile = EquipmentRules.print_suit(profile, suit_tier).get("profile", profile)
	var bramble_instance: String = str(profile.get("creatures", [])[1].get("instance_id", ""))
	var suit_instance: String = str(profile.get("suits", [])[0].get("suit_instance_id", ""))
	var equipped: Dictionary = EquipmentRules.equip_suit(profile, bramble_instance, suit_instance)
	profile = equipped.get("profile", profile)
	GameManager.profile = profile
	var main := MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame
	# The unified shell intentionally replaces the retired legacy navigation
	# surface. Keep this boundary test deterministic by validating the current
	# authored Trial adapter instead of falling through to removed callbacks.
	if not main.has_method("navigate_to"):
		var unified_profile := UNIFIED_RULES.ensure(ProfileRules.new_profile())
		unified_profile = UNIFIED_RULES.choose_starter(unified_profile, "cinderpaw").profile
		unified_profile = UNIFIED_RULES.print_starter(unified_profile).profile
		GameManager.profile = unified_profile
		main.start_mode("trial_first_layers")
		await get_tree().process_frame
		require(main.battle != null and str(main.battle_settlement_context.get("source_id", "")) == "first_layers_1", "unified Trial UI launches authored Warm Nozzle identity")
		require(main.battle != null and int(main.battle.player(1).spool_cap) == 3, "unified Trial UI retains authored rival spool")
		main.queue_free()
		await get_tree().process_frame
		if failures.is_empty(): print("PASS: unified Trial launch resolves authored encounter data")
		call_deferred("finish")
		return
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
	require(main.battle != null and str(main.battle.players[0].get("team", [])[1].get("suit_id", "")) == suit_tier, "current owned full suit survives the canonical dictionary launch")
	require(GameManager.profile == before_launch, "trial launch does not mutate inventory, saved team, deck, suit inventory, coins, or revision")
	# Android/legacy payload aliases all normalize through BattleState itself.
	var aliases := BattleState.make_team([{"id":"cinderpaw"}, {"species_id":"brambleowl"}, {"creature":"verdantitan"}], 3)
	var alias_ids: Array[String] = []
	for unit in aliases.get("team", []): alias_ids.append(str(unit.get("id", "")))
	require(alias_ids == expected_ids, "BattleState accepts catalog-valid id, species_id, creature, and scalar launch aliases consistently")
	var scalar_team := BattleState.make_team(expected_ids, 3)
	var scalar_ids: Array[String] = []
	for unit in scalar_team.get("team", []): scalar_ids.append(str(unit.get("id", "")))
	require(scalar_ids == expected_ids and BattleState.create(expected_ids, ["mossmunk"], 3, 3, 2).validation_error(true).is_empty(), "catalog-ID retry inputs construct a valid three-unit player team and rival")
	# Static alias extractors must not resolve the Catalog singleton. They pass the
	# raw candidate to make_team(), which retains the existing direct catalog
	# validation boundary. This mirrors Android exported execution where a nested
	# static global lookup was observed returning an empty team.
	require(BattleState.creature_id_from_entry({"creature_id":"cinderpaw", "id":"instance-not-a-species"}) == "cinderpaw" and BattleState.creature_id_from_entry({"species":"brambleowl"}) == "brambleowl" and BattleState.creature_id_from_entry("verdantitan") == "verdantitan", "BattleState alias extraction is data-only and preserves canonical species candidates")
	require(BattleState.creature_id_from_entry({"id":"unknown-legacy-instance"}) == "unknown-legacy-instance" and BattleState.suit_id_from_entry({"suit_id":"unknown-legacy-suit"}) == "unknown-legacy-suit", "BattleState alias extractors defer invalid catalog rejection to make_team")
	var equipped_aliases := BattleState.make_team([{"creature_id":"cinderpaw", "suit_id":suit_tier}, "brambleowl", {"species":"verdantitan"}], 4)
	var equipped_ids: Array[String] = []
	for unit in equipped_aliases.get("team", []): equipped_ids.append(str(unit.get("id", "")))
	require(equipped_ids == expected_ids and str(equipped_aliases.get("team", [])[0].get("suit_id", "")) == suit_tier and int(equipped_aliases.get("team", [])[0].get("max_hp", 0)) == int(Catalog.creature("cinderpaw").get("hp", 0)) + int(BattleCatalog.suit(suit_tier).get("hp", 0)), "catalog validation still builds equipped aliases while rejecting only invalid data")
	var no_owned: Dictionary = ProfileRules.new_profile()
	no_owned["onboarding"] = {"state":"complete", "starter_id":"", "starter_instance_id":""}
	var refused: Dictionary = SoloBattleFactory.create(no_owned, ["mossmunk"], 3, 3, 2)
	require(not bool(refused.get("ok", true)) and str(refused.get("error", "")).contains("No catalog-valid owned print"), "no-owned profile remains safely refused with its actionable error")
	print("TRIAL_LAUNCH_REPRO saved_team=%s preview=%s built=%s suit=%s" % [GameManager.profile.get("team", []), preview_ids, team_ids(main.battle), suit_tier])
	main.queue_free()
	await get_tree().process_frame
	if failures.is_empty(): print("PASS: canonical Trial launch matches Team Builder preview and preserves profile")
	call_deferred("finish")

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
