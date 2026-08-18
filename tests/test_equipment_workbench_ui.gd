extends Node
## Focused regression for the Workbench's equipped-Core removal affordance.

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	var profile := ProfileRules.new_profile()
	profile["coins"] = 9999
	profile = ProfileRules.choose_starter(profile, "cinderpaw").get("profile", profile)
	for tier_id in ArmorCoreDefinitions.ARMOR_TIERS:
		profile = EquipmentRules.learn_suit(profile, tier_id).get("profile", profile)
		profile = EquipmentRules.print_suit(profile, tier_id).get("profile", profile)
	profile = EquipmentRules.learn_core(profile, "arcane").get("profile", profile)
	profile = EquipmentRules.print_core(profile, "arcane").get("profile", profile)
	var creature_id := str(profile.get("onboarding", {}).get("starter_instance_id", ""))
	var suit_id := str(profile.get("suits", [])[4].get("suit_instance_id", ""))
	var core_id := str(profile.get("cores", [])[0].get("core_instance_id", ""))
	profile = EquipmentRules.equip_suit(profile, creature_id, suit_id).get("profile", profile)
	profile = EquipmentRules.socket_core(profile, suit_id, core_id).get("profile", profile)
	GameManager.profile = profile
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(main)
	main.set("screen", "armor")
	main.call("render")
	await get_tree().process_frame
	await get_tree().process_frame
	var remove_core := main.find_child("EquipmentRemoveCore", true, false) as Button
	if remove_core == null or not remove_core.visible or remove_core.text != "Remove Core":
		push_error("Equipment Workbench must expose a visible named Remove Core action for a socketed Core.")
		get_tree().quit(1)
		return
	var normal := remove_core.get_theme_stylebox("normal") as StyleBoxTexture
	var hover := remove_core.get_theme_stylebox("hover") as StyleBoxTexture
	var pressed := remove_core.get_theme_stylebox("pressed") as StyleBoxTexture
	var focus := remove_core.get_theme_stylebox("focus") as StyleBoxTexture
	var disabled := remove_core.get_theme_stylebox("disabled") as StyleBoxTexture
	if normal == null or hover == null or pressed == null or focus == null or disabled == null or normal.texture == hover.texture or normal.texture == pressed.texture or normal.texture == disabled.texture:
		push_error("Equipment Workbench actions must use the shared textured Arcane Foundry keycap state contract.")
		get_tree().quit(1)
		return
	for dimensions in [Vector2i(576, 1024), Vector2i(1280, 720)]:
		get_viewport().size = dimensions
		main.size = Vector2(dimensions)
		main.call("render")
		await get_tree().process_frame
		await get_tree().process_frame
		var tier_cards := main.find_child("EquipmentWorkbenchTierCards", true, false)
		var hero_control := main.find_child("EquipmentWorkbenchHero", true, false) as Control
		var selector := main.find_child("EquipmentWorkbenchCreatureSelector", true, false) as Control
		var tabs := main.find_child("EquipmentWorkbenchTabs", true, false) as Control
		var cards := main.find_child("EquipmentWorkbenchTierCards", true, false) as Control
		require(hero_control != null and hero_control.get_global_rect().size.y <= (240.0 if dimensions.y > dimensions.x else 320.0), "Workbench hero remains compact at %s" % dimensions)
		require(selector != null and selector.get_global_rect().size.y >= 48.0 and selector.get_global_rect().size.y <= 56.0 and tabs != null and tabs.get_global_rect().size.y >= 48.0 and tabs.get_global_rect().size.y <= 56.0, "Workbench selector and tabs retain one 48px touch row at %s" % dimensions)
		require(cards != null and cards.get_global_rect().size.y <= 260.0, "Workbench tier cards do not expand into a vertical text column at %s" % dimensions)
		if tier_cards != null:
			for child in tier_cards.get_children():
				var card := child as Control
				require(card != null and card.get_global_rect().size.x >= 120.0 and card.get_global_rect().size.y >= 76.0 and card.get_global_rect().size.y <= 90.0, "Workbench tier card stays readable and compact at %s" % dimensions)
	GameManager.profile.settings.text_scale_bps = 15000
	var large_dimensions := Vector2i(1280, 720)
	get_viewport().size = large_dimensions
	main.size = Vector2(large_dimensions)
	main.call("render")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	# Cover the deferred focus pass as well as the initial layout pass: it must
	# not restore a below-title scroll offset after the Workbench first paints.
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var large_scroll := main.find_child("TouchFirstScroll", true, false) as ScrollContainer
	var large_heading := main.find_child("EquipmentWorkbenchHeading", true, false) as Control
	var large_cards := main.find_child("EquipmentWorkbenchTierCards", true, false) as GridContainer
	require(large_scroll != null and is_zero_approx(large_scroll.scroll_vertical), "150% landscape Workbench opens at its scroll origin")
	require(large_heading != null and large_heading.get_global_rect().position.y >= large_scroll.get_global_rect().position.y and large_heading.get_global_rect().end.y <= large_scroll.get_global_rect().end.y, "150% landscape Workbench keeps its title visible at entry")
	require(large_cards != null and large_cards.columns == 1, "150% landscape Workbench uses a readable one-column tier rail")
	if large_cards != null:
		for child in large_cards.get_children():
			var large_card := child as Control
			require(large_card != null and large_card.get_global_rect().size.x >= 280.0 and large_card.get_global_rect().position.x >= 0.0 and large_card.get_global_rect().end.x <= float(large_dimensions.x), "150% landscape tier card remains wide and horizontally contained")
	if not failures.is_empty():
		get_tree().quit(1)
		return
	print("PASS test_equipment_workbench_ui")
	get_tree().quit()
