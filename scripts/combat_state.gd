class_name CombatState
extends RefCounted

const SNAPSHOT_VERSION := 1


func create_faction_state(rosters: Dictionary, starting_filament: int) -> Dictionary:
	var result := {}
	for faction in rosters.keys():
		result[faction] = {
			"filament": starting_filament,
			"reserve": rosters[faction].duplicate(),
			"spawned": false,
		}
	return result


func create_unit_entry(id: String, unit_key: String, faction: String, cell: Vector2i, hp: int) -> Dictionary:
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
	}


func create_printer_entry(hp: int, defense: int, cells: Array) -> Dictionary:
	return {
		"hp": hp,
		"max_hp": hp,
		"defense": defense,
		"cells": cells.duplicate(),
	}


func build_snapshot(
	units: Dictionary,
	printers: Dictionary,
	faction_state: Dictionary,
	initiative_queue: Array[String],
	flow: Dictionary
) -> Dictionary:
	return {
		"version": SNAPSHOT_VERSION,
		"units": units.duplicate(true),
		"printers": printers.duplicate(true),
		"factions": faction_state.duplicate(true),
		"initiative": initiative_queue.duplicate(),
		"round": int(flow.get("round", 1)),
		"phase": str(flow.get("phase", "setup")),
		"first_faction": str(flow.get("first_faction", "elves")),
		"active_unit_id": str(flow.get("active_unit_id", "")),
		"battle_over": bool(flow.get("battle_over", false)),
		"action_counter": int(flow.get("action_counter", 0)),
		"next_unit_serial": int(flow.get("next_unit_serial", 1)),
	}


func apply_snapshot(
	snapshot: Dictionary,
	units: Dictionary,
	printers: Dictionary,
	faction_state: Dictionary,
	cell_occupants: Dictionary,
	initiative_queue: Array[String]
) -> Dictionary:
	if int(snapshot.get("version", -1)) != SNAPSHOT_VERSION:
		return {}
	for required_key in ["units", "printers", "factions", "initiative"]:
		if not snapshot.has(required_key):
			return {}
	units.clear()
	units.assign(snapshot["units"].duplicate(true))
	printers.clear()
	printers.assign(snapshot["printers"].duplicate(true))
	faction_state.clear()
	faction_state.assign(snapshot["factions"].duplicate(true))
	initiative_queue.clear()
	initiative_queue.append_array(snapshot["initiative"])
	cell_occupants.clear()
	for id in units.keys():
		cell_occupants[units[id]["cell"]] = id
	return {
		"round": int(snapshot.get("round", 1)),
		"phase": str(snapshot.get("phase", "setup")),
		"first_faction": str(snapshot.get("first_faction", "elves")),
		"active_unit_id": str(snapshot.get("active_unit_id", "")),
		"battle_over": bool(snapshot.get("battle_over", false)),
		"action_counter": int(snapshot.get("action_counter", 0)),
		"next_unit_serial": int(snapshot.get("next_unit_serial", 1)),
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
