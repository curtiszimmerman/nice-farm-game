#!/usr/bin/env python3
"""Rebuild the prototype's original music, wildlife, water, and spell WAV assets.

Uses only Python's standard library. Run after editing a composition or sound;
the native game plays these assets directly, with no synthesis work during play.
"""
import argparse
from array import array
from math import exp, pi, sin, tanh
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
    track = buffer(31)
    random = Random(79)
    for start in [1.1, 4.6, 8.3, 12.8, 17.2, 21.5, 26.9]:
        for chirp in range(random.randint(2, 4)):
            seconds = random.uniform(.08, .17)
            hz = random.uniform(2300, 3300)
            sample = buffer(seconds)
            phase = 0.0
            for i in range(len(sample)):
                t = i / RATE
                phase += TAU * (hz + 520 * sin(pi * t / seconds)) / RATE
                envelope = sin(pi * t / seconds) ** 2
                sample[i] = (sin(phase) + .13 * sin(phase * 2)) * envelope * .18
            add(track, start + chirp * .23, sample, random.uniform(.55, 1))
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


def write(name, samples):
    # Short boundary fades prevent clicks at loop seams without a sustained drone.
    fade = min(round(.02 * RATE), len(samples) // 2)
    for i in range(fade):
        samples[i] *= i / fade
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


def ship():
    track = buffer(16)
    for i in range(len(track)):
        t = i / RATE
        track[i] = (sin(TAU * 55 * t) * .10 + sin(TAU * 110 * t) * .025 + sin(TAU * 82.5 * t) * .018) * (1 + .12 * sin(TAU * .25 * t))
    for start, hz in [(2.1, 880), (2.32, 1100), (7.7, 660), (11.2, 990), (11.5, 740)]:
        tone = buffer(.12)
        for i in range(len(tone)):
            t = i / RATE
            tone[i] = sin(TAU * hz * t) * sin(pi * t / .12) ** 2 * .035
        add(track, start, tone)
    return track


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


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--only", choices=["music", "birds", "crickets", "drips", "wildgrowth", "ship", "crash", "laser", "laser_hit", "explosion"], help="Rebuild one sound instead of all assets.")
    args = parser.parse_args()
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name, build in {"music": music, "birds": birds, "crickets": crickets, "drips": drips, "wildgrowth": wildgrowth, "ship": ship, "crash": crash, "laser": laser, "laser_hit": laser_hit, "explosion": explosion}.items():
        if args.only is None or args.only == name:
            write(name, build())


if __name__ == "__main__":
    main()
