"""Composes PrintForge Legends' music.

    uv run --with numpy --with soundfile python tools/make_music.py [track ...]

Writes stereo OGG loops into assets/audio:

    music_menu.ogg      warm lo-fi electric piano; menu and campaign map
    music_shop.ogg      bright marimba groove; card packs
    music_bench.ogg     ticking, mechanical; workshop, collection, blueprints
    music_battle1_*.ogg three layers of one battle theme that play in sync:
        base   always on (pad, pulse)
        drive  joins when the bench fills up (drums, arpeggio)
        danger joins when a Printer is in trouble (lead riff, toms)
    music_battle2_*.ogg the same idea, faster and darker, for the late rivals

Every layer of a theme is exactly the same length and is mastered with one
shared gain, so any mix of them is balanced and loops without a gap.
"""

import sys

import numpy as np

from audiolib import (
    Song, bass, brass, clap, ep, hat, kick, lead, marimba, master, noise, pad, pluck, report, shaker, snare,
    sub, tick, tom, hz, write_ogg, secs, tt, band, fft_filter, SR, soft_clip,
)

MAJ7 = [0, 4, 7, 11]
MIN9 = [0, 3, 7, 10, 14]
MAJ9 = [0, 4, 7, 11, 14]
DOM7 = [0, 4, 7, 10]
MIN = [0, 3, 7]
MAJ = [0, 4, 7]
SUS = [0, 5, 7, 10]


def voice(root, shape, lift=0):
    return [root + s + lift for s in shape]


def swing(beat, amount=0.12):
    """Delays off-beat eighths a little."""
    return beat + (amount if (beat * 2.0) % 2.0 == 1.0 else 0.0)


# ------------------------------------------------------------------- menu

def menu():
    rng = np.random.default_rng(11)
    s = Song(bpm=80, bars=16)
    prog = [(57, MIN9), (53, MAJ7), (48, MAJ9), (55, [0, 4, 7, 9, 14])]   # Am9 Fmaj7 Cmaj9 G6/9
    penta = [69, 72, 74, 76, 79, 81]                                      # A minor pentatonic
    kk, sn, hh = kick(rng, 0.5), snare(rng, 0.7), hat(rng)
    for bar in range(16):
        root, shape = prog[bar % 4]
        notes = voice(root, shape)
        for j, m in enumerate(notes):            # a loose, rolled chord
            s.put("keys", s.at(bar, 0.0 + j * 0.03), ep(hz(m), 3.2, 0.55 + 0.03 * j), p=-0.25, gain=0.8)
        if bar % 2 == 1:
            for j, m in enumerate(notes[1:]):
                s.put("keys", s.at(bar, 2.5 + j * 0.03), ep(hz(m), 1.2, 0.4), p=-0.25, gain=0.6)
        s.put("bass", s.at(bar, 0.0), bass(hz(root - 24), 1.4, 0.9), gain=0.8)
        s.put("bass", s.at(bar, 2.5), bass(hz(root - 24), 0.9, 0.7), gain=0.7)
        if bar % 4 == 3:
            s.put("bass", s.at(bar, 3.5), bass(hz(root - 12 + 2), 0.4, 0.6), gain=0.6)
        s.put("drums", s.at(bar, 0.0), kk, gain=0.7)
        s.put("drums", s.at(bar, 1.5), kk, gain=0.45)
        s.put("drums", s.at(bar, 2.5), kk, gain=0.55)
        s.put("drums", s.at(bar, 1.0), sn, gain=0.55)
        s.put("drums", s.at(bar, 3.0), sn, gain=0.55)
        for e in range(8):
            s.put("drums", swing(s.at(bar, e * 0.5)), hh, p=0.3, gain=0.28 if e % 2 == 0 else 0.18)
        # a sparse melody in the second half of each four bars
        if bar % 4 in (2, 3) and bar >= 4:
            pos = 0.0
            while pos < 4.0:
                if rng.random() < 0.55:
                    note = int(rng.choice(penta))
                    s.put("lead", s.at(bar, pos), ep(hz(note), 0.7, 0.55), p=0.3, gain=0.55)
                pos += float(rng.choice([0.5, 1.0, 1.5]))
    # vinyl dust
    dust = np.zeros(s.loop_n + s.tail_n)
    hits = np.nonzero(rng.random(len(dust)) < 9.0 / SR)[0]
    for h in hits:
        end = min(len(dust), h + secs(0.003))
        dust[h:end] += rng.standard_normal(end - h) * 0.05
    s.put("dust", 0.0, band(dust, 800.0, 9000.0, 1), gain=0.6)
    keys = s.finish("keys", lo=120.0, hi=5200.0, wet=0.55, tau=1.6, seed=3)
    lead_stem = s.finish("lead", lo=300.0, hi=5000.0, wet=0.8, tau=1.8, seed=5)
    bass_stem = s.finish("bass", hi=700.0)
    drums = s.finish("drums", lo=40.0, hi=9500.0, wet=0.1, tau=0.5)
    dust_stem = s.finish("dust")
    mix = master([keys * 0.9 + lead_stem * 0.9 + bass_stem * 0.8 + drums * 0.6 + dust_stem * 0.5])[0]
    report("music_menu", mix)
    write_ogg("music_menu", mix)


# ------------------------------------------------------------------- shop

def shop():
    rng = np.random.default_rng(23)
    s = Song(bpm=104, bars=16)
    prog = [(55, MAJ), (52, MIN), (48, MAJ), (50, MAJ)]                    # G  Em  C  D
    scale = [67, 69, 71, 72, 74, 76, 79, 81]                               # G major
    kk, cl, hh, oh = kick(rng, 0.6), clap(rng), hat(rng), hat(rng, True)
    for bar in range(16):
        root, shape = prog[bar % 4]
        chord = voice(root + 12, shape + [12])
        # marimba arpeggio, 8ths, up then down
        order = [0, 1, 2, 3, 2, 1, 2, 1]
        for e in range(8):
            m = chord[order[e] % len(chord)]
            s.put("arp", s.at(bar, e * 0.5), marimba(hz(m), 0.3, 0.75 if e % 4 == 0 else 0.5), p=-0.3 + 0.08 * e, gain=0.75)
        s.put("bass", s.at(bar, 0.0), bass(hz(root - 12), 0.45, 0.9, 0.5), gain=0.75)
        s.put("bass", s.at(bar, 1.5), bass(hz(root - 12 + 7), 0.3, 0.7, 0.5), gain=0.6)
        s.put("bass", s.at(bar, 2.0), bass(hz(root - 12), 0.45, 0.8, 0.5), gain=0.7)
        s.put("bass", s.at(bar, 3.5), bass(hz(root - 12 + 7), 0.3, 0.6, 0.5), gain=0.6)
        s.put("drums", s.at(bar, 0.0), kk, gain=0.55)
        s.put("drums", s.at(bar, 2.0), kk, gain=0.45)
        s.put("drums", s.at(bar, 1.0), cl, p=0.1, gain=0.5)
        s.put("drums", s.at(bar, 3.0), cl, p=0.1, gain=0.5)
        for e in range(8):
            s.put("drums", s.at(bar, e * 0.5), hh, p=0.35, gain=0.22 if e % 2 == 0 else 0.13)
        s.put("drums", s.at(bar, 1.75), oh, p=-0.2, gain=0.18)
        # chord stabs on the off beats, a little bell on top every other bar
        for j, m in enumerate(voice(root + 12, shape)):
            s.put("keys", s.at(bar, 1.5), pluck(hz(m), 0.3, 0.5, 0.8), p=0.2, gain=0.5)
        if bar % 2 == 0 and bar >= 4:
            note = int(rng.choice(scale))
            s.put("lead", s.at(bar, 2.0), marimba(hz(note + 12), 0.6, 0.6), p=0.35, gain=0.6)
            s.put("lead", s.at(bar, 3.0), marimba(hz(int(rng.choice(scale)) + 12), 0.6, 0.5), p=0.35, gain=0.5)
    arp = s.finish("arp", lo=150.0, hi=9000.0, wet=0.35, tau=0.9)
    keys = s.finish("keys", lo=200.0, hi=7000.0, wet=0.3, tau=0.9)
    lead_stem = s.finish("lead", lo=300.0, hi=9000.0, wet=0.5, tau=1.2)
    bass_stem = s.finish("bass", hi=800.0)
    drums = s.finish("drums", lo=40.0, hi=12000.0, wet=0.08, tau=0.4)
    mix = master([arp * 0.8 + keys * 0.7 + lead_stem * 0.8 + bass_stem * 0.9 + drums * 0.7])[0]
    report("music_shop", mix)
    write_ogg("music_shop", mix)


# ------------------------------------------------------------------ bench

def bench():
    rng = np.random.default_rng(37)
    s = Song(bpm=92, bars=16)
    prog = [(50, MIN9), (50, MIN9), (55, [0, 4, 7, 10, 14]), (48, MAJ9)]   # Dm9 Dm9 G9 Cmaj9
    scale = [62, 64, 65, 67, 69, 71, 72]                                   # D dorian
    kk, hh = kick(rng, 0.9), hat(rng)
    ticks = [tick(rng, 1300.0), tick(rng, 1900.0), tick(rng, 900.0)]
    for bar in range(16):
        root, shape = prog[bar % 4]
        notes = voice(root + 12, shape)
        for j, m in enumerate(notes[:4]):
            s.put("keys", s.at(bar, 0.5 * j + (0.0 if bar % 2 == 0 else 0.25)), ep(hz(m), 1.4, 0.5), p=-0.2, gain=0.7)
        for j, m in enumerate(notes[1:4]):
            s.put("keys", s.at(bar, 2.5 + 0.5 * j), ep(hz(m), 1.0, 0.4), p=0.2, gain=0.55)
        s.put("bass", s.at(bar, 0.0), bass(hz(root - 24), 0.7, 0.95, 0.6), gain=0.8)
        s.put("bass", s.at(bar, 1.5), bass(hz(root - 24), 0.5, 0.75, 0.6), gain=0.65)
        s.put("bass", s.at(bar, 3.0), bass(hz(root - 12), 0.5, 0.75, 0.6), gain=0.65)
        # a printer's stepper motors: steady little ticks with a rotating accent
        for e in range(16):
            tk = ticks[(e // 4 + bar) % 3] if e % 4 == 0 else ticks[0]
            s.put("drums", s.at(bar, e * 0.25), tk, p=0.4 if e % 2 else -0.4, gain=0.35 if e % 4 == 0 else 0.16)
        s.put("drums", s.at(bar, 0.0), kk, gain=0.6)
        s.put("drums", s.at(bar, 2.0), kk, gain=0.5)
        s.put("drums", s.at(bar, 3.5), hh, gain=0.3)
        if bar % 4 == 3:
            for e in range(4):
                s.put("drums", s.at(bar, 3.0 + e * 0.25), tick(rng, 2400.0), gain=0.3)
        if bar >= 8 and bar % 2 == 1:
            for e, off in enumerate([0.0, 0.75, 1.5, 2.5]):
                s.put("lead", s.at(bar, off), pluck(hz(int(rng.choice(scale)) + 12), 0.4, 0.7, 1.1), p=0.3, gain=0.6)
    keys = s.finish("keys", lo=150.0, hi=5500.0, wet=0.45, tau=1.4, seed=9)
    lead_stem = s.finish("lead", lo=250.0, hi=8000.0, wet=0.6, tau=1.5, seed=13)
    bass_stem = s.finish("bass", hi=650.0)
    drums = s.finish("drums", lo=40.0, hi=11000.0, wet=0.06, tau=0.3)
    mix = master([keys * 0.85 + lead_stem * 0.8 + bass_stem * 0.9 + drums * 0.75])[0]
    report("music_bench", mix)
    write_ogg("music_bench", mix)


# ----------------------------------------------------------------- battle

def battle(name, bpm, key, prog_a, prog_b, seed, lead_scale):
    """Three layers on one grid. `prog_*` are four (semitones-above-key, shape) chords, two bars each."""
    rng = np.random.default_rng(seed)
    bars = 32
    s = Song(bpm=bpm, bars=bars)
    kk, sn, cl, hh, oh, sh = kick(rng), snare(rng), clap(rng), hat(rng), hat(rng, True), shaker(rng)
    toms = [tom(f, rng) for f in (110.0, 146.0, 196.0)]
    riser_n = secs(s.beat * 4)
    riser = band(noise(riser_n, rng), 500.0, 9000.0, 1) * np.linspace(0.0, 1.0, riser_n) ** 2.2 * 0.5

    def chord_for(bar):
        prog = prog_a if (bar // 8) % 2 == 0 else prog_b
        off, shape = prog[(bar % 8) // 2]
        return key + off, shape

    for bar in range(bars):
        root, shape = chord_for(bar)
        section_b = (bar // 8) % 2 == 1
        top = bar % 8 == 7
        # -- base: pad, a quiet sub pulse, ticking shaker
        if bar % 2 == 0:
            s.put("base", s.at(bar, 0.0), pad([hz(m) for m in voice(root + 12, shape)], s.beat * 8 * 0.5, 0.9, 1.6, 0.8), p=0.0, gain=0.5)
        for e in range(8):
            s.put("base", s.at(bar, e * 0.5), sub(hz(root - 24), s.beat * 0.45, 0.6 if e % 2 == 0 else 0.4), gain=0.75)
        for e in range(4):
            s.put("base", s.at(bar, e + 0.5), sh, p=0.35 if e % 2 else -0.35, gain=0.5)
        if bar % 8 == 0:
            s.put("base", s.at(bar, 0.0), kk, gain=0.7)
        # -- drive: four on the floor, backbeat, hats, off-beat bass, arpeggio
        for b in range(4):
            s.put("drive", s.at(bar, b), kk, gain=0.8)
        s.put("drive", s.at(bar, 1.0), sn, gain=0.7)
        s.put("drive", s.at(bar, 3.0), sn, gain=0.7)
        s.put("drive", s.at(bar, 3.0), cl, p=0.15, gain=0.35)
        for e in range(8):
            s.put("drive", s.at(bar, e * 0.5), hh, p=0.4, gain=0.3 if e % 2 else 0.2)
        s.put("drive", s.at(bar, 1.5), oh, p=-0.2, gain=0.22)
        s.put("drive", s.at(bar, 3.5), oh, p=-0.2, gain=0.22)
        for e, off in enumerate([0.5, 1.5, 2.5, 3.5]):
            octave = 12 if (e + bar) % 4 == 3 else 0
            s.put("drive", s.at(bar, off), bass(hz(root - 24 + octave), 0.35, 0.85, 0.7), gain=0.7)
        chord = voice(root + 12 + (12 if section_b else 0), shape)
        order = [0, 1, 2, 1, 3, 2, 1, 2] if not section_b else [0, 2, 1, 3, 2, 3, 1, 2]
        for e in range(8):
            m = chord[order[e] % len(chord)]
            s.put("drive", s.at(bar, e * 0.5), pluck(hz(m), 0.28, 0.65 if e % 2 == 0 else 0.45, 1.2), p=-0.3 + 0.075 * e, gain=0.6)
        # -- danger: a stabbing riff, toms and a riser into each 8 bar phrase
        riff = [0, 0, 7, 0, 3, 0, 5, 7] if not section_b else [0, 3, 0, 5, 0, 7, 10, 7]
        for e, step in enumerate(riff):
            if e % 2 == 1 and step == 0:
                continue
            note = root + 24 + step if step else root + 24
            s.put("danger", s.at(bar, e * 0.5), lead(hz(note), s.beat * 0.4, 0.8 if e % 2 == 0 else 0.55), p=0.15, gain=0.75)
        s.put("danger", s.at(bar, 2.0), toms[1], p=-0.25, gain=0.5)
        s.put("danger", s.at(bar, 3.0), toms[0], p=0.25, gain=0.55)
        s.put("danger", s.at(bar, 3.5), toms[2], p=-0.1, gain=0.4)
        s.put("danger", s.at(bar, 0.0), brass(hz(root - 12), s.beat * 3.5, 0.6), gain=0.5)
        if top:
            s.put("danger", s.at(bar, 0.0), riser, gain=0.9)
    base = s.finish("base", lo=30.0, hi=4800.0, wet=0.35, tau=1.8, seed=21)
    drive = s.finish("drive", lo=35.0, hi=11000.0, wet=0.12, tau=0.6, seed=22)
    danger = s.finish("danger", lo=60.0, hi=8000.0, wet=0.3, tau=1.2, seed=23)
    layers = master([base, drive, danger * 1.7])
    for label, x in zip(("base", "drive", "danger"), layers):
        report(f"music_{name}_{label}", x)
        write_ogg(f"music_{name}_{label}", x)


def battle1():
    # A minor: Am F C G, then Dm Am F E
    a = [(0, MIN), (-4, MAJ7), (3, MAJ), (-2, MAJ)]
    b = [(5, MIN), (0, MIN), (-4, MAJ), (-1, MAJ)]
    battle("battle1", 124, 57, a, b, 101, None)


def battle2():
    # D minor, faster and heavier: Dm Bb Gm A, then Gm Bb F C
    a = [(0, MIN), (-4, MAJ), (5, MIN), (7, DOM7)]
    b = [(5, MIN), (-4, MAJ), (-2, MAJ), (3, MAJ)]
    battle("battle2", 140, 50, a, b, 202, None)


TRACKS = {"menu": menu, "shop": shop, "bench": bench, "battle1": battle1, "battle2": battle2}

if __name__ == "__main__":
    wanted = sys.argv[1:] or list(TRACKS)
    for track in wanted:
        print(track)
        TRACKS[track]()
