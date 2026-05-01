class_name BattleResolver

## Target slot for an attack. UNSET = use frontal (same column). CORE = strike enemy printer directly.
const TARGET_UNSET := -2
const TARGET_CORE := -1


static func is_element_advantage(attacker_element: String, defender_element: String) -> bool:
	var a := attacker_element
	var b := defender_element
	if a == "Heat" and b == "PLA":
		return true
	if a == "PLA" and b == "Resin":
		return true
	if a == "Resin" and b == "Heat":
		return true
	return false


static func effective_damage(attacker_element: String, atk: int, defender_element: String) -> int:
	var mult := 1.0
	if is_element_advantage(attacker_element, defender_element):
		mult = 1.5
	elif is_element_advantage(defender_element, attacker_element):
		mult = 0.75
	return max(1, int(round(atk * mult)))
