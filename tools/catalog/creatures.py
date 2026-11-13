"""The creature roster. One row per creature:

    C(id, name, element, cost, atk, hp, rarity, keywords, ability, art)

`art` is "base:hue:finish[:hue2]" (a base creature recoloured with a filament
finish, see tools/creature_finish.py) or "src:name" (a design cut out of
tools/creature_sources/). Stat lines follow cost: roughly 2 x cost + 2 points,
less for abilities and keywords, more for legendaries.
"""
from .fx import (ability, armor, bounce, buff, destroy, dmg, draw, heal, heat, jam, sh_armor, sh_buff, sh_dmg,
                 sh_draw, sh_heal, sh_spool, sh_summon, speed, spool, steal, summon)

CREATURES = []


def C(cid, name, element, cost, atk, hp, rarity, kw=(), fx=None, art=""):
    d = {"id": cid, "name": name, "type": "creature", "cost": cost, "atk": atk, "hp": hp, "element": element,
         "rarity": rarity, "kw": list(kw), "art": art}
    d.update(fx or ability())
    CREATURES.append(d)


# ------------------------------------------------------------------- Fire
F = "Fire"
C("emberling", "Emberling", F, 1, 1, 2, "common", ["scorch"], None, "frostling:14:glow")
C("sootsprite", "Sootsprite", F, 2, 2, 2, "common", [], ability(dmg(1, "print")), "galehopper:10:carbon")
C("kilnpup", "Kilnpup", F, 2, 2, 1, "common", ["rush"], None, "voltwig:24:silk:50")
C("forgefinch", "Forgefinch", F, 3, 2, 3, "common", [], ability(speed(2)), "aurorawing:20:silk:44")
C("lavalynx", "Lavalynx", F, 3, 4, 2, "common", [], None, "cinderpaw:5:stripes")
C("wickfox", "Wickfox", F, 2, 2, 2, "uncommon", [], ability(buff(2, 0, "print")), "miragefox:16:glitter")
C("cindermoth", "Cindermoth", F, 3, 2, 3, "uncommon", [], ability(heat(2, "print")), "starloom:18:glow")
C("slagrhino", "Slagrhino", F, 4, 3, 5, "uncommon", ["guard"], None, "verdantitan:12:carbon")
C("thermochameleon", "Thermochameleon", F, 4, 3, 4, "rare", ["scorch"], ability(heat(2, "print")), "src:chamelion")
C("blazehound", "Blazehound", F, 5, 4, 4, "rare", ["rush", "scorch"], None, "coalgriffin:8:metal:24")
C("furnacedrake", "Furnacedrake", F, 5, 4, 5, "epic", [], ability(dmg(2, "all")), "glassdrake:15:lava")
C("phoenixfilament", "Phoenix Filament", F, 6, 5, 4, "epic", [], ability(sh_dmg(3, "all")), "aurorawing:22:glow")
C("cinderwyrm", "Cinderwyrm", F, 8, 7, 7, "legendary", ["scorch"], ability(heat(3, "all")), "worldcoil:8:lava")
C("magmabloom", "Magmabloom", F, 7, 5, 8, "legendary", ["guard"], ability(heat(2, "all"), sh_dmg(2, "all")), "src:magmabloom")

# ------------------------------------------------------------------ Water
W = "Water"
C("dewdrop", "Dewdrop", W, 1, 1, 2, "common", [], ability(heal(1, "printer")), "aquafin:195:glass")
C("puddlepup", "Puddlepup", W, 2, 2, 2, "common", [], ability(heal(2)), "frostling:205:silk:170")
C("bubbleray", "Bubbleray", W, 2, 1, 3, "common", ["guard"], None, "voidmanta:190:glass")
C("reefhopper", "Reefhopper", W, 3, 3, 3, "common", [], None, "galehopper:185:marble:210")
C("mistwalker", "Mistwalker", W, 1, 2, 1, "common", [], None, "aquafin:182:pla")
C("tideotter", "Tideotter", W, 2, 2, 1, "uncommon", [], ability(draw(1)), "sparkotter:215:marble:180")
C("pearlback", "Pearlback", W, 4, 2, 7, "uncommon", ["guard"], ability(heal(2, "printer")), "stoneback:200:marble:195")
C("siphonshark", "Siphonshark", W, 4, 4, 4, "uncommon", ["thief"], None, "ironmaw:190:metal:205")
C("kelpwyrm", "Kelpwyrm", W, 3, 2, 3, "uncommon", [], ability(buff(1, 2, "print")), "worldcoil:150:marble:120")
C("glassserpent", "Glassserpent", W, 4, 3, 4, "rare", ["siphon"], None, "src:glassserpent")
C("undertow", "Undertow", W, 5, 4, 6, "rare", [], ability(bounce()), "tidewhale:175:silk:200")
C("brineleech", "Brineleech", W, 5, 3, 6, "rare", ["thief"], None, "coralisk:170:carbon")
C("tsunamiray", "Tsunami Ray", W, 6, 4, 6, "epic", [], ability(jam("all")), "voidmanta:205:glass")
C("leviathanvat", "Leviathan Vat", W, 8, 6, 9, "legendary", [], ability(heal(6, "printer"), draw(2)), "tidewhale:230:glow")

# -------------------------------------------------------------- Lightning
L = "Lightning"
C("zapkit", "Zapkit", L, 1, 2, 1, "common", [], None, "voltwig:55:glitter")
C("jolthare", "Jolthare", L, 2, 2, 2, "common", [], ability(speed(1)), "galehopper:52:silk:30")
C("staticcub", "Staticcub", L, 2, 3, 1, "common", [], None, "frostling:60:carbon")
C("fusefox", "Fusefox", L, 3, 2, 3, "common", [], ability(draw(1)), "miragefox:45:metal:50")
C("sparkbug", "Sparkbug", L, 1, 1, 2, "common", [], None, "mossmunk:55:glitter")
C("amperfinch", "Amperfinch", L, 3, 3, 2, "uncommon", [], ability(dmg(2, "printer")), "aurorawing:50:silk:36")
C("capacitor", "Capacitor", L, 4, 2, 6, "uncommon", ["guard"], None, "ironmaw:55:carbon")
C("gridstag", "Gridstag", L, 5, 4, 4, "uncommon", ["rush"], None, "runestag:58:stripes")
C("gigahertz", "Gigahertz", L, 3, 4, 1, "uncommon", ["rush"], None, "starloom:50:pla")
C("voltviper", "Voltviper", L, 4, 3, 3, "rare", ["rush", "thief"], None, "src:voltviper")
C("arcflicker", "Arcflicker", L, 4, 2, 3, "rare", ["twin"], None, "voltwig:62:glass")
C("overcharger", "Overcharger", L, 5, 4, 5, "rare", [], ability(jam()), "coalgriffin:56:silk:40")
C("surgebeast", "Surgebeast", L, 6, 5, 5, "epic", ["rush"], ability(dmg(2, "printer")), "pyraxis:52:metal:50")
C("stormcoil", "Stormcoil", L, 8, 7, 7, "legendary", ["twin"], None, "worldcoil:50:volt")

# ----------------------------------------------------------------- Nature
N = "Nature"
C("sproutling", "Sproutling", N, 1, 1, 2, "common", [], None, "mossmunk:100:wood")
C("leafmite", "Leafmite", N, 2, 2, 2, "common", [], ability(heal(2)), "galehopper:110:glitter")
C("barkback", "Barkback", N, 3, 2, 5, "common", ["guard"], None, "stoneback:90:wood")
C("mushmunk", "Mushmunk", N, 2, 1, 3, "common", [], ability(heal(2, "printer")), "mossmunk:20:marble:130")
C("seedpup", "Seedpup", N, 1, 2, 1, "common", [], None, "frostling:100:pla")
C("petalfawn", "Petalfawn", N, 3, 2, 3, "uncommon", [], ability(buff(1, 0, "others")), "runestag:320:silk:100")
C("vinehare", "Vinehare", N, 3, 3, 2, "uncommon", ["thief"], None, "voltwig:120:stripes")
C("canopyowl", "Canopyowl", N, 4, 3, 4, "uncommon", [], ability(draw(1)), "brambleowl:135:silk:100")
C("spoolshell", "Spoolshell", N, 4, 2, 6, "uncommon", ["guard"], ability(spool(4)), "src:spoolshell")
C("bramblemaw", "Bramblemaw", N, 5, 4, 5, "rare", ["thief"], None, "ironmaw:95:wood")
C("rootstag", "Rootstag", N, 5, 4, 6, "rare", [], ability(buff(1, 1, "others")), "runestag:105:wood")
C("nautilark", "Nautilark", N, 5, 3, 6, "rare", ["guard", "brim"], None, "src:nautilark")
C("greenwarden", "Greenwarden", N, 6, 5, 6, "epic", ["guard"], ability(buff(1, 2, "others")), "verdantitan:130:marble:90")
C("worldroot", "Worldroot", N, 9, 6, 11, "legendary", ["guard"], ability(buff(2, 2, "others")), "worldcoil:110:wood")

# -------------------------------------------------------------------- Ice
I = "Ice"
C("snowmite", "Snowmite", I, 1, 2, 1, "common", [], None, "frostling:190:glitter")
C("slushpup", "Slushpup", I, 2, 2, 3, "common", [], None, "galehopper:195:glass")
C("rimefox", "Rimefox", I, 2, 2, 1, "common", ["rush"], None, "miragefox:200:silk:185")
C("frostbite", "Frostbite", I, 3, 3, 2, "common", [], ability(dmg(1, "printer")), "cinderpaw:200:pla")
C("snowdrift", "Snowdrift", I, 4, 3, 4, "common", [], None, "verdantitan:200:marble:180")
C("icehare", "Icehare", I, 3, 2, 3, "uncommon", [], ability(jam()), "voltwig:185:glass")
C("permafrost", "Permafrost", I, 4, 2, 7, "uncommon", ["guard"], None, "stoneback:195:glass")
C("hailstorm", "Hailstorm", I, 5, 4, 4, "uncommon", [], ability(dmg(1, "all")), "coalgriffin:205:silk:190")
C("shivercat", "Shivercat", I, 2, 2, 2, "uncommon", [], ability(buff(0, 2, "print")), "starloom:205:silk:180")
C("chillwhale", "Chillwhale", I, 5, 3, 7, "rare", ["guard"], ability(jam()), "tidewhale:190:glass")
C("rimestag", "Rimestag", I, 4, 3, 5, "rare", ["brim"], None, "runestag:195:glitter")
C("glaciermaw", "Glaciermaw", I, 6, 5, 6, "rare", ["guard"], None, "ironmaw:190:metal:200")
C("blizzardowl", "Blizzard Owl", I, 6, 4, 5, "epic", [], ability(jam("all")), "brambleowl:195:glow")
C("cryowyrm", "Cryowyrm", I, 9, 8, 9, "legendary", ["brim"], ability(jam("all")), "worldcoil:185:glass")

# ------------------------------------------------------------------ Stone
S = "Stone"
C("pebblepup", "Pebblepup", S, 1, 1, 2, "common", ["guard"], None, "frostling:35:marble:30")
C("gravelhopper", "Gravelhopper", S, 2, 2, 3, "common", [], None, "galehopper:30:marble:25")
C("cairncrab", "Cairncrab", S, 3, 3, 4, "common", [], None, "ironmaw:28:carbon")
C("slatehound", "Slatehound", S, 3, 2, 5, "common", ["guard"], None, "glassdrake:25:marble:210")
C("sandpiper", "Sandpiper", S, 1, 2, 1, "common", [], None, "aurorawing:38:pla")
C("quarrymole", "Quarrymole", S, 2, 2, 2, "uncommon", [], ability(armor(2)), "mossmunk:28:carbon")
C("basaltbison", "Basaltbison", S, 4, 4, 5, "uncommon", [], None, "verdantitan:25:carbon")
C("geodefox", "Geodefox", S, 3, 3, 3, "uncommon", [], ability(spool(2)), "miragefox:40:glass")
C("obsidianray", "Obsidian Ray", S, 4, 3, 4, "uncommon", ["siphon"], None, "voidmanta:260:carbon")
C("crystalscorp", "Crystalscorp", S, 5, 4, 4, "rare", ["scorch", "thief"], None, "src:crystalscorp")
C("monolith", "Monolith", S, 6, 3, 9, "rare", ["guard"], None, "stoneback:35:carbon")
C("granitegriffin", "Granite Griffin", S, 5, 4, 6, "rare", ["brim"], None, "skyforge:30:metal:210")
C("titanminer", "Titan Miner", S, 6, 5, 6, "epic", [], ability(dmg(3, "print")), "coalgriffin:30:carbon")
C("mountainwyrm", "Mountain Wyrm", S, 8, 7, 9, "legendary", ["guard", "brim"], None, "worldcoil:20:marble:30")

# ------------------------------------------------------------------- Wind
D = "Wind"
C("breezepup", "Breezepup", D, 1, 1, 2, "common", [], None, "frostling:160:glitter")
C("gustkit", "Gustkit", D, 2, 2, 2, "common", [], None, "cinderpaw:150:silk:175")
C("cloudhopper", "Cloudhopper", D, 2, 1, 3, "common", [], None, "galehopper:165:glass")
C("pinfeather", "Pinfeather", D, 1, 2, 1, "common", [], None, "aurorawing:180:pla")
C("slipstream", "Slipstream", D, 3, 3, 2, "common", ["rush"], None, "thunderelk:150:stripes")
C("zephyrfinch", "Zephyrfinch", D, 3, 3, 3, "uncommon", [], ability(speed(1)), "aurorawing:170:silk:150")
C("swiftwhip", "Swiftwhip", D, 2, 2, 1, "uncommon", ["rush"], None, "sparkotter:155:stripes")
C("galemoth", "Gale Moth", D, 4, 3, 3, "uncommon", [], ability(bounce()), "starloom:160:silk:140")
C("skyhawk", "Skyhawk", D, 4, 4, 3, "uncommon", ["rush"], None, "coalgriffin:175:metal:190")
C("tempestlynx", "Tempest Lynx", D, 4, 3, 4, "rare", ["twin"], None, "miragefox:158:glow")
C("squallmaw", "Squallmaw", D, 5, 4, 4, "rare", [], ability(bounce()), "ironmaw:165:carbon")
C("stormdrake", "Stormdrake", D, 4, 3, 5, "rare", ["brim"], None, "glassdrake:165:silk:145")
C("vortexray", "Vortex Ray", D, 6, 5, 5, "epic", ["rush"], ability(bounce()), "voidmanta:170:glass")
C("tempestforge", "Tempestforge", D, 8, 7, 6, "legendary", ["twin", "rush"], None, "skyforge:160:glow")

# ------------------------------------------------------------------ Arcane
A = "Arcane"
C("runemite", "Runemite", A, 1, 1, 2, "common", [], None, "mossmunk:275:glow")
C("wispling", "Wispling", A, 2, 2, 2, "common", [], ability(heal(1, "printer")), "frostling:280:glitter")
C("hexcat", "Hexcat", A, 2, 2, 1, "common", [], ability(speed(1)), "starloom:285:silk:310")
C("glyphhare", "Glyphhare", A, 3, 3, 3, "common", [], None, "voltwig:270:marble:300")
C("gearspider", "Gearspider", A, 3, 2, 3, "uncommon", ["thief"], None, "src:gearspider")
C("sigilowl", "Sigilowl", A, 4, 3, 4, "uncommon", [], ability(draw(1)), "brambleowl:270:silk:300")
C("voidmoth", "Voidmoth", A, 4, 3, 3, "uncommon", ["siphon"], None, "starloom:265:carbon")
C("hexstag", "Hexstag", A, 5, 4, 4, "rare", [], ability(heat(2, "print"), jam()), "runestag:290:glow")
C("sigilsmith", "Sigilsmith", A, 4, 3, 3, "rare", [], ability(buff(2, 2, "print")), "miragefox:275:metal:280")
C("chronocat", "Chronocat", A, 5, 4, 5, "rare", ["brim"], None, "cinderpaw:300:marble:270")
C("cosmicray", "Cosmic Ray", A, 6, 4, 6, "epic", [], ability(dmg(3, "print")), "voidmanta:295:glitter")
C("oracledrake", "Oracle Drake", A, 6, 5, 5, "epic", [], ability(steal(2, 2)), "glassdrake:285:glow")
C("jellycrown", "Jellycrown", A, 7, 5, 6, "legendary", [], ability(draw(2), buff(1, 1, "others")), "src:jellycrown")
C("voidwyrm", "Voidwyrm", A, 9, 8, 8, "legendary", [], ability(destroy()), "worldcoil:280:carbon")

# ------------------------------------- Modelled prints (new designs, not recolours)
# Modelled from primitives by tools/render_art4.gd; every one is a print gone
# wonderfully wrong or a piece of printer come to life.
C("clogglin", "Clog Goblin", F, 2, 2, 2, "common", [], ability(heat(1, "print")), "src:clog_goblin")
C("trihydra", "Tri-Head Hydra", F, 8, 6, 7, "legendary", ["twin", "scorch"], None, "src:tri_head_hydra")
C("benchyboss", "Benchy Boss", W, 5, 4, 6, "rare", [], ability(heal(3, "printer")), "src:benchy_boss")
C("coilcobra", "Coil Cobra", L, 3, 3, 2, "rare", ["rush"], ability(dmg(1, "print")), "src:coil_cobra")
C("spaghettimess", "Spaghetti Mess", N, 3, 2, 3, "uncommon", [], ability(jam()), "src:spaghetti_mess")
C("cubecrab", "Cube Crab", I, 2, 2, 3, "common", ["guard"], None, "src:cube_crab")
C("steppergolem", "Stepper Golem", S, 5, 4, 5, "uncommon", ["guard"], ability(sh_armor(2)), "src:stepper_golem")
C("gantrymantis", "Gantry Mantis", D, 4, 4, 3, "uncommon", ["twin"], None, "src:gantry_mantis")
C("layershifter", "Layer Shifter", A, 4, 3, 3, "rare", [], ability(draw(1)), "src:layer_shifter")

assert len({c["id"] for c in CREATURES}) == len(CREATURES), "duplicate creature id"
