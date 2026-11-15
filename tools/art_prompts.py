#!/usr/bin/env python3
"""Writes docs/art_prompts.md: one image-generator prompt per creature that
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


def main():
    rows = [c for c in CREATURES if c.get("art") == "gen" or str(c.get("art", "")).startswith(("rig:", "src:"))]
    out = ["# Painted art prompts", "",
           "Every creature below is still a placeholder 3D model. Paste its prompt into an image generator, save the result as",
           "`art_inbox/<id>.png` and run `uv run --with numpy --with pillow python tools/import_creature_art.py`.",
           "", "%d creatures. Tokens (later evolution stages) are marked." % len(rows), ""]
    for c in rows:
        colors = COLORS.get(c["element"], COLORS["Neutral"])
        if c.get("look", {}).get("colors"):
            colors = "two-tone silk " + colors
        line = "%s, called %s. %s" % (describe(c)[0].upper() + describe(c)[1:], c["name"], STYLE.format(colors=colors))
        out.append("## %s `%s`%s" % (c["name"], c["id"], " (token)" if c.get("token") else ""))
        out.append("")
        out.append(line.replace("..", "."))
        out.append("")
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "docs", "art_prompts.md")
    with open(path, "w") as f:
        f.write("\n".join(out))
    print("wrote", path, len(rows))


if __name__ == "__main__":
    main()
