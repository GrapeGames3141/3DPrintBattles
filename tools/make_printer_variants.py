#!/usr/bin/env python3
"""Builds the six Printer colourways from the base printer art.

Recolours only the blue/cyan parts (frame paint, filament, runes) and leaves
the brass and steel alone, then writes assets/printers/<id>.png.

    python3 tools/make_printer_variants.py      (needs Pillow + numpy)
"""
import os

import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..")
SRC = os.path.join(ROOT, "assets", "ui", "arcane_forge_printer.png")
OUT = os.path.join(ROOT, "assets", "printers")

# id: (target hue in degrees, saturation multiplier, value multiplier)
VARIANTS = {
    "tide_press": (205, 1.0, 1.0),
    "ember_forge": (8, 1.15, 1.05),
    "volt_rig": (48, 1.2, 1.15),
    "stone_kiln": (28, 0.38, 1.0),
    "verdant_loom": (128, 1.0, 1.0),
    "arcane_engine": (278, 1.05, 1.05),
    # Later Printers: same machine until they get their own models.
    "frost_chamber": (192, 0.85, 1.12),
    "cyclone_rig": (160, 0.65, 1.12),
    "resin_vat": (32, 0.6, 0.95),
    "delta_rig": (322, 0.8, 1.0),
    "pellet_press": (92, 0.5, 0.9),
    "titan_gantry": (0, 0.08, 0.78),
}


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    src = Image.open(SRC).convert("RGBA")
    src = src.resize((src.width // 2, src.height // 2), Image.LANCZOS)
    alpha = src.getchannel("A")
    hsv = np.asarray(src.convert("RGB").convert("HSV"), dtype=np.float32)
    hue = hsv[..., 0] * (360.0 / 255.0)
    # How strongly each pixel belongs to the blue/cyan family (soft edges).
    centre, width = 210.0, 62.0
    dist = np.abs(hue - centre)
    weight = np.clip((width - dist) / 18.0, 0.0, 1.0)
    weight *= np.clip(hsv[..., 1] / 60.0, 0.0, 1.0)
    for name, (target, sat_mul, val_mul) in VARIANTS.items():
        out = hsv.copy()
        shifted = (target + (hue - centre) * 0.35) % 360.0
        new_hue = hue * (1.0 - weight) + shifted * weight
        # Blend across the wrap-around properly for pixels being recoloured.
        new_hue = np.where(weight > 0.5, shifted, new_hue)
        out[..., 0] = (new_hue % 360.0) * (255.0 / 360.0)
        out[..., 1] = np.clip(out[..., 1] * (1.0 + (sat_mul - 1.0) * weight), 0, 255)
        out[..., 2] = np.clip(out[..., 2] * (1.0 + (val_mul - 1.0) * weight), 0, 255)
        img = Image.fromarray(out.astype(np.uint8), "HSV").convert("RGB")
        img.putalpha(alpha)
        img.save(os.path.join(OUT, name + ".png"))
        print("wrote", name)


if __name__ == "__main__":
    main()
