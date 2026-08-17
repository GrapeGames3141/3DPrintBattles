class_name ArmorCoreDefinitions
extends RefCounted
## Exact player-facing Core effect copy and deterministic equipment data.

const ARMOR_TIERS := ["standard", "reinforced", "arcane", "masterwork", "legendary"]
const CORES := {
	"ember": {"name": "Ember Core", "color": Color("ff6338"), "effect": "+2 Attack"},
	"tide": {"name": "Tide Core", "color": Color("38d8ff"), "effect": "Start battle with 4 Shield"},
	"verdant": {"name": "Verdant Core", "color": Color("65dc72"), "effect": "Once per battle: heal 4 below half HP"},
	"storm": {"name": "Storm Core", "color": Color("ffe15a"), "effect": "+1 Speed"},
	"arcane": {"name": "Arcane Core", "color": Color("f44cff"), "effect": "Signature costs 1 less (minimum 1)"}
}

static func suit_definition(tier_id: String) -> Dictionary:
	for suit in Catalog.SUITS:
		if str(suit.get("id", "")) == tier_id:
			return suit.duplicate(true)
	return {}

static func core_blueprint_definition(core_id: String) -> Dictionary:
	for core in Catalog.CORE_BLUEPRINTS:
		if str(core.get("id", "")) == core_id:
			var result: Dictionary = core.duplicate(true)
			result["effect"] = str(definition(core_id).get("effect", ""))
			return result
	return {}

static func core_ids() -> Array[String]:
	return ["ember", "tide", "verdant", "storm", "arcane"]

static func definition(core_id: String) -> Dictionary:
	return Dictionary(CORES.get(core_id, {})).duplicate(true)

static func equipment_contract() -> Dictionary:
	return {
		"armor_slot": "armor",
		"armor_tiers": ARMOR_TIERS.duplicate(),
		"optional_socket": "core",
		"full_suit_only": true,
		"migrations": "deferred_until_release"
	}
