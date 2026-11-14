"""New tools (one-shot effects) and equipment (permanent buffs on a print)."""
from .fx import armor, bounce, buff, dmg, draw, heal, heat, jam, speed, spool, summon, tool_effect

TOOLS = []
UPGRADES = []


def T(tid, name, cost, rarity, *parts):
    d = {"id": tid, "name": name, "type": "tool", "cost": cost, "rarity": rarity}
    d.update(tool_effect(*parts))
    TOOLS.append(d)


def U(uid, name, cost, rarity, a, h, kw=()):
    p = buff(a, h, "print", kw)
    TOOLS_TEXT = p["text"]
    UPGRADES.append({"id": uid, "name": name, "type": "upgrade", "cost": cost, "rarity": rarity, "text": TOOLS_TEXT,
                     "target": "friendly_print", "buff": {"atk": a, "hp": h, "kw": list(kw)}})


# ------------------------------------------------------------------ tools
T("zip_ties", "Zip Ties", 1, "common", buff(1, 1))
T("sandpaper", "Sandpaper", 1, "common", heal(2))
T("masking_tape", "Masking Tape", 1, "common", armor(2))
T("nozzle_brush", "Nozzle Brush", 1, "common", draw(1))
T("needle_pliers", "Needle Pliers", 2, "common", dmg(3, "print"))
T("iso_wipes", "Isopropyl Wipes", 2, "common", heal(4, "printer"))

T("heat_block", "Heat Block", 2, "uncommon", dmg(1, "print"), heat(2, "print"))
T("hot_plate", "Hot Plate", 3, "uncommon", heat(2, "all"))
T("desiccant_packs", "Desiccant Packs", 2, "uncommon", spool(4))
T("digital_scale", "Digital Scale", 2, "uncommon", draw(2))
T("flush_cutters", "Flush Cutters", 3, "uncommon", dmg(4, "print"))
T("print_remover", "Print Remover", 2, "uncommon", bounce())
T("cooling_spray", "Cooling Spray", 2, "uncommon", jam(), armor(2))

T("soldering_station", "Soldering Station", 4, "rare", heat(3, "all"), dmg(1, "all"))
T("torque_wrench", "Torque Wrench", 3, "rare", buff(3, 3))
T("laser_level", "Laser Level", 3, "rare", draw(2), armor(2))
T("multimeter", "Multimeter", 2, "rare", speed(3))
T("wash_station", "Resin Wash Station", 4, "rare", heal(6, "printer"), armor(2))
T("color_change", "Color Change", 3, "rare", buff(2, 2, "print", ["thief"]))

T("plasma_cutter", "Plasma Cutter", 4, "epic", dmg(5, "print"))
T("hot_swap", "Hot Swap", 4, "epic", bounce(), dmg(2, "printer"))
T("kiln", "Kiln", 5, "epic", heat(3, "all"), dmg(2, "all"))
T("overclock_kit", "Overclock Kit", 4, "epic", buff(3, 3, "print", ["scorch", "rush"]))
T("bulk_order", "Bulk Order", 5, "epic", draw(3))

T("print_farm", "Print Farm", 7, "legendary", summon(3), armor(4))
T("mega_spool", "Mega Spool", 4, "legendary", spool(20), speed(2))
T("master_slicer", "Master Slicer", 6, "legendary", draw(2), spool(8), speed(3))

# ------------------------------------------------------- newest tools
T("fine_tweezers", "Fine Tweezers", 1, "common", dmg(2, "print"))
T("cutting_mat", "Cutting Mat", 1, "common", armor(3))
T("magnifier_lamp", "Magnifier Lamp", 2, "uncommon", draw(1), heal(2, "printer"))
T("fire_extinguisher", "Fire Extinguisher", 3, "rare", jam("all"))
T("dry_box", "Dry Box", 3, "epic", spool(10), draw(1))
T("resin_printer", "Resin Printer", 6, "legendary", dmg(3, "all"), heal(4, "printer"))

# ------------------------------------------------- newest tools, second wave
T("cable_management", "Cable Management", 2, "common", armor(2), draw(1))
T("post_processing_kit", "Post-Processing Kit", 2, "uncommon", heal(3, "all"))
T("glow_filament", "Glow Filament", 2, "uncommon", buff(1, 1, "all"))
T("pressure_advance", "Pressure Advance", 3, "rare", buff(2, 0, "print", ["rush"]), speed(1))
T("power_loss_recovery", "Power Loss Recovery", 4, "rare", heal(5, "printer"), spool(4))
T("thermal_runaway", "Thermal Runaway", 4, "epic", dmg(5, "enemy"))
T("firmware_update", "Firmware Update", 5, "epic", buff(2, 2, "all"))
T("open_source_blueprint", "Open Source Blueprint", 7, "legendary", summon(2), draw(2))

# -------------------------------------------------------------- equipment
U("rubber_feet", "Rubber Feet", 1, "common", 0, 3)
U("mini_fan", "Mini Fan", 1, "common", 2, 0)
U("spool_holder", "Spool Holder", 2, "common", 1, 3)
U("cable_chain", "Cable Chain", 2, "common", 2, 1)
U("nozzle_guard", "Nozzle Guard", 2, "common", 1, 2, ["guard"])

U("heat_sink", "Heat Sink", 3, "uncommon", 2, 2, ["scorch"])
U("grappling_hook", "Grappling Hook", 3, "uncommon", 2, 1, ["thief"])
U("carbon_plate", "Carbon Plate", 3, "uncommon", 2, 4)
U("servo_arms", "Servo Arms", 3, "uncommon", 3, 2)
U("turbo_fan", "Turbo Fan", 3, "uncommon", 2, 2, ["rush"])

U("silk_cape", "Silk Cape", 3, "rare", 2, 3, ["brim"])
U("spiked_gauntlets", "Spiked Gauntlets", 4, "rare", 3, 3, ["thief"])
U("thermal_core", "Thermal Core", 4, "rare", 3, 3, ["scorch"])
U("overdrive_chip", "Overdrive Chip", 4, "rare", 3, 2, ["twin"])

U("exo_frame", "Exo Frame", 5, "epic", 4, 5, ["guard"])
U("phoenix_wings", "Phoenix Wings", 5, "epic", 4, 3, ["rush", "scorch"])
U("vampire_fangs", "Vampire Fangs", 4, "epic", 3, 3, ["siphon", "thief"])
U("quad_nozzle", "Quad Nozzle", 5, "epic", 3, 3, ["twin", "scorch"])

U("titan_exosuit", "Titan Exosuit", 6, "legendary", 5, 6, ["guard", "brim"])
U("omega_core", "Omega Core", 5, "legendary", 4, 4, ["twin", "thief", "scorch"])

# -------------------------------------------------- newest equipment
U("bowden_whip", "Bowden Whip", 2, "uncommon", 2, 1, ["thief"])
U("glass_bed_shield", "Glass Bed Shield", 3, "uncommon", 1, 5, ["guard"])
U("lead_screw_lance", "Lead Screw Lance", 4, "rare", 4, 2, ["rush"])
U("hotend_crown", "Hotend Crown", 5, "epic", 3, 4, ["scorch", "brim"])

# ------------------------------------------- newest equipment, second wave
U("belt_tensioner", "Belt Tensioner", 1, "common", 1, 2)
U("linear_rails", "Linear Rails", 2, "uncommon", 1, 3, ["rush"])
U("direct_drive_gearbox", "Direct Drive Gearbox", 4, "rare", 3, 3, ["siphon"])
U("enclosure_panels", "Enclosure Panels", 4, "rare", 1, 6, ["guard", "brim"])
U("laser_engraver", "Laser Engraver", 5, "epic", 5, 2, ["twin", "scorch"])
U("corexy_frame", "CoreXY Frame", 6, "legendary", 4, 6, ["guard", "twin", "rush"])

assert len({c["id"] for c in TOOLS + UPGRADES}) == len(TOOLS) + len(UPGRADES)
