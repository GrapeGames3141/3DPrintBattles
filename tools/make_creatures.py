#!/usr/bin/env python3
"""Builds the art for every creature in tools/catalog/creatures.py.

  "base:hue:finish[:hue2]"  a base creature's sprite sheet and raw print,
                            recoloured and printed in a filament finish
                            (tools/creature_finish.py); rare and better
                            creatures also get their element's look
                            (tools/creature_fx.py)
  "src:name"                a design cut out of tools/creature_sources/,
                            fitted to a single sprite cell

    uv run --with numpy --with pillow --with scipy python tools/make_creatures.py [id ...]
"""
import os
import sys
import zlib

import numpy as np
from PIL import Image

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, ".."))
import creature_fx  # noqa: E402
import creature_finish  # noqa: E402
from make_creature_variants import recolor  # noqa: E402
from catalog.creatures import CREATURES  # noqa: E402

ROOT = os.path.join(HERE, "..", "assets", "creatures", "2d")
SRC = os.path.join(HERE, "creature_sources")


def fit(img, box_w, box_h, canvas_w, canvas_h, bottom):
    """Scales a cut-out to fit, centred, standing on the line `bottom`."""
    bbox = img.getchannel("A").getbbox()
    img = img.crop(bbox)
    k = min(box_w / img.width, box_h / img.height)
    img = img.resize((max(1, round(img.width * k)), max(1, round(img.height * k))), Image.LANCZOS)
    out = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    out.alpha_composite(img, ((canvas_w - img.width) // 2, bottom - img.height))
    return out


def make(c):
    cid, spec = c["id"], c["art"]
    sheet_path = os.path.join(ROOT, f"{cid}_sprite_sheet.png")
    raw_path = os.path.join(ROOT, "raw", f"{cid}_raw_print.png")
    if spec.startswith("src:"):
        cut = Image.open(os.path.join(SRC, spec[4:] + ".png")).convert("RGBA")
        fit(cut, 352, 470, 384, 512, 500).save(sheet_path)
        fit(cut, 1150, 1150, 1254, 1254, 1220).save(raw_path)
        return
    base, hue, finish, *rest = spec.split(":")
    hue = float(hue)
    hue2 = float(rest[0]) if rest else hue + 40
    recipe = None
    if c["rarity"] in ("rare", "epic", "legendary"):
        recipe = creature_fx.ELEMENT_RECIPES.get(c["element"])
    for kind, src_path, dst in (("sheet", os.path.join(ROOT, f"{base}_sprite_sheet.png"), sheet_path),
                                ("raw", os.path.join(ROOT, "raw", f"{base}_raw_print.png"), raw_path)):
        img = Image.open(src_path)
        img = recolor(img, hue, 0.65, 1.0, 1.0)
        rng = np.random.default_rng(zlib.crc32((cid + kind).encode()))
        if finish != "pla":
            img = creature_finish.apply_finish(img, finish, hue, hue2, rng)
        img = creature_fx.apply_recipe(img, recipe, cid, kind)
        img.save(dst)


def main():
    only = set(sys.argv[1:])
    for c in CREATURES:
        if only and c["id"] not in only:
            continue
        make(c)
        print("made", c["id"])


if __name__ == "__main__":
    main()
