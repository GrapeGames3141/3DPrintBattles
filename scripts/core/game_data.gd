class_name GameData
extends RefCounted
## Immutable catalog for 3D Print Arena.
## Everything at runtime (profiles, battle state, network messages) stores IDs only.

const VERSION := "1.0.0"

## A deck holds DECK_MIN to DECK_MAX cards. DECK_SIZE is the size the computer
## builds (and what Auto-fill tops a deck up to): the minimum.
const DECK_MIN := 20
const DECK_MAX := 60
const DECK_SIZE := DECK_MIN
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
	"common": {"name": "Common", "color": "#c3ccd9", "copies": 2},
	"uncommon": {"name": "Uncommon", "color": "#5fd47c", "copies": 2},
	"rare": {"name": "Rare", "color": "#58a6ff", "copies": 2},
	"epic": {"name": "Epic", "color": "#c47dff", "copies": 2},
	"legendary": {"name": "Legendary", "color": "#ffc93c", "copies": 1},
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
	"scorch": {"name": "Scorch", "text": "Hits Heat the print they hit. Heated prints take 1 damage each turn."},
	"thief": {"name": "Filament Thief", "text": "Hits steal 1 Attack and give +1 Health. Twice as much from Heated prints."},
	"hover": {"name": "Hover", "text": "Only prints with Hover or Reach can attack it."},
	"reach": {"name": "Reach", "text": "Can attack prints that have Hover."},
	"snap": {"name": "Snap", "text": "Any damage it deals destroys the print it hits."},
	"quick": {"name": "Quick Draw", "text": "Hits first. A print it destroys cannot hit back."},
	"overflow": {"name": "Overflow", "text": "Damage left over after destroying a print hits the enemy Printer."},
	"reprint": {"name": "Reprint", "text": "The first time it is destroyed it comes back with 1 Health."},
	"menace": {"name": "Menace", "text": "A single Guard print cannot stop it."},
	"ward": {"name": "Ward", "text": "The first tool the enemy aims at it is wasted."},
	"cloak": {"name": "Cloak", "text": "The enemy cannot aim tools at it until it attacks."},
	"triple": {"name": "Three Heads", "text": "Can attack three times each turn."},
}

const SPRITE := "res://assets/creatures/2d/%s_sprite_sheet.png"
const RAW := "res://assets/creatures/2d/raw/%s_raw_print.png"
const TOOL_ART := "res://assets/tools/%s.png"
const ARMOR_ART := "res://assets/armor/raw/%s_raw_print_alpha_v2.png"

## Effect ops: damage, heal, buff, jam, destroy, bounce, copy, draw, filament,
## spool, armor, summon, plus heat (`n` turns) and steal (`atk`, `hp`, `bonus_hp`:
## the print running the effect takes filament off the target).
## Effect targets (`to`): target, self, enemy_prints, friendly_prints,
## other_friendly_prints, all_prints, enemy_printer, own_printer.
const CARDS_BASE := [
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
	{"id": "skyforge", "name": "Skyforge", "type": "creature", "cost": 6, "atk": 5, "hp": 4, "element": "Wind", "rarity": "epic",
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
	{"id": "starloom", "name": "Starloom", "type": "creature", "cost": 9, "atk": 9, "hp": 9, "element": "Arcane", "rarity": "legendary",
		"kw": [], "text": "On Print: Give your other prints +2/+2 and Brim.",
		"on_print": [{"op": "buff", "atk": 2, "hp": 2, "kw": ["brim"], "to": "other_friendly_prints"}]},
	# ---- second wave: cousins of the first prints, in other elements
	{"id": "sparkling", "name": "Sparkling", "type": "creature", "cost": 1, "atk": 1, "hp": 1, "element": "Lightning", "rarity": "common",
		"kw": [], "text": "Shatter: +2 Print Speed this turn.",
		"shatter": [{"op": "filament", "n": 2}]},
	{"id": "rainotter", "name": "Rainotter", "type": "creature", "cost": 2, "atk": 2, "hp": 2, "element": "Water", "rarity": "common",
		"kw": [], "text": "On Print: Repair 2.", "target": "friendly",
		"on_print": [{"op": "heal", "n": 2, "to": "target"}]},
	{"id": "mosshopper", "name": "Mosshopper", "type": "creature", "cost": 2, "atk": 2, "hp": 3, "element": "Nature", "rarity": "common",
		"kw": [], "text": "On Print: Give a friendly print +1/+1.", "target": "friendly_print",
		"on_print": [{"op": "buff", "atk": 1, "hp": 1, "to": "target"}]},
	{"id": "icicle", "name": "Icicle", "type": "creature", "cost": 2, "atk": 2, "hp": 1, "element": "Ice", "rarity": "uncommon",
		"kw": [], "text": "On Print: Jam an enemy print and deal 1 damage to the enemy Printer.", "target": "enemy_print",
		"on_print": [{"op": "jam", "to": "target"}, {"op": "damage", "n": 1, "to": "enemy_printer"}]},
	{"id": "pebblefin", "name": "Pebblefin", "type": "creature", "cost": 2, "atk": 1, "hp": 5, "element": "Stone", "rarity": "uncommon",
		"kw": ["guard"], "text": ""},
	{"id": "zephyrcat", "name": "Zephyrcat", "type": "creature", "cost": 2, "atk": 2, "hp": 2, "element": "Wind", "rarity": "uncommon",
		"kw": [], "text": "On Print: Give a friendly print Rush.", "target": "friendly_print",
		"on_print": [{"op": "buff", "atk": 0, "hp": 0, "kw": ["rush"], "to": "target"}]},
	{"id": "cinderowl", "name": "Cinderowl", "type": "creature", "cost": 3, "atk": 3, "hp": 2, "element": "Fire", "rarity": "uncommon",
		"kw": [], "text": "On Print: Deal 2 damage to an enemy print.", "target": "enemy_print",
		"on_print": [{"op": "damage", "n": 2, "to": "target"}]},
	{"id": "magmaback", "name": "Magmaback", "type": "creature", "cost": 4, "atk": 3, "hp": 6, "element": "Fire", "rarity": "rare",
		"kw": ["guard"], "text": "Shatter: Deal 2 damage to the enemy Printer.",
		"shatter": [{"op": "damage", "n": 2, "to": "enemy_printer"}]},
	{"id": "stormstag", "name": "Stormstag", "type": "creature", "cost": 4, "atk": 3, "hp": 4, "element": "Lightning", "rarity": "rare",
		"kw": ["rush"], "text": "On Print: Deal 1 damage to all enemy prints.",
		"on_print": [{"op": "damage", "n": 1, "to": "enemy_prints"}]},
	{"id": "thornfox", "name": "Thornfox", "type": "creature", "cost": 4, "atk": 3, "hp": 3, "element": "Nature", "rarity": "rare",
		"kw": ["rush", "brim"], "text": ""},
	{"id": "tidemaw", "name": "Tidemaw", "type": "creature", "cost": 5, "atk": 4, "hp": 6, "element": "Water", "rarity": "epic",
		"kw": ["siphon"], "text": "Turn End: Repair your Printer by 2.",
		"trig": [{"when": "turn_end", "fx": [{"op": "heal", "n": 2, "to": "own_printer"}]}]},
	{"id": "frostelk", "name": "Frostelk", "type": "creature", "cost": 5, "atk": 4, "hp": 6, "element": "Ice", "rarity": "epic",
		"kw": ["guard"], "text": "On Print: Jam an enemy print.", "target": "enemy_print",
		"on_print": [{"op": "jam", "to": "target"}]},
	{"id": "quartzdrake", "name": "Quartzdrake", "type": "creature", "cost": 5, "atk": 4, "hp": 4, "element": "Stone", "rarity": "epic",
		"kw": [], "text": "Shatter: Deal 3 damage to all enemy prints.",
		"shatter": [{"op": "damage", "n": 3, "to": "enemy_prints"}]},
	{"id": "gustgriffin", "name": "Gustgriffin", "type": "creature", "cost": 6, "atk": 4, "hp": 5, "element": "Wind", "rarity": "epic",
		"kw": ["twin"], "text": "On Attack: Deal 1 damage to a random enemy print.",
		"trig": [{"when": "attack", "fx": [{"op": "damage", "n": 1, "to": "random_enemy"}]}]},
	{"id": "arcanitan", "name": "Arcanitan", "type": "creature", "cost": 6, "atk": 6, "hp": 6, "element": "Arcane", "rarity": "epic",
		"kw": [], "text": "On Print: Draw a card. Give your other prints +1/+1.",
		"on_print": [{"op": "draw", "n": 1}, {"op": "buff", "atk": 1, "hp": 1, "to": "other_friendly_prints"}]},
	{"id": "starwhale", "name": "Starwhale", "type": "creature", "cost": 8, "atk": 6, "hp": 10, "element": "Arcane", "rarity": "legendary",
		"kw": ["guard"], "text": "On Print: Add 8 Filament to your Spool.",
		"on_print": [{"op": "spool", "n": 8}]},
	# ----------------------------------------------------------------- tools
	{"id": "spare_spool", "name": "Spare Spool", "type": "tool", "cost": 1, "rarity": "uncommon",
		"text": "Add 3 Filament to your Spool. +2 Print Speed this turn.",
		"effects": [{"op": "spool", "n": 3}, {"op": "filament", "n": 2}]},
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
	# ---- second wave of tools
	{"id": "safety_goggles", "name": "Safety Goggles", "type": "tool", "cost": 1, "rarity": "common",
		"text": "Your Printer gains 3 Armor.",
		"effects": [{"op": "armor", "n": 3}]},
	{"id": "tweezers", "name": "Tweezers", "type": "tool", "cost": 1, "rarity": "uncommon",
		"text": "Return a friendly print to your hand.", "target": "friendly_print",
		"effects": [{"op": "bounce", "to": "target"}]},
	{"id": "soldering_iron", "name": "Soldering Iron", "type": "tool", "cost": 2, "rarity": "common",
		"text": "Deal 1 damage to all enemy prints.",
		"effects": [{"op": "damage", "n": 1, "to": "enemy_prints"}]},
	{"id": "glue_gun", "name": "Hot Glue Gun", "type": "tool", "cost": 2, "rarity": "uncommon",
		"text": "Deal 1 damage to an enemy print and Jam it.", "target": "enemy_print",
		"effects": [{"op": "damage", "n": 1, "to": "target"}, {"op": "jam", "to": "target"}]},
	{"id": "filament_dryer", "name": "Filament Dryer", "type": "tool", "cost": 2, "rarity": "uncommon",
		"text": "Add 4 Filament to your Spool. Draw a card.",
		"effects": [{"op": "spool", "n": 4}, {"op": "draw", "n": 1}]},
	{"id": "z_offset", "name": "Z-Offset", "type": "tool", "cost": 2, "rarity": "uncommon",
		"text": "Give your prints +1 Attack.",
		"effects": [{"op": "buff", "atk": 1, "hp": 0, "to": "friendly_prints"}]},
	{"id": "spaghetti", "name": "Spaghetti Failure", "type": "tool", "cost": 3, "rarity": "epic",
		"text": "Jam all enemy prints.",
		"effects": [{"op": "jam", "to": "enemy_prints"}]},
	{"id": "power_outage", "name": "Power Outage", "type": "tool", "cost": 4, "rarity": "epic",
		"text": "Destroy an enemy print. Your Printer takes 3 damage.", "target": "enemy_print",
		"effects": [{"op": "destroy", "to": "target"}, {"op": "damage", "n": 3, "to": "own_printer"}]},
	{"id": "backup_spool", "name": "Backup Spool", "type": "tool", "cost": 3, "rarity": "legendary",
		"text": "Add 12 Filament to your Spool.",
		"effects": [{"op": "spool", "n": 12}]},
	{"id": "master_blueprint", "name": "Master Blueprint", "type": "tool", "cost": 5, "rarity": "legendary",
		"text": "Draw 3 cards.",
		"effects": [{"op": "draw", "n": 3}]},
	# -------------------------------------------------------------- upgrades
	{"id": "helm", "name": "Printed Helm", "type": "upgrade", "cost": 1, "rarity": "common",
		"text": "Give a friendly print +1/+2 and Ward.", "target": "friendly_print", "buff": {"atk": 1, "hp": 2, "kw": ["ward"]}},
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
	# ---- second wave of equipment
	{"id": "spare_plating", "name": "Spare Plating", "type": "upgrade", "cost": 2, "rarity": "common",
		"text": "Give a friendly print +0/+4.", "target": "friendly_print", "buff": {"atk": 0, "hp": 4, "kw": []}},
	{"id": "spike_collar", "name": "Spiked Collar", "type": "upgrade", "cost": 2, "rarity": "uncommon",
		"text": "Give a friendly print +2/+0 and Rush.", "target": "friendly_print", "buff": {"atk": 2, "hp": 0, "kw": ["rush"]}},
	{"id": "wing_kit", "name": "Wing Kit", "type": "upgrade", "cost": 3, "rarity": "rare",
		"text": "Give a friendly print +2/+2 and Rush.", "target": "friendly_print", "buff": {"atk": 2, "hp": 2, "kw": ["rush"]}},
	{"id": "scale_mail", "name": "Scale Mail", "type": "upgrade", "cost": 4, "rarity": "epic",
		"text": "Give a friendly print +2/+5 and Guard.", "target": "friendly_print", "buff": {"atk": 2, "hp": 5, "kw": ["guard"]}},
	{"id": "jet_pack", "name": "Jet Pack", "type": "upgrade", "cost": 4, "rarity": "epic",
		"text": "Give a friendly print +2/+2, Rush and Brim.", "target": "friendly_print", "buff": {"atk": 2, "hp": 2, "kw": ["rush", "brim"]}},
	{"id": "crown", "name": "Printed Crown", "type": "upgrade", "cost": 4, "rarity": "legendary",
		"text": "Give a friendly print +3/+3 and Twin Nozzle.", "target": "friendly_print", "buff": {"atk": 3, "hp": 3, "kw": ["twin"]}},
	# ---------------------------------------------------------------- tokens
	{"id": "test_bot", "name": "Test Bot", "type": "creature", "cost": 1, "atk": 1, "hp": 1, "element": "Neutral", "rarity": "common",
		"kw": [], "text": "", "token": true},
	{"id": "filament_scrap", "name": "Filament Scrap", "type": "tool", "cost": 0, "rarity": "common",
		"text": "+1 Print Speed this turn.", "token": true,
		"effects": [{"op": "filament", "n": 1}]},
]


## Everything that can be printed: the original cards plus the generated
## catalog (tools/catalog/ writes scripts/core/catalog/).
const CARDS := CARDS_BASE + preload("res://scripts/core/catalog/catalog_creatures.gd").LIST \
	+ preload("res://scripts/core/catalog/catalog_tools.gd").LIST \
	+ preload("res://scripts/core/catalog/catalog_upgrades.gd").LIST

## Printers are the heroes. Each has one Power (costs `cost` Filament, default
## POWER_COST, once per turn) and its own look. Starter Printers have price 0.
const PRINTERS := [
	{"id": "ember_forge", "name": "Ember Forge", "element": "Fire", "price": 0, "rank": 1,
		"power": {"name": "Hot Nozzle", "text": "Deal 1 damage.", "target": "enemy", "icon": "flame",
			"effects": [{"op": "damage", "n": 1, "to": "target"}]}},
	{"id": "tide_press", "name": "Tide Press", "element": "Water", "price": 0, "rank": 1,
		"power": {"name": "Coolant Flush", "text": "Repair 2 damage.", "target": "friendly", "icon": "drop",
			"effects": [{"op": "heal", "n": 2, "to": "target"}]}},
	{"id": "volt_rig", "name": "Volt Rig", "element": "Lightning", "price": 0, "rank": 1,
		"power": {"name": "Test Bot", "text": "Print a 1/1 Test Bot.", "target": "", "icon": "cube",
			"effects": [{"op": "summon", "card": "test_bot", "n": 1}]}},
	{"id": "stone_kiln", "name": "Stone Kiln", "element": "Stone", "price": 900, "rank": 4,
		"power": {"name": "Reinforce", "text": "Your Printer gains 2 Armor.", "target": "", "icon": "shield",
			"effects": [{"op": "armor", "n": 2}]}},
	{"id": "verdant_loom", "name": "Verdant Loom", "element": "Nature", "price": 900, "rank": 4,
		"power": {"name": "Regrow", "text": "Give a friendly print +1/+1.", "target": "friendly_print", "icon": "leaf",
			"effects": [{"op": "buff", "atk": 1, "hp": 1, "to": "target"}]}},
	{"id": "frost_chamber", "name": "Frost Chamber", "element": "Ice", "price": 1400, "rank": 6,
		"power": {"name": "Flash Freeze", "text": "Jam an enemy print.", "target": "enemy_print", "icon": "snow",
			"effects": [{"op": "jam", "to": "target"}]}},
	{"id": "cyclone_rig", "name": "Cyclone Rig", "element": "Wind", "price": 1400, "rank": 6,
		"power": {"name": "Tailwind", "text": "Give a friendly print Rush.", "target": "friendly_print", "icon": "twin",
			"effects": [{"op": "buff", "atk": 0, "hp": 0, "kw": ["rush"], "to": "target"}]}},
	{"id": "arcane_engine", "name": "Arcane Engine", "element": "Arcane", "price": 1800, "rank": 9,
		"power": {"name": "Blueprint Scan", "text": "Draw a card. Your Printer takes 2 damage.", "target": "", "icon": "star",
			"effects": [{"op": "damage", "n": 2, "to": "own_printer"}, {"op": "draw", "n": 1}]}},
	{"id": "resin_vat", "name": "Resin Vat", "element": "Neutral", "price": 2200, "rank": 12,
		"power": {"name": "Cure", "text": "Give a friendly print +2 Health.", "target": "friendly_print", "icon": "drop",
			"effects": [{"op": "buff", "atk": 0, "hp": 2, "to": "target"}]}},
	{"id": "delta_rig", "name": "Delta Rig", "element": "Neutral", "price": 2800, "rank": 15,
		"power": {"name": "Rapid Pull", "text": "Draw a card.", "target": "", "icon": "hex", "cost": 3,
			"effects": [{"op": "draw", "n": 1}]}},
	{"id": "pellet_press", "name": "Pellet Press", "element": "Neutral", "price": 3500, "rank": 19,
		"power": {"name": "Hopper Refill", "text": "Add 4 Filament to your Spool.", "target": "", "icon": "spool",
			"effects": [{"op": "spool", "n": 4}]}},
	{"id": "titan_gantry", "name": "Titan Gantry", "element": "Stone", "price": 5000, "rank": 24,
		"power": {"name": "Brace", "text": "Your Printer gains 3 Armor.", "target": "", "icon": "shield", "cost": 3,
			"effects": [{"op": "armor", "n": 3}]}},
]
const STARTER_PRINTER := {"cinderpaw": "ember_forge", "aquafin": "tide_press", "voltwig": "volt_rig"}

## Printer mods. Each copy you buy fits one Printer at a time (move it whenever
## you like), a Printer carries one copy of each mod, and a copy can be upgraded
## (MOD_LEVELS). `cost` and `rank` are the coins and Maker Rank to buy it, `per`
## is what it adds at level 1, and `requires` (in the generated mods) lists mods
## a Printer must also carry for it to work.
const PRINTER_MODS_BASE := [
	{"id": "stepper", "rarity": "rare", "name": "Stepper Motors", "icon": "burst", "text": "Prints %d more Filament each turn.", "per": 1, "cost": 1200, "rank": 5},
	{"id": "spool", "rarity": "common", "name": "Bigger Spool", "icon": "spool", "text": "Your Spool holds %d more Filament.", "per": 5, "cost": 250, "rank": 1},
	{"id": "frame", "rarity": "common", "name": "Reinforced Frame", "icon": "shield", "text": "Your Printer has %d more Health.", "per": 2, "cost": 300, "rank": 2},
	{"id": "bed", "rarity": "uncommon", "name": "Heated Bed", "icon": "flame", "text": "Your first print each battle gets +%d/+%d.", "per": 1, "cost": 350, "rank": 2},
	{"id": "enclosure", "rarity": "uncommon", "name": "Enclosure", "icon": "lock", "text": "Your Printer starts with %d Armor.", "per": 2, "cost": 500, "rank": 4},
	{"id": "sensor", "rarity": "rare", "name": "Filament Sensor", "icon": "check", "text": "A shattered print returns %d more Filament to your Spool.", "per": 1, "cost": 700, "rank": 6},
	{"id": "preheater", "rarity": "uncommon", "name": "Pre-heater", "icon": "flame", "text": "Your first long print each battle starts %d Filament ahead.", "per": 2, "cost": 600, "rank": 5},
	{"id": "quickstart", "rarity": "rare", "name": "Quick Start", "icon": "star", "text": "Draw %d extra card on your first turn.", "per": 1, "cost": 900, "rank": 7},
	{"id": "slicer", "rarity": "rare", "name": "Smart Slicer", "icon": "cube", "text": "A thin hand is topped up to %d cards instead of 3.", "per": 4, "cost": 1000, "rank": 9},
	{"id": "hot_end", "rarity": "uncommon", "name": "All-metal Hot End", "icon": "drop", "text": "Your Printer Power costs %d less Filament.", "per": 1, "cost": 1500, "rank": 10},
	{"id": "mixer", "rarity": "rare", "name": "Colour Mixer", "icon": "twin", "text": "Prints that match your Printer's element get +%d Attack.", "per": 1, "cost": 2600, "rank": 20},
	{"id": "sorter", "rarity": "common", "name": "Coin Sorter", "icon": "coin", "text": "Earn %d more Forge Coins for each win.", "per": 4, "cost": 200, "rank": 1},
]
const PRINTER_MODS := PRINTER_MODS_BASE + preload("res://scripts/core/catalog/catalog_printer_mods.gd").LIST
## Three packs. `weights` is the chance of each rarity for every card in the pack
## (parts out of their total); a pack with a `guarantee` swaps its last card for
## one from `guarantee_weights` when nothing at that rarity or better came up.
## Every pack can give a good card; the better packs just do it far more often.
## `foil` and `foil_deep` colour the pouch, `holo` is its rainbow sheen (0-1),
## and `art` is the creature printed on the front (`art_raw`: as a bare print).
const PACKS := {
	"basic": {"name": "Basic Pack", "price": 100, "size": 5, "guarantee": "", "tint": "#8fbf9f",
		"foil": "#7fb894", "foil_deep": "#1d3a2b", "holo": 0.0, "art": "mossmunk", "art_raw": true,
		"weights": {"common": 8200, "uncommon": 1500, "rare": 270, "epic": 28, "legendary": 2},
		"guarantee_weights": {},
		"text": "5 cards, nearly all Common. A small chance of better."},
	"standard": {"name": "Blueprint Pack", "price": 250, "size": 5, "guarantee": "uncommon", "tint": "#3fa7ff",
		"foil": "#4aa8ff", "foil_deep": "#10307a", "holo": 0.12, "art": "cinderpaw", "art_raw": true,
		"weights": {"common": 5500, "uncommon": 3000, "rare": 1200, "epic": 260, "legendary": 40},
		"guarantee_weights": {"uncommon": 7000, "rare": 2500, "epic": 450, "legendary": 50},
		"text": "5 cards. At least one Uncommon or better."},
	"premium": {"name": "Golden Spool Pack", "price": 800, "size": 5, "guarantee": "epic", "tint": "#ffc93c",
		"foil": "#ffcf4d", "foil_deep": "#8a4a08", "holo": 0.7, "art": "starloom", "art_raw": false,
		"weights": {"common": 2500, "uncommon": 3500, "rare": 3000, "epic": 850, "legendary": 150},
		"guarantee_weights": {"epic": 850, "legendary": 150},
		"text": "5 cards. At least one Epic or better, and Rares are common."},
}
const PACK_ORDER := ["basic", "standard", "premium"]
## Rarity weights for Mod Crates and other random draws.
const PACK_WEIGHTS := {"common": 580, "uncommon": 250, "rare": 120, "epic": 40, "legendary": 10}

## Random mods: a Mod Crate in the Workshop, and a chance of finding one after a win.
## What you get is random, weighted by rarity (PACK_WEIGHTS).
const MOD_CRATE_PRICE := 350
const MOD_FIND_CHANCE := 0.12
const STARTER_COINS := 150
## A new player starts with no cards, only these Basic Packs (about 100 cards).
const STARTER_PACKS := 20
const STARTER_PACK_KIND := "basic"
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

## ------------------------------------------------------------- Blueprints
## Every card you own has a Blueprint: a level (1 to 3), one mod from level 2 (a
## second from level 3), and a paint. Every copy of the card in a battle has them.
const MAX_TIER := 3
## Coins to reach level 2 by rarity (level 3 costs 2.5x). Nothing else is spent.
const TIER_COINS := {"common": 60, "uncommon": 100, "rare": 180, "epic": 320, "legendary": 600}
## Maker Rank needed to reach tier 1, 2, 3 (index = tier).
const TIER_RANK := [0, 1, 3, 10]

## `kinds` are the card types a mod fits. A mod trades something for something.
const CARD_MODS_BASE := [
	{"id": "sharp_nozzle", "rarity": "uncommon", "name": "Sharp Nozzle", "icon": "burst", "kinds": ["creature"], "text": "+2 Attack, -1 Health.", "cost": 400, "rank": 4},
	{"id": "infill", "rarity": "uncommon", "name": "Extra Infill", "icon": "hex", "kinds": ["creature"], "text": "+3 Health, costs 1 more.", "cost": 400, "rank": 4},
	{"id": "draft_mode", "rarity": "uncommon", "name": "Draft Mode", "icon": "cube", "kinds": ["creature"], "text": "Costs 1 less, -1 Attack.", "cost": 700, "rank": 6},
	{"id": "supports", "rarity": "uncommon", "name": "Support Material", "icon": "shield", "kinds": ["creature"], "text": "Gains Guard, -1 Attack.", "cost": 500, "rank": 5},
	{"id": "rapid_layers", "rarity": "uncommon", "name": "Rapid Layers", "icon": "twin", "kinds": ["creature"], "text": "Gains Rush, -1 Health.", "cost": 600, "rank": 6},
	{"id": "brim_coat", "rarity": "rare", "name": "Brim Coat", "icon": "burst", "kinds": ["creature"], "text": "Gains Brim, costs 1 more.", "cost": 900, "rank": 9},
	{"id": "siphon_core", "rarity": "rare", "name": "Siphon Core", "icon": "drop", "kinds": ["creature"], "text": "Gains Siphon, costs 1 more.", "cost": 900, "rank": 9},
	{"id": "overclock", "rarity": "uncommon", "name": "Overclock", "icon": "flame", "kinds": ["creature"], "text": "+2 Attack, costs 1 more.", "cost": 700, "rank": 7},
	{"id": "recycler", "rarity": "rare", "name": "Recycler", "icon": "spool", "kinds": ["creature"], "text": "Shatter: +2 Filament on your Spool.", "cost": 800, "rank": 8},
	{"id": "overcharge", "rarity": "uncommon", "name": "Overcharge", "icon": "flame", "kinds": ["tool", "upgrade"], "text": "Its effect is 1 stronger, costs 1 more.", "cost": 600, "rank": 5},
	{"id": "lean_print", "rarity": "uncommon", "name": "Lean Print", "icon": "cube", "kinds": ["tool", "upgrade"], "text": "Costs 1 less, its effect is 1 weaker.", "cost": 600, "rank": 5},
	{"id": "quick_draw", "rarity": "epic", "name": "Quick Draw", "icon": "star", "kinds": ["creature", "tool", "upgrade"], "text": "Draw a card when used, costs 1 more.", "cost": 1000, "rank": 10},
	{"id": "reclaim", "rarity": "rare", "name": "Reclaim", "icon": "check", "kinds": ["creature", "tool", "upgrade"], "text": "Add 2 Filament to your Spool when used, costs 1 more.", "cost": 800, "rank": 8},
]
const CARD_MODS := CARD_MODS_BASE + preload("res://scripts/core/catalog/catalog_card_mods.gd").LIST

## Paints recolour a card's art, and the print on the bench. hue is a turn in degrees.
const PAINTS := [
	{"id": "original", "name": "Original", "hue": 0.0, "sat": 1.0, "val": 1.0, "price": 0, "rank": 1},
	{"id": "sky", "name": "Sky", "hue": 200.0, "sat": 1.0, "val": 1.0, "price": 0, "rank": 1},
	{"id": "rose", "name": "Rose", "hue": 320.0, "sat": 1.0, "val": 1.0, "price": 0, "rank": 1},
	{"id": "lime", "name": "Lime", "hue": 95.0, "sat": 1.05, "val": 1.0, "price": 0, "rank": 1},
	{"id": "amber", "name": "Amber", "hue": 38.0, "sat": 1.1, "val": 1.05, "price": 150, "rank": 3},
	{"id": "teal", "name": "Teal", "hue": 165.0, "sat": 1.0, "val": 1.0, "price": 150, "rank": 3},
	{"id": "violet", "name": "Violet", "hue": 265.0, "sat": 1.0, "val": 1.0, "price": 150, "rank": 3},
	{"id": "ghost", "name": "Ghost", "hue": 0.0, "sat": 0.12, "val": 1.15, "price": 300, "rank": 6},
	{"id": "midnight", "name": "Midnight", "hue": 230.0, "sat": 1.2, "val": 0.6, "price": 300, "rank": 6},
	{"id": "gold", "name": "Gold", "hue": 45.0, "sat": 1.35, "val": 1.2, "price": 600, "rank": 12},
]

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


## Total XP at which `rank` begins (rank 1 starts at 0).
static func xp_for_rank(rank: int) -> int:
	var total := 0
	for r in range(1, clampi(rank, 1, RANK_MAX)):
		total += xp_to_advance(r)
	return total


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
	{"id": "pip", "name": "Apprentice Pip", "title": "First Layers", "printer": "volt_rig", "level": 0, "tier": 1, "hp_bonus": -6, "coins": 27, "pack": "standard",
		"arena": "first_layers",
		"deck": {"mossmunk": 2, "voltwig": 2, "cinderpaw": 2, "aquafin": 2, "sparkotter": 2, "stoneback": 2, "galehopper": 2, "heat_gun": 2, "glue_stick": 2, "test_print": 2}},
	{"id": "cora", "name": "Coolant Cora", "title": "Coolant Check", "printer": "tide_press", "level": 0, "tier": 1, "hp_bonus": -6, "coins": 32, "pack": "standard",
		"arena": "hobby_shelf",
		"deck": {"mossmunk": 2, "aquafin": 2, "sparkotter": 2, "frostling": 2, "stoneback": 2, "coralisk": 2, "heat_gun": 2, "rainotter": 2, "helm": 2, "calipers": 2}},
	{"id": "flint", "name": "Foreman Flint", "title": "Hot End", "printer": "ember_forge", "level": 0, "tier": 1, "hp_bonus": -4, "coins": 36, "pack": "standard",
		"arena": "element_bench",
		"deck": {"voltwig": 2, "cinderpaw": 2, "sparkotter": 2, "galehopper": 2, "slagrhino": 2, "cinderowl": 2, "heat_gun": 2, "hobby_knife": 2, "leg_guards": 2, "printed_wrench": 1, "thermochameleon": 1}},
	{"id": "zed", "name": "Sparkwright Zed", "title": "Overclocked", "printer": "volt_rig", "level": 1, "tier": 1, "hp_bonus": 2, "coins": 40, "pack": "standard",
		"arena": "element_bench",
		"deck": {"voltwig": 2, "sparkotter": 2, "cinderpaw": 2, "galehopper": 2, "voltviper": 1, "arcflicker": 1, "runestag": 2, "heat_gun": 2, "hobby_knife": 1, "gear_up": 1, "zapkit": 2, "spare_spool": 2}},
	{"id": "fern", "name": "Gardener Fern", "title": "Overgrowth", "printer": "verdant_loom", "level": 1, "tier": 1, "hp_bonus": -2, "coins": 45, "pack": "standard",
		"arena": "reinforced_run",
		"deck": {"mossmunk": 2, "voltwig": 2, "cinderpaw": 2, "sparkotter": 2, "brambleowl": 2, "coralisk": 2, "vinehare": 2, "hex_keys": 2, "glue_stick": 2, "full_suit": 1, "nautilark": 1}},
	{"id": "brick", "name": "Mason Brick", "title": "Solid Infill", "printer": "stone_kiln", "level": 1, "tier": 2, "hp_bonus": -8, "coins": 50, "pack": "standard",
		"arena": "reinforced_run",
		"deck": {"mossmunk": 2, "aquafin": 2, "stoneback": 2, "frostling": 2, "ironmaw": 2, "brambleowl": 2, "chest_plate": 2, "pebblefin": 2, "bed_scraper": 2, "calipers": 1, "tidewhale": 1}},
	{"id": "lyra", "name": "Runekeeper Lyra", "title": "Arcane Circuit", "printer": "arcane_engine", "level": 2, "tier": 2, "hp_bonus": 4, "coins": 58, "pack": "standard",
		"arena": "masterwork_circuit",
		"deck": {"mossmunk": 2, "cinderpaw": 2, "sparkotter": 2, "stoneback": 2, "hexstag": 2, "brambleowl": 2, "printed_wrench": 2, "spaghetti": 1, "arcane_core": 1, "pyraxis": 1, "oracledrake": 1, "coalgriffin": 2}},
	{"id": "gale", "name": "Stormsmith Gale", "title": "Cold Front", "printer": "tide_press", "level": 1, "tier": 2, "hp_bonus": 0, "coins": 68, "pack": "premium",
		"arena": "masterwork_circuit",
		"deck": {"mossmunk": 2, "aquafin": 2, "frostling": 2, "galehopper": 2, "coralisk": 2, "aurorawing": 2, "skyforge": 2, "icehare": 2, "bed_leveling": 1, "clean_nozzle": 1, "tempestlynx": 1, "tidewhale": 1}},
	{"id": "atlas", "name": "Warden Atlas", "title": "Masterwork", "printer": "stone_kiln", "level": 2, "tier": 3, "hp_bonus": -7, "coins": 80, "pack": "premium",
		"arena": "primordial_proof",
		"deck": {"mossmunk": 2, "aquafin": 2, "stoneback": 2, "frostling": 2, "cairncrab": 2, "tidewhale": 2, "scale_mail": 2, "bed_scraper": 1, "emergency_stop": 1, "titan_plate": 1, "mountainwyrm": 1, "verdantitan": 1, "clean_nozzle": 1}},
	{"id": "forge", "name": "Grandmaster Forge", "title": "Primordial Proof", "printer": "arcane_engine", "level": 2, "tier": 3, "hp_bonus": 14, "coins": 135, "pack": "premium",
		"arena": "primordial_proof",
		"deck": {"voltwig": 2, "cinderpaw": 2, "sparkotter": 2, "galehopper": 2, "runestag": 2, "crystalscorp": 1, "gearspider": 1, "thunderelk": 1, "coalgriffin": 1, "arcanitan": 1, "z_offset": 1, "printed_wrench": 1, "cinderwyrm": 1, "voidmanta": 1, "starloom": 1}},
]

const ARENAS := ["daily_arena", "first_layers", "hobby_shelf", "element_bench", "reinforced_run", "masterwork_circuit", "primordial_proof"]

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


## Mods a Printer must carry for this one to work.
static func mod_requires(id: String) -> Array:
	return mod(id).get("requires", [])


## Mods that stop working when this one is taken off.
static func mod_dependents(id: String) -> Array:
	var out: Array = []
	for m in PRINTER_MODS:
		if (m.get("requires", []) as Array).has(id):
			out.append(str(m["id"]))
	return out


## Upgrade levels: [highest level, what each extra level adds]. A mod starts at
## level 1 (its `per`), and each upgrade adds `step` more. An effect that is
## all-or-nothing (a keyword, a once-a-turn draw) has one level only.
const MOD_LEVELS := {
	"stepper": [4, 1], "dual_extruder": [2, 1], "direct_drive": [2, 1], "spool": [5, 5], "frame": [4, 2], "bed": [3, 1],
	"enclosure": [4, 2], "sensor": [2, 1], "preheater": [3, 2], "quickstart": [2, 1], "slicer": [3, 1], "hot_end": [2, 1],
	"mixer": [2, 1], "sorter": [5, 4], "cooling_duct": [3, 1], "self_cleaning": [3, 1], "spool_feeder": [3, 1],
	"capacitor_bank": [2, 2], "scrap_chute": [1, 0], "quick_release": [1, 0], "failsafe": [3, 3], "plating": [2, 1],
	"thermal_mass": [2, 1], "prehensile_gantry": [2, 1], "quantum_slicer": [1, 0], "spool_rack": [3, 5], "twin_feed": [2, 1],
	"titanium_frame": [3, 2], "armor_panels": [3, 2], "auto_leveler": [2, 1], "runout_sensor": [2, 1], "preheat_chamber": [2, 2],
	"liquid_hot_end": [2, 1], "overdrive_board": [2, 2], "auto_sorter": [4, 3], "guard_frame": [3, 1], "overflow_hopper": [1, 0],
	"tool_beacon": [3, 1], "rush_springs": [2, 1], "salvage_arm": [3, 1], "twin_gantry": [2, 1],
}
## Upgrades are meant to be a long climb: level L to L+1 costs the mod's price
## times L in coins, and needs this many more Maker Ranks per level.
const MOD_UPGRADE_RANKS_PER_LEVEL := 3
## Points a level of a mod counts for in a Printer's Tune, by rarity.
const MOD_TUNE_POINTS := {"common": 1, "uncommon": 2, "rare": 3, "epic": 5, "legendary": 8}


static func mod_max_level(id: String) -> int:
	return int((MOD_LEVELS.get(id, [1, 0]) as Array)[0])


## What the mod does at `level` (clamped to what it can reach).
static func mod_effect(id: String, level: int) -> int:
	var m := mod(id)
	if m.is_empty():
		return 0
	var lv := clampi(level, 1, mod_max_level(id))
	return int(m["per"]) + (lv - 1) * int((MOD_LEVELS.get(id, [1, 0]) as Array)[1])


## Coins to take a mod from `level` to the next one, or 0 at the top.
static func mod_upgrade_cost(id: String, level: int) -> int:
	if level >= mod_max_level(id):
		return 0
	return int(mod(id)["cost"]) * level


## Maker Rank needed for that upgrade.
static func mod_upgrade_rank(id: String, level: int) -> int:
	return mini(RANK_MAX, int(mod(id)["rank"]) + MOD_UPGRADE_RANKS_PER_LEVEL * level)


## What a mod does, as a player-facing sentence ("Your Spool holds 5 more Filament.").
static func mod_text(id: String, level := 1) -> String:
	var m := mod(id)
	if m.is_empty():
		return ""
	var text: String = m["text"]
	var per := mod_effect(id, level)
	var n := text.count("%d")
	if n == 0:
		return text
	if n == 2:
		return text % [per, per]
	return text % per


## A mods dictionary ({mod id: level}) as one number for how strong a Printer is.
## Ranked play shows it and builds the computer opponent to match it.
static func tune(mods: Dictionary) -> int:
	var total := 0
	for id in mods:
		var m := mod(str(id))
		if not m.is_empty():
			total += int(MOD_TUNE_POINTS[m["rarity"]]) * clampi(int(mods[id]), 1, mod_max_level(str(id)))
	return total


## What a mod gives in a battle: its effect at the level the Printer carries it, else 0.
static func mv(mods: Dictionary, id: String) -> int:
	return mod_effect(id, int(mods[id])) if mods.has(id) else 0


## The names of the mods that are missing for a mod to work, from a list of
## mod ids a Printer carries.
static func missing_requirements(id: String, carried: Array) -> Array:
	var out: Array = []
	for r in mod_requires(id):
		if not carried.has(r):
			out.append(str(mod(str(r)).get("name", r)))
	return out


## A mods dictionary cut down to what works on a Printer: known mods only (one
## each, with the level held to what the mod can reach), and nothing whose
## required mods are missing.
static func clean_mods(_printer_id: String, mods: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for id in mods:
		if int(mods[id]) > 0 and not mod(str(id)).is_empty():
			out[str(id)] = clampi(int(mods[id]), 1, mod_max_level(str(id)))
	var changed := true
	while changed:
		changed = false
		for id in out.keys():
			for r in mod_requires(str(id)):
				if not out.has(r):
					out.erase(id)
					changed = true
					break
	return out


## Filament a Printer's Power costs before mods.
static func power_cost(printer_id: String) -> int:
	return int(printer(printer_id)["power"].get("cost", POWER_COST))


static func rival(id: String) -> Dictionary:
	for r in RIVALS:
		if r["id"] == id:
			return r
	return {}


## The Forbidden Printer: hold all five of these parts in your hand to win.
const FORBIDDEN_PARTS := ["fp_left_rail", "fp_right_rail", "fp_hot_end", "fp_frame", "fp_mainboard"]

## Coins a spare copy (one a deck cannot use) is worth when it is recycled.
const RECYCLE_COINS := {"common": 5, "uncommon": 10, "rare": 18, "epic": 30, "legendary": 50}


static func recycle_value(id: String) -> int:
	return int(RECYCLE_COINS.get(card(id).get("rarity", "common"), 5))


## The most copies of one card a single deck can hold. You may own more; the
## rest are spares.
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
	if list.size() < DECK_MIN:
		return "A deck needs at least %d cards (this one has %d)." % [DECK_MIN, list.size()]
	if list.size() > DECK_MAX:
		return "A deck holds at most %d cards (this one has %d)." % [DECK_MAX, list.size()]
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


# ------------------------------------------------------------- Blueprints

static var _built: Dictionary = {}


static func card_mod(id: String) -> Dictionary:
	for m in CARD_MODS:
		if m["id"] == id:
			return m
	return {}


static func paint(id: String) -> Dictionary:
	for p in PAINTS:
		if p["id"] == id:
			return p
	return PAINTS[0]


## A Blueprint of one tier for every card in a deck: how the campaign rivals
## keep up with a player who has been building up their cards.
static func uniform_builds(deck: Array, tier: int) -> Dictionary:
	var out: Dictionary = {}
	if tier > 1:
		for id in deck:
			out[str(id)] = {"tier": tier, "mod": "", "mod2": "", "paint": "original"}
	return out


static func default_build() -> Dictionary:
	return {"tier": 1, "mod": "", "mod2": "", "paint": "original"}


static func tier_coins(id: String, tier: int) -> int:
	var base: int = int(TIER_COINS[card(id).get("rarity", "common")])
	return base if tier <= 2 else base * 5 / 2


## The first effect that scales with tier: where it is, or {} (draws, jams, destroys and copies do not).
static func _strength(d: Dictionary) -> Dictionary:
	if d["type"] == "upgrade":
		if int(d["buff"]["atk"]) <= 0 and int(d["buff"]["hp"]) <= 0:
			return {}
		return {"list": "", "key": "atk" if int(d["buff"]["atk"]) > 0 else "hp"}
	for op in ["damage", "heal", "armor", "buff", "spool", "summon"]:
		var list: Array = d.get("effects", [])
		for i in list.size():
			# Effects that scale ("for each ...") get cheaper instead: their
			# number is per thing counted, which a bigger number would misstate.
			if list[i].has("per"):
				continue
			if list[i]["op"] == op and list[i].get("to", "") != "own_printer" and int(list[i].get("atk", 1)) >= 0:
				var key := "n"
				if op == "buff":
					key = "atk" if int(list[i].get("atk", 0)) > 0 else "hp"
				return {"list": "effects", "i": i, "key": key}
	return {}


const _WORDS := ["zero", "one", "two", "three", "four", "five", "six", "seven"]


## Changes the first number in a card's rules text from `old` to `new`.
static func _renumber(text: String, old: int, new: int) -> String:
	var rx := RegEx.new()
	rx.compile("(?<![0-9])%d(?![0-9])" % old)
	var m := rx.search(text)
	if m != null:
		return text.substr(0, m.get_start()) + str(new) + text.substr(m.get_end())
	if old < _WORDS.size() and new < _WORDS.size():
		var at := text.find(_WORDS[old])
		if at >= 0:
			return text.substr(0, at) + _WORDS[new] + text.substr(at + _WORDS[old].length())
	return text


static func _bump(d: Dictionary, slot: Dictionary, by: int) -> void:
	var holder: Dictionary = d["buff"] if slot["list"] == "" else (d["effects"] as Array)[int(slot["i"])]
	var old: int = int(holder.get(slot["key"], 0))
	var new: int = maxi(old + by, 1 if by < 0 else 0)
	holder[slot["key"]] = new
	d["text"] = _renumber(str(d["text"]), old, new)


static func _cost_by(d: Dictionary, by: int) -> void:
	var c: int = int(d["cost"])
	if by < 0:
		d["cost"] = c if c <= 1 else maxi(c + by, 1)
	else:
		d["cost"] = c + by


static func _add_text(d: Dictionary, line: String) -> void:
	d["text"] = (str(d.get("text", "")) + " " + line).strip_edges()


static func _add_effect(d: Dictionary, effect: Dictionary, line: String) -> void:
	var key := "on_print" if d["type"] == "creature" else "effects"
	var list: Array = d.get(key, [])
	list.append(effect)
	d[key] = list
	_add_text(d, line)


## True when `mod_id` can go on this card (right kind, and it would actually do something).
## `current` is the card as it stands with other mods already on it (a second
## mod has to fit what the first one made of the card); empty means the base card.
static func mod_fits(mod_id: String, id: String, current := {}) -> bool:
	var m := card_mod(mod_id)
	var d := card(id) if current.is_empty() else current
	if m.is_empty() or d.is_empty() or d.get("token", false) or not (m["kinds"] as Array).has(d["type"]):
		return false
	var kw: Array = d.get("kw", [])
	match mod_id:
		"draft_mode", "lean_print":
			return int(d["cost"]) >= 2 and (mod_id == "draft_mode" or not _strength(d).is_empty())
		"overcharge":
			return not _strength(d).is_empty()
		"supports":
			return not kw.has("guard")
		"rapid_layers":
			return not kw.has("rush")
		"brim_coat":
			return not kw.has("brim")
		"siphon_core":
			return not kw.has("siphon")
		"potent_mix":
			return not _strength(d).is_empty()
		"bulk_discount":
			return int(d["cost"]) >= 2
	# Data-driven mods: keywords it would add must not all be there already,
	# a cheaper card needs room to get cheaper, and stats stay above zero.
	var adds: Array = m.get("kw", [])
	if not adds.is_empty():
		var all_there := true
		for k in adds:
			if not kw.has(k):
				all_there = false
		if all_there:
			return false
	if int(m.get("dcost", 0)) < 0 and int(d["cost"]) < 2:
		return false
	if d["type"] == "creature":
		if int(d["hp"]) + int(m.get("hp", 0)) < 1 or int(d["atk"]) + int(m.get("atk", 0)) < 0:
			return false
	return true


static func _apply_mod(d: Dictionary, mod_id: String) -> void:
	match mod_id:
		"sharp_nozzle":
			d["atk"] = int(d["atk"]) + 2
			d["hp"] = maxi(int(d["hp"]) - 1, 1)
		"infill":
			d["hp"] = int(d["hp"]) + 3
			_cost_by(d, 1)
		"draft_mode":
			_cost_by(d, -1)
			d["atk"] = maxi(int(d["atk"]) - 1, 0)
		"supports":
			d["kw"] = (d.get("kw", []) as Array) + ["guard"]
			d["atk"] = maxi(int(d["atk"]) - 1, 0)
		"rapid_layers":
			d["kw"] = (d.get("kw", []) as Array) + ["rush"]
			d["hp"] = maxi(int(d["hp"]) - 1, 1)
		"brim_coat":
			d["kw"] = (d.get("kw", []) as Array) + ["brim"]
			_cost_by(d, 1)
		"siphon_core":
			d["kw"] = (d.get("kw", []) as Array) + ["siphon"]
			_cost_by(d, 1)
		"overclock":
			d["atk"] = int(d["atk"]) + 2
			_cost_by(d, 1)
		"recycler":
			var list: Array = d.get("shatter", [])
			list.append({"op": "spool", "n": 2})
			d["shatter"] = list
			_add_text(d, "Shatter: +2 Filament on your Spool.")
		"overcharge":
			_bump(d, _strength(d), 1)
			_cost_by(d, 1)
		"lean_print":
			_cost_by(d, -1)
			_bump(d, _strength(d), -1)
		"quick_draw":
			_add_effect(d, {"op": "draw", "n": 1}, "Also draw a card." if d["type"] != "creature" else "On Print: Draw a card.")
			_cost_by(d, 1)
		"reclaim":
			_add_effect(d, {"op": "spool", "n": 2}, "Also add 2 Filament to your Spool." if d["type"] != "creature" else "On Print: +2 Filament on your Spool.")
			_cost_by(d, 1)
		"potent_mix":
			_bump(d, _strength(d), 2)
			_cost_by(d, 2)
		_:
			_apply_data_mod(d, card_mod(mod_id))


## A mod described by its data: atk/hp/dcost changes, keywords, effects that run
## when the card is used (fx_on) and Shatter effects (fx_sh, creatures only).
static func _apply_data_mod(d: Dictionary, m: Dictionary) -> void:
	if d["type"] == "creature":
		d["atk"] = maxi(int(d["atk"]) + int(m.get("atk", 0)), 0)
		d["hp"] = maxi(int(d["hp"]) + int(m.get("hp", 0)), 1)
		var kw: Array = (d.get("kw", []) as Array).duplicate()
		for k in m.get("kw", []):
			if not kw.has(k):
				kw.append(k)
		d["kw"] = kw
	var fx: Array = m.get("fx_on", [])
	if not fx.is_empty():
		var key := "on_print" if d["type"] == "creature" else "effects"
		var list: Array = d.get(key, [])
		list.append_array(fx)
		d[key] = list
		_add_text(d, str(m.get("line_on", "")) if d["type"] != "creature" else "On Print: " + str(m.get("line_on", "")))
	var sh: Array = m.get("fx_sh", [])
	if not sh.is_empty() and d["type"] == "creature":
		var slist: Array = d.get("shatter", [])
		slist.append_array(sh)
		d["shatter"] = slist
		_add_text(d, "Shatter: " + str(m.get("line_sh", "")))
	if int(m.get("dcost", 0)) != 0:
		_cost_by(d, int(m["dcost"]))


## How many mods a card at this tier carries: one from level 2, two at level 3.
static func mod_slots(tier: int) -> int:
	return clampi(tier - 1, 0, 2)


## The card with its tier bonus and then each mod applied in turn. Returns the
## card and the mods that actually went on: each must fit the card as the mods
## before it left it, and a mod can only be fitted once.
static func _assemble(id: String, tier: int, mods: Array) -> Array:
	var d: Dictionary = card(id).duplicate(true)
	if d["type"] == "creature":
		if tier >= 2:
			d["atk"] = int(d["atk"]) + 1
		if tier >= 3:
			d["hp"] = int(d["hp"]) + 1
	elif tier >= 2:
		var slot := _strength(d)
		if slot.is_empty():
			_cost_by(d, -1)
		else:
			_bump(d, slot, 1)
		if tier >= 3:
			if int(d["cost"]) > 1 or slot.is_empty():
				_cost_by(d, -1)
			else:
				_bump(d, slot, 1)
	var applied: Array = []
	for m in mods:
		var mod_id := str(m)
		if applied.size() >= mod_slots(tier) or mod_id == "" or applied.has(mod_id):
			continue
		if mod_fits(mod_id, id, d):
			_apply_mod(d, mod_id)
			applied.append(mod_id)
	return [d, applied]


## The mods of a Blueprint that really apply, in order.
static func fitted_mods(id: String, tier: int, mods: Array) -> Array:
	if card(id).is_empty():
		return []
	return _assemble(id, clampi(tier, 1, MAX_TIER), mods)[1]


## The card as it is actually printed: the base card with its Blueprint applied.
## Results are shared, so treat them as read-only.
static func built(id: String, build: Dictionary) -> Dictionary:
	var base := card(id)
	var tier := clampi(int(build.get("tier", 1)), 1, MAX_TIER)
	var wanted: Array = [str(build.get("mod", "")), str(build.get("mod2", ""))] if tier >= 2 else []
	if base.is_empty() or (tier == 1 and wanted.is_empty()):
		return base
	var key := "%s|%d|%s" % [id, tier, "|".join(wanted)]
	if _built.has(key):
		return _built[key]
	var made := _assemble(id, tier, wanted)
	var d: Dictionary = made[0]
	var applied: Array = made[1]
	d["mk"] = tier
	d["mod"] = applied[0] if applied.size() > 0 else ""
	d["mod2"] = applied[1] if applied.size() > 1 else ""
	_built[key] = d
	return d


## Builds cut down to what the deck can carry and the rules allow: only cards
## in the deck, tier 1-3, mods only from level 2 (a second from level 3) and only
## ones that fit, a real paint.
static func clean_builds(deck: Array, builds: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for id in deck:
		if out.has(id) or not builds.get(id) is Dictionary or card(str(id)).is_empty():
			continue
		var b: Dictionary = builds[id]
		var tier := clampi(int(b.get("tier", 1)), 1, MAX_TIER)
		var mods := fitted_mods(str(id), tier, [str(b.get("mod", "")), str(b.get("mod2", ""))])
		var paint_id := str(b.get("paint", "original"))
		if paint(paint_id)["id"] != paint_id:
			paint_id = "original"
		if tier > 1 or not mods.is_empty() or paint_id != "original":
			out[str(id)] = {"tier": tier, "mod": mods[0] if mods.size() > 0 else "", "mod2": mods[1] if mods.size() > 1 else "", "paint": paint_id}
	return out


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
