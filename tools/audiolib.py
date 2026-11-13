"""A tiny synthesizer for 3D Print Arena' music and sound effects.

Pure numpy (plus soundfile to write OGG). Everything here is deterministic:
the same script always renders the same audio, so assets can be regenerated.

    uv run --with numpy --with soundfile python tools/make_music.py
    uv run --with numpy --with soundfile python tools/make_sfx.py
"""

from pathlib import Path

import numpy as np

SR = 44100
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio"
TAU = 2.0 * np.pi


def hz(midi):
    return 440.0 * 2.0 ** ((np.asarray(midi, dtype=float) - 69.0) / 12.0)


def tt(n):
    return np.arange(n) / SR


def secs(s):
    return int(round(s * SR))


# --------------------------------------------------------------- filtering

def fft_filter(x, lo=None, hi=None, order=2):
    """Zero-phase band limit. `lo` is a high-pass corner, `hi` a low-pass corner."""
    n = len(x)
    spec = np.fft.rfft(x)
    f = np.fft.rfftfreq(n, 1.0 / SR)
    gain = np.ones_like(f)
    if hi is not None:
        gain = gain / np.sqrt(1.0 + (f / hi) ** (2 * order))
    if lo is not None:
        gain = gain / np.sqrt(1.0 + (lo / np.maximum(f, 1e-3)) ** (2 * order))
    return np.fft.irfft(spec * gain, n)


def band(x, lo, hi, order=2):
    return fft_filter(x, lo=lo, hi=hi, order=order)


def noise(n, rng):
    return rng.standard_normal(n)


def exp_env(n, rate):
    return np.exp(-tt(n) * rate)


def attack(n, a):
    return np.minimum(tt(n) / max(a, 1e-4), 1.0)


def adsr(n, a, d, s, r):
    """Envelope over n samples: attack, decay to level s, hold, then release over the last r seconds."""
    t = tt(n)
    env = np.minimum(t / max(a, 1e-4), 1.0)
    env = env * (s + (1.0 - s) * np.exp(-np.maximum(t - a, 0.0) / max(d, 1e-4)))
    end = n / SR
    return env * np.where(t > end - r, np.clip((end - t) / max(r, 1e-4), 0.0, 1.0), 1.0)


def saw(freq, n, detune_cents=0.0, phase=0.0):
    f = freq * 2.0 ** (detune_cents / 1200.0)
    return 2.0 * (((tt(n) * f) + phase) % 1.0) - 1.0


def sine(freq, n, phase=0.0):
    return np.sin(TAU * freq * tt(n) + phase)


def chirp(f0, f1, n, curve=1.0):
    """A sine that glides from f0 to f1 (curve > 1 spends longer near f0)."""
    u = np.linspace(0.0, 1.0, n) ** curve
    freq = f0 + (f1 - f0) * u
    return np.sin(TAU * np.cumsum(freq) / SR)


def soft_clip(x, drive=1.0):
    return np.tanh(x * drive) / np.tanh(drive)


# ------------------------------------------------------------------- space

def reverb(stereo, wet=0.3, tau=1.3, seed=7, predelay=0.014, damp=5500.0):
    """Convolution reverb with a synthetic, decaying, darkened noise tail. Returns the wet signal only."""
    rng = np.random.default_rng(seed)
    n_ir = secs(tau * 2.4)
    t = tt(n_ir)
    out = np.zeros_like(stereo)
    for ch in range(stereo.shape[1]):
        ir = rng.standard_normal(n_ir) * np.exp(-t / tau * 3.0)
        ir = fft_filter(ir, hi=damp, order=1)
        ir[: secs(predelay) + ch * 37] = 0.0
        ir /= np.sqrt(np.sum(ir ** 2)) + 1e-9
        size = 1 << int(np.ceil(np.log2(len(stereo) + n_ir)))
        conv = np.fft.irfft(np.fft.rfft(stereo[:, ch], size) * np.fft.rfft(ir, size), size)[: len(stereo)]
        out[:, ch] = conv
    return out * wet


def pan(mono, p):
    """Constant-power pan, p from -1 (left) to 1 (right). Returns (n, 2)."""
    a = (p + 1.0) * np.pi / 4.0
    return np.stack([mono * np.cos(a), mono * np.sin(a)], axis=1)


# ------------------------------------------------------------- instruments

def ep(f, dur, vel=1.0):
    """Electric piano: gentle FM with a decaying bell-like tine."""
    n = secs(dur + 0.9)
    t = tt(n)
    idx = (1.5 * vel) * np.exp(-t * 4.2) + 0.2
    body = np.sin(TAU * f * t + idx * np.sin(TAU * f * t))
    tine = np.sin(TAU * f * 7.0 * t) * np.exp(-t * 20.0) * 0.1 * vel
    amp = np.exp(-t * 1.7) * attack(n, 0.004)
    rel = np.where(t < dur, 1.0, np.exp(-(t - dur) * 9.0))
    return (body + tine) * amp * rel * vel * 0.5


def pluck(f, dur=0.3, vel=1.0, bright=1.0):
    n = secs(dur + 0.25)
    t = tt(n)
    y = np.zeros(n)
    for k, (a, d) in enumerate([(1.0, 3.5), (0.5, 6.0), (0.33, 9.0), (0.2, 14.0), (0.12, 20.0)], 1):
        if f * k < SR * 0.45:
            y += a * np.sin(TAU * k * f * t) * np.exp(-t * d / max(bright, 0.2))
    return y * attack(n, 0.002) * vel * 0.45


def marimba(f, dur=0.3, vel=1.0):
    n = secs(dur + 0.3)
    t = tt(n)
    y = np.zeros(n)
    for ratio, a, d in [(1.0, 1.0, 6.0), (3.97, 0.32, 16.0), (9.9, 0.1, 32.0)]:
        if f * ratio < SR * 0.45:
            y += a * np.sin(TAU * f * ratio * t) * np.exp(-t * d)
    return y * attack(n, 0.001) * vel * 0.55


def bass(f, dur, vel=1.0, snap=0.35):
    n = secs(dur + 0.1)
    t = tt(n)
    ph = TAU * f * t
    y = np.sin(ph) + 0.4 * np.sin(2 * ph) + 0.18 * np.sin(3 * ph) * np.exp(-t * 9.0) * (1.0 + snap)
    y = soft_clip(y * 1.1, 1.2)
    return y * adsr(n, 0.006, 0.18, 0.75, 0.06) * vel * 0.6


def sub(f, dur, vel=1.0):
    n = secs(dur + 0.1)
    return np.sin(TAU * f * tt(n)) * adsr(n, 0.02, 0.4, 0.9, 0.08) * vel * 0.7


def pad(freqs, dur, a=0.7, r=1.2, vel=1.0):
    """A held chord: detuned saws plus a sine each. Meant to be low-passed by the caller."""
    n = secs(dur + r)
    y = np.zeros(n)
    for f in freqs:
        y += saw(f, n, -7.0) + saw(f, n, 7.0) + 0.6 * saw(f * 2.0, n, 3.0) * 0.5 + 0.8 * sine(f, n)
    y *= 1.0 / (len(freqs) * 2.0)
    t = tt(n)
    env = np.minimum(t / a, 1.0) * np.where(t < dur, 1.0, np.exp(-(t - dur) / r * 3.0))
    return y * env * vel


def lead(f, dur, vel=1.0, vibrato=0.006):
    n = secs(dur + 0.12)
    t = tt(n)
    vib = 1.0 + vibrato * np.sin(TAU * 5.5 * t) * np.minimum(t / 0.25, 1.0)
    ph = TAU * np.cumsum(f * vib) / SR
    y = 0.6 * (2.0 * ((ph / TAU) % 1.0) - 1.0) + 0.4 * np.sign(np.sin(ph)) * 0.5
    y = fft_filter(y, hi=4200.0, order=2)
    return y * adsr(n, 0.01, 0.3, 0.6, 0.08) * vel * 0.5


def brass(f, dur, vel=1.0):
    n = secs(dur + 0.2)
    t = tt(n)
    y = saw(f, n, -5.0) + saw(f, n, 5.0)
    y = fft_filter(y, hi=700.0 + 2600.0 * vel, order=2)
    swell = np.minimum(t / 0.09, 1.0)
    rel = np.where(t < dur, 1.0, np.exp(-(t - dur) * 14.0))
    return y * swell * rel * vel * 0.3


# ------------------------------------------------------------------- drums

def kick(rng, punch=1.0):
    n = secs(0.5)
    t = tt(n)
    freq = 44.0 + 120.0 * np.exp(-t * 30.0)
    ph = TAU * np.cumsum(freq) / SR
    body = np.sin(ph) * np.exp(-t * 7.0)
    click = noise(n, rng) * np.exp(-t * 600.0) * 0.25 * punch
    return soft_clip(body * 1.3 + click, 1.4) * 0.9


def snare(rng, tone=1.0):
    n = secs(0.3)
    t = tt(n)
    nz = band(noise(n, rng), 1300.0, 9000.0, order=1) * np.exp(-t * 17.0)
    body = np.sin(TAU * 188.0 * t) * np.exp(-t * 28.0) * 0.55 * tone
    return (nz * 0.7 + body) * 0.8


def hat(rng, open_=False):
    n = secs(0.45 if open_ else 0.09)
    t = tt(n)
    return fft_filter(noise(n, rng), lo=7000.0, order=2) * np.exp(-t * (11.0 if open_ else 70.0)) * 0.35


def clap(rng):
    n = secs(0.3)
    t = tt(n)
    y = np.zeros(n)
    for k, off in enumerate([0.0, 0.011, 0.022]):
        i = secs(off)
        seg = band(noise(n - i, rng), 900.0, 4800.0, order=1) * np.exp(-tt(n - i) * 95.0)
        y[i:] += seg
    y += band(noise(n, rng), 900.0, 3500.0, order=1) * np.exp(-t * 16.0) * 0.45
    return y * 0.5


def tom(freq, rng):
    n = secs(0.5)
    t = tt(n)
    ph = TAU * np.cumsum(freq * (1.0 + 0.55 * np.exp(-t * 22.0))) / SR
    return np.sin(ph) * np.exp(-t * 8.5) * 0.8


def shaker(rng):
    n = secs(0.07)
    env = np.sin(np.pi * np.linspace(0, 1, n)) ** 2
    return band(noise(n, rng), 5200.0, 13000.0, order=1) * env * 0.3


def tick(rng, freq=1500.0):
    n = secs(0.03)
    t = tt(n)
    return (np.sin(TAU * freq * t) * np.exp(-t * 260.0) + noise(n, rng) * np.exp(-t * 500.0) * 0.4) * 0.7


# ---------------------------------------------------------------- sequencer

class Song:
    """A looping arrangement on a beat grid. Notes may ring past the end; the
    tail is folded back onto the start so the loop has no gap."""

    def __init__(self, bpm, bars, beats=4, tail=3.0):
        self.bpm = bpm
        self.beat = 60.0 / bpm
        self.bars = bars
        self.beats = beats
        self.loop_n = secs(self.beat * beats * bars)
        self.tail_n = secs(tail)
        self.stems = {}

    def stem(self, name):
        if name not in self.stems:
            self.stems[name] = np.zeros((self.loop_n + self.tail_n, 2))
        return self.stems[name]

    def at(self, bar, beat=0.0):
        return bar * self.beats + beat

    def put(self, name, where_beats, mono, p=0.0, gain=1.0):
        buf = self.stem(name)
        i = secs(where_beats * self.beat)
        if i >= self.loop_n or i < 0:
            return
        m = mono[: len(buf) - i]
        buf[i : i + len(m)] += pan(m, p) * gain

    def finish(self, name, lo=None, hi=None, wet=0.0, tau=1.3, seed=7):
        """Fold the tail, band-limit, add reverb. Returns the (loop_n, 2) stem."""
        buf = self.stem(name).copy()
        if lo is not None or hi is not None:
            for ch in range(2):
                buf[:, ch] = fft_filter(buf[:, ch], lo=lo, hi=hi)
        if wet > 0.0:
            buf = buf + reverb(buf, wet, tau, seed)
        out = buf[: self.loop_n].copy()
        tail = buf[self.loop_n :]
        out[: len(tail)] += tail
        return out


# --------------------------------------------------------------------- I/O

def master(layers, ceiling=0.89):
    """Scales a group of layers by one shared gain so that all of them playing
    together peak at `ceiling`, and each is still balanced against the rest."""
    total = sum(layers)
    peak = np.max(np.abs(total))
    gain = ceiling / max(peak, 1e-9)
    return [soft_clip(l * gain, 1.05) for l in layers]


def write_ogg(name, stereo, quality=0.45):
    import soundfile as sf

    path = OUT / f"{name}.ogg"
    data = np.ascontiguousarray(stereo, dtype=np.float32)
    # Written in blocks: libsndfile's Vorbis writer crashes on one huge buffer.
    with sf.SoundFile(str(path), "w", samplerate=SR, channels=2, format="OGG", subtype="VORBIS") as f:
        for i in range(0, len(data), 16384):
            f.write(data[i : i + 16384])
    return path


def write_wav(name, mono, peak=0.85):
    import wave

    mono = np.asarray(mono, dtype=float)
    top = np.max(np.abs(mono))
    if top > 0:
        mono = mono / top * peak
    fade = min(secs(0.004), len(mono) // 4)
    mono[-fade:] *= np.linspace(1.0, 0.0, fade)
    data = (mono * 32767.0).astype("<i2")
    path = OUT / f"sfx_{name}.wav"
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    return path


def report(label, x):
    mono = x.mean(axis=1) if x.ndim == 2 else x
    peak = 20 * np.log10(max(np.max(np.abs(x)), 1e-9))
    rms = 20 * np.log10(max(np.sqrt(np.mean(mono ** 2)), 1e-9))
    seam = abs(float(mono[0]) - float(mono[-1]))
    print(f"  {label:<26} {len(x) / SR:6.1f}s  peak {peak:5.1f} dB  rms {rms:6.1f} dB  seam jump {seam:.4f}")
