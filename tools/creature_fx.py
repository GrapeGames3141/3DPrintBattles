"""Element looks for the recoloured creatures.

A recolour alone leaves a creature with its original's shape. These effects
give each element its own material and silhouette, and they work from the
picture itself (its outline and its creases), so they land correctly on every
pose in a sprite sheet and on the raw prints:

  surface:     glowing cracks (Fire, Lightning), frost rime, moss, water
               droplets, a starfield, stone speckle
  silhouette:  flames, ice or quartz crystals, lightning bolts, leaves, fins,
               thorns, wind wisps, bubbles, floating orbs and stars

Used by tools/make_creature_variants.py.
"""
import math
import zlib

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage as ndi

SS = 2


# ------------------------------------------------------------------ helpers

class Canvas:
    """A transparent supersampled layer the decorations are drawn on."""

    def __init__(self, size):
        self.size = size
        self.im = Image.new("RGBA", (size[0] * SS, size[1] * SS), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.im)

    def pt(self, p):
        return (p[0] * SS, p[1] * SS)

    def poly(self, pts, fill, outline=None):
        self.d.polygon([self.pt(p) for p in pts], fill=fill, outline=outline)

    def line(self, pts, fill, width):
        self.d.line([self.pt(p) for p in pts], fill=fill, width=max(1, round(width * SS)), joint="curve")

    def disc(self, c, r, fill, outline=None):
        self.d.ellipse([(c[0] - r) * SS, (c[1] - r) * SS, (c[0] + r) * SS, (c[1] + r) * SS], fill=fill, outline=outline, width=SS)

    def glow(self, c, r, col, alpha=120, steps=7):
        for i in range(steps):
            k = 1.0 - i / steps
            self.disc(c, r * (0.25 + 0.75 * k), (col[0], col[1], col[2], int(alpha * (1 - k) * 0.5 + alpha * 0.1)))

    def done(self):
        return self.im.resize(self.size, Image.LANCZOS)


def unit(v):
    n = math.hypot(v[0], v[1]) or 1.0
    return (v[0] / n, v[1] / n)


def perp(v):
    return (-v[1], v[0])


def add(p, v, k):
    return (p[0] + v[0] * k, p[1] + v[1] * k)


def luma(rgb):
    return rgb[..., 0] * 0.299 + rgb[..., 1] * 0.587 + rgb[..., 2] * 0.114


def edge_points(alpha, rng, spacing, k, upper=False, band=2):
    """Points on the outline with their outward normals, thinned to `spacing`."""
    a = alpha > 128
    ring = a & ~ndi.binary_erosion(a, iterations=band)
    soft = ndi.gaussian_filter(a.astype(np.float32), 3.0)
    gy, gx = np.gradient(soft)
    ys, xs = np.nonzero(ring)
    order = rng.permutation(len(xs))
    taken = {}
    cell = max(2.0, spacing * k)
    out = []
    for i in order:
        x, y = int(xs[i]), int(ys[i])
        nx, ny = -gx[y, x], -gy[y, x]
        m = math.hypot(nx, ny)
        if m < 1e-5:
            continue
        n = (nx / m, ny / m)
        if upper and n[1] > -0.2:
            continue
        gx_, gy_ = int(x // cell), int(y // cell)
        if any((gx_ + dx, gy_ + dy) in taken for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
            continue
        taken[(gx_, gy_)] = True
        out.append(((float(x), float(y)), n))
    return out


# ---------------------------------------------------------- silhouette bits

def flame(c, p, d, length, width, hot, mid):
    side = perp(d)
    bend = (d[0] + side[0] * 0.35, d[1] + side[1] * 0.35)
    tip = add(add(p, bend, length), side, width * 0.1)
    midp = add(add(p, d, length * 0.5), side, width * 0.55)
    midq = add(add(p, d, length * 0.5), side, -width * 0.45)
    base_l, base_r = add(p, side, -width * 0.5), add(p, side, width * 0.5)
    c.poly([base_l, midq, tip, midp, base_r], mid + (235,))
    tip2 = add(add(p, bend, length * 0.66), side, width * 0.05)
    c.poly([add(p, side, -width * 0.25), add(add(p, d, length * 0.4), side, -width * 0.2), tip2, add(add(p, d, length * 0.4), side, width * 0.25), add(p, side, width * 0.25)], hot + (245,))


def crystal(c, p, d, length, width, body, light, edge):
    side = perp(d)
    base_l, base_r = add(p, side, -width * 0.5), add(p, side, width * 0.5)
    sh_l, sh_r = add(add(p, d, length * 0.72), side, -width * 0.42), add(add(p, d, length * 0.72), side, width * 0.42)
    tip = add(p, d, length)
    c.poly([base_l, sh_l, tip, sh_r, base_r], body + (240,), edge + (255,))
    c.poly([add(p, d, length * 0.05), sh_l, tip, add(p, d, length * 0.5)], light + (150,))
    c.line([sh_l, tip, sh_r], (255, 255, 255, 140), 1.2)


def bolt(c, p, d, length, rng, core, halo):
    side = perp(d)
    pts = [p]
    segs = 4
    for i in range(1, segs + 1):
        off = (rng.random() - 0.5) * length * 0.55 * (1 if i % 2 else -1)
        pts.append(add(add(p, d, length * i / segs), side, off))
    c.line(pts, halo + (110,), 11)
    c.line(pts, halo + (235,), 6)
    c.line(pts, core + (255,), 2.6)


def leaf(c, p, d, length, width, body, vein):
    side = perp(d)
    tip = add(p, d, length)
    a = add(add(p, d, length * 0.45), side, width * 0.55)
    b = add(add(p, d, length * 0.45), side, -width * 0.55)
    c.poly([p, a, tip, b], body + (245,), (20, 60, 24, 255))
    c.line([p, tip], vein + (230,), 1.2)


def wisp(c, p, d, length, width, col):
    side = perp(d)
    pts = []
    n = 14
    for i in range(n + 1):
        t = i / n
        sway = math.sin(t * math.pi * 1.4) * length * 0.18
        pts.append((add(add(p, d, length * t), side, sway), width * (1 - t) ** 0.8))
    for q, w in pts:
        c.disc(q, max(w, 0.6), col + (int(120 + 110 * (w / width)),))


def star4(c, p, r, col, core=(255, 255, 255)):
    c.glow(p, r * 2.6, col, 110)
    pts = []
    for i in range(8):
        ang = i * math.pi / 4
        rad = r if i % 2 == 0 else r * 0.28
        pts.append((p[0] + math.cos(ang) * rad, p[1] + math.sin(ang) * rad))
    c.poly(pts, core + (255,))


def bubble(c, p, r):
    c.disc(p, r, (170, 225, 255, 55), (210, 240, 255, 235))
    c.disc((p[0] - r * 0.35, p[1] - r * 0.35), max(r * 0.22, 0.8), (255, 255, 255, 235))


# ------------------------------------------------------------- surface bits

def cracks(rgb, a, core, glow, strength=1.0, pct=87.0, width=3.0):
    """Grooves in the surface light up from inside."""
    inside = ndi.binary_erosion(a, iterations=3)
    L = luma(rgb)
    hp = ndi.gaussian_filter(L, width) - L
    thr = np.percentile(hp[inside], pct)
    crease = np.clip((hp - thr) / max(thr * 0.6, 1.0), 0, 1) * inside
    crease = ndi.gaussian_filter(crease, 0.8)
    core_c = np.array(core, np.float32)
    glow_c = np.array(glow, np.float32)
    out = rgb * (1 - crease[..., None] * strength) + core_c * crease[..., None] * strength
    bloom = ndi.gaussian_filter(crease, 5.0)[..., None] * a[..., None]
    return np.clip(out + glow_c * bloom * 0.55 * strength, 0, 255)


def noise(shape, rng, sigma):
    n = ndi.gaussian_filter(rng.random(shape).astype(np.float32), sigma)
    n -= n.min()
    return n / max(n.max(), 1e-5)


def frost(rgb, a, rng, k):
    inside = ndi.binary_erosion(a, iterations=1)
    L = luma(rgb)
    rime = (noise(a.shape, rng, 2.2 * k) > 0.62) & (L > np.percentile(L[inside], 38)) & inside
    out = rgb.copy()
    white = np.array([232, 247, 255], np.float32)
    m = ndi.gaussian_filter(rime.astype(np.float32), 0.9)[..., None]
    out = out * (1 - 0.8 * m) + white * 0.8 * m
    dist = ndi.distance_transform_edt(inside)
    rim = np.clip(1 - dist / (6.0 * k), 0, 1)[..., None] * inside[..., None]
    out = out * (1 - 0.4 * rim) + np.array([200, 240, 255], np.float32) * 0.4 * rim
    return np.clip(out, 0, 255)


def moss(rgb, a, rng, k, tint=(78, 150, 50)):
    inside = ndi.binary_erosion(a, iterations=2)
    L = luma(rgb)
    big = noise(a.shape, rng, 11.0 * k)
    fine = noise(a.shape, rng, 1.4 * k)
    patch = (big > 0.62) & (L > np.percentile(L[inside], 28)) & inside
    m = ndi.gaussian_filter(patch.astype(np.float32), 1.2)[..., None]
    col = np.array(tint, np.float32) * (0.7 + 0.6 * fine[..., None])
    return np.clip(rgb * (1 - 0.85 * m) + col * 0.85 * m, 0, 255)


def speckle(rgb, a, rng, k, dark=0.28):
    inside = ndi.binary_erosion(a, iterations=1)
    n = noise(a.shape, rng, 0.9 * k)
    m = ((n > 0.7) & inside).astype(np.float32)[..., None]
    return np.clip(rgb * (1 - dark * m), 0, 255)


def sheen(rgb, a, col, amount=0.22):
    """Brightest spots turn glossy."""
    inside = ndi.binary_erosion(a, iterations=1)
    L = luma(rgb)
    hot = np.clip((L - np.percentile(L[inside], 90)) / 40.0, 0, 1) * inside
    hot = ndi.gaussian_filter(hot, 1.0)[..., None]
    return np.clip(rgb * (1 - amount * hot) + np.array(col, np.float32) * amount * hot * 1.6, 0, 255)


def inside_points(a, rng, count):
    ys, xs = np.nonzero(ndi.binary_erosion(a, iterations=6))
    if len(xs) == 0:
        return []
    idx = rng.integers(0, len(xs), size=count)
    return [(float(xs[i]), float(ys[i])) for i in idx]


# ------------------------------------------------------------------- recipes
# Each recipe has surface(rgb, a, rng, k) and deco(canvas, edge, a, rng, k).

def _flames(hot, mid, n_scale=1.0, size=1.0):
    def deco(c, a, rng, k):
        for p, n in edge_points(a * 255, rng, 28 / n_scale, k, upper=True):
            d = unit((n[0] * 0.5 + rng.normal(0, 0.12), n[1] * 0.5 - 0.85))
            flame(c, p, d, (34 + rng.random() * 30) * k * size, (20 + rng.random() * 12) * k * size, hot, mid)
    return deco


def _crystals(body, light, edge, spacing=24, size=1.0, upper=False):
    def deco(c, a, rng, k):
        for p, n in edge_points(a * 255, rng, spacing, k, upper=upper):
            d = unit((n[0] + rng.normal(0, 0.15), n[1] + rng.normal(0, 0.15) - (0.2 if upper else 0.0)))
            crystal(c, add(p, d, -3 * k), d, (20 + rng.random() * 26) * k * size, (9 + rng.random() * 6) * k * size, body, light, edge)
    return deco


def _bolts(core, halo, spacing=60):
    def deco(c, a, rng, k):
        for p, n in edge_points(a * 255, rng, spacing, k):
            bolt(c, p, unit((n[0] + rng.normal(0, 0.2), n[1] + rng.normal(0, 0.2))), (44 + rng.random() * 28) * k, rng, core, halo)
    return deco


def _leaves(body, vein, spacing=28):
    def deco(c, a, rng, k):
        for p, n in edge_points(a * 255, rng, spacing, k, upper=True):
            d = unit((n[0] + rng.normal(0, 0.3), n[1] - 0.3))
            leaf(c, add(p, d, -2 * k), d, (28 + rng.random() * 16) * k, (13 + rng.random() * 5) * k, body, vein)
    return deco


def _thorns(body, edge, spacing=24):
    def deco(c, a, rng, k):
        for p, n in edge_points(a * 255, rng, spacing, k, upper=True):
            d = unit((n[0] + rng.normal(0, 0.12), n[1] - 0.25))
            crystal(c, add(p, d, -3 * k), d, (20 + rng.random() * 14) * k, (8 + rng.random() * 3) * k, body, tuple(min(255, v + 50) for v in body), edge)
    return deco


def _wisps(col, spacing=46, size=1.0):
    def deco(c, a, rng, k):
        for p, n in edge_points(a * 255, rng, spacing, k):
            d = unit((n[0] * 0.8 + 0.5 + rng.normal(0, 0.2), n[1] * 0.6 - 0.1))
            wisp(c, p, d, (46 + rng.random() * 34) * k * size, (6 + rng.random() * 3.5) * k, col)
    return deco


def _orbs(col, count, size):
    def deco(c, a, rng, k):
        pts = edge_points(a * 255, rng, 70, k)
        for p, n in pts[:count]:
            q = add(p, n, (16 + rng.random() * 26) * k)
            c.glow(q, size * k * 2.2, col, 150)
            c.disc(q, size * k, col + (255,))
            c.disc((q[0] - size * k * 0.3, q[1] - size * k * 0.3), size * k * 0.35, (255, 255, 255, 235))
    return deco


def _stars(col, spacing=52, size=5.0):
    def deco(c, a, rng, k):
        for p, n in edge_points(a * 255, rng, spacing, k):
            q = add(p, n, (6 + rng.random() * 22) * k)
            star4(c, q, size * k * (0.6 + rng.random() * 0.8), col)
    return deco


def _bubbles(spacing=44):
    def deco(c, a, rng, k):
        for p, n in edge_points(a * 255, rng, spacing, k):
            bubble(c, add(p, n, (8 + rng.random() * 22) * k), (3.5 + rng.random() * 5) * k)
    return deco


def _fins(body, light, edge, spacing=30):
    def deco(c, a, rng, k):
        for p, n in edge_points(a * 255, rng, spacing, k, upper=True):
            d = unit((n[0] + 0.35, n[1] - 0.2))
            crystal(c, add(p, d, -3 * k), d, (26 + rng.random() * 18) * k, (14 + rng.random() * 6) * k, body, light, edge)
    return deco


def _droplets(count_per_area=1100.0):
    def surf(rgb, a, rng, k):
        out = rgb.copy()
        area = float(a.sum())
        pts = inside_points(a, rng, max(6, int(area / (count_per_area * k * k))))
        cv = Canvas((a.shape[1], a.shape[0]))
        for p in pts:
            r = (2.2 + rng.random() * 3.0) * k
            cv.disc(p, r, (20, 70, 120, 110))
            cv.disc((p[0] - r * 0.15, p[1] - r * 0.15), r * 0.8, (150, 215, 255, 190))
            cv.disc((p[0] - r * 0.35, p[1] - r * 0.4), r * 0.3, (255, 255, 255, 250))
        return out, cv
    return surf


def _starfield(col, per_area=1400.0):
    def surf(rgb, a, rng, k):
        area = float(a.sum())
        pts = inside_points(a, rng, max(8, int(area / (per_area * k * k))))
        cv = Canvas((a.shape[1], a.shape[0]))
        for p in pts:
            star4(cv, p, (2.5 + rng.random() * 3.5) * k, col)
        return rgb, cv
    return surf


def glitter(rgb, a, rng, k):
    pts = inside_points(a, rng, max(8, int(a.sum() / (1500 * k * k))))
    cv = Canvas((a.shape[1], a.shape[0]))
    for p in pts:
        star4(cv, p, (2.0 + rng.random() * 2.5) * k, (255, 245, 215))
    return rgb, cv


RECIPES = {
    "magmaback": dict(
        surf=[lambda rgb, a, rng, k: (cracks(rgb, a, (255, 190, 70), (255, 90, 20), 1.0, 84.0, 3.0), None)],
        deco=[_flames((255, 230, 120), (255, 110, 30), 0.8, 1.15)]),
    "cinderowl": dict(
        surf=[lambda rgb, a, rng, k: (cracks(rgb, a, (255, 200, 90), (255, 100, 30), 0.7, 90.0, 2.5), None)],
        deco=[_flames((255, 235, 140), (255, 120, 35), 0.9, 0.8)]),
    "rainotter": dict(surf=[_droplets()], deco=[_bubbles(40)]),
    "tidemaw": dict(
        surf=[_droplets(1500.0), lambda rgb, a, rng, k: (sheen(rgb, a, (210, 240, 255), 0.35), None)],
        deco=[_fins((70, 170, 215), (170, 235, 255), (20, 70, 110)), _bubbles(80)]),
    "stormstag": dict(
        surf=[lambda rgb, a, rng, k: (cracks(rgb, a, (255, 252, 190), (255, 220, 60), 1.0, 88.0, 2.5), None)],
        deco=[_bolts((255, 255, 235), (255, 214, 60), 70)]),
    "sparkling": dict(
        surf=[lambda rgb, a, rng, k: (cracks(rgb, a, (255, 252, 200), (255, 225, 70), 0.8, 90.0, 2.0), None)],
        deco=[_stars((255, 214, 40), 40, 8.0), _bolts((255, 255, 235), (255, 214, 60), 90)]),
    "mosshopper": dict(
        surf=[lambda rgb, a, rng, k: (moss(rgb, a, rng, k), None)],
        deco=[_leaves((88, 170, 62), (190, 240, 140), 30)]),
    "thornfox": dict(
        surf=[lambda rgb, a, rng, k: (moss(rgb, a, rng, k, (60, 120, 52)), None)],
        deco=[_thorns((112, 78, 44), (50, 30, 14), 22), _leaves((70, 150, 60), (180, 235, 130), 80)]),
    "frostelk": dict(
        surf=[lambda rgb, a, rng, k: (frost(rgb, a, rng, k), None), glitter],
        deco=[_crystals((140, 205, 245), (235, 250, 255), (50, 120, 185), 32, 1.5)]),
    "icicle": dict(
        surf=[lambda rgb, a, rng, k: (frost(rgb, a, rng, k), None), glitter],
        deco=[_crystals((130, 200, 245), (235, 250, 255), (45, 115, 180), 30, 1.6)]),
    "pebblefin": dict(
        surf=[lambda rgb, a, rng, k: (speckle(rgb, a, rng, k, 0.32), None)],
        deco=[_crystals((140, 122, 98), (205, 190, 165), (55, 45, 34), 34, 1.4, True)]),
    "quartzdrake": dict(
        surf=[glitter, lambda rgb, a, rng, k: (sheen(rgb, a, (255, 250, 230), 0.3), None)],
        deco=[_crystals((255, 214, 150), (255, 250, 230), (160, 105, 50), 38, 1.7, True)]),
    "zephyrcat": dict(surf=[], deco=[_wisps((150, 238, 205), 56, 1.0)]),
    "gustgriffin": dict(
        surf=[],
        deco=[_wisps((150, 238, 205), 44, 1.3)]),
    "arcanitan": dict(
        surf=[_starfield((225, 170, 255), 2200.0)],
        deco=[_crystals((150, 90, 235), (225, 190, 255), (60, 30, 110), 34, 1.1, True), _orbs((190, 130, 255), 5, 5.0)]),
    "starwhale": dict(
        surf=[_starfield((235, 190, 255), 900.0), lambda rgb, a, rng, k: (sheen(rgb, a, (235, 210, 255), 0.3), None)],
        deco=[_stars((225, 175, 255), 40, 6.0), _orbs((200, 150, 255), 4, 4.5)]),
}


def apply(img, creature_id, kind):
    """`kind` is "sheet" (1536x1024, a 4x2 grid) or "raw" (one big picture)."""
    recipe = RECIPES.get(creature_id)
    if recipe is None:
        return img
    rng = np.random.default_rng(zlib.crc32(("%s/%s" % (creature_id, kind)).encode()))
    k = 0.8 if kind == "sheet" else 2.6
    rgba = img.convert("RGBA")
    arr = np.asarray(rgba).astype(np.float32)
    a = arr[..., 3] > 128
    rgb = arr[..., :3]
    overlays = []
    for s in recipe["surf"]:
        rgb, extra = s(rgb, a, rng, k)
        if extra is not None:
            overlays.append(extra)
    body = Image.fromarray(np.dstack([np.clip(rgb, 0, 255), arr[..., 3]]).astype(np.uint8), "RGBA")
    for cv in overlays:
        layer = cv.done()
        # surface marks only land on the creature
        mask = Image.fromarray((a * 255).astype(np.uint8))
        clipped = Image.new("RGBA", body.size, (0, 0, 0, 0))
        clipped.paste(layer, (0, 0), mask)
        body.alpha_composite(clipped)
    behind = Canvas(body.size)
    for d in recipe["deco"]:
        d(behind, a, rng, k)
    out = behind.done()
    out.alpha_composite(body)
    return out
