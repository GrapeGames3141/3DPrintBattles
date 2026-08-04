class_name CombatState
extends RefCounted


func create_faction_state(rosters: Dictionary, starting_filament: int) -> Dictionary:
	var result := {}
	for faction in rosters.keys():
		result[faction] = {
			"filament": starting_filament,
			"reserve": rosters[faction].duplicate(),
			"spawned": false,
		}
	return result


func create_unit_entry(id: String, unit_key: String, faction: String, cell: Vector2i, hp: int, node: Node3D) -> Dictionary:
	return {
		"id": id,
		"key": unit_key,
		"faction": faction,
		"cell": cell,
		"hp": hp,
		"max_hp": hp,
		"cooldown": 0,
		"acted": false,
		"moved": 0,
		"statuses": {},
		"node": node,
	}


func refill_filament(faction_state: Dictionary, maximum: int, amount: int) -> void:
	for faction in faction_state.keys():
		faction_state[faction]["filament"] = mini(maximum, int(faction_state[faction]["filament"]) + amount)


func losing_faction(units: Dictionary, printers: Dictionary, faction_state: Dictionary, rosters: Dictionary) -> String:
	for faction in rosters.keys():
		if int(printers[faction]["hp"]) <= 0:
			return faction
		var living_units := 0
		for id in units.keys():
			if str(units[id]["faction"]) == faction and int(units[id]["hp"]) > 0:
				living_units += 1
		if living_units == 0 and faction_state.has(faction) and faction_state[faction]["reserve"].is_empty():
			return faction
	return ""
