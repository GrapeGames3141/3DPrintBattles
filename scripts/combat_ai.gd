class_name CombatAI
extends RefCounted


func should_use_round_support(ability_id: String, round_number: int) -> bool:
	return ability_id in ["brace", "bloodlust", "hold_line", "forest_shield"] and round_number % 2 == 1


func most_hurt_ally(units: Dictionary, ally_ids: Array[String]) -> String:
	var result := ""
	var largest_gap := 0
	for ally_id in ally_ids:
		var gap := int(units[ally_id]["max_hp"]) - int(units[ally_id]["hp"])
		if gap > largest_gap:
			largest_gap = gap
			result = ally_id
	return result


func best_destination(
	id: String,
	reachable: Dictionary,
	units: Dictionary,
	printers: Dictionary,
	enemy_faction: String,
	grid
) -> Vector2i:
	var destination: Vector2i = units[id]["cell"]
	var best_distance := 99999
	for cell in reachable.keys():
		var distance := distance_to_nearest_target(id, cell, units, printers, enemy_faction, grid)
		if distance < best_distance:
			best_distance = distance
			destination = cell
	return destination


func distance_to_nearest_target(
	id: String,
	from_cell: Vector2i,
	units: Dictionary,
	printers: Dictionary,
	enemy_faction: String,
	grid
) -> int:
	var result := 99999
	var faction := str(units[id]["faction"])
	for enemy_id in units.keys():
		if str(units[enemy_id]["faction"]) != faction:
			result = mini(result, grid.grid_distance(from_cell, units[enemy_id]["cell"]))
	for cell in printers[enemy_faction]["cells"]:
		result = mini(result, grid.grid_distance(from_cell, cell))
	return result
