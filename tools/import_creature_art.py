#!/usr/bin/env python3
"""Brings painted creature art into the game in the same shape as the
starters' (Cinderpaw, Aquafin, Voltwig): a 1152x768 sheet of eight 288x384
poses on a transparent background. (The raw, unpainted look for cards you do
not own is made from the sheet by a shader, so no second image is needed.)

Drop images into art_inbox/ (kept out of Git), named by card id:

    art_inbox/<id>.png            a whole 4x2 sheet, poses in the usual order
    art_inbox/<id>_0.png ... _7   or eight separate poses

Pose order: 0 stand, 1 crouch, 2 stride, 3 proud (tail up), 4 wind-up,
5 strike (mouth open), 6 low, 7 hurt. A plain background (black, white, grey
or green) is removed; transparent images are used as they are. Every pose is
scaled by the same amount and stood on the same line, so the frames line up
when the game swaps them.

    uv run --with numpy --with pillow python tools/import_creature_art.py [id ...]
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
INBOX = os.path.join(ROOT, "art_inbox")
OUT = os.path.join(ROOT, "assets", "creatures", "2d")
CELL_W, CELL_H = 288, 384
FIT_W, FIT_H, BASE = 264, 352, 375


def cut_background(img):
    """Transparent where the picture matches the colour of its corners."""
    img = img.convert("RGBA")
    a = np.array(img).astype(float)
    if (a[:, :, 3] < 10).mean() > 0.2:
        return img
    corners = np.array([a[2, 2, :3], a[2, -3, :3], a[-3, 2, :3], a[-3, -3, :3]])
    bg = np.median(corners, axis=0)
    dist = np.sqrt(((a[:, :, :3] - bg) ** 2).sum(axis=2))
    alpha = np.clip((dist - 28.0) / 40.0, 0.0, 1.0) * 255.0
    out = np.array(img)
    out[:, :, 3] = alpha.astype(np.uint8)
    res = Image.fromarray(out)
    # Soften the cut edge by a pixel so it does not look jagged.
    res.putalpha(res.getchannel("A").filter(ImageFilter.GaussianBlur(0.6)))
    return res


def frames_for(cid):
    whole = os.path.join(INBOX, cid + ".png")
    if os.path.exists(whole):
        sheet = cut_background(Image.open(whole))
        w, h = sheet.size
        return [sheet.crop((i % 4 * w // 4, i // 4 * h // 2, (i % 4 + 1) * w // 4, (i // 4 + 1) * h // 2)) for i in range(8)]
    parts = [os.path.join(INBOX, "%s_%d.png" % (cid, i)) for i in range(8)]
    if all(os.path.exists(p) for p in parts):
        return [cut_background(Image.open(p)) for p in parts]
    return None


def build(cid):
    frames = frames_for(cid)
    if frames is None:
        print("no art for", cid)
        return False
    boxes = [f.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox() for f in frames]
    if any(b is None for b in boxes):
        print("an empty pose in", cid)
        return False
    # One scale for the whole sheet: the biggest pose fits the cell.
    k = min(min(FIT_W / (b[2] - b[0]), FIT_H / (b[3] - b[1])) for b in boxes)
    sheet = Image.new("RGBA", (CELL_W * 4, CELL_H * 2), (0, 0, 0, 0))
    for i, (f, b) in enumerate(zip(frames, boxes)):
        fig = f.crop(b)
        fig = fig.resize((max(1, round(fig.width * k)), max(1, round(fig.height * k))), Image.LANCZOS)
        x = i % 4 * CELL_W + (CELL_W - fig.width) // 2
        y = i // 4 * CELL_H + BASE - fig.height
        sheet.alpha_composite(fig, (x, y))
    sheet.save(os.path.join(OUT, cid + "_sprite_sheet.png"))
    print("imported", cid)
    return True


def main():
    wanted = sys.argv[1:]
    if not wanted:
        names = sorted(os.listdir(INBOX)) if os.path.isdir(INBOX) else []
        wanted = sorted({n.rsplit(".", 1)[0].rsplit("_", 1)[0] if n[:-4].rsplit("_", 1)[-1].isdigit() else n[:-4] for n in names if n.endswith(".png")})
    for cid in wanted:
        build(cid)


if __name__ == "__main__":
    main()
