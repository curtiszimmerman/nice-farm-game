#!/usr/bin/env python3
"""Rebuild the prototype's original music, wildlife, water, and spell WAV assets.

Uses only Python's standard library. Run after editing a composition or sound;
the native game plays these assets directly, with no synthesis work during play.
"""
import argparse
from array import array
from math import cos, exp, pi, sin, tanh
from pathlib import Path
from random import Random
import sys
import wave

RATE = 22050
TAU = 2 * pi
OUTPUT = Path(__file__).resolve().parent.parent / "src/native/audio"


def buffer(seconds):
    return array("f", [0.0]) * round(seconds * RATE)


def add(target, start, samples, gain=1.0):
    offset = round(start * RATE)
    for i, value in enumerate(samples):
        if 0 <= offset + i < len(target):
            target[offset + i] += value * gain


def frequency(midi):
    return 440 * 2 ** ((midi - 69) / 12)


def pluck(midi, seconds, gain, bass=False):
    """A soft string-like attack with high harmonics decaying before the body."""
    result = buffer(seconds)
    hz = frequency(midi)
    for i in range(len(result)):
        t = i / RATE
        attack = min(1.0, t / 0.009)
        release = min(1.0, (seconds - t) / 0.065)
        body = sin(TAU * hz * t) * exp(-t * (4.5 if bass else 5.5))
        body += 0.36 * sin(TAU * hz * 2 * t) * exp(-t * 10)
        body += 0.12 * sin(TAU * hz * 3 * t) * exp(-t * 17)
        body += 0.04 * sin(TAU * hz * 4 * t) * exp(-t * 24)
        result[i] = body * attack * release * gain
    return result


def music():
    beat = 60 / 108
    track = buffer(16 * 4 * beat)
    chords = [(48, [60, 64, 67]), (48, [60, 64, 67]),
              (53, [60, 65, 69]), (55, [59, 62, 67]),
              (48, [60, 64, 67]), (45, [60, 64, 69]),
              (53, [60, 65, 69]), (55, [59, 62, 67]),
              (53, [60, 65, 69]), (48, [60, 64, 67]),
              (50, [62, 65, 69]), (55, [59, 62, 67]),
              (48, [60, 64, 67]), (53, [60, 65, 69]),
              (55, [59, 62, 67]), (48, [60, 64, 67])]
    phrases = [
        [(0, 67, .5), (.75, 69, .25), (1, 72, .75), (2, 71, .5), (2.75, 69, .25), (3, 67, .75)],
        [(0, 64, .75), (1, 67, .5), (2, 72, .75), (3.25, 67, .25)],
        [(0, 69, .5), (.75, 72, .25), (1, 74, .75), (2, 72, .5), (3, 69, .75)],
        [(0, 67, .75), (1, 69, .5), (2, 71, .75), (3, 67, .5)],
        [(0, 72, .5), (.75, 76, .25), (1, 74, .5), (2, 72, .75), (3, 67, .5)],
        [(0, 69, .75), (1, 72, .5), (2, 71, .5), (3, 69, .5)],
        [(0, 65, .5), (.75, 69, .25), (1, 72, .75), (2.5, 69, .5)],
        [(0, 67, .5), (1, 71, .5), (2, 74, .5), (3, 71, .5)],
        [(0, 72, .75), (1, 69, .5), (2, 65, .75), (3, 69, .5)],
        [(0, 67, .5), (.75, 64, .25), (1, 60, .75), (2, 64, .5), (3, 67, .5)],
        [(0, 69, .75), (1, 65, .5), (2, 62, .75), (3, 65, .5)],
        [(0, 67, .5), (.75, 69, .25), (1, 71, .75), (2.5, 74, .5)],
        [(0, 76, .5), (1, 74, .5), (2, 72, .75), (3, 67, .5)],
        [(0, 69, .5), (.75, 72, .25), (1, 74, .5), (2, 72, .75), (3, 69, .5)],
        [(0, 71, .5), (1, 69, .5), (2, 67, .5), (3, 62, .5)],
        [(0, 64, .5), (1, 67, .5), (2, 72, 1.0)],
    ]
    for bar, (root, chord) in enumerate(chords):
        start = bar * 4 * beat
        for offset, note in [(0, root), (2, root + 7)]:
            add(track, start + offset * beat, pluck(note, .6, .065, True))
        for offset in [1, 3]:
            for j, note in enumerate(chord):
                add(track, start + offset * beat + j * .018, pluck(note, .45, .026))
        for offset, note, length in phrases[bar]:
            add(track, start + offset * beat, pluck(note, max(.22, length * beat), .17))
    return track


def birds():
    track = buffer(67)
    random = Random(79)
    for start in [3.7, 19.3, 38.6, 55.2]:
        onset = start
        for chirp in range(random.randint(2, 5)):
            seconds = random.uniform(.09, .24)
            hz = random.uniform(2100, 3700)
            bend = random.uniform(-1100, 1400)
            sample = buffer(seconds)
            phase = 0.0
            for i in range(len(sample)):
                t = i / RATE
                phase += TAU * (hz + bend*t/seconds + 170*sin(TAU*27*t)) / RATE
                envelope = sin(pi * t / seconds) ** 2
                sample[i] = (sin(phase) + .06*sin(phase*2) + random.uniform(-.025,.025)) * envelope * .1
            add(track, onset, sample, random.uniform(.35, .7))
            onset += seconds + random.uniform(.06,.28)
    return track


def crickets():
    track = buffer(29)
    random = Random(13)
    for start in [.7, 2.3, 4.9, 7.2, 9.8, 12.0, 14.8, 17.1, 20.4, 23.1, 26.4]:
        for chirp in range(4):
            sample = buffer(.035)
            hz = random.uniform(4100, 4400)
            for i in range(len(sample)):
                t = i / RATE
                sample[i] = sin(TAU * hz * t) * sin(pi * t / .035) ** 2 * .055
            add(track, start + chirp * .065, sample)
    return track


def drips():
    track = buffer(37)
    random = Random(42)
    for start in [1.2, 3.8, 7.2, 9.0, 13.5, 17.6, 20.3, 24.8, 28.0, 32.5]:
        sample = buffer(.25)
        pitch = random.uniform(620, 950)
        for i in range(len(sample)):
            t = i / RATE
            envelope = (1 - exp(-t * 1600)) * exp(-t * 30)
            phase = TAU * (pitch * t + 45 * (1 - exp(-t * 70)))
            sample[i] = (sin(phase) + .16 * sin(phase * 1.48)) * envelope * .23
        add(track, start, sample)
        for delay, gain in [(.19, .4), (.39, .19), (.68, .08)]:
            add(track, start + delay, sample, gain)
    return track


def wildgrowth():
    track = buffer(1.8)
    for i, note in enumerate([72, 76, 79, 84]):
        add(track, .08 + i * .085, pluck(note, .8, .14 - i * .016))
    random = Random(91)
    low = 0.0
    for i in range(round(RATE * .6)):
        t = i / RATE
        noise = random.uniform(-1, 1)
        low += (noise - low) * .12
        track[i] += low * sin(pi * t / .6) ** 2 * .17
    return track


def wreck():
    """Sparse sounds of the damaged ship on the first visit: sputtering sparks, soft console
    chirps and the odd metal tick as the hull cools. Mostly quiet, with no sustained drone."""
    track = buffer(41)
    random = Random(7)
    # Sparks are short bursts of crackling noise, a few pops close together.
    for start in [2.4, 11.8, 19.5, 30.2, 36.6]:
        for pop in range(random.randint(3, 6)):
            burst = buffer(.05)
            for i in range(len(burst)):
                t = i / RATE
                burst[i] = random.uniform(-1, 1) * exp(-t * 90) * .16
            add(track, start + pop * random.uniform(.03, .11), burst)
    # Console chirps are two quiet rising tones, like a system still trying to report in.
    for start, low in [(6.1, 740), (16.4, 880), (25.7, 660), (33.9, 784)]:
        for step, hz in enumerate([low, low * 1.5]):
            tone = buffer(.11)
            for i in range(len(tone)):
                t = i / RATE
                tone[i] = sin(TAU * hz * t) * sin(pi * t / .11) ** 2 * .05
            add(track, start + step * .14, tone)
    # The hull ticks as it cools: a low, damped knock with a short ringing tail.
    for start in [8.9, 22.3, 28.8]:
        knock = buffer(.6)
        pitch = random.uniform(180, 260)
        for i in range(len(knock)):
            t = i / RATE
            knock[i] = (sin(TAU * pitch * t) + .4 * sin(TAU * pitch * 2.7 * t)) * exp(-t * 9) * (1 - exp(-t * 900)) * .09
        add(track, start, knock)
    return track


def write(name, samples, impact=False):
    # Short boundary fades prevent clicks at loop seams without a sustained drone. Impacts keep
    # their opening instead, since the first few milliseconds are what make a hit sound like one.
    fade = min(round(.02 * RATE), len(samples) // 2)
    for i in range(fade):
        if not impact: samples[i] *= i / fade
        samples[-i - 1] *= i / fade
    peak = max(abs(v) for v in samples)
    if peak > .85:
        raise ValueError(f"{name}: peak {peak:.3f} exceeds the mix headroom")
    pcm = array("h", (round(tanh(v) * 32767) for v in samples))
    if sys.byteorder != "little":
        pcm.byteswap()
    with wave.open(str(OUTPUT / f"{name}.wav"), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(pcm.tobytes())
    print(f"{name}: {len(samples)/RATE:.1f}s, peak {peak:.3f}")


def crash():
    track = buffer(3.6)
    random = Random(410)
    low = 0.0
    for i in range(len(track)):
        t = i / RATE
        low += (random.uniform(-1, 1) - low) * .08
        impact = exp(-t * 3) + .55 * exp(-abs(t - .55) * 8) + .3 * exp(-abs(t - 1.2) * 7)
        envelope = min(1, t * 80) * exp(-t * .8)
        track[i] = (low * impact * .8 + sin(TAU * (42 * t - 2 * t * t)) * .22 + sin(TAU * 63 * t) * .12) * envelope
    return track


def laser():
    track = buffer(.23)
    noise = Random(721)
    phase = 0.0
    for i in range(len(track)):
        t = i / RATE
        phase += TAU * (170 + 2100 * exp(-t * 22)) / RATE
        envelope = min(1, t * 600) * exp(-t * 20)
        track[i] = (sin(phase) * .52 + sin(phase * 2.03) * .16 + noise.uniform(-1, 1) * .08) * envelope
    return track


def laser_hit():
    track = buffer(.35)
    noise = Random(722)
    low = 0.0
    for i in range(len(track)):
        t = i / RATE
        low += (noise.uniform(-1, 1) - low) * .24
        track[i] = (low * .55 + sin(TAU * (105 * t - 95 * t * t)) * .45) * min(1, t * 900) * exp(-t * 17)
    return track


def explosion():
    track = buffer(2.1)
    noise = Random(723)
    low = 0.0
    for i in range(len(track)):
        t = i / RATE
        sample = noise.uniform(-1, 1)
        low += (sample - low) * .075
        crack = sample * exp(-t * 13) * .32
        rumble = low * .8 + sin(TAU * (51 * t - 4 * t * t)) * .27
        track[i] = (crack + rumble) * min(1, t * 700) * exp(-t * 2.5)
    return track


def rain():
    track = buffer(12)
    noise = Random(730)
    low = 0.0
    for i in range(len(track)):
        low += (noise.uniform(-1, 1) - low) * .18
        track[i] = low * .3 * (.8 + .12 * sin(TAU * i / RATE / 7))
    return track


def thunder():
    track = buffer(4.8)
    noise = Random(731)
    low = 0.0
    for i in range(len(track)):
        t = i / RATE
        low += (noise.uniform(-1, 1) - low) * .018
        envelope = min(1, t * 4) * exp(-t * .85)
        track[i] = (low * .9 + sin(TAU * (39 * t - t * t)) * .12) * envelope
    return track


# ---------------------------------------------------------------- tool effects
# These are built from shaped noise and short decaying partials, with lots of small random grains
# so they sound like material rather than like an oscillator.

class Biquad:
    """A two-pole filter (the standard audio-cookbook recipe) whose centre can move while it runs."""

    def __init__(self, kind, q):
        self.kind, self.q = kind, q
        self.x1 = self.x2 = self.y1 = self.y2 = 0.0
        self.coefficients = (0.0, 0.0, 0.0, 0.0, 0.0)

    def tune(self, hz):
        w = TAU * min(hz, RATE * .45) / RATE
        alpha, c = sin(w) / (2 * self.q), cos(w)
        if self.kind == "band": b0, b1, b2 = alpha, 0.0, -alpha
        elif self.kind == "low": b0, b1, b2 = (1 - c) / 2, 1 - c, (1 - c) / 2
        else: b0, b1, b2 = (1 + c) / 2, -(1 + c), (1 + c) / 2
        a0 = 1 + alpha
        self.coefficients = (b0 / a0, b1 / a0, b2 / a0, -2 * c / a0, (1 - alpha) / a0)

    def step(self, x):
        b0, b1, b2, a1, a2 = self.coefficients
        y = b0 * x + b1 * self.x1 + b2 * self.x2 - a1 * self.y1 - a2 * self.y2
        self.x2, self.x1, self.y2, self.y1 = self.x1, x, self.y1, y
        return y


def noise(seconds, kind, q, hz, envelope, random, gain=1.0):
    """Filtered white noise. hz and envelope are functions of time in seconds, so the colour and
    loudness can both move; the filter is retuned every 16 samples, which is plenty for sweeps."""
    result = buffer(seconds)
    flt = Biquad(kind, q)
    for i in range(len(result)):
        t = i / RATE
        if i % 16 == 0: flt.tune(hz(t))
        result[i] = flt.step(random.uniform(-1, 1)) * envelope(t) * gain
    return result


def grains(track, count, start, end, kind, q, hz_range, length_range, gain_range, random, fade=0.0):
    """Scatters short noise bursts, like dirt crumbling or stalks snapping. Later grains are
    quieter when fade is set, so the texture dies away naturally."""
    for _ in range(count):
        at = random.uniform(start, end)
        length = random.uniform(*length_range)
        hz = random.uniform(*hz_range)
        level = random.uniform(*gain_range) * exp(-(at - start) * fade)
        add(track, at, noise(length, kind, q, lambda t: hz, lambda t: sin(pi * t / length) ** 2, random, level))


def partials(seconds, tones, glide=0.0):
    """A struck object: (hz, gain, decay) partials, optionally sliding down in pitch by glide."""
    result = buffer(seconds)
    for i in range(len(result)):
        t = i / RATE
        bend = 1 - glide * (1 - exp(-t * 30))
        result[i] = sum(sin(TAU * hz * bend * t) * gain * exp(-t * decay) for hz, gain, decay in tones) * min(1, t * 2000)
    return result


def glide_tone(seconds, start_hz, end_hz, gain, decay):
    """A sine that slides between two pitches, for plops and bubbles."""
    result = buffer(seconds)
    phase = 0.0
    for i in range(len(result)):
        t = i / RATE
        hz = end_hz + (start_hz - end_hz) * exp(-t * 60)
        phase += TAU * hz / RATE
        result[i] = sin(phase) * gain * exp(-t * decay) * min(1, t * 1500)
    return result


def till():
    """A hoe or shovel biting into soil: a dull thump, a scrape, then crumbling dirt."""
    random = Random(311)
    track = buffer(.5)
    add(track, 0, partials(.2, [(92, .45, 26), (1350, .05, 70)], glide=.3))
    add(track, 0, noise(.3, "low", .7, lambda t: 1300, lambda t: min(1, t * 120) * exp(-t * 11), random, .55))
    grains(track, 45, .02, .34, "band", 1.1, (500, 1700), (.006, .02), (.15, .45), random, fade=5)
    return track


def pickaxe_stone():
    """Steel on rock: a sharp clank of inharmonic partials, a thud, then grit falling away."""
    random = Random(523)
    track = buffer(.6)
    add(track, 0, partials(.5, [(1730, .26, 30), (2580, .2, 38), (3910, .13, 46), (5270, .07, 58), (140, .25, 40)]))
    add(track, 0, noise(.02, "high", .8, lambda t: 3000, lambda t: exp(-t * 300), random, .55))
    grains(track, 28, .03, .38, "high", .9, (2400, 5000), (.003, .009), (.06, .2), random, fade=6)
    return track


def sword_hit():
    """A blade landing on a creature: a quick slice, a heavy thud and a wet, gushing squelch."""
    random = Random(907)
    track = buffer(.5)
    add(track, 0, noise(.06, "band", 2.0, lambda t: 3200, lambda t: exp(-t * 70), random, .35))
    add(track, 0, partials(.25, [(140, .4, 16), (210, .15, 22)], glide=.55))
    wet = noise(.42, "low", .9, lambda t: 650 + 400 * exp(-t * 8), lambda t: min(1, t * 200) * exp(-t * 7.5), random, .9)
    wobble = noise(.42, "low", .7, lambda t: 28, lambda t: 1.0, Random(908), 1.0)
    peak = max(abs(v) for v in wobble) or 1
    for i in range(len(wet)):
        wet[i] *= .45 + .55 * abs(wobble[i]) / peak
    add(track, .01, wet)
    for _ in range(5):
        add(track, random.uniform(.05, .3), glide_tone(.04, 260, 520, .1, 40))
    return track


def water_fill():
    """Water running into a jug: a rushing bed, bubbles, and a hollow ring that rises as it fills."""
    random = Random(144)
    track = buffer(1.3)
    shape = lambda t: min(1, t / .06) * min(1, (1.3 - t) / .22)
    add(track, 0, noise(1.3, "low", .7, lambda t: 2400, shape, random, .32))
    add(track, 0, noise(1.3, "band", 6.0, lambda t: 420 + 650 * t / 1.3, shape, random, .55))
    for _ in range(80):
        at = random.uniform(0, 1.15)
        base = 340 + 520 * at / 1.15
        add(track, at, glide_tone(random.uniform(.025, .055), base, base * random.uniform(1.4, 1.9), random.uniform(.06, .13), 45))
    return track


def water_pour():
    """A watering can over plants: a soft spray, patter on leaves and little splashes in the soil."""
    random = Random(266)
    track = buffer(1.1)
    shape = lambda t: min(1, t / .15) * min(1, (1.1 - t) / .3)
    add(track, 0, noise(1.1, "band", .8, lambda t: 4300, shape, random, .32))
    add(track, 0, noise(1.1, "high", .7, lambda t: 2200, shape, random, .12))
    for _ in range(55):
        add(track, random.uniform(.06, .95), partials(.02, [(random.uniform(1800, 3200), random.uniform(.05, .11), 140)]))
    grains(track, 25, .08, .95, "low", .8, (700, 1100), (.012, .03), (.05, .12), random)
    return track


def scythe():
    """A blade sweeping through grain: a rising swish with a burst of stalks snapping in the middle."""
    random = Random(388)
    track = buffer(.5)
    sweep = lambda t: 1200 + 2600 * min(1, t / .18) - 1800 * max(0, t - .18) / .14
    add(track, 0, noise(.34, "band", 1.3, sweep, lambda t: sin(pi * min(1, t / .32)) ** 2, random, .5))
    grains(track, 32, .08, .26, "high", .8, (3200, 6000), (.002, .005), (.2, .45), random)
    grains(track, 18, .2, .45, "band", .7, (4200, 5800), (.01, .03), (.04, .09), random, fade=6)
    return track


def cast():
    """Casting a line: the ratchet of the reel, the line whistling out, then a plop and splash."""
    random = Random(455)
    track = buffer(1.0)
    for k in range(6):
        add(track, k * .022, partials(.012, [(random.uniform(3500, 4200), .12, 260)]))
    add(track, .1, noise(.48, "band", 8.0, lambda t: 4200 - 2400 * min(1, t / .45), lambda t: sin(pi * min(1, t / .45)) ** 2, random, .55))
    add(track, .6, glide_tone(.12, 1100, 280, .32, 22))
    add(track, .6, noise(.32, "low", .8, lambda t: 1800, lambda t: min(1, t * 400) * exp(-t * 13), random, .45))
    for _ in range(4):
        add(track, random.uniform(.68, .85), glide_tone(.04, 380, 650, .07, 40))
    return track


def chop():
    """An axe biting into a trunk: a hard knock with a hollow, woody body and a little splintering."""
    random = Random(677)
    track = buffer(.5)
    add(track, 0, noise(.015, "band", 1.5, lambda t: 2200, lambda t: exp(-t * 200), random, .45))
    add(track, 0, partials(.4, [(190, .32, 22), (410, .18, 30), (780, .1, 45), (1230, .05, 60), (82, .22, 30)], glide=.08))
    grains(track, 8, .01, .08, "high", .9, (2500, 4500), (.004, .012), (.08, .18), random)
    return track


def whoosh():
    """A swing through empty air: a rush of breath that rises and falls with the swing."""
    random = Random(799)
    track = buffer(.36)
    swing = lambda t: sin(pi * min(1, t / .32)) ** 2
    add(track, 0, noise(.34, "band", 1.4, lambda t: 600 + 1600 * sin(pi * min(1, t / .3)), swing, random, .55))
    add(track, 0, noise(.34, "low", .7, lambda t: 420, swing, random, .25))
    return track

def bridge_electrical():
    """Soft filtered hiss with irregular, short electrical sputters."""
    track = buffer(12)
    noise = Random(862)
    low = 0.0
    for i in range(len(track)):
        low += (noise.uniform(-1, 1) - low) * .12
        track[i] = low * .12
    for _ in range(24):
        duration = noise.uniform(.04, .21)
        burst = buffer(duration)
        low = 0.0
        for i in range(len(burst)):
            t = i / RATE
            low += (noise.uniform(-1, 1) - low) * .28
            burst[i] = low * sin(pi * t / duration) ** 2 * .32
        add(track, noise.uniform(.1, 11.7), burst)
    return track


def bridge_klaxon():
    """A low rounded warning tone, breathing in two gentle warbling pulses."""
    track = buffer(4.5)
    for i in range(len(track)):
        t = i / RATE
        pulse = (.5 - .5 * cos(TAU * t / 2.25)) ** 2
        phase = TAU * 150 * t + 6 * (1 - cos(TAU * t / 2.25))
        track[i] = pulse * (.21 * sin(phase) + .025 * sin(2 * phase))
    return track


def decloak():
    """A low descending electrical snap with a short unstable rumble."""
    track = buffer(.75)
    noise = Random(863)
    low = 0.0
    for i in range(len(track)):
        t = i / RATE
        low += (noise.uniform(-1, 1) - low) * .22
        phase = TAU * (60 * t + 25 * (1 - exp(-8 * t)))
        envelope = min(1, t / .008) * exp(-t * 5) * min(1, (.75 - t) / .08)
        track[i] = (.38 * sin(phase) + .12 * sin(phase * 1.47) + .28 * low) * envelope
    return track


SOUNDS = {"music": music, "birds": birds, "crickets": crickets, "drips": drips, "wildgrowth": wildgrowth, "wreck": wreck,
          "crash": crash, "laser": laser, "laser_hit": laser_hit, "explosion": explosion, "rain": rain, "thunder": thunder,
          "bridge_electrical": bridge_electrical, "bridge_klaxon": bridge_klaxon, "decloak": decloak,
          "till": till, "pickaxe_stone": pickaxe_stone, "sword_hit": sword_hit, "water_fill": water_fill,
          "water_pour": water_pour, "scythe": scythe, "cast": cast, "chop": chop, "whoosh": whoosh}
IMPACTS = {"till", "pickaxe_stone", "sword_hit", "chop"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--only", choices=list(SOUNDS), help="Rebuild one sound instead of all assets.")
    args = parser.parse_args()
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name, build in SOUNDS.items():
        if args.only is None or args.only == name:
            write(name, build(), impact=name in IMPACTS)


if __name__ == "__main__":
    main()
