class_name BattleUnitRuntime
extends RefCounted
## Typed, catalog-backed adapter at battle import boundaries. The public battle
## state deliberately remains Dictionary-shaped for save and intent compatibility.
const BATTLE_CATALOG := preload("res://scripts/battle/battle_catalog.gd")
const CORE_DEFINITIONS := preload("res://scripts/core/armor_core_definitions.gd")

var source: Dictionary = {}
var id: String = ""
var name: String = ""
var element: String = "Unknown"
var hp: int = 0
var max_hp: int = 1
var attack: int = 0
var speed: int = 0
var cost: int = 0
var ability: String = "Signature"
var ability_cost: int = 0
var cooldown: int = 0
var cooldown_remaining: int = 0
var armor: int = 0
var suit_id: String = ""
var suit_name: String = ""
var core_id: String = ""
var core_name: String = ""
var shield: int = 0
var verdant_ready: bool = false

static func from_dictionary(unit: Dictionary) -> BattleUnitRuntime:
	var result := BattleUnitRuntime.new()
	result.source = unit.duplicate(true)
	result.id = str(unit.get("id", unit.get("creature_id", unit.get("species_id", ""))))
	var definition: Dictionary = BATTLE_CATALOG.creature(result.id)
	if definition.is_empty(): return result
	result.suit_id = str(unit.get("suit_id", ""))
	var suit_definition: Dictionary = BATTLE_CATALOG.suit(result.suit_id)
	var requested_core_id := str(unit.get("core_id", ""))
	result.core_id = requested_core_id if not suit_definition.is_empty() and not CORE_DEFINITIONS.definition(requested_core_id).is_empty() else ""
	var suit_hp: int = clampi(int(suit_definition.get("hp", 0)), 0, 100)
	var suit_speed: int = clampi(int(suit_definition.get("speed", 0)), 0, 10) + (1 if result.core_id == "storm" else 0)
	var suit_guard: int = clampi(int(suit_definition.get("armor", 0)), 0, 10)
	result.name = str(unit.get("name", definition.get("name", result.id)))
	result.element = str(unit.get("element", definition.get("element", "Unknown")))
	result.max_hp = maxi(1, int(unit.get("max_hp", unit.get("max_health", unit.get("maxHp", clampi(int(definition.get("hp", 1)) + suit_hp, 1, 999))))))
	result.hp = clampi(int(unit.get("hp", unit.get("health", unit.get("current_hp", result.max_hp)))), 0, result.max_hp)
	result.attack = maxi(0, int(unit.get("attack", unit.get("attack_power", unit.get("power", int(definition.get("attack", 0)) + (2 if result.core_id == "ember" else 0))))))
	result.speed = maxi(0, int(unit.get("speed", clampi(int(definition.get("speed", 0)) + suit_speed, 1, 99))))
	result.cost = maxi(0, int(unit.get("cost", unit.get("filament_cost", definition.get("cost", 0)))))
	result.ability = str(unit.get("ability", unit.get("signature", definition.get("ability", "Signature"))))
	var default_ability_cost := maxi(1, int(definition.get("ability_cost", 1)) - (1 if result.core_id == "arcane" else 0))
	result.ability_cost = maxi(1, int(unit.get("ability_cost", unit.get("signature_cost", default_ability_cost))))
	result.cooldown = maxi(0, int(unit.get("cooldown", unit.get("ability_cooldown", definition.get("cooldown", 0)))))
	result.cooldown_remaining = maxi(0, int(unit.get("cooldown_remaining", unit.get("cooldown_left", 0))))
	result.armor = maxi(0, int(unit.get("armor", unit.get("guard", suit_guard))))
	result.suit_name = str(unit.get("suit_name", suit_definition.get("name", "")))
	result.core_name = str(unit.get("core_name", CORE_DEFINITIONS.definition(result.core_id).get("name", "")))
	result.shield = maxi(0, int(unit.get("shield", 0)))
	result.verdant_ready = bool(unit.get("verdant_ready", result.core_id == "verdant")) and result.core_id == "verdant"
	return result

func is_valid() -> bool:
	return not BATTLE_CATALOG.creature(id).is_empty()

func to_dictionary() -> Dictionary:
	if not is_valid(): return source.duplicate(true)
	var result := source.duplicate(true)
	result["id"] = id
	result["name"] = name
	result["element"] = element
	result["hp"] = hp
	result["max_hp"] = max_hp
	result["attack"] = attack
	result["speed"] = speed
	result["cost"] = cost
	result["ability"] = ability
	result["ability_cost"] = ability_cost
	result["cooldown"] = cooldown
	result["cooldown_remaining"] = cooldown_remaining
	result["armor"] = armor
	result["suit_id"] = suit_id
	result["suit_name"] = suit_name
	result["core_id"] = core_id
	result["core_name"] = core_name
	result["shield"] = shield
	result["verdant_ready"] = verdant_ready
	result["attack_buff"] = int(result.get("attack_buff", 0))
	result["attack_debuff"] = maxi(0, int(result.get("attack_debuff", 0)))
	result["ability_lock_turns"] = maxi(0, int(result.get("ability_lock_turns", 0)))
	result["cooling"] = bool(result.get("cooling", false))
	result["status"] = str(result.get("status", "ready"))
	return result
