class_name BattleUnitRuntime
extends RefCounted
## Typed, catalog-backed adapter at battle import boundaries. The public battle
## state deliberately remains Dictionary-shaped for save and intent compatibility.

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
var armor_id: String = ""
var armor_name: String = ""

static func from_dictionary(unit: Dictionary) -> BattleUnitRuntime:
	var result := BattleUnitRuntime.new()
	result.source = unit.duplicate(true)
	result.id = str(unit.get("id", unit.get("creature_id", unit.get("species_id", ""))))
	var definition: Dictionary = Catalog.creature(result.id)
	if definition.is_empty(): return result
	result.armor_id = str(unit.get("armor_id", unit.get("equipped_armor_id", "")))
	var armor_definition: Dictionary = ProgressionRules.armor_def(result.armor_id)
	var armor_hp: int = clampi(int(armor_definition.get("hp", 0)), 0, 100)
	var armor_speed: int = clampi(int(armor_definition.get("speed", 0)), -10, 10)
	var armor_guard: int = clampi(int(armor_definition.get("armor", 0)), 0, 10)
	result.name = str(unit.get("name", definition.get("name", result.id)))
	result.element = str(unit.get("element", definition.get("element", "Unknown")))
	result.max_hp = maxi(1, int(unit.get("max_hp", unit.get("max_health", unit.get("maxHp", clampi(int(definition.get("hp", 1)) + armor_hp, 1, 999))))))
	result.hp = clampi(int(unit.get("hp", unit.get("health", unit.get("current_hp", result.max_hp)))), 0, result.max_hp)
	result.attack = maxi(0, int(unit.get("attack", unit.get("attack_power", unit.get("power", definition.get("attack", 0))))))
	result.speed = maxi(0, int(unit.get("speed", clampi(int(definition.get("speed", 0)) + armor_speed, 1, 99))))
	result.cost = maxi(0, int(unit.get("cost", unit.get("filament_cost", definition.get("cost", 0)))))
	result.ability = str(unit.get("ability", unit.get("signature", definition.get("ability", "Signature"))))
	result.ability_cost = maxi(0, int(unit.get("ability_cost", unit.get("signature_cost", definition.get("ability_cost", 0)))))
	result.cooldown = maxi(0, int(unit.get("cooldown", unit.get("ability_cooldown", definition.get("cooldown", 0)))))
	result.cooldown_remaining = maxi(0, int(unit.get("cooldown_remaining", unit.get("cooldown_left", 0))))
	result.armor = maxi(0, int(unit.get("armor", unit.get("guard", armor_guard))))
	result.armor_name = str(unit.get("armor_name", armor_definition.get("name", "")))
	return result

func is_valid() -> bool:
	return not Catalog.creature(id).is_empty()

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
	result["armor_id"] = armor_id
	result["armor_name"] = armor_name
	result["shield"] = maxi(0, int(result.get("shield", 0)))
	result["attack_buff"] = int(result.get("attack_buff", 0))
	result["attack_debuff"] = maxi(0, int(result.get("attack_debuff", 0)))
	result["ability_lock_turns"] = maxi(0, int(result.get("ability_lock_turns", 0)))
	result["cooling"] = bool(result.get("cooling", false))
	result["status"] = str(result.get("status", "ready"))
	return result
