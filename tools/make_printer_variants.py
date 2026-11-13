#!/usr/bin/env python3
"""Builds the six Printer colourways from the base printer art.

Recolours only the blue/cyan parts (frame paint, filament, runes) and leaves
the brass and steel alone, then writes assets/printers/<id>.png.

    python3 tools/make_printer_variants.py      (needs Pillow + numpy)
"""
import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.join(os.path.dirname(__file__), "..")
PARTS = os.path.join(os.path.dirname(__file__), "printer_parts")
SS = 2  # drawing supersample
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
    # Later Printers: the same machine with their own parts (see DECORATE).
    "frost_chamber": (192, 0.85, 1.12),
    "cyclone_rig": (160, 0.65, 1.12),
    "resin_vat": (32, 0.6, 0.95),
    "delta_rig": (322, 0.8, 1.0),
    "pellet_press": (92, 0.5, 0.9),
    "titan_gantry": (0, 0.08, 0.78),
}


# ------------------------------------------------------------- decorations
# Coordinates are in the 656x599 printer image. The bed is the quad
# front-left, back-left, back-right, front-right.
BED = [(150, 398), (258, 352), (520, 372), (405, 430)]


def part(name):
    img = Image.open(os.path.join(PARTS, name + ".png")).convert("RGBA")
    return img.crop(img.getchannel("A").getbbox())


def paste_part(img, name, box, align="bottom"):
    """Fits a rendered part into box=(x0, y0, x1, y1), keeping its shape."""
    p = part(name)
    w, h = box[2] - box[0], box[3] - box[1]
    k = min(w / p.width, h / p.height)
    p = p.resize((max(1, round(p.width * k)), max(1, round(p.height * k))), Image.LANCZOS)
    x = box[0] + (w - p.width) // 2
    y = box[3] - p.height if align == "bottom" else box[1]
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    shadow.paste(Image.new("RGBA", p.size, (0, 0, 0, 120)), (x + 5, y + 6), p)
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(4)))
    img.alpha_composite(p, (x, y))
    return (x, y, p.width, p.height)


def hose(img, start, col, width=7):
    """A feed hose from a part to where the filament line enters the frame."""
    L = Layer(img.size)
    pts = bez(start, (start[0] + 6, 28), (170, 52), 30)
    L.line(pts, (16, 18, 24, 255), width + 4)
    L.line(pts, col, width)
    L.line([(x + 1, y - 1) for x, y in pts], (255, 255, 255, 90), 2)
    L.disc(start, width * 0.8, (217, 160, 42, 255), (110, 70, 10, 255))
    L.disc((170, 52), width * 0.9, (217, 160, 42, 255), (110, 70, 10, 255))
    img.alpha_composite(L.done())


def erase_spool(img):
    """Takes the filament spool and its bracket off the left of the machine."""
    a = np.asarray(img).copy()
    a[100:420, 0:131, 3] = 0
    img.paste(Image.fromarray(a), (0, 0))


class Layer:
    """A transparent drawing layer, supersampled for smooth edges."""

    def __init__(self, size):
        self.size = size
        self.im = Image.new("RGBA", (size[0] * SS, size[1] * SS), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.im)

    def pts(self, points):
        return [(x * SS, y * SS) for x, y in points]

    def poly(self, points, fill, outline=None, width=1):
        self.d.polygon(self.pts(points), fill=fill, outline=outline)
        if outline and width > 1:
            self.line(points + [points[0]], outline, width)

    def line(self, points, col, width):
        self.d.line(self.pts(points), fill=col, width=round(width * SS), joint="curve")

    def disc(self, c, r, fill, outline=None):
        self.d.ellipse([(c[0] - r) * SS, (c[1] - r) * SS, (c[0] + r) * SS, (c[1] + r) * SS], fill=fill, outline=outline, width=SS)

    def done(self):
        return self.im.resize(self.size, Image.LANCZOS)


def bez(p0, p1, p2, n=24):
    return [((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0],
             (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]) for t in [i / n for i in range(n + 1)]]


def frost_chamber(img):
    L = Layer(img.size)
    # a glass front over the build volume, with a frosty rim
    pane = [(168, 112), (500, 112), (524, 424), (402, 436), (150, 402)]
    L.poly(pane, (170, 225, 255, 34))
    L.poly([(180, 118), (230, 118), (190, 400), (156, 398)], (255, 255, 255, 30))
    L.poly([(300, 118), (318, 118), (282, 410), (268, 408)], (255, 255, 255, 22))
    L.line(pane + [pane[0]], (205, 240, 255, 170), 4)
    L.line([(172, 116), (498, 116)], (255, 255, 255, 220), 3)
    # icicles hang from the top bar
    x = 196
    while x < 490:
        h = 18 + (x * 7 % 26)
        L.poly([(x - 7, 104), (x + 7, 104), (x + 1, 104 + h)], (225, 248, 255, 235), (140, 205, 240, 255))
        x += 17 + (x * 3 % 9)
    # frost creeping up the corners
    for cx, cy, sgn in [(160, 404, 1), (518, 426, -1)]:
        for k in range(4):
            ang = math.radians(-96 + sgn * 22 * k)
            r = 20 + 6 * (k % 2)
            L.line([(cx, cy), (cx + math.cos(ang) * r, cy + math.sin(ang) * r)], (235, 250, 255, 200), 2)
    img.alpha_composite(L.done())


def cyclone_rig(img):
    paste_part(img, "cyclone_turbine", (468, 168, 640, 340))
    L = Layer(img.size)
    # wind streaks across the build volume
    for (y0, y1, a) in [(210, 188, 150), (255, 262, 170), (300, 330, 140)]:
        pts = bez((505, y0), (400, y0 - 26), (250, y1))
        for i in range(len(pts) - 1):
            fade = i / (len(pts) - 1)
            L.line([pts[i], pts[i + 1]], (190, 255, 230, int(a * (1 - fade))), 4 - 2.2 * fade)
    img.alpha_composite(L.done())


def resin_vat(img):
    erase_spool(img)
    x, y, w, h = paste_part(img, "resin_bottle", (2, 128, 142, 404))
    hose(img, (x + w * 0.86, y + h * 0.05), (232, 150, 40, 255))
    L = Layer(img.size)
    # an amber resin vat sits on the bed, lit from below
    vat = [(BED[0][0] - 4, BED[0][1] - 8), (BED[1][0], BED[1][1] - 6), (BED[2][0] + 4, BED[2][1] - 8), (BED[3][0] + 4, BED[3][1] - 6)]
    L.poly(vat, (255, 160, 40, 70))
    L.line(vat + [vat[0]], (255, 190, 80, 235), 5)
    L.line([vat[0], vat[3]], (255, 225, 140, 255), 3)
    for k in range(5):
        t = 0.18 + k * 0.16
        L.disc((BED[0][0] + 40 + 280 * t, BED[0][1] - 18 - 10 * math.sin(k * 2.0) - 20 * t), 3 + (k % 2) * 2, (255, 225, 140, 210))
    # a violet UV glow under the bed
    L.line([(BED[0][0] + 20, BED[0][1] + 18), (BED[3][0] - 10, BED[3][1] + 16)], (190, 110, 255, 200), 5)
    img.alpha_composite(L.done().filter(ImageFilter.GaussianBlur(0.6)))


def delta_rig(img):
    L = Layer(img.size)
    nozzle = (346, 250)
    for top in [(176, 86), (338, 72), (498, 86)]:
        L.line([nozzle, top], (20, 24, 32, 255), 11)
        L.line([nozzle, top], (170, 180, 195, 255), 7)
        L.line([(nozzle[0] + 2, nozzle[1] - 2), (top[0] + 2, top[1] + 2)], (235, 240, 248, 255), 2)
        L.disc(top, 9, (217, 160, 42, 255), (110, 70, 10, 255))
        L.disc(top, 4, (255, 225, 130, 255))
    L.disc(nozzle, 12, (217, 160, 42, 255), (110, 70, 10, 255))
    L.disc(nozzle, 5, (255, 225, 130, 255))
    img.alpha_composite(L.done())


def pellet_press(img):
    erase_spool(img)
    x, y, w, h = paste_part(img, "pellet_hopper", (0, 60, 146, 414))
    hose(img, (x + w * 0.52, y + h * 0.04), (120, 132, 148, 255))


def titan_gantry(img):
    L = Layer(img.size)
    # a thick steel crown on the top bar, with rivets
    L.poly([(140, 52), (592, 52), (592, 70), (140, 70)], (92, 100, 112, 255), (30, 34, 42, 255), 3)
    L.line([(144, 56), (588, 56)], (190, 200, 214, 255), 2)
    for x in range(160, 590, 40):
        L.disc((x, 62), 4, (217, 160, 42, 255), (110, 70, 10, 255))
    # hazard bands and gussets on the uprights
    for (x0, x1, y0, y1) in [(150, 214, 296, 332), (506, 588, 150, 186)]:
        L.poly([(x0, y0), (x1, y0), (x1, y1), (x0, y1)], (30, 34, 42, 255))
        k = x0 - (y1 - y0)
        while k < x1:
            a, b = max(k, x0), min(k + 14, x1)
            top = [(a, y0), (b, y0), (min(b + (y1 - y0), x1), y1), (min(a + (y1 - y0), x1), y1)]
            if (a + (y1 - y0)) <= x1 or b <= x1:
                L.poly([(max(k, x0), y0), (min(k + 14, x1), y0), (min(k + 14 - (y1 - y0), x1) if False else min(k + 14 + (y1 - y0), x1), y1), (min(k + (y1 - y0), x1), y1)], (255, 196, 30, 255))
            k += 28
        L.line([(x0, y0), (x1, y0), (x1, y1), (x0, y1), (x0, y0)], (20, 22, 28, 255), 2.5)
    for (a, b, c) in [((150, 420), (150, 372), (192, 420)), ((588, 420), (588, 372), (546, 420))]:
        L.poly([a, b, c], (92, 100, 112, 255), (30, 34, 42, 255), 3)
        L.disc((a[0] + (c[0] - a[0]) * 0.18, a[1] - 14), 4, (217, 160, 42, 255))
    img.alpha_composite(L.done())


DECORATE = {
    "frost_chamber": frost_chamber,
    "cyclone_rig": cyclone_rig,
    "resin_vat": resin_vat,
    "delta_rig": delta_rig,
    "pellet_press": pellet_press,
    "titan_gantry": titan_gantry,
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
        if name in DECORATE:
            DECORATE[name](img)
        img.save(os.path.join(OUT, name + ".png"))
        print("wrote", name)


if __name__ == "__main__":
    main()
