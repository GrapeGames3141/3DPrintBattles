# GameData.gd
# Master data file for PrintForge Legends
# All creatures, abilities, equipment, and filament cards defined here.
# This is the single source of truth — do not hardcode stats anywhere else.
# To add a new creature: add an entry to CREATURES dict and seed it in SaveManager.

extends Node

# ─────────────────────────────────────────────────────────────────────────────
# ABILITIES
# Each ability has: name, description, effect_type, value, cooldown_turns
# effect_types: "damage_bonus", "heal", "stun_chance", "speed_debuff",
#               "block", "reflect", "forge_fill", "bench_damage", "stat_boost"
# ─────────────────────────────────────────────────────────────────────────────
const ABILITIES := {
	"ember_bite": {
		"name": "Ember Bite",
		"description": "Deals 3 bonus damage on first attack.",
		"effect_type": "damage_bonus",
		"value": 3,
		"cooldown": 3,
		"element": "fire"
	},
	"tidal_shield": {
		"name": "Tidal Shield",
		"description": "Blocks 2 incoming damage once per battle.",
		"effect_type": "block",
		"value": 2,
		"cooldown": 3,
		"element": "water"
	},
	"static_burst": {
		"name": "Static Burst",
		"description": "25% chance to stun opponent for 1 turn.",
		"effect_type": "stun_chance",
		"value": 0.25,
		"cooldown": 3,
		"element": "lightning"
	},
	"layer_shield": {
		"name": "Layer Shield",
		"description": "Block 3 incoming damage this turn.",
		"effect_type": "block",
		"value": 3,
		"cooldown": 3,
		"element": "any"
	},
	"tangle_roots": {
		"name": "Tangle Roots",
		"description": "Slows opponent speed by 1 for 2 turns.",
		"effect_type": "speed_debuff",
		"value": 1,
		"cooldown": 3,
		"element": "nature"
	},
	"frost_nip": {
		"name": "Frost Nip",
		"description": "+2 damage; opponent loses 1 speed next turn.",
		"effect_type": "damage_bonus",
		"value": 2,
		"cooldown": 3,
		"element": "ice"
	},
	"gust_strike": {
		"name": "Gust Strike",
		"description": "Attack hits twice at 60% power each.",
		"effect_type": "double_hit",
		"value": 0.6,
		"cooldown": 2,
		"element": "wind"
	},
	"overheat": {
		"name": "Overheat",
		"description": "Deal 6 bonus damage; take 2 self-damage.",
		"effect_type": "damage_self",
		"value": 6,
		"self_damage": 2,
		"cooldown": 2,
		"element": "fire"
	},
	"tidal_surge": {
		"name": "Tidal Surge",
		"description": "Heal your Print for 8 HP.",
		"effect_type": "heal",
		"value": 8,
		"cooldown": 2,
		"element": "water"
	},
	"barbed_layer": {
		"name": "Barbed Layer",
		"description": "Attacker takes 3 damage each time they hit you.",
		"effect_type": "thorns",
		"value": 3,
		"cooldown": 3,
		"element": "nature"
	},
	"print_storm": {
		"name": "Print Storm",
		"description": "Deal 3 damage to all opponent bench Prints.",
		"effect_type": "bench_damage",
		"value": 3,
		"cooldown": 2,
		"element": "lightning"
	},
	"cyclone_charge": {
		"name": "Cyclone Charge",
		"description": "Skip this turn; next turn deal 2.5x damage.",
		"effect_type": "charge",
		"value": 2.5,
		"cooldown": 3,
		"element": "wind"
	},
	"ancient_roar": {
		"name": "Ancient Roar",
		"description": "Reduce opponent Forge Bar by 2 units.",
		"effect_type": "forge_drain",
		"value": 2,
		"cooldown": 2,
		"element": "stone"
	},
	"arcane_surge": {
		"name": "Arcane Surge",
		"description": "All stats +30% for 2 turns.",
		"effect_type": "stat_boost",
		"value": 0.30,
		"duration": 2,
		"cooldown": 3,
		"element": "arcane"
	},
}

# ─────────────────────────────────────────────────────────────────────────────
# CREATURES
# bend_score: base attack stat (damage = bend_score / 4, rounded up)
# hp_base: bend_score * 3
# forge_cost: Forge Bar units needed to summon (1–10)
# blueprint_cost: Forge Coins to buy blueprint (permanent)
# print_cost: Forge Coins to print one copy
# rarity: 1=Common 2=Uncommon 3=Rare 4=Epic 5=Legendary
# sprite: filename in assets/sprites/ (placeholder color used if file missing)
# placeholder_color: hex color for placeholder rectangle
# ─────────────────────────────────────────────────────────────────────────────
const CREATURES := {
	# ── STARTERS (not purchasable, id used in starter selection) ──
	"cinderpaw": {
		"name": "Cinderpaw",
		"element": "fire",
		"rarity": 0,  # 0 = starter
		"bend_score": 12,
		"hp_base": 36,
		"forge_cost": 3,
		"blueprint_cost": 0,
		"print_cost": 0,
		"ability": "ember_bite",
		"is_starter": true,
		"lore": "A small fox with flame-tipped tails forged from enchanted orange filament.",
		"sprite": "cinderpaw_idle.png",
		"placeholder_color": Color(0.88, 0.36, 0.16),
	},
	"aquafin": {
		"name": "Aquafin",
		"element": "water",
		"rarity": 0,
		"bend_score": 11,
		"hp_base": 33,
		"forge_cost": 3,
		"blueprint_cost": 0,
		"print_cost": 0,
		"ability": "tidal_shield",
		"is_starter": true,
		"lore": "A dolphin-shark hybrid with wave-ridged fins, printed in shimmering teal filament.",
		"sprite": "aquafin_idle.png",
		"placeholder_color": Color(0.16, 0.48, 0.88),
	},
	"voltwig": {
		"name": "Voltwig",
		"element": "lightning",
		"rarity": 0,
		"bend_score": 10,
		"hp_base": 30,
		"forge_cost": 3,
		"blueprint_cost": 0,
		"print_cost": 0,
		"ability": "static_burst",
		"is_starter": true,
		"lore": "A hedgehog-bird hybrid with spiky quill-wings, crackling with yellow filament energy.",
		"sprite": "voltwig_idle.png",
		"placeholder_color": Color(0.96, 0.84, 0.12),
	},

	# ── COMMON (rarity 1) ──
	"stonepup": {
		"name": "Stonepup",
		"element": "stone",
		"rarity": 1,
		"bend_score": 8,
		"hp_base": 24,
		"forge_cost": 2,
		"blueprint_cost": 50,
		"print_cost": 20,
		"ability": "layer_shield",
		"is_starter": false,
		"lore": "A round puppy made of stacked stone rings, grey and steady.",
		"sprite": "stonepup_idle.png",
		"placeholder_color": Color(0.55, 0.55, 0.55),
	},
	"leafling": {
		"name": "Leafling",
		"element": "nature",
		"rarity": 1,
		"bend_score": 9,
		"hp_base": 27,
		"forge_cost": 2,
		"blueprint_cost": 50,
		"print_cost": 20,
		"ability": "tangle_roots",
		"is_starter": false,
		"lore": "A tiny sprout with vine arms and leaf ears, green and curious.",
		"sprite": "leafling_idle.png",
		"placeholder_color": Color(0.22, 0.68, 0.22),
	},
	"frostkit": {
		"name": "Frostkit",
		"element": "ice",
		"rarity": 1,
		"bend_score": 8,
		"hp_base": 24,
		"forge_cost": 2,
		"blueprint_cost": 50,
		"print_cost": 20,
		"ability": "frost_nip",
		"is_starter": false,
		"lore": "An arctic fox cub with icicle-tipped ears, white and pale blue.",
		"sprite": "frostkit_idle.png",
		"placeholder_color": Color(0.78, 0.92, 0.98),
	},

	# ── UNCOMMON (rarity 2) ──
	"galebird": {
		"name": "Galebird",
		"element": "wind",
		"rarity": 2,
		"bend_score": 14,
		"hp_base": 42,
		"forge_cost": 4,
		"blueprint_cost": 120,
		"print_cost": 40,
		"ability": "gust_strike",
		"is_starter": false,
		"lore": "A sleek hawk with layered geometric wing feathers of silver and sky blue.",
		"sprite": "galebird_idle.png",
		"placeholder_color": Color(0.68, 0.82, 0.92),
	},
	"magmaback": {
		"name": "Magmaback",
		"element": "fire",
		"rarity": 2,
		"bend_score": 16,
		"hp_base": 48,
		"forge_cost": 4,
		"blueprint_cost": 120,
		"print_cost": 40,
		"ability": "overheat",
		"is_starter": false,
		"lore": "A tortoise with a volcanic ridge shell and ember feet, dark red and orange.",
		"sprite": "magmaback_idle.png",
		"placeholder_color": Color(0.72, 0.22, 0.08),
	},
	"coralwing": {
		"name": "Coralwing",
		"element": "water",
		"rarity": 2,
		"bend_score": 15,
		"hp_base": 45,
		"forge_cost": 4,
		"blueprint_cost": 120,
		"print_cost": 40,
		"ability": "tidal_surge",
		"is_starter": false,
		"lore": "A manta ray with ornate coral-patterned wings of pink and ocean blue.",
		"sprite": "coralwing_idle.png",
		"placeholder_color": Color(0.92, 0.48, 0.68),
	},

	# ── RARE (rarity 3) ──
	"thornmantle": {
		"name": "Thornmantle",
		"element": "nature",
		"rarity": 3,
		"bend_score": 20,
		"hp_base": 60,
		"forge_cost": 5,
		"blueprint_cost": 300,
		"print_cost": 70,
		"ability": "barbed_layer",
		"is_starter": false,
		"lore": "A large armadillo with thorn-lattice plates of deep green and bronze.",
		"sprite": "thornmantle_idle.png",
		"placeholder_color": Color(0.18, 0.48, 0.12),
	},
	"boltfang": {
		"name": "Boltfang",
		"element": "lightning",
		"rarity": 3,
		"bend_score": 22,
		"hp_base": 66,
		"forge_cost": 5,
		"blueprint_cost": 300,
		"print_cost": 70,
		"ability": "print_storm",
		"is_starter": false,
		"lore": "A wolf with a lightning-rod spine and crackling paw pads, electric blue and charcoal.",
		"sprite": "boltfang_idle.png",
		"placeholder_color": Color(0.22, 0.38, 0.88),
	},

	# ── EPIC (rarity 4) ──
	"vortexhorn": {
		"name": "Vortexhorn",
		"element": "wind",
		"rarity": 4,
		"bend_score": 28,
		"hp_base": 84,
		"forge_cost": 7,
		"blueprint_cost": 600,
		"print_cost": 110,
		"ability": "cyclone_charge",
		"is_starter": false,
		"lore": "A rhino with a spiral horn and whirlwind shoulder plating, silver and storm grey.",
		"sprite": "vortexhorn_idle.png",
		"placeholder_color": Color(0.58, 0.58, 0.72),
	},
	"obsidianwyrm": {
		"name": "Obsidianwyrm",
		"element": "stone",
		"rarity": 4,
		"bend_score": 30,
		"hp_base": 90,
		"forge_cost": 7,
		"blueprint_cost": 600,
		"print_cost": 110,
		"ability": "ancient_roar",
		"is_starter": false,
		"lore": "A serpentine dragon covered in sharp obsidian facets, black and deep purple.",
		"sprite": "obsidianwyrm_idle.png",
		"placeholder_color": Color(0.18, 0.08, 0.28),
	},

	# ── LEGENDARY (rarity 5) ──
	"aurorathane": {
		"name": "Aurorathane",
		"element": "arcane",
		"rarity": 5,
		"bend_score": 40,
		"hp_base": 120,
		"forge_cost": 10,
		"blueprint_cost": 1200,
		"print_cost": 160,
		"ability": "arcane_surge",
		"is_starter": false,
		"lore": "A great stag with prismatic antlers of layered arcane crystal. Rainbow-on-black.",
		"sprite": "aurorathane_idle.png",
		"placeholder_color": Color(0.62, 0.22, 0.88),
	},
}

# ─────────────────────────────────────────────────────────────────────────────
# ELEMENTAL TYPE CHART
# Returns damage multiplier for attacker_element vs defender_element
# ─────────────────────────────────────────────────────────────────────────────
const ELEMENT_CHART := {
	"fire":      {"strong": ["nature", "ice"],      "weak": ["water", "stone"]},
	"water":     {"strong": ["fire", "lightning"],  "weak": ["nature", "ice"]},
	"lightning": {"strong": ["water", "wind"],      "weak": ["stone", "nature"]},
	"nature":    {"strong": ["water", "stone"],     "weak": ["fire", "lightning"]},
	"ice":       {"strong": ["nature", "wind"],     "weak": ["fire", "lightning"]},
	"stone":     {"strong": ["fire", "lightning"],  "weak": ["water", "nature"]},
	"wind":      {"strong": ["lightning", "nature"],"weak": ["stone", "ice"]},
	"arcane":    {"strong": [],                     "weak": []},
}

static func get_damage_multiplier(attacker_element: String, defender_element: String) -> float:
	if attacker_element == "arcane" or defender_element == "arcane":
		return 1.0
	var chart = ELEMENT_CHART.get(attacker_element, {})
	if defender_element in chart.get("strong", []):
		return 1.5
	if defender_element in chart.get("weak", []):
		return 0.6
	return 1.0

# ─────────────────────────────────────────────────────────────────────────────
# FILAMENT CARDS
# ─────────────────────────────────────────────────────────────────────────────
const FILAMENT_CARDS := {
	"raw_filament": {
		"name": "Raw Filament",
		"description": "+2 Forge Units.",
		"effect_type": "forge_fill",
		"value": 2,
		"rarity": 1,
		"placeholder_color": Color(0.88, 0.78, 0.48),
	},
	"heated_spool": {
		"name": "Heated Spool",
		"description": "+3 Forge Units; next Print gets +2 attack this turn.",
		"effect_type": "forge_fill_attack",
		"forge_value": 3,
		"attack_bonus": 2,
		"rarity": 1,
		"placeholder_color": Color(0.92, 0.52, 0.18),
	},
	"emergency_print": {
		"name": "Emergency Print",
		"description": "Summon next Print at half Forge Cost but it arrives at 50% HP.",
		"effect_type": "emergency_summon",
		"value": 0.5,
		"rarity": 2,
		"placeholder_color": Color(0.88, 0.22, 0.22),
	},
	"reinforced_layer": {
		"name": "Reinforced Layer",
		"description": "Add 8 HP to your active Print.",
		"effect_type": "heal",
		"value": 8,
		"rarity": 2,
		"placeholder_color": Color(0.38, 0.68, 0.38),
	},
	"arcane_filament": {
		"name": "Arcane Filament",
		"description": "Double your current Forge Units (once per battle).",
		"effect_type": "forge_double",
		"value": 2.0,
		"rarity": 3,
		"placeholder_color": Color(0.62, 0.22, 0.92),
	},
}

# ─────────────────────────────────────────────────────────────────────────────
# EQUIPMENT
# type: "armor" | "weapon" | "accessory"
# ─────────────────────────────────────────────────────────────────────────────
const EQUIPMENT := {
	# Armor
	"helm": {
		"name": "Helm", "type": "armor", "rarity": 1,
		"hp_bonus": 10, "speed_mod": 0,
		"blueprint_cost": 40, "print_cost": 15,
		"description": "+10 HP.",
		"placeholder_color": Color(0.72, 0.72, 0.72),
	},
	"chest_plate": {
		"name": "Chest Plate", "type": "armor", "rarity": 1,
		"hp_bonus": 15, "speed_mod": -1,
		"blueprint_cost": 60, "print_cost": 25,
		"description": "+15 HP, -1 speed.",
		"placeholder_color": Color(0.58, 0.58, 0.68),
	},
	"leg_guards": {
		"name": "Leg Guards", "type": "armor", "rarity": 1,
		"hp_bonus": 5, "speed_mod": 1,
		"blueprint_cost": 30, "print_cost": 12,
		"description": "+5 HP, +1 speed.",
		"placeholder_color": Color(0.62, 0.62, 0.52),
	},
	"full_suit": {
		"name": "Full Suit", "type": "armor", "rarity": 2,
		"hp_bonus": 25, "speed_mod": -2,
		"blueprint_cost": 100, "print_cost": 50,
		"description": "+25 HP, -2 speed.",
		"placeholder_color": Color(0.42, 0.42, 0.58),
	},
	"arcane_plate": {
		"name": "Arcane Plate", "type": "armor", "rarity": 3,
		"hp_bonus": 20, "speed_mod": 0,
		"blueprint_cost": 250, "print_cost": 60,
		"description": "+20 HP, element resistance +15%.",
		"placeholder_color": Color(0.52, 0.32, 0.78),
	},
	# Weapons
	"iron_claw": {
		"name": "Iron Filament Claw", "type": "weapon", "rarity": 1,
		"attack_bonus": 3, "effect_type": "none",
		"blueprint_cost": 40, "print_cost": 18,
		"description": "+3 attack.",
		"placeholder_color": Color(0.62, 0.62, 0.62),
	},
	"ember_fang": {
		"name": "Ember Fang", "type": "weapon", "rarity": 2,
		"attack_bonus": 4, "effect_type": "burn",
		"blueprint_cost": 80, "print_cost": 30,
		"description": "+4 attack; fire burns for 1 bonus damage next turn.",
		"placeholder_color": Color(0.92, 0.42, 0.12),
	},
	"frost_shard": {
		"name": "Frost Shard", "type": "weapon", "rarity": 2,
		"attack_bonus": 3, "effect_type": "slow",
		"blueprint_cost": 80, "print_cost": 30,
		"description": "+3 attack; slows opponent speed by 1 on hit.",
		"placeholder_color": Color(0.72, 0.88, 0.98),
	},
	"thunder_coil": {
		"name": "Thunder Coil", "type": "weapon", "rarity": 2,
		"attack_bonus": 5, "effect_type": "stun_chance",
		"blueprint_cost": 100, "print_cost": 45,
		"description": "+5 attack; 10% chance to stun opponent 1 turn.",
		"placeholder_color": Color(0.92, 0.88, 0.18),
	},
	# Accessories
	"filament_ring": {
		"name": "Filament Ring", "type": "accessory", "rarity": 1,
		"effect_type": "forge_fill_passive",
		"value": 0.5,
		"blueprint_cost": 40, "print_cost": 20,
		"description": "Forge Bar fills +0.5 units faster per turn.",
		"placeholder_color": Color(0.88, 0.78, 0.32),
	},
	"ember_amulet": {
		"name": "Ember Amulet", "type": "accessory", "rarity": 2,
		"effect_type": "element_damage_bonus",
		"element": "fire", "value": 2,
		"blueprint_cost": 60, "print_cost": 25,
		"description": "Fire attacks deal +2 bonus damage.",
		"placeholder_color": Color(0.88, 0.42, 0.18),
	},
	"tidal_core": {
		"name": "Tidal Core", "type": "accessory", "rarity": 2,
		"effect_type": "regen",
		"value": 2,
		"blueprint_cost": 80, "print_cost": 35,
		"description": "Heal 2 HP at start of each turn.",
		"placeholder_color": Color(0.22, 0.62, 0.88),
	},
	"arcane_sigil": {
		"name": "Arcane Sigil", "type": "accessory", "rarity": 3,
		"effect_type": "cooldown_reduction",
		"value": 1,
		"blueprint_cost": 200, "print_cost": 60,
		"description": "Special ability cooldown reduced by 1 turn.",
		"placeholder_color": Color(0.72, 0.32, 0.92),
	},
}

# ─────────────────────────────────────────────────────────────────────────────
# AI TRAINER OPPONENTS
# Each trainer has a name, difficulty (1–5), and a roster of creature IDs.
# Trainers are fought in order. Difficulty scales XP/coin rewards.
# ─────────────────────────────────────────────────────────────────────────────
const AI_TRAINERS := [
	{
		"id": "trainer_gizmo",
		"name": "Gizmo (Tutorial)",
		"difficulty": 1,
		"portrait": "trainer_gizmo.png",
		"intro_text": "Welcome to the Proving Grounds, Apprentice! Let's see what your starter can do.",
		"roster": ["stonepup", "leafling", "frostkit"],
		"reward_coins": 30,
		"reward_xp": 60,
	},
	{
		"id": "trainer_sparks",
		"name": "Sparks",
		"difficulty": 2,
		"portrait": "trainer_sparks.png",
		"intro_text": "My Prints have never lost on this forge floor. Don't expect to be the first.",
		"roster": ["galebird", "stonepup", "voltwig"],
		"reward_coins": 50,
		"reward_xp": 100,
	},
	{
		"id": "trainer_ember",
		"name": "Ember",
		"difficulty": 3,
		"portrait": "trainer_ember.png",
		"intro_text": "Fire always wins. Always.",
		"roster": ["magmaback", "cinderpaw", "boltfang"],
		"reward_coins": 75,
		"reward_xp": 150,
	},
	{
		"id": "trainer_tide",
		"name": "Tide",
		"difficulty": 4,
		"portrait": "trainer_tide.png",
		"intro_text": "The ocean is patient. I am not.",
		"roster": ["coralwing", "thornmantle", "aquafin"],
		"reward_coins": 100,
		"reward_xp": 200,
	},
	{
		"id": "trainer_forge_master",
		"name": "The Forge Master",
		"difficulty": 5,
		"portrait": "trainer_forgemaster.png",
		"intro_text": "You've come far, Apprentice. But mastery of the Forge takes more than courage.",
		"roster": ["vortexhorn", "obsidianwyrm", "aurorathane"],
		"reward_coins": 200,
		"reward_xp": 500,
	},
]

# ─────────────────────────────────────────────────────────────────────────────
# RARITY DISPLAY NAMES AND COLORS
# ─────────────────────────────────────────────────────────────────────────────
const RARITY_NAMES := {
	0: "Starter",
	1: "Common",
	2: "Uncommon",
	3: "Rare",
	4: "Epic",
	5: "Legendary",
	6: "Mythic",
	7: "Prismatic",
	8: "Primordial",
}

const RARITY_COLORS := {
	0: Color(0.78, 0.78, 0.78),  # grey
	1: Color(0.88, 0.88, 0.88),  # white
	2: Color(0.22, 0.78, 0.22),  # green
	3: Color(0.22, 0.52, 0.92),  # blue
	4: Color(0.62, 0.18, 0.88),  # purple
	5: Color(0.92, 0.78, 0.12),  # gold
	6: Color(0.92, 0.52, 0.12),  # orange
	7: Color(0.72, 0.22, 0.92),  # rainbow (use animated shader)
	8: Color(0.18, 0.08, 0.08),  # black/gold
}
