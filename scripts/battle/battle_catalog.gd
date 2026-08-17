class_name BattleCatalog
extends RefCounted
## Export-safe immutable battle data access.
##
## `Catalog` remains the app-wide Node autoload. Battle-domain static scripts
## intentionally do not rely on that singleton: an Android export can load a
## static battle class before the autoload/class cache is ready. Preloading the
## source script makes the authored constants available without creating a Node
## or duplicating the catalog data.

const DATA := preload("res://scripts/core/catalog.gd")

static func creature(id: String) -> Dictionary:
	for item in DATA.CREATURES:
		if str(item.get("id", "")) == id: return item.duplicate(true)
	return {}

static func suit(id: String) -> Dictionary:
	for item in DATA.SUITS:
		if str(item.get("id", "")) == id: return item.duplicate(true)
	return {}

static func core(id: String) -> Dictionary:
	for item in DATA.CORE_BLUEPRINTS:
		if str(item.get("id", "")) == id: return item.duplicate(true)
	return {}

static func support_card(id: String) -> Dictionary:
	for item in DATA.SUPPORT_CARDS:
		if str(item.get("id", "")) == id: return item.duplicate(true)
	return {}

static func element_multiplier(attacker: String, defender: String) -> int:
	return int(DATA.ELEMENT_CHART.get(attacker, {}).get(defender, 100))

static func signature_for_creature(id: String) -> Dictionary:
	var definition := creature(id)
	var raw_effects = definition.get("signature", {})
	if not raw_effects is Dictionary: return {"damage_bonus":0, "effects":[]}
	var signature: Dictionary = raw_effects.duplicate(true)
	signature["damage_bonus"] = clampi(int(signature.get("damage_bonus", 0)), 0, 99)
	if not signature.get("effects", []) is Array: signature["effects"] = []
	return signature

static func signature_description(id: String) -> String:
	var signature := signature_for_creature(id)
	var phrases: Array[String] = []
	var damage_bonus: int = int(signature.get("damage_bonus", 0))
	if damage_bonus > 0: phrases.append("+%d base damage before element and armor" % damage_bonus)
	for raw_effect in signature.get("effects", []):
		if not raw_effect is Dictionary: continue
		var effect: String = str(raw_effect.get("effect", ""))
		var amount: int = maxi(0, int(raw_effect.get("amount", 0)))
		match effect:
			"heal": phrases.append("restore %d HP" % amount)
			"shield": phrases.append("gain %d shield" % amount)
			"filament": phrases.append("gain %d Filament" % amount)
			"attack_buff": phrases.append("gain +%d Attack" % amount)
			"debuff": phrases.append("foe loses %d Attack and is locked 1 turn" % amount)
			"cleanse": phrases.append("cleanse debuffs")
			"switch_discount": phrases.append("next switch costs %d less" % amount)
			"ability_lock": phrases.append("lock foe signatures %d turns" % amount)
	return "; ".join(phrases) if not phrases.is_empty() else "No added effect"
