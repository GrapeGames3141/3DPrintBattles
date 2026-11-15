"""Wave 6: two hundred new cards, every one with its own job.

Ideas come from Yu-Gi-Oh! (the Forbidden Printer, tributes, swapping stats),
Pokemon and Digimon (evolution lines, poison and sleep, signature moves) and
Magic: The Gathering (a tribe that shares its gifts, fights, silence,
sacrifice). Every effect is told through 3D printing.

Each creature also gets a `look` for tools/render_art7.gd, which builds it a
body of its own from printed parts and poses it in all eight frames.
"""
import zlib

from .cards import TOOLS, UPGRADES
from .creatures import CREATURES, C, evolves, token
from .fx import _e, ability, on, tool_effect

F, W, L, N, I, S, D, A, X = "Fire", "Water", "Lightning", "Nature", "Ice", "Stone", "Wind", "Arcane", "Neutral"


# ---------------------------------------------------------------- helpers

def E(op, text, target="", **kw):
    return _e(op, text, target, **kw)


def IF(cond, part):
    q = dict(part)
    eff = dict(q["effect"])
    eff["if"] = cond
    q["effect"] = eff
    return q


def PER(per, part, cap=None):
    q = dict(part)
    eff = dict(q["effect"])
    eff["per"] = per
    if cap is not None:
        eff["cap"] = cap
    q["effect"] = eff
    return q


def SH(part):
    q = dict(part)
    q["shatter"] = True
    return q


def ON(when, *parts):
    return on(when, *parts)


def trig(when, *parts):
    """An ability for equipment to grant: {"when", "fx"}."""
    return {"when": when, "fx": [p["effect"] for p in parts]}


# Body plans for the art, picked from the creature's name unless given.
PLANS = [
    (("Owl", "Hawk", "Finch", "Parrot", "Roc", "Phoenix", "Pegasus", "Ashling", "Bat", "Kite"), "bird"),
    (("Serpent", "Eel", "Worm", "Wyrm", "Snake", "Wyvern", "Drake", "Dragon"), "serpent"),
    (("Crab", "Beetle", "Scarab", "Wasp", "Mantis", "Moth", "Dragonfly", "Swarm", "Spider"), "bug"),
    (("Golem", "Ogre", "Knight", "Sentinel", "Titan", "Colossus", "Automaton", "King", "Gargoyle", "Engine",
      "Bard", "Druid", "Sage", "Juggler", "Torchbearer", "Matriarch", "Welder", "Librarian", "Queen", "Imp"), "biped"),
    (("Slime", "Blob", "Jelly", "Oyster", "Orb", "Cube", "Globe", "Choir", "Mimic", "Pillar", "Spool"), "blob"),
    (("Ray", "Squid", "Angler", "Narwhal", "Seal", "Fish", "Shark", "Whale", "Penguin"), "fish"),
    (("Sprite", "Pixie", "Wraith", "Spirit", "Wisp", "Sylph", "Weaver", "Oracle"), "floater"),
    (("Tortoise", "Tortle", "Turtle", "Armadillo", "Snail", "Hedgehog"), "shell"),
]


def look(name, element, plan=None, **extra):
    seed = zlib.crc32(name.encode()) & 0xffffff
    if plan is None:
        plan = "quad"
        for words, p in PLANS:
            if any(w in name for w in words):
                plan = p
                break
    d = {"plan": plan, "seed": seed, "element": element}
    d.update(extra)
    return d


def K(cid, name, element, cost, atk, hp, rarity, kw, fx=None, plan=None, **extra):
    """A wave-6 creature with its own generated look."""
    art = dict(extra.pop("art", {}))
    lk = look(name, element, art.pop("plan", plan), **art)
    C(cid, name, element, cost, atk, hp, rarity, kw, fx, "gen")
    c = CREATURES[-1]
    c["look"] = lk
    c.update(extra)
    return c


def T(tid, name, cost, rarity, *parts, **extra):
    d = {"id": tid, "name": name, "type": "tool", "cost": cost, "rarity": rarity}
    d.update(tool_effect(*parts))
    d.update(extra)
    TOOLS.append(d)


def U(uid, name, cost, rarity, a, h, kw=(), text="", grant=(), effects=()):
    sign = ("+%d/+%d" % (a, h)) if (a or h) else ""
    kws = ", ".join({"guard": "Guard", "rush": "Rush", "hover": "Hover", "quick": "Quick Draw", "snap": "Snap",
                     "overflow": "Overflow", "reprint": "Reprint", "menace": "Menace", "ward": "Ward", "cloak": "Cloak",
                     "brim": "Brim", "twin": "Twin Nozzle", "siphon": "Siphon"}[k] for k in kw)
    head = " and ".join(x for x in (sign, kws) if x)
    full = ("Give a friendly print %s. " % head if head else "") + text
    d = {"id": uid, "name": name, "type": "upgrade", "cost": cost, "rarity": rarity, "text": full.strip(),
         "target": "friendly_print", "buff": {"atk": a, "hp": h, "kw": list(kw)}}
    if grant:
        d["grant"] = list(grant)
    if effects:
        d["effects"] = [p["effect"] for p in effects]
    UPGRADES.append(d)


# =================================================================== FIRE

K("sparkplug_imp", "Sparkplug Imp", F, 1, 1, 1, "common", [],
  ability(E("damage", "Deal 1 damage to a random enemy or the enemy Printer.", n=1, to="random_enemy_any")))
K("ember_moth", "Ember Moth", F, 2, 2, 2, "common", [],
  ability(ON("foe_attack", E("heat", "Heat the attacker.", n=2, to="trigger"))))
K("kilnback_tortoise", "Kilnback Tortoise", F, 4, 2, 6, "uncommon", ["guard"],
  ability(ON("printer_hit", E("heat", "Heat a random enemy print.", n=2, to="random_enemy"))))
K("brimstone_bulldog", "Brimstone Bulldog", F, 3, 3, 3, "common", [],
  ability(ON("kill", E("damage", "Deal 2 damage to the enemy Printer.", n=2, to="enemy_printer"))))
K("flarefox_kit", "Flarefox Kit", F, 2, 2, 1, "common", ["rush"],
  ability(SH(E("damage", "Deal 2 damage to a random enemy print.", n=2, to="random_enemy"))))
K("cinder_juggler", "Cinder Juggler", F, 3, 2, 3, "uncommon", [],
  ability(E("missiles", "Throw 3 embers of 1 damage at random enemies.", n=3)))
K("furnace_golem", "Furnace Golem", F, 5, 4, 6, "rare", [],
  ability(ON("turn_end", E("damage", "Deal 1 damage to every damaged enemy print.", n=1, to="damaged_enemies"))))
K("slagtooth", "Slagtooth", F, 4, 4, 3, "uncommon", [],
  ability(ON("attack", E("destroy_if", "Destroy the print it hits if that print has 2 Attack or less.", max_atk=2, to="trigger"))))
K("ashling", "Ashling", F, 2, 2, 2, "common", [],
  ability(SH(E("damage", "Deal 2 damage to the enemy Printer.", n=2, to="enemy_printer"))))
K("magma_mole", "Magma Mole", F, 2, 1, 4, "common", [],
  ability(PER("enemies", E("armor", "Your Printer gains 1 Armor for each enemy print.", n=1))))
K("torchbearer", "Torchbearer", F, 3, 3, 2, "uncommon", [],
  ability(ON("ally_attack", E("buff", "Give the attacker +1 Attack.", atk=1, hp=0, to="trigger"))))
K("scorch_wyrmling", "Scorch Wyrmling", F, 4, 3, 4, "rare", [],
  ability(E("double_atk", "Double a friendly print's Attack.", "friendly_print", to="target")))
K("volcano_tortle", "Volcano Tortle", F, 6, 3, 8, "rare", ["guard"],
  ability(E("damage", "Deal 2 damage to every other print, yours too.", n=2, to="other_prints")))
K("blaze_matriarch", "Blaze Matriarch", F, 7, 6, 6, "legendary", [],
  ability(PER("allies", E("damage", "Deal 1 damage to every enemy print for each print you have.", n=1, to="enemy_prints"))))
K("sootling", "Sootling", F, 1, 1, 2, "common", [],
  ability(IF({"element_ally": "Fire"}, E("damage", "If you have another Fire print, deal 2 damage.", "enemy", n=2, to="target"))))
K("cinder_sprite", "Cinder Sprite", F, 2, 1, 2, "uncommon", [],
  ability(ON("tool", E("damage", "Deal 1 damage to the enemy Printer and 1 to a random enemy print.", n=1, to="enemy_printer"),
              E("damage", "", n=1, to="random_enemy"))))

# ================================================================== WATER

K("bubblepip", "Bubblepip", W, 1, 1, 2, "common", [],
  ability(E("heal", "Repair a friendly print by 3.", "friendly_print", n=3, to="target")))
K("tidecaller_crab", "Tidecaller Crab", W, 3, 2, 4, "common", [],
  ability(ON("turn_start", E("heal", "Repair your most hurt print by 2.", n=2, to="lowest_ally"))))
K("siphon_squid", "Siphon Squid", W, 4, 3, 4, "uncommon", [],
  ability(ON("attack", E("drain", "Drain 2 Health from the enemy Printer into yours.", n=2, to="enemy_printer"))))
K("coral_sentinel", "Coral Sentinel", W, 5, 3, 7, "rare", ["guard"],
  ability(ON("printer_hit", E("buff", "This gets +1 Attack.", atk=1, hp=0, to="self"))))
K("whirlpool_ray", "Whirlpool Ray", W, 5, 4, 4, "rare", [],
  ability(E("swap", "Swap a print's Attack and Health.", "any_print", to="target")))
K("mistweaver", "Mistweaver", W, 2, 1, 3, "common", [],
  ability(IF({"hand_at_most": 3}, E("draw", "If you have 3 or fewer cards in hand, draw 2 cards.", n=2))))
K("puddle_mimic", "Puddle Mimic", W, 4, 1, 1, "rare", [],
  ability(E("copy", "Print a copy of an enemy print on your side.", "enemy_print", to="target")))
K("pearl_oyster", "Pearl Oyster", W, 2, 0, 4, "common", [],
  ability(ON("turn_end", E("armor", "Your Printer gains 1 Armor.", n=1))))
K("surge_seal", "Surge Seal", W, 4, 3, 3, "uncommon", [],
  ability(E("bounce", "Send an enemy print with 3 Attack or less back to its owner's hand.", "enemy_print", to="target")),
  target_max_atk=3)
K("kelp_strangler", "Kelp Strangler", W, 3, 2, 4, "common", [],
  ability(ON("attack", E("jam", "Jam the print it hits.", to="trigger"))))
K("abyssal_angler", "Abyssal Angler", W, 6, 5, 5, "rare", [],
  ability(E("tutor", "Take a print from your deck into your hand.", kind="creature")))
K("tsunami_titan", "Tsunami Titan", W, 8, 7, 7, "legendary", [],
  ability(E("bounce", "Send every other print back to its owner's hand.", to="other_prints")))
K("dewdrop_sprite", "Dewdrop Sprite", W, 1, 1, 1, "common", [],
  ability(ON("turn_start", PER("element:Water", E("heal", "Repair your Printer by 1 for each Water print you have.", n=1, to="own_printer")))))
K("narwhal_lancer", "Narwhal Lancer", W, 5, 5, 3, "rare", ["overflow"],
  ability(ON("kill", E("buff", "This gets +2/+2.", atk=2, hp=2, to="self"))))
K("brine_bard", "Brine Bard", W, 3, 2, 3, "uncommon", [],
  ability(ON("ally_print", E("heal", "Repair your Printer by 1.", n=1, to="own_printer"))))

# ============================================================== LIGHTNING

K("zapling", "Zapling", L, 1, 1, 1, "common", [],
  ability(E("chain", "Lightning: 2 damage to a random enemy print, then 1 to another.", n=2)))
K("static_hedgehog", "Static Hedgehog", L, 2, 2, 2, "common", [],
  ability(ON("hurt", E("damage", "Deal 1 damage to the enemy Printer.", n=1, to="enemy_printer"))))
K("volt_ferret", "Volt Ferret", L, 2, 3, 1, "common", ["rush"],
  ability(SH(E("buff", "Give a random friendly print +1 Attack and Rush.", atk=1, hp=0, kw=["rush"], to="random_friendly"))))
K("thunder_ram", "Thunder Ram", L, 4, 4, 3, "uncommon", [],
  ability(ON("attack", E("chain", "Lightning leaps from the print it hits: 3, then 2, then 1 damage.", n=3))))
K("capacitor_crab", "Capacitor Crab", L, 3, 1, 5, "common", [],
  ability(ON("turn_start", IF({"printer_damaged": True}, E("filament", "If your Printer is damaged, +2 Print Speed this turn.", n=2)))))
K("surge_owl", "Surge Owl", L, 3, 2, 3, "uncommon", [],
  ability(ON("tool", E("damage", "Deal 1 damage to a random enemy or the enemy Printer.", n=1, to="random_enemy_any"))))
K("gigavolt_golem", "Gigavolt Golem", L, 6, 5, 6, "epic", [],
  ability(E("missiles", "Fire 6 sparks of 1 damage at random enemies.", n=6)))
K("overload_eel", "Overload Eel", L, 4, 3, 3, "uncommon", [],
  ability(E("silence", "Silence an enemy print: it loses its keywords and abilities.", "enemy_print", to="target")))
K("tesla_tortoise", "Tesla Tortoise", L, 5, 2, 7, "rare", ["guard"],
  ability(ON("foe_attack", E("damage", "Deal 2 damage to the attacker.", n=2, to="trigger"))))
K("spark_kitten", "Spark Kitten", L, 1, 1, 2, "common", [],
  ability(ON("turn_end", E("buff", "Give a random friendly print +1 Attack.", atk=1, hp=0, to="random_friendly"))))
K("short_circuit", "Short Circuit", L, 3, 3, 2, "uncommon", [],
  ability(E("slow", "Your opponent gets 2 less Filament next turn.", n=2)))
K("blackout_bat", "Blackout Bat", L, 4, 3, 3, "rare", ["hover"],
  ability(E("sleep", "Put the strongest enemy print to sleep for 2 turns.", n=2, to="strongest_enemy")))
K("arc_wasp", "Arc Wasp", L, 2, 2, 1, "common", [],
  ability(ON("attack", IF({"allies_at_least": 3}, E("draw", "If you have 3 or more prints, draw a card.", n=1)))))
K("plasma_pegasus", "Plasma Pegasus", L, 7, 5, 5, "epic", ["hover"],
  ability(ON("turn_start", E("chain", "Lightning: 3 damage to a random enemy print, then 2, then 1.", n=3))))
K("raijin_reactor", "Raijin Reactor", L, 8, 6, 8, "legendary", [],
  ability(E("double_atk", "Double the Attack of all your other prints.", to="other_friendly_prints")))

# ================================================================= NATURE

K("moss_sprout", "Moss Sprout", N, 1, 0, 3, "common", ["guard"],
  ability(ON("turn_end", E("buff", "Give your most hurt print +0/+1.", atk=0, hp=1, to="lowest_ally"))))
K("thornback_hare", "Thornback Hare", N, 2, 2, 2, "common", [],
  ability(ON("hurt", E("damage", "Deal 1 damage to all enemy prints.", n=1, to="enemy_prints"))))
K("vine_weaver", "Vine Weaver", N, 3, 2, 3, "common", [],
  ability(E("buff", "Give a friendly print +0/+2 and Guard.", "friendly_print", atk=0, hp=2, kw=["guard"], to="target")))
K("seedbomb_squirrel", "Seedbomb Squirrel", N, 2, 1, 1, "common", [],
  ability(SH(E("summon", "Print two 1/1 Test Bots.", n=2, card="test_bot"))))
K("bloom_druid", "Bloom Druid", N, 4, 3, 4, "uncommon", [],
  ability(E("heal", "Repair all your prints by 2", n=2, to="friendly_prints"), E("heal", "and your Printer by 2.", n=2, to="own_printer")))
K("treant_elder", "Treant Elder", N, 6, 4, 8, "rare", ["guard"],
  ability(ON("turn_start", E("buff", "Give your other prints +0/+1.", atk=0, hp=1, to="other_friendly_prints"))))
K("venus_snapper", "Venus Snapper", N, 3, 3, 3, "uncommon", [],
  ability(E("destroy_if", "Destroy an enemy print with 2 Attack or less.", "enemy_print", max_atk=2, to="target")),
  target_max_atk=2)
K("pollen_pixie", "Pollen Pixie", N, 1, 1, 1, "common", [],
  ability(E("cleanse", "Cleanse a friendly print", "friendly_print", to="target"), E("buff", "and give it +1 Attack.", atk=1, hp=0, to="target")))
K("mushroom_choir", "Mushroom Choir", N, 5, 2, 5, "rare", [],
  ability(E("poison", "Poison all enemy prints.", to="enemy_prints")))
K("ironbark_bear", "Ironbark Bear", N, 5, 4, 6, "uncommon", [],
  ability(ON("turn_end", IF({"self_damaged": True}, E("buff", "If this is damaged, it gets +2 Attack.", atk=2, hp=0, to="self")))))
K("grove_stag", "Grove Stag", N, 4, 3, 5, "uncommon", [],
  ability(ON("ally_shatter", E("summon", "Print a 1/1 Test Bot.", n=1, card="test_bot"))))
K("pack_wolf", "Pack Wolf", N, 3, 2, 2, "common", [],
  ability(PER("element:Nature", E("buff", "This gets +1/+1 for each Nature print you have.", atk=1, hp=1, to="self"))))
K("rootling", "Rootling", N, 2, 1, 3, "common", [],
  ability(PER("enemies", E("spool", "Add 2 Filament to your Spool for each enemy print.", n=2))))
K("overgrowth_hydra", "Overgrowth Hydra", N, 7, 4, 7, "epic", [],
  ability(ON("turn_start", PER("allies", E("buff", "This gets +1/+1 for each of your prints.", atk=1, hp=1, to="self")))))
K("gaia_engine", "Gaia Engine", N, 9, 8, 10, "legendary", [],
  ability(E("buff", "Give your other prints +2/+2 and Guard.", atk=2, hp=2, kw=["guard"], to="other_friendly_prints")))

# ==================================================================== ICE

K("frostbit_penguin", "Frostbit Penguin", I, 1, 1, 2, "common", [],
  ability(ON("foe_attack", E("jam", "Jam the attacker.", to="trigger"))))
K("snowball_seal", "Snowball Seal", I, 2, 2, 3, "common", [],
  ability(E("jam", "Jam an enemy print", "enemy_print", to="target"), E("damage", "and deal 1 damage to it.", n=1, to="target")))
K("glacier_golem", "Glacier Golem", I, 5, 3, 7, "rare", ["guard"],
  ability(ON("turn_end", E("sleep", "Put a random enemy print to sleep for 2 turns.", n=2, to="random_enemy"))))
K("icicle_archer", "Icicle Archer", I, 3, 3, 2, "common", ["reach"],
  ability(ON("attack", E("jam", "Jam a random enemy print.", to="random_enemy"))))
K("frost_wyvern", "Frost Wyvern", I, 6, 5, 5, "epic", ["hover"],
  ability(E("jam", "Jam all enemy prints", to="enemy_prints"), E("damage", "and deal 1 damage to them.", n=1, to="enemy_prints")))
K("permafrost_bear", "Permafrost Bear", I, 4, 3, 5, "uncommon", [],
  ability(ON("turn_start", PER("enemies", E("armor", "Your Printer gains 1 Armor for each enemy print.", n=1)))))
K("crystal_fox", "Crystal Fox", I, 2, 2, 2, "uncommon", [],
  ability(SH(E("jam", "Jam all enemy prints.", to="enemy_prints"))))
K("hailstorm_hawk", "Hailstorm Hawk", I, 4, 3, 3, "uncommon", ["hover"],
  ability(E("missiles", "Throw 4 hailstones of 1 damage at random enemy prints.", n=4, printer=False)))
K("snow_globe_golem", "Snow Globe Golem", I, 3, 0, 6, "common", ["guard"],
  ability(ON("printer_hit", E("jam", "Jam a random enemy print.", to="random_enemy"))))
K("cryo_slime", "Cryo Slime", I, 2, 1, 3, "common", [],
  ability(SH(E("sleep", "Put the strongest enemy print to sleep for 2 turns.", n=2, to="strongest_enemy"))))
K("ice_queen_moth", "Ice Queen Moth", I, 7, 5, 6, "legendary", ["hover"],
  ability(E("sleep", "Put every enemy print to sleep for 2 turns.", n=2, to="enemy_prints")))
K("polar_packrat", "Polar Packrat", I, 1, 1, 1, "common", [],
  ability(E("tutor", "Take a tool from your deck into your hand.", kind="tool")))
K("rime_knight", "Rime Knight", I, 5, 4, 5, "rare", [],
  ability(ON("kill", E("sleep", "Put a random enemy print to sleep for 2 turns.", n=2, to="random_enemy"))))
K("avalanche_ox", "Avalanche Ox", I, 6, 6, 5, "rare", [],
  ability(ON("attack", IF({"printer_at_most": 10}, E("damage", "If your Printer has 10 Health or less, deal 2 damage to all enemy prints.", n=2, to="enemy_prints")))))

# ================================================================== STONE

K("pebble_golemite", "Pebble Golemite", S, 1, 1, 3, "common", [],
  ability(E("armor", "Your Printer gains 2 Armor.", n=2)))
K("boulder_beetle", "Boulder Beetle", S, 3, 2, 5, "common", ["guard"],
  ability(ON("ally_shatter", E("buff", "This gets +1/+1.", atk=1, hp=1, to="self"))))
K("geode_armadillo", "Geode Armadillo", S, 4, 2, 6, "uncommon", [],
  ability(ON("hurt", PER("element:Stone", E("damage", "Deal 1 damage to the enemy Printer for each Stone print you have.", n=1, to="enemy_printer")))))
K("quarry_crusher", "Quarry Crusher", S, 5, 5, 5, "rare", [],
  ability(ON("attack", E("destroy_if", "Destroy the print it hits if that print was already damaged.", damaged=True, to="trigger"))))
K("obsidian_sentinel", "Obsidian Sentinel", S, 6, 4, 8, "rare", ["guard"],
  ability(ON("printer_hit", E("damage", "Deal 2 damage to a random enemy print.", n=2, to="random_enemy"))))
K("marble_sculptor", "Marble Sculptor", S, 3, 2, 4, "uncommon", [],
  ability(E("buff", "Give a friendly print +0/+3 and Brim.", "friendly_print", atk=0, hp=3, kw=["brim"], to="target")))
K("sandstone_scarab", "Sandstone Scarab", S, 2, 2, 2, "common", [],
  ability(SH(E("armor", "Your Printer gains 3 Armor.", n=3))))
K("fossil_raptor", "Fossil Raptor", S, 4, 3, 3, "uncommon", [],
  ability(PER("scrapped", E("buff", "This gets +1/+1 for each of your prints destroyed this battle.", atk=1, hp=1, to="self"), cap=6)))
K("crag_ogre", "Crag Ogre", S, 4, 6, 5, "uncommon", [],
  ability(ON("turn_end", E("damage", "Deal 1 damage to your own Printer.", n=1, to="own_printer"))))
K("mountain_king", "Mountain King", S, 8, 7, 9, "legendary", [],
  ability(PER("damage", E("armor", "Your Printer gains Armor equal to the damage it has taken.", n=1))))
K("gravel_gremlin", "Gravel Gremlin", S, 1, 2, 1, "common", [],
  ability(SH(E("damage", "Deal 1 damage to all enemy prints.", n=1, to="enemy_prints"))))
K("statue_gargoyle", "Statue Gargoyle", S, 3, 3, 3, "uncommon", [],
  ability(ON("turn_start", IF({"alone": True}, E("buff", "If it is your only print, it gets +1/+1 and Guard.", atk=1, hp=1, kw=["guard"], to="self")))))
K("rubble_hound", "Rubble Hound", S, 3, 3, 3, "common", [],
  ability(ON("kill", E("armor", "Your Printer gains 2 Armor.", n=2))))
K("basalt_colossus", "Basalt Colossus", S, 7, 5, 9, "epic", [],
  ability(PER("allies", E("armor", "Your Printer gains 2 Armor for each of your prints.", n=2))))

# =================================================================== WIND

K("breeze_finch", "Breeze Finch", D, 1, 1, 1, "common", ["hover"],
  ability(E("buff", "Give a friendly print Hover.", "friendly_print", atk=0, hp=0, kw=["hover"], to="target")))
K("gust_glider", "Gust Glider", D, 2, 2, 2, "common", ["hover"],
  ability(ON("kill", E("bounce", "Fly back to your hand.", to="self"))))
K("tornado_weasel", "Tornado Weasel", D, 3, 2, 3, "uncommon", [],
  ability(E("discard", "Your opponent throws away a random card from their hand.", n=1)))
K("cyclone_serpent", "Cyclone Serpent", D, 5, 4, 5, "rare", [],
  ability(ON("attack", E("bounce", "Blow the print it hits back to its owner's hand.", to="trigger"))))
K("kite_drake", "Kite Drake", D, 4, 3, 3, "uncommon", [],
  ability(E("buff", "Give all your Wind prints Hover.", atk=0, hp=0, kw=["hover"], to="element:Wind")))
K("zephyr_sprite", "Zephyr Sprite", D, 2, 1, 2, "common", [],
  ability(ON("ally_print", E("buff", "Give the arriving print Hover.", atk=0, hp=0, kw=["hover"], to="trigger"))))
K("sky_pirate_parrot", "Sky Pirate Parrot", D, 3, 2, 2, "uncommon", ["hover"],
  ability(ON("attack", E("drain_spool", "Steal 2 Filament from your opponent's Spool.", n=2))))
K("windmill_golem", "Windmill Golem", D, 4, 2, 6, "uncommon", [],
  ability(ON("turn_start", PER("element:Wind", E("filament", "+1 Print Speed this turn for each Wind print you have.", n=1)))))
K("storm_roc", "Storm Roc", D, 6, 5, 5, "epic", ["hover"],
  ability(E("bounce", "Blow the strongest enemy print back to its owner's hand.", to="strongest_enemy")))
K("feather_duster_fox", "Feather Duster Fox", D, 1, 1, 2, "common", [],
  ability(SH(E("draw", "Draw a card.", n=1))))
K("whirligig", "Whirligig", D, 2, 2, 1, "common", [],
  ability(IF({"outnumbered": True}, E("summon", "If your opponent has more prints than you, print two 1/1 Test Bots.", n=2, card="test_bot"))))
K("aero_mantis", "Aero Mantis", D, 3, 3, 2, "uncommon", ["quick"],
  ability(ON("kill", E("buff", "This gets Hover.", atk=0, hp=0, kw=["hover"], to="self"))))
K("jetstream_dragonfly", "Jetstream Dragonfly", D, 4, 3, 3, "rare", ["twin"],
  ability(ON("ally_attack", E("damage", "Deal 1 damage to the enemy Printer.", n=1, to="enemy_printer"))))
K("sylph_queen", "Sylph Queen", D, 7, 5, 6, "legendary", ["hover"],
  ability(E("discard", "Your opponent throws away 2 random cards", n=2), E("slow", "and gets 2 less Filament next turn.", n=2)))

# ================================================================= ARCANE

K("runeling", "Runeling", A, 1, 1, 1, "common", [],
  ability(E("tutor", "Take an equipment card from your deck into your hand.", kind="upgrade")))
K("hex_owl", "Hex Owl", A, 2, 2, 2, "common", [],
  ability(E("buff", "Give an enemy print -2 Attack.", "enemy_print", atk=-2, hp=0, to="target")))
K("mirror_imp", "Mirror Imp", A, 3, 2, 2, "uncommon", [],
  ability(E("give_copy", "Add a copy of an enemy print's card to your hand.", "enemy_print", to="target")))
K("shapeshift_sage", "Shapeshift Sage", A, 4, 3, 3, "rare", [],
  ability(E("polymorph", "Turn an enemy print into a 1/1 Test Bot.", "enemy_print", to="target")))
K("arcane_librarian", "Arcane Librarian", A, 3, 1, 4, "common", [],
  ability(ON("turn_end", IF({"hand_at_most": 2}, E("draw", "If you have 2 or fewer cards in hand, draw a card.", n=1)))))
K("spellsword_fox", "Spellsword Fox", A, 3, 3, 2, "uncommon", [],
  ability(ON("tool", E("refresh", "This can attack again.", to="self"))))
K("void_weaver", "Void Weaver", A, 5, 3, 6, "rare", [],
  ability(PER("element:Arcane", E("discard", "Your opponent throws away a random card for each Arcane print you have.", n=1), cap=3)))
K("chrono_snail", "Chrono Snail", A, 4, 0, 6, "rare", [],
  ability(ON("turn_end", E("slow", "Your opponent gets 1 less Filament next turn.", n=1))))
K("mana_wraith", "Mana Wraith", A, 4, 3, 4, "uncommon", [],
  ability(E("drain_spool", "Steal 4 Filament from your opponent's Spool.", n=4)))
K("glitch_cat", "Glitch Cat", A, 2, 2, 2, "uncommon", [],
  ability(SH(E("polymorph", "Turn a random enemy print into a 1/1 Test Bot.", to="random_enemy"))))
K("oracle_orb", "Oracle Orb", A, 4, 0, 4, "rare", [],
  ability(ON("turn_start", E("tutor", "Take a print costing 2 or less from your deck into your hand.", kind="creature", max_cost=2))))
K("archmage_automaton", "Archmage Automaton", A, 6, 4, 6, "epic", [],
  ability(ON("tool", E("damage", "Deal 2 damage to all enemy prints.", n=2, to="enemy_prints"))))
K("nullifier", "Nullifier", A, 5, 4, 4, "epic", [],
  ability(E("silence", "Silence all enemy prints.", to="enemy_prints")))
K("eternity_engine", "Eternity Engine", A, 8, 6, 6, "legendary", [],
  ability(ON("turn_end", PER("hand", E("heal", "Repair your Printer by 1 for each card in your hand.", n=1, to="own_printer")))))

# ================================================================ NEUTRAL

K("calibration_cube", "Calibration Cube", X, 2, 1, 1, "uncommon", [],
  ability(E("mimic", "Take on the Attack and Health of another print.", "any_print", to="target")))
K("benchy_unsinkable", "Benchy the Unsinkable", X, 4, 3, 5, "legendary", [],
  ability(SH(E("give", "Return to your hand.", card="benchy_unsinkable"))), art={"plan": "boat"})
K("spool_twin", "Spool Twin", X, 4, 2, 2, "rare", [],
  ability(E("copy", "Print a copy of a friendly print.", "friendly_print", to="target")))
K("failed_print", "Failed Print", X, 1, 2, 2, "common", [],
  ability(E("damage", "Deal 2 damage to your own Printer.", n=2, to="own_printer")), art={"plan": "blob"})
K("support_pillar", "Support Pillar", X, 2, 0, 5, "common", ["guard"],
  ability(SH(E("buff", "Give your prints +1 Attack.", atk=1, hp=0, to="friendly_prints"))))
K("stringing_slime", "Stringing Slime", X, 2, 1, 3, "common", [],
  ability(ON("foe_print", E("poison", "Poison the arriving print.", to="trigger"))))
K("raft_crawler", "Raft Crawler", X, 3, 3, 3, "uncommon", [],
  ability(E("sacrifice", "Scrap your weakest other print to get +3/+3.",
            then=[{"op": "buff", "atk": 3, "hp": 3, "to": "self"}])))
K("tribute_titan", "Tribute Titan", X, 4, 7, 7, "epic", [],
  ability(E("sacrifice", "Scrap your weakest other print, or this one is scrapped instead.",
            then=[], **{"else": [{"op": "destroy", "to": "self"}]})), art={"plan": "biped"})
K("glue_golem", "Glue Golem", X, 4, 2, 6, "common", [],
  ability(E("buff", "Give your other prints +0/+2.", atk=0, hp=2, to="other_friendly_prints")))
K("purge_line_worm", "Purge Line Worm", X, 3, 2, 3, "uncommon", [],
  ability(E("cleanse", "Cleanse all your prints", to="friendly_prints"), E("heal", "and repair them by 1.", n=1, to="friendly_prints")))

# ======================================================= THE FORBIDDEN PRINTER

_FP = "Part of the Forbidden Printer: hold all five parts in your hand at once and you win."
for cid, name, a, h, kw in (("fp_left_rail", "Forbidden Left Rail", 1, 4, []), ("fp_right_rail", "Forbidden Right Rail", 1, 4, []),
                            ("fp_hot_end", "Forbidden Hot End", 2, 2, []), ("fp_frame", "Forbidden Frame", 0, 6, ["guard"]),
                            ("fp_mainboard", "Forbidden Mainboard", 1, 3, [])):
    K(cid, name, X, 3, a, h, "legendary", kw, {"text": _FP, "target": "", "on_print": [], "shatter": []},
      art={"plan": "part", "part": cid})

# ================================================================ SWARMLINGS
# Like Slivers: every Swarmling shares its gift with every other Swarmling.

def swarm(cid, name, element, cost, a, h, rarity, gift_text, eff):
    share = dict(eff)
    share_on_arrive = dict(eff)
    share_on_arrive["to"] = "trigger"
    share_on_arrive["if"] = {"trigger_tribe": "swarm"}
    share["to"] = "tribe:swarm"
    fx = {"text": "Swarmling. Your Swarmlings %s, now and when they arrive." % gift_text, "target": "", "on_print": [share], "shatter": [],
          "trig": [{"when": "ally_print", "fx": [share_on_arrive]}], "tribe": "swarm"}
    K(cid, name, element, cost, a, h, rarity, [], fx, plan="bug", art={"swarm": True})


swarm("swarm_scout", "Swarm Scout", D, 1, 1, 1, "common", "get Rush", {"op": "buff", "atk": 0, "hp": 0, "kw": ["rush"]})
swarm("swarm_warden", "Swarm Warden", N, 2, 1, 3, "common", "get Guard", {"op": "buff", "atk": 0, "hp": 0, "kw": ["guard"]})
swarm("swarm_stinger", "Swarm Stinger", N, 2, 2, 1, "common", "get +1 Attack", {"op": "buff", "atk": 1, "hp": 0})
swarm("swarm_carapace", "Swarm Carapace", S, 3, 1, 4, "uncommon", "get +0/+2", {"op": "buff", "atk": 0, "hp": 2})
swarm("swarm_glider", "Swarm Glider", D, 3, 2, 2, "uncommon", "get Hover", {"op": "buff", "atk": 0, "hp": 0, "kw": ["hover"]})
swarm("swarm_leech", "Swarm Leech", W, 3, 2, 2, "rare", "get Siphon", {"op": "buff", "atk": 0, "hp": 0, "kw": ["siphon"]})
swarm("swarm_twinwing", "Swarm Twinwing", L, 4, 2, 3, "rare", "get Twin Nozzle", {"op": "buff", "atk": 0, "hp": 0, "kw": ["twin"]})
K("swarm_larva", "Swarm Larva", N, 1, 1, 1, "common", [], {"text": "Swarmling.", "target": "", "on_print": [], "shatter": [], "tribe": "swarm"},
  plan="bug", art={"swarm": True})
token("swarm_larva")
K("swarm_queen", "Swarm Queen", N, 6, 4, 6, "legendary", [],
  dict(ability(ON("turn_start", E("summon", "Print a 1/1 Swarm Larva.", n=1, card="swarm_larva"))), tribe="swarm"),
  plan="bug", art={"swarm": True, "crown": True})
CREATURES[-1]["text"] = "Swarmling. " + CREATURES[-1]["text"]

# ======================================================= THREE MORE EVOLUTION LINES

K("dripling", "Dripling", W, 1, 1, 2, "common", [], evolves("splashard", "Splashard", 2), art={"plan": "blob", "stage": 1})
K("splashard", "Splashard", W, 4, 3, 4, "rare", ["guard"], evolves("torrentus", "Torrentus", 3), art={"plan": "fish", "stage": 2})
K("torrentus", "Torrentus", W, 7, 6, 6, "legendary", ["guard"],
  ability(ON("turn_start", E("heal", "Repair all your prints by 2.", n=2, to="friendly_prints"))), art={"plan": "serpent", "stage": 3})
K("pebbit", "Pebbit", S, 2, 1, 3, "common", [], evolves("bouldron", "Bouldron", 2), art={"plan": "blob", "stage": 1})
K("bouldron", "Bouldron", S, 5, 3, 6, "rare", ["guard"], evolves("titanite", "Titanite", 3), art={"plan": "shell", "stage": 2})
K("titanite", "Titanite", S, 8, 6, 9, "legendary", ["guard", "brim"],
  ability(ON("printer_hit", E("armor", "Your Printer gains 2 Armor.", n=2))), art={"plan": "biped", "stage": 3})
K("sproutpaw", "Sproutpaw", N, 2, 2, 2, "common", [], evolves("thornfang", "Thornfang", 2), art={"plan": "quad", "stage": 1})
K("thornfang", "Thornfang", N, 5, 4, 4, "rare", ["thief"], evolves("elderbloom", "Elderbloom", 3), art={"plan": "quad", "stage": 2})
K("elderbloom", "Elderbloom", N, 8, 7, 7, "legendary", ["guard"],
  ability(ON("turn_end", E("buff", "Give your other prints +1/+1.", atk=1, hp=1, to="other_friendly_prints"))), art={"plan": "quad", "stage": 3})
for t in ("splashard", "torrentus", "bouldron", "titanite", "thornfang", "elderbloom"):
    token(t)

# =================================================================== TOOLS

T("lightning_rod", "Lightning Rod", 3, "uncommon", E("chain", "Lightning: 3 damage to an enemy print, then 2 and 1 to others.", "enemy_print", n=3))
T("scatter_shot", "Scatter Shot", 2, "common", E("missiles", "Fire 3 sparks of 1 damage at random enemies.", n=3))
T("mute_button", "Mute Button", 2, "uncommon", E("silence", "Silence a print: it loses its keywords and abilities.", "any_print", to="target"))
T("shapeshifter_resin", "Shapeshifter Resin", 4, "rare", E("polymorph", "Turn a print into a 1/1 Test Bot.", "any_print", to="target"))
T("glitch_patch", "Glitch Patch", 1, "uncommon", E("swap", "Swap a print's Attack and Health.", "any_print", to="target"))
T("double_extrusion", "Double Extrusion", 3, "rare", E("double_atk", "Double a friendly print's Attack.", "friendly_print", to="target"))
T("paint_thinner", "Paint Thinner", 1, "common", E("buff", "Give an enemy print -3 Attack.", "enemy_print", atk=-3, hp=0, to="target"))
T("rebalance", "Rebalance", 2, "uncommon", E("set_atk", "Set an enemy print's Attack to 1.", "enemy_print", n=1, to="target"))
T("bed_purge", "Bed Purge", 5, "epic", E("destroy_if", "Destroy every damaged enemy print.", damaged=True, to="enemy_prints"))
T("pest_control", "Pest Control", 2, "uncommon", E("destroy_if", "Destroy every enemy print with 1 Attack or less.", max_atk=1, to="enemy_prints"))
T("data_leak", "Data Leak", 2, "common", E("discard", "Your opponent throws away a random card", n=1), E("draw", "and you draw a card.", n=1))
T("siphon_filament", "Siphon Filament", 2, "common", E("drain_spool", "Steal 5 Filament from your opponent's Spool.", n=5))
T("thermal_throttle", "Thermal Throttle", 2, "uncommon", E("slow", "Your opponent gets 3 less Filament next turn.", n=3))
T("scrap_recycler", "Scrap Recycler", 2, "uncommon", PER("scrapped", E("draw", "Draw a card for each of your prints destroyed this battle (up to 3).", n=1), cap=3))
T("last_layer", "Last Layer", 3, "rare", IF({"printer_at_most": 10}, E("heal", "If your Printer has 10 Health or less, repair it by 8.", n=8, to="own_printer")))
T("team_build", "Team Build", 3, "uncommon", IF({"allies_at_least": 3}, E("buff", "If you have 3 or more prints, give them all +1/+1.", atk=1, hp=1, to="friendly_prints")))
T("sacrificial_layer", "Sacrificial Layer", 1, "uncommon", E("sacrifice", "Scrap your weakest print to draw 2 cards.", then=[{"op": "draw", "n": 2}]))
T("tribute_kiln", "Tribute Kiln", 2, "rare", E("sacrifice", "Scrap your weakest print to deal 5 damage to the enemy Printer.",
                                                 then=[{"op": "damage", "n": 5, "to": "enemy_printer"}]))
T("field_calibration", "Field Calibration", 3, "uncommon", E("cleanse", "Cleanse your prints", to="friendly_prints"), E("buff", "and give them +1 Attack.", atk=1, hp=0, to="friendly_prints"))
T("lucky_spool", "Lucky Spool", 1, "common", E("tutor", "Take a print from your deck into your hand.", kind="creature"))
T("toolbox", "Toolbox", 2, "common", E("tutor", "Take a tool from your deck into your hand", kind="tool"), E("spool", "and add 2 Filament to your Spool.", n=2))
T("reinforcement_ribs", "Reinforcement Ribs", 2, "common", PER("enemies", E("buff", "Give a friendly print +0/+2 for each enemy print.", "friendly_print", atk=0, hp=2, to="target")))
T("overcharge", "Overcharge", 3, "rare", E("buff", "Give a friendly print +3 Attack and Twin Nozzle,", "friendly_print", atk=3, hp=0, kw=["twin"], to="target"),
  E("damage", "then deal 2 damage to it.", n=2, to="target"))
T("echo_print", "Echo Print", 4, "rare", E("give_copy", "Add a copy of a friendly print's card to your hand.", "friendly_print", to="target"))
T("gravity_well", "Gravity Well", 4, "uncommon", E("damage", "Deal 3 damage to the strongest enemy print", n=3, to="strongest_enemy"),
  E("damage", "and 3 to the weakest.", n=3, to="weakest_enemy"))
T("mass_production", "Mass Production", 6, "legendary", PER("empty", E("summon", "Fill every empty spot on your bench with a 1/1 Test Bot.", n=1, card="test_bot")))
T("data_overload", "Data Overload", 5, "epic", PER("foe_hand", E("damage", "Deal 1 damage to the enemy Printer for each card in your opponent's hand.", n=1, to="enemy_printer")))
T("resin_bath", "Resin Bath", 3, "uncommon", E("heal", "Fully repair all your prints.", n=99, to="friendly_prints"))
T("poison_dart", "Poison Dart", 1, "common", E("poison", "Poison an enemy print", "enemy_print", to="target"), E("damage", "and deal 1 damage to it.", n=1, to="target"))
T("weathering", "Weathering", 4, "rare", PER("tools", E("damage", "Deal 1 damage to all enemy prints for each tool you used this turn, this one too.", n=1, to="enemy_prints")))
T("final_countdown", "Final Countdown", 7, "legendary", E("destroy", "Destroy every print", to="all_prints"), E("draw", "and draw 2 cards.", n=2))
T("print_duel", "Print Duel", 2, "uncommon", E("damage", "Deal 1 damage to an enemy print for each print you have.", "enemy_print", n=1, to="target", per="allies"))

# =============================================================== EQUIPMENT

U("spiked_bumper", "Spiked Bumper", 1, "common", 1, 0, text="When it is hurt, deal 1 damage to the enemy Printer.",
  grant=[trig("hurt", E("damage", "", n=1, to="enemy_printer"))])
U("lucky_keychain", "Lucky Keychain", 1, "common", 0, 1, text="When it is destroyed, draw a card.",
  grant=[trig("shatter", E("draw", "", n=1))])
U("rocket_boots", "Rocket Boots", 2, "uncommon", 1, 1, ["rush", "hover"])
U("leech_nozzle", "Leech Nozzle", 2, "common", 1, 0, text="On Kill: Repair your Printer by 3.",
  grant=[trig("kill", E("heal", "", n=3, to="own_printer"))])
U("thermal_camera", "Thermal Camera", 2, "uncommon", 1, 1, text="On Attack: Heat the print it hits.",
  grant=[trig("attack", E("heat", "", n=2, to="trigger"))])
U("toxic_tip", "Toxic Tip", 2, "uncommon", 1, 0, text="On Attack: Poison the print it hits.",
  grant=[trig("attack", E("poison", "", to="trigger"))])
U("mirror_plating", "Mirror Plating", 3, "rare", 0, 3, text="When it is hurt, deal 2 damage to a random enemy print.",
  grant=[trig("hurt", E("damage", "", n=2, to="random_enemy"))])
U("growth_serum", "Growth Serum Tank", 3, "rare", 0, 0, text="At the start of your turn it gets +1/+1.",
  grant=[trig("turn_start", E("buff", "", atk=1, hp=1, to="self"))])
U("scrap_magnet", "Scrap Magnet", 2, "uncommon", 1, 1, text="Whenever an enemy print is destroyed, it gets +1 Attack.",
  grant=[trig("foe_shatter", E("buff", "", atk=1, hp=0, to="self"))])
U("signal_booster", "Signal Booster", 3, "rare", 0, 2, text="Whenever another of your prints attacks, give the attacker +1/+1.",
  grant=[trig("ally_attack", E("buff", "", atk=1, hp=1, to="trigger"))])
U("ward_rune", "Ward Rune", 2, "uncommon", 0, 1, ["ward", "cloak"])
U("berserker_chip", "Berserker Chip", 3, "rare", 2, 0, text="On Kill: It can attack again.",
  grant=[trig("kill", E("refresh", "", to="self"))])
U("snap_jaws", "Snap Jaws", 4, "epic", 1, 0, ["snap"])
U("quickdraw_holster", "Quick-Draw Holster", 2, "uncommon", 1, 0, ["quick"])
U("overflow_valve", "Overflow Valve", 3, "uncommon", 2, 0, ["overflow"])
U("reprint_backup", "Reprint Backup", 3, "rare", 0, 1, ["reprint"])
U("menace_mask", "Menace Mask", 2, "common", 1, 1, ["menace"])
U("turret_mount", "Turret Mount", 4, "rare", 0, 2, text="At the end of your turn, deal 2 damage to a random enemy print.",
  grant=[trig("turn_end", E("damage", "", n=2, to="random_enemy"))])
U("healing_halo", "Healing Halo", 3, "uncommon", 0, 2, text="At the end of your turn, repair your other prints by 1.",
  grant=[trig("turn_end", E("heal", "", n=1, to="other_friendly_prints"))])
U("battery_pack", "Battery Pack", 2, "common", 0, 1, text="At the start of your turn, +1 Print Speed.",
  grant=[trig("turn_start", E("filament", "", n=1))])
U("rally_banner", "Rally Banner", 3, "uncommon", 1, 1, text="When you fit it, give all your prints +1 Attack.",
  effects=[E("buff", "", atk=1, hp=0, to="friendly_prints")])
U("golden_spool_crown", "Golden Spool Crown", 5, "legendary", 3, 3, text="At the start of your turn, draw a card.",
  grant=[trig("turn_start", E("draw", "", n=1))])
U("dragon_scale_mail", "Dragon Scale Mail", 5, "epic", 2, 5, ["guard"], text="When your Printer is hit, your Printer gains 1 Armor.",
  grant=[trig("printer_hit", E("armor", "", n=1))])
U("thruster_pack", "Thruster Pack", 2, "common", 2, 0, ["hover"])
U("cursed_gear", "Cursed Gear", 1, "rare", 3, 3, text="At the end of your turn it takes 2 damage.",
  grant=[trig("turn_end", E("damage", "", n=2, to="self"))])
U("silence_emitter", "Silence Emitter", 3, "rare", 0, 2, text="On Attack: Silence the print it hits.",
  grant=[trig("attack", E("silence", "", to="trigger"))])
U("tribe_totem", "Swarm Totem", 2, "uncommon", 1, 1, text="When you fit it, give all your Swarmlings +1/+1.",
  effects=[E("buff", "", atk=1, hp=1, to="tribe:swarm")])


# =============================================================== MYTHICAL
# Dragons, unicorns and the beasts of legend, each with a move of its own.

def M(cid, name, element, cost, a, h, rarity, kw, fx, **art):
    K(cid, name, element, cost, a, h, rarity, kw, fx, art=art)


M("ember_dragon", "Ember Dragon", F, 7, 6, 6, "epic", ["hover"],
  ability(ON("attack", E("heat", "Breathe fire: Heat all enemy prints.", n=2, to="enemy_prints"))), plan="dragon")
M("tidal_dragon", "Tidal Dragon", W, 7, 5, 7, "epic", ["hover"],
  ability(ON("turn_end", E("heal", "Repair your Printer by 3", n=3, to="own_printer"), E("cleanse", "and Cleanse your prints.", to="friendly_prints"))), plan="dragon")
M("storm_dragon", "Storm Dragon", L, 7, 6, 5, "epic", ["hover"],
  ability(E("chain", "Lightning: 4 damage to a random enemy print, then 3, 2 and 1 to others.", n=4)), plan="dragon")
M("verdant_dragon", "Verdant Dragon", N, 7, 5, 7, "epic", ["hover"],
  ability(E("heal", "Fully repair your prints", n=99, to="friendly_prints"), E("buff", "and give them Hover.", atk=0, hp=0, kw=["hover"], to="friendly_prints")), plan="dragon")
M("glacier_dragon", "Glacier Dragon", I, 8, 6, 8, "legendary", ["hover"],
  ability(ON("attack", E("sleep", "Freeze the print it hits: it sleeps for 2 turns.", n=2, to="trigger"))), plan="dragon")
M("obsidian_dragon", "Obsidian Dragon", S, 8, 7, 8, "legendary", ["hover"],
  ability(ON("printer_hit", E("damage", "Deal 3 damage to the enemy Printer.", n=3, to="enemy_printer"))), plan="dragon")
M("tempest_dragon", "Tempest Dragon", D, 7, 5, 6, "epic", ["hover", "twin"],
  ability(ON("kill", E("bounce", "Blow the strongest enemy print back to its owner's hand.", to="strongest_enemy"))), plan="dragon")
M("void_dragon", "Void Dragon", A, 9, 7, 7, "legendary", ["hover"],
  ability(E("silence", "Silence all enemy prints", to="enemy_prints"), E("drain_spool", "and steal 5 Filament from their Spool.", n=5)), plan="dragon")
M("fairy_dragon", "Fairy Dragon", A, 2, 1, 2, "uncommon", ["hover"],
  ability(E("buff", "Give a friendly print Hover and Ward.", "friendly_print", atk=0, hp=0, kw=["hover", "ward"], to="target")), plan="dragon", small=True)
M("wyvern_rider", "Wyvern Rider", D, 4, 3, 3, "uncommon", ["hover"],
  ability(ON("attack", E("buff", "Give a random friendly print +1/+1.", atk=1, hp=1, to="random_friendly"))), plan="dragon", small=True)
M("dragon_egg", "Dragon Egg", F, 2, 0, 4, "rare", [], evolves("dragon_hatchling", "Dragon Hatchling", 3), plan="egg")
M("dragon_hatchling", "Dragon Hatchling", F, 4, 3, 3, "rare", ["hover"], evolves("elder_wyrm", "Elder Wyrm", 3), plan="dragon", small=True, stage=2)
M("elder_wyrm", "Elder Wyrm", F, 9, 8, 8, "legendary", ["hover"],
  ability(ON("attack", E("damage", "Deal 2 damage to all enemy prints.", n=2, to="enemy_prints"))), plan="dragon", stage=3)

M("unicorn_foal", "Unicorn Foal", A, 2, 1, 3, "uncommon", [], evolves("unicorn", "Unicorn", 2), plan="horse", horn=True, foal=True, stage=1)
M("unicorn", "Unicorn", A, 5, 4, 5, "rare", [],
  dict(evolves("alicorn", "Alicorn", 3, ability(ON("turn_start", E("cleanse", "Cleanse your prints", to="friendly_prints"), E("heal", "and repair them by 1.", n=1, to="friendly_prints"))))),
  plan="horse", horn=True, stage=2)
M("alicorn", "Alicorn", A, 8, 6, 7, "legendary", ["hover", "ward"],
  ability(ON("turn_start", E("heal", "Repair your Printer by 3", n=3, to="own_printer"), E("buff", "and give your prints +1/+1.", atk=1, hp=1, to="friendly_prints"))),
  plan="horse", horn=True, wings=True, stage=3)
M("moonlight_unicorn", "Moonlight Unicorn", A, 5, 4, 5, "rare", [],
  ability(E("heal", "Fully repair your prints", n=99, to="friendly_prints"), E("cleanse", "and Cleanse them.", to="friendly_prints")), plan="horse", horn=True)
M("rainbow_unicorn", "Rainbow Unicorn", X, 6, 5, 5, "epic", [],
  ability(PER("elements", E("buff", "Give your prints +1/+1 for each different element among them.", atk=1, hp=1, to="friendly_prints"))),
  plan="horse", horn=True, rainbow=True)
M("pegasus_courier", "Pegasus Courier", D, 3, 2, 3, "uncommon", ["hover"],
  ability(ON("turn_end", E("buff", "Give a random friendly print Hover.", atk=0, hp=0, kw=["hover"], to="random_friendly"))), plan="horse", wings=True)
M("shadow_mare", "Shadow Mare", A, 4, 3, 4, "rare", [],
  ability(ON("attack", E("discard", "Your opponent throws away a random card.", n=1))), plan="horse", pale=False)
M("kelpie", "Kelpie", W, 3, 3, 2, "uncommon", [],
  ability(ON("attack", E("bounce", "Drag the print it hits back to its owner's hand if it has 2 Attack or less.", max_atk=2, to="trigger"))), plan="horse", pale=False)
M("thunder_kirin", "Thunder Kirin", L, 6, 5, 5, "epic", [],
  ability(E("buff", "Give all your prints Rush.", atk=0, hp=0, kw=["rush"], to="friendly_prints")), plan="horse", horn=True, pale=False)

M("griffin_knight", "Griffin Knight", D, 5, 4, 4, "rare", ["hover"],
  ability(E("buff", "Give a friendly print Hover and +2 Attack.", "friendly_print", atk=2, hp=0, kw=["hover"], to="target")), plan="beast", beast="griffin")
M("sunfire_phoenix", "Sunfire Phoenix", F, 6, 5, 4, "legendary", ["hover", "reprint"],
  ability(ON("turn_end", E("heal", "It rises from its ashes: fully repair it.", n=99, to="self"))), plan="phoenix")
M("cerberus", "Cerberus", F, 5, 2, 5, "rare", ["triple"],
  ability(ON("kill", E("heat", "Heat a random enemy print.", n=2, to="random_enemy"))), plan="beast", beast="cerberus")
M("spool_hydra", "Spool Hydra", W, 7, 4, 7, "epic", [],
  ability(ON("hurt", E("summon", "Grow a 1/1 Hydra Head beside it.", n=1, card="hydra_head"))), plan="hydra", heads=3)
M("hydra_head", "Hydra Head", W, 1, 1, 1, "common", [], {"text": "", "target": "", "on_print": [], "shatter": []}, plan="serpent")
M("kitsune", "Kitsune", A, 4, 3, 3, "rare", ["cloak"],
  ability(PER("hand", E("buff", "Gets +1/+1 for each card in your hand (up to 4).", atk=1, hp=1, to="self"), cap=4),
          ON("turn_end", E("buff", "It hides again with Cloak.", atk=0, hp=0, kw=["cloak"], to="self"))), plan="beast", beast="kitsune", tails=7)
M("kraken", "Kraken", W, 9, 6, 9, "legendary", [],
  ability(E("take", "Pull the strongest enemy print onto your side for good.", to="strongest_enemy")), plan="kraken")
M("chimera", "Chimera", F, 6, 5, 5, "epic", [],
  ability(ON("attack", E("heat", "Heat,", n=2, to="trigger"), E("poison", "Poison", to="trigger"), E("jam", "and Jam the print it hits.", to="trigger"))), plan="beast", beast="chimera")
M("manticore", "Manticore", S, 5, 3, 4, "rare", ["snap"],
  ability(PER("enemies", E("buff", "Gets +1 Attack for each enemy print.", atk=1, hp=0, to="self"))), plan="beast", beast="manticore")
M("minotaur", "Minotaur", S, 5, 5, 5, "rare", ["menace", "overflow"],
  ability(E("buff", "Give your other Stone prints Menace.", atk=0, hp=0, kw=["menace"], to="element:Stone")), plan="biped", bull=True)
M("cyclops", "Cyclops", S, 4, 5, 5, "uncommon", [],
  ability(E("destroy_if", "Knock an enemy print with Hover out of the sky: destroy it.", "enemy_print", has_kw="hover", to="target")), plan="biped", cyclops=True)
M("sphinx", "Sphinx", A, 6, 4, 6, "epic", [],
  ability(ON("turn_start", IF({"foe_hand_more": True}, E("discard", "If your opponent has more cards than you, they throw one away.", n=1)))), plan="beast", beast="sphinx")
M("basilisk", "Basilisk", N, 5, 3, 5, "rare", [],
  ability(E("destroy", "Its gaze turns the weakest enemy print to stone: destroy it.", to="weakest_enemy")), plan="serpent")
M("leviathan", "Leviathan", W, 9, 8, 10, "legendary", [],
  ability(E("swap", "Swap the Attack and Health of every enemy print.", to="enemy_prints")), plan="serpent")
M("thunderbird", "Thunderbird", L, 6, 5, 4, "epic", ["hover"],
  ability(ON("printer_hit", E("chain", "Lightning: 2 damage to a random enemy print, then 1 to another.", n=2))), plan="phoenix")
M("yeti", "Yeti", I, 5, 4, 6, "rare", [],
  ability(ON("foe_attack", E("sleep", "Put the attacker to sleep for 2 turns.", n=2, to="trigger"))), plan="biped")

for t in ("dragon_hatchling", "elder_wyrm", "unicorn", "alicorn", "hydra_head"):
    token(t)

# Wave-6 creatures whose names promise a legend get the matching body.
_LEGEND_LOOKS = {"scorch_wyrmling": {"plan": "dragon", "small": True}, "frost_wyvern": {"plan": "dragon"},
                 "kite_drake": {"plan": "dragon", "small": True}, "blaze_matriarch": {"plan": "dragon"},
                 "plasma_pegasus": {"plan": "horse", "wings": True, "pale": False}, "ashling": {"plan": "phoenix"},
                 "overgrowth_hydra": {"plan": "hydra", "heads": 5}, "storm_roc": {"plan": "phoenix"},
                 "statue_gargoyle": {"plan": "beast", "beast": "griffin"}, "ice_queen_moth": {"plan": "bug"}}
for c in CREATURES:
    if c["id"] in _LEGEND_LOOKS and "look" in c:
        c["look"].update(_LEGEND_LOOKS[c["id"]])


# ============================================== older cards made their own
# Before wave 6 several cards did exactly the same thing (six of them just
# jammed a print on arrival). Each now keeps its body and stats but gets an
# ability no other card has.

def _rework(cid, parts=None, kind="creature", text=None, buff=None, grant=None, kw=None, target_max_atk=None):
    rows = {"creature": CREATURES, "tool": TOOLS, "upgrade": UPGRADES}[kind]
    for c in rows:
        if c["id"] != cid:
            continue
        if kind == "creature":
            fx = ability(*parts)
            for k in ("on_print", "shatter", "trig", "target"):
                c.pop(k, None)
            c.update(fx)
        elif kind == "tool":
            for k in ("effects", "target"):
                c.pop(k, None)
            c.update(tool_effect(*parts))
        else:
            c["buff"] = buff
            c["text"] = text
            if grant:
                c["grant"] = grant
        if kw is not None:
            c["kw"] = kw
        if target_max_atk is not None:
            c["target_max_atk"] = target_max_atk
        return
    raise KeyError(cid)


_rework("wispling", [PER("hand", E("heal", "Repair your Printer by 1 for each card in your hand (up to 4).", n=1, to="own_printer"), cap=4)])
_rework("hexcat", [PER("tools", E("filament", "+1 Print Speed this turn for each tool you have used this turn.", n=1))])
_rework("jolthare", [IF({"printer_damaged": True}, E("filament", "If your Printer is damaged, +2 Print Speed this turn.", n=2))])
_rework("zephyrfinch", [E("filament", "+1 Print Speed this turn,", n=1), IF({"hand_at_most": 2}, E("draw", "and draw a card if you have 2 or fewer cards.", n=1))])
_rework("mushmunk", [E("heal", "Repair your Printer by 2", n=2, to="own_printer"), E("cleanse", "and Cleanse your prints.", to="friendly_prints")])
_rework("cindermoth", [E("heat", "Heat every damaged enemy print.", n=2, to="damaged_enemies")])
_rework("icehare", [E("jam", "Jam an enemy print", "enemy_print", to="target"), E("draw", "and draw a card.", n=1)])
_rework("spaghettimess", [E("jam", "Jam an enemy print", "enemy_print", to="target"), E("poison", "and Poison it.", to="target")])
_rework("chillfan", [E("jam", "Jam the strongest enemy print.", to="strongest_enemy")])
_rework("overcharger", [E("jam", "Jam an enemy print", "enemy_print", to="target"), E("buff", "and give your prints +1 Attack.", atk=1, hp=0, to="friendly_prints")])
_rework("leafmite", [E("heal", "Repair a friendly print by 2", "friendly_print", n=2, to="target"), E("buff", "and give it +0/+1.", atk=0, hp=1, to="target")])
_rework("puddlepup", [E("heal", "Repair all your prints by 1.", n=1, to="friendly_prints")])
_rework("tideotter", [IF({"hand_at_most": 4}, E("draw", "Draw a card if you have 4 or fewer cards in hand.", n=1)), E("buff", "Gets +0/+1.", atk=0, hp=1, to="self")])
_rework("fusefox", [IF({"allies_at_least": 3}, E("draw", "If you have 3 or more prints, draw 2 cards.", n=2))])
_rework("canopyowl", [E("tutor", "Take a print costing 3 or less from your deck into your hand.", kind="creature", max_cost=3)])
_rework("layershifter", [E("draw", "Draw a card", n=1), E("discard", "and your opponent throws away a random card.", n=1)])
_rework("sigilowl", [E("draw", "Draw a card", n=1), E("silence", "and Silence an enemy print.", "enemy_print", to="target")])
_rework("thermochameleon", [E("heat", "Heat all enemy prints", n=2, to="enemy_prints"), E("buff", "and take on +1 Attack for each of them.", atk=1, hp=0, to="self", per="enemies")])
_rework("galemoth", [E("bounce", "Blow back an enemy print", "enemy_print", to="target"), E("draw", "and draw a card.", n=1)])
_rework("squallmaw", [E("bounce", "Blow back an enemy print", "enemy_print", to="target"), E("damage", "and deal 2 damage to the enemy Printer.", n=2, to="enemy_printer")])
_rework("undertow", [E("bounce", "Blow every enemy print with 2 Attack or less back to its owner's hand.", max_atk=2, to="enemy_prints")])
_rework("blizzardowl", [E("jam", "Jam all enemy prints", to="enemy_prints"), E("buff", "and give your prints +0/+2.", atk=0, hp=2, to="friendly_prints")])
_rework("tsunamiray", [E("jam", "Jam all enemy prints", to="enemy_prints"), E("heal", "and repair your Printer by 3.", n=3, to="own_printer")])
_rework("chillwhale", [E("jam", "Jam an enemy print", "enemy_print", to="target"), E("armor", "and your Printer gains 3 Armor.", n=3)])
_rework("furnacedrake", [E("damage", "Deal 2 damage to all enemy prints", n=2, to="enemy_prints"), E("heat", "and Heat them.", n=2, to="enemy_prints")])
_rework("phoenixfilament", [SH(E("damage", "Deal 3 damage to all enemy prints", n=3, to="enemy_prints")), SH(E("give", "and return to your hand.", card="phoenixfilament"))])
_rework("titanminer", [E("damage", "Deal 3 damage to an enemy print", "enemy_print", n=3, to="target"), E("armor", "and your Printer gains 3 Armor.", n=3)])
_rework("voidwyrm", [E("destroy", "Destroy the strongest enemy print", to="strongest_enemy"), E("destroy", "and the weakest one.", to="weakest_enemy")])

_rework("cutting_mat", [PER("enemies", E("armor", "Your Printer gains 2 Armor for each enemy print (up to 6).", n=2), cap=3)], kind="tool")
_rework("digital_scale", [PER("enemies", E("draw", "Draw a card for each enemy print (up to 3).", n=1), cap=3)], kind="tool")
_rework("glow_filament", [E("buff", "Give your prints +1/+1", atk=1, hp=1, to="friendly_prints"), E("cleanse", "and Cleanse them.", to="friendly_prints")], kind="tool")
_rework("fire_extinguisher", [E("jam", "Jam all enemy prints", to="enemy_prints"), E("cleanse", "and Cleanse yours.", to="friendly_prints")], kind="tool")
_rework("flush_cutters", [E("destroy", "Destroy an enemy print with 4 Attack or less.", "enemy_print", to="target")], kind="tool", target_max_atk=4)
_rework("bulk_order", [E("draw", "Draw 3 cards", n=3), E("spool", "and add 5 Filament to your Spool.", n=5)], kind="tool")

_rework("belt_tensioner", kind="upgrade", buff={"atk": 0, "hp": 2, "kw": []},
        text="Give a friendly print +0/+2. On Attack: It gets +1 Attack.", grant=[trig("attack", E("buff", "", atk=1, hp=0, to="self"))])
_rework("grappling_hook", kind="upgrade", buff={"atk": 1, "hp": 1, "kw": ["thief"]},
        text="Give a friendly print +1/+1 and Filament Thief. On Kill: Draw a card.", grant=[trig("kill", E("draw", "", n=1))])
_rework("carbon_plate", kind="upgrade", buff={"atk": 1, "hp": 4, "kw": []},
        text="Give a friendly print +1/+4. When your Printer is hit, it gets +1 Attack.", grant=[trig("printer_hit", E("buff", "", atk=1, hp=0, to="self"))])
_rework("turbo_fan", kind="upgrade", buff={"atk": 1, "hp": 1, "kw": ["rush"]},
        text="Give a friendly print +1/+1 and Rush. On Attack: Jam the print it hits.", grant=[trig("attack", E("jam", "", to="trigger"))])
_rework("direct_drive_gearbox", kind="upgrade", buff={"atk": 2, "hp": 3, "kw": []},
        text="Give a friendly print +2/+3. At the start of your turn, +2 Print Speed.", grant=[trig("turn_start", E("filament", "", n=2))])

for c in CREATURES:
    if c["id"] == "pebble_golemite":
        c.update(ability(PER("element:Stone", E("armor", "Your Printer gains 2 Armor for each Stone print you have.", n=2))))


# ============================================================ one of each
# Only one card per picture and one per ability. Plain recolours of a painted
# body are retired (the painted original stays); recolours that carry an
# ability built for them get a body of their own instead (see LOOK_FOR below).
# Players who owned a retired card are paid for it (Profile._sanitize).

RETIRE_LOOKALIKES = """emberling sootsprite forgefinch wickfox cindermoth slagrhino blazehound furnacedrake phoenixfilament cinderwyrm
dewdrop puddlepup tideotter pearlback kelpwyrm undertow tsunamiray leviathanvat jolthare fusefox amperfinch gigahertz arcflicker
overcharger surgebeast stormcoil leafmite petalfawn canopyowl rootstag greenwarden worldroot frostbite icehare permafrost hailstorm
shivercat chillwhale blizzardowl cryowyrm slatehound quarrymole geodefox titanminer mountainwyrm slipstream zephyrfinch galemoth
squallmaw vortexray tempestforge wispling hexcat sigilowl hexstag sigilsmith cosmicray oracledrake voidwyrm""".split()

RETIRED = {}


def retire(ids):
    for rows in (CREATURES, TOOLS, UPGRADES):
        keep = []
        for c in rows:
            if c["id"] in ids:
                RETIRED[c["id"]] = c["rarity"]
            else:
                keep.append(c)
        rows[:] = keep


retire(set(RETIRE_LOOKALIKES))


# Cards whose ability was the same as another card's (only the numbers
# differed). One of each stays.
RETIRE_SAME_ABILITY = """bubblepip fine_tweezers needle_pliers plasma_cutter quartzdrake gravel_gremlin thermal_runaway linear_rails lead_screw_lance wing_kit masking_tape cubecrab pebblefin master_blueprint rubber_feet mega_spool torque_wrench bowden_whip cable_chain spool_holder servo_arms nozzle_guard glass_bed_shield scale_mail exo_frame cinderowl desiccant_packs dry_box resin_bath soldering_iron flush_cutters gigavolt_golem coilcobra heat_sink glassserpent enclosure_panels hexnuthog overdrive_chip spool_twin gcodegolem soldering_station spoolsnail spoolshell surge_seal thornfox laser_engraver""".split()
retire(set(RETIRE_SAME_ABILITY))
import json as _json, os as _os
RETIRED.update(_json.load(open(_os.path.join(_os.path.dirname(__file__), "retired_base.json"))))

# Duplicates the game itself leans on get an ability of their own instead.
_rework("nautilark", [ON("turn_start", E("buff", "It gets Brim again.", atk=0, hp=0, kw=["brim"], to="self"))])
_rework("benchyboss", [E("heal", "Repair your Printer by 3", n=3, to="own_printer"), E("summon", "and print a 1/1 Test Bot.", n=1, card="test_bot")])


# =========================================================== new bodies
# The recolours that kept their ability each get a hybrid body of their own
# (tools/render_art8.gd): a frame, a head, a lower body, extras and a
# two-tone filament.

def H(frame, head, extras=(), colors=(), lower="", heads=1, scale=1.0):
    return {"plan": "hybrid", "frame": frame, "head": head, "extras": list(extras), "colors": list(colors), "lower": lower,
            "heads": heads, "scale": scale}


REBODY = {
    "kilnpup": H("quad", "fox", ["flame_mane", "gears"], ["c8402a", "ffb347", "b87333", "ff8a2a"]),
    "lavalynx": H("quad", "lion", ["spikes", "armor", "core", "flame_mane"], ["2b2f3a", "e8492e", "d9773a", "ff8a2a"]),
    "bubbleray": H("kraken", "owl", [], ["3a8ee8", "bfe9ff", "c7ced6", "6ad8ff"]),
    "reefhopper": H("crawler", "bug", ["spikes"], ["ff7a6a", "ffd0c0", "e9a91c", "ffb0a0"], "insect"),
    "mistwalker": H("biped", "owl", ["feather_wings"], ["9fc8e8", "f2f6f8", "c0c8d0", "d8f0ff"], "bird"),
    "siphonshark": H("wyrm", "serpent", ["spikes"], ["3a6a9a", "dfe8f0", "b9c2cc", "6ad8ff"], heads=1),
    "brineleech": H("kraken", "serpent", [], ["2a6a5a", "8fd8c0", "d9773a", "8be04a"]),
    "zapkit": H("quad", "fox", ["spikes", "coil_spine"], ["ffcf2e", "2b2f3a", "b87333", "fff27a"]),
    "staticcub": H("quad", "lion", ["spikes"], ["f0c030", "4a3a8a", "c7ced6", "9fe0ff"]),
    "sparkbug": H("crawler", "bug", ["bug_wings"], ["ffd23a", "1b1b24", "c7ced6", "fff27a"], "insect"),
    "capacitor": H("rover", "robot", ["coil_spine", "solar"], ["3a3f4a", "ffcf2e", "b87333", "5fe6ff"]),
    "gridstag": H("quad", "stag", ["armor", "core", "gears"], ["2b2f3a", "5fe6ff", "c7ced6", "9fe0ff"]),
    "sproutling": H("quad", "dog", ["antlers"], ["6abf4a", "a87a4a", "ff8fc0", "b6ff6a"], scale=0.85),
    "barkback": H("quad", "bull", ["armor"], ["7a5a3a", "56b84a", "a87a4a", "b6ff6a"]),
    "mushmunk": H("taur", "owl", [], ["d84a4a", "f4efe0", "8a5a32", "ffd0d0"], "lion", scale=0.9),
    "seedpup": H("quad", "dog", [], ["8ac04a", "f4e0a0", "a87a4a", "d0ff8a"], scale=0.85),
    "vinehare": H("quad", "fox", ["snake_tail"], ["56b84a", "2a6a3a", "b87333", "b6ff6a"]),
    "bramblemaw": H("quad", "lion", ["spikes", "ram_horns"], ["4a6a2a", "8a2a4a", "8a6a4a", "c0ff6a"]),
    "snowmite": H("crawler", "bug", ["spikes"], ["bfe9ff", "f4fbff", "8f8cf0", "c8f2ff"], "insect", scale=0.85),
    "slushpup": H("quad", "dog", ["spikes"], ["8fc8f0", "f4fbff", "c0c8d0", "c8f2ff"]),
    "rimefox": H("quad", "fox", ["nine_tails"], ["e8f4ff", "9fdcff", "c0c8d0", "bff0ff"]),
    "snowdrift": H("biped", "owl", ["feather_wings"], ["f4fbff", "9fdcff", "c0c8d0", "c8f2ff"], "bird"),
    "rimestag": H("quad", "stag", ["mask", "feather_wings"], ["eaf2ff", "a0d0f0", "ffcf3a", "c8f2ff"]),
    "glaciermaw": H("wyrm", "serpent", ["spikes"], ["7ab8e8", "eaf6ff", "8f8cf0", "c8f2ff"], heads=2),
    "pebblepup": H("quad", "dog", ["armor"], ["8d8a86", "c9c2b8", "e9a91c", "ffb84a"], scale=0.85),
    "gravelhopper": H("crawler", "rock", [], ["7a7068", "a89888", "b87333", "ffb84a"], "rock"),
    "cairncrab": H("crawler", "bug", ["armor"], ["9a8a7a", "d8c8b8", "e9a91c", "ffb84a"], "insect"),
    "sandpiper": H("biped", "eagle", ["feather_wings"], ["d8c08a", "f4efe0", "b87333", "ffd36a"], "bird"),
    "basaltbison": H("quad", "bull", ["armor", "gears"], ["3a3a3e", "8a6a4a", "d9773a", "ff8a2a"]),
    "obsidianray": H("kraken", "skull", [], ["1a1a24", "4a2a6a", "c0c0d0", "c46aff"]),
    "monolith": H("biped", "rock", ["core"], ["5a5a60", "8a8a90", "e9a91c", "5fe6ff"], "rock"),
    "granitegriffin": H("quad", "eagle", ["feather_wings", "armor"], ["8d8a86", "f4efe0", "e9a91c", "ffb84a"]),
    "breezepup": H("quad", "dog", ["feather_wings"], ["9fe8d0", "f2f6f8", "7fb8ff", "c6fff0"], scale=0.85),
    "gustkit": H("quad", "fox", ["bug_wings"], ["7fe0c4", "f2f6f8", "c7ced6", "c6fff0"], scale=0.85),
    "cloudhopper": H("biped", "owl", ["feather_wings"], ["eef4f8", "a8d8f0", "c7ced6", "ffffff"], "bird", scale=0.85),
    "pinfeather": H("biped", "eagle", ["feather_wings", "gold_feathers"], ["4a8ac0", "f2f6f8", "e9a91c", "c6fff0"], "bird"),
    "swiftwhip": H("wyrm", "serpent", ["bat_wings"], ["4ad0a0", "f2f6f8", "c7ced6", "c6fff0"], heads=1, scale=0.85),
    "skyhawk": H("quad", "horse", ["feather_wings"], ["7fb8ff", "f2f6f8", "e9a91c", "c6fff0"]),
    "tempestlynx": H("quad", "lion", ["bat_wings", "segment_tail"], ["5aa0a0", "2b2f3a", "c7ced6", "c6fff0"]),
    "stormdrake": H("wyrm", "serpent", ["bat_wings", "spikes"], ["3a8a9a", "dfe8f0", "c7ced6", "9fe0ff"], heads=1),
    "runemite": H("crawler", "bug", ["crown"], ["8a55f0", "e05ad8", "ffcf3a", "c9a0ff"], "insect", scale=0.8),
    "glyphhare": H("quad", "fox", ["mask"], ["c070f0", "f0e0ff", "ffcf3a", "e0b0ff"]),
    "voidmoth": H("biped", "bug", ["bug_wings"], ["4a2a6a", "1a1030", "ffcf3a", "c46aff"], "bird"),
    "chronocat": H("quad", "lion", ["gears", "coil_spine", "core"], ["8a6af0", "2b2f3a", "e9a91c", "c9a0ff"]),
}
for c in CREATURES:
    if c["id"] in REBODY:
        c["art"] = "gen"
        lk = dict(REBODY[c["id"]])
        lk["seed"] = zlib.crc32(c["id"].encode()) & 0xffffff
        lk["element"] = c["element"]
        c["look"] = lk


# ======================================================= HYBRIDS OF LEGEND
# Several legends in one print, as a maker would build them.

def HY(cid, name, element, cost, a, h, rarity, kw, fx, look):
    K(cid, name, element, cost, a, h, rarity, kw, fx, plan="hybrid", art={k: v for k, v in look.items() if k != "plan"})


HY("scarab_medusa", "Scarab Medusa", A, 6, 4, 6, "epic", [],
   ability(E("sleep", "Its gaze turns the strongest enemy print to stone: it sleeps for 2 turns", n=2, to="strongest_enemy"),
           E("buff", "and loses 2 Attack.", atk=-2, hp=0, to="strongest_enemy")),
   H("taur", "medusa", ["gears"], ["5a2a7a", "1f7a5a", "c9a227", "8be04a"], "scarab"))
HY("pyre_griffin", "Pyre Griffin", F, 6, 5, 5, "epic", ["hover"],
   ability(ON("turn_start", E("heat", "Heat a random enemy print", n=2, to="random_enemy"), E("buff", "and it gets +1 Attack.", atk=1, hp=0, to="self"))),
   H("quad", "eagle", ["feather_wings", "armor", "core", "gold_feathers"], ["b8282a", "ffb347", "c9a227", "ff8a2a"]))
HY("scylla_kraken", "Scylla Kraken", W, 8, 6, 8, "legendary", [],
   ability(ON("foe_attack", E("damage", "Bite the attacker for 2", n=2, to="trigger"), E("jam", "and Jam it.", to="trigger"))),
   H("kraken", "serpent", [], ["2b2f4a", "8a4ad8", "8a8a9a", "c49aff"]))
HY("anubis_harpy", "Anubis Harpy", A, 5, 4, 4, "rare", ["hover"],
   ability(ON("foe_shatter", E("draw", "Draw a card.", n=1))),
   H("biped", "jackal", ["feather_wings", "gold_feathers", "segment_tail"], ["17171c", "2b2b30", "d4a72c", "ffd36a"], "bird"))
HY("chimera_raiju", "Chimera Raiju", L, 7, 6, 5, "epic", [],
   ability(ON("attack", E("chain", "Lightning leaps from the print it hits: 2, then 1,", n=2), E("poison", "and its snake tail Poisons that print.", to="trigger"))),
   H("quad", "ram", ["spikes", "coil_spine", "snake_tail", "armor"], ["4a4a50", "c8742a", "b87333", "ffe03a"]))
HY("wendigo_sphinx", "Wendigo Sphinx", I, 6, 4, 7, "epic", [],
   ability(ON("turn_start", IF({"foe_hand_more": True}, E("draw", "If your opponent has more cards than you, draw a card.", n=1)))),
   H("quad", "stag", ["mask", "feather_wings"], ["f0ebe0", "d8d0c0", "d4a72c", "fff4c0"]))
HY("pegasus_leviathan", "Pegasus Leviathan", W, 6, 5, 5, "epic", ["hover"],
   ability(PER("element:Water", E("heal", "Repair your Printer by 2 for each Water print you have.", n=2, to="own_printer"))),
   H("seahorse", "horse", ["feather_wings"], ["f0f2f4", "dfe6ec", "c7ced6", "2ab0d8"]))
HY("foo_cerberus", "Foo Cerberus", S, 6, 3, 7, "epic", ["guard", "triple"],
   ability(ON("printer_hit", E("refresh", "It can attack again.", to="self"))),
   H("quad", "lion", ["three_heads", "armor", "glow_claws"], ["3a3a40", "c8ccd0", "9aa0a8", "5fe6ff"]))
HY("quetzal_hydra", "Quetzal Hydra", D, 8, 6, 7, "legendary", ["hover"],
   ability(ON("turn_start", E("buff", "Give your other prints Hover and +1 Attack.", atk=1, hp=0, kw=["hover"], to="other_friendly_prints"))),
   H("wyrm", "serpent", ["feather_wings", "gold_feathers"], ["1f9a8a", "d4a72c", "c9a227", "ff6a4a"], heads=3))
HY("minotaur_kitsune", "Minotaur Kitsune", F, 7, 6, 6, "epic", ["menace"],
   ability(ON("attack", PER("element:Fire", E("buff", "It gets +1 Attack for each of your Fire prints.", atk=1, hp=0, to="self")))),
   H("biped", "bull", ["nine_tails"], ["9a6a3a", "c8884a", "b87333", "ff7a1a"]))
HY("nebula_strider", "Nebula Strider", A, 4, 3, 4, "rare", ["hover"],
   ability(PER("element:Arcane", E("draw", "Draw a card for each Arcane print you have (up to 3).", n=1), cap=3)),
   H("biped", "human", ["bug_wings", "crown"], ["3a5ad8", "8ab8ff", "d4a72c", "c8e0ff"]))
HY("solar_flare_rover", "Solar-Flare Rover", F, 3, 2, 4, "uncommon", [],
   ability(ON("turn_start", IF({"outnumbered": True}, E("spool", "If your opponent has more prints, add 3 Filament to your Spool.", n=3)))),
   H("rover", "robot", ["solar"], ["e8642a", "2b2f3a", "c7ced6", "ffb347"]))
HY("void_stalker", "Void Stalker", A, 4, 4, 3, "rare", ["cloak"],
   ability(ON("kill", E("silence", "Silence a random enemy print.", to="random_enemy"))),
   H("crawler", "bug", ["coil_spine", "spikes"], ["17171c", "6a2ad8", "4a4a50", "b06aff"], "insect"))
HY("asteroid_grubber", "Asteroid Grubber", S, 3, 2, 4, "common", [],
   ability(ON("turn_end", PER("element:Stone", E("armor", "Your Printer gains 1 Armor for each Stone print you have.", n=1)))),
   H("crawler", "rock", [], ["6a5a4a", "8a7a6a", "c7ced6", "ffb84a"], "rock"))
HY("lunar_crawler", "Lunar Crawler", I, 3, 2, 3, "uncommon", [],
   ability(ON("turn_start", E("jam", "Jam the strongest enemy print.", to="strongest_enemy"))),
   H("crawler", "dish", ["gears"], ["b9c2cc", "e0e6ec", "8a929c", "c8f2ff"], "insect"))
HY("nova_burster", "Nova Burster", F, 5, 4, 4, "rare", [],
   ability(SH(E("damage", "Burst: deal 3 damage to every print.", n=3, to="all_prints"))),
   H("biped", "rock", ["spikes", "core"], ["ffb020", "ff6a1a", "c9a227", "fff27a"], "rock"))
HY("starlight_drifter", "Starlight Drifter", D, 5, 4, 4, "rare", ["hover"],
   ability(ON("turn_end", E("buff", "Give your weakest print +1/+1.", atk=1, hp=1, to="lowest_ally"))),
   H("wyrm", "serpent", ["solar"], ["3a6ad8", "c8d8ff", "c7ced6", "e8f0ff"], heads=1))
HY("meteorite_golem", "Meteorite Golem", S, 7, 6, 8, "epic", [],
   ability(E("fight", "It crashes into the strongest enemy print: they hit each other.", to="strongest_enemy")),
   H("biped", "rock", ["core"], ["2a2a2e", "6a4a3a", "b87333", "ff8a2a"], "rock"))
HY("quasar_serpent", "Quasar Serpent", L, 6, 5, 5, "epic", [],
   ability(ON("attack", E("slow", "Your opponent gets 1 less Filament next turn.", n=1))),
   H("wyrm", "serpent", ["spikes", "coil_spine"], ["d4a72c", "2a4ad8", "c9a227", "fff27a"], heads=1))
HY("orbit_flyer", "Orbit Flyer", D, 3, 3, 2, "uncommon", ["hover"],
   ability(ON("foe_print", E("damage", "Deal 1 damage to the enemy Printer.", n=1, to="enemy_printer"))),
   H("biped", "bug", ["bug_wings", "segment_tail"], ["17171c", "ffcf2e", "c7ced6", "fff27a"], "bird"))
HY("cockatrice", "Cockatrice", N, 4, 3, 3, "rare", [],
   ability(ON("attack", E("silence", "Silence the print it hits.", to="trigger"))),
   H("biped", "eagle", ["snake_tail", "feather_wings"], ["5a8a3a", "e8d8a0", "b87333", "c0ff6a"], "bird"))
HY("wolpertinger", "Wolpertinger", N, 2, 2, 2, "uncommon", [],
   ability(ON("turn_end", IF({"allies_at_least": 3}, E("draw", "If you have 3 or more prints, draw a card.", n=1)))),
   H("quad", "fox", ["antlers", "feather_wings"], ["b88a5a", "f0e0c8", "8a6a4a", "ffe0a0"], scale=0.85))
HY("ammit", "Ammit the Devourer", A, 5, 4, 5, "rare", [],
   ability(ON("foe_shatter", E("heal", "Repair your Printer by 2.", n=2, to="own_printer"))),
   H("quad", "serpent", ["armor", "mask", "flame_mane"], ["2a6a4a", "d4a72c", "c9a227", "ffd36a"]))
HY("tengu", "Tengu", D, 4, 3, 4, "rare", ["quick"],
   ability(E("buff", "Give your other prints Quick Draw.", atk=0, hp=0, kw=["quick"], to="other_friendly_prints")),
   H("biped", "eagle", ["feather_wings", "mask"], ["1a1a20", "c82a2a", "d4a72c", "ff6a4a"], "bird"))


# ===================================================== every body its own
# The picture check (identical silhouettes) found look-alikes among the plans
# that had no variation; each of these now differs in build.
LOOK_TWEAKS = {
    "ember_dragon": {"legs": 4, "neck": 0.55, "horns": "curl", "wings": "bat", "tail": "flame", "spikes": 5},
    "tidal_dragon": {"legs": 2, "neck": 0.8, "horns": "crest", "wings": "feather", "tail": "fan", "spikes": 0, "bulk": 0.9},
    "storm_dragon": {"legs": 4, "neck": 0.45, "horns": "straight", "wings": "double", "tail": "spikes", "spikes": 3, "bulk": 0.95},
    "verdant_dragon": {"legs": 4, "neck": 0.6, "horns": "antler", "wings": "feather", "tail": "fan", "spikes": 2, "bulk": 1.15},
    "glacier_dragon": {"legs": 4, "neck": 0.7, "horns": "many", "wings": "crystal", "tail": "spade", "spikes": 6, "bulk": 1.1},
    "obsidian_dragon": {"legs": 4, "neck": 0.35, "horns": "curl", "wings": "bat", "tail": "club", "spikes": 7, "bulk": 1.3, "span": 0.8},
    "tempest_dragon": {"legs": 2, "neck": 0.6, "horns": "straight", "wings": "bat", "tail": "spade", "spikes": 0, "bulk": 0.8, "span": 1.3},
    "void_dragon": {"legs": 4, "neck": 0.7, "horns": "many", "wings": "double", "tail": "flame", "heads": 2},
    "blaze_matriarch": {"legs": 2, "neck": 0.5, "horns": "crest", "wings": "feather", "tail": "flame", "bulk": 1.1},
    "frost_wyvern": {"legs": 2, "neck": 0.55, "horns": "straight", "wings": "bat", "tail": "spade", "spikes": 4},
    "elder_wyrm": {"legs": 4, "neck": 0.8, "horns": "many", "wings": "double", "tail": "club", "bulk": 1.3, "heads": 3},
    "fairy_dragon": {"legs": 4, "neck": 0.4, "horns": "antler", "wings": "bug", "tail": "fan", "spikes": 0},
    "wyvern_rider": {"legs": 2, "neck": 0.5, "horns": "curl", "wings": "bat", "tail": "spade", "spikes": 2},
    "kite_drake": {"legs": 2, "neck": 0.45, "horns": "none", "wings": "feather", "tail": "fan", "spikes": 0, "bulk": 0.85},
    "scorch_wyrmling": {"legs": 4, "neck": 0.35, "horns": "none", "wings": "none", "tail": "flame", "spikes": 4},
    "dragon_hatchling": {"legs": 4, "neck": 0.3, "horns": "curl", "wings": "bat", "tail": "spade", "spikes": 1, "span": 0.7},
    "moonlight_unicorn": {"crescent": True, "tail_len": 1.4},
    "thunder_kirin": {"horn": False, "antlers": True, "flame_mane": True},
    "rainbow_unicorn": {"wings": False, "tail_len": 1.6, "flame_mane": True},
    "shadow_mare": {"flame_mane": True},
    "kelpie": {"fish_tail": True},

    "plasma_pegasus": {"flame_mane": True, "tail_len": 1.3},
    "swarm_scout": {"gift": "scout"}, "swarm_warden": {"gift": "warden"}, "swarm_stinger": {"gift": "stinger"},
    "swarm_carapace": {"gift": "carapace"}, "swarm_glider": {"gift": "glider"}, "swarm_leech": {"gift": "leech"},
    "swarm_twinwing": {"gift": "twinwing"}, "arc_wasp": {"gift": "stinger"}, "ember_moth": {"gift": "glider"},
    "sandstone_scarab": {"gift": "carapace"}, "pegasus_courier": {"foal": True, "tail_len": 0.6}, "swarm_larva": {"gift": "larva"}, "swarm_queen": {"gift": "queen"},
    "failed_print": {"shape": "tangle"}, "support_pillar": {"shape": "pillar"}, "mushroom_choir": {"plan": "blob", "shape": "mushroom"},
    "calibration_cube": {"shape": "cube"}, "dripling": {"shape": "drop"}, "pebbit": {"shape": "pebble"},
    "pearl_oyster": {"shape": "clam"}, "oracle_orb": {"shape": "orb"},
    "narwhal_lancer": {"fish": "narwhal"}, "whirlpool_ray": {"fish": "ray"}, "splashard": {"fish": "sail"},
"ashling": {"plan": "bird"}, "pollen_pixie": {"plan": "bird"},
}
REBODY2 = {
    "cloudhopper": H("quad", "owl", ["antlers"], ["eef4f8", "a8d8f0", "c7ced6", "ffffff"]),
    "mistwalker": H("taur", "human", ["feather_wings"], ["9fc8e8", "f2f6f8", "c0c8d0", "d8f0ff"], "horse"),
    "snowdrift": H("wyrm", "owl", ["feather_wings"], ["f4fbff", "9fdcff", "c0c8d0", "c8f2ff"], heads=1),
    "sandpiper": H("biped", "eagle", ["segment_tail"], ["d8c08a", "f4efe0", "b87333", "ffd36a"], "bird", scale=0.85),
    "cockatrice": H("biped", "eagle", ["snake_tail", "crown"], ["5a8a3a", "e8d8a0", "b87333", "c0ff6a"], "bird"),
    "seedpup": H("biped", "dog", ["antlers"], ["8ac04a", "f4e0a0", "a87a4a", "d0ff8a"], scale=0.8),
    "gustkit": H("quad", "fox", ["bat_wings"], ["7fe0c4", "f2f6f8", "c7ced6", "c6fff0"], scale=0.85),
    "slushpup": H("quad", "dog", ["ram_horns", "spikes"], ["8fc8f0", "f4fbff", "c0c8d0", "c8f2ff"]),
    "glyphhare": H("taur", "fox", ["mask"], ["c070f0", "f0e0ff", "ffcf3a", "e0b0ff"], "lion"),
    "barkback": H("quad", "bull", ["antlers"], ["7a5a3a", "56b84a", "a87a4a", "b6ff6a"]),
    "brineleech": H("crawler", "serpent", [], ["2a6a5a", "8fd8c0", "d9773a", "8be04a"], "insect"),
    "gravelhopper": H("quad", "rock", ["spikes"], ["7a7068", "a89888", "b87333", "ffb84a"]),
    "cairncrab": H("crawler", "bug", ["armor", "spikes"], ["9a8a7a", "d8c8b8", "e9a91c", "ffb84a"], "rock"),
    "rimestag": H("quad", "stag", ["spikes"], ["eaf2ff", "a0d0f0", "ffcf3a", "c8f2ff"]),
    "storm_roc": H("biped", "eagle", ["bat_wings", "coil_spine"], ["5a7ab0", "f2f6f8", "e9a91c", "c6fff0"], "bird", scale=1.15),
    "surge_owl": H("biped", "owl", ["spikes", "coil_spine"], ["ffcf2e", "2b2f3a", "c7ced6", "fff27a"], "bird"),
    "static_hedgehog": H("crawler", "fox", ["spikes"], ["ffcf2e", "2b2f3a", "c7ced6", "fff27a"], "rock", scale=0.8),
    "tidecaller_crab": H("crawler", "bug", ["armor"], ["e8643a", "ffd0b0", "c7ced6", "ffb0a0"], "insect"),
    "boulder_beetle": H("quad", "bug", ["armor"], ["8d8a86", "c9c2b8", "e9a91c", "ffb84a"]),
    "swiftwhip": H("wyrm", "fox", ["bat_wings"], ["4ad0a0", "f2f6f8", "c7ced6", "c6fff0"], heads=1, scale=0.85),
    "snowmite": H("biped", "bug", ["spikes"], ["bfe9ff", "f4fbff", "8f8cf0", "c8f2ff"], "bird", scale=0.8),
    "granitegriffin": H("biped", "eagle", ["armor", "feather_wings"], ["8d8a86", "f4efe0", "e9a91c", "ffb84a"], "rock"),
    "pinfeather": H("wyrm", "eagle", ["feather_wings"], ["4a8ac0", "f2f6f8", "e9a91c", "c6fff0"], heads=1, scale=0.85),
    "siphon_squid": H("seahorse", "serpent", [], ["d86a8a", "f8d0e0", "c7ced6", "ff9ac0"]),
}
for c in CREATURES:
    if c["id"] in REBODY2:
        lk = dict(REBODY2[c["id"]])
        lk["seed"] = zlib.crc32(c["id"].encode()) & 0xffffff
        lk["element"] = c["element"]
        c["art"] = "gen"
        c["look"] = lk
    if c["id"] in LOOK_TWEAKS and "look" in c:
        c["look"].update(LOOK_TWEAKS[c["id"]])


# =========================================================== painted art
# Creatures that now have painted sheets (tools/catalog/painted.txt) keep them:
# no `look`, so the render scripts leave them alone.
PAINTED = set()
with open(_os.path.join(_os.path.dirname(__file__), "painted.txt")) as _f:
    for _line in _f:
        _line = _line.strip()
        if _line and not _line.startswith("#"):
            PAINTED.add(_line)
for c in CREATURES:
    if c["id"] in PAINTED:
        c["art"] = "painted"
        c.pop("look", None)
