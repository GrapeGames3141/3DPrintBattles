class_name BattleResolver

## Target slot for an attack. UNSET = use frontal (same column). CORE = strike enemy printer directly.
const TARGET_UNSET := -2
const TARGET_CORE := -1

## TPU (Air): chance to avoid a direct unit-vs-unit hit (cores are not dodged).
const TPU_DODGE_CHANCE := 0.15


static func tpu_dodges(rng: RandomNumberGenerator) -> bool:
	if rng == null:
		return false
	return rng.randf() < TPU_DODGE_CHANCE


static func is_element_advantage(attacker_element: String, defender_element: String) -> bool:
	var a: String = attacker_element
	var b: String = defender_element
	if a == "Heat" and b == "PLA":
		return true
	if a == "PLA" and b == "Resin":
		return true
	if a == "Resin" and b == "Heat":
		return true
	return false


const ELEMENT_ADVANTAGE_MULT := 2.0
const ELEMENT_DISADVANTAGE_MULT := 0.5


static func effective_damage(attacker_element: String, atk: int, defender_element: String) -> int:
	## Carbon does not participate in the Heat / PLA / Resin triangle (neutral damage multiplier).
	if attacker_element == "Carbon" or defender_element == "Carbon":
		return maxi(1, atk)
	var mult: float = 1.0
	if is_element_advantage(attacker_element, defender_element):
		mult = ELEMENT_ADVANTAGE_MULT
	elif is_element_advantage(defender_element, attacker_element):
		mult = ELEMENT_DISADVANTAGE_MULT
	return maxi(1, int(round(atk * mult)))
