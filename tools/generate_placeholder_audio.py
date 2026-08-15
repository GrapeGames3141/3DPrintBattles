#!/usr/bin/env python3
"""Generate royalty-free placeholder WAV audio (no API keys). Replace with ElevenLabs in Phase 4."""

import math
import os
import random
import struct
import wave

SAMPLE_RATE = 44100
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")


def write_wav(path: str, samples: list[float]) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        frames = b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples
        )
        w.writeframes(frames)


def sine(freq: float, t: float, amp: float = 1.0) -> float:
    return amp * math.sin(2 * math.pi * freq * t)


def env(t: float, attack: float, release: float, duration: float) -> float:
    if t < attack:
        return t / attack
    if t > duration - release:
        return max(0.0, (duration - t) / release)
    return 1.0


def mix(*parts: float) -> float:
    return max(-1.0, min(1.0, sum(parts)))


def gen_music_workshop(duration: float = 8.0) -> list[float]:
    chords = [(220, 277, 330), (196, 247, 294), (247, 311, 370), (220, 277, 330)]
    samples = []
    n = int(duration * SAMPLE_RATE)
    step = duration / len(chords)
    for i in range(n):
        t = i / SAMPLE_RATE
        ci = min(int(t / step), len(chords) - 1)
        f1, f2, f3 = chords[ci]
        e = 0.35 + 0.15 * math.sin(t * 0.5)
        s = sine(f1, t, 0.12 * e) + sine(f2, t, 0.08 * e) + sine(f3, t, 0.06 * e)
        s += sine(f1 * 0.5, t, 0.05 * e)
        samples.append(s * 0.7)
    return samples


def gen_music_battle(duration: float = 6.0) -> list[float]:
    samples = []
    n = int(duration * SAMPLE_RATE)
    for i in range(n):
        t = i / SAMPLE_RATE
        beat = (t * 2.0) % 1.0
        kick = sine(60, t, 0.4) * math.exp(-beat * 8) if beat < 0.15 else 0
        bass = sine(110 + 20 * math.sin(t * 0.8), t, 0.15)
        pulse = sine(440, t, 0.04) * (0.5 + 0.5 * math.sin(t * 8))
        samples.append(mix(kick, bass, pulse) * 0.65)
    return samples


def gen_music_academy(duration: float = 10.0) -> list[float]:
    melody = [523, 587, 659, 784, 659, 587, 523, 440]
    samples = []
    n = int(duration * SAMPLE_RATE)
    note_len = duration / len(melody)
    for i in range(n):
        t = i / SAMPLE_RATE
        ni = min(int(t / note_len), len(melody) - 1)
        freq = melody[ni]
        local_t = t - ni * note_len
        e = env(local_t, 0.02, 0.08, note_len)
        s = sine(freq, t, 0.18 * e) + sine(freq * 2, t, 0.06 * e)
        s += sine(262, t, 0.05)
        samples.append(s * 0.6)
    return samples


def gen_tone_burst(freqs: list[float], duration: float, decay: float = 4.0) -> list[float]:
    samples = []
    n = int(duration * SAMPLE_RATE)
    for i in range(n):
        t = i / SAMPLE_RATE
        e = math.exp(-t * decay)
        s = sum(sine(f, t, 0.25 * e) for f in freqs)
        samples.append(s * 0.5)
    return samples


def gen_noise_hit(duration: float = 0.25) -> list[float]:
    samples = []
    n = int(duration * SAMPLE_RATE)
    for i in range(n):
        t = i / SAMPLE_RATE
        e = math.exp(-t * 12)
        nse = (random.random() * 2 - 1) * 0.3 * e
        thump = sine(80, t, 0.5 * e)
        samples.append(mix(nse, thump))
    return samples


def gen_coin() -> list[float]:
    samples = []
    for freq, start, dur in [(880, 0.0, 0.12), (1175, 0.1, 0.15)]:
        n = int(dur * SAMPLE_RATE)
        for i in range(n):
            t = i / SAMPLE_RATE
            e = env(t, 0.005, 0.05, dur)
            samples.append(sine(freq, t, 0.35 * e) if i == 0 or True else 0)
    # rebuild properly
    out = []
    total = int(0.3 * SAMPLE_RATE)
    for i in range(total):
        t = i / SAMPLE_RATE
        s = 0.0
        if t < 0.12:
            s += sine(880, t, 0.35 * env(t, 0.005, 0.04, 0.12))
        if t >= 0.08:
            s += sine(1175, t - 0.08, 0.35 * env(t - 0.08, 0.005, 0.05, 0.15))
        out.append(s * 0.6)
    return out


def gen_whir_pop() -> list[float]:
    out = []
    n = int(0.9 * SAMPLE_RATE)
    for i in range(n):
        t = i / SAMPLE_RATE
        if t < 0.6:
            freq = 200 + t * 400
            s = sine(freq, t, 0.12) * (0.3 + 0.7 * t / 0.6)
        else:
            pop_t = t - 0.6
            s = sine(660, t, 0.3 * math.exp(-pop_t * 8))
            s += sine(990, t, 0.15 * math.exp(-pop_t * 10))
        out.append(s * 0.55)
    return out


def gen_click() -> list[float]:
    return gen_tone_burst([1200], 0.08, 20.0)


def gen_buzz() -> list[float]:
    out = []
    n = int(0.35 * SAMPLE_RATE)
    for i in range(n):
        t = i / SAMPLE_RATE
        s = sine(180, t, 0.3) + (random.random() * 2 - 1) * 0.15
        out.append(s * math.exp(-t * 3) * 0.5)
    return out


def main() -> int:
    tracks = {
        "music_workshop.wav": gen_music_workshop,
        "music_battle.wav": gen_music_battle,
        "music_academy.wav": gen_music_academy,
        "sfx_hit.wav": gen_noise_hit,
        "sfx_victory.wav": lambda: gen_tone_burst([523, 659, 784, 1047], 1.2, 2.5),
        "sfx_defeat.wav": lambda: gen_tone_burst([392, 330, 262, 196], 1.0, 3.0),
        "sfx_coin.wav": gen_coin,
        "sfx_levelup.wav": lambda: gen_tone_burst([440, 554, 659, 880], 1.0, 2.0),
        "sfx_summon.wav": gen_whir_pop,
        "sfx_card.wav": gen_click,
        "sfx_ability.wav": lambda: gen_tone_burst([330, 440, 550, 660], 0.45, 5.0),
        "sfx_buy.wav": gen_coin,
        "sfx_error.wav": gen_buzz,
    }
    for name, fn in tracks.items():
        path = os.path.join(OUT_DIR, name)
        print(f"Generating {name}...")
        write_wav(path, fn())
    print(f"Done — {len(tracks)} placeholder WAV files in {OUT_DIR}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
