class_name CombatRules
extends RefCounted

var units: Dictionary
var unit_definitions: Dictionary


func configure(unit_state: Dictionary, definitions: Dictionary) -> void:
	units = unit_state
	unit_definitions = definitions


func unit_data(id: String) -> Dictionary:
	return unit_definitions[units[id]["key"]]


func effective_stat(id: String, stat: String) -> int:
	var value := int(unit_data(id)[stat])
	var statuses: Dictionary = units[id]["statuses"]
	if stat == "defense" and statuses.has("defense_bonus"):
		value += int(statuses["defense_bonus"]["amount"])
	elif stat == "offense" and statuses.has("offense_bonus"):
		value += int(statuses["offense_bonus"]["amount"])
	elif stat == "movement":
		if statuses.has("movement_bonus"):
			value += int(statuses["movement_bonus"]["amount"])
		if statuses.has("slow"):
			value -= int(statuses["slow"]["amount"])
		value = maxi(1, value)
	return value


func effective_max_hp(id: String) -> int:
	var value := int(units[id]["max_hp"])
	if units[id]["statuses"].has("forest_shield"):
		value += int(units[id]["statuses"]["forest_shield"]["amount"])
	return value


func apply_status(id: String, status_name: String, payload: Dictionary) -> bool:
	if not units.has(id):
		return false
	units[id]["statuses"][status_name] = payload.duplicate(true)
	return true


func heal(id: String, amount: int) -> bool:
	if not units.has(id):
		return false
	units[id]["hp"] = mini(effective_max_hp(id), int(units[id]["hp"]) + amount)
	return true


func damage(attacker_id: String, target_id: String, ignore_defense: bool) -> Dictionary:
	if not units.has(attacker_id) or not units.has(target_id):
		return {"amount": 0, "killed": false}
	var offense := effective_stat(attacker_id, "offense")
	var defense := 0 if ignore_defense else effective_stat(target_id, "defense")
	var amount := maxi(1, offense - floori(float(defense) / 2.0))
	units[target_id]["hp"] = int(units[target_id]["hp"]) - amount
	return {"amount": amount, "killed": int(units[target_id]["hp"]) <= 0}


func raw_damage(target_id: String, amount: int) -> bool:
	if not units.has(target_id):
		return false
	units[target_id]["hp"] = int(units[target_id]["hp"]) - amount
	return int(units[target_id]["hp"]) <= 0


func printer_damage_amount(attacker_id: String, printer_defense: int) -> int:
	return maxi(1, effective_stat(attacker_id, "offense") - floori(float(printer_defense) / 2.0))
