#!/usr/bin/env python3
"""Builds the second wave of creatures from existing sprite sheets.

Each new creature takes an existing creature's sheet and raw print and
recolours it into another element: the dominant colour is turned to the target
hue, and grey bodies (stone, metal) are tinted so they take the colour too.
Eyes, outlines and highlights are left alone.

    uv run --with numpy --with pillow python tools/make_creature_variants.py
"""
import os

import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..", "assets", "creatures", "2d")

# new id: (base id, target hue in degrees, grey-body saturation 0..1, saturation x, brightness x)
VARIANTS = {
    "magmaback": ("stoneback", 12, 0.78, 1.0, 1.0),
    "cinderowl": ("brambleowl", 16, 0.7, 1.05, 1.0),
    "rainotter": ("sparkotter", 205, 0.7, 1.0, 1.0),
    "tidemaw": ("ironmaw", 188, 0.62, 1.0, 1.0),
    "stormstag": ("runestag", 52, 0.75, 1.1, 1.1),
    "sparkling": ("frostling", 54, 0.75, 1.15, 1.08),
    "mosshopper": ("galehopper", 112, 0.7, 1.0, 0.95),
    "thornfox": ("miragefox", 128, 0.65, 1.0, 0.95),
    "frostelk": ("thunderelk", 192, 0.6, 0.95, 1.1),
    "icicle": ("voltwig", 184, 0.65, 0.9, 1.1),
    "pebblefin": ("aquafin", 30, 0.38, 0.8, 0.9),
    "quartzdrake": ("glassdrake", 36, 0.4, 0.8, 1.05),
    "zephyrcat": ("cinderpaw", 158, 0.55, 0.9, 1.1),
    "gustgriffin": ("coalgriffin", 150, 0.55, 0.9, 1.1),
    "arcanitan": ("verdantitan", 276, 0.6, 1.05, 1.0),
    "starwhale": ("tidewhale", 284, 0.6, 1.05, 1.0),
}


def recolor(img, target, grey_sat, sat_mul, val_mul):
    rgba = img.convert("RGBA")
    alpha = np.asarray(rgba.getchannel("A"))
    hsv = np.asarray(rgba.convert("RGB").convert("HSV"), dtype=np.float32)
    hue = hsv[..., 0] * (360.0 / 255.0)
    sat = hsv[..., 1] / 255.0
    val = hsv[..., 2] / 255.0
    body = (alpha > 128) & (sat > 0.22) & (val > 0.22)
    if body.sum() > 50:
        w = (sat * val)[body]
        ang = np.deg2rad(hue[body])
        dominant = np.rad2deg(np.arctan2((np.sin(ang) * w).sum(), (np.cos(ang) * w).sum())) % 360.0
    else:
        dominant = target
    delta = target - dominant
    coloured = sat > 0.12
    grey = (~coloured) & (val > 0.16) & (val < 0.92)
    new_hue = np.where(coloured, (hue + delta) % 360.0, np.where(grey, target, hue))
    new_sat = np.where(grey, np.maximum(sat, grey_sat * (0.5 + 0.5 * val)), np.clip(sat * sat_mul, 0, 1))
    new_val = np.clip(val * np.where(coloured | grey, val_mul, 1.0), 0, 1)
    out = np.stack([new_hue * (255.0 / 360.0), new_sat * 255.0, new_val * 255.0], axis=-1)
    rgb = Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "HSV").convert("RGB")
    rgb.putalpha(rgba.getchannel("A"))
    return rgb


def main():
    for new, (base, hue, grey, s, v) in VARIANTS.items():
        sheet = Image.open(os.path.join(ROOT, f"{base}_sprite_sheet.png"))
        recolor(sheet, hue, grey, s, v).save(os.path.join(ROOT, f"{new}_sprite_sheet.png"))
        raw = Image.open(os.path.join(ROOT, "raw", f"{base}_raw_print.png"))
        recolor(raw, hue, grey, s, v).save(os.path.join(ROOT, "raw", f"{new}_raw_print.png"))
        print("wrote", new)


if __name__ == "__main__":
    main()
