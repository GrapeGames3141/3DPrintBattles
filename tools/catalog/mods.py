"""New card mods (Blueprint slot) and Printer mods (Workshop slot), by rarity.

Card mods are data: stat changes (atk, hp, dcost), keywords (kw) and effects
(on_print / shatter, which tools and equipment run as plain effects).
Prices and Maker Rank follow rarity:
  common 200-300 / rank 2-4, uncommon 450-700 / 4-8, rare 900-1500 / 8-13,
  epic 1800-2600 / 14-20, legendary 4000-6000 / 22-28.
"""
from .fx import armor, draw, heal, heat, sh_armor, sh_dmg, sh_draw, sh_summon, speed, spool, summon, dmg

CARD_MODS = []
PRINTER_MODS = []
CR = ["creature"]
ALL = ["creature", "tool", "upgrade"]
TU = ["tool", "upgrade"]


def M(mid, name, icon, kinds, rarity, cost, rank, text, atk=0, hp=0, dcost=0, kw=(), on=(), sh=(), special=""):
    d = {"id": mid, "name": name, "icon": icon, "kinds": kinds, "rarity": rarity, "cost": cost, "rank": rank, "text": text,
         "atk": atk, "hp": hp, "dcost": dcost, "kw": list(kw),
         "fx_on": [p["effect"] for p in on], "line_on": " ".join(p["text"] for p in on),
         "fx_sh": [p["effect"] for p in sh], "line_sh": " ".join(p["text"] for p in sh), "special": special}
    CARD_MODS.append(d)


# ---------------------------------------------------------- creature mods
M("cooling_fins", "Cooling Fins", "snow", CR, "common", 200, 2, "+1 Health.", hp=1)
M("wide_nozzle", "Wide Nozzle", "burst", CR, "common", 220, 2, "+1 Attack, -1 Health.", atk=1, hp=-1)
M("thick_walls", "Thick Walls", "shield", CR, "common", 220, 3, "+2 Health, -1 Attack.", atk=-1, hp=2)
M("brass_insert", "Brass Insert", "cube", CR, "common", 260, 3, "+1/+1, costs 1 more.", atk=1, hp=1, dcost=1)
M("snap_fit", "Snap Fit", "check", CR, "common", 240, 4, "Costs 1 less, -1 Health.", hp=-1, dcost=-1)
M("ember_core", "Ember Core", "flame", CR, "uncommon", 500, 5, "Gains Scorch, costs 1 more.", kw=["scorch"], dcost=1)
M("sticky_fingers", "Sticky Fingers", "spool", CR, "uncommon", 550, 6, "Gains Filament Thief, -1 Health.", hp=-1, kw=["thief"])
M("patch_kit", "Patch Kit", "drop", CR, "uncommon", 480, 5, "On Print: Repair your Printer by 2.", on=[heal(2, "printer")])
M("data_log", "Data Log", "star", CR, "uncommon", 650, 7, "On Print: Draw a card, costs 1 more.", on=[draw(1)], dcost=1)
M("spare_parts", "Spare Parts", "cube", CR, "uncommon", 600, 7, "Shatter: Draw a card.", sh=[sh_draw(1)])
M("scrap_armor", "Scrap Armor", "shield", CR, "uncommon", 520, 6, "Shatter: Your Printer gains 3 Armor.", sh=[sh_armor(3)])
M("dual_extruder", "Dual Extruder", "twin", CR, "rare", 1200, 10, "Gains Twin Nozzle, costs 2 more.", kw=["twin"], dcost=2)
M("flame_jet", "Flame Jet", "flame", CR, "rare", 1000, 9, "On Print: Deal 2 damage to the enemy Printer, costs 1 more.", on=[dmg(2, "printer")], dcost=1)
M("blast_cap", "Blast Cap", "burst", CR, "rare", 1300, 11, "Shatter: Deal 2 damage to all enemy prints.", sh=[sh_dmg(2, "all")])
M("decoy_core", "Decoy Core", "cube", CR, "rare", 1100, 10, "Shatter: Print 2 Test Bots, costs 1 more.", sh=[sh_summon(2)], dcost=1)
M("heater_cartridge", "Heater Cartridge", "flame", CR, "rare", 1400, 12, "On Print: Heat all enemy prints, costs 2 more.", on=[heat(2, "all")], dcost=2)
M("glass_filament", "Glass Filament", "burst", CR, "epic", 1900, 15, "+3 Attack, -2 Health.", atk=3, hp=-2)
M("titan_infill", "Titan Infill", "hex", CR, "epic", 2200, 17, "+5 Health, costs 2 more.", hp=5, dcost=2)
M("berserk_firmware", "Berserk Firmware", "twin", CR, "epic", 2400, 18, "Gains Rush and +2 Attack, -2 Health.", atk=2, hp=-2, kw=["rush"])
M("ghost_layer", "Ghost Layer", "lock", CR, "epic", 2600, 19, "Gains Brim and Guard, costs 2 more.", kw=["brim", "guard"], dcost=2)
M("overclocked_core", "Overclocked Core", "flame", CR, "legendary", 5000, 24, "+3/+3 and Rush, costs 2 more.", atk=3, hp=3, kw=["rush"], dcost=2)
M("soul_of_the_machine", "Soul of the Machine", "star", CR, "legendary", 6000, 27, "+2/+2, Siphon and Filament Thief, costs 2 more.", atk=2, hp=2, kw=["siphon", "thief"], dcost=2)

# --------------------------------------------------------- any-card mods
M("pressure_valve", "Pressure Valve", "shield", ALL, "common", 240, 3, "Your Printer gains 1 Armor when used.", on=[armor(1)])
M("quick_print", "Quick Print", "burst", ALL, "common", 280, 4, "+2 Print Speed when used, costs 1 more.", on=[speed(2)], dcost=1)
M("healing_hum", "Healing Hum", "drop", ALL, "uncommon", 520, 6, "Repair your Printer by 2 when used, costs 1 more.", on=[heal(2, "printer")], dcost=1)
M("filament_tap", "Filament Tap", "spool", ALL, "uncommon", 600, 7, "Add 3 Filament to your Spool when used, costs 1 more.", on=[spool(3)], dcost=1)
M("echo_chamber", "Echo Chamber", "star", ALL, "rare", 1300, 11, "Draw a card and gain 1 Armor when used, costs 2 more.", on=[draw(1), armor(1)], dcost=2)
M("test_bot_bonus", "Test Bot Bonus", "cube", ALL, "rare", 1000, 9, "Print a Test Bot when used, costs 1 more.", on=[summon(1)], dcost=1)
M("smart_core", "Smart Core", "star", ALL, "epic", 2300, 17, "Draw a card and +1 Print Speed when used.", on=[draw(1), speed(1)])
M("phase_shift", "Phase Shift", "star", ALL, "legendary", 4500, 22, "Draw 2 cards when used, costs 2 more.", on=[draw(2)], dcost=2)

# -------------------------------------------------- tool and equipment mods
M("potent_mix", "Potent Mix", "flame", TU, "rare", 1200, 10, "Its effect is 2 stronger, costs 2 more.", dcost=2, special="bump2")
M("bulk_discount", "Bulk Discount", "coin", TU, "epic", 2000, 15, "Costs 1 less.", dcost=-1)
assert len(CARD_MODS) == 32, len(CARD_MODS)


def P(pid, name, icon, rarity, text, per, cost, rank, requires=()):
    row = {"id": pid, "name": name, "icon": icon, "rarity": rarity, "text": text, "per": per, "cost": cost, "rank": rank}
    if requires:
        row["requires"] = list(requires)
    PRINTER_MODS.append(row)


P("cooling_duct", "Cooling Duct", "snow", "common", "Every print you make has %d more Health.", 1, 500, 3)
P("self_cleaning", "Self-Cleaning Nozzle", "drop", "common", "Your Printer repairs %d at the start of your turn.", 1, 600, 4)
P("spool_feeder", "Spool Feeder", "spool", "uncommon", "Add %d Filament to your Spool at the start of your turn.", 1, 900, 6)
P("capacitor_bank", "Capacitor Bank", "burst", "uncommon", "%d extra Print Speed on your first turn.", 2, 700, 5)
P("scrap_chute", "Scrap Chute", "check", "uncommon", "The first time each turn one of your prints shatters, draw a card.", 1, 1800, 8)
P("quick_release", "Quick-Release Bed", "twin", "rare", "The first print you make each battle has Rush.", 1, 1600, 10)
P("failsafe", "Failsafe", "lock", "rare", "Once a battle, if your Printer would be destroyed it is repaired to %d Health instead.", 5, 2200, 12)
P("plating", "Plating", "shield", "rare", "Damage to your Printer is reduced by %d (never below 1).", 1, 1800, 10)
P("thermal_mass", "Thermal Mass", "flame", "epic", "Heat you inflict lasts %d turn longer.", 1, 2400, 14)
P("prehensile_gantry", "Prehensile Gantry", "spool", "epic", "Your Filament Thieves steal %d more Attack.", 1, 2600, 15)
P("quantum_slicer", "Quantum Slicer", "star", "legendary", "Draw %d extra card each turn.", 1, 9000, 26)

# Mods that need other mods. A Printer only runs one of these while every mod it
# `requires` is installed on that Printer too, so they form small upgrade chains.
P("dual_extruder", "Dual Extruder", "burst", "rare", "Prints %d more Filament each turn.", 1, 2800, 12, requires=["stepper"])
P("direct_drive", "Direct Drive Gearbox", "burst", "epic", "Prints %d more Filament each turn.", 1, 5200, 20, requires=["dual_extruder", "hot_end"])
P("spool_rack", "Spool Rack", "spool", "uncommon", "Your Spool holds %d more Filament.", 10, 900, 7, requires=["spool"])
P("twin_feed", "Twin Feed Tower", "spool", "rare", "Add %d more Filament to your Spool at the start of your turn.", 1, 3200, 16, requires=["spool_feeder", "spool_rack"])
P("titanium_frame", "Titanium Frame", "shield", "rare", "Your Printer has %d more Health.", 4, 1400, 11, requires=["frame"])
P("armor_panels", "Armour Panels", "lock", "uncommon", "Your Printer starts with %d more Armor.", 3, 1100, 9, requires=["enclosure"])
P("auto_leveler", "Auto Bed Leveling", "check", "uncommon", "Your first print each battle gets another +%d/+%d.", 1, 1200, 10, requires=["bed"])
P("runout_sensor", "Runout Sensor", "check", "rare", "A shattered print returns %d more Filament to your Spool.", 1, 1500, 12, requires=["sensor"])
P("preheat_chamber", "Preheat Chamber", "flame", "uncommon", "Your first long print each battle starts %d Filament further ahead.", 3, 1300, 10, requires=["preheater"])
P("liquid_hot_end", "Liquid-cooled Hot End", "drop", "rare", "Your Printer Power costs %d less Filament.", 1, 2800, 16, requires=["hot_end"])
P("overdrive_board", "Overdrive Board", "burst", "epic", "%d more Print Speed on your first turn.", 3, 3600, 18, requires=["capacitor_bank", "stepper"])
P("auto_sorter", "Auto Sorter", "coin", "uncommon", "Earn %d more Forge Coins for each win.", 6, 700, 8, requires=["sorter"])
