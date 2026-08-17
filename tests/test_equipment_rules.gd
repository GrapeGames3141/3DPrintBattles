extends Node

func _ready() -> void:
	var p := ProfileRules.new_profile()
	p.coins = 10000
	for tier in ArmorCoreDefinitions.ARMOR_TIERS:
		var learned := EquipmentRules.learn_suit(p, tier); require(bool(learned.get("ok", false)), "learn suit " + tier); p = learned.get("profile", {})
		var printed := EquipmentRules.print_suit(p, tier); require(bool(printed.get("ok", false)), "print suit " + tier); p = printed.get("profile", {})
	for core_id in ArmorCoreDefinitions.core_ids():
		var learned_core := EquipmentRules.learn_core(p, core_id); require(bool(learned_core.get("ok", false)), "learn core " + core_id); p = learned_core.get("profile", {})
		var printed_core := EquipmentRules.print_core(p, core_id); require(bool(printed_core.get("ok", false)), "print core " + core_id); p = printed_core.get("profile", {})
	var cinder := ProfileRules.choose_starter(p, "cinderpaw"); require(bool(cinder.get("ok", false)), "starter"); p = cinder.get("profile", {})
	var suit_id := str(p.get("suits", [])[0].get("suit_instance_id", "")); var core_id := str(p.get("cores", [])[0].get("core_instance_id", ""))
	var equipped := EquipmentRules.equip_suit(p, str(cinder.get("instance_id", "")), suit_id); require(bool(equipped.get("ok", false)), "equip suit"); p = equipped.get("profile", {})
	var socketed := EquipmentRules.socket_core(p, suit_id, core_id); require(bool(socketed.get("ok", false)), "socket core"); p = socketed.get("profile", {})
	var loadout := EquipmentRules.suit_loadout(p, str(cinder.instance_id)); require(str(loadout.tier_id) == "standard" and str(loadout.core_id) == "ember", "authoritative loadout")
	var battle := BattleState.create([{"creature_id":"cinderpaw","suit_id":"legendary","core_id":"arcane"}], ["mossmunk"], 3, 3, 2)
	var unit := battle.active_unit(0); require(int(unit.max_hp) == 70 and int(unit.armor) == 3 and int(unit.speed) == 8 and int(unit.ability_cost) == 1, "tier and core deterministic stats")
	print("PASS test_equipment_rules")
	get_tree().quit()

func require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message); get_tree().quit(1)
