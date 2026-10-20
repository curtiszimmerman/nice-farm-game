#!/usr/bin/env python3
"""Build the rustic16 art pack: a native 16-pixel-per-cell sprite atlas.

Uses only the standard library. Every sprite is painted here pixel by pixel at
half of option2's native size; the engine scales this pack by two with
nearest-neighbour sampling, so the 32-world-pixel gameplay grid is unchanged.
Outputs: src/native/art/option3/{sprites.png,sprites.json,pack.json}.
"""
import argparse
import json
import math
import pathlib
import random
import re
import struct
import zlib

ROOT = pathlib.Path(__file__).resolve().parents[1]
DEST = ROOT / "src/native/art/option3"
ASSETS = {}
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

# Shared ramps, darkest first. Shadows lean violet, highlights lean warm cream.
INK = "2a1d22"
WOOD = ["3a2418", "5a3824", "7c5131", "a06c41", "c38d58", "e0b67c"]
GRASS = ["263f2b", "345a31", "48783a", "62953f", "84b04a", "b2cb68"]
STONE = ["2b2a33", "44424b", "615d62", "817b78", "a59d91", "cbc2ad"]
CAVE = ["17161e", "24232d", "34323d", "47434f", "5e5865", "7b737f"]
DIRT = ["38231a", "573826", "7a5034", "9b6b44", "bb8c5c", "d6ad7a"]
ROCK = ["2b231f", "43372f", "5e4e42", "7b6857", "9a8470", "bba58a"]
WATER = ["1d3448", "285468", "3a7886", "5ea2a6", "a3d4c9", "e4f4e6"]
METAL = ["1f2830", "33424c", "4d5f69", "6e8188", "98a8a8", "cfd8cf"]
LEAF_OAK = ["1f3526", "2f4f2c", "426f33", "5f9139", "86b046", "b5cf62"]
LEAF_BIRCH = ["2a4128", "3f6233", "5c873c", "7fa845", "a8c556", "d4e07a"]
LEAF_PINE = ["14282a", "1d3b35", "2a5242", "3c6c4f", "5a8b5c", "86ad73"]
SHADOW = (38, 24, 40)


def rgba(value):
    if isinstance(value, tuple):
        return value if len(value) == 4 else tuple(value) + (255,)
    value = value.lstrip("#")
    return tuple(bytes.fromhex(value)) + ((255,) if len(value) == 6 else ())


def mix(a, b, t):
    a, b = rgba(a), rgba(b)
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3)) + (a[3],)


def shade(color, k):
    """One hue-shifted ramp step per unit: darker toward violet, lighter toward cream."""
    if k < 0:
        return mix(color, (46, 28, 56, 255), min(1, -k * 0.22))
    return mix(color, (255, 242, 198, 255), min(1, k * 0.2))


def fade(color, a):
    return rgba(color)[:3] + (a,)


def hash01(x, y, seed=0):
    n = (x * 374761393 + y * 668265263 + seed * 2246822519 + 1013904223) & 0xFFFFFFFF
    n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((n ^ (n >> 16)) & 0xFFFF) / 65535


def vnoise(x, y, seed=0):
    xi, yi = math.floor(x), math.floor(y)
    xf, yf = x - xi, y - yi
    u, v = xf * xf * (3 - 2 * xf), yf * yf * (3 - 2 * yf)
    a, b = hash01(xi, yi, seed), hash01(xi + 1, yi, seed)
    c, d = hash01(xi, yi + 1, seed), hash01(xi + 1, yi + 1, seed)
    return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v


def dither(x, y):
    return (BAYER[y % 4][x % 4] + 0.5) / 16


class Pixels:
    def __init__(self, width, height):
        self.w, self.h = width, height
        self.data = bytearray(width * height * 4)

    def get(self, x, y):
        x, y = int(x), int(y)
        if 0 <= x < self.w and 0 <= y < self.h:
            o = (y * self.w + x) * 4
            return tuple(self.data[o:o + 4])
        return (0, 0, 0, 0)

    def solid(self, x, y):
        return self.get(x, y)[3] == 255

    def dot(self, x, y, color):
        x, y = int(x), int(y)
        if not (0 <= x < self.w and 0 <= y < self.h):
            return
        c, o = rgba(color), (y * self.w + x) * 4
        if c[3] == 255 or self.data[o + 3] == 0:
            self.data[o:o + 4] = bytes(c)
        elif c[3] > 0:
            t = c[3] / 255
            for i in range(3):
                self.data[o + i] = int(round(self.data[o + i] + (c[i] - self.data[o + i]) * t))
            self.data[o + 3] = max(self.data[o + 3], c[3])

    def under(self, x, y, color):
        """Paint only on empty pixels, so shadows tuck beneath what is already drawn."""
        if self.get(x, y)[3] == 0:
            self.dot(x, y, color)

    def clear(self, x, y):
        x, y = int(x), int(y)
        if 0 <= x < self.w and 0 <= y < self.h:
            o = (y * self.w + x) * 4
            self.data[o:o + 4] = b"\0\0\0\0"

    def box(self, x, y, w, h, color):
        for yy in range(int(y), int(y + h)):
            for xx in range(int(x), int(x + w)):
                self.dot(xx, yy, color)

    def hline(self, x0, x1, y, color):
        for x in range(int(x0), int(x1) + 1):
            self.dot(x, y, color)

    def vline(self, x, y0, y1, color):
        for y in range(int(y0), int(y1) + 1):
            self.dot(x, y, color)

    def oval(self, cx, cy, rx, ry, color):
        rx, ry = max(rx, 0.5), max(ry, 0.5)
        for yy in range(math.floor(cy - ry), math.ceil(cy + ry) + 1):
            for xx in range(math.floor(cx - rx), math.ceil(cx + rx) + 1):
                if ((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2 <= 1.0:
                    self.dot(xx, yy, color)

    def polygon(self, points, color):
        for y in range(min(p[1] for p in points), max(p[1] for p in points) + 1):
            edges = []
            for a, b in zip(points, points[1:] + points[:1]):
                if min(a[1], b[1]) <= y < max(a[1], b[1]):
                    edges.append(a[0] + (y - a[1]) * (b[0] - a[0]) / (b[1] - a[1]))
            edges.sort()
            for left, right in zip(edges[::2], edges[1::2]):
                self.hline(math.ceil(left), math.floor(right), y, color)

    def line(self, x0, y0, x1, y1, color):
        steps = max(abs(x1 - x0), abs(y1 - y0), 1)
        for i in range(steps + 1):
            self.dot(round(x0 + (x1 - x0) * i / steps), round(y0 + (y1 - y0) * i / steps), color)

    def outline(self, color=None, k=-3.0, diagonal=False):
        """Selective outline: empty pixels touching opaque ones take a darkened neighbour colour."""
        marks = []
        near = [(1, 0), (-1, 0), (0, 1), (0, -1)] + ([(1, 1), (-1, 1), (1, -1), (-1, -1)] if diagonal else [])
        for y in range(self.h):
            for x in range(self.w):
                if self.get(x, y)[3] != 0:
                    continue
                for dx, dy in near:
                    n = self.get(x + dx, y + dy)
                    if n[3] == 255:
                        marks.append((x, y, color if color else shade(n, k)))
                        break
        for x, y, c in marks:
            self.dot(x, y, c)

    def flipped(self):
        out = Pixels(self.w, self.h)
        for y in range(self.h):
            for x in range(self.w):
                o, m = (y * self.w + x) * 4, (y * self.w + self.w - 1 - x) * 4
                out.data[m:m + 4] = self.data[o:o + 4]
        return out

    def stamp(self, other, x, y):
        for yy in range(other.h):
            for xx in range(other.w):
                c = other.get(xx, yy)
                if c[3]:
                    self.dot(x + xx, y + yy, c)

    def copy(self, other, x, y):
        for yy in range(other.h):
            start = ((y + yy) * self.w + x) * 4
            self.data[start:start + other.w * 4] = other.data[yy * other.w * 4:(yy + 1) * other.w * 4]

    def png(self, path):
        def chunk(kind, payload):
            return struct.pack(">I", len(payload)) + kind + payload + struct.pack(">I", zlib.crc32(kind + payload))
        rows = b"".join(b"\0" + bytes(self.data[y * self.w * 4:(y + 1) * self.w * 4]) for y in range(self.h))
        header = struct.pack(">IIBBBBB", self.w, self.h, 8, 6, 0, 0, 0)
        path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header) + chunk(b"IDAT", zlib.compress(rows, 9)) + chunk(b"IEND", b""))


def add(name, image, **metadata):
    ASSETS[name] = (image, metadata)
    return image


def tile(name):
    return add("tile_" + name, Pixels(16, 16))


def contact_shadow(p, x0, x1, y, rows=2, strength=120):
    """Shadow hugging a base: row y is the object's own bottom row, so it can never float free."""
    for i in range(rows):
        inset = i * 2
        for x in range(x0 + inset, x1 - inset + 1):
            p.under(x, y + i, SHADOW + (max(30, strength - i * 45),))


def ramp_fill(p, x, y, w, h, ramp, top, light_left=True):
    """Fill a box with a vertical ramp index 'top', lit top-left edge and shaded bottom-right edge."""
    p.box(x, y, w, h, ramp[top])
    p.hline(x, x + w - 1, y, ramp[min(len(ramp) - 1, top + 1)])
    if light_left:
        p.vline(x, y, y + h - 1, ramp[min(len(ramp) - 1, top + 1)])
    p.vline(x + w - 1, y + 1, y + h - 1, ramp[max(0, top - 1)])
    p.hline(x + 1, x + w - 1, y + h - 1, ramp[max(0, top - 1)])


def grass_tile(p, variant, seed=0):
    """Seamless meadow: one base, speckled clusters, and blade tufts wrapped across edges."""
    p.box(0, 0, 16, 16, GRASS[3])
    for y in range(16):
        for x in range(16):
            n = hash01(x, y, 40 + seed)
            if n > 0.9:
                p.dot(x, y, GRASS[4])
            elif n < 0.1:
                p.dot(x, y, GRASS[2])
    rng = random.Random(100 + variant + seed * 7)
    for _ in range(4 + variant % 2):
        x, y = rng.randrange(16), rng.randrange(2, 16)
        for dx, dy, c in [(-1, 1, 1), (0, 1, 1), (1, 1, 1), (2, 1, 1), (-1, 0, 2), (0, -1, 4), (0, 0, 3), (1, 0, 2), (2, -1, 5), (2, 0, 4)]:
            p.dot((x + dx) % 16, (y + dy) % 16, GRASS[c])
    if variant == 2:
        for x, y, petal in [(4, 5, "f3ead0"), (11, 11, "f2c96a")]:
            for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                p.dot(x + dx, y + dy, petal)
            p.dot(x, y, "e08a4a")
            p.dot(x, y + 2, GRASS[1])
    if variant == 3:
        p.box(9, 6, 2, 1, STONE[4]); p.dot(11, 6, STONE[3]); p.hline(9, 11, 7, STONE[1])
        for x, y in [(3, 12), (4, 11), (5, 12)]:
            p.dot(x, y, GRASS[5])
        p.dot(4, 12, GRASS[2])


def terrain():
    for i in range(4):
        grass_tile(tile("grass" + str(i)), i)

        p = tile("wood" + str(i))
        for k, y0 in enumerate(range(0, 16, 4)):
            tone = [WOOD[3], mix(WOOD[3], WOOD[4], 0.35), mix(WOOD[3], WOOD[2], 0.3)][int(hash01(k, i, 3) * 3)]
            p.box(0, y0, 16, 3, tone)
            p.hline(0, 15, y0 + 3, WOOD[1])
            for x in range(16):
                if hash01(x, y0, i) > 0.72:
                    p.dot(x, y0, shade(tone, 0.8))
                if hash01(x, y0 + 1, i + 9) > 0.85:
                    p.hline(x, x + 1, y0 + 1 + (x % 2), shade(tone, -0.8))
            joint = (i * 5 + k * 7 + 3) % 16
            p.vline(joint, y0, y0 + 2, WOOD[1])
            p.dot((joint + 1) % 16, y0, shade(tone, 1.2))
            p.dot((joint + 2) % 16, y0 + 1, WOOD[2])

        p = tile("cave" + str(i))
        p.box(0, 0, 16, 16, CAVE[2])
        for y in range(16):
            for x in range(16):
                n = hash01(x, y, 70 + i)
                if n > 0.88:
                    p.dot(x, y, CAVE[3])
                elif n < 0.08:
                    p.dot(x, y, CAVE[1])
        rng = random.Random(80 + i)
        x, y = rng.randrange(16), rng.randrange(16)
        for _ in range(6):
            p.dot(x % 16, y % 16, CAVE[0])
            x, y = x + 1, y + rng.choice((-1, 0, 0, 1))
        for _ in range(2):
            x, y = rng.randrange(1, 14), rng.randrange(1, 14)
            p.hline(x, x + 1, y, CAVE[4]); p.dot(x, y, CAVE[5]); p.hline(x, x + 1, y + 1, CAVE[0])

        p = tile("paving" + str(i))
        pave = ["3c3a3c", "5c5652", "857c71", "a49a89", "c3b8a1", "ddd2b8"]
        p.box(0, 0, 16, 16, pave[1])
        rng = random.Random(90 + i)
        for y0, h in [(0, 5), (5, 5), (10, 6)]:
            x = rng.randrange(16)
            remaining = 16
            while remaining > 0:
                w = min(remaining, rng.choice((4, 5, 6)))
                tone = pave[3] if rng.random() > 0.3 else mix(pave[3], "b09a7e", 0.5)
                for yy in range(y0 + 1, y0 + h):
                    for xx in range(x + 1, x + w):
                        corner = (xx in (x + 1, x + w - 1)) and (yy in (y0 + 1, y0 + h - 1))
                        if corner:
                            continue
                        c = tone
                        if yy == y0 + 1 or xx == x + 1:
                            c = pave[4]
                        if yy == y0 + h - 1 or xx == x + w - 1:
                            c = pave[2]
                        p.dot(xx % 16, yy, c)
                p.dot((x + 2) % 16, y0 + 1, pave[5])
                x, remaining = x + w, remaining - w

        p = tile("trail")
        p.box(0, 0, 16, 16, DIRT[4])
        for y in range(16):
            for x in range(16):
                n = hash01(x, y, 120)
                if n > 0.86:
                    p.dot(x, y, DIRT[5])
                elif n < 0.14:
                    p.dot(x, y, DIRT[3])
        for x, y in [(3, 4), (11, 9), (6, 13)]:
            p.dot(x, y, STONE[4]); p.dot(x + 1, y, STONE[3]); p.hline(x, x + 1, y + 1, DIRT[2])

    p = tile("bath")
    for ty in (0, 8):
        for tx in (0, 8):
            body = "cfe0d6" if (tx + ty) % 16 == 0 else "e6e4cf"
            p.box(tx, ty, 8, 8, body)
            p.hline(tx, tx + 7, ty, "9eaea7"); p.vline(tx, ty, ty + 7, "9eaea7")
            p.hline(tx + 1, tx + 6, ty + 1, shade(body, 1.5)); p.vline(tx + 7, ty + 2, ty + 7, shade(body, -0.6))
            p.hline(tx + 2, tx + 7, ty + 7, shade(body, -0.6)); p.dot(tx + 2, ty + 2, "ffffff")

    p = tile("metal")
    p.box(0, 0, 16, 16, METAL[2])
    p.hline(0, 15, 0, METAL[4]); p.vline(0, 0, 15, METAL[3]); p.hline(0, 15, 15, METAL[0]); p.vline(15, 0, 15, METAL[1])
    for y in range(2, 14, 3):
        for x in range(2 + (y // 3) % 2 * 2, 14, 4):
            p.dot(x, y, METAL[3]); p.dot(x + 1, y + 1, METAL[1])
    for x, y in [(2, 2), (13, 2), (2, 13), (13, 13)]:
        p.dot(x, y, METAL[5]); p.dot(x + 1, y, METAL[1]); p.dot(x, y + 1, METAL[1])

    p = tile("metal_wall")
    p.box(0, 0, 16, 16, METAL[1])
    p.box(1, 2, 14, 11, METAL[2])
    p.hline(0, 15, 0, METAL[5]); p.hline(0, 15, 1, METAL[3])
    p.hline(0, 15, 13, METAL[1]); p.box(0, 14, 16, 2, METAL[0])
    p.vline(1, 3, 12, METAL[3]); p.vline(14, 3, 12, METAL[1])
    for x in (2, 13):
        p.dot(x, 3, METAL[5]); p.dot(x, 11, METAL[4])
    for y in (8, 10): p.hline(5, 10, y, METAL[0])

    p = tile("wall")
    paper, paper_dark = "b9a07e", "9c8264"
    p.box(0, 0, 16, 16, paper)
    for x in range(0, 16, 4):
        p.vline(x, 2, 10, paper_dark); p.vline(x + 1, 2, 10, shade(paper, 0.7))
    for x, y in [(2, 5), (10, 8), (6, 3)]:
        p.dot(x + 1, y, "8a5f4e"); p.dot(x + 1, y + 1, "6f7d55")
    p.box(0, 0, 16, 2, WOOD[2]); p.hline(0, 15, 0, WOOD[4])
    p.box(0, 11, 16, 1, WOOD[4]); p.box(0, 12, 16, 3, WOOD[3])
    for x in range(1, 16, 4):
        p.vline(x, 12, 14, WOOD[2])
    p.hline(0, 15, 15, WOOD[1]); p.hline(0, 15, 10, shade(paper, -1.2))

    p = tile("void")
    p.box(0, 0, 16, 16, "1b2022")
    for y in range(16):
        for x in range(16):
            if hash01(x, y, 7) > 0.93:
                p.dot(x, y, "232b2c")

    for mask in range(16):
        cliff_tile(tile("cliff" + str(mask)), mask)

    p = tile("jetty")
    p.box(0, 0, 16, 16, "1e2a2c")
    for k, x0 in enumerate(range(0, 16, 4)):
        tone = [WOOD[3], mix(WOOD[3], WOOD[4], 0.3), mix(WOOD[3], WOOD[2], 0.25), WOOD[3]][k]
        p.box(x0, 0, 3, 16, tone)
        p.vline(x0, 0, 15, shade(tone, 1.0))
        p.vline(x0 + 2, 0, 15, shade(tone, -0.7))
        joint = (k * 6 + 5) % 14 + 1
        p.hline(x0, x0 + 2, joint, WOOD[1]); p.hline(x0, x0 + 2, joint + 1, shade(tone, 1.2))
        for y in (2, 13):
            p.dot(x0 + 1, y, METAL[1])
        p.dot(x0 + 1, (joint + 7) % 16, WOOD[2])


def cliff_tile(p, mask):
    """Raised rock shelf; open sides get lit (left/up) or shaded (right) rims, an open bottom a columnar face."""
    p.box(0, 0, 16, 16, ROCK[3])
    for y in range(16):
        for x in range(16):
            n, m = hash01(x, y, 300), vnoise(x / 3, y / 3, 301)
            if m > 0.7 and n > 0.35:
                p.dot(x, y, GRASS[2] if n > 0.7 else GRASS[1])
            elif n > 0.9 or m < 0.25 and n > 0.6:
                p.dot(x, y, ROCK[4])
            elif n < 0.08:
                p.dot(x, y, ROCK[2])
    for x, y in [(3, 4), (11, 10)]:
        p.dot(x, y, GRASS[4]); p.dot(x + 1, y - 1, GRASS[3]); p.dot(x - 1, y, GRASS[2])
    p.hline(8, 9, 6, ROCK[5]); p.hline(8, 10, 7, ROCK[2])
    face = 7
    if mask & 4:
        p.hline(0, 15, 0, ROCK[5]); p.hline(0, 15, 1, ROCK[4])
        for x in range(16):
            if hash01(x, 0, 303) > 0.55: p.dot(x, 1, GRASS[3])
    if mask & 8:
        x = 0
        k = 0
        while x < 16:
            w = 3 + int(hash01(k, mask, 306) * 3)
            brk = face + 3 + int(hash01(k, 1, 307) * 5)
            for xx in range(x, min(16, x + w)):
                for y in range(face, 16):
                    c = ROCK[2]
                    if xx == x: c = ROCK[3]
                    if xx == x + w - 1: c = ROCK[1]
                    tilt = brk + (xx - x) // 2
                    if y == tilt and xx < x + w - 1 - (k % 2): c = ROCK[0]
                    if y == tilt + 1 and x < xx < x + w - 1: c = ROCK[3]
                    if hash01(xx, y, 310) > 0.85: c = shade(c, 0.6)
                    elif hash01(xx, y, 311) < 0.1: c = shade(c, -0.6)
                    if y >= 14: c = shade(c, -0.8)
                    p.dot(xx, y, c)
            if hash01(k, 2, 308) > 0.5 and x + 1 < 16:
                p.dot(x + 1, face + 1, ROCK[4])
            x += w
            k += 1
        p.hline(0, 15, face - 1, ROCK[5])
        for x in range(16):
            if hash01(x, 5, 309) > 0.6:
                p.dot(x, face, GRASS[2]); p.dot(x, face + 1, GRASS[1]) if hash01(x, 6, 309) > 0.5 else None
        p.hline(0, 15, 15, ROCK[0])
    top_end = face - 1 if mask & 8 else 15
    if mask & 1:
        p.vline(0, 0, top_end, ROCK[5]); p.vline(1, 0, top_end, ROCK[4])
        if mask & 8: p.vline(0, face, 15, ROCK[3])
    if mask & 2:
        p.vline(15, 0, top_end, ROCK[0]); p.vline(14, 0, top_end, ROCK[2])
        if mask & 8: p.vline(15, face, 15, ROCK[0])


ROOF = ["3b1e1f", "5c2c28", "82402f", "a7573a", "c8774a", "e39f68"]
PLASTER = ["5e4a3c", "8d7559", "b8a07c", "d6c39b", "e9dcb6", "f6eed2"]
LOGS = ["3a2318", "5b3622", "7d4f2e", "9d6a3d", "bd8a52", "d9ab70"]
SHOP = ["23383a", "33544f", "467266", "5f907c", "86b096", "b8d3b0"]
FENCE = ["3d2a1f", "64452e", "8c6440", "b08552", "cfa76c", "e8c88e"]


def wall_material(p, variant):
    if variant == "plaster":
        p.box(0, 0, 16, 16, PLASTER[3])
        for y in range(16):
            for x in range(16):
                n = vnoise(x / 3, y / 3, 11)
                if n > 0.72 and dither(x, y) < 0.5:
                    p.dot(x, y, PLASTER[4])
                elif n < 0.25 and dither(x, y) < 0.4:
                    p.dot(x, y, PLASTER[2])
        p.line(11, 4, 13, 7, PLASTER[1]); p.dot(12, 4, PLASTER[2])
        p.hline(0, 15, 0, PLASTER[1])
    elif variant == "log":
        for k, y0 in enumerate(range(0, 16, 4)):
            p.hline(0, 15, y0, LOGS[4]); p.box(0, y0 + 1, 16, 2, LOGS[3]); p.hline(0, 15, y0 + 3, LOGS[1])
            for x in range(16):
                if hash01(x, y0, 12 + k) > 0.8:
                    p.dot(x, y0 + 2, LOGS[2])
            knot = (k * 7 + 3) % 13 + 1
            p.dot(knot, y0 + 1, LOGS[1]); p.dot(knot + 1, y0 + 1, LOGS[2])
            p.dot(knot, y0 + 2, LOGS[5] if k % 2 else LOGS[2])
    elif variant == "stone":
        p.box(0, 0, 16, 16, STONE[1])
        for y0, h, off in [(0, 4, 0), (4, 5, 3), (9, 3, 6), (12, 4, 1)]:
            x = -off
            while x < 16:
                w = 4 + int(hash01(x, y0, 13) * 4)
                tone = STONE[3] if hash01(x, y0, 14) > 0.35 else mix(STONE[3], ROCK[4], 0.5)
                for yy in range(y0, y0 + h - 1):
                    for xx in range(x, x + w - 1):
                        if 0 <= xx < 16:
                            c = tone
                            if yy == y0 or xx == x:
                                c = STONE[4]
                            if yy == y0 + h - 2 or xx == x + w - 2:
                                c = STONE[2]
                            p.dot(xx, yy, c)
                if 0 <= x + 1 < 16:
                    p.dot(x + 1, y0, STONE[5])
                x += w
    else:
        p.box(0, 0, 16, 16, SHOP[3])
        for y0 in range(0, 16, 3):
            p.hline(0, 15, y0, SHOP[4]); p.hline(0, 15, y0 + 2, SHOP[2])
            for x in range(16):
                if hash01(x, y0, 15) > 0.86:
                    p.dot(x, y0 + 1, SHOP[4])
        p.hline(0, 15, 15, SHOP[1])


def trim_colors(variant):
    return {"plaster": (WOOD[1], WOOD[3]), "log": (LOGS[0], LOGS[2]), "stone": (STONE[0], STONE[2]), "shop": ("d7cba6", "efe6c6")}[variant]


def building_tile(p, variant, kind):
    wall_material(p, variant)
    dark, light = trim_colors(variant)
    if kind in ("left", "right"):
        x = 0 if kind == "left" else 13
        if variant == "log":
            for y0 in range(0, 16, 4):
                p.box(x, y0, 3, 4, LOGS[3]); p.dot(x + 1, y0 + 1, LOGS[5]); p.dot(x + 1, y0 + 2, LOGS[2])
                p.hline(x, x + 2, y0 + 3, LOGS[1]); p.vline(x + (2 if kind == "left" else 0), y0, y0 + 3, LOGS[1])
        elif variant == "stone":
            for y0 in range(0, 16, 4):
                w = 3 if (y0 // 4) % 2 else 4
                xx = 0 if kind == "left" else 16 - w
                p.box(xx, y0, w, 4, STONE[4]); p.hline(xx, xx + w - 1, y0 + 3, STONE[1]); p.dot(xx + 1, y0 + 1, STONE[5])
        else:
            p.box(x, 0, 3, 16, light); p.vline(x + 2 if kind == "left" else x, 0, 15, dark)
            p.vline(x + 1 if kind == "left" else x + 1, 0, 15, shade(light, 0.8) if variant == "shop" else WOOD[4])
    if kind == "foundation":
        p.hline(0, 15, 6, shade(rgba(p.get(4, 5)), -1.5))
        for y0, off in [(7, 0), (11, 2)]:
            x = -off
            while x < 16:
                w = 4 + int(hash01(x, y0, 21) * 3)
                for yy in range(y0, y0 + 4):
                    for xx in range(x, x + w):
                        if 0 <= xx < 16:
                            c = ROCK[3]
                            if yy == y0: c = ROCK[4]
                            if yy == y0 + 3 or xx == x + w - 1: c = ROCK[1]
                            p.dot(xx, yy, c)
                if 0 <= x + 1 < 16: p.dot(x + 1, y0 + 1, ROCK[5])
                x += w
        for x in range(16):
            if hash01(x, 15, 22) > 0.6:
                p.dot(x, 14, GRASS[3]); p.dot(x, 15, GRASS[2])
    if kind == "window":
        p.box(2, 2, 12, 11, dark)
        p.box(3, 3, 10, 9, light)
        p.box(4, 4, 8, 7, WATER[1])
        for y in range(4, 11):
            for x in range(4, 12):
                if x + y < 12: p.dot(x, y, WATER[2])
        p.line(5, 5, 6, 4, WATER[4]); p.dot(5, 6, WATER[3])
        p.vline(7, 4, 10, light); p.hline(4, 11, 7, light)
        p.vline(8, 4, 10, shade(light, -1.2))
        p.box(1, 12, 14, 2, light); p.hline(1, 14, 12, shade(light, 1.2)); p.hline(1, 14, 13, dark)
        for x in (2, 5, 9, 12):
            p.dot(x, 11, LEAF_OAK[3]); p.dot(x + 1, 11, ["e0717a", "f2c96a", "f3ead0", "d98ad0"][x % 4])
        p.hline(2, 13, 14, shade(rgba(p.get(2, 15)), -1.2))
    if kind in ("door", "door_top", "door_bottom"):
        door = WOOD[3] if variant != "shop" else "9a5a3c"
        top = 1 if kind == "door" else 0
        p.box(2, top, 12, 16 - top, dark)
        if kind in ("door", "door_top"):
            p.box(2, top, 12, 2, light); p.hline(2, 13, top, shade(light, 1))
        p.box(4, top + (2 if kind != "door_bottom" else 0), 8, 16, door)
        for x in (4, 6, 8, 10):
            p.vline(x + 1, 0, 15, shade(door, -1.4))
            p.vline(x, 0, 15, shade(door, 0.5))
        if kind in ("door", "door_top"):
            p.box(5, top + 4, 6, 4, WATER[1]); p.hline(5, 10, top + 4, dark)
            p.dot(6, top + 5, WATER[4]); p.dot(7, top + 5, WATER[3]); p.vline(8, top + 4, top + 7, dark)
        if kind in ("door", "door_bottom"):
            y = 9 if kind == "door" else 4
            p.hline(4, 11, y, shade(door, -2)); p.hline(4, 11, y - 1, shade(door, 0.8))
            hy = 10 if kind == "door" else 3
            p.dot(10, hy, "f2d27a"); p.dot(10, hy + 1, "a37a32")
            p.box(2, 15, 12, 1, STONE[3]); p.hline(3, 12, 15, STONE[4])
        if kind == "door_top":
            p.box(4, 2, 8, 1, shade(door, -1.6))
            p.box(5, 9, 6, 6, WATER[1]); p.vline(8, 9, 14, dark); p.hline(5, 10, 12, dark)
            p.dot(5, 9, WATER[4]); p.dot(6, 10, WATER[3])


def roof_tile(p, kind):
    for y in range(16):
        for x in range(16):
            if kind == "roof_left" and x < 15 - y: continue
            if kind == "roof_right" and x > y: continue
            row, ry = y // 4, y % 4
            off = 2 if row % 2 else 0
            col = (x + off) % 4
            c = ROOF[3]
            if ry == 0: c = ROOF[4]
            if ry == 3: c = ROOF[1]
            if ry == 2 and col == 0: c = ROOF[2]
            if col == 3 and ry < 3: c = ROOF[2]
            if ry == 1 and col == 0: c = ROOF[5] if hash01(x, y, 5) > 0.5 else ROOF[4]
            if hash01(x // 4 + off, row, 31) > 0.82 and ry in (1, 2) and col in (1, 2): c = mix(c, "8a6b4a", 0.45)
            p.dot(x, y, c)
    if kind == "roof_left":
        for y in range(16):
            x = 15 - y
            p.dot(x, y, WOOD[4]); p.dot(x + 1, y, WOOD[2])
    if kind == "roof_right":
        for y in range(16):
            p.dot(y, y, WOOD[4]); p.dot(y - 1, y, WOOD[2])
    if kind == "ridge":
        p.box(0, 0, 16, 3, ROOF[4])
        for x in range(0, 16, 4):
            p.hline(x, x + 2, 0, ROOF[5]); p.vline(x + 3, 0, 2, ROOF[2])
        p.hline(0, 15, 3, ROOF[0]); p.hline(0, 15, 4, ROOF[1])


def chimney(p):
    brick = ["3a1f1d", "6a3528", "8f4a34", "ad6243", "c98159", "e5a87a"]
    p.box(4, 2, 8, 14, brick[2])
    for y in range(3, 16, 3):
        p.hline(4, 11, y + 2, brick[1])
        off = 0 if (y // 3) % 2 else 2
        for x in range(4 + off, 12, 4):
            p.vline(x, y, y + 1, brick[1]); p.dot(x + 1, y, brick[4])
    p.vline(4, 2, 15, brick[3]); p.vline(11, 2, 15, brick[1])
    p.box(3, 1, 10, 2, STONE[4]); p.hline(3, 12, 1, STONE[5]); p.hline(3, 12, 2, STONE[2])
    p.box(5, 0, 6, 1, CAVE[0]); p.dot(6, 0, CAVE[2])


def fence_post(p, x, top, bottom):
    p.box(x, top + 1, 3, bottom - top, FENCE[3])
    p.hline(x, x + 2, top + 1, FENCE[4]); p.dot(x + 1, top, FENCE[5]); p.dot(x, top + 1, FENCE[5])
    p.vline(x, top + 2, bottom, FENCE[4]); p.vline(x + 2, top + 1, bottom, FENCE[1])
    p.dot(x + 1, top + 4, FENCE[2]); p.dot(x + 1, bottom - 2, FENCE[2])


def rail_h(p, x0, x1, y):
    p.hline(x0, x1, y, FENCE[4]); p.hline(x0, x1, y + 1, FENCE[2])
    for x in range(x0, x1 + 1):
        if hash01(x, y, 9) > 0.8: p.dot(x, y, FENCE[3])


def rail_v(p, y0, y1):
    """North-south rail fixed to the post's lit face, so it reads beside the post."""
    p.vline(9, y0, y1, FENCE[4]); p.vline(10, y0, y1, FENCE[2])
    for y in range(y0, y1 + 1):
        if hash01(9, y, 4) > 0.8: p.dot(9, y, FENCE[3])


def fences():
    p = tile("fence")
    for y in (6, 10): rail_h(p, 0, 15, y)
    for x in (1, 7, 12): fence_post(p, x, 3, 14)
    for x in (1, 7, 12): contact_shadow(p, x - 1, x + 3, 15, 1)
    for mask in range(16):
        p = tile(f"fence_mask{mask}")
        for y in (6, 10):
            if mask & 1: rail_h(p, 0, 7, y)
            if mask & 2: rail_h(p, 8, 15, y)
        fence_post(p, 6, 3, 14)
        if mask & 4: rail_v(p, 0, 9)
        if mask & 8: rail_v(p, 5, 15)
        if mask & 12: p.dot(9, 6, METAL[3]); p.dot(9, 10, METAL[3])
        contact_shadow(p, 5, 9, 15, 1)
        if mask & 8: contact_shadow(p, 9, 10, 15, 1)
    p = tile("gate_h_open")
    for y in (6, 10): rail_h(p, 0, 1, y); rail_h(p, 14, 15, y)
    fence_post(p, 1, 2, 14); fence_post(p, 12, 2, 14)
    for i, x in enumerate(range(4, 9)):
        top, bottom = 4 + i, 12 + i
        p.vline(x, top, bottom, FENCE[4] if i % 2 == 0 else FENCE[2])
        p.dot(x, top, FENCE[5] if i % 2 == 0 else FENCE[3])
    p.line(4, 6, 8, 10, FENCE[1]); p.line(4, 10, 8, 14, FENCE[1])
    p.dot(4, 6, METAL[4]); p.dot(4, 10, METAL[4])
    for x0 in (1, 12): contact_shadow(p, x0 - 1, x0 + 3, 15, 1)
    p.dot(8, 15, SHADOW + (120,)); p.dot(7, 15, SHADOW + (80,))
    p = tile("gate_v_open")
    rail_v(p, 0, 2); fence_post(p, 6, -1, 3)
    fence_post(p, 6, 8, 14); rail_v(p, 12, 15)
    for x in range(10, 16, 2):
        p.vline(x, 6, 13, FENCE[4]); p.dot(x, 5, FENCE[5])
        p.vline(x + 1, 7, 13, FENCE[2])
    for y in (7, 11): p.hline(9, 15, y, FENCE[3])
    p.line(10, 12, 15, 7, FENCE[1]); p.dot(9, 9, METAL[4]); p.dot(9, 12, METAL[4])
    contact_shadow(p, 5, 15, 14, 1); contact_shadow(p, 5, 9, 15, 1)


def towers_and_arches():
    stone = ["3e4048", "5a5b62", "767676", "93918a", "b0ab9d", "cdc6b1"]
    for right in (False, True):
        p = tile("tower_right" if right else "tower_left")
        for x in range(16):
            gx = x + (16 if right else 0)
            if gx < 3 or gx > 28: continue
            t = (gx - 3) / 25
            idx = 4 if t < 0.2 else 3 if t < 0.45 else 2 if t < 0.7 else 1 if t < 0.9 else 0
            for y in range(16):
                c = stone[idx]
                course = (y + (2 if (gx // 6) % 2 else 0)) % 5
                if y % 5 == 4: c = stone[max(0, idx - 1)]
                if (gx + (3 if (y // 5) % 2 else 0)) % 6 == 0 and y % 5 != 4: c = stone[max(0, idx - 1)]
                if course == 0 and hash01(gx, y, 3) > 0.5: c = stone[min(5, idx + 1)]
                p.dot(x, y, c)
        edge = 3 if not right else 12
        p.vline(edge, 0, 15, stone[5] if not right else stone[0])
    for right in (False, True):
        p = tile("cave_arch_right" if right else "cave_arch_left")
        p.box(0, 0, 16, 16, ROCK[3])
        for y in range(16):
            for x in range(16):
                n = hash01(x + (16 if right else 0), y, 44)
                if n > 0.86: p.dot(x, y, ROCK[4])
                elif n < 0.14: p.dot(x, y, ROCK[2])
        for y in range(16):
            for x in range(16):
                gx = x + (16 if right else 0)
                d = math.hypot(gx - 15.5, y - 16)
                if d < 12: p.dot(x, y, mix(CAVE[0], CAVE[2], max(0, (y - 6) / 18)))
                elif d < 13: p.dot(x, y, ROCK[1])
                elif d < 14.2: p.dot(x, y, ROCK[5] if gx < 16 else ROCK[4])
        for gx, y in [(4, 3), (24, 6), (10, 2)]:
            x = gx - (16 if right else 0)
            if 0 <= x < 15: p.hline(x, x + 1, y, ROCK[1]); p.dot(x, y - 1, ROCK[5])


def small_fixtures():
    p = tile("flowerbed")
    p.box(1, 9, 14, 5, DIRT[1])
    for x in range(1, 15):
        if hash01(x, 9, 2) > 0.5: p.dot(x, 9, DIRT[2])
    p.box(0, 12, 16, 3, WOOD[3]); p.hline(0, 15, 12, WOOD[4]); p.hline(0, 15, 14, WOOD[1])
    for x in (0, 5, 10, 15): p.vline(x, 12, 14, WOOD[2])
    blooms = [(3, 5, "e86a6a", "f6b1a6"), (8, 3, "f2c96a", "fff0a8"), (12, 6, "b98ad8", "e1c6f2")]
    for x, y, c, hi in blooms:
        p.vline(x, y + 2, 10, LEAF_OAK[2])
        p.dot(x - 1, y + 4, LEAF_OAK[4]); p.dot(x + 1, y + 5, LEAF_OAK[3]); p.dot(x - 2, y + 5, LEAF_OAK[2])
        for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]: p.dot(x + dx, y + dy, c)
        p.dot(x - 1, y - 1, hi); p.dot(x, y, "f6e3a0")
    for x in (5, 10, 14):
        p.dot(x, 8, LEAF_OAK[3]); p.dot(x, 7, LEAF_OAK[4])
    contact_shadow(p, 0, 15, 15, 1)
    p = tile("light")
    p.box(6, 0, 4, 2, METAL[1]); p.hline(5, 10, 2, METAL[2])
    p.box(5, 3, 6, 7, "f5d98c"); p.box(6, 4, 4, 5, "fff3c4")
    p.vline(5, 3, 9, METAL[1]); p.vline(10, 3, 9, METAL[0]); p.vline(7, 3, 9, "e2b65e")
    p.hline(4, 11, 10, METAL[1]); p.hline(5, 10, 11, METAL[0]); p.dot(7, 12, METAL[2])
    p.dot(6, 4, "ffffff")


def buildings():
    for variant in ("plaster", "log", "stone", "shop"):
        for kind in ("wall", "left", "right", "foundation", "window", "door", "door_top", "door_bottom"):
            building_tile(tile(variant + "_" + kind), variant, kind)
    for kind in ("roof", "roof_left", "roof_right", "ridge"):
        roof_tile(tile(kind), kind)
    chimney(tile("chimney"))
    small_fixtures()
    fences()
    towers_and_arches()


BARK = ["2a1a16", "432a1f", "5e3d29", "7b5434", "9a6e45", "b88b5c"]
BIRCH_BARK = ["2b2a2c", "6d6a66", "b5afa2", "d8d2c2", "efe9d8", "fbf8ee"]


def foliage_blob(p, cx, cy, r, ramp, seed, rough=1.2):
    """One leafy cluster lit from the upper left: bright cap, mid body, dark under-rim, ragged leaf tips."""
    for y in range(math.floor(cy - r - 2), math.ceil(cy + r + 2)):
        for x in range(math.floor(cx - r - 2), math.ceil(cx + r + 2)):
            dx, dy = x - cx, (y - cy) * 1.08
            d = math.hypot(dx, dy)
            edge = r + (vnoise(x / 1.6, y / 1.6, seed) - 0.5) * 2 * rough
            if d > edge:
                continue
            light = (dx * -0.55 + dy * -0.83) / max(r, 1)
            rim = d / max(edge, 1)
            v = 3.0 + light * 1.7 + (dither(x, y) - 0.5) * 0.45
            if rim > 0.8 and light < 0.1: v = min(v, 1.6)
            elif rim > 0.86: v -= 0.6
            p.dot(x, y, ramp[max(1, min(5, int(v)))])


def leaf_texture(p, x0, y0, x1, y1, ramp, seed, count):
    """Small leaf flecks: a lit tip over a shaded underside, only inside mid-tone foliage."""
    rng = random.Random(seed)
    tones = [rgba(c) for c in ramp]
    for _ in range(count):
        x, y = rng.randrange(x0, x1), rng.randrange(y0, y1)
        here = p.get(x, y)
        if here[3] != 255 or p.get(x, y + 1)[3] != 255:
            continue
        idx = tones.index(here) if here in tones else -1
        if idx in (2, 3):
            p.dot(x, y, ramp[idx + 1]); p.dot(x + 1, y, ramp[idx + 1]) if rng.random() < 0.5 else None
            if p.get(x, y + 1) in tones: p.dot(x, y + 1, ramp[idx - 1])
        elif idx == 4 and rng.random() < 0.4:
            p.dot(x, y, ramp[5])


def trunk(p, cx, top, base, width, ramp, birch=False):
    x0 = cx - width // 2
    for y in range(top, base + 1):
        flare = max(0, y - (base - 3))
        for x in range(x0 - flare, x0 + width + flare):
            t = (x - (x0 - flare)) / max(1, width + 2 * flare - 1)
            idx = 4 if t < 0.25 else 3 if t < 0.6 else 2 if t < 0.85 else 1
            if birch:
                idx = 4 if t < 0.3 else 3 if t < 0.7 else 2
            p.dot(x, y, ramp[idx])
        if not birch and hash01(cx, y, 7) > 0.55:
            xx = x0 + 1 + int(hash01(y, cx, 8) * (width - 2))
            p.dot(xx, y, ramp[1])
            p.dot(xx, y + 1, ramp[2])
        if birch and hash01(cx, y, 9) > 0.62:
            xx = x0 + int(hash01(y, cx, 10) * (width - 2))
            p.hline(xx, xx + 1 + int(hash01(y, 3, 11) * 2), y, ramp[0])
    for dx in (-width // 2 - 3, width // 2 + 2):
        p.dot(cx + dx, base, ramp[2]); p.dot(cx + dx + (1 if dx < 0 else -1), base - 1, ramp[3])
    p.hline(cx - width // 2 - 3, cx + width // 2 + 2, base, ramp[1])


def tree(species, rows):
    w, h = 48, rows * 16 + 32
    p = add(f"tree_{species}_{rows}", Pixels(w, h), trunk_tiles=[1, 2], canopy_tiles=[3, rows])
    seed = rows * 31 + len(species) * 7
    base = h - 3
    canopy_bottom = rows * 16 + 8
    if species == "pine":
        trunk(p, 24, canopy_bottom - 10, base, 6, BARK)
        ramp = LEAF_PINE
        tiers = rows + 1
        step = (canopy_bottom - 6) / tiers
        for i in reversed(range(tiers)):
            t = (i + 1) / tiers
            top = 1 + int(step * i * 0.85)
            bottom = min(canopy_bottom, int(6 + step * (i + 1)))
            half = 6 + t * 16
            for y in range(top, bottom + 1):
                k = (y - top) / max(1, bottom - top)
                span = half * (0.15 + 0.85 * k ** 0.9)
                for x in range(int(24 - span) - 1, int(24 + span) + 2):
                    dx = x - 24
                    if abs(dx) > span: continue
                    if y == bottom and hash01(x, y, seed) > 0.55: continue
                    side = dx / max(1, span)
                    v = 3.6 - side * 1.4 - k * 0.5 + (dither(x, y) - 0.5) * 0.5
                    droop = bottom - 1 - (1 if (x // 3) % 2 else 0)
                    if y >= droop: v = 1.2
                    p.dot(x, y, ramp[max(1, min(5, int(v)))])
            for j in range(int(half)):
                x = int(24 - half * 0.8 + j * 1.5)
                y = bottom - 2 - int(hash01(j, i, seed) * 4)
                if p.get(x, y)[3] == 255 and x < 26:
                    p.dot(x, y, ramp[5]); p.dot(x + 1, y + 1, ramp[2])
        p.dot(24, 0, ramp[4]); p.dot(24, 1, ramp[5])
    else:
        birch = species == "birch"
        trunk(p, 24, canopy_bottom - 12, base, 6 if birch else 8, BIRCH_BARK if birch else BARK, birch)
        branch = BIRCH_BARK[1] if birch else BARK[2]
        p.line(23, canopy_bottom - 4, 16, canopy_bottom - 10, branch)
        p.line(26, canopy_bottom - 3, 33, canopy_bottom - 9, branch)
        ramp = LEAF_BIRCH if birch else LEAF_OAK
        rng = random.Random(seed)
        ch = canopy_bottom - 2
        ry = ch / 2 - (4 if birch else 3)
        rx = 17 if birch else 19
        cy0 = ch / 2 + 1
        blobs = []
        count = 7 + rows * (3 if birch else 2)
        for i in range(count):
            a = i * math.tau / count + rng.uniform(-0.2, 0.2)
            f = rng.uniform(0.45, 0.75)
            blobs.append((24 + math.cos(a) * rx * f, cy0 + math.sin(a) * ry * f, rng.uniform(5, 7) if birch else rng.uniform(7, 9.5)))
        blobs.append((24, cy0 - 1, ry * 0.65))
        blobs.append((24, cy0 + ry * 0.35, rx * 0.7))
        for i, (cx, cy, r) in enumerate(sorted(blobs, key=lambda b: b[1])):
            foliage_blob(p, cx, cy, r, ramp, seed + i, 1.4 if birch else 1.1)
        leaf_texture(p, 3, 2, 45, ch + 2, ramp, seed, rows * (60 if birch else 45))
        if birch:
            for _ in range(rows * 3):
                x, y = rng.randrange(12, 36), rng.randrange(6, ch - 6)
                if p.get(x, y)[3] == 255:
                    p.dot(x, y, LEAF_BIRCH[0]); p.dot(x + 1, y, LEAF_BIRCH[1])
            p.dot(17, canopy_bottom - 9, BIRCH_BARK[3])
        elif rows >= 3:
            for x, y in [(15, ch // 2), (31, ch // 3), (27, ch - 9)]:
                if p.get(x, y)[3] == 255:
                    p.dot(x, y, "c94a3b"); p.dot(x, y - 1, "f08a6a")
    p.outline(k=-2.6)
    contact_shadow(p, 24 - 8, 24 + 7, base + 1, 2, 130)


def bushes():
    looks = [(LEAF_OAK, None), (LEAF_OAK, ("b8303a", "f07a6e")), (LEAF_BIRCH, ("f2c94a", "fff2a6")), (LEAF_PINE, ("e9e3d0", "ffffff"))]
    for variant, (ramp, berry) in enumerate(looks):
        p = add("bush" + str(variant), Pixels(32, 24))
        rng = random.Random(500 + variant)
        blobs = [(9, 15, 6.5), (23, 15, 6.5), (16, 10, 7.5), (12, 16, 6), (20, 17, 6)]
        for i, (cx, cy, r) in enumerate(blobs):
            foliage_blob(p, cx + rng.uniform(-0.6, 0.6), cy + rng.uniform(-0.5, 0.5), r, ramp, 600 + variant * 9 + i)
        for x in range(3, 29):
            for y in range(19, 24):
                if p.get(x, y)[3] == 255 and y >= 20:
                    p.dot(x, y, ramp[1])
        leaf_texture(p, 3, 3, 29, 20, ramp, 700 + variant, 40)
        if berry:
            for _ in range(7):
                x, y = rng.randrange(5, 27), rng.randrange(5, 18)
                if p.get(x, y)[3] == 255 and p.get(x + 1, y + 1)[3] == 255:
                    p.dot(x, y, berry[0]); p.dot(x + 1, y, berry[0]); p.dot(x, y - 1, berry[1]) if variant != 1 else p.dot(x, y, berry[1])
                    p.dot(x + 1, y + 1, ramp[0])
        p.outline(k=-2.6)
        bottom = max(y for y in range(24) for x in range(32) if p.get(x, y)[3] == 255)
        contact_shadow(p, 4, 27, bottom + 1, 2, 120)


def vegetation():
    for species in ("oak", "birch", "pine"):
        for rows in (2, 3, 4):
            tree(species, rows)
    bushes()


LINEN = ["5b5248", "8a8070", "b2a891", "d2c9b0", "e9e1ca", "faf5e6"]
QUILT = ["4a2026", "73302f", "9c4538", "c4664a", "e08f62", "f3bb8a"]
SAGE = ["24382f", "35503f", "4c6c52", "688b67", "8fae80", "bed3a6"]
TEAL = ["1b2f36", "234652", "2f6470", "418a8f", "6db6b0", "b2e3d3"]
BOOKS = ["8e3a33", "3f6a5c", "c48a3a", "4c5a86", "7a4a6a", "a8a45c", "b65d3f", "e2d7b7"]
JARS = ["c46b4a", "e0b04e", "7fa35a", "b65d7d", "d9d2b8", "6d8fb3"]


def slab(p, x, y, w, h, ramp, grain=True, seed=0):
    """Lit top surface: light back edge, shaded right edge, planks along its width."""
    p.box(x, y, w, h, ramp[3])
    if grain:
        for yy in range(y + 2, y + h - 1, 3):
            for xx in range(x, x + w):
                if hash01(xx, yy, seed) > 0.25: p.dot(xx, yy, ramp[2] if hash01(xx, yy, seed + 1) > 0.5 else mix(ramp[2], ramp[3], 0.5))
        for yy in range(y + 1, y + h - 1):
            for xx in range(x + 1, x + w - 1):
                if hash01(xx, yy, seed + 2) > 0.93: p.hline(xx, xx + 1, yy, ramp[4])
    p.hline(x, x + w - 1, y, ramp[4]); p.vline(x, y, y + h - 1, ramp[4])
    p.vline(x + w - 1, y + 1, y + h - 1, ramp[2])


def face(p, x, y, w, h, ramp, lip=True):
    """Front face beneath a slab: lit lip, mid body, dark foot."""
    p.box(x, y, w, h, ramp[2])
    if lip: p.hline(x, x + w - 1, y, ramp[5])
    if h > 2: p.hline(x, x + w - 1, y + h - 1, ramp[1])
    p.vline(x + w - 1, y + 1, y + h - 1, ramp[1])
    if h > 1: p.vline(x, y + 1, y + h - 2, ramp[3])


def under_shadow(p, x0, x1, y0, y1, a=80):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            p.under(x, y, SHADOW + (a,))


def finish(p, x0, x1, base, rows=2):
    p.outline(k=-2.8)
    contact_shadow(p, x0, x1, base + 2, rows, 115)


def pot_plant(p, cx, base, big=False):
    pot = ["4a2418", "7a3b24", "a8553a", "c97452", "e09a72", "f2c09a"]
    pw = 6 if big else 4
    p.box(cx - pw // 2, base - (5 if big else 3), pw, 5 if big else 3, pot[3])
    p.hline(cx - pw // 2 - 1, cx + pw // 2, base - (5 if big else 3), pot[4])
    p.vline(cx + pw // 2 - 1, base - (4 if big else 2), base - 1, pot[1])
    leaves = [(-4, -9, 3), (3, -10, 3), (0, -13, 3), (-2, -6, 2), (4, -6, 2)] if big else [(-1, -5, 2), (1, -6, 2)]
    for dx, dy, r in leaves:
        foliage_blob(p, cx + dx, base + dy, r, LEAF_OAK, cx + dx * 7 + dy)


def plant_sprig(p, x, y):
    p.dot(x, y, LEAF_OAK[4]); p.dot(x - 1, y + 1, LEAF_OAK[3]); p.dot(x + 1, y + 1, LEAF_OAK[2]); p.dot(x, y + 1, LEAF_OAK[1])


def goods_row(p, x0, x1, y, seed, kind):
    """A shelf's worth of goods sitting on a board at row y (their bottom)."""
    x = x0
    rng = random.Random(seed)
    while x < x1:
        if kind == "books":
            bw, bh = rng.choice((1, 2, 2)), rng.randrange(4, 7)
            if x + bw > x1: break
            c = rng.choice(BOOKS)
            if rng.random() < 0.12 and x + bh <= x1:
                p.box(x, y - 2, bh, 2, c); p.hline(x, x + bh - 1, y - 2, shade(c, 1.2)); x += bh + 1; continue
            p.box(x, y - bh, bw, bh, c); p.dot(x, y - bh, shade(c, 1.5)); p.dot(x, y - bh + 2, shade(c, 2.5))
            if bw == 2: p.vline(x + 1, y - bh + 1, y - 1, shade(c, -1))
            x += bw
        elif kind == "jars":
            c = rng.choice(JARS)
            if x + 3 > x1: break
            p.box(x, y - 4, 3, 4, "c9d8cf"); p.box(x, y - 3, 3, 3, c); p.dot(x, y - 3, shade(c, 1.6))
            p.hline(x, x + 2, y - 5, WOOD[2]); p.vline(x + 2, y - 3, y - 1, shade(c, -1.2))
            x += 4
        elif kind == "sacks":
            if x + 4 > x1: break
            p.box(x, y - 4, 4, 4, LINEN[3]); p.hline(x + 1, x + 2, y - 5, LINEN[2]); p.dot(x, y - 4, LINEN[4])
            p.vline(x + 3, y - 3, y - 1, LINEN[1]); p.hline(x + 1, x + 2, y - 2, rng.choice(("7fa35a", "c46b4a", "6d8fb3")))
            x += 5
        else:
            if x + 4 > x1: break
            c = rng.choice(("c46b4a", "e0b04e", "7fa35a", "e9e1ca"))
            p.box(x, y - 3, 4, 3, WOOD[2]); p.hline(x, x + 3, y - 3, WOOD[4])
            p.dot(x + 1, y - 4, c); p.dot(x + 2, y - 4, shade(c, 1)); p.dot(x + 1, y - 3, c)
            x += 5


def storage(p, kind, x0, w, d, yb):
    top_y, top_h = 3, d - 13
    face_y = top_y + top_h
    ramp = WOOD if kind != "cabinet" else ["3a2a22", "5c4032", "7f5a43", "a07656", "c49a72", "e2c398"]
    slab(p, x0, top_y, w, top_h, ramp, True, w + d)
    if top_h > 6:
        for y in range(top_y + 6, face_y - 1, 7):
            p.hline(x0 + 1, x0 + w - 2, y, ramp[1])
            goods_row(p, x0 + 2, x0 + w - 2, y, y * 3 + w, "books" if kind == "bookshelf" else "jars" if kind == "stock" else "sacks")
    else:
        for x in range(x0 + 2, x0 + w - 3, 11):
            if hash01(x, w, 5) > 0.4:
                p.box(x, top_y - 2, 3, 3, JARS[x % 6]); p.dot(x, top_y - 2, shade(JARS[x % 6], 1.5))
    face(p, x0, face_y, w, yb - face_y + 1, ramp)
    inner = ramp[1]
    if kind == "cabinet":
        for x in range(x0 + 1, x0 + w - 1, 8):
            dw = min(7, x0 + w - 1 - x)
            p.box(x, face_y + 2, dw, yb - face_y - 3, ramp[3]); p.hline(x, x + dw - 1, face_y + 2, ramp[4])
            p.box(x + 1, face_y + 4, dw - 2, yb - face_y - 7, ramp[2]); p.vline(x + dw - 1, face_y + 2, yb - 2, ramp[1])
            p.dot(x + dw - 2 if (x // 8) % 2 else x + 1, face_y + 10, "e8c873")
        return
    shelves = list(range(face_y + 2, yb - 2, 7))
    for sy in shelves:
        bottom = min(sy + 6, yb - 2)
        p.box(x0 + 1, sy, w - 2, bottom - sy, inner)
        p.hline(x0 + 1, x0 + w - 2, sy, ramp[0])
        goods_row(p, x0 + 2, x0 + w - 2, bottom, sy * 7 + w, {"bookshelf": "books", "stock": "jars", "seed_tray": "sacks"}.get(kind, "crates"))
        p.hline(x0 + 1, x0 + w - 2, bottom, ramp[4]); p.hline(x0 + 1, x0 + w - 2, bottom + 1, ramp[2])


def crates(p, x0, w, d, yb):
    def crate(x, y, cw, ch, depth):
        slab(p, x, y, cw, depth, WOOD, False)
        p.hline(x + 1, x + cw - 2, y + depth // 2, WOOD[2])
        face(p, x, y + depth, cw, ch, WOOD)
        for yy in (y + depth + 2, y + depth + ch - 3):
            p.hline(x + 1, x + cw - 2, yy, WOOD[4]); p.hline(x + 1, x + cw - 2, yy + 1, WOOD[1])
        p.line(x + 1, y + depth + ch - 2, x + cw - 2, y + depth + 2, WOOD[3])
        p.vline(x + 1, y + depth + 1, y + depth + ch - 2, WOOD[1]); p.vline(x + cw - 2, y + depth + 1, y + depth + ch - 2, WOOD[1])
    crate(x0, yb - 21, 15, 10, 12)
    crate(x0 + 16, yb - 23, 16, 12, 12)
    crate(x0 + 5, yb - 33, 14, 9, 8)
    p.box(x0 + 23, yb - 26, 6, 4, LINEN[3]); p.hline(x0 + 23, x0 + 28, yb - 26, LINEN[4]); p.hline(x0 + 24, x0 + 27, yb - 27, LINEN[2])


def table_like(p, kind, x0, w, d, yb, wd):
    leg = yb - 5
    top_y = 12 - (6 if kind != "chair" else 0) + (2 if kind == "chair" else 0)
    top_h = max(5, leg - 3 - top_y)
    if kind == "chair":
        top_y, top_h = 18, 6
        p.box(x0 + 3, 4, w - 6, 15, wd[2])
        p.hline(x0 + 3, x0 + w - 4, 4, wd[4]); p.hline(x0 + 3, x0 + w - 4, 5, wd[3])
        for x in range(x0 + 5, x0 + w - 4, 3): p.vline(x, 7, 17, wd[1]); p.vline(x + 1, 7, 17, wd[3])
        p.vline(x0 + 3, 4, 18, wd[4]); p.vline(x0 + w - 4, 4, 18, wd[1])
    for lx in sorted({x0 + 1, x0 + w - 3} | ({x0 + w // 2 - 1} if w >= 64 else set())):
        p.box(lx, top_y + top_h + 2, 2, yb - top_y - top_h - 1, wd[2]); p.vline(lx, top_y + top_h + 2, yb, wd[3])
    if d > 16:
        for lx in (x0 + 3, x0 + w - 5):
            p.box(lx, top_y + top_h + 1, 2, yb - top_y - top_h - 3, wd[1])
    slab(p, x0, top_y, w, top_h, wd, True, w * 3 + d)
    if kind == "desk":
        dx = x0 + w - 13
        face(p, x0, top_y + top_h, w, 3, wd)
        face(p, dx, top_y + top_h, 12, yb - top_y - top_h + 1, wd)
        for yy in range(top_y + top_h + 3, yb - 1, 4):
            p.hline(dx + 1, dx + 10, yy, wd[1]); p.dot(dx + 6, yy + 2, "e8c873")
        p.box(x0 + 4, top_y + 2, 8, 5, LINEN[4]); p.hline(x0 + 5, x0 + 10, top_y + 4, LINEN[2]); p.hline(x0 + 5, x0 + 9, top_y + 5, LINEN[2])
        p.box(x0 + 14, top_y + 1, 2, 3, "2b2a33"); p.line(x0 + 16, top_y - 2, x0 + 15, top_y + 1, "e9e1ca")
        if w >= 48:
            p.box(x0 + 22, top_y + 1, 7, 4, BOOKS[0]); p.hline(x0 + 22, x0 + 28, top_y + 4, LINEN[4])
            p.box(x0 + 23, top_y - 2, 6, 3, BOOKS[3]); p.hline(x0 + 23, x0 + 28, top_y - 2, shade(BOOKS[3], 1.3))
        if w >= 32:
            p.box(x0 + w - 8, top_y - 3, 3, 5, "e8c873"); p.dot(x0 + w - 7, top_y - 4, "fff3c4"); p.hline(x0 + w - 9, x0 + w - 5, top_y + 2, METAL[2])
    elif kind == "counter":
        face(p, x0, top_y + top_h, w, yb - top_y - top_h + 1, wd)
        for x in range(x0 + 2, x0 + w - 5, 16):
            p.box(x, top_y + top_h + 3, 12, yb - top_y - top_h - 5, wd[3]); p.hline(x, x + 11, top_y + top_h + 3, wd[1])
            p.vline(x + 11, top_y + top_h + 3, yb - 3, wd[4])
        p.hline(x0, x0 + w - 1, yb - 1, wd[0])
        p.box(x0 + 5, top_y - 2, 8, 5, METAL[3]); p.hline(x0 + 5, x0 + 12, top_y - 2, METAL[4]); p.box(x0 + 7, top_y - 1, 3, 1, "e8c873")
        goods_row(p, x0 + 28, x0 + w - 6, top_y + 4, 77, "jars")
    else:
        face(p, x0, top_y + top_h, w, 3, wd)
        under_shadow(p, x0 + 1, x0 + w - 2, top_y + top_h + 3, yb, 70)
        if kind == "table":
            cx = x0 + w // 2
            if w == 16 and d == 16:
                p.box(cx - 2, top_y - 1, 4, 4, "c9d8cf"); p.dot(cx - 2, top_y - 1, "f4fbf6"); plant_sprig(p, cx - 1, top_y - 4); plant_sprig(p, cx + 1, top_y - 3)
            if d > 16:
                p.box(x0 + 4, top_y + 1, w - 8, top_h - 2, LINEN[4]); p.hline(x0 + 4, x0 + w - 5, top_y + top_h - 2, LINEN[2])
                for x in range(x0 + 4, x0 + w - 5, 4): p.dot(x, top_y + top_h - 1, LINEN[3])
            for i, px in enumerate(range(x0 + 6, x0 + w - 6, 14)):
                if w == 16: break
                py = top_y + (top_h // 2) - 1
                p.oval(px + 2, py, 3, 1.6, "eef3ea"); p.oval(px + 2, py, 1.6, 0.8, ["e0b04e", "c46b4a", "7fa35a"][i % 3])
                p.dot(px + 6, py - 1, "e2c398"); p.dot(px + 6, py - 2, "b8794a")
    if kind == "chair":
        face(p, x0 + 1, top_y + top_h, w - 2, 2, wd)


def bed(p, x0, w, d, yb):
    head_top = 4
    p.box(x0, head_top, w, 10, WOOD[2]); p.hline(x0, x0 + w - 1, head_top, WOOD[4])
    for x in range(x0 + 3, x0 + w - 3, 3): p.vline(x, head_top + 3, head_top + 8, WOOD[1])
    for px in (x0, x0 + w - 2):
        p.box(px, head_top - 2, 2, 14, WOOD[3]); p.dot(px, head_top - 2, WOOD[5])
    p.box(x0 + 1, 13, w - 2, yb - 16, LINEN[4])
    for i in range(max(1, w // 16)):
        px = x0 + 2 + i * ((w - 4) // max(1, w // 16))
        pw = (w - 4) // max(1, w // 16) - 1
        p.box(px, 14, pw, 7, LINEN[5]); p.hline(px, px + pw - 1, 20, LINEN[2]); p.vline(px + pw - 1, 15, 20, LINEN[3])
        p.dot(px, 14, LINEN[3]); p.dot(px + pw - 1, 14, LINEN[3])
    qy = 26
    p.box(x0 + 1, qy, w - 2, yb - qy - 3, QUILT[3])
    p.hline(x0 + 1, x0 + w - 2, qy, LINEN[5]); p.hline(x0 + 1, x0 + w - 2, qy + 1, LINEN[3])
    for y in range(qy + 2, yb - 3):
        for x in range(x0 + 1, x0 + w - 1):
            cell = ((x - x0 - 1) // 5 + (y - qy - 2) // 5) % 2
            c = QUILT[3] if cell else "e2c48c"
            if (x - x0 - 1) % 5 == 4 or (y - qy - 2) % 5 == 4: c = QUILT[2] if cell else "b99666"
            p.dot(x, y, c)
    p.vline(x0 + 1, qy + 2, yb - 4, QUILT[4]); p.vline(x0 + w - 2, qy + 2, yb - 4, QUILT[1])
    face(p, x0, yb - 3, w, 4, WOOD)
    for px in (x0, x0 + w - 2): p.box(px, yb - 5, 2, 6, WOOD[3]); p.dot(px, yb - 5, WOOD[5])


def sofa(p, x0, w, d, yb):
    p.box(x0 + 2, 4, w - 4, 10, SAGE[3]); p.hline(x0 + 3, x0 + w - 4, 4, SAGE[5]); p.hline(x0 + 2, x0 + w - 3, 5, SAGE[4])
    p.hline(x0 + 2, x0 + w - 3, 13, SAGE[1])
    seat = 14
    n = max(2, w // 16)
    cw = (w - 8) // n
    for i in range(n):
        cx = x0 + 4 + i * cw
        p.box(cx, seat, cw - 1, 7, SAGE[3]); p.hline(cx, cx + cw - 2, seat, SAGE[4]); p.hline(cx, cx + cw - 2, seat + 6, SAGE[1])
        p.vline(cx + cw - 2, seat + 1, seat + 6, SAGE[2]); p.dot(cx + 2, seat + 2, SAGE[5])
        p.box(cx + 2, 7, cw - 5, 6, SAGE[2]); p.hline(cx + 2, cx + cw - 4, 7, SAGE[4]); p.dot(cx + cw // 2 - 1, 10, SAGE[1])
    face(p, x0 + 3, seat + 7, w - 6, yb - seat - 8, SAGE)
    for ax in (x0, x0 + w - 4):
        p.box(ax, 8, 4, yb - 9, SAGE[3]); p.hline(ax, ax + 3, 8, SAGE[5]); p.vline(ax + 3, 9, yb - 2, SAGE[1]); p.vline(ax, 9, yb - 2, SAGE[4])
    p.box(x0 + w - 13, 10, 5, 5, QUILT[4]); p.hline(x0 + w - 13, x0 + w - 9, 10, QUILT[5]); p.vline(x0 + w - 9, 11, 14, QUILT[2])
    for fx in (x0 + 1, x0 + w - 3): p.box(fx, yb - 1, 2, 2, WOOD[1])


def kitchen(p, x0, w, d, yb):
    tiles = ["8f9a8e", "c9d4c4", "e6ece0"]
    p.box(x0, 1, w, 8, tiles[1])
    for y in range(1, 9, 3):
        for x in range(x0 + (0 if (y // 3) % 2 else 1), x0 + w, 3):
            p.dot(x, y, tiles[2]); p.vline(x + 2, y, y + 2, tiles[0])
        p.hline(x0, x0 + w - 1, y + 2, tiles[0])
    slab(p, x0, 9, w, 8, ["4a4440", "6d655d", "988c7e", "c2b6a2", "ddd3bf", "f2eadb"], False)
    face(p, x0, 17, w, yb - 16, WOOD)
    for x in range(x0 + 2, x0 + w - 3, 10):
        p.box(x, 19, 8, yb - 21, WOOD[3]); p.hline(x, x + 7, 19, WOOD[4]); p.vline(x + 7, 20, yb - 3, WOOD[1]); p.dot(x + 6, 23, "e8c873")
    p.box(x0 + 1, 9, 14, 8, "2e2b2f"); p.hline(x0 + 1, x0 + 14, 9, "57525a")
    for bx in (x0 + 4, x0 + 11):
        p.oval(bx, 13, 2.5, 1.6, "17151a"); p.dot(bx, 12, "57525a"); p.dot(bx - 1, 13, "c4664a")
    p.box(x0 + 2, 17, 12, yb - 18, "3b373d"); p.box(x0 + 4, 19, 8, 5, "17151a"); p.hline(x0 + 4, x0 + 11, 19, "57525a"); p.dot(x0 + 6, 21, "e08f62")
    p.box(x0 + 5, 7, 6, 4, METAL[2]); p.hline(x0 + 5, x0 + 10, 7, METAL[4]); p.hline(x0 + 4, x0 + 11, 6, METAL[1])
    sx = x0 + w - 12
    p.box(sx, 11, 10, 5, METAL[1]); p.box(sx + 1, 12, 8, 3, TEAL[2]); p.hline(sx + 1, sx + 8, 12, TEAL[4])
    p.vline(sx + 5, 5, 10, METAL[4]); p.hline(sx + 4, sx + 6, 5, METAL[4]); p.dot(sx + 4, 11, METAL[3])
    if w >= 48:
        mx = x0 + w // 2 - 3
        p.box(mx, 8, 7, 4, "e9e1ca"); p.hline(mx + 1, mx + 5, 9, "d1825a"); p.dot(mx + 3, 7, "c4664a")
        goods_row(p, mx + 9, mx + 18, 11, 5, "jars")


def bathroom(p, kind, x0, w, d, yb):
    enamel = ["6d7f7c", "a3b4ae", "c9d6cf", "e3ebe4", "f4f8f2", "ffffff"]
    if kind == "bath":
        p.box(x0 + 1, 6, w - 2, yb - 8, enamel[3])
        p.hline(x0 + 2, x0 + w - 3, 6, enamel[5]); p.vline(x0 + 1, 7, yb - 4, enamel[4]); p.vline(x0 + w - 2, 7, yb - 4, enamel[1])
        p.box(x0 + 3, 9, w - 6, yb - 17, TEAL[3])
        for y in range(9, yb - 8):
            for x in range(x0 + 3, x0 + w - 3):
                if (x + y * 2) % 7 == 0: p.dot(x, y, TEAL[4])
        p.hline(x0 + 3, x0 + w - 4, 9, TEAL[1]); p.dot(x0 + 5, 11, TEAL[5])
        face(p, x0 + 1, yb - 8, w - 2, 7, enamel)
        for fx in (x0 + 2, x0 + w - 4): p.box(fx, yb - 1, 2, 2, "c49a4a"); p.dot(fx, yb - 1, "f2d27a")
        p.box(x0 + w // 2 - 1, 3, 2, 4, METAL[4]); p.dot(x0 + w // 2 - 2, 3, METAL[5])
    elif kind == "sink":
        p.box(x0 + 3, 1, 10, 9, WOOD[2]); p.box(x0 + 4, 2, 8, 7, "a7c6cc"); p.line(x0 + 5, 7, x0 + 9, 3, "e4f4f2")
        p.box(x0 + 1, 11, 14, 6, enamel[3]); p.hline(x0 + 1, x0 + 14, 11, enamel[5])
        p.oval(x0 + 8, 14, 4.5, 1.6, enamel[1]); p.oval(x0 + 8, 14, 3, 1, TEAL[3])
        p.vline(x0 + 8, 9, 12, METAL[4])
        face(p, x0 + 1, 17, 14, 2, enamel)
        p.box(x0 + 6, 19, 4, yb - 18, enamel[3]); p.vline(x0 + 9, 19, yb, enamel[1]); p.vline(x0 + 6, 19, yb, enamel[4])
    else:
        p.box(x0 + 3, 3, 10, 8, enamel[3]); p.hline(x0 + 3, x0 + 12, 3, enamel[5]); p.vline(x0 + 12, 4, 10, enamel[1])
        p.hline(x0 + 2, x0 + 13, 3, enamel[4]); p.dot(x0 + 10, 5, METAL[4])
        p.oval(x0 + 8, 16, 5, 4, enamel[3]); p.oval(x0 + 8, 15.5, 3.5, 2.6, enamel[1]); p.oval(x0 + 8, 16, 2.2, 1.5, TEAL[3])
        p.hline(x0 + 5, x0 + 10, 12, enamel[5])
        p.box(x0 + 5, 20, 6, yb - 19, enamel[2]); p.vline(x0 + 10, 20, yb, enamel[1])


def machinery(p, kind, x0, w, d, yb):
    if kind == "radio":
        body = ["3a2418", "5a3824", "7c5131", "a06c41", "c38d58", "e0b67c"]
        units = max(1, w // 16)
        for i in range(units):
            ux = x0 + i * (w // units)
            uw = w // units - (1 if units > 1 else 0)
            p.box(ux, 4, uw, yb - 3, body[2])
            p.hline(ux + 1, ux + uw - 2, 3, body[4]); p.hline(ux, ux + uw - 1, 4, body[4]); p.vline(ux, 4, yb, body[3]); p.vline(ux + uw - 1, 5, yb, body[1])
            p.box(ux + 2, 7, uw - 4, 9, "8a7356")
            for y in range(8, 16, 2): p.hline(ux + 3, ux + uw - 4, y, "5b4a38")
            p.box(ux + 3, 18, uw - 6, 3, "1f2a28"); p.hline(ux + 4, ux + 4 + (i * 3 + 5) % max(1, uw - 8), 19, "e8c873")
            for kx in (ux + 3, ux + uw - 5): p.box(kx, 23, 2, 2, "d8c7a4"); p.dot(kx, 23, "fff3c4")
            p.hline(ux, ux + uw - 1, yb, body[0])
        p.line(x0 + w - 4, 3, x0 + w - 2, 0, METAL[4])
        return
    shell = METAL
    top = 2 if kind != "console" else 8
    slab(p, x0, top, w, 6, shell, False)
    p.box(x0 + 2, top + 1, 4, 3, shell[1]); p.box(x0 + w - 8, top + 2, 5, 2, shell[1])
    face(p, x0, top + 6, w, yb - top - 5, shell)
    if kind == "console":
        p.box(x0 + 3, top - 6, w - 6, 7, shell[1]); p.box(x0 + 4, top - 5, w - 8, 5, TEAL[1])
        for x in range(x0 + 5, x0 + w - 5, 2): p.dot(x, top - 3 + (x // 2) % 3 - 1, TEAL[5])
        for x in range(x0 + 3, x0 + w - 3, 3):
            p.box(x, top + 2, 2, 2, ["e8c873", "e0716a", "8fd0b6"][x % 3])
        for x in range(x0 + 3, x0 + w - 3, 4): p.vline(x, top + 9, yb - 2, shell[1])
        return
    p.box(x0 + 3, top + 9, w - 6, 6, TEAL[1]); p.hline(x0 + 3, x0 + w - 4, top + 9, shell[0])
    for x in range(x0 + 4, x0 + w - 4):
        p.dot(x, top + 12 + round(math.sin(x * 0.9) * 1.5), TEAL[5])
    for i, x in enumerate(range(x0 + 4, x0 + w - 4, 5)):
        p.dot(x, top + 17, ["e8c873", "8fd0b6", "e0716a"][i % 3]); p.dot(x + 1, top + 17, shell[1])
    for y in range(top + 20, yb - 2, 2): p.hline(x0 + 3, x0 + w - 4, y, shell[1])
    if kind == "reactor":
        cx, cy = x0 + w // 2, top + 1
        p.oval(cx, cy - 1, 9, 4, shell[1]); p.oval(cx, cy - 2, 7, 3, "e8a64a"); p.oval(cx, cy - 2, 4, 1.5, "fff0b6")
        for gx in (cx - 12, cx + 11): p.box(gx, top + 9, 2, yb - top - 12, "b8794a"); p.vline(gx, top + 9, yb - 4, "e0a66a")
    if kind == "machine":
        gx = x0 + w - 9
        p.oval(gx, top + 3, 3, 3, LINEN[5]); p.line(gx, top + 3, gx + 2, top + 1, "c4664a"); p.dot(gx, top + 3, METAL[0])
        p.box(x0 + 2, top - 1, 3, 3, METAL[3]); p.line(x0 + 3, top - 1, x0 + 3, 0, METAL[4])


def art_piece(p, x0, w, d, yb):
    fw = w - 2
    p.box(x0 + 1, 2, fw, 14, "8a5a2a"); p.hline(x0 + 1, x0 + fw, 2, "e0b067"); p.vline(x0 + 1, 2, 15, "c48a3a")
    p.hline(x0 + 1, x0 + fw, 15, "4a2c14"); p.vline(x0 + fw, 3, 15, "4a2c14")
    for y in range(4, 14):
        for x in range(x0 + 3, x0 + fw - 1):
            t = (y - 4) / 9
            c = mix("9cc7d2", "f2d8a6", t)
            hill = 9 + math.sin((x - x0) * 0.35) * 1.6
            if y > hill: c = LEAF_OAK[3] if y < hill + 2 else LEAF_OAK[2]
            if y > 11: c = LEAF_OAK[1] if (x + y) % 3 else LEAF_OAK[2]
            p.dot(x, y, c)
    p.oval(x0 + fw - 5, 6, 1.4, 1.4, "fff3c4")
    p.dot(x0 + fw // 2, 1, METAL[2])


def telescope(p, x0, yb):
    for lx in (x0 + 3, x0 + 8, x0 + 12): p.line(x0 + 8, 18, lx, yb, WOOD[2])
    p.line(x0 + 9, 18, x0 + 13, yb, WOOD[4])
    for i in range(10):
        x, y = x0 + 3 + i, 18 - i
        p.dot(x, y, "c48a3a"); p.dot(x, y + 1, "e0b067"); p.dot(x + 1, y + 1, "8a5a2a"); p.dot(x, y - 1, "8a5a2a")
    p.box(x0 + 12, 6, 3, 3, "e0b067"); p.dot(x0 + 13, 7, "fff3c4"); p.dot(x0 + 7, 17, METAL[1])


def rug(p, x0, w, d):
    red = ["3e1a1f", "6e2a2c", "9c4038", "c46b4a", "e0a066", "f3d39a"]
    y0 = 12
    for y in range(y0, y0 + d):
        for x in range(x0 + 1, x0 + w - 1):
            bx, by = min(x - x0 - 1, x0 + w - 2 - x), min(y - y0, y0 + d - 1 - y)
            b = min(bx, by)
            c = red[2]
            if b == 0: c = red[1]
            elif b in (2, 3): c = "2f6470" if (x + y) % 2 else TEAL[2]
            elif b == 4: c = red[5]
            elif b > 4:
                mx, my = x - (x0 + w // 2), y - (y0 + d // 2)
                diamond = abs(mx) * d / w + abs(my)
                c = red[2]
                if int(diamond) % 6 in (0, 1): c = red[4]
                if diamond < 3: c = red[5]
                if (x + y) % 8 == 0 and int(diamond) % 6 > 2: c = red[3]
            p.dot(x, y, c)
    for y in range(y0, y0 + d, 2):
        p.dot(x0, y, LINEN[4]); p.dot(x0 + w - 1, y, LINEN[4])


def drop_sheet(w, h, lift):
    """Dust sheet thrown over unfinished furniture; folds hang to the floor."""
    width, depth = w * 16, h * 16
    c = add(f"cover_{w}x{h}", Pixels(width + 4, depth + 20))
    top, base = max(1, 12 - lift), 12 + depth
    for y in range(top, base + 1):
        sag = round(math.sin((y - top) / max(1, base - top) * math.pi) * 1)
        for x in range(2 - sag, width + 2 + sag):
            fold = math.sin(x * 0.55 + y * 0.08)
            t = (y - top) / max(1, base - top)
            v = 3.6 - t * 0.9 + fold * 0.8 + (dither(x, y) - 0.5) * 0.6
            if x > width - 2: v -= 1
            c.dot(x, y, LINEN[max(1, min(5, int(v)))])
    c.hline(3, width, top, LINEN[5])
    for x in range(2, width + 2, 4):
        if hash01(x, base, 3) > 0.4: c.dot(x, base + 1, LINEN[2])
    c.outline(k=-2.4)
    contact_shadow(c, 1, width + 2, base + 2, 2, 100)


def furniture(kind, w, h):
    W, D = w * 16, h * 16
    p = add(f"furniture_{kind}_{w}x{h}", Pixels(W + 4, D + 20))
    x0, yb = 2, 12 + D
    if kind == "rug":
        rug(p, x0, W, D)
        return
    if kind in ("bookshelf", "stock", "cabinet"):
        storage(p, kind, x0, W, D, yb)
    elif kind == "tools":
        storage(p, "tools", x0, W, D, yb)
        hx = x0 + 2
        if W > 16:
            for i, tool in enumerate(("hoe", "rake", "saw", "axe")):
                tx = hx + 3 + i * 7
                if tx > x0 + W - 4: break
                p.vline(tx, 3, 10, WOOD[4])
                if tool == "hoe": p.hline(tx - 2, tx, 10, METAL[3])
                if tool == "rake": p.hline(tx - 2, tx + 2, 2, METAL[3]); p.dot(tx - 2, 3, METAL[2]); p.dot(tx + 2, 3, METAL[2])
                if tool == "saw": p.box(tx + 1, 4, 3, 5, METAL[4]); p.vline(tx + 3, 4, 8, METAL[2])
                if tool == "axe": p.box(tx + 1, 3, 2, 3, METAL[4])
    elif kind == "seed_tray":
        table_like(p, "seed_tray", x0, W, D, yb, WOOD)
        p.box(x0 + 2, 7, W - 4, 6, DIRT[1]); p.hline(x0 + 2, x0 + W - 3, 7, WOOD[4]); p.hline(x0 + 2, x0 + W - 3, 12, WOOD[1])
        for x in range(x0 + 4, x0 + W - 3, 4):
            for y in (9, 11): plant_sprig(p, x, y - 1)
    elif kind == "crates":
        crates(p, x0, W, D, yb)
    elif kind in ("table", "chair", "desk", "counter"):
        table_like(p, kind, x0, W, D, yb, WOOD)
    elif kind == "bed":
        bed(p, x0, W, D, yb)
    elif kind == "sofa":
        sofa(p, x0, W, D, yb)
    elif kind == "kitchen":
        kitchen(p, x0, W, D, yb)
    elif kind in ("bath", "sink", "toilet"):
        bathroom(p, kind, x0, W, D, yb)
    elif kind in ("reactor", "machine", "console", "radio"):
        machinery(p, kind, x0, W, D, yb)
    elif kind == "art":
        art_piece(p, x0, W, D, yb)
        p.outline(k=-2.4)
        return
    elif kind == "telescope":
        telescope(p, x0, yb)
    elif kind == "plant":
        pot_plant(p, x0 + 8, yb + 1, True)
    finish(p, x0, x0 + W - 1, yb - 1)
    lift = {"radio": 15, "sofa": 8, "bed": 4}.get(kind)
    if lift is not None and f"cover_{w}x{h}" not in ASSETS:
        drop_sheet(w, h, lift)


COPPER = ["4a2416", "7a3c22", "a85a30", "d07f45", "eda766", "ffd59a"]
GOLD = ["5a3a12", "8a5f1c", "bb8a2a", "e2b544", "f6d872", "fff4bf"]


def boulder(p, ore):
    pts = [(2, 21), (1, 15), (4, 9), (9, 6), (14, 8), (15, 14), (14, 20), (9, 22)]
    p.polygon(pts, STONE[2])
    for y in range(5, 23):
        for x in range(0, 16):
            if p.get(x, y)[3] != 255: continue
            light = -((x - 8) * -0.6 + (y - 14) * -0.8) / 8
            v = 2.9 - light * 1.6 + (vnoise(x / 2.5, y / 2.5, 8 + ore) - 0.5) * 1.4 + (dither(x, y) - 0.5) * 0.7
            p.dot(x, y, STONE[max(0, min(5, int(v)))])
    p.line(5, 12, 9, 15, STONE[1]); p.line(9, 15, 12, 13, STONE[1]); p.dot(6, 11, STONE[4])
    p.line(4, 18, 7, 20, STONE[1])
    if ore:
        for x, y in [(4, 14), (9, 9), (11, 17), (7, 19)]:
            p.dot(x, y, COPPER[3]); p.dot(x + 1, y, COPPER[2]); p.dot(x, y - 1, COPPER[5]); p.dot(x + 1, y + 1, COPPER[1])
    p.outline(k=-2.5)
    contact_shadow(p, 1, 15, 23, 1, 130)


def barrel(p):
    for y in range(6, 22):
        bulge = 1 if 9 <= y <= 18 else 0
        for x in range(3 - bulge, 13 + bulge):
            t = (x - 2) / 11
            idx = 4 if t < 0.25 else 3 if t < 0.6 else 2 if t < 0.85 else 1
            p.dot(x, y, WOOD[idx])
        for x in (5, 8, 11):
            p.dot(x, y, WOOD[1] if y % 5 else WOOD[2])
    for y in (8, 18):
        p.hline(2, 13, y, METAL[2]); p.hline(2, 13, y + 1, METAL[1]); p.dot(4, y, METAL[4])
    p.oval(7.5, 5.5, 5, 2.2, WOOD[4]); p.oval(7.5, 5.5, 3.6, 1.2, WOOD[3]); p.hline(5, 10, 5, WOOD[2]); p.hline(4, 11, 3, WOOD[5])
    p.outline(k=-2.8)
    contact_shadow(p, 2, 13, 23, 1)


def chest(p):
    p.box(1, 12, 14, 9, WOOD[2]); p.box(1, 6, 14, 6, WOOD[3])
    p.hline(2, 13, 5, WOOD[5]); p.hline(1, 14, 6, WOOD[4]); p.hline(1, 14, 11, WOOD[1]); p.hline(1, 14, 12, WOOD[4])
    for x in (3, 12):
        p.vline(x, 5, 20, GOLD[3]); p.vline(x + 1, 6, 20, GOLD[1])
    p.box(6, 10, 4, 4, GOLD[3]); p.hline(6, 9, 10, GOLD[5]); p.dot(7, 12, GOLD[0]); p.dot(8, 12, GOLD[0])
    p.hline(1, 14, 20, WOOD[0])
    for x in range(5, 11, 2): p.dot(x, 16, WOOD[1])
    p.outline(k=-2.8)
    contact_shadow(p, 1, 14, 22, 1)


def cart(p):
    p.box(4, 9, 38, 10, WOOD[2]); slab(p, 4, 5, 38, 5, WOOD, False)
    for x in range(4, 42, 6): p.vline(x, 10, 17, WOOD[1])
    p.hline(4, 41, 10, WOOD[4]); p.hline(4, 41, 18, WOOD[0])
    goods = [(8, 4, "c46b4a"), (13, 3, "e0b04e"), (19, 4, "7fa35a"), (25, 3, "e9e1ca"), (31, 4, "c46b4a"), (36, 3, "b65d7d")]
    for x, y, c in goods:
        p.oval(x, y, 2.6, 2.2, c); p.dot(x - 1, y - 1, shade(c, 1.8)); p.dot(x + 1, y + 1, shade(c, -1.5))
    p.line(42, 14, 47, 12, WOOD[3]); p.line(42, 15, 47, 13, WOOD[1])
    for cx in (11, 35):
        p.oval(cx, 24, 5.5, 5.5, WOOD[1]); p.oval(cx, 24, 4.4, 4.4, WOOD[3])
        for y in range(20, 29):
            for x in range(cx - 4, cx + 5):
                if (x - cx) ** 2 + (y - 24) ** 2 <= 9: p.clear(x, y)
        for a in range(4):
            ang = a * math.pi / 4
            p.line(cx - round(math.cos(ang) * 3), 24 - round(math.sin(ang) * 3), cx + round(math.cos(ang) * 3), 24 + round(math.sin(ang) * 3), WOOD[2])
        p.dot(cx, 24, METAL[3]); p.dot(cx - 3, 21, WOOD[5])
    p.outline(k=-2.8)
    contact_shadow(p, 6, 16, 30, 1); contact_shadow(p, 30, 40, 30, 1)


def signpost(p):
    p.box(15, 8, 3, 23, WOOD[2]); p.vline(15, 8, 30, WOOD[4]); p.vline(17, 8, 30, WOOD[1])
    for y, flip in [(5, False), (15, True)]:
        x0, x1 = (3, 28) if not flip else (4, 29)
        tip = [(x1, y), (x1 + 3, y + 3), (x1, y + 6)] if not flip else [(x0, y), (x0 - 3, y + 3), (x0, y + 6)]
        p.box(x0, y, x1 - x0 + 1, 7, WOOD[3]); p.polygon(tip, WOOD[3])
        p.hline(x0, x1, y, WOOD[5]); p.hline(x0, x1, y + 6, WOOD[1])
        for x in range(x0 + 3, x1 - 2, 3):
            p.dot(x, y + 3, WOOD[0]); p.dot(x + 1, y + 3, WOOD[0]) if (x // 3) % 2 else p.dot(x, y + 2, WOOD[0])
        p.dot(16, y + 1, METAL[4]); p.dot(16, y + 5, METAL[4])
    p.dot(14, 30, GRASS[3]); p.dot(18, 30, GRASS[4]); p.dot(19, 29, GRASS[3])
    p.outline(k=-2.8)
    contact_shadow(p, 13, 19, 32, 1)


def lamp_post(p):
    p.box(7, 18, 2, 27, METAL[1]); p.vline(7, 18, 44, METAL[3])
    p.box(5, 43, 6, 2, METAL[2]); p.hline(5, 10, 43, METAL[4])
    p.box(4, 6, 8, 11, "f5d98c"); p.box(5, 7, 6, 9, "fff1b8"); p.dot(5, 7, "ffffff")
    p.vline(4, 6, 16, METAL[1]); p.vline(11, 6, 16, METAL[0]); p.vline(7, 7, 15, "e6b65a"); p.hline(4, 11, 11, "e6b65a")
    p.polygon([(3, 6), (8, 2), (12, 6)], METAL[2]); p.hline(3, 12, 6, METAL[4]); p.dot(8, 1, METAL[4])
    p.hline(4, 11, 17, METAL[2]); p.hline(5, 10, 18, METAL[1])
    p.outline(k=-2.8)
    contact_shadow(p, 4, 11, 46, 1)


def fountain(p):
    basin = ["4e4b52", "6f6a6e", "908a87", "b0a89d", "cfc6b3", "ebe3cf"]
    p.oval(16, 30, 15, 7, basin[2]); p.oval(16, 29, 15, 6, basin[4])
    p.box(1, 30, 31, 6, basin[2])
    for y in range(30, 36):
        for x in range(1, 32):
            if p.get(x, y)[3] and (x * 3 + y) % 7 == 0: p.dot(x, y, basin[1])
    p.hline(2, 30, 35, basin[0])
    p.oval(16, 29, 12.5, 4.5, WATER[2]); p.oval(15, 28, 10, 3, WATER[3])
    for x in (8, 13, 20, 24): p.hline(x, x + 1, 29 + x % 2, WATER[4])
    p.box(14, 10, 4, 19, basin[3]); p.vline(14, 10, 28, basin[5]); p.vline(17, 10, 28, basin[1])
    p.oval(16, 11, 7, 2.5, basin[3]); p.oval(16, 10.5, 5, 1.6, WATER[3]); p.hline(10, 22, 13, basin[1])
    p.vline(16, 3, 9, WATER[4]); p.dot(16, 2, WATER[5]); p.dot(15, 4, WATER[5])
    for side in (-1, 1):
        for i in range(6):
            p.dot(16 + side * (3 + i), 6 + i * i // 3, WATER[4 if i % 2 else 5])
    for i in range(5):
        p.dot(10 + side * 0 + i * 3, 25 - (i % 2), WATER[5])
    p.outline(k=-2.6)
    contact_shadow(p, 2, 30, 37, 2)


def chrysalis(p):
    p.vline(8, 0, 6, LINEN[2]); p.dot(8, 0, LINEN[4])
    for y in range(6, 20):
        r = math.sin((y - 5) / 15 * math.pi) * 3.4
        for x in range(round(8 - r), round(8 + r) + 1):
            t = (x - (8 - r)) / max(1, 2 * r)
            c = TEAL[4] if t < 0.3 else TEAL[3] if t < 0.7 else TEAL[2]
            p.dot(x, y, c)
    for y in range(9, 19, 3): p.hline(6, 10, y, TEAL[1]); p.dot(7, y - 1, GOLD[4])
    p.dot(7, 8, TEAL[5])
    p.outline(k=-2.5)


def sparkfire(p, bloom):
    p.vline(8, 10, 21, LEAF_OAK[2]); p.vline(9, 13, 21, LEAF_OAK[1])
    for lx, ly, d in [(4, 16, -1), (12, 18, 1), (5, 20, -1)]:
        p.hline(min(lx, lx + d * 3), max(lx, lx + d * 3), ly, LEAF_OAK[3]); p.dot(lx + d * 3, ly - 1, LEAF_OAK[4])
        p.hline(min(lx, lx + d * 2), max(lx, lx + d * 2), ly + 1, LEAF_OAK[1])
    if bloom:
        for i in range(6):
            a = i * math.tau / 6 - math.pi / 2
            x, y = 8 + round(math.cos(a) * 3.3), 8 + round(math.sin(a) * 3.3)
            p.box(x - 1, y - 1, 2, 2, GOLD[3]); p.dot(x - 1, y - 1, GOLD[5])
        p.oval(8, 8, 1.6, 1.6, "fff4bf"); p.dot(8, 8, "e08f62")
    else:
        p.oval(8, 9, 2, 2.6, LEAF_OAK[3]); p.dot(7, 8, GOLD[4]); p.dot(8, 7, "e08f62")
    p.outline(k=-2.5)
    contact_shadow(p, 5, 11, 22, 1)


def rat(p, frame):
    fur = ["2c2428", "4a3f42", "6b5f5d", "8d807a", "ad9f94", "cfc2b2"]
    p.line(0, 12 - frame % 2, 3, 11, "c99a96"); p.line(3, 11, 4, 11, "c99a96")
    p.oval(8, 10, 5, 3.2, fur[3]); p.oval(7, 9, 3.5, 2, fur[4])
    p.oval(13, 9.5, 2.5, 2, fur[3]); p.dot(15, 10, "e2a8a2"); p.dot(13, 9, "17151a")
    p.dot(12, 7, fur[4]); p.dot(11, 7, "e2a8a2")
    p.hline(5, 11, 12, fur[2])
    step = [0, 1, -1][frame]
    for fx in (5 + step, 10 - step): p.dot(fx, 13, "c99a96")
    p.outline(k=-2.6)
    contact_shadow(p, 4, 12, 14, 1)


def display(p, kind, frame):
    p.box(0, 0, 32, 16, "102027"); p.box(1, 1, 30, 14, "17323b")
    on = TEAL[4] if frame < 4 else LINEN[4]
    for y in range(2, 14, 2):
        for x in range(2, 30, 2):
            if frame == 4:
                p.dot(x, y, LINEN[3] if (x + y) % 4 else LINEN[5])
                continue
            if kind == "console" and (x // 2 + frame * 2 + y) % 5 > 1 and x < 4 + ((y * 7 + frame * 5) % 26): p.dot(x, y, on)
            if kind == "reactor":
                level = 7 + round(math.sin(x * 0.4 + frame) * 3)
                if y >= level: p.dot(x, y, GOLD[4] if y < level + 2 else on)
            if kind == "machine" and (x + frame * 4) % 12 < 6 and y % 4 == 2: p.dot(x, y, on); p.dot(x + 1, y, TEAL[3])
    p.hline(1, 30, 1, "2e5260")


def props():
    boulder(add("rock", Pixels(16, 24)), False)
    boulder(add("copper", Pixels(16, 24)), True)
    barrel(add("barrel", Pixels(16, 24)))
    chest(add("chest", Pixels(16, 24)))
    cart(add("cart", Pixels(48, 32)))
    signpost(add("sign", Pixels(32, 32)))
    lamp_post(add("lamp", Pixels(16, 48)))
    fountain(add("fountain", Pixels(32, 40)))
    chrysalis(add("chrysalis", Pixels(16, 24)))
    sparkfire(add("sparkfire", Pixels(16, 24)), False)
    sparkfire(add("sparkfire_bloom", Pixels(16, 24)), True)
    for frame in range(3):
        rat(add("rat" + str(frame), Pixels(16, 16)), frame)
    for frame in range(5):
        for kind in ("console", "reactor", "machine"):
            display(add(f"display_{kind}{frame}", Pixels(32, 16)), kind, frame)


HEAD_DOWN = [
    "......HHHH......",
    "....HLLHHHHH....",
    "...HLLHHHHHHh...",
    "...HHHHHHHHHh...",
    "...HHSSSSSSHh...",
    "...HSSSSSSSSh...",
    "...hSESSSSESh...",
    "...sSESSSSESs...",
    "....SrSSSSrS....",
    "....sSSmmSSs....",
    ".....ssSSss.....",
]
HEAD_UP = [
    "......HHHH......",
    "....HLLHHHHH....",
    "...HLLHHHHHHh...",
    "...HHHHHHHHHh...",
    "...HHHHHHHHHh...",
    "...HHHHHHHHHh...",
    "...hHHHHHHHHh...",
    "...shHHHHHHhs...",
    "....hHHHHHHh....",
    "....shhhhhhs....",
    ".....ssSSss.....",
]
HEAD_SIDE = [
    "......HHHH......",
    "....HLLHHHHH....",
    "...HLLHHHHHHH...",
    "...HHHHHHHHHH...",
    "...hHHHHSSSSS...",
    "...hHHHSSSSSS...",
    "...hHHsSSSSES...",
    "...hHhsSSSSESS..",
    "....hHSSSSSrS...",
    "....hsSSSSSm....",
    ".....ssSSSs.....",
]
BODY_DOWN = [
    "....CCWssWCC....",
    "...ACCWWWWCCa...",
    "..AACCCWWCCCaa..",
    "..AACCCCCCCCaa..",
    "..AACCCCCCCCaa..",
    "..kAbbbbbbbbak..",
    "..k.CCCCCCCc.k..",
]
BODY_UP = [
    "....CCCssCCC....",
    "...ACCCCCCCCa...",
    "..AACCCCcCCCaa..",
    "..AACCCCcCCCaa..",
    "..AACCCCcCCCaa..",
    "..kAbbbbbbbbak..",
    "..k.CCCCCCCc.k..",
]
BODY_SIDE = [
    ".....CCsCCC.....",
    "....cCCCWCCC....",
    "....cCAACCCC....",
    "....cCAaCCCC....",
    "....cCAaCCCC....",
    "....cbAabbbb....",
    "....cCkkCCCc....",
]
CAST = {
    "player": ("6f9793", "5c5045", "d0a981", "3d4652", "e2b84f", ""),
    "moss": ("a7834d", "d6cb9c", "d4a776", "4d4a3c", None, "hat"),
    "tavi": ("aa7262", "bd996b", "c0a070", "4a3c38", None, "ears"),
    "iona": ("8885ad", "e3d7bd", "ae856c", "3d3a52", None, "long"),
    "finch": ("6d96a0", "765842", "d3ab88", "4a4038", "c46b4a", "cap"),
    "vale": ("8b9baf", "b5a68e", "a97959", "44465a", None, "bun"),
    "mayor": ("657b70", "c2c4b0", "d0a181", "33363a", "e2b84f", "tophat"),
    "veteran": ("777a60", "b9b6a3", "b08f77", "4a4436", None, "beard"),
    "assistant": ("61758a", "c7cbcd", "65566d", "2e3440", "8fd0b6", "ears"),
    "keeper": ("536e81", "ded8c8", "c99c78", "393e4c", "e0b96e", "beard"),
}


def actor_palette(coat, hair, skin, pants, accent):
    eye = "2a2230"
    return {
        "H": hair, "h": shade(hair, -1.6), "L": shade(hair, 1.6),
        "S": skin, "s": shade(skin, -1.2), "r": mix(skin, "e0716a", 0.35), "m": shade(skin, -1.1),
        "E": eye if accent != "8fd0b6" else "8fd0b6",
        "C": coat, "c": shade(coat, -1.3), "A": shade(coat, 0.4), "a": shade(coat, -1.0),
        "W": accent or shade(coat, 2.6), "b": shade(coat, -3.0), "k": skin,
        "P": pants, "p": shade(pants, -1.2), "B": WOOD[1], "O": WOOD[0],
    }


def stamp_rows(p, rows, y0, pal, shift=None):
    for r, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch == ".": continue
            dx, dy = shift(x, r, ch) if shift else (0, 0)
            p.dot(x + dx, y0 + r + dy, pal[ch])


def legs(p, direction, frame, pal):
    P, pd, B, O = pal["P"], pal["p"], pal["B"], pal["O"]
    if direction in ("down", "up"):
        p.hline(4, 11, 24, P); p.hline(4, 11, 25, pd)
        for lx, lift in ((5, frame == 1), (8, frame == 2)):
            top, foot = 26, 28 - (1 if lift else 0)
            p.vline(lx, top, foot - 1, P); p.vline(lx + 1, top, foot - 1, P); p.vline(lx + 2, top, foot - 1, pd)
            bx = lx - 1 if lx == 5 else lx
            p.hline(bx, bx + 3, foot, B); p.hline(bx, bx + 3, foot + 1, O)
            p.dot(bx + (0 if lx == 5 else 3), foot, shade(B, 1.2))
        if direction == "up": p.vline(7, 24, 25, pd)
        return
    p.hline(5, 10, 24, P); p.hline(5, 10, 25, pd)
    if frame == 0:
        p.box(6, 26, 4, 2, P); p.vline(9, 26, 27, pd)
        p.hline(6, 10, 28, B); p.hline(6, 11, 29, O); p.dot(10, 28, shade(B, 1.2))
        return
    front, back = (P, pd) if frame == 1 else (pd, P)
    p.line(8, 26, 10, 27, front); p.line(9, 26, 11, 27, front)
    p.line(7, 26, 5, 27, back); p.line(6, 26, 4, 27, back)
    p.hline(9, 12, 28, B); p.hline(9, 12, 29, O); p.dot(12, 28, shade(B, 1.2))
    p.hline(3, 6, 28, shade(B, -0.5)); p.hline(3, 6, 29, O)


def accessory(p, kind, direction, pal, coat):
    side = direction in ("left", "right")
    H, h = pal["H"], pal["h"]
    if kind == "hat":
        straw = ["6e5a2c", "a68a46", "cdb36a", "e8d38f"]
        p.box(5, 3, 6, 4, straw[2]); p.hline(5, 10, 3, straw[3]); p.hline(5, 10, 6, "8a3a2c")
        p.hline(1 if not side else 2, 14, 7, straw[2]); p.hline(1 if not side else 2, 14, 8, straw[1])
        p.dot(6, 4, straw[3]); p.vline(10, 4, 5, straw[1])
    elif kind == "ears":
        if side:
            p.dot(5, 9, pal["S"]); p.dot(5, 8, pal["S"]); p.dot(4, 7, pal["s"]); p.dot(6, 10, pal["s"])
        else:
            for x, d in ((2, -1), (13, 1)):
                p.dot(x, 11, pal["S"]); p.dot(x, 12, pal["s"]); p.dot(x + d, 10, pal["S"])
    elif kind == "long":
        if direction == "down":
            for x, c in ((3, H), (12, h)): p.vline(x, 12, 18, c)
            p.vline(2, 13, 17, h); p.vline(13, 13, 17, h); p.dot(4, 18, h); p.dot(11, 18, h)
        elif direction == "up":
            p.box(3, 12, 10, 8, H); p.hline(4, 11, 20, h)
            for x in (5, 8, 11): p.vline(x, 13, 19, h)
            p.vline(4, 12, 18, pal["L"])
        else:
            p.box(3, 13, 3, 6, H); p.vline(3, 13, 19, h); p.dot(4, 19, h)
    elif kind == "bun":
        p.box(6, 3, 4, 3, H); p.hline(7, 8, 3, pal["L"]); p.hline(6, 9, 5, h)
        if side: p.box(3, 7, 2, 3, H)
    elif kind == "cap":
        p.box(4, 5, 8, 3, coat); p.hline(5, 9, 5, shade(coat, 1.4)); p.hline(4, 11, 8, shade(coat, -1.5))
        if direction == "down": p.hline(4, 11, 9, shade(coat, -2.2))
        if direction == "right": p.hline(9, 14, 9, shade(coat, -1.5))
        p.dot(8, 4, "c46b4a")
    elif kind == "tophat":
        hat = ["1c1a20", "2e2b33", "4a4552"]
        p.box(5, 0, 6, 7, hat[1]); p.vline(5, 0, 6, hat[2]); p.hline(5, 10, 5, "8a3a2c")
        p.hline(3, 12, 7, hat[0]); p.hline(4, 11, 6, hat[1])
        if direction == "down": p.hline(6, 9, 15, H); p.dot(5, 16, H); p.dot(10, 16, H)
        if side: p.hline(10, 12, 15, H)
    elif kind == "beard":
        if direction == "down":
            p.box(4, 14, 8, 3, H); p.hline(5, 10, 17, h); p.hline(6, 9, 15, pal["m"]); p.dot(5, 14, pal["L"])
        elif side:
            p.box(8, 14, 5, 3, H); p.hline(9, 11, 17, h)


def actors():
    for name, (coat, hair, skin, pants, accent, extra) in CAST.items():
        pal = actor_palette(coat, hair, skin, pants, accent)
        for direction in ("down", "up", "left", "right", "sleep"):
            for frame in range(3 if direction != "sleep" else 1):
                p = add(f"actor_{name}_{direction}{frame}", Pixels(16, 32))
                if direction == "sleep":
                    head = [r for r in HEAD_DOWN]
                    head[6] = "...hSSSSSSSSh..."
                    head[7] = "...sbbSSSSbbs..."
                    stamp_rows(p, head, 4, dict(pal, b=shade(skin, -2.6)))
                    if extra in ("ears", "bun"):
                        accessory(p, extra, "down", pal, coat)
                    p.box(3, 15, 10, 2, shade(coat, 0.3)); p.hline(3, 12, 15, shade(coat, 1.4))
                    p.outline(k=-2.6)
                    continue
                side = direction in ("left", "right")
                head = HEAD_SIDE if side else HEAD_UP if direction == "up" else HEAD_DOWN
                body = BODY_SIDE if side else BODY_UP if direction == "up" else BODY_DOWN
                bob = 1 if frame else 0
                legs(p, "right" if side else direction, frame, pal)

                def swing(x, r, ch, frame=frame, side=side):
                    if ch not in "Aak" or frame == 0:
                        return (0, 0)
                    sign = 1 if frame == 1 else -1
                    if side:
                        return (sign if r >= 4 else 0, 0)
                    return (0, -sign if x < 8 else sign) if r >= 4 else (0, 0)
                stamp_rows(p, body, 17 + bob, pal, swing)
                stamp_rows(p, head, 6 + bob, pal)
                if name == "player" and direction == "down":
                    p.dot(7, 19 + bob, shade(accent, -1.2)); p.dot(8, 20 + bob, shade(accent, -1.2))
                if extra:
                    sub = Pixels(16, 32)
                    accessory(sub, extra, "right" if side else direction, pal, coat)
                    p.stamp(sub, 0, bob)
                if direction == "left":
                    flipped = p.flipped()
                    p.data = flipped.data
                p.outline(k=-3.0)
                contact_shadow(p, 4, 11, 30, 2, 120)


FIRE = ["5a1e1a", "a83a24", "e0662e", "f5a03c", "fbd36a", "fff6d0"]
SMOKE = ["2e2a30", "4a4448", "6a6264", "8a8280"]


def planet(p):
    for y in range(96):
        for x in range(96):
            nx, ny = (x - 47.5) / 46.5, (y - 47.5) / 46.5
            r2 = nx * nx + ny * ny
            if r2 > 1: continue
            z = math.sqrt(1 - r2)
            u, v = nx / (z + 0.6), ny / (z + 0.6)
            land = vnoise(u * 3 + 5, v * 3 + 2, 77) * 0.65 + vnoise(u * 7, v * 7, 78) * 0.35
            cloud = vnoise(u * 5 + 9, v * 9, 79)
            if land > 0.56:
                ramp = ["2c4a2c", "3f6a37", "5c8a44", "86a85a", "c7b783"]
                base = 2 + (1 if land > 0.66 else 0) + (1 if land > 0.74 else 0)
            else:
                ramp = WATER
                base = 2 if land > 0.5 else 1
            light = z * 0.75 - nx * 0.45 - ny * 0.35
            v2 = base + (light - 0.35) * 3 + (dither(x, y) - 0.5) * 0.8
            c = ramp[max(0, min(len(ramp) - 1, int(v2)))]
            if cloud > 0.68 and light > 0.05:
                c = mix(c, "f4f1e6", 0.85 if light > 0.3 else 0.5)
            if light < -0.15: c = mix(c, "0c1220", 0.55)
            if light < -0.35: c = mix(c, "0c1220", 0.6)
            if r2 > 0.93 and light > -0.2: c = mix(c, "a8e0e8", 0.6)
            p.dot(x, y, c)


def explosion(p, frame):
    rng = random.Random(900 + frame)
    radius = 6 + frame * 3.6
    puffs = [(24 + math.cos(a) * radius * rng.uniform(0.5, 1), 24 + math.sin(a) * radius * rng.uniform(0.5, 1), rng.uniform(4, 7) + (2 if frame < 3 else 0)) for a in [i * math.tau / 11 + rng.uniform(-0.2, 0.2) for i in range(11)]]
    for cx, cy, r in puffs + [(24, 24, max(3, 11 - frame))]:
        for y in range(int(cy - r), int(cy + r) + 1):
            for x in range(int(cx - r), int(cx + r) + 1):
                d = math.hypot(x - cx, y - cy) / r
                if d > 1 - (hash01(x, y, frame) * 0.15): continue
                heat = 5.6 - frame * 0.95 - d * 2 - (math.hypot(x - 24, y - 24) / 24) * 2 + ((x - cx) + (y - cy)) / r * -0.6
                heat += dither(x, y) - 0.5
                if frame >= 3 and heat < 1.8:
                    c = SMOKE[max(0, min(3, int(heat + 1.5)))]
                else:
                    c = FIRE[max(0, min(5, int(heat)))]
                p.dot(x, y, c)
    if frame >= 2:
        for i in range(8):
            a = i * math.tau / 8 + frame
            d = radius + 6
            x, y = 24 + math.cos(a) * d, 24 + math.sin(a) * d
            p.dot(x, y, FIRE[4] if frame < 4 else SMOKE[3]); p.dot(x - math.cos(a), y - math.sin(a), FIRE[2] if frame < 4 else SMOKE[1])
    if frame >= 4:
        for y in range(48):
            for x in range(48):
                if p.get(x, y)[3] and hash01(x, y, 91 + frame) < (frame - 3) * 0.22: p.clear(x, y)


def spark(p, frame):
    arm = [3, 3, 2, 3, 2, 1][frame]
    p.dot(4, 4, "ffffff"); p.dot(3, 3, FIRE[5]); p.dot(4, 3, FIRE[5]); p.dot(3, 4, FIRE[5])
    for i in range(1, arm + 1):
        c = FIRE[5] if i == 1 else FIRE[4] if i == 2 else FIRE[3]
        if frame % 2 == 0:
            for dx, dy in ((i, 0), (-i, 0), (0, i), (0, -i)): p.dot(3.5 + dx + 0.5, 3.5 + dy + 0.5, c)
        else:
            for dx, dy in ((i, i), (-i, -i), (i, -i), (-i, i)): p.dot(3.5 + dx + 0.5, 3.5 + dy + 0.5, c)


def ship(p, hostile):
    hull = ["2a2238", "45365a", "6a5280", "8f74a0", "b49ac0", "d8c6dc"] if hostile else ["2f3a40", "4c5e66", "75898e", "a3b4ae", "cfd8c8", "eef2e2"]
    accent = "e0485a" if hostile else "e2b84f"
    body = [(4, 10), (36, 13), (90, 24), (36, 35), (4, 38), (18, 24)]
    p.polygon(body, hull[3])
    for y in range(9, 40):
        for x in range(96):
            if p.get(x, y)[3] != 255: continue
            v = 3.4 - (y - 20) / 10 + (dither(x, y) - 0.5) * 0.6
            p.dot(x, y, hull[max(1, min(5, int(v)))])
    p.polygon([(8, 12), (40, 15), (76, 22), (26, 22)], hull[4])
    p.line(4, 10, 36, 13, hull[5]); p.line(36, 13, 90, 24, hull[5])
    p.line(18, 24, 90, 24, hull[2]); p.line(36, 35, 90, 24, hull[1])
    for wy, sign in ((4, -1), (38, 1)):
        p.box(2, wy, 36, 6, hull[2]); p.hline(2, 37, wy, hull[4]); p.hline(2, 37, wy + 5, hull[0])
        p.box(2, wy + 1, 5, 4, "a8e0e8" if not hostile else "ff8a6a"); p.dot(3, wy + 2, "ffffff")
        for x in range(10, 36, 6): p.vline(x, wy + 1, wy + 4, hull[1])
    p.polygon([(56, 18), (68, 20), (64, 23), (52, 23)], "2a4a5a" if not hostile else "4a1a2a")
    p.line(57, 19, 64, 20, "a8e0e8" if not hostile else "e0485a")
    for x in range(24, 52, 5): p.box(x, 23, 2, 1, accent)
    for x in (30, 46): p.vline(x, 14, 33, hull[1])
    p.box(0, 20, 4, 8, FIRE[3]); p.box(0, 21, 2, 6, FIRE[5]); p.dot(1, 23, "ffffff")
    if hostile:
        p.polygon([(70, 22), (94, 18), (80, 24)], hull[2]); p.dot(84, 24, accent)
    p.outline(k=-2.8)


def bridge(p):
    p.box(0, 0, 160, 78, "141e28")
    p.box(15, 12, 130, 22, METAL[3]); p.box(19, 15, 122, 16, "0b1a2c")
    for x, y in [(30, 18), (52, 24), (70, 17), (97, 27), (115, 20), (133, 25), (40, 28), (85, 21)]:
        p.dot(x, y, "ffffff"); p.dot(x + 1, y, "8fb0d0")
    p.oval(120, 26, 9, 9, "3f6a7a"); p.oval(118, 24, 7, 6, "6d9fa3")
    for y in range(15, 31):
        for x in range(19, 141):
            if p.get(x, y)[:3] == (0x0b, 0x1a, 0x2c) and (x + y) % 37 == 0: p.dot(x, y, "6c909f")
    for x in (47, 80, 112): p.vline(x, 15, 30, METAL[4]); p.vline(x + 1, 15, 30, METAL[1])
    p.hline(15, 144, 12, METAL[5]); p.hline(15, 144, 33, METAL[1])
    p.polygon([(10, 77), (30, 34), (130, 34), (150, 77)], METAL[2])
    for y in range(36, 78, 5): p.hline(10, 150, y, METAL[1])
    for x0 in (24, 107):
        p.box(x0, 42, 29, 20, METAL[1]); p.box(x0 + 2, 44, 25, 8, TEAL[1])
        for y in (46, 48, 50): p.hline(x0 + 4, x0 + 4 + (y * 7 + x0) % 18, y, TEAL[4])
        for x in range(x0 + 3, x0 + 26, 4): p.dot(x, 55, ["e2b84f", "e0716a", "8fd0b6"][x % 3])
        p.hline(x0, x0 + 28, 61, METAL[0])
    p.box(73, 43, 14, 19, "3b4a52"); p.box(74, 44, 12, 12, "56707a"); p.hline(74, 85, 44, "8aa2a8")
    p.box(77, 40, 6, 5, "d0a981"); p.box(76, 38, 8, 3, "5c5045"); p.hline(77, 82, 38, "7a6a5c")
    p.box(76, 45, 8, 7, "6f9793"); p.box(72, 50, 3, 7, METAL[4]); p.box(85, 50, 3, 7, METAL[4])
    p.box(77, 52, 2, 8, "3d4652"); p.box(81, 52, 2, 8, "3d4652")
    p.box(78, 62, 4, 6, METAL[1])


def effects_and_ships():
    planet(add("planet", Pixels(96, 96)))
    p = add("particle", Pixels(2, 2)); p.box(0, 0, 2, 2, "ffffff")
    p = add("firefly", Pixels(4, 4)); p.box(0, 0, 4, 4, "f6d87a55"); p.box(1, 1, 2, 2, "fff0b6"); p.dot(1, 1, "ffffff")
    p = add("ripple", Pixels(8, 2)); p.hline(1, 6, 0, "c8e6dc99"); p.hline(0, 1, 1, "c8e6dc44"); p.hline(6, 7, 1, "c8e6dc44")
    p = add("cable", Pixels(16, 32))
    for y in range(32):
        x = 6 + round(math.sin(y * 0.2) * 2)
        p.hline(x, x + 2, y, "26323a"); p.dot(x, y, "4a5a62"); p.dot(x + 2, y, "151c22")
        if y % 4 == 0: p.dot(x + 1, y, "b08c5a")
    for frame in range(3):
        p = add("bird" + str(frame), Pixels(8, 8))
        wing = [(-2, -1), (0, 0), (2, 1)][frame]
        p.box(3, 4, 2, 2, "3a3238"); p.dot(5, 4, "3a3238"); p.dot(6, 4, "e2b84f")
        for i in range(1, 4):
            dy = wing[0] * i // 3 if frame != 1 else 0
            p.dot(3 - i, 4 + dy + (1 if frame == 2 else 0), "4a4248"); p.dot(4 + i, 4 + dy + (1 if frame == 2 else 0), "4a4248")
        p.dot(3, 5, "8a8288")
    for frame in range(6):
        explosion(add("explosion" + str(frame), Pixels(48, 48)), frame)
        spark(add("spark" + str(frame), Pixels(8, 8)), frame)
    for name, core, glow in (("bolt_friendly", "e8fbff", "6fd0e0"), ("bolt_enemy", "fff0e0", "f06a5a")):
        p = add(name, Pixels(16, 4))
        p.hline(1, 14, 1, glow); p.hline(1, 14, 2, glow); p.hline(4, 14, 1, core); p.hline(6, 14, 2, core)
        p.dot(0, 1, glow + "88"); p.dot(0, 2, glow + "88"); p.hline(9, 13, 0, glow + "88"); p.hline(9, 13, 3, glow + "88")
    ship(add("ship_crew", Pixels(96, 48)), False)
    ship(add("ship_enemy", Pixels(96, 48)), True)
    bridge(add("bridge", Pixels(160, 78)))


def handle(p, x0, y0, x1, y1):
    p.line(x0, y0, x1, y1, WOOD[4]); p.line(x0 + 1, y0, x1 + 1, y1, WOOD[2])


def fish_icon(p, length, height, body, belly, fin, stripes=False, eel=False):
    for x in range(1, 1 + length):
        t = (x - 1) / max(1, length - 1)
        h = height * (math.sin(min(1, t * 1.15) * math.pi) ** 0.6) if not eel else height * (1 - abs(t - 0.5) * 0.6)
        cy = 6 + (math.sin(t * 6) * 1.2 if eel else 0)
        for y in range(round(cy - h / 2), round(cy + h / 2) + 1):
            c = body if y < cy else belly
            if stripes and x % 3 == 0 and y < cy: c = shade(body, -1.8)
            p.dot(11 - x, y, c)
        p.dot(11 - x, round(cy - h / 2), shade(body, 1.4))
    tx = 11 - length
    if not eel:
        p.polygon([(tx + 1, 6), (tx - 2, 3), (tx - 2, 9)], fin)
    p.dot(9, 5, "1a1820"); p.dot(9, 4, "ffffff") if not eel else None
    p.dot(6, 3 if not eel else 4, fin)


def item_icon(name):
    p = add("item_" + name, Pixels(12, 12))
    if name == "axe":
        handle(p, 1, 11, 7, 3)
        p.polygon([(6, 2), (9, 0), (11, 2), (11, 6), (8, 7), (7, 4)], METAL[3])
        p.vline(11, 2, 6, METAL[5]); p.dot(7, 3, WOOD[1])
    elif name == "wood":
        for x, y in [(1, 4), (4, 7), (2, 10)]:
            p.box(x, y - 1, 7, 2, WOOD[3]); p.hline(x, x + 6, y - 1, WOOD[5]); p.dot(x, y, WOOD[2])
    elif name == "lantern_ray":
        p.polygon([(0, 4), (5, 1), (11, 4), (6, 8)], "82a2a5")
        p.line(6, 7, 9, 11, GOLD[3]); p.dot(4, 4, GOLD[5]); p.dot(7, 4, GOLD[5]); p.dot(6, 6, GOLD[4])
    elif name == "hoe":
        handle(p, 1, 11, 7, 3)
        p.box(7, 1, 2, 2, METAL[2]); p.box(8, 2, 4, 5, METAL[3]); p.vline(8, 2, 6, METAL[5]); p.hline(8, 11, 6, METAL[1])
    elif name == "pickaxe":
        handle(p, 2, 11, 6, 3)
        for x, y in [(1, 4), (2, 3), (3, 2), (4, 2), (5, 1), (6, 1), (7, 1), (8, 2), (9, 2), (10, 3), (11, 4)]:
            p.dot(x, y, METAL[4]); p.dot(x, y + 1, METAL[2])
        p.dot(6, 2, METAL[1]); p.dot(1, 5, METAL[1]); p.dot(11, 5, METAL[1])
    elif name == "sickle":
        handle(p, 1, 11, 3, 8)
        p.dot(3, 8, METAL[1]); p.dot(4, 7, METAL[1])
        for a in range(200, 380, 12):
            r = math.radians(a)
            x, y = 7 + math.cos(r) * 4, 5 + math.sin(r) * 4
            p.dot(round(x), round(y), METAL[4])
            p.dot(round(7 + math.cos(r) * 3), round(5 + math.sin(r) * 3), METAL[2] if a < 330 else METAL[4])
        p.dot(11, 6, METAL[5]); p.dot(4, 6, METAL[3])
    elif name == "rusty_sword":
        for i in range(7):
            p.dot(4 + i, 7 - i, METAL[4]); p.dot(5 + i, 7 - i, METAL[2])
        for x, y in ((6, 5), (8, 3), (9, 1)): p.dot(x, y, COPPER[2])
        p.line(1, 6, 5, 10, GOLD[2]); p.line(2, 9, 0, 11, WOOD[2]); p.dot(0, 11, GOLD[3])
    elif name == "watering_can":
        p.box(2, 5, 6, 6, "4f8a7a"); p.hline(2, 7, 5, "8fc4a8"); p.vline(7, 6, 10, "2f5a50"); p.hline(2, 7, 10, "2f5a50")
        p.line(8, 8, 11, 4, "4f8a7a"); p.dot(11, 3, "8fc4a8"); p.dot(10, 3, "8fc4a8")
        p.line(2, 4, 4, 2, "2f5a50"); p.line(4, 2, 7, 4, "2f5a50"); p.dot(3, 7, "b8e0c8")
    elif name in ("seeds", "star_seeds", "rations"):
        paper = LINEN if name != "rations" else ["4a3a28", "6e5838", "9a7c4c", "c0a06a", "dcc08a", "f0dcae"]
        p.box(2, 1, 8, 10, paper[3]); p.hline(2, 9, 1, paper[5]); p.vline(9, 2, 10, paper[1]); p.hline(2, 9, 10, paper[1])
        p.hline(2, 9, 2, paper[2])
        if name == "rations":
            p.vline(5, 1, 10, "a83a24"); p.hline(2, 9, 6, "a83a24"); p.dot(5, 6, "e0662e")
        elif name == "seeds":
            p.box(3, 4, 6, 5, "8fc46a"); plant_sprig(p, 6, 5); p.dot(4, 8, DIRT[2]); p.dot(7, 8, DIRT[2])
        else:
            p.box(3, 4, 6, 5, "4a3a6a")
            for dx, dy in ((0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)): p.dot(6 + dx, 6 + dy, GOLD[4])
            p.dot(4, 5, "ffffff")
    elif name in ("turnips", "star_bulbs"):
        if name == "turnips":
            p.oval(6, 7.5, 3.6, 3, "efe6dc"); p.oval(6, 6, 3.4, 1.6, "a75a9a"); p.dot(4, 7, "ffffff"); p.line(6, 10, 6, 11, "c8b8a8")
        else:
            for dx, dy in ((0, 0), (-1, 0), (1, 0), (0, -1), (0, 1), (-2, 1), (2, 1), (-1, 2), (1, 2)): p.dot(6 + dx, 7 + dy, GOLD[3])
            p.dot(5, 6, GOLD[5]); p.dot(6, 7, "fff4bf"); p.dot(7, 9, GOLD[1])
        for x, y in ((4, 3), (6, 2), (8, 3)): p.line(6, 5, x, y, LEAF_OAK[3]); p.dot(x, y, LEAF_OAK[5])
    elif name == "golden_sparkfire_bloom":
        p.line(6, 7, 6, 11, LEAF_OAK[2]); p.dot(4, 9, LEAF_OAK[4]); p.dot(8, 10, LEAF_OAK[4])
        for i in range(6):
            a = i * math.tau / 6
            p.box(round(5.5 + math.cos(a) * 2.6), round(4.5 + math.sin(a) * 2.6), 2, 2, GOLD[3])
        p.box(5, 4, 2, 2, "fff4bf"); p.dot(4, 2, GOLD[5])
    elif name == "cave_moth_chrysalis":
        p.vline(6, 0, 2, LINEN[3])
        for y in range(3, 11):
            r = math.sin((y - 2) / 9 * math.pi) * 2.6
            for x in range(round(6 - r), round(6 + r) + 1): p.dot(x, y, TEAL[4] if x < 6 else TEAL[2])
        for y in (5, 7, 9): p.hline(5, 7, y, TEAL[1])
        p.dot(5, 4, TEAL[5])
    elif name in ("pot", "fish_stew"):
        p.box(2, 5, 8, 6, METAL[1]); p.hline(2, 9, 5, METAL[3]); p.vline(2, 6, 10, METAL[2]); p.hline(3, 8, 10, METAL[0])
        p.dot(1, 6, METAL[2]); p.dot(10, 6, METAL[2])
        p.hline(2, 9, 4, METAL[4])
        if name == "fish_stew":
            p.hline(3, 8, 4, "d07a3a"); p.dot(4, 4, "f0b060"); p.dot(7, 4, "efe6dc")
            for x, y in ((4, 2), (6, 1), (8, 2)): p.dot(x, y, "e4ece888")
        else:
            p.hline(3, 8, 3, METAL[3]); p.dot(5, 2, METAL[4]); p.dot(6, 2, METAL[4])
    elif name == "pan":
        p.oval(5, 6, 4, 3.4, METAL[1]); p.oval(5, 5.6, 3, 2.4, METAL[0]); p.dot(4, 5, METAL[2])
        p.line(9, 5, 11, 3, WOOD[2]); p.dot(11, 2, WOOD[4])
    elif name == "fish_sticks":
        for y in (2, 5, 8):
            p.box(2 + y % 3, y, 7, 2, "d09a4a"); p.hline(2 + y % 3, 8 + y % 3, y, "f0c870"); p.dot(8 + y % 3, y + 1, "a06a2a")
    elif name in ("health_elixir", "light_bulbs"):
        if name == "health_elixir":
            p.box(5, 0, 2, 2, WOOD[3]); p.box(4, 2, 4, 2, "c9d8cf")
            p.oval(6, 7.5, 3.5, 3.5, "c9d8cf"); p.oval(6, 8, 2.6, 2.4, "c43a4a"); p.dot(5, 7, "f08a8a"); p.dot(4, 6, "ffffff")
        else:
            p.oval(6, 4.5, 3.5, 3.5, "fff0b0"); p.dot(4, 3, "ffffff"); p.line(5, 5, 7, 5, GOLD[2]); p.dot(6, 4, GOLD[3])
            p.box(5, 8, 3, 3, METAL[3]); p.hline(5, 7, 9, METAL[1]); p.dot(6, 11, METAL[1])
    elif name in ("stones", "copper"):
        rocks = [(3, 8, 2.6), (8, 8, 2.8), (6, 5, 2.6)] if name == "stones" else [(6, 6.5, 4.4)]
        for cx, cy, r in rocks:
            p.oval(cx, cy, r, r * 0.85, STONE[2]); p.oval(cx - 0.6, cy - 0.8, r * 0.7, r * 0.5, STONE[3]); p.dot(round(cx - 1), round(cy - 1), STONE[4])
        if name == "copper":
            for x, y in ((4, 5), (7, 8), (8, 4)): p.dot(x, y, COPPER[4]); p.dot(x + 1, y, COPPER[2])
    else:
        specs = {"fish": (9, 4, "7aa0b0", "d8e4dc", "5a7a90"), "moon_pike": (11, 3, "8a92b8", "e6e8f2", "5a6290"),
                 "sea_sprat": (7, 3, "a8c4c4", "eef4ee", "6a9494"), "blue_mackerel": (10, 4, "3a6aa8", "dde8ee", "2a4a78"),
                 "storm_eel": (11, 2, "4a5868", "8a9aa8", "e2d84f")}
        length, height, body, belly, fin = specs.get(name, specs["fish"])
        fish_icon(p, length, height, body, belly, fin, name == "blue_mackerel", name == "storm_eel")
    p.outline(k=-3.0)


def crop(name):
    p = add("crop_" + name, Pixels(16, 16))
    wet = name == "wet" or name.endswith("_wet")
    plant = name.removesuffix("_wet")
    dirt = ["24170f", "3a261a", "52372a", "6a4a36", "85614a", "9e7a5e"] if wet else DIRT
    p.box(1, 2, 14, 13, dirt[3])
    for y in range(2, 15):
        for x in range(1, 15):
            if hash01(x, y, 55) > 0.85: p.dot(x, y, dirt[4])
            elif hash01(x, y, 56) < 0.12: p.dot(x, y, dirt[2])
    if plant != "soil":
        for y0 in (3, 7, 11):
            p.hline(1, 14, y0, dirt[4]); p.hline(1, 14, y0 + 1, dirt[3]); p.hline(1, 14, y0 + 2, dirt[1])
            for x in range(1, 15):
                if hash01(x, y0, 57) > 0.8: p.dot(x, y0, dirt[5])
    else:
        for x, y in ((4, 5), (10, 9), (7, 12)): p.dot(x, y, STONE[4]); p.dot(x + 1, y, STONE[2])
    p.hline(1, 14, 2, dirt[2]); p.hline(1, 14, 14, dirt[0]); p.vline(1, 2, 14, dirt[2]); p.vline(14, 2, 14, dirt[1])
    if wet:
        for x, y in ((3, 6), (9, 4), (12, 10), (5, 12)): p.dot(x, y, "4a6a78"); p.dot(x + 1, y, "2e4450")
    if plant == "sprout":
        p.vline(8, 7, 10, LEAF_OAK[3]); p.hline(5, 7, 7, LEAF_OAK[4]); p.dot(5, 6, LEAF_OAK[5])
        p.hline(9, 11, 6, LEAF_OAK[3]); p.dot(11, 5, LEAF_OAK[4]); p.dot(7, 8, LEAF_OAK[2]); p.dot(9, 7, LEAF_OAK[1])
        p.hline(7, 9, 11, dirt[1])
    elif plant == "turnip":
        p.oval(8, 10, 3.5, 2.6, "efe6dc"); p.hline(5, 11, 9, "a75a9a"); p.hline(6, 10, 8, "c27ab4")
        p.dot(6, 10, "ffffff"); p.hline(6, 10, 12, "c8b8a8")
        for x, y in ((4, 3), (8, 1), (12, 3), (6, 2), (10, 2)): p.line(8, 7, x, y, LEAF_OAK[3]); p.dot(x, y, LEAF_OAK[5])
        p.dot(8, 6, LEAF_OAK[1])
    elif plant == "bulb":
        for dx, dy in ((0, 0), (-1, 0), (1, 0), (0, -1), (0, 1), (-2, 1), (2, 1), (-1, 2), (1, 2), (-2, 0), (2, 0)): p.dot(8 + dx, 9 + dy, GOLD[3])
        p.dot(7, 8, GOLD[5]); p.dot(8, 9, "fff4bf"); p.hline(7, 9, 11, GOLD[1])
        for x, y in ((5, 3), (8, 2), (11, 3)): p.line(8, 7, x, y, LEAF_BIRCH[3]); p.dot(x, y, LEAF_BIRCH[5])
        p.dot(4, 6, "fff4bf88"); p.dot(12, 7, "fff4bf88")


def item_names():
    names = [k[5:] for k in json.loads((ROOT / "src/native/art/option2/sprites.json").read_text()) if k.startswith("item_")]
    source = (ROOT / "src/native/items.gd").read_text()
    for name in re.findall(r'^\t"(\w+)":\{"name"', source, re.MULTILINE):
        if name not in names: names.append(name)
    return names


FURNITURE_KINDS = {"rug", "bed", "sofa", "table", "chair", "desk", "counter", "bookshelf", "stock", "cabinet", "crates", "tools", "seed_tray", "kitchen", "bath", "sink", "toilet", "reactor", "machine", "console", "radio", "art", "telescope", "plant"}
EXTRA_IDS = [f"tile_fence_mask{i}" for i in range(16)] + ["tile_gate_h_open", "tile_gate_v_open", "crop_sprout_wet", "crop_turnip_wet", "crop_bulb_wet"]


def coastal_sprites():
    p = tile("stone_jetty")
    p.box(0, 0, 16, 16, "354d59")
    for row in range(4):
        for x in range(-4 if row % 2 else 0, 16, 8):
            p.box(x + 1, row * 4 + 1, 7, 3, "88978e")
            p.hline(x + 1, x + 6, row * 4 + 1, "c0c3aa")
            p.dot(x + 6, row * 4 + 2, "657b7a")
    for kind in ("wall", "stripe", "window", "door_top", "door_bottom"):
        p = tile("lighthouse_" + kind)
        ramp = ["8b3e38", "b45a48", "d17a5a"] if kind == "stripe" else ["b1b7a6", "e2dfc6", "fff1ce"]
        p.box(0, 0, 16, 16, ramp[1]); p.hline(0, 15, 0, ramp[2]); p.hline(0, 15, 15, ramp[0])
        for y in (5, 10):
            p.hline(0, 15, y, ramp[0]); p.dot((y * 3) % 16, y - 1, ramp[2])
        if kind == "window":
            p.box(4, 1, 8, 13, "303e49"); p.box(5, 2, 6, 10, "92b8bc")
            p.hline(5, 10, 2, "d5e2ce"); p.vline(8, 2, 11, "e0dbc3"); p.hline(3, 12, 13, "929d91")
        if kind.startswith("door"):
            p.box(2, 0, 12, 16, "3c5361"); p.box(3, 0, 10, 15, "617d85")
            p.vline(3, 0, 15, "9ab0ab"); p.vline(12, 0, 15, "344d59")
            if kind == "door_bottom": p.dot(11, 7, "f0c574")
    for part in ("left", "center", "right"):
        p = tile("lantern_" + part)
        p.box(0, 0, 16, 16, "344650"); p.box(1, 2, 14, 10, "dbb65c")
        p.box(3, 3, 10, 7, "ffe6a0"); p.vline(7, 1, 12, "52636a")
        p.hline(0, 15, 0, "8f9c95"); p.hline(0, 15, 13, "86978f"); p.box(0, 14, 16, 2, "243b48")
        p = tile("cap_" + part)
        if part == "center":
            p.box(0, 8, 16, 8, "465b67"); p.vline(7, 1, 9, "263e4e"); p.hline(0, 15, 8, "8e9d9a")
        elif part == "left": p.polygon([(0, 15), (15, 8), (15, 15)], "728992")
        else: p.polygon([(0, 8), (15, 15), (0, 15)], "344b5b")
    p = tile("civic_emblem")
    p.box(2, 0, 12, 16, "2f4f67"); p.hline(2, 13, 1, "dfbd71")
    p.polygon([(8, 3), (12, 8), (8, 13), (4, 8)], "e5c77e"); p.vline(8, 6, 10, "6d7a75")
    p = add("stump", Pixels(16, 16))
    p.box(3, 9, 10, 6, WOOD[2]); p.oval(8, 9, 5, 3, WOOD[4]); p.oval(8, 9, 3, 1, WOOD[2]); p.dot(8, 9, WOOD[5])


def main():
    argparse.ArgumentParser(description=__doc__).parse_args()
    terrain(); buildings(); coastal_sprites(); vegetation(); props(); actors(); effects_and_ships()
    for name in item_names(): item_icon(name)
    source = (ROOT / "src/native/interior_layouts.gd").read_text()
    sizes = {(kind, int(w), int(h)) for kind, w, h in re.findall(r'\["(\w+)",Rect2i\([^,]+,[^,]+,(\d+),(\d+)\)\]', source) if kind in FURNITURE_KINDS and (kind != "kitchen" or h == "1")}
    baseline = json.loads((ROOT / "src/native/art/option2/sprites.json").read_text())
    for key in baseline:
        m = re.fullmatch(r"furniture_(\w+)_(\d+)x(\d+)", key)
        if m: sizes.add((m.group(1), int(m.group(2)), int(m.group(3))))
    for kind, w, h in sorted(sizes): furniture(kind, w, h)
    for name in ("soil", "tilled", "wet", "sprout", "turnip", "bulb", "sprout_wet", "turnip_wet", "bulb_wet"): crop(name)
    missing = [k for k in list(baseline) + EXTRA_IDS if k not in ASSETS]
    if missing: raise SystemExit("Missing sprites: " + ", ".join(missing))
    for key, value in baseline.items():
        w, h = ASSETS[key][0].w, ASSETS[key][0].h
        if (w, h) != ((value["rect"][2] + 1) // 2, (value["rect"][3] + 1) // 2):
            raise SystemExit(f"Size mismatch for {key}: {w}x{h}")
    width, x, y, row = 1024, 1, 1, 0
    manifest = {}
    for name, (image, metadata) in ASSETS.items():
        if x + image.w + 1 > width: x, y, row = 1, y + row + 2, 0
        manifest[name] = dict(rect=[x, y, image.w, image.h], **metadata)
        x += image.w + 2
        row = max(row, image.h)
    atlas = Pixels(width, y + row + 1)
    for name, (image, _) in ASSETS.items(): atlas.copy(image, *manifest[name]["rect"][:2])
    DEST.mkdir(parents=True, exist_ok=True)
    atlas.png(DEST / "sprites.png")
    (DEST / "sprites.json").write_text(json.dumps(manifest, indent=2) + "\n")
    pack = {"id": "rustic16", "name": "Rustic 16-pixel artwork", "tile_size": 16, "atlas": "sprites.png", "sprites": "sprites.json"}
    (DEST / "pack.json").write_text(json.dumps(pack, indent=2) + "\n")
    print(f"Built {len(manifest)} pixel sprites in {atlas.w} x {atlas.h} atlas: {DEST.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
