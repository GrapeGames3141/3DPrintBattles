extends Node
## Focused regression for the Workbench's equipped-Core removal affordance.

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
	print("PASS test_equipment_workbench_ui")
	get_tree().quit()
