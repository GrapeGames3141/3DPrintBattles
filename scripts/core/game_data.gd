class_name GameData
extends RefCounted
## Immutable catalog for PrintForge Legends.
## Everything at runtime (profiles, battle state, network messages) stores IDs only.

const VERSION := "1.0.0"

const DECK_SIZE := 20
const MAX_HAND := 9
const MAX_BOARD := 6
const PRINTER_HP := 20
const POWER_COST := 2
## Filament on a Printer's spool for the whole battle.
const SPOOL_SIZE := 40
## Extra Filament per level of the Bigger Spool workshop upgrade.
const SPOOL_PER_UPGRADE := 5
## Filament a Printer can lay down each turn.
const PRINT_SPEED := 3
## At the start of a turn you draw one card, then more until you hold this many.
const HAND_TOP_UP := 3
## Filament that goes back on the spool when one of your prints shatters.
const SCRAP_REFUND := 1

const RARITY_ORDER := ["common", "uncommon", "rare", "epic", "legendary"]
const RARITIES := {
	"common": {"name": "Common", "color": "#c3ccd9", "craft": 40, "recycle": 3, "copies": 2},
	"uncommon": {"name": "Uncommon", "color": "#5fd47c", "craft": 80, "recycle": 6, "copies": 2},
	"rare": {"name": "Rare", "color": "#58a6ff", "craft": 160, "recycle": 15, "copies": 2},
	"epic": {"name": "Epic", "color": "#c47dff", "craft": 400, "recycle": 36, "copies": 2},
	"legendary": {"name": "Legendary", "color": "#ffc93c", "craft": 1000, "recycle": 90, "copies": 1},
}

## Filament colours per element: `color` is the plastic, `dark` is the card body.
const ELEMENTS := {
	"Fire": {"color": "#ff6a3d", "dark": "#4a1d14"},
	"Water": {"color": "#3fa7ff", "dark": "#12304f"},
	"Lightning": {"color": "#ffd23f", "dark": "#4a3a10"},
	"Nature": {"color": "#5fcf6a", "dark": "#173d22"},
	"Ice": {"color": "#9fe8ff", "dark": "#1d4250"},
	"Stone": {"color": "#b59a7a", "dark": "#3a3026"},
	"Wind": {"color": "#b8f0d8", "dark": "#1f4a40"},
	"Arcane": {"color": "#b98cff", "dark": "#2e1d52"},
	"Neutral": {"color": "#d0d6e0", "dark": "#2a3242"},
}

const KEYWORDS := {
	"guard": {"name": "Guard", "text": "Enemies must attack this print first."},
	"rush": {"name": "Rush", "text": "Can attack enemy prints the turn it is printed."},
	"brim": {"name": "Brim", "text": "Ignores the first damage it takes."},
	"siphon": {"name": "Siphon", "text": "Damage it deals repairs your Printer."},
	"twin": {"name": "Twin Nozzle", "text": "Can attack twice each turn."},
}

const SPRITE := "res://assets/creatures/2d/%s_sprite_sheet.png"
const RAW := "res://assets/creatures/2d/raw/%s_raw_print.png"
const TOOL_ART := "res://assets/tools/%s.png"
const ARMOR_ART := "res://assets/armor/raw/%s_raw_print_alpha_v2.png"

## Effect targets (`to`): target, self, enemy_prints, friendly_prints,
## other_friendly_prints, all_prints, enemy_printer, own_printer.
const CARDS := [
	# ---------------------------------------------------------------- prints
	{"id": "mossmunk", "name": "Mossmunk", "type": "creature", "cost": 1, "atk": 1, "hp": 3, "element": "Nature", "rarity": "common",
		"kw": ["guard"], "text": ""},
	{"id": "voltwig", "name": "Voltwig", "type": "creature", "cost": 1, "atk": 2, "hp": 1, "element": "Lightning", "rarity": "common",
		"kw": ["rush"], "text": ""},
	{"id": "cinderpaw", "name": "Cinderpaw", "type": "creature", "cost": 2, "atk": 3, "hp": 2, "element": "Fire", "rarity": "common",
		"kw": [], "text": "On Print: Deal 1 damage.", "target": "enemy",
		"on_print": [{"op": "damage", "n": 1, "to": "target"}]},
	{"id": "aquafin", "name": "Aquafin", "type": "creature", "cost": 2, "atk": 2, "hp": 3, "element": "Water", "rarity": "common",
		"kw": [], "text": "On Print: Repair your Printer by 2.",
		"on_print": [{"op": "heal", "n": 2, "to": "own_printer"}]},
	{"id": "sparkotter", "name": "Sparkotter", "type": "creature", "cost": 2, "atk": 2, "hp": 2, "element": "Lightning", "rarity": "common",
		"kw": [], "text": "On Print: +1 Print Speed this turn.",
		"on_print": [{"op": "filament", "n": 1}]},
	{"id": "frostling", "name": "Frostling", "type": "creature", "cost": 3, "atk": 3, "hp": 3, "element": "Ice", "rarity": "uncommon",
		"kw": [], "text": "On Print: Jam an enemy print.", "target": "enemy_print",
		"on_print": [{"op": "jam", "to": "target"}]},
	{"id": "stoneback", "name": "Stoneback", "type": "creature", "cost": 3, "atk": 2, "hp": 6, "element": "Stone", "rarity": "uncommon",
		"kw": ["guard"], "text": ""},
	{"id": "galehopper", "name": "Galehopper", "type": "creature", "cost": 3, "atk": 4, "hp": 2, "element": "Wind", "rarity": "uncommon",
		"kw": ["rush"], "text": ""},
	{"id": "glassdrake", "name": "Glassdrake", "type": "creature", "cost": 4, "atk": 5, "hp": 3, "element": "Fire", "rarity": "rare",
		"kw": [], "text": "Shatter: Deal 2 damage to all enemy prints.",
		"shatter": [{"op": "damage", "n": 2, "to": "enemy_prints"}]},
	{"id": "coralisk", "name": "Coralisk", "type": "creature", "cost": 4, "atk": 3, "hp": 5, "element": "Water", "rarity": "rare",
		"kw": ["siphon"], "text": ""},
	{"id": "runestag", "name": "Runestag", "type": "creature", "cost": 4, "atk": 4, "hp": 4, "element": "Arcane", "rarity": "rare",
		"kw": [], "text": "On Print: Draw a card.",
		"on_print": [{"op": "draw", "n": 1}]},
	{"id": "brambleowl", "name": "Brambleowl", "type": "creature", "cost": 4, "atk": 4, "hp": 3, "element": "Nature", "rarity": "rare",
		"kw": ["brim"], "text": ""},
	{"id": "ironmaw", "name": "Ironmaw", "type": "creature", "cost": 5, "atk": 4, "hp": 7, "element": "Stone", "rarity": "epic",
		"kw": ["guard"], "text": ""},
	{"id": "aurorawing", "name": "Aurorawing", "type": "creature", "cost": 5, "atk": 4, "hp": 5, "element": "Ice", "rarity": "epic",
		"kw": [], "text": "On Print: Jam all enemy prints.",
		"on_print": [{"op": "jam", "to": "enemy_prints"}]},
	{"id": "thunderelk", "name": "Thunderelk", "type": "creature", "cost": 5, "atk": 4, "hp": 5, "element": "Lightning", "rarity": "epic",
		"kw": ["rush", "twin"], "text": ""},
	{"id": "coalgriffin", "name": "Coalgriffin", "type": "creature", "cost": 6, "atk": 6, "hp": 5, "element": "Fire", "rarity": "epic",
		"kw": [], "text": "On Print: Deal 3 damage.", "target": "enemy",
		"on_print": [{"op": "damage", "n": 3, "to": "target"}]},
	{"id": "tidewhale", "name": "Tidewhale", "type": "creature", "cost": 6, "atk": 4, "hp": 9, "element": "Water", "rarity": "epic",
		"kw": ["guard"], "text": "On Print: Repair your Printer by 4.",
		"on_print": [{"op": "heal", "n": 4, "to": "own_printer"}]},
	{"id": "skyforge", "name": "Skyforge", "type": "creature", "cost": 6, "atk": 5, "hp": 5, "element": "Wind", "rarity": "epic",
		"kw": [], "text": "On Print: Blow an enemy print back to its owner's hand.", "target": "enemy_print",
		"on_print": [{"op": "bounce", "to": "target"}]},
	{"id": "pyraxis", "name": "Pyraxis", "type": "creature", "cost": 7, "atk": 6, "hp": 6, "element": "Arcane", "rarity": "legendary",
		"kw": [], "text": "On Print: Deal 2 damage to all enemy prints.",
		"on_print": [{"op": "damage", "n": 2, "to": "enemy_prints"}]},
	{"id": "verdantitan", "name": "Verdantitan", "type": "creature", "cost": 7, "atk": 5, "hp": 9, "element": "Nature", "rarity": "legendary",
		"kw": ["guard"], "text": "On Print: Give your other prints +1/+1.",
		"on_print": [{"op": "buff", "atk": 1, "hp": 1, "to": "other_friendly_prints"}]},
	{"id": "miragefox", "name": "Miragefox", "type": "creature", "cost": 8, "atk": 7, "hp": 6, "element": "Ice", "rarity": "legendary",
		"kw": ["rush", "brim"], "text": ""},
	{"id": "voidmanta", "name": "Voidmanta", "type": "creature", "cost": 8, "atk": 7, "hp": 7, "element": "Arcane", "rarity": "legendary",
		"kw": [], "text": "On Print: Destroy an enemy print.", "target": "enemy_print",
		"on_print": [{"op": "destroy", "to": "target"}]},
	{"id": "worldcoil", "name": "Worldcoil", "type": "creature", "cost": 9, "atk": 8, "hp": 10, "element": "Stone", "rarity": "legendary",
		"kw": ["guard", "brim"], "text": ""},
	{"id": "starloom", "name": "Starloom", "type": "creature", "cost": 9, "atk": 8, "hp": 8, "element": "Arcane", "rarity": "legendary",
		"kw": [], "text": "On Print: Give your other prints +2/+2 and Brim.",
		"on_print": [{"op": "buff", "atk": 2, "hp": 2, "kw": ["brim"], "to": "other_friendly_prints"}]},
	# ----------------------------------------------------------------- tools
	{"id": "spare_spool", "name": "Spare Spool", "type": "tool", "cost": 0, "rarity": "uncommon",
		"text": "Add 3 Filament to your Spool. +1 Print Speed this turn.",
		"effects": [{"op": "spool", "n": 3}, {"op": "filament", "n": 1}]},
	{"id": "heat_gun", "name": "Heat Gun", "type": "tool", "cost": 1, "rarity": "common",
		"text": "Deal 2 damage.", "target": "enemy",
		"effects": [{"op": "damage", "n": 2, "to": "target"}]},
	{"id": "glue_stick", "name": "Glue Stick", "type": "tool", "cost": 1, "rarity": "common",
		"text": "Give a friendly print +1/+2.", "target": "friendly_print",
		"effects": [{"op": "buff", "atk": 1, "hp": 2, "to": "target"}]},
	{"id": "hobby_knife", "name": "Hobby Knife", "type": "tool", "cost": 2, "rarity": "common",
		"text": "Give a friendly print +3 Attack.", "target": "friendly_print",
		"effects": [{"op": "buff", "atk": 3, "hp": 0, "to": "target"}]},
	{"id": "test_print", "name": "Test Print", "type": "tool", "cost": 2, "rarity": "common",
		"text": "Print two 1/1 Test Bots.",
		"effects": [{"op": "summon", "card": "test_bot", "n": 2}]},
	{"id": "calipers", "name": "Calipers", "type": "tool", "cost": 3, "rarity": "common",
		"text": "Draw 2 cards.",
		"effects": [{"op": "draw", "n": 2}]},
	{"id": "cooling_fan", "name": "Cooling Fan", "type": "tool", "cost": 2, "rarity": "uncommon",
		"text": "Jam an enemy print. Draw a card.", "target": "enemy_print",
		"effects": [{"op": "jam", "to": "target"}, {"op": "draw", "n": 1}]},
	{"id": "tree_supports", "name": "Tree Supports", "type": "tool", "cost": 2, "rarity": "uncommon",
		"text": "Give a friendly print +3 Health and Guard.", "target": "friendly_print",
		"effects": [{"op": "buff", "atk": 0, "hp": 3, "kw": ["guard"], "to": "target"}]},
	{"id": "bed_scraper", "name": "Bed Scraper", "type": "tool", "cost": 3, "rarity": "uncommon",
		"text": "Destroy an enemy print with 3 or less Attack.", "target": "enemy_print", "target_max_atk": 3,
		"effects": [{"op": "destroy", "to": "target"}]},
	{"id": "printed_wrench", "name": "Printed Wrench", "type": "tool", "cost": 3, "rarity": "rare",
		"text": "Deal 4 damage to an enemy print.", "target": "enemy_print",
		"effects": [{"op": "damage", "n": 4, "to": "target"}]},
	{"id": "clean_nozzle", "name": "Clean Nozzle", "type": "tool", "cost": 3, "rarity": "rare",
		"text": "Repair your Printer by 5. Draw a card.",
		"effects": [{"op": "heal", "n": 5, "to": "own_printer"}, {"op": "draw", "n": 1}]},
	{"id": "hex_keys", "name": "Hex Keys", "type": "tool", "cost": 3, "rarity": "rare",
		"text": "Give your prints +1/+1.",
		"effects": [{"op": "buff", "atk": 1, "hp": 1, "to": "friendly_prints"}]},
	{"id": "bed_leveling", "name": "Bed Leveling", "type": "tool", "cost": 4, "rarity": "rare",
		"text": "Deal 2 damage to all enemy prints.",
		"effects": [{"op": "damage", "n": 2, "to": "enemy_prints"}]},
	{"id": "gear_up", "name": "Gear Up", "type": "tool", "cost": 4, "rarity": "epic",
		"text": "Give a friendly print +2/+2 and Twin Nozzle.", "target": "friendly_print",
		"effects": [{"op": "buff", "atk": 2, "hp": 2, "kw": ["twin"], "to": "target"}]},
	{"id": "emergency_stop", "name": "Emergency Stop", "type": "tool", "cost": 6, "rarity": "epic",
		"text": "Destroy all prints.",
		"effects": [{"op": "destroy", "to": "all_prints"}]},
	{"id": "rainbow_spool", "name": "Rainbow Spool", "type": "tool", "cost": 5, "rarity": "legendary",
		"text": "Print a copy of a friendly print.", "target": "friendly_print",
		"effects": [{"op": "copy", "to": "target"}]},
	# -------------------------------------------------------------- upgrades
	{"id": "helm", "name": "Printed Helm", "type": "upgrade", "cost": 1, "rarity": "common",
		"text": "Give a friendly print +1/+2.", "target": "friendly_print", "buff": {"atk": 1, "hp": 2, "kw": []}},
	{"id": "leg_guards", "name": "Leg Guards", "type": "upgrade", "cost": 1, "rarity": "common",
		"text": "Give a friendly print +1/+1 and Rush.", "target": "friendly_print", "buff": {"atk": 1, "hp": 1, "kw": ["rush"]}},
	{"id": "chest_plate", "name": "Chest Plate", "type": "upgrade", "cost": 2, "rarity": "uncommon",
		"text": "Give a friendly print +1/+3 and Guard.", "target": "friendly_print", "buff": {"atk": 1, "hp": 3, "kw": ["guard"]}},
	{"id": "shadow_cloak", "name": "Shadow Cloak", "type": "upgrade", "cost": 2, "rarity": "rare",
		"text": "Give a friendly print +1 Attack and Brim.", "target": "friendly_print", "buff": {"atk": 1, "hp": 0, "kw": ["brim"]}},
	{"id": "full_suit", "name": "Full Suit", "type": "upgrade", "cost": 3, "rarity": "rare",
		"text": "Give a friendly print +2/+4.", "target": "friendly_print", "buff": {"atk": 2, "hp": 4, "kw": []}},
	{"id": "arcane_core", "name": "Arcane Core", "type": "upgrade", "cost": 4, "rarity": "epic",
		"text": "Give a friendly print +3/+3 and Siphon.", "target": "friendly_print", "buff": {"atk": 3, "hp": 3, "kw": ["siphon"]}},
	{"id": "titan_plate", "name": "Titan Plate", "type": "upgrade", "cost": 5, "rarity": "legendary",
		"text": "Give a friendly print +4/+6 and Guard.", "target": "friendly_print", "buff": {"atk": 4, "hp": 6, "kw": ["guard"]}},
	# ---------------------------------------------------------------- tokens
	{"id": "test_bot", "name": "Test Bot", "type": "creature", "cost": 1, "atk": 1, "hp": 1, "element": "Neutral", "rarity": "common",
		"kw": [], "text": "", "token": true},
	{"id": "filament_scrap", "name": "Filament Scrap", "type": "tool", "cost": 0, "rarity": "common",
		"text": "+1 Print Speed this turn.", "token": true,
		"effects": [{"op": "filament", "n": 1}]},
]

## Printers are the heroes. Each has one Power (costs `cost` Filament, default
## POWER_COST, once per turn) and some mod `slots`. Starter Printers have price 0.
const PRINTERS := [
	{"id": "ember_forge", "name": "Ember Forge", "element": "Fire", "price": 0, "rank": 1, "slots": 2,
		"power": {"name": "Hot Nozzle", "text": "Deal 1 damage.", "target": "enemy", "icon": "flame",
			"effects": [{"op": "damage", "n": 1, "to": "target"}]}},
	{"id": "tide_press", "name": "Tide Press", "element": "Water", "price": 0, "rank": 1, "slots": 2,
		"power": {"name": "Coolant Flush", "text": "Repair 2 damage.", "target": "friendly", "icon": "drop",
			"effects": [{"op": "heal", "n": 2, "to": "target"}]}},
	{"id": "volt_rig", "name": "Volt Rig", "element": "Lightning", "price": 0, "rank": 1, "slots": 2,
		"power": {"name": "Test Bot", "text": "Print a 1/1 Test Bot.", "target": "", "icon": "cube",
			"effects": [{"op": "summon", "card": "test_bot", "n": 1}]}},
	{"id": "stone_kiln", "name": "Stone Kiln", "element": "Stone", "price": 900, "rank": 4, "slots": 3,
		"power": {"name": "Reinforce", "text": "Your Printer gains 2 Armor.", "target": "", "icon": "shield",
			"effects": [{"op": "armor", "n": 2}]}},
	{"id": "verdant_loom", "name": "Verdant Loom", "element": "Nature", "price": 900, "rank": 4, "slots": 3,
		"power": {"name": "Regrow", "text": "Give a friendly print +1/+1.", "target": "friendly_print", "icon": "leaf",
			"effects": [{"op": "buff", "atk": 1, "hp": 1, "to": "target"}]}},
	{"id": "frost_chamber", "name": "Frost Chamber", "element": "Ice", "price": 1400, "rank": 6, "slots": 3,
		"power": {"name": "Flash Freeze", "text": "Jam an enemy print.", "target": "enemy_print", "icon": "snow",
			"effects": [{"op": "jam", "to": "target"}]}},
	{"id": "cyclone_rig", "name": "Cyclone Rig", "element": "Wind", "price": 1400, "rank": 6, "slots": 3,
		"power": {"name": "Tailwind", "text": "Give a friendly print Rush.", "target": "friendly_print", "icon": "twin",
			"effects": [{"op": "buff", "atk": 0, "hp": 0, "kw": ["rush"], "to": "target"}]}},
	{"id": "arcane_engine", "name": "Arcane Engine", "element": "Arcane", "price": 1800, "rank": 9, "slots": 3,
		"power": {"name": "Blueprint Scan", "text": "Draw a card. Your Printer takes 2 damage.", "target": "", "icon": "star",
			"effects": [{"op": "damage", "n": 2, "to": "own_printer"}, {"op": "draw", "n": 1}]}},
	{"id": "resin_vat", "name": "Resin Vat", "element": "Neutral", "price": 2200, "rank": 12, "slots": 3,
		"power": {"name": "Cure", "text": "Give a friendly print +2 Health.", "target": "friendly_print", "icon": "drop",
			"effects": [{"op": "buff", "atk": 0, "hp": 2, "to": "target"}]}},
	{"id": "delta_rig", "name": "Delta Rig", "element": "Neutral", "price": 2800, "rank": 15, "slots": 4,
		"power": {"name": "Rapid Pull", "text": "Draw a card.", "target": "", "icon": "hex", "cost": 3,
			"effects": [{"op": "draw", "n": 1}]}},
	{"id": "pellet_press", "name": "Pellet Press", "element": "Neutral", "price": 3500, "rank": 19, "slots": 4,
		"power": {"name": "Hopper Refill", "text": "Add 4 Filament to your Spool.", "target": "", "icon": "spool",
			"effects": [{"op": "spool", "n": 4}]}},
	{"id": "titan_gantry", "name": "Titan Gantry", "element": "Stone", "price": 5000, "rank": 24, "slots": 4,
		"power": {"name": "Brace", "text": "Your Printer gains 3 Armor.", "target": "", "icon": "shield", "cost": 3,
			"effects": [{"op": "armor", "n": 3}]}},
]
const STARTER_PRINTER := {"cinderpaw": "ember_forge", "aquafin": "tide_press", "voltwig": "volt_rig"}

## Printer mods. Buy a level once and it is yours; install it into a slot on
## any Printer you own. `costs[level - 1]` and `ranks[level - 1]` are what level
## `level` costs and the Maker Rank it needs. `per` says what each level adds.
const PRINTER_MODS := [
	{"id": "stepper", "name": "Stepper Motors", "icon": "burst", "text": "Prints %d more Filament each turn.", "per": 1, "costs": [1200, 3200], "ranks": [5, 15]},
	{"id": "spool", "name": "Bigger Spool", "icon": "spool", "text": "Your Spool holds %d more Filament.", "per": 5, "costs": [250, 700, 1500], "ranks": [1, 6, 14]},
	{"id": "frame", "name": "Reinforced Frame", "icon": "shield", "text": "Your Printer has %d more Health.", "per": 2, "costs": [300, 800, 1800], "ranks": [2, 8, 16]},
	{"id": "bed", "name": "Heated Bed", "icon": "flame", "text": "Your first print each battle gets +%d/+%d.", "per": 1, "costs": [350, 900, 2000], "ranks": [2, 9, 18]},
	{"id": "enclosure", "name": "Enclosure", "icon": "lock", "text": "Your Printer starts with %d Armor.", "per": 2, "costs": [500, 1300, 2800], "ranks": [4, 12, 22]},
	{"id": "sensor", "name": "Filament Sensor", "icon": "check", "text": "A shattered print returns %d more Filament to your Spool.", "per": 1, "costs": [700, 2200], "ranks": [6, 16]},
	{"id": "preheater", "name": "Pre-heater", "icon": "flame", "text": "Your first long print each battle starts %d Filament ahead.", "per": 2, "costs": [600, 1600], "ranks": [5, 13]},
	{"id": "quickstart", "name": "Quick Start", "icon": "star", "text": "Draw %d extra card on your first turn.", "per": 1, "costs": [900], "ranks": [7]},
	{"id": "slicer", "name": "Smart Slicer", "icon": "cube", "text": "A thin hand is topped up to %d cards instead of 3.", "per": 4, "costs": [1000], "ranks": [9]},
	{"id": "hot_end", "name": "All-metal Hot End", "icon": "drop", "text": "Your Printer Power costs %d less Filament.", "per": 1, "costs": [1500], "ranks": [10]},
	{"id": "mixer", "name": "Colour Mixer", "icon": "twin", "text": "Prints that match your Printer's element get +%d Attack.", "per": 1, "costs": [2600], "ranks": [20]},
	{"id": "sorter", "name": "Coin Sorter", "icon": "coin", "text": "Earn %d more Forge Coins for each win.", "per": 4, "costs": [200, 500, 1100], "ranks": [1, 5, 12]},
]
## `foil` and `foil_deep` colour the pouch, `holo` is its rainbow sheen (0-1),
## and `art` is the creature printed on the front (`art_raw`: as a bare print).
const PACKS := {
	"standard": {"name": "Blueprint Pack", "price": 150, "size": 5, "guarantee": "rare", "tint": "#3fa7ff",
		"foil": "#4aa8ff", "foil_deep": "#10307a", "holo": 0.12, "art": "cinderpaw", "art_raw": true,
		"text": "5 cards. At least one Rare or better."},
	"premium": {"name": "Golden Spool Pack", "price": 400, "size": 5, "guarantee": "epic", "tint": "#ffc93c",
		"foil": "#ffcf4d", "foil_deep": "#8a4a08", "holo": 0.7, "art": "starloom", "art_raw": false,
		"text": "5 cards. At least one Epic or better."},
}
const PACK_WEIGHTS := {"common": 580, "uncommon": 250, "rare": 120, "epic": 40, "legendary": 10}
const PACK_GUARANTEE_WEIGHTS := {
	"rare": {"rare": 780, "epic": 180, "legendary": 40},
	"epic": {"epic": 850, "legendary": 150},
}

const STARTER_COINS := 150
const STARTER_PACKS := 3
const STARTER_DECK := {
	"mossmunk": 2, "voltwig": 2, "cinderpaw": 2, "aquafin": 2, "sparkotter": 2,
	"frostling": 2, "stoneback": 2, "galehopper": 2, "heat_gun": 2, "glue_stick": 1, "calipers": 1,
}
const STARTER_EXTRA := {"glue_stick": 1, "calipers": 1, "hobby_knife": 2, "test_print": 2, "helm": 2, "leg_guards": 2}

## The guided first battle: fixed hands and draw order (top of deck first).
const TUTORIAL := {
	"coins": 50,
	"player": {"printer": "ember_forge",
		"hand": ["voltwig", "cinderpaw", "heat_gun", "mossmunk"],
		# Runestag comes second: it costs more than one turn's printing, so it
		# teaches the long print.
		"deck": ["runestag", "helm", "stoneback", "galehopper", "cinderpaw", "aquafin", "frostling", "heat_gun", "sparkotter",
			"glue_stick", "mossmunk", "voltwig", "stoneback", "galehopper", "aquafin", "calipers"]},
	"foe": {"printer": "volt_rig", "hp_bonus": -10,
		"hand": ["mossmunk", "sparkotter", "voltwig", "aquafin", "filament_scrap"],
		"deck": ["mossmunk", "aquafin", "voltwig", "sparkotter", "cinderpaw", "stoneback", "mossmunk", "aquafin",
			"voltwig", "sparkotter", "cinderpaw", "stoneback", "galehopper", "frostling", "galehopper", "frostling"]},
}

const AI_LEVELS := ["Apprentice", "Craftsman", "Master"]
## Coins and Maker XP for a battle, by AI level. Winning pays, but not a lot:
## this is a long game, and the rank gates matter as much as the coins.
const WIN_COINS := [20, 30, 45]
const LOSS_COINS := 6
const XP_WIN := [30, 45, 65]
const XP_LOSS := [10, 14, 18]
const XP_FIRST_CLEAR := 60
const XP_PVP_WIN := 50
const XP_PVP_LOSS := 20
const XP_TUTORIAL := 40
const RANK_MAX := 30
## What an unpicked starter Printer costs, and the rank it needs.
const STARTER_PRINTER_PRICE := 600
const STARTER_PRINTER_RANK := 2


## XP needed to climb from `rank` to the next rank.
static func xp_to_advance(rank: int) -> int:
	return 100 + 30 * rank


## {"rank", "into" (XP into this rank), "need" (XP for the next, 0 at the cap)} for a total XP.
static func rank_from_xp(xp: int) -> Dictionary:
	var rank := 1
	var left := maxi(xp, 0)
	while rank < RANK_MAX and left >= xp_to_advance(rank):
		left -= xp_to_advance(rank)
		rank += 1
	return {"rank": rank, "into": left, "need": xp_to_advance(rank) if rank < RANK_MAX else 0}

## Campaign rivals, fought in order. `level` indexes AI_LEVELS.
const RIVALS := [
	{"id": "pip", "name": "Apprentice Pip", "title": "First Layers", "printer": "volt_rig", "level": 0, "hp_bonus": -6, "coins": 27, "pack": "standard",
		"arena": "first_layers",
		"deck": {"mossmunk": 2, "voltwig": 2, "cinderpaw": 2, "aquafin": 2, "sparkotter": 2, "stoneback": 2, "galehopper": 2, "heat_gun": 2, "glue_stick": 2, "test_print": 2}},
	{"id": "cora", "name": "Coolant Cora", "title": "Coolant Check", "printer": "tide_press", "level": 0, "hp_bonus": -6, "coins": 32, "pack": "standard",
		"arena": "first_layers",
		"deck": {"mossmunk": 2, "aquafin": 2, "sparkotter": 2, "frostling": 2, "stoneback": 2, "coralisk": 2, "heat_gun": 2, "glue_stick": 2, "helm": 2, "calipers": 2}},
	{"id": "flint", "name": "Foreman Flint", "title": "Hot End", "printer": "ember_forge", "level": 0, "hp_bonus": -4, "coins": 36, "pack": "standard",
		"arena": "element_bench",
		"deck": {"voltwig": 2, "cinderpaw": 2, "sparkotter": 2, "galehopper": 2, "glassdrake": 2, "frostling": 2, "heat_gun": 2, "hobby_knife": 2, "leg_guards": 2, "printed_wrench": 1, "coalgriffin": 1}},
	{"id": "zed", "name": "Sparkwright Zed", "title": "Overclocked", "printer": "volt_rig", "level": 1, "hp_bonus": 2, "coins": 40, "pack": "standard",
		"arena": "element_bench",
		"deck": {"voltwig": 2, "sparkotter": 2, "cinderpaw": 2, "galehopper": 2, "thunderelk": 2, "runestag": 2, "heat_gun": 2, "hobby_knife": 1, "gear_up": 1, "leg_guards": 2, "spare_spool": 2}},
	{"id": "fern", "name": "Gardener Fern", "title": "Overgrowth", "printer": "verdant_loom", "level": 1, "hp_bonus": -2, "coins": 45, "pack": "standard",
		"arena": "reinforced_run",
		"deck": {"mossmunk": 2, "voltwig": 2, "cinderpaw": 2, "sparkotter": 2, "brambleowl": 2, "coralisk": 2, "test_print": 2, "hex_keys": 2, "glue_stick": 2, "full_suit": 1, "verdantitan": 1}},
	{"id": "brick", "name": "Mason Brick", "title": "Solid Infill", "printer": "stone_kiln", "level": 1, "hp_bonus": -8, "coins": 50, "pack": "standard",
		"arena": "reinforced_run",
		"deck": {"mossmunk": 2, "aquafin": 2, "stoneback": 2, "frostling": 2, "ironmaw": 2, "brambleowl": 2, "chest_plate": 2, "tree_supports": 2, "bed_scraper": 2, "calipers": 1, "tidewhale": 1}},
	{"id": "lyra", "name": "Runekeeper Lyra", "title": "Arcane Circuit", "printer": "arcane_engine", "level": 2, "hp_bonus": 4, "coins": 58, "pack": "standard",
		"arena": "masterwork_circuit",
		"deck": {"mossmunk": 2, "cinderpaw": 2, "sparkotter": 2, "stoneback": 2, "runestag": 2, "brambleowl": 2, "printed_wrench": 2, "bed_leveling": 1, "arcane_core": 1, "pyraxis": 1, "voidmanta": 1, "coalgriffin": 2}},
	{"id": "gale", "name": "Stormsmith Gale", "title": "Cold Front", "printer": "tide_press", "level": 1, "hp_bonus": 0, "coins": 68, "pack": "premium",
		"arena": "masterwork_circuit",
		"deck": {"mossmunk": 2, "aquafin": 2, "frostling": 2, "galehopper": 2, "coralisk": 2, "aurorawing": 2, "skyforge": 2, "cooling_fan": 2, "bed_leveling": 1, "clean_nozzle": 1, "miragefox": 1, "tidewhale": 1}},
	{"id": "atlas", "name": "Warden Atlas", "title": "Masterwork", "printer": "stone_kiln", "level": 2, "hp_bonus": -7, "coins": 80, "pack": "premium",
		"arena": "primordial_proof",
		"deck": {"mossmunk": 2, "aquafin": 2, "stoneback": 2, "frostling": 2, "ironmaw": 2, "tidewhale": 2, "chest_plate": 2, "bed_scraper": 1, "emergency_stop": 1, "titan_plate": 1, "worldcoil": 1, "verdantitan": 1, "clean_nozzle": 1}},
	{"id": "forge", "name": "Grandmaster Forge", "title": "Primordial Proof", "printer": "arcane_engine", "level": 2, "hp_bonus": 14, "coins": 135, "pack": "premium",
		"arena": "primordial_proof",
		"deck": {"voltwig": 2, "cinderpaw": 2, "sparkotter": 2, "galehopper": 2, "runestag": 2, "glassdrake": 2, "thunderelk": 1, "coalgriffin": 1, "heat_gun": 2, "printed_wrench": 1, "pyraxis": 1, "voidmanta": 1, "starloom": 1}},
]

const ARENAS := ["daily_arena", "first_layers", "element_bench", "reinforced_run", "masterwork_circuit", "primordial_proof"]

static var _index: Dictionary = {}


static func card(id: String) -> Dictionary:
	if _index.is_empty():
		for c in CARDS:
			_index[c["id"]] = c
	return _index.get(id, {})


static func has_card(id: String) -> bool:
	return not card(id).is_empty()


## Cards that can be collected and put in decks (no tokens), in display order.
static func collectible() -> Array:
	var out: Array = []
	for c in CARDS:
		if not c.get("token", false):
			out.append(c)
	out.sort_custom(func(a, b):
		if a["cost"] != b["cost"]:
			return a["cost"] < b["cost"]
		return a["name"] < b["name"])
	return out


static func printer(id: String) -> Dictionary:
	for p in PRINTERS:
		if p["id"] == id:
			return p
	return PRINTERS[0]


static func mod(id: String) -> Dictionary:
	for m in PRINTER_MODS:
		if m["id"] == id:
			return m
	return {}


static func mod_max(id: String) -> int:
	return (mod(id).get("costs", []) as Array).size()


## What a mod's level adds, as a player-facing sentence ("Your Spool holds 10 more Filament.").
static func mod_text(id: String, level: int) -> String:
	var m := mod(id)
	if m.is_empty():
		return ""
	var amount: int = int(m["per"]) * maxi(level, 1)
	var text: String = m["text"]
	if text.count("%d") == 2:
		return text % [amount, amount]
	if id == "slicer":
		return text % int(m["per"])
	return text % amount


## Slots on a Printer for mods.
static func printer_slots(printer_id: String) -> int:
	return int(printer(printer_id).get("slots", 2))


## Filament a Printer's Power costs before mods.
static func power_cost(printer_id: String) -> int:
	return int(printer(printer_id)["power"].get("cost", POWER_COST))


## A mods dictionary {mod id: level} cut down to what is allowed on a
## Printer: known mods only, levels within range, no more than the slots.
static func clean_mods(printer_id: String, mods: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for id in mods:
		if out.size() >= printer_slots(printer_id):
			break
		var level := clampi(int(mods[id]), 0, mod_max(str(id)))
		if level > 0 and not mod(str(id)).is_empty():
			out[str(id)] = level
	return out


static func rival(id: String) -> Dictionary:
	for r in RIVALS:
		if r["id"] == id:
			return r
	return {}


static func max_copies(id: String) -> int:
	return int(RARITIES[card(id).get("rarity", "common")]["copies"])


static func rarity_color(rarity: String) -> Color:
	return Color(RARITIES.get(rarity, RARITIES["common"])["color"])


static func element_color(element: String) -> Color:
	return Color(ELEMENTS.get(element, ELEMENTS["Neutral"])["color"])


static func element_dark(element: String) -> Color:
	return Color(ELEMENTS.get(element, ELEMENTS["Neutral"])["dark"])


## Expands {"id": count} into a flat list of card ids.
static func expand(counts: Dictionary) -> Array:
	var out: Array = []
	for id in counts:
		for i in int(counts[id]):
			out.append(id)
	return out


static func count_cards(list: Array) -> Dictionary:
	var out: Dictionary = {}
	for id in list:
		out[id] = int(out.get(id, 0)) + 1
	return out


## Returns "" when the list is a legal deck, else a player-facing reason.
static func deck_error(list: Array) -> String:
	if list.size() != DECK_SIZE:
		return "A deck needs exactly %d cards (this one has %d)." % [DECK_SIZE, list.size()]
	var counts := count_cards(list)
	for id in counts:
		var def := card(id)
		if def.is_empty() or def.get("token", false):
			return "This deck contains an unknown card."
		if int(counts[id]) > max_copies(id):
			return "Too many copies of %s." % def["name"]
	return ""


## Full rules text for a card, including its keywords.
static func rules_text(def: Dictionary) -> String:
	var parts: Array = []
	var kws: Array = []
	for k in def.get("kw", []):
		kws.append(KEYWORDS[k]["name"])
	if not kws.is_empty():
		parts.append("[b]%s[/b]" % ", ".join(kws))
	var text: String = def.get("text", "")
	if text != "":
		for head in ["On Print:", "Shatter:"]:
			text = text.replace(head, "[b]%s[/b]" % head)
		parts.append(text)
	return "\n".join(parts)


static func art_path(def: Dictionary) -> String:
	match def.get("type", ""):
		"creature":
			if def["id"] == "test_bot":
				return TOOL_ART % "test_bot_sprite"
			return SPRITE % def["id"]
		"upgrade":
			return ARMOR_ART % def["id"]
		_:
			return TOOL_ART % def["id"]
