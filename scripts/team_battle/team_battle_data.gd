class_name TeamBattleData
extends RefCounted

## M1's deliberately small, additive authority table.  It does not reuse legacy
## card costs or printer-health concepts.

const SCHEMA_VERSION := 1
const FILAMENT_CAP := 9
const STARTING_FILAMENT := 5
const HAND_SIZE := 4
const FIFO_CAPACITY := 3
const FABRICATION_COST := 3
const FILAMENT_REGEN := 2
const MINIMUM_HIT := 1
const ARMOR_CAP := 8

const FULL_SUIT_ARMOR := 8
const IRON_GEM_ATTACK := 2
const SURGE_NUMERATOR := 3
const SURGE_DENOMINATOR := 2

const TRAIT_LANDED_INTERVAL := 3
const CINDERPAW_TRAIT_DAMAGE := 2
const AQUAFIN_TRAIT_HEAL := 3
const VOLTWIG_TRAIT_FILAMENT := 1
const MOSSMUNK_TRAIT_ARMOR := 2

const MEMBERS := {
	"cinderpaw": {"hp": 34, "attack": 7},
	"aquafin": {"hp": 36, "attack": 6},
	"voltwig": {"hp": 30, "attack": 7},
	"mossmunk": {"hp": 31, "attack": 5},
}

const SUPPORTS := {
	"raw_filament": {"cost": 0, "aid": 2, "work": 0, "kind": "aid"},
	"heated_spool": {"cost": 0, "aid": 3, "work": 0, "kind": "aid"},
	"standard_full_suit": {"cost": 2, "aid": 0, "work": 1, "kind": "armor", "effect": FULL_SUIT_ARMOR},
	"iron_gem": {"cost": 2, "aid": 0, "work": 1, "kind": "gem", "effect": IRON_GEM_ATTACK},
	"forge_surge": {"cost": 2, "aid": 0, "work": 0, "kind": "surge", "numerator": SURGE_NUMERATOR, "denominator": SURGE_DENOMINATOR},
}

const RECOMMENDED_KIT := [
	"raw_filament", "raw_filament", "raw_filament",
	"heated_spool", "heated_spool",
	"standard_full_suit", "standard_full_suit", "standard_full_suit",
	"iron_gem", "iron_gem", "iron_gem",
	"forge_surge", "forge_surge", "forge_surge", "forge_surge",
]

const TUTORIAL_OPENING := ["raw_filament", "standard_full_suit", "iron_gem", "forge_surge"]

static func is_member_eligible(member_id: String) -> bool:
	return MEMBERS.has(member_id)

static func is_support_eligible(card_id: String) -> bool:
	return SUPPORTS.has(card_id)

static func recommended_kit() -> Array:
	return RECOMMENDED_KIT.duplicate()

static func validate_production_team(team: Variant) -> String:
	if not team is Array or team.size() != 3:
		return "Team must contain exactly three companions."
	var seen := {}
	for value in team:
		if not value is String or not is_member_eligible(value):
			return "Team contains an unknown or ineligible companion."
		if seen.has(value):
			return "Team companions must be distinct."
		seen[value] = true
	return ""

static func validate_test_team(team: Variant) -> String:
	if not team is Array or team.size() != 1:
		return "Test-only 1v1 factory requires exactly one companion."
	if not team[0] is String or not is_member_eligible(team[0]):
		return "Test-only roster contains an unknown companion."
	return ""

static func validate_kit(kit: Variant) -> String:
	if not kit is Array or kit.size() != 15:
		return "Support Kit must contain exactly 15 cards."
	for value in kit:
		if not value is String or not is_support_eligible(value):
			return "Support Kit contains an ineligible card."
	return ""

static func member_stats(member_id: String) -> Dictionary:
	return MEMBERS.get(member_id, {}).duplicate(true)

static func support_definition(card_id: String) -> Dictionary:
	return SUPPORTS.get(card_id, {}).duplicate(true)
