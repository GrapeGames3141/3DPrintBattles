"""Composes 3D Print Arena' music.

The sound is "the Foundry": a workshop that sounds like a heroic fantasy
score. Strings, brass and big drums carry plain minor triads and a melody
you can hum; stepper-motor ticks and hammer-on-metal hits are the percussion.
(The first version used jazz seventh chords and an electric piano, which is
what lifts sound like.)

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
    Song, anvil, bass, bell, brass, clap, crash, ep, hat, heartbeat, kick, lead, marimba, master, noise, pad, pluck,
    report, saw_bass, shaker, snare, strings, sub, taiko, tick, tom, hz, write_ogg, secs, tt, band, fft_filter, SR,
    soft_clip,
)

MIN = [0, 3, 7]
MAJ = [0, 4, 7]
SUS = [0, 5, 7]


def ladder(root, shape):
    """The notes of a chord stacked upward over three octaves: root, 3rd, 5th, root+12 ..."""
    base = [root + x for x in shape]
    return base + [x + 12 for x in base] + [x + 24 for x in base]


# One chord's worth of melody is two bars of this rhythm: (beat, length).
HOOK_RHYTHM = [(0.0, 1.5), (1.5, 0.5), (2.0, 1.0), (3.0, 1.0), (4.0, 1.5), (5.5, 0.5), (6.0, 2.0)]


def hook(s, stem, bar, root, shape, steps, inst, base_octave=3, p=0.1, gain=0.7, vel=0.8):
    """Plays the melody for one chord (two bars): `steps` are chord-ladder positions."""
    notes = ladder(root, shape)
    for (beat, length), step in zip(HOOK_RHYTHM, steps):
        m = notes[step]
        s.put(stem, s.at(bar, beat), inst(hz(m), length * s.beat * 0.92, vel if beat % 2 == 0 else vel * 0.75), p=p, gain=gain)


# ------------------------------------------------------------------- menu

def menu():
    """The Foundry theme: strings and harp under a bell melody, with a slow taiko heartbeat."""
    rng = np.random.default_rng(11)
    s = Song(bpm=88, bars=16)
    prog = [(57, MIN), (53, MAJ), (48, MAJ), (55, MAJ)]                  # Am  F  C  G
    tk, st = taiko(rng, 58.0), taiko(rng, 76.0)
    ticks = [tick(rng, 1500.0), tick(rng, 2100.0)]
    a_hook = [5, 4, 3, 4, 5, 4, 3]            # down and back up: the "welcome" tune
    b_hook = [5, 6, 5, 4, 5, 4, 3]            # lifts at the top
    for chord_i in range(8):
        bar = chord_i * 2
        root, shape = prog[chord_i % 4]
        notes = ladder(root, shape)
        # strings swell under the whole chord; a second voice doubles an octave up
        for m in [root + x for x in shape]:
            s.put("pad", s.at(bar, 0.0), strings(hz(m + 12), s.beat * 7.5, 0.7, 0.9), p=-0.2, gain=0.55)
        s.put("pad", s.at(bar, 0.0), strings(hz(root + 24), s.beat * 7.5, 0.55, 1.1), p=0.25, gain=0.35)
        # harp: a rolling arpeggio, eighth notes, one octave and a half across
        run = [0, 1, 2, 4, 5, 4, 2, 1]
        for e in range(16):
            m = notes[run[e % 8] + 3] if e < 8 else notes[run[(e + 3) % 8] + 3]
            s.put("harp", s.at(bar, e * 0.5), pluck(hz(m), 0.4, 0.5 if e % 4 else 0.7, 0.9), p=-0.35 + 0.05 * (e % 8), gain=0.7)
        # bass holds the root and walks to the next chord
        s.put("bass", s.at(bar, 0.0), saw_bass(hz(root - 24), s.beat * 3.0, 0.8, 500.0), gain=0.8)
        s.put("bass", s.at(bar, 4.0), saw_bass(hz(root - 24), s.beat * 3.0, 0.7, 500.0), gain=0.7)
        s.put("bass", s.at(bar, 7.0), saw_bass(hz(root - 12 + (7 if chord_i % 2 else 0)), s.beat * 0.9, 0.7, 500.0), gain=0.6)
        # the heartbeat: a taiko on the first beat of each chord, softer on the third bar's downbeat
        s.put("drums", s.at(bar, 0.0), tk, gain=0.8)
        s.put("drums", s.at(bar, 4.0), st, gain=0.45)
        if chord_i >= 2:
            s.put("drums", s.at(bar, 6.0), st, gain=0.35)
            s.put("drums", s.at(bar, 7.5), st, gain=0.3)
        for e in range(16):
            s.put("drums", s.at(bar, e * 0.5), ticks[e % 2], p=0.4 if e % 2 else -0.4, gain=0.2 if e % 4 else 0.3)
        if chord_i % 4 == 0:
            s.put("drums", s.at(bar, 0.0), anvil(rng, 440.0), gain=0.45)
        # the tune: bells for the first four chords, a violin-ish lead takes it for the last four
        if chord_i >= 2:
            inst = bell if chord_i < 6 else (lambda f, d, v: strings(f, d, v, 0.05))
            steps = a_hook if chord_i % 4 != 3 else b_hook
            hook(s, "lead", bar, root, shape, steps, inst, gain=0.75 if chord_i < 6 else 0.6, vel=0.8)
    pad = s.finish("pad", lo=100.0, hi=5200.0, wet=0.45, tau=2.2, seed=3)
    harp = s.finish("harp", lo=200.0, hi=7500.0, wet=0.4, tau=1.4, seed=4)
    lead_stem = s.finish("lead", lo=250.0, hi=9000.0, wet=0.5, tau=1.8, seed=5)
    bass_stem = s.finish("bass", hi=700.0)
    drums = s.finish("drums", lo=35.0, hi=9000.0, wet=0.2, tau=1.0, seed=6)
    mix = master([pad * 0.8 + harp * 0.7 + lead_stem * 1.0 + bass_stem * 0.85 + drums * 0.9])[0]
    report("music_menu", mix)
    write_ogg("music_menu", mix)


# ------------------------------------------------------------------- shop

def shop():
    """Bright and bouncy: marimba groove under a catchy four-bar tune."""
    rng = np.random.default_rng(23)
    s = Song(bpm=108, bars=16)
    prog = [(55, MAJ), (52, MIN), (48, MAJ), (50, MAJ)]                    # G  Em  C  D
    kk, cl, hh, oh = kick(rng, 0.6), clap(rng), hat(rng), hat(rng, True)
    # The tune, one bar per chord: (beat, ladder position, length). Position 3 is the chord's root in the octave above the bass.
    tune_a = [(0.0, 4, 0.5), (0.5, 5, 0.5), (1.0, 7, 1.0), (2.0, 5, 0.5), (2.5, 4, 0.5), (3.0, 5, 1.0)]
    tune_b = [(0.0, 5, 0.5), (0.5, 7, 0.5), (1.0, 8, 1.0), (2.0, 7, 0.5), (2.5, 5, 0.5), (3.0, 4, 1.0)]
    for bar in range(16):
        root, shape = prog[bar % 4]
        chord = ladder(root, shape)
        order = [3, 4, 5, 6, 5, 4, 5, 4]
        for e in range(8):
            s.put("arp", s.at(bar, e * 0.5), marimba(hz(chord[order[e]]), 0.3, 0.7 if e % 4 == 0 else 0.45), p=-0.3 + 0.08 * e, gain=0.6)
        s.put("bass", s.at(bar, 0.0), saw_bass(hz(root - 12), 0.4, 0.9, 700.0), gain=0.8)
        s.put("bass", s.at(bar, 1.5), saw_bass(hz(root - 12 + 7), 0.3, 0.7, 700.0), gain=0.65)
        s.put("bass", s.at(bar, 2.0), saw_bass(hz(root - 12), 0.4, 0.8, 700.0), gain=0.75)
        s.put("bass", s.at(bar, 3.5), saw_bass(hz(root - 12 + 7), 0.3, 0.6, 700.0), gain=0.6)
        s.put("drums", s.at(bar, 0.0), kk, gain=0.6)
        s.put("drums", s.at(bar, 2.0), kk, gain=0.5)
        s.put("drums", s.at(bar, 1.0), cl, p=0.1, gain=0.5)
        s.put("drums", s.at(bar, 3.0), cl, p=0.1, gain=0.5)
        for e in range(8):
            s.put("drums", s.at(bar, e * 0.5), hh, p=0.35, gain=0.22 if e % 2 == 0 else 0.13)
        s.put("drums", s.at(bar, 1.75), oh, p=-0.2, gain=0.18)
        for m in [root + 12 + x for x in shape]:
            s.put("keys", s.at(bar, 1.5), pluck(hz(m), 0.3, 0.5, 0.8), p=0.2, gain=0.4)
        if bar >= 4:
            tune = tune_a if bar % 8 < 4 else tune_b
            for beat, pos, length in tune:
                s.put("lead", s.at(bar, beat), bell(hz(chord[pos - 1]), length * s.beat, 0.8), p=0.3, gain=0.7)
                if bar >= 8:
                    s.put("lead", s.at(bar, beat), marimba(hz(chord[pos - 1]), 0.4, 0.5), p=0.35, gain=0.45)
    arp = s.finish("arp", lo=150.0, hi=9000.0, wet=0.35, tau=0.9)
    keys = s.finish("keys", lo=200.0, hi=7000.0, wet=0.3, tau=0.9)
    lead_stem = s.finish("lead", lo=300.0, hi=11000.0, wet=0.5, tau=1.2)
    bass_stem = s.finish("bass", hi=800.0)
    drums = s.finish("drums", lo=40.0, hi=12000.0, wet=0.08, tau=0.4)
    mix = master([arp * 0.8 + keys * 0.6 + lead_stem * 0.9 + bass_stem * 0.9 + drums * 0.7])[0]
    report("music_shop", mix)
    write_ogg("music_shop", mix)


# ------------------------------------------------------------------ bench

def bench():
    """The workshop: busy stepper ticks and a dark pulse under a small pluck motif."""
    rng = np.random.default_rng(37)
    s = Song(bpm=96, bars=16)
    prog = [(50, MIN), (50, MIN), (46, MAJ), (48, MAJ)]                    # Dm Dm Bb C
    kk, hh = kick(rng, 0.9), hat(rng)
    ticks = [tick(rng, 1300.0), tick(rng, 1900.0), tick(rng, 900.0)]
    motif = [3, 5, 4, 5, 6, 5, 4]
    for bar in range(16):
        root, shape = prog[bar % 4]
        notes = ladder(root, shape)
        for j in range(8):
            s.put("keys", s.at(bar, j * 0.5), pluck(hz(notes[[3, 5, 4, 5, 3, 5, 6, 5][j]]), 0.3, 0.5 if j % 2 else 0.7, 1.0), p=-0.2 + 0.05 * j, gain=0.6)
        for m in [root + x for x in shape]:
            s.put("pad", s.at(bar, 0.0), strings(hz(m + 12), s.beat * 3.8, 0.5, 0.5), p=0.0, gain=0.35)
        s.put("bass", s.at(bar, 0.0), saw_bass(hz(root - 24), 0.7, 0.9, 500.0), gain=0.8)
        s.put("bass", s.at(bar, 1.5), saw_bass(hz(root - 24), 0.4, 0.7, 500.0), gain=0.65)
        s.put("bass", s.at(bar, 2.5), saw_bass(hz(root - 12), 0.4, 0.7, 500.0), gain=0.65)
        for e in range(16):
            tk = ticks[(e // 4 + bar) % 3] if e % 4 == 0 else ticks[0]
            s.put("drums", s.at(bar, e * 0.25), tk, p=0.4 if e % 2 else -0.4, gain=0.35 if e % 4 == 0 else 0.16)
        s.put("drums", s.at(bar, 0.0), kk, gain=0.6)
        s.put("drums", s.at(bar, 2.0), kk, gain=0.5)
        s.put("drums", s.at(bar, 3.5), hh, gain=0.3)
        if bar % 4 == 3:
            s.put("drums", s.at(bar, 3.0), anvil(rng, 620.0), gain=0.4)
        if bar >= 8:
            hook(s, "lead", bar - (bar % 2), root, shape, motif, bell, gain=0.55, vel=0.7) if bar % 2 == 0 else None
    keys = s.finish("keys", lo=150.0, hi=6500.0, wet=0.4, tau=1.2, seed=9)
    pad_stem = s.finish("pad", lo=120.0, hi=3500.0, wet=0.5, tau=1.8, seed=11)
    lead_stem = s.finish("lead", lo=250.0, hi=9000.0, wet=0.55, tau=1.4, seed=13)
    bass_stem = s.finish("bass", hi=650.0)
    drums = s.finish("drums", lo=40.0, hi=11000.0, wet=0.06, tau=0.3)
    mix = master([keys * 0.8 + pad_stem * 0.7 + lead_stem * 0.8 + bass_stem * 0.9 + drums * 0.75])[0]
    report("music_bench", mix)
    write_ogg("music_bench", mix)


# ----------------------------------------------------------------- battle

def battle(name, bpm, phrase_a, phrase_b, seed, gallop, hooks):
    """Three layers on one grid. `phrase_*` are four (root midi, shape) chords, two bars each,
    for eight-bar phrases that alternate A B A B over 32 bars.

    base   the tension that never leaves: a galloping synth bass, stepper ticks, a drone, hammer hits
    drive  the fight: kick, snare, claps, hats, taiko fills, string stabs, a chiming arpeggio
    danger the crisis: the melody on lead and brass, heartbeats, a riser into each phrase
    """
    rng = np.random.default_rng(seed)
    bars = 32
    s = Song(bpm=bpm, bars=bars)
    kk, sn, cl, hh, oh, sh = kick(rng), snare(rng), clap(rng), hat(rng), hat(rng, True), shaker(rng)
    tms = [taiko(rng, f) for f in (70.0, 92.0, 118.0)]
    ticks = [tick(rng, 1500.0), tick(rng, 2200.0), tick(rng, 1000.0)]
    hits = [anvil(rng, 380.0), anvil(rng, 520.0)]
    cr, hb = crash(rng), heartbeat(rng)
    riser_n = secs(s.beat * 8)
    riser = band(noise(riser_n, rng), 400.0, 9000.0, 1) * np.linspace(0.0, 1.0, riser_n) ** 2.4 * 0.5

    for bar in range(bars):
        phrase = phrase_a if (bar // 8) % 2 == 0 else phrase_b
        phrase_is_b = (bar // 8) % 2 == 1
        chord_i = (bar % 8) // 2
        root, shape = phrase[chord_i]
        first = bar % 2 == 0
        notes = ladder(root, shape)
        last_of_phrase = bar % 8 == 7
        # ---- base
        for e, on in enumerate(gallop):
            if on:
                oct_up = 12 if (e == 6 and bar % 4 == 3) else 0
                s.put("base", s.at(bar, e * 0.5), saw_bass(hz(root - 24 + oct_up), s.beat * 0.4, 0.9 if e % 4 == 0 else 0.7, 650.0), gain=0.85)
        for e in range(8):
            s.put("base", s.at(bar, e * 0.5), ticks[(e + bar) % 3], p=0.4 if e % 2 else -0.4, gain=0.34 if e % 2 == 0 else 0.2)
        if first:
            for m in [root + x for x in shape]:
                s.put("base", s.at(bar, 0.0), strings(hz(m + 12), s.beat * 7.4, 0.6, 0.7), p=0.0, gain=0.38)
            s.put("base", s.at(bar, 0.0), sub(hz(root - 36), s.beat * 7.5, 0.7), gain=0.7)
        if bar % 4 == 0:
            s.put("base", s.at(bar, 0.0), hits[(bar // 4) % 2], p=-0.2, gain=0.5)
        # ---- drive
        for b in (0.0, 2.0):
            s.put("drive", s.at(bar, b), kk, gain=0.85)
        s.put("drive", s.at(bar, 1.5), kk, gain=0.5)
        s.put("drive", s.at(bar, 3.5 if bar % 2 else 2.75), kk, gain=0.5)
        s.put("drive", s.at(bar, 1.0), sn, gain=0.75)
        s.put("drive", s.at(bar, 3.0), sn, gain=0.8)
        s.put("drive", s.at(bar, 3.0), cl, p=0.15, gain=0.4)
        for e in range(8):
            s.put("drive", s.at(bar, e * 0.5), hh, p=0.4, gain=0.3 if e % 2 else 0.2)
        s.put("drive", s.at(bar, 1.5), oh, p=-0.2, gain=0.2)
        s.put("drive", s.at(bar, 3.5), oh, p=-0.2, gain=0.2)
        # string stabs on a syncopated rhythm: the chord, short and hard
        for off in ([0.0, 0.75, 1.5, 2.5, 3.0] if not phrase_is_b else [0.0, 0.5, 1.5, 2.0, 3.5]):
            for m in [root + x for x in shape]:
                s.put("drive", s.at(bar, off), strings(hz(m + 12), s.beat * 0.32, 0.9, 0.012), p=0.0, gain=0.34)
        arp = [3, 5, 4, 5, 6, 5, 4, 5] if not phrase_is_b else [3, 4, 5, 6, 7, 6, 5, 4]
        for e in range(8):
            s.put("drive", s.at(bar, e * 0.5), bell(hz(notes[arp[e]] + 12), 0.25, 0.5 if e % 2 == 0 else 0.35), p=-0.3 + 0.075 * e, gain=0.45)
        if bar % 4 == 3:                       # a fill into every fourth bar
            for e, (beat, t_i) in enumerate([(2.0, 2), (2.5, 2), (3.0, 1), (3.25, 1), (3.5, 0), (3.75, 0)]):
                s.put("drive", s.at(bar, beat), tms[t_i], p=-0.3 + 0.12 * e, gain=0.6)
        if bar % 8 == 0:
            s.put("drive", s.at(bar, 0.0), cr, gain=0.55)
        # ---- danger
        if first:
            steps = hooks[0 if not phrase_is_b else 1][chord_i]
            for (beat, length), step in zip(HOOK_RHYTHM, steps):
                m = notes[step]
                s.put("danger", s.at(bar, beat), lead(hz(m), length * s.beat * 0.92, 0.85), p=0.15, gain=0.7)
                s.put("danger", s.at(bar, beat), brass(hz(m - 12), length * s.beat * 0.85, 0.8), p=-0.1, gain=0.5)
        s.put("danger", s.at(bar, 0.0), hb, p=-0.1, gain=0.7)
        s.put("danger", s.at(bar, 2.0), hb, p=-0.1, gain=0.45)
        if last_of_phrase:
            s.put("danger", s.at(bar - 1, 0.0), riser, gain=0.9)
    base = s.finish("base", lo=30.0, hi=5200.0, wet=0.25, tau=1.6, seed=21)
    drive = s.finish("drive", lo=35.0, hi=11000.0, wet=0.18, tau=0.8, seed=22)
    danger = s.finish("danger", lo=40.0, hi=8000.0, wet=0.3, tau=1.4, seed=23)
    layers = master([base * 1.15, drive, danger * 1.5])
    for label, x in zip(("base", "drive", "danger"), layers):
        report(f"music_{name}_{label}", x)
        write_ogg(f"music_{name}_{label}", x)


def battle1():
    """D minor, 132 bpm. Dm Bb F C, then Dm C Bb A: the fanfare rises, then turns on the dominant."""
    a = [(50, MIN), (46, MAJ), (53, MAJ), (48, MAJ)]
    b = [(50, MIN), (48, MAJ), (46, MAJ), (45, MAJ)]
    hooks = [
        [[5, 7, 8, 7, 6, 7, 5], [5, 7, 8, 7, 6, 7, 5], [5, 7, 8, 7, 6, 7, 5], [5, 7, 8, 7, 6, 5, 4]],
        [[8, 7, 6, 7, 8, 7, 5], [8, 7, 6, 7, 8, 7, 5], [8, 7, 6, 7, 8, 7, 5], [6, 7, 8, 7, 6, 5, 3]],
    ]
    gallop = [1, 0, 1, 1, 0, 1, 1, 0]        # x . x x . x x .
    battle("battle1", 132, a, b, 101, gallop, hooks)


def battle2():
    """A minor, 144 bpm, heavier: Am F C G, then Am Dm F E."""
    a = [(57, MIN), (53, MAJ), (48, MAJ), (55, MAJ)]
    b = [(57, MIN), (50, MIN), (53, MAJ), (52, MAJ)]
    hooks = [
        [[4, 5, 6, 5, 4, 3, 4], [4, 5, 6, 5, 4, 3, 4], [4, 5, 6, 5, 4, 3, 4], [5, 4, 3, 4, 5, 4, 3]],
        [[6, 5, 4, 5, 6, 7, 6], [6, 5, 4, 5, 6, 7, 6], [6, 5, 4, 5, 6, 7, 6], [7, 6, 5, 6, 7, 6, 5]],
    ]
    gallop = [1, 1, 0, 1, 1, 0, 1, 0]        # x x . x x . x .
    battle("battle2", 144, a, b, 202, gallop, hooks)


TRACKS = {"menu": menu, "shop": shop, "bench": bench, "battle1": battle1, "battle2": battle2}

if __name__ == "__main__":
    wanted = sys.argv[1:] or list(TRACKS)
    for track in wanted:
        print(track)
        TRACKS[track]()
