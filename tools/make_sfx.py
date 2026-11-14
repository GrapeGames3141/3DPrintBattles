"""Synthesises every sound effect and jingle.

    uv run --with numpy --with soundfile python tools/make_sfx.py [name ...]

Writes mono 44.1 kHz WAVs into assets/audio as sfx_<name>.wav. All of it is
built from oscillators and filtered noise (tools/audiolib.py), so there are no
samples to license and everything can be regenerated.
"""

import sys

import numpy as np

from audiolib import (
    OUT, SR, adsr, attack, band, brass, chirp, ep, exp_env, fft_filter, hz, marimba, noise, pluck, saw, secs, sine,
    soft_clip, tt, tick, write_wav,
)
from audiolib import anvil as _anvil, bell as _bell, crash as _crash, heartbeat as _heartbeat, strings as _strings, taiko as _taiko

rng = np.random.default_rng(3141)
SFX = {}


class Sig(np.ndarray):
    """A mono signal where `+` pads the shorter side with silence, so sounds of
    different lengths can simply be added together."""

    def __new__(cls, data):
        return np.asarray(data, dtype=float).view(cls)

    def __add__(self, other):
        other = np.asarray(other)
        if other.ndim == 0 or other.shape == self.shape:
            return np.ndarray.__add__(self, other)
        n = max(len(self), len(other))
        a = np.zeros(n)
        b = np.zeros(n)
        a[: len(self)] = self
        b[: len(other)] = other
        return Sig(a + b)

    __radd__ = __add__


def sigout(fn):
    def wrapped(*args, **kwargs):
        return Sig(fn(*args, **kwargs))

    wrapped.__name__ = fn.__name__
    return wrapped


tick = sigout(tick)
brass = sigout(brass)
ep = sigout(ep)
clank = sigout(lambda f, vel=1.0: _anvil(rng, f) * vel)
drum = sigout(lambda f, vel=1.0: _taiko(rng, f) * vel)
cymbal = sigout(lambda vel=1.0: _crash(rng) * vel)
bell = sigout(_bell)
strings = sigout(_strings)
chirp = sigout(chirp)


def sfx(fn):
    SFX[fn.__name__.rstrip("_")] = fn
    return fn


@sigout
def place(parts, length):
    """Mixes (start_seconds, signal) pairs into one buffer."""
    out = np.zeros(secs(length))
    for start, sig in parts:
        i = secs(start)
        m = sig[: max(0, len(out) - i)]
        out[i : i + len(m)] += m
    return out


@sigout
def ping(f, dur, decay=9.0, partials=((1.0, 1.0),)):
    n = secs(dur)
    t = tt(n)
    y = sum(a * np.sin(2 * np.pi * f * r * t) for r, a in partials)
    return y * np.exp(-t * decay) * attack(n, 0.002)


@sigout
def whoosh(dur, lo, hi, peak=0.5, rise=True):
    n = secs(dur)
    t = np.linspace(0, 1, n)
    sig = noise(n, rng)
    # sweeping the band by mixing a low and a high version
    a = band(sig, lo, lo * 2.5, 1)
    b = band(sig, hi * 0.5, hi, 1)
    mix = (1 - t) * a + t * b if rise else t * a + (1 - t) * b
    env = np.sin(np.pi * np.clip((t - 0.0) / 1.0, 0, 1)) ** (1.5)
    env = np.where(t < peak, t / peak, (1 - t) / (1 - peak)) ** 1.3
    return mix * env


@sigout
def thump(f=70.0, dur=0.25, decay=14.0):
    n = secs(dur)
    t = tt(n)
    return np.sin(2 * np.pi * np.cumsum(f * (1 + 1.8 * np.exp(-t * 40.0))) / SR) * np.exp(-t * decay)


@sigout
def crunch(dur, lo, hi, density, decay):
    """A burst of crackling: random short noise grains."""
    n = secs(dur)
    out = np.zeros(n)
    for h in np.nonzero(rng.random(n) < density / SR)[0]:
        ln = int(rng.integers(30, 220))
        end = min(n, h + ln)
        out[h:end] += rng.standard_normal(end - h) * np.exp(-np.arange(end - h) / (ln * 0.25)) * rng.uniform(0.3, 1.0)
    return band(out, lo, hi, 1) * np.exp(-tt(n) * decay)


# ---------------------------------------------------------------------- UI

@sfx
def click():
    return tick(rng, 2100.0) * 0.9 + ping(1400.0, 0.06, 60.0) * 0.3


@sfx
def back():
    return tick(rng, 1300.0) * 0.8 + ping(700.0, 0.08, 45.0) * 0.3


@sfx
def open():
    return whoosh(0.22, 400.0, 3500.0, 0.7, True) * 0.5 + ping(880.0, 0.2, 14.0) * 0.18


@sfx
def close():
    return whoosh(0.2, 400.0, 3000.0, 0.3, False) * 0.45


@sfx
def deny():
    n = secs(0.26)
    t = tt(n)
    y = np.sign(np.sin(2 * np.pi * 150.0 * t)) * 0.5 + np.sign(np.sin(2 * np.pi * 158.0 * t)) * 0.5
    y = fft_filter(y, hi=900.0)
    gate = (np.sin(2 * np.pi * 14.0 * t) > -0.2).astype(float)
    return y * gate * np.exp(-t * 7.0) * attack(n, 0.004)


@sfx
def coin():
    return place([(0.0, ping(1568.0, 0.35, 9.0, ((1, 1), (2.0, 0.3), (3.01, 0.1)))), (0.07, ping(2093.0, 0.5, 7.0, ((1, 1), (2.0, 0.25), (3.01, 0.08))))], 0.6)


@sfx
def buy():
    return place([(0.0, thump(120.0, 0.12, 30.0) * 0.5), (0.03, ping(1319.0, 0.3, 10.0, ((1, 1), (2.0, 0.3)))), (0.1, ping(1760.0, 0.4, 8.0, ((1, 1), (2.0, 0.3))))], 0.55)


# ------------------------------------------------------------------- cards

@sfx
def draw():
    return whoosh(0.17, 1500.0, 7000.0, 0.45, True) * 0.45 + tick(rng, 1800.0) * 0.25


@sfx
def pick():
    return tick(rng, 1600.0) * 0.6 + ping(1050.0, 0.1, 36.0) * 0.22


@sfx
def drop():
    return thump(95.0, 0.14, 26.0) * 0.8 + tick(rng, 900.0) * 0.5 + clank(900.0, 0.25)


# ---------------------------------------------------------------- printing

@sfx
def print_():
    """About a second of a printer at work: stepper whine and layer ticks."""
    n = secs(1.25)
    t = tt(n)
    freq = 180.0 + 260.0 * np.minimum(t / 0.5, 1.0)
    motor = np.sign(np.sin(2 * np.pi * np.cumsum(freq) / SR)) * 0.5 + np.sin(2 * np.pi * np.cumsum(freq * 2.0) / SR) * 0.3
    motor = fft_filter(motor, lo=140.0, hi=2400.0) * 0.4
    sway = np.sin(2 * np.pi * 7.0 * t)
    gear = fft_filter(noise(n, rng), lo=700.0, hi=2600.0, order=1) * (0.5 + 0.5 * (sway > 0)) * 0.22
    layers = np.zeros(n)
    for k in range(int(1.25 * 16)):
        i = secs(k / 16.0)
        layers[i : i + secs(0.03)] += tick(rng, 1200.0 + 60.0 * (k % 5))[: secs(0.03)] * 0.35
    heat = fft_filter(noise(n, rng), lo=4500.0, order=1) * 0.05
    env = adsr(n, 0.05, 0.3, 0.85, 0.25)
    return (motor + gear + heat) * env + layers * np.minimum(t / 0.1, 1.0)


@sfx
def job_start():
    """Loading filament: a clunk, a spool winding up, a latch."""
    n = secs(0.6)
    t = tt(n)
    whirr = fft_filter(np.sign(np.sin(2 * np.pi * np.cumsum(120.0 + 400.0 * t) / SR)), hi=1800.0) * np.exp(-t * 4.0) * 0.4
    return place([(0.0, thump(80.0, 0.2, 18.0)), (0.05, whirr), (0.42, tick(rng, 1000.0) * 1.0 + thump(140.0, 0.1, 30.0) * 0.5)], 0.65)


@sfx
def print_done():
    return place([(0.0, ping(1047.0, 0.5, 6.0, ((1, 1), (2, 0.35), (3.01, 0.12)))), (0.1, ping(1319.0, 0.5, 6.0, ((1, 1), (2, 0.3)))),
                  (0.2, ping(1568.0, 0.7, 5.0, ((1, 1), (2, 0.3), (4.02, 0.08)))), (0.0, crunch(0.25, 4000.0, 12000.0, 900.0, 12.0) * 0.18)], 0.95)


@sfx
def deploy():
    return place([(0.0, whoosh(0.28, 500.0, 4000.0, 0.4, True) * 0.5), (0.2, thump(75.0, 0.3, 11.0) * 0.9), (0.2, crunch(0.2, 300.0, 3000.0, 600.0, 18.0) * 0.4)], 0.55)


@sfx
def hop():
    return thump(110.0, 0.12, 28.0) * 0.8 + tick(rng, 1100.0) * 0.4


# ------------------------------------------------------------------ combat

@sfx
def swing():
    return whoosh(0.22, 700.0, 5000.0, 0.45, True) * 0.5


@sfx
def hit():
    return place([(0.0, thump(110.0, 0.2, 22.0) * 0.9), (0.0, crunch(0.14, 500.0, 5000.0, 900.0, 24.0) * 0.5),
                  (0.0, clank(640.0, 0.5)), (0.0, drum(95.0, 0.35))], 0.5)


@sfx
def hit_heavy():
    return place([(0.0, drum(58.0, 0.9)), (0.0, thump(55.0, 0.5, 8.0) * 0.7), (0.0, crunch(0.3, 200.0, 5000.0, 1400.0, 11.0) * 0.6),
                  (0.0, clank(430.0, 0.8)), (0.02, clank(960.0, 0.4)), (0.03, cymbal(0.35))], 1.0)


@sfx
def hit_printer():
    partial = ((1.0, 1.0), (2.76, 0.7), (5.4, 0.5), (8.93, 0.3))
    return place([(0.0, drum(52.0, 0.8)), (0.0, ping(410.0, 0.7, 6.0, partial) * 0.55), (0.0, crunch(0.2, 1000.0, 9000.0, 900.0, 22.0) * 0.45),
                  (0.0, clank(330.0, 0.7)), (0.04, cymbal(0.3))], 1.1)


@sfx
def shatter():
    return place([(0.0, crunch(0.6, 1500.0, 12000.0, 2800.0, 6.0) * 1.0), (0.0, drum(80.0, 0.7)), (0.0, clank(760.0, 0.5)),
                  (0.05, clank(1180.0, 0.35)), (0.09, ping(2400.0, 0.25, 16.0, ((1, 1), (1.6, 0.6))) * 0.25)], 0.9)


@sfx
def heal():
    return place([(i * 0.07, ping(hz(72 + s), 0.5, 7.0, ((1, 1), (2.0, 0.2)))) for i, s in enumerate([0, 4, 7, 12])], 0.75) * 0.7


@sfx
def buff():
    return place([(i * 0.045, ping(hz(79 + s), 0.3, 12.0, ((1, 1), (2.0, 0.3)))) for i, s in enumerate([0, 3, 7, 10, 14])], 0.5) * 0.6


@sfx
def jam():
    return place([(0.0, crunch(0.5, 3000.0, 14000.0, 1800.0, 6.0) * 0.7), (0.0, ping(1900.0, 0.45, 9.0, ((1, 1), (2.31, 0.5), (3.7, 0.3))) * 0.4)], 0.55)


@sfx
def armor():
    return place([(0.0, ping(520.0, 0.5, 8.0, ((1, 1), (2.4, 0.5), (4.1, 0.3)))), (0.0, thump(100.0, 0.15, 25.0) * 0.5)], 0.55)


@sfx
def power():
    n = secs(0.55)
    t = tt(n)
    sweep = chirp(160.0, 1200.0, n, 1.8) * np.minimum(t / 0.3, 1.0) * np.exp(-np.maximum(t - 0.3, 0) * 9.0)
    return sweep * 0.5 + place([(0.3, ping(1760.0, 0.25, 14.0) * 0.4)], 0.55) + fft_filter(noise(n, rng), lo=3000.0) * 0.08 * np.exp(-t * 5.0)


@sfx
def tool():
    """A ratchet clicking over."""
    return place([(k * 0.045, tick(rng, 1500.0 + 140.0 * k)) for k in range(5)] + [(0.24, thump(130.0, 0.12, 30.0) * 0.5)], 0.4)


@sfx
def attach():
    return place([(0.0, ping(380.0, 0.35, 12.0, ((1, 1), (2.7, 0.5), (5.2, 0.3)))), (0.09, tick(rng, 1700.0) * 1.2), (0.09, thump(150.0, 0.1, 40.0) * 0.5)], 0.45)


@sfx
def burn():
    return crunch(0.5, 600.0, 7000.0, 1500.0, 7.0) * 0.8 + whoosh(0.4, 300.0, 2000.0, 0.3, False) * 0.3


@sfx
def fatigue():
    return place([(0.0, ping(110.0, 0.9, 3.5, ((1, 1), (2.0, 0.4), (3.0, 0.2)))), (0.0, thump(55.0, 0.5, 6.0) * 0.6)], 0.9)


@sfx
def scrap():
    return place([(0.0, ping(2300.0, 0.18, 24.0, ((1, 1), (1.5, 0.4)))), (0.05, ping(1700.0, 0.2, 22.0, ((1, 1), (1.5, 0.3))))], 0.3) * 0.7


@sfx
def spool_add():
    return place([(k * 0.05, ping(hz(84 + 2 * k), 0.25, 14.0)) for k in range(4)], 0.45) * 0.6


# ---------------------------------------------------------------- elements

@sfx
def atk_fire():
    return whoosh(0.4, 500.0, 3500.0, 0.35, True) * 0.5 + crunch(0.35, 700.0, 6000.0, 1600.0, 6.0) * 0.6


@sfx
def atk_water():
    n = secs(0.4)
    t = tt(n)
    bub = sum(np.sin(2 * np.pi * np.cumsum(np.full(n, f0) * (1 + 1.5 * np.minimum((t - s) / 0.08, 1.0).clip(0))) / SR) * np.exp(-np.maximum(t - s, 0) * 30.0) * (t > s)
              for f0, s in [(500.0, 0.0), (650.0, 0.06), (420.0, 0.12), (780.0, 0.18)]) * 0.25
    return bub + whoosh(0.4, 600.0, 3000.0, 0.3, True) * 0.3


@sfx
def atk_lightning():
    n = secs(0.35)
    t = tt(n)
    zap = np.sign(np.sin(2 * np.pi * np.cumsum(2400.0 * np.exp(-t * 6.0) + 300.0) / SR)) * np.exp(-t * 9.0) * 0.35
    buzz = fft_filter(np.sign(np.sin(2 * np.pi * 120.0 * t)), lo=300.0, hi=4000.0) * np.exp(-t * 7.0) * 0.4
    return zap + buzz + crunch(0.3, 2000.0, 12000.0, 2500.0, 10.0) * 0.5


@sfx
def atk_nature():
    return place([(0.0, whoosh(0.35, 800.0, 5000.0, 0.5, True) * 0.4), (0.15, ping(hz(76), 0.3, 12.0) * 0.3), (0.22, ping(hz(79), 0.3, 12.0) * 0.25)], 0.5)


@sfx
def atk_ice():
    return place([(0.0, crunch(0.4, 4000.0, 14000.0, 2000.0, 7.0) * 0.6), (0.0, ping(2800.0, 0.4, 9.0, ((1, 1), (2.31, 0.5), (3.7, 0.3))) * 0.3),
                  (0.12, ping(3500.0, 0.3, 11.0, ((1, 1), (2.31, 0.4))) * 0.25)], 0.5)


@sfx
def atk_stone():
    return place([(0.0, thump(55.0, 0.4, 8.0)), (0.0, crunch(0.35, 150.0, 2500.0, 1800.0, 9.0) * 0.7)], 0.45)


@sfx
def atk_wind():
    return whoosh(0.5, 400.0, 6000.0, 0.5, True) * 0.7


@sfx
def atk_arcane():
    n = secs(0.6)
    t = tt(n)
    shimmer = sum(np.sin(2 * np.pi * np.cumsum(np.full(n, f0) * (1 + 0.8 * t)) / SR + k) for k, f0 in enumerate([523.0, 659.0, 784.0, 1047.0])) * 0.12
    return shimmer * np.sin(np.pi * np.clip(t / 0.6, 0, 1)) ** 0.7 + ping(2093.0, 0.4, 9.0) * 0.2


# ------------------------------------------------------------- turns, state

@sfx
def turn_mine():
    # A horn call: root and fifth, with a bell on top.
    return place([(0.0, brass(hz(62), 0.35, 0.9)), (0.0, brass(hz(69), 0.35, 0.8)), (0.18, brass(hz(69), 0.7, 0.9)), (0.18, brass(hz(74), 0.7, 0.8)),
                  (0.18, bell(hz(86), 0.6, 0.8) * 0.5), (0.0, drum(75.0, 0.5))], 1.2) * 0.8


@sfx
def turn_foe():
    # A low answer: a taiko hit and a falling minor horn.
    return place([(0.0, drum(66.0, 0.8)), (0.0, brass(hz(55), 0.4, 0.8)), (0.2, brass(hz(52), 0.7, 0.8)), (0.2, clank(300.0, 0.4))], 1.1) * 0.8


@sfx
def heartbeat():
    """The Printer is nearly gone: a slow double thump."""
    return Sig(_heartbeat(rng)) * 0.9


@sfx
def spool_low():
    return place([(0.0, ping(988.0, 0.14, 24.0)), (0.17, ping(988.0, 0.14, 24.0))], 0.35) * 0.8


@sfx
def reveal():
    n = secs(0.9)
    return place([(0.0, chirp(500.0, 2400.0, secs(0.35), 1.5) * np.exp(-tt(secs(0.35)) * 4.0) * 0.3)] +
                 [(0.25 + k * 0.06, ping(hz(84 + s), 0.6, 6.0, ((1, 1), (2, 0.3)))) for k, s in enumerate([0, 4, 7, 12, 16])], 1.1)


@sfx
def reveal_epic():
    return place([(0.0, SFX["reveal"]()), (0.05, thump(60.0, 0.5, 6.0) * 0.5)], 1.2)


@sfx
def win():
    parts = []
    for k, (m, d) in enumerate([(62, 0.0), (66, 0.2), (69, 0.4), (74, 0.6)]):
        parts.append((d, brass(hz(m), 0.3 if k < 3 else 1.6, 0.95)))
        parts.append((d, strings(hz(m + 12), 0.3 if k < 3 else 1.8, 0.8, 0.02) * 0.6))
    for m in (62, 66, 69, 74):
        parts.append((0.8, brass(hz(m), 1.5, 0.8) * 0.6))
    parts += [(0.0, drum(70.0, 0.7)), (0.4, drum(70.0, 0.6)), (0.8, drum(60.0, 0.9)), (0.8, cymbal(0.7)),
              (0.8, bell(hz(98), 1.5, 0.8) * 0.5), (0.95, bell(hz(102), 1.5, 0.7) * 0.4)]
    return place(parts, 3.0)


@sfx
def lose():
    parts = []
    for k, (m, d) in enumerate([(62, 0.0), (60, 0.45), (57, 0.9)]):
        parts.append((d, strings(hz(m), 0.5 if k < 2 else 1.8, 0.9, 0.12)))
        parts.append((d, strings(hz(m + 7), 0.5 if k < 2 else 1.8, 0.8, 0.12) * 0.8))
        parts.append((d, drum(48.0 - 4 * k, 0.8)))
    parts.append((1.3, strings(hz(50), 2.0, 0.8, 0.3) * 0.8))
    parts.append((0.0, clank(260.0, 0.5)))
    return place(parts, 3.6)


# -------------------------------------------------------------------- packs

@sfx
def rip():
    n = secs(0.42)
    t = np.linspace(0, 1, n)
    hiss = fft_filter(noise(n, rng), lo=1800.0, hi=5000.0 + 7000.0 * t.mean(), order=1)
    ticks = fft_filter(crunch(0.42, 2500.0, 14000.0, 1700.0, 0.0), lo=2500.0)
    return (hiss * 0.5 + ticks * 0.8) * np.minimum(t / 0.1, 1) * (1 - t) ** 0.6


@sfx
def foil():
    return crunch(0.13, 2800.0, 14000.0, 1100.0, 0.0) * np.sin(np.pi * np.linspace(0, 1, secs(0.13)))


@sfx
def swipe():
    return whoosh(0.2, 600.0, 5200.0, 0.5, True) * 0.6 + tick(rng, 1300.0) * 0.2


# ------------------------------------------------------------------- mods

@sfx
def mod_install():
    """A screwdriver ratcheting a part in, then a click."""
    return place([(k * 0.055, tick(rng, 1000.0 + 90.0 * (k % 3)) * 0.8) for k in range(6)] + [(0.36, ping(1500.0, 0.3, 12.0) * 0.4), (0.36, thump(130.0, 0.12, 30.0) * 0.5)], 0.7)


@sfx
def upgrade():
    """A press stamping a blueprint, then a bright rising ding."""
    return place([(0.0, thump(65.0, 0.3, 10.0) * 0.9), (0.0, crunch(0.15, 400.0, 6000.0, 1000.0, 22.0) * 0.4),
                  (0.18, ping(hz(79), 0.8, 5.0, ((1, 1), (2, 0.3)))), (0.28, ping(hz(84), 0.9, 4.5, ((1, 1), (2, 0.3)))),
                  (0.38, ping(hz(88), 1.2, 4.0, ((1, 1), (2, 0.3), (3.01, 0.1))))], 1.5)


if __name__ == "__main__":
    names = sys.argv[1:] or list(SFX)
    for name in names:
        sig = SFX[name]()
        write_wav(name, sig)
    print(f"{len(names)} effects written to {OUT}")
