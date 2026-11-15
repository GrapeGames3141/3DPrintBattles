#!/usr/bin/env python3
"""Writes art_brief/prompts.md and art_brief/creatures.csv: one image-generator prompt per creature that
does not yet have painted art, worded to match the starters' look (Cinderpaw,
Aquafin, Voltwig). Generate each, save it as art_inbox/<id>.png, then run
tools/import_creature_art.py.

    python3 tools/art_prompts.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import catalog.wave6  # noqa: E402,F401
from catalog.creatures import CREATURES  # noqa: E402

STYLE = ("A sprite sheet of one cute chibi creature that looks like a glossy 3D-printed toy figure, made of {colors} PLA "
         "filament with very fine visible print layer lines, smooth rounded shapes, big expressive eyes, soft studio lighting. "
         "Exactly 8 poses of the same creature in a grid of 4 columns and 2 rows on a plain solid black background, every pose "
         "the same size, standing on the same ground line, side three-quarter view facing right. Poses in order: "
         "1 standing idle, 2 crouching ready, 3 walking mid-stride, 4 proud with tail or crest raised, 5 winding up to attack, "
         "6 lunging attack with mouth open, 7 low sneaking crouch, 8 flinching hurt with eyes squeezed shut. "
         "No text, no shadows on the background, no frames.")
COLORS = {"Fire": "red, orange and warm yellow", "Water": "ocean blue, teal and pearl white", "Lightning": "bright yellow and graphite black",
          "Nature": "leaf green, bark brown and blossom pink", "Ice": "pale ice blue, white and lilac", "Stone": "granite grey, sandstone and amber",
          "Wind": "mint, white and sky blue", "Arcane": "violet, magenta and gold", "Neutral": "orange, white and blue"}
PLAN_WORDS = {"quad": "a four-legged beast", "biped": "a creature standing on two legs", "bird": "a round bird", "serpent": "a serpent",
              "bug": "a beetle-like bug", "blob": "a squishy blob", "fish": "a fish", "floater": "a floating spirit", "shell": "a shelled creature",
              "dragon": "a dragon with wings", "horse": "a horse of legend", "beast": "a mythical beast", "hydra": "a many-headed hydra",
              "kraken": "a kraken with tentacles", "egg": "a dragon egg with eyes peeking out of a crack", "phoenix": "a phoenix of flame",
              "part": "a living machine part", "boat": "a little boat (a 3D Benchy) with a face"}


def describe(c):
    lk = c.get("look", {})
    plan = lk.get("plan", "")
    bits = []
    if plan == "hybrid":
        frame = {"quad": "a four-legged beast", "biped": "a figure on two legs", "taur": "a centaur-like creature (an upper body on a lower beast body)",
                 "kraken": "an armoured torso on curling tentacles", "seahorse": "a winged horse with a fish tail", "wyrm": "a long-bodied wyrm",
                 "crawler": "a many-legged crawler", "rover": "a little rover on wheels"}.get(lk.get("frame"), "a creature")
        bits.append(frame)
        if lk.get("head"):
            bits.append("with a %s head" % lk["head"])
        if lk.get("lower"):
            bits.append("and a %s lower body" % lk["lower"])
        extras = [e.replace("_", " ") for e in lk.get("extras", []) if e not in ("gold_feathers", "gears")]
        if extras:
            bits.append("featuring " + ", ".join(extras))
        if lk.get("heads", 1) > 1:
            bits.append("with %d heads" % lk["heads"])
        bits.append("with small brass gears at the joints")
    else:
        bits.append(PLAN_WORDS.get(plan, "a creature"))
        for k, words in (("wings", "with %s wings"), ("horns", "with %s horns"), ("tail", "with a %s-tipped tail")):
            if lk.get(k) and lk[k] not in (True, "none"):
                bits.append(words % lk[k])
        if lk.get("horn"):
            bits.append("with a spiral golden horn")
        if lk.get("heads", 1) > 1:
            bits.append("with %d heads" % lk["heads"])
    return " ".join(bits)


# Hand-written concepts for the creatures drawn from the reference pictures.
CONCEPTS = {
    "scarab_medusa": "a Medusa centaur: a woman's upper body with a crown of snakes for hair on the body of a giant scarab beetle with six jointed legs, carved shell, brass gears at the joints",
    "pyre_griffin": "a phoenix griffin: an eagle head with a flame crest, fiery feathered wings, a lion body in red armour plates with a glowing fire core in its chest, a flaming tail",
    "scylla_kraken": "a Scylla kraken: a spiky armoured torso with a ring of snarling wolf heads at its waist standing on curling segmented tentacles",
    "anubis_harpy": "an Anubis harpy: a jackal-headed warrior with golden feathered wings, eagle talon feet and a long segmented black-and-gold tail",
    "chimera_raiju": "a chimera raiju: a copper-armoured lion with ram horns, a lightning-bolt mane, a coiled spring along its spine and a snake-headed tail",
    "wendigo_sphinx": "a sphinx wendigo stag: a pale lion with huge branching antlers, feathered wings and a golden lion-face mask",
    "pegasus_leviathan": "a pegasus leviathan: a white armoured winged horse whose hindquarters become a translucent blue fish tail with fins",
    "foo_cerberus": "a cerberus foo dog: a three-headed guardian lion-dog with curly foo-dog manes, carbon-black armour and glowing cyan claws",
    "quetzal_hydra": "a hydra quetzalcoatl: three serpent heads on ribbed necks with feather crests, big Aztec feathered wings, teal and gold",
    "minotaur_kitsune": "a minotaur kitsune: a muscular bronze bull-headed warrior with nine glowing orange fox tails",
    "nebula_strider": "a nebula strider: a slim star knight with a spiky star crown and translucent space-sail wings",
    "solar_flare_rover": "a solar-flare rover: a little six-wheeled rover creature with solar-panel fins and a curious sensor head",
    "void_stalker": "a void stalker: a black spider-like stalker with a purple spiral spine and a mechanical sting",
    "asteroid_grubber": "an asteroid grubber: a rocky boulder creature with drill claws digging on stubby legs",
    "lunar_crawler": "a lunar crawler: a silver crab-like crawler with a radar-dish head on many thin legs",
    "nova_burster": "a nova burster: a golden star-fire golem bursting with flame spikes and a blazing core",
    "starlight_drifter": "a starlight drifter: a long segmented space serpent with solar-blade fins",
    "meteorite_golem": "a meteorite golem: a hulking black rock golem with copper seams and a glowing magma core",
    "quasar_serpent": "a quasar serpent: a gold-and-blue armoured serpent with glowing spines",
    "orbit_flyer": "an orbit flyer: a wasp-like flyer with a thruster backpack, clear wings and a striped segmented tail",
    "cockatrice": "a cockatrice: a rooster-headed beast with a crown, bird legs and a snake for a tail",
    "wolpertinger": "a wolpertinger: a little horned hare with antlers and feathered wings",
    "ammit": "Ammit the Devourer: a crocodile-headed lion-hippo with a golden mask and flaming mane",
    "tengu": "a tengu: a crow-faced mountain spirit warrior with a red mask and black feathered wings",
}


def main():
    rows = [c for c in CREATURES if c.get("art") == "gen" or str(c.get("art", "")).startswith(("rig:", "src:"))]
    # The reference-inspired hybrids first, then cards, then tokens.
    rows.sort(key=lambda c: (c["id"] not in CONCEPTS, bool(c.get("token")), c["element"], c["name"]))
    csv_rows = []
    out = ["# Prompts, one per creature", "",
           "See README.md for the rules every image must follow. Save each result as `art_inbox/<id>.png`.",
           "", "%d creatures, the reference-inspired hybrids first. Tokens (later evolution stages, never in packs) are marked." % len(rows), ""]
    for c in rows:
        colors = COLORS.get(c["element"], COLORS["Neutral"])
        if c.get("look", {}).get("colors"):
            colors = "two-tone silk " + colors
        what = CONCEPTS.get(c["id"]) or describe(c)
        line = "%s, called %s. %s" % (what[0].upper() + what[1:], c["name"], STYLE.format(colors=colors))
        csv_rows.append((c["id"], c["name"], c["element"], c["rarity"], "token" if c.get("token") else "card", line))
        out.append("## %s `%s`%s" % (c["name"], c["id"], " (token)" if c.get("token") else ""))
        out.append("")
        out.append(line.replace("..", "."))
        out.append("")
    folder = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "art_brief")
    with open(os.path.join(folder, "prompts.md"), "w") as f:
        f.write("\n".join(out))
    import csv
    with open(os.path.join(folder, "creatures.csv"), "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["id", "name", "element", "rarity", "kind", "prompt"])
        w.writerows(csv_rows)
    print("wrote art_brief/prompts.md and creatures.csv", len(rows))


if __name__ == "__main__":
    main()
