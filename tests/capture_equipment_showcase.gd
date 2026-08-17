extends Node
## Non-interactive visual QA for suit/Core Forge, Team, and armored battle states.

const ARTIFACT_ROOT := "user://"

func _ready() -> void:
	var profile := _fixture_profile()
	GameManager.profile = profile
	for dimensions in [Vector2i(576, 1024), Vector2i(1280, 720)]:
		await _capture_forge(profile, dimensions, "legendary", false, ArcaneForgeSequence.IDLE, "forge_suit_select")
		await _capture_forge(profile, dimensions, "legendary", false, ArcaneForgeSequence.PRINTING, "forge_suit_printing")
		await _capture_forge(profile, dimensions, "legendary", false, ArcaneForgeSequence.RAW_HOLD, "forge_suit_raw_hold")
		await _capture_forge(profile, dimensions, "arcane", true, ArcaneForgeSequence.IDLE, "forge_core_select")
		await _capture_forge(profile, dimensions, "arcane", true, ArcaneForgeSequence.PRINTING, "forge_core_printing")
		await _capture_forge(profile, dimensions, "arcane", true, ArcaneForgeSequence.RAW_HOLD, "forge_core_raw_hold")
		await _capture_screen(profile, dimensions, "team", "team_armored_cinderpaw")
		await _capture_battle(profile, dimensions)
		await _capture_battle_multiturn(profile, dimensions)
	print("CAPTURED Forge, Team, and Battle equipment showcase")
	get_tree().quit()

func _fixture_profile() -> Dictionary:
	var profile := ProfileRules.new_profile()
	profile["coins"] = 9999
	profile = ProfileRules.choose_starter(profile, "cinderpaw").get("profile", profile)
	for tier_id in ArmorCoreDefinitions.ARMOR_TIERS:
		profile = EquipmentRules.learn_suit(profile, tier_id).get("profile", profile)
		profile = EquipmentRules.print_suit(profile, tier_id).get("profile", profile)
	for core_key in ArmorCoreDefinitions.core_ids():
		profile = EquipmentRules.learn_core(profile, core_key).get("profile", profile)
		profile = EquipmentRules.print_core(profile, core_key).get("profile", profile)
	var creature_id := str(profile.get("onboarding", {}).get("starter_instance_id", ""))
	var suit_id := str(profile.get("suits", [])[4].get("suit_instance_id", ""))
	var core_id := str(profile.get("cores", [])[4].get("core_instance_id", ""))
	profile = EquipmentRules.equip_suit(profile, creature_id, suit_id).get("profile", profile)
	profile = EquipmentRules.socket_core(profile, suit_id, core_id).get("profile", profile)
	return profile

func _capture_forge(profile: Dictionary, dimensions: Vector2i, item_id: String, is_core: bool, phase: String, tag: String) -> void:
	var main := _main(profile, dimensions)
	main.set("screen", "printer")
	main.set("printer_is_armor", true)
	main.set("printer_is_core", is_core)
	main.set("printer_armor_id", item_id)
	main.set("printer_price", int((ArmorCoreDefinitions.core_blueprint_definition(item_id) if is_core else ProgressionRules.armor_def(item_id)).get("print", 0)))
	var sequence := ArcaneForgeSequence.create(false, true)
	if phase != ArcaneForgeSequence.IDLE:
		sequence.begin()
		if phase == ArcaneForgeSequence.PRINTING: sequence.advance(3600)
		else:
			sequence.advance(10000)
			sequence.request_commit()
			sequence.resolve_commit(true)
	main.set("printer_sequence", sequence)
	main.call("render")
	await _save(main, dimensions, tag)

func _capture_screen(profile: Dictionary, dimensions: Vector2i, screen: String, tag: String) -> void:
	var main := _main(profile, dimensions)
	main.set("screen", screen)
	main.call("render")
	await _save(main, dimensions, tag)

func _capture_battle(profile: Dictionary, dimensions: Vector2i) -> void:
	var main := _main(profile, dimensions)
	main.set("screen", "battle")
	main.set("battle", BattleState.create(GameManager.current_team_loadout(), ["mossmunk"], 3, 3, 2, GameManager.active_deck_cards()))
	main.set("battle_last_event", "ability")
	main.set("battle_last_actor", 0)
	main.set("battle_presentation_serial", 1)
	main.call("render")
	for _frame in 4: await get_tree().process_frame
	var activation := main.find_child("BattleLeftCoreActivation", true, false) as CorePowerVFX
	if activation != null:
		activation.configure_core("arcane")
		activation.show_peak()
	else:
		push_error("Battle Arcane Core activation node was not present for visual QA.")
	await _save(main, dimensions, "battle_armored_cinderpaw_arcane_peak")

func _capture_battle_multiturn(profile: Dictionary, dimensions: Vector2i) -> void:
	var main := _main(profile, dimensions)
	main.set("screen", "battle")
	main.set("battle", BattleState.create(GameManager.current_team_loadout(), ["mossmunk"], 3, 3, 2, GameManager.active_deck_cards()))
	# Run six accepted player/rival exchanges through the same re-render path as
	# the live HUD. Defend keeps the review fixture alive while battle feedback
	# and history change on every frame.
	main.battle.turn = 2
	main.battle.opening_player = 1
	main.battle.active_player = 0
	main.set("ai_pending", true)
	main.call("render")
	for _exchange in 6:
		var player_result := BattleRules.apply_intent(main.battle, 0, {"type": "defend"})
		if not bool(player_result.get("ok", false)):
			push_error("Multi-turn player fixture action was rejected.")
			get_tree().quit(1)
			return
		main.set("battle_last_event", "defend")
		main.set("battle_last_actor", 0)
		main.set("battle_presentation_serial", int(main.get("battle_presentation_serial")) + 1)
		main.call("render")
		await get_tree().process_frame
		var rival_result := BattleRules.apply_intent(main.battle, 1, {"type": "defend"})
		if not bool(rival_result.get("ok", false)):
			push_error("Multi-turn rival fixture action was rejected.")
			get_tree().quit(1)
			return
		main.set("battle_last_event", "defend")
		main.set("battle_last_actor", 1)
		main.set("battle_presentation_serial", int(main.get("battle_presentation_serial")) + 1)
		main.call("render")
		await get_tree().process_frame
	await _save(main, dimensions, "battle_armored_cinderpaw_multiturn")

func _main(profile: Dictionary, dimensions: Vector2i) -> Node:
	GameManager.profile = profile.duplicate(true)
	get_window().size = dimensions
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(main)
	return main

func _save(main: Node, dimensions: Vector2i, tag: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	if image == null:
		push_error("Capture requires a non-dummy renderer.")
		get_tree().quit(1)
		return
	image.save_png(ARTIFACT_ROOT + "%s_%dx%d.png" % [tag, dimensions.x, dimensions.y])
	main.queue_free()
	await get_tree().process_frame
