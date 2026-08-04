class_name CombatCommandValidator
extends RefCounted

const SPAWN := "spawn"
const SKIP_SPAWN := "skip_spawn"
const MOVE := "move"
const ATTACK := "attack"
const ABILITY := "ability"
const WAIT := "wait"
const TYPES := [SPAWN, SKIP_SPAWN, MOVE, ATTACK, ABILITY, WAIT]


func validate(command: Dictionary, sender_faction: String, context: Dictionary) -> String:
	var command_type := str(command.get("type", ""))
	if command_type not in TYPES:
		return "Unknown command type."
	if sender_faction == "":
		return "The sender has no assigned faction."
	var phase := str(context.get("phase", "setup"))
	var units: Dictionary = context.get("units", {})
	var factions: Dictionary = context.get("factions", {})
	var definitions: Dictionary = context.get("definitions", {})
	var valid_cells: Array = context.get("valid_cells", [])
	if command_type in [SPAWN, SKIP_SPAWN]:
		if phase != "spawn" or not factions.has(sender_faction):
			return "Deployment is not active."
		if bool(factions[sender_faction].get("spawned", false)):
			return "That faction already completed deployment."
		if command_type == SKIP_SPAWN:
			return ""
		var unit_key := str(command.get("unit_key", ""))
		if not definitions.has(unit_key) or unit_key not in factions[sender_faction]["reserve"]:
			return "That unit is not in reserve."
		if str(definitions[unit_key].get("faction", "")) != sender_faction:
			return "That unit belongs to the other faction."
		if int(definitions[unit_key]["cost"]) > int(factions[sender_faction]["filament"]):
			return "There is not enough filament."
		return ""
	if phase != "initiative":
		return "No activation is accepting commands."
	var actor_id := str(context.get("active_unit_id", ""))
	if actor_id == "" or not units.has(actor_id):
		return "There is no active unit."
	if str(units[actor_id]["faction"]) != sender_faction:
		return "It is the other faction's activation."
	if str(command.get("actor_id", actor_id)) != actor_id:
		return "The command actor is not active."
	if command_type == WAIT:
		return ""
	if command_type == ABILITY and not bool(context.get("requires_cell", true)):
		return ""
	if not command.has("cell") or typeof(command["cell"]) != TYPE_VECTOR2I:
		return "The command needs a grid cell."
	if command["cell"] not in valid_cells:
		return "That grid cell is not valid for this action."
	return ""


func make(command_type: String, sequence: int, actor_id := "", cell := Vector2i(-1, -1), unit_key := "") -> Dictionary:
	var command := {"type": command_type, "sequence": sequence}
	if actor_id != "":
		command["actor_id"] = actor_id
	if cell.x >= 0:
		command["cell"] = cell
	if unit_key != "":
		command["unit_key"] = unit_key
	return command
