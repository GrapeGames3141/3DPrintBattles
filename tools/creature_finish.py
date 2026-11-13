"""Filament finishes: the look of a print beyond its colour.

Each finish takes an RGBA picture (a sprite sheet or a raw print) and returns
one that looks printed in that filament: silk (a shiny two-colour gradient),
marble, glow-in-the-dark, carbon fibre, wood, metal, translucent glass,
glitter, stripes, and lava or volt cracks. They work from the picture's own
shading and outline, so they fit every pose.

Used by tools/make_creatures.py.
"""
import colorsys

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage as ndi

import creature_fx


def _rgb_to_hsv(rgb):
    img = Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), "RGB").convert("HSV")
    h = np.asarray(img, dtype=np.float32)
    return h[..., 0] / 255.0 * 360.0, h[..., 1] / 255.0, h[..., 2] / 255.0


def _hsv_to_rgb(h, s, v):
    out = np.stack([(h % 360.0) / 360.0 * 255.0, np.clip(s, 0, 1) * 255.0, np.clip(v, 0, 1) * 255.0], axis=-1)
    return np.asarray(Image.fromarray(out.astype(np.uint8), "HSV").convert("RGB"), dtype=np.float32)


def _cells(shape):
    """Cell rectangles: a 4x2 sheet is eight cells, anything else one."""
    h, w = shape
    if (w, h) == (1536, 1024):
        return [(x * 384, y * 512, 384, 512) for y in range(2) for x in range(4)]
    return [(0, 0, w, h)]


def _noise(shape, rng, sigma):
    n = ndi.gaussian_filter(rng.random(shape).astype(np.float32), sigma)
    n -= n.min()
    return n / max(float(n.max()), 1e-5)


def _scale(shape):
    return 1.0 if shape[1] <= 1600 and shape[0] <= 1100 and shape == (1024, 1536) else 3.0 if shape[0] > 1100 else 1.0


def apply_finish(img, finish, hue, hue2, rng):
    """`img` is already recoloured toward `hue`. Returns the finished RGBA picture."""
    rgba = np.asarray(img.convert("RGBA")).astype(np.float32)
    a = rgba[..., 3] > 128
    rgb = rgba[..., :3].copy()
    alpha = rgba[..., 3].copy()
    k = 1.0 if rgb.shape[:2] == (1024, 1536) else 3.0 if rgb.shape[0] > 1100 else 1.0
    h, s, v = _rgb_to_hsv(rgb)
    L = rgb[..., 0] * 0.299 + rgb[..., 1] * 0.587 + rgb[..., 2] * 0.114
    yy, xx = np.mgrid[0:rgb.shape[0], 0:rgb.shape[1]].astype(np.float32)
    halo = None

    if finish == "silk":
        t = np.zeros(rgb.shape[:2], np.float32)
        for (x0, y0, w, hh) in _cells(rgb.shape[:2]):
            m = a[y0:y0 + hh, x0:x0 + w]
            if m.any():
                ys = np.nonzero(m.any(axis=1))[0]
                top, bot = ys.min(), ys.max()
                t[y0:y0 + hh, x0:x0 + w] = np.clip((np.arange(hh)[:, None] - top) / max(bot - top, 1), 0, 1)
        nh = hue + ((hue2 - hue + 180.0) % 360.0 - 180.0) * t
        v2 = np.clip(v * 1.05 + 0.12 * np.clip((L - 150) / 100.0, 0, 1), 0, 1)
        out = _hsv_to_rgb(nh, np.clip(s * 1.1, 0, 1), v2)
        spec = np.clip((L - np.percentile(L[a], 88)) / 30.0, 0, 1)[..., None]
        rgb = np.clip(out * (1 - 0.3 * spec) + 255 * 0.3 * spec, 0, 255)
    elif finish == "marble":
        n = _noise(rgb.shape[:2], rng, 14 * k)
        veins = 1 - np.abs(2 * _noise(rgb.shape[:2], rng, 5 * k) - 1)
        veins = np.clip((veins - 0.92) / 0.08, 0, 1)
        mix = np.clip((n - 0.45) * 6, 0, 1)
        nh = hue * (1 - mix) + (hue2 if hue2 else hue + 40) * mix
        out = _hsv_to_rgb(nh, np.clip(s * (0.65 + 0.25 * mix), 0, 1), np.clip(v * 1.05, 0, 1))
        rgb = np.clip(out * (1 - 0.7 * veins[..., None]) + 245 * 0.7 * veins[..., None], 0, 255)
    elif finish == "glow":
        out = _hsv_to_rgb(np.full_like(h, hue), np.clip(s * 0.45, 0, 1), np.clip(v * 0.7 + 0.35, 0, 1))
        rgb = np.clip(out, 0, 255)
        shape_mask = ndi.binary_dilation(a, iterations=int(9 * k))
        halo = Image.fromarray((ndi.gaussian_filter(shape_mask.astype(np.float32), 7 * k) * 150).astype(np.uint8))
        col = tuple(int(x * 255) for x in colorsys.hsv_to_rgb((hue % 360) / 360.0, 0.55, 1.0))
    elif finish == "carbon":
        dark = _hsv_to_rgb(np.full_like(h, hue), np.clip(s * 0.35, 0, 1), np.clip(v * 0.42, 0, 1))
        period = 5 * k
        weave = (np.floor((xx + yy) / period) + np.floor((xx - yy) / period)) % 2
        dark = dark * (0.88 + 0.24 * weave[..., None])
        accent = np.clip((s - 0.45) * 3, 0, 1) * np.clip((v - 0.5) * 3, 0, 1)
        accent = ndi.gaussian_filter(accent, 0.8)[..., None]
        rgb = np.clip(dark * (1 - 0.85 * accent) + rgb * 1.1 * 0.85 * accent, 0, 255)
    elif finish == "wood":
        base_h = 24.0 + (hue % 40) * 0.3
        grain = np.sin((yy + 10 * _noise(rgb.shape[:2], rng, 8 * k) * 20 * k) * 0.35 / k) * 0.5 + 0.5
        vv = np.clip(0.28 + 0.62 * (L / 255.0) ** 0.9, 0, 1) * (0.82 + 0.3 * grain)
        out = _hsv_to_rgb(np.full_like(h, base_h), np.full_like(h, 0.62), vv)
        leaf = np.clip((s - 0.45) * 2.5, 0, 1) * (np.abs(((hue - h) + 180) % 360 - 180) < 40)
        leaf = ndi.gaussian_filter(leaf.astype(np.float32), 0.8)[..., None]
        rgb = np.clip(out * (1 - 0.6 * leaf) + rgb * 0.6 * leaf, 0, 255)
    elif finish == "metal":
        t = np.clip(L / 255.0, 0, 1) ** 1.3
        sat = 0.08 if hue >= 200 and hue <= 230 else 0.62
        dark = _hsv_to_rgb(np.full_like(h, hue), np.full_like(h, sat), np.full_like(h, 0.18))
        mid = _hsv_to_rgb(np.full_like(h, hue), np.full_like(h, sat), np.full_like(h, 0.72))
        light = _hsv_to_rgb(np.full_like(h, hue), np.full_like(h, sat * 0.35), np.full_like(h, 1.0))
        t3 = t[..., None]
        out = np.where(t3 < 0.5, dark + (mid - dark) * (t3 * 2), mid + (light - mid) * ((t3 - 0.5) * 2))
        band = (np.sin((xx * 0.045 + yy * 0.02) / k) * 0.5 + 0.5)[..., None]
        rgb = np.clip(out * (0.85 + 0.3 * band), 0, 255)
    elif finish == "glass":
        out = _hsv_to_rgb(np.full_like(h, hue), np.clip(s * 0.75 + 0.1, 0, 1), np.clip(v * 0.9 + 0.12, 0, 1))
        dist = ndi.distance_transform_edt(a)
        rim = np.clip(1 - dist / (9.0 * k), 0, 1)
        rgb = np.clip(out + rim[..., None] * 70, 0, 255)
        alpha = alpha * (0.66 + 0.34 * rim)
    elif finish == "glitter":
        rgb = np.clip(rgb, 0, 255)
    elif finish == "stripes":
        n = _noise(rgb.shape[:2], rng, 10 * k)
        period = 17.0 * k
        band = np.sin(((xx * 0.8 + yy * 0.6) / period + n * 3.0) * np.pi) > 0.35
        shade = np.where(band, 0.5, 1.0)[..., None]
        dark = _hsv_to_rgb(np.full_like(h, (hue + 12) % 360), np.clip(s * 1.1, 0, 1), np.clip(v * 0.5, 0, 1))
        rgb = np.clip(np.where(band[..., None], dark, rgb), 0, 255)
    elif finish in ("lava", "volt"):
        core, glow_c = ((255, 190, 70), (255, 90, 20)) if finish == "lava" else ((255, 252, 190), (255, 220, 60))
        rgb = creature_fx.cracks(rgb * 0.82, a, core, glow_c, 1.0, 84.0, 3.0 * min(k, 2.0))

    out = Image.fromarray(np.dstack([np.clip(rgb, 0, 255), np.clip(alpha, 0, 255)]).astype(np.uint8), "RGBA")
    if finish == "glitter":
        pts = creature_fx.inside_points(a, rng, max(30, int(a.sum() / (700 * k * k))))
        cv = creature_fx.Canvas(out.size)
        for p in pts:
            creature_fx.star4(cv, p, (2.5 + rng.random() * 3.5) * k, (255, 245, 215))
        clip = Image.new("RGBA", out.size, (0, 0, 0, 0))
        clip.paste(cv.done(), (0, 0), Image.fromarray((a * 255).astype(np.uint8)))
        out.alpha_composite(clip)
    if halo is not None:
        h_img = Image.new("RGBA", out.size, col + (0,))
        h_img.putalpha(halo)
        h_img.alpha_composite(out)
        out = h_img
    return out
