class_name CombatData
extends RefCounted

const FACTION_GOBLINS := "goblins"
const FACTION_ELVES := "elves"

const RARITY_STYLE := {
	"Common": {"color": Color("#7f9b67"), "edge": Color("#a9d479"), "chevrons": 1, "material": "Reclaimed Wood"},
	"Uncommon": {"color": Color("#738b9b"), "edge": Color("#a8d4ee"), "chevrons": 2, "material": "Carved Stone"},
	"Rare": {"color": Color("#a86e31"), "edge": Color("#ffc268"), "chevrons": 3, "material": "Cast Bronze"},
}

const FACTIONS := {
	FACTION_GOBLINS: {
		"name": "Goblin Scrap Legion",
		"short": "GOBLINS",
		"color": Color("#55d98b"),
		"dark": Color("#173b2b"),
		"printer_name": "Scrapmaw War-Forge",
		"printer_concept": "res://assets/concepts/combat/printer-scrapmaw-turnaround-v1.png",
	},
	FACTION_ELVES: {
		"name": "Elven Moonloom Host",
		"short": "ELVES",
		"color": Color("#64d9ff"),
		"dark": Color("#17374a"),
		"printer_name": "Moonloom Grove-Forge",
		"printer_concept": "res://assets/concepts/combat/printer-moonloom-turnaround-v1.png",
	},
}

const UNITS := {
	"ironbound_goblin": {
		"name": "Ironbound Goblin Warrior", "faction": FACTION_GOBLINS, "gender": "Male",
		"rarity": "Common", "roles": ["Melee"], "hp": 24, "defense": 6, "offense": 8,
		"range": 0, "movement": 5, "initiative": 5, "cost": 3,
		"ability": "Brace", "ability_id": "brace", "cooldown": 2,
		"ability_text": "+4 Defense until the next activation.",
		"concept": "res://assets/concepts/combat/four-view-v2/ironbound-goblin/front.png",
		"scene": "res://assets/models/ironbound_goblin_animated_v3.glb",
	},
	"hobgoblin_brute": {
		"name": "Hobgoblin Forge-Brute", "faction": FACTION_GOBLINS, "gender": "Male",
		"rarity": "Rare", "roles": ["Melee"], "hp": 38, "defense": 7, "offense": 14,
		"range": 0, "movement": 3, "initiative": 2, "cost": 5,
		"ability": "Wide Cleave", "ability_id": "cleave", "cooldown": 3,
		"ability_text": "Full damage to the target and half damage beside it.",
		"concept": "res://assets/concepts/combat/four-view-v2/hobgoblin-brute/front.png", "scene": "",
	},
	"scrapbolt_slinger": {
		"name": "Scrapbolt Slinger", "faction": FACTION_GOBLINS, "gender": "Male",
		"rarity": "Uncommon", "roles": ["Ranged"], "hp": 19, "defense": 3, "offense": 10,
		"range": 5, "movement": 5, "initiative": 6, "cost": 4,
		"ability": "Pinning Bolt", "ability_id": "pin", "cooldown": 3,
		"ability_text": "Damage and -2 Movement on the target's next activation.",
		"concept": "res://assets/concepts/combat/four-view-v2/scrapbolt-slinger/front.png", "scene": "",
	},
	"bogbrew_stitchdoc": {
		"name": "Bogbrew Stitchdoc", "faction": FACTION_GOBLINS, "gender": "Female",
		"rarity": "Uncommon", "roles": ["Ranged", "Healer"], "hp": 21, "defense": 4, "offense": 5,
		"range": 3, "movement": 5, "initiative": 4, "cost": 3,
		"ability": "Emergency Stitch", "ability_id": "stitch", "cooldown": 2,
		"ability_text": "Heal for double Offense and remove one negative effect.",
		"concept": "res://assets/concepts/combat/four-view-v2/bogbrew-stitchdoc/front.png", "scene": "",
	},
	"sparkspool_shaman": {
		"name": "Sparkspool Shaman", "faction": FACTION_GOBLINS, "gender": "Female",
		"rarity": "Rare", "roles": ["Magic", "Support"], "hp": 23, "defense": 4, "offense": 7,
		"range": 4, "movement": 4, "initiative": 5, "cost": 4,
		"ability": "Bloodlust Pulse", "ability_id": "bloodlust", "cooldown": 3,
		"ability_text": "Self and adjacent allies gain +3 Offense and +2 Movement through their next activations.",
		"concept": "res://assets/concepts/combat/four-view-v2/sparkspool-shaman/front.png", "scene": "",
	},
	"dawnwood_warden": {
		"name": "Dawnwood Warden", "faction": FACTION_ELVES, "gender": "Female",
		"rarity": "Common", "roles": ["Melee"], "hp": 28, "defense": 7, "offense": 8,
		"range": 0, "movement": 5, "initiative": 5, "cost": 3,
		"ability": "Hold the Line", "ability_id": "hold_line", "cooldown": 3,
		"ability_text": "Self and one adjacent ally gain +3 Defense until their next activations.",
		"concept": "res://assets/concepts/combat/four-view-v2/dawnwood-warden/front.png", "scene": "",
	},
	"moonshadow_rogue": {
		"name": "Moonshadow Rogue", "faction": FACTION_ELVES, "gender": "Female",
		"rarity": "Rare", "roles": ["Melee"], "hp": 20, "defense": 4, "offense": 12,
		"range": 0, "movement": 7, "initiative": 8, "cost": 4,
		"ability": "Ambush", "ability_id": "ambush", "cooldown": 2,
		"ability_text": "After moving 3+ cells, the next attack ignores Defense.",
		"concept": "res://assets/concepts/combat/four-view-v2/moonshadow-rogue/front.png",
		"scene": "res://assets/models/moonlit_elf_duelist_animated.glb",
	},
	"starbough_longbow": {
		"name": "Starbough Longbow", "faction": FACTION_ELVES, "gender": "Male",
		"rarity": "Uncommon", "roles": ["Ranged"], "hp": 18, "defense": 3, "offense": 10,
		"range": 6, "movement": 5, "initiative": 7, "cost": 4,
		"ability": "Pinning Arrow", "ability_id": "pin", "cooldown": 3,
		"ability_text": "Damage and -2 Movement on the target's next activation.",
		"concept": "res://assets/concepts/combat/four-view-v2/starbough-longbow/front.png", "scene": "",
	},
	"lifesong_tender": {
		"name": "Lifesong Tender", "faction": FACTION_ELVES, "gender": "Female",
		"rarity": "Uncommon", "roles": ["Magic", "Healer"], "hp": 20, "defense": 4, "offense": 4,
		"range": 4, "movement": 5, "initiative": 5, "cost": 3,
		"ability": "Renewing Verse", "ability_id": "renew", "cooldown": 2,
		"ability_text": "Heal for double Offense now and 3 at the target's next activation.",
		"concept": "res://assets/concepts/combat/four-view-v2/lifesong-tender/front.png", "scene": "",
	},
	"runeweave_sage": {
		"name": "Runeweave Sage", "faction": FACTION_ELVES, "gender": "Male",
		"rarity": "Rare", "roles": ["Magic", "Support"], "hp": 22, "defense": 5, "offense": 6,
		"range": 4, "movement": 4, "initiative": 6, "cost": 5,
		"ability": "Forest Shield", "ability_id": "forest_shield", "cooldown": 3,
		"ability_text": "Self and adjacent allies gain 6 temporary Health and +3 Defense through their next activations.",
		"concept": "res://assets/concepts/combat/four-view-v2/runeweave-sage/front.png", "scene": "",
	},
}

const ROSTERS := {
	FACTION_GOBLINS: ["ironbound_goblin", "hobgoblin_brute", "scrapbolt_slinger", "bogbrew_stitchdoc", "sparkspool_shaman"],
	FACTION_ELVES: ["dawnwood_warden", "moonshadow_rogue", "starbough_longbow", "lifesong_tender", "runeweave_sage"],
}

static func enemy_faction(faction: String) -> String:
	return FACTION_ELVES if faction == FACTION_GOBLINS else FACTION_GOBLINS


static func unit(unit_id: String) -> Dictionary:
	return (UNITS.get(unit_id, {}) as Dictionary).duplicate(true)


static func total_roster_cost(faction: String) -> int:
	var total := 0
	for unit_id in ROSTERS[faction]:
		total += int(UNITS[unit_id]["cost"])
	return total


static func validate() -> void:
	assert(UNITS.size() == 10, "Combat roster must contain ten units")
	for faction in ROSTERS:
		assert((ROSTERS[faction] as Array).size() == 5, "Each faction must contain five units")
		var total_cost := 0
		for unit_id in ROSTERS[faction]:
			var definition: Dictionary = UNITS[unit_id]
			assert(definition["faction"] == faction, "Roster faction mismatch")
			assert(definition["rarity"] in ["Common", "Uncommon", "Rare"], "Unsupported rarity")
			total_cost += int(definition["cost"])
		assert(total_cost == 19, "Faction roster costs must remain symmetric")
