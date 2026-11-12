"""Synthesises the pack-opening sound effects.

    uv run --with numpy python tools/make_sfx.py

Writes 44.1 kHz mono 16-bit WAVs into assets/audio:
    sfx_rip.wav    the foil strip tearing right off
    sfx_foil.wav   a short crackle while the tear is being pulled
    sfx_swipe.wav  a card sliding off the stack
"""

import wave
from pathlib import Path

import numpy as np

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio"


def one_pole(x, cutoff, high=False):
    """First-order low-pass (or high-pass); `cutoff` in Hz, scalar or per-sample."""
    a = 1.0 - np.exp(-2.0 * np.pi * np.broadcast_to(cutoff, x.shape) / RATE)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += a[i] * (x[i] - acc)
        y[i] = acc
    return x - y if high else y


def crackle(rng, n, rate_hz):
    """Random sharp ticks, each a few milliseconds of decaying noise."""
    out = np.zeros(n)
    rate = np.broadcast_to(rate_hz, (n,))
    hits = np.nonzero(rng.random(n) < rate / RATE)[0]
    for h in hits:
        length = int(rng.integers(40, 260))
        end = min(n, h + length)
        burst = rng.standard_normal(end - h) * np.exp(-np.arange(end - h) / (length * 0.22))
        out[h:end] += burst * rng.uniform(0.4, 1.0)
    return out


def save(name, samples):
    samples = samples / max(1e-9, np.max(np.abs(samples))) * 0.85
    fade = min(200, len(samples) // 4)
    samples[-fade:] *= np.linspace(1.0, 0.0, fade)
    data = (samples * 32767.0).astype("<i2")
    with wave.open(str(OUT / f"sfx_{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())
    print(f"sfx_{name}.wav  {len(samples) / RATE:.2f}s")


def rip(rng):
    n = int(RATE * 0.42)
    t = np.arange(n) / n
    # Hiss that brightens as the tear speeds up, with dense crackle on top.
    hiss = one_pole(rng.standard_normal(n), 1800.0, high=True)
    hiss = one_pole(hiss, 5000.0 + 7000.0 * t)
    ticks = one_pole(crackle(rng, n, 500.0 + 1600.0 * t), 2500.0, high=True)
    env = np.minimum(t / 0.04, 1.0) * (1.0 - t) ** 0.6
    snap = np.exp(-np.arange(n) / (RATE * 0.012)) * rng.standard_normal(n)
    return (hiss * 0.55 + ticks * 0.9) * env + np.roll(snap, int(n * 0.86)) * 0.5 * (t > 0.86)


def foil(rng):
    n = int(RATE * 0.13)
    t = np.arange(n) / n
    ticks = one_pole(crackle(rng, n, 900.0), 3000.0, high=True)
    hiss = one_pole(rng.standard_normal(n), 4000.0, high=True) * 0.25
    return (ticks + hiss) * np.sin(np.pi * t) ** 0.7


def swipe(rng):
    n = int(RATE * 0.2)
    t = np.arange(n) / n
    air = one_pole(rng.standard_normal(n), 900.0 + 5200.0 * np.sin(np.pi * t) ** 2)
    air = one_pole(air, 300.0, high=True)
    tick = np.exp(-np.arange(n) / (RATE * 0.004)) * rng.standard_normal(n) * 0.35
    return air * np.sin(np.pi * t) ** 1.5 + np.roll(tick, int(n * 0.8)) * (t > 0.8)


if __name__ == "__main__":
    generator = np.random.default_rng(3141)
    save("rip", rip(generator))
    save("foil", foil(generator))
    save("swipe", swipe(generator))
