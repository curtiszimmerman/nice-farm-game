#!/usr/bin/env python3
"""Build option 2's integer-pixel PNG atlas, using only the standard library.

Run from any directory. All outputs stay in src/native/art/option2.
Tiles have no smoothing or gutters inside their 32-pixel logical cells.
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
ASSETS = {}


def rgba(value):
    if isinstance(value, tuple):
        return value
    value = value.lstrip("#")
    return tuple(bytes.fromhex(value)) + ((255,) if len(value) == 6 else ())


class Pixels:
    def __init__(self, width, height):
        self.w, self.h = width, height
        self.data = bytearray(width * height * 4)

    def dot(self, x, y, color):
        x, y = int(x), int(y)
        if 0 <= x < self.w and 0 <= y < self.h:
            offset = (y * self.w + x) * 4
            self.data[offset:offset + 4] = bytes(rgba(color))

    def box(self, x, y, w, h, color):
        for yy in range(int(y), int(y + h)):
            for xx in range(int(x), int(x + w)):
                self.dot(xx, yy, color)

    def oval(self, x, y, rx, ry, color):
        for yy in range(math.floor(y - ry), math.ceil(y + ry + 1)):
            for xx in range(math.floor(x - rx), math.ceil(x + rx + 1)):
                if ((xx - x) / max(rx, 1)) ** 2 + ((yy - y) / max(ry, 1)) ** 2 <= 1:
                    self.dot(xx, yy, color)

    def polygon(self, points, color):
        for y in range(min(p[1] for p in points), max(p[1] for p in points) + 1):
            edges = []
            for a, b in zip(points, points[1:] + points[:1]):
                if min(a[1], b[1]) <= y < max(a[1], b[1]):
                    edges.append(a[0] + (y - a[1]) * (b[0] - a[0]) / (b[1] - a[1]))
            for left, right in zip(sorted(edges)[::2], sorted(edges)[1::2]):
                self.box(math.ceil(left), y, math.floor(right) - math.ceil(left) + 1, 1, color)

    def grain(self, x, y, w, h, colors, seed, count=50):
        rng = random.Random(seed)
        for _ in range(count):
            xx, yy = rng.randrange(int(x), int(x + w)), rng.randrange(int(y), int(y + h))
            self.box(xx, yy, rng.choice((1, 2, 3)), 1, rng.choice(colors))

    def copy(self, other, x, y):
        for yy in range(other.h):
            start = ((y + yy) * self.w + x) * 4
            self.data[start:start + other.w * 4] = other.data[yy * other.w * 4:(yy + 1) * other.w * 4]

    def png(self, path):
        def chunk(kind, payload):
            return struct.pack(">I", len(payload)) + kind + payload + struct.pack(">I", zlib.crc32(kind + payload))
        rows = b"".join(b"\0" + self.data[y * self.w * 4:(y + 1) * self.w * 4] for y in range(self.h))
        path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", self.w, self.h, 8, 6, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(rows, 9)) + chunk(b"IEND", b""))


def add(name, image, **metadata):
    ASSETS[name] = (image, metadata)
    return image


def tile(name, color):
    p = add("tile_" + name, Pixels(32, 32))
    p.box(0, 0, 32, 32, color)
    return p


def terrain():
    for i in range(4):
        p = tile("grass" + str(i), "7d9259")
        p.grain(0, 0, 30, 32, ["879c60", "74894f", "96a56b"], i, 90)
        for x, y in [(4 + i, 11), (21, 23 - i)]:
            p.box(x, y, 1, 3, "647c46"); p.box(x + 1, y + 2, 2, 1, "9bac6d")
        p = tile("wood" + str(i), "ad8c61")
        for y in range(0, 32, 8):
            p.box(0, y, 32, 1, "806245"); p.box(0, y + 1, 32, 1, "c5a878")
            x = (i * 9 + y * 3) % 30
            p.box(x, y, 1, 8, "8f704c")
            p.box(x + 2, y + 3, 1, 1, "675942")
        p.grain(0, 0, 30, 32, ["b89668", "9c7e55"], 12 + i, 50)
        p = tile("cave" + str(i), "555f63")
        p.grain(0, 0, 29, 32, ["657074", "4b565d", "707976"], 22 + i, 70)
        p.box(3, 19, 7, 1, "3a4b52"); p.box(10, 20, 3, 1, "3a4b52")
        p = tile("paving" + str(i), "7b8274")
        for y in range(0, 32, 8):
            for x in range(-8 if y % 16 else 0, 32, 16):
                p.box(x + 1, y + 1, 14, 6, "b0b49b" if (x + y + i) % 3 else "9fa78f")
                p.box(x + 2, y + 1, 12, 1, "c4c5ab")
    p = tile("bath", "758b87")
    for y in [0, 16]:
        for x in [0, 16]:
            p.box(x + 1, y + 1, 15, 15, "bec7b4" if x == y else "d4d3b8")
            p.box(x + 2, y + 2, 13, 1, "e2dfc5")
    p = tile("metal", "3a4e5a")
    p.box(1, 1, 30, 30, "586b72"); p.box(3, 3, 26, 1, "87989b")
    for x in [5, 26]:
        for y in [5, 26]: p.box(x, y, 2, 2, "b2b8a8")
    p = tile("wall", "829082")
    p.box(0, 0, 32, 6, "d1d0b7"); p.box(0, 6, 32, 2, "9da88f")
    p.box(0, 29, 32, 3, "3b544c"); p.box(1, 27, 30, 2, "b6bca0")
    p = tile("void", "263632")
    for mask in range(16):
        p = tile("cliff" + str(mask), "788879")
        p.grain(0, 0, 29, 32, ["8c9987", "697e72", "819481"], mask, 60)
        for y in [9, 21]:
            p.box(0, y, 32, 2, "9aa58c"); p.box(0, y + 2, 32, 1, "526b60")
        if mask & 1: p.box(0, 0, 4, 32, "acb39a")
        if mask & 2: p.box(28, 0, 4, 32, "435e54")
        if mask & 4:
            p.box(0, 0, 32, 4, "b0b69c"); p.box(2, 4, 28, 2, "8c9e82")
        if mask & 8:
            p.box(0, 12, 32, 20, "526d61"); p.box(0, 11, 32, 3, "bbc0a0")
            for y in [19, 27]: p.box(0, y, 32, 2, "849680")
            p.grain(0, 15, 29, 17, ["617a6a", "3d584f"], mask, 25)
    p = tile("trail", "a4a186")
    p.grain(0, 0, 29, 32, ["bcb798", "8a9279", "c1b99d"], 31, 75)
    p = tile("jetty", "66523d")
    for x in range(0, 32, 8):
        p.box(x + 1, 0, 6, 32, "ae8c58"); p.box(x + 1, 1, 1, 30, "d1b17a")
        p.box(x + 2, 4, 2, 2, "66583f"); p.box(x + 2, 26, 2, 2, "66583f")


def buildings():
    for variant, base in [("plaster", "c8b68e"), ("log", "96704b"), ("stone", "85948a"), ("shop", "bb9d72")]:
        for kind in ["wall", "left", "right", "foundation", "window", "door", "door_top", "door_bottom"]:
            p = tile(variant + "_" + kind, base)
            for y in range(3, 32, 7):
                p.box(0, y, 32, 1, "aa9471" if variant != "stone" else "657d72")
                if variant in ["stone", "log"]: p.box((y * 3) % 24, y - 5, 1, 5, "625c49")
            p.grain(2, 2, 28, 28, ["d0bd94", "b6a57e"] if variant == "plaster" else [base, "98896a"], len(variant) + len(kind), 30)
            if kind in ["left", "right"]:
                x = 0 if kind == "left" else 26
                p.box(x, 0, 6, 32, "766c51"); p.box(x + 1, 0, 2, 32, "a19573")
            if kind == "foundation":
                for y in range(13, 32, 6):
                    p.box(0, y, 32, 5, "73786b"); p.box(1, y, 30, 1, "999b84")
                    p.box((y * 3) % 25, y, 2, 5, "4d6055")
            if kind == "window":
                p.box(5, 3, 22, 24, "6a6048"); p.box(7, 4, 18, 20, "d6c9a0")
                p.box(9, 6, 14, 16, "406575"); p.box(10, 7, 5, 6, "90b5bb")
                p.box(16, 6, 2, 16, "d9cdac"); p.box(9, 13, 14, 2, "c1b58e")
                p.box(3, 26, 26, 3, "e2d2a4")
            if kind == "door":
                p.box(5, 0, 23, 32, "5a503e"); p.box(7, 1, 18, 29, "967451")
                p.box(9, 3, 14, 12, "465f61"); p.box(10, 4, 5, 8, "86a3a1")
                p.box(9, 18, 14, 10, "7d5e40"); p.box(21, 18, 2, 2, "efcf85")
                p.box(4, 30, 25, 2, "b9ad8b")
            if kind in ["door_top", "door_bottom"]:
                p.box(4, 0, 24, 32, "5b503d"); p.box(7, 0, 18, 32, "987652")
                if kind == "door_top":
                    p.box(4, 0, 24, 3, "c2aa7d"); p.box(9, 7, 14, 21, "466b77")
                    p.box(10, 8, 5, 18, "83a8ad"); p.box(16, 7, 2, 21, "d3bf96")
                else:
                    for y in [4, 18]: p.box(9, y, 14, 11, "785a3c"); p.box(10, y + 1, 12, 1, "bd9864")
                    p.box(21, 5, 2, 3, "ecd294"); p.box(3, 30, 26, 2, "b9ad8b")
    for kind in ["roof", "roof_left", "roof_right", "ridge", "chimney"]:
        p = add("tile_" + kind, Pixels(32, 32))
        for y in range(32):
            for x in range(32):
                if kind == "roof_left" and x < 31 - y: continue
                if kind == "roof_right" and x > y: continue
                p.dot(x, y, "9c5d49" if y % 8 > 1 else "d29168")
                if (x + (8 if y // 8 % 2 else 0)) % 16 == 0: p.dot(x, y, "744b3c")
        p.grain(4, 4, 24, 25, ["a86c50", "bc7b55"], len(kind), 20) if kind == "roof" else None
        if kind == "ridge": p.box(0, 0, 32, 4, "e5ac7a"); p.box(0, 4, 32, 2, "714535")
        if kind == "chimney":
            p.data = bytearray(32 * 32 * 4)
            p.box(10, 3, 14, 29, "876e59")
            for y in range(6, 32, 6): p.box(10, y, 14, 1, "bfac8b"); p.box(10 + y % 9, y, 1, 5, "594e40")
            p.box(7, 2, 20, 4, "baa987"); p.box(11, 2, 12, 2, "423e34")
    p = add("tile_flowerbed", Pixels(32, 32))
    p.oval(16, 23, 16, 7, "6c5e43")
    for x in [5, 14, 24]:
        p.box(x, 9, 2, 15, "476940"); p.oval(x - 3, 16, 4, 2, "77984e")
        for dx, dy in [(-2, 0), (2, 0), (0, -3), (0, 3)]: p.oval(x + dx, 8 + dy, 2, 2, "dab29b")
        p.dot(x, 8, "f2d781")
    p = add("tile_light", Pixels(32, 32))
    p.box(14, 2, 3, 21, "575a47"); p.box(10, 7, 11, 15, "66553e")
    p.box(12, 9, 7, 10, "efdb9e"); p.box(13, 10, 2, 7, "fff0bf")
    p.box(9, 5, 13, 3, "657067")
    p = add("tile_fence", Pixels(32, 32))
    for y in [11, 23]: p.box(0, y, 32, 3, "b9ae8a")
    for x in [1, 13, 25]:
        p.polygon([(x, 31), (x, 6), (x + 3, 2), (x + 6, 6), (x + 6, 31)], "d1c6a3")
        p.box(x + 4, 7, 2, 24, "9a9677")
    for mask in range(16):
        p = add(f"tile_fence_mask{mask}", Pixels(32, 32))
        for y in [13, 23]:
            if mask & 1: p.box(0, y, 16, 3, "b9ae8a")
            if mask & 2: p.box(16, y, 16, 3, "b9ae8a")
        if mask & 4: p.box(15, 0, 3, 18, "b9ae8a")
        if mask & 8: p.box(15, 18, 3, 14, "b9ae8a")
        p.polygon([(13, 31), (13, 9), (16, 5), (19, 9), (19, 31)], "d1c6a3")
        p.box(17, 10, 2, 21, "9a9677")
    for vertical in [False, True]:
        p = add("tile_gate_v_open" if vertical else "tile_gate_h_open", Pixels(32, 32))
        if vertical:
            p.box(13, 0, 6, 6, "d1c6a3"); p.box(13, 27, 6, 5, "d1c6a3")
            p.box(17, 1, 14, 3, "b9ae8a")
        else:
            p.box(0, 11, 4, 21, "d1c6a3"); p.box(28, 11, 4, 21, "d1c6a3")
            p.box(1, 4, 3, 24, "b9ae8a")
    for right in [False, True]:
        p = add("tile_tower_right" if right else "tile_tower_left", Pixels(32, 32))
        shades = ["b0b8ac", "a2afa3", "91a297", "7c9387", "6e857a", "596f66"]
        for x in range(32):
            if (not right and x < 6) or (right and x > 25): continue
            p.box(x, 0, 1, 32, shades[min(5, x // 6)] if right else shades[max(0, 2 - x // 12)])
        for y in range(5, 32, 9): p.box(6 if not right else 0, y, 26, 1, "65796d")
    for right in [False, True]:
        p = tile("cave_arch_right" if right else "cave_arch_left", "879180")
        p.grain(0, 0, 29, 32, ["a0a78e", "76866e", "697b6c"], int(right), 75)
        for y in range(32):
            for x in range(32):
                if (x + (32 if right else 0) - 32) ** 2 + (y - 32) ** 2 < 28 ** 2: p.dot(x, y, "263632")


def trees_and_bushes():
    for species in ["oak", "birch", "pine"]:
        for rows in [2, 3, 4]:
            h = rows * 32 + 64
            p = add(f"tree_{species}_{rows}", Pixels(96, h), trunk_tiles=[1, 2], canopy_tiles=[3, rows])
            rng = random.Random(rows + len(species) * 17)
            p.oval(49, h - 6, 36, 6, "263f3544")
            p.box(37, h - 68, 23, 63, "d0c6a1" if species == "birch" else "68543d")
            p.box(39, h - 65, 7, 58, "f0daba" if species == "birch" else "a3824e")
            p.box(52, h - 63, 5, 59, "6b7058" if species == "birch" else "4e4935")
            for y in range(h - 61, h - 8, 7):
                p.box(rng.randrange(38, 51), y, rng.randrange(4, 10), 2, "5c6657" if species == "birch" else "84633e")
            p.polygon([(37, h - 18), (29, h - 3), (47, h - 7), (65, h - 3), (59, h - 20)], "6f5e40")
            canopy_h = rows * 32
            if species == "pine":
                for y in range(4, canopy_h, 9):
                    half = min(43, 7 + y * 38 // canopy_h)
                    p.polygon([(48, max(0, y - 17)), (48 - half, y + 10), (48 + half, y + 10)], "315647")
                    p.polygon([(48, max(0, y - 15)), (48 - half + 4, y + 4), (49, y + 1)], "66865b")
            else:
                for cx, cy, rx, ry in [(30, canopy_h // 2, 27, canopy_h // 2 - 4), (62, canopy_h // 2, 28, canopy_h // 2 - 3), (46, canopy_h // 3, 28, canopy_h // 3), (47, canopy_h - 20, 36, 20)]:
                    p.oval(cx, cy, rx, ry, "375b42")
                    p.oval(cx - 2, cy - 5, rx - 3, ry - 5, "607f49" if species == "oak" else "6d8a4d")
            for _ in range(rows * 130):
                x, y = rng.randrange(5, 91), rng.randrange(3, canopy_h + 8)
                if p.data[(min(y, h - 1) * 96 + x) * 4 + 3] == 0: continue
                if species == "pine" and abs(x - 48) > 6 + y * 42 // canopy_h: continue
                p.box(x, y, rng.choice([1, 2, 3]), 1, rng.choice(["9caf64", "78994f", "527645", "335942"]))
    for variant in range(4):
        p = add("bush" + str(variant), Pixels(64, 48))
        p.oval(32, 41, 29, 5, "30463344")
        for x, y in [(17, 27), (32, 18), (46, 28)]:
            p.oval(x, y, 15, 15, "3e6040"); p.oval(x - 2, y - 4, 12, 11, "7d944e")
        p.grain(10, 12, 44, 24, ["8fa659", "5c7d45", "a5b46c"], variant, 130)
        if variant % 2:
            for x in [16, 27, 43]: p.box(x, 23 + x % 7, 2, 2, "c1958c")


def furniture(kind, w, h):
    p = add(f"furniture_{kind}_{w}x{h}", Pixels(w * 32 + 8, h * 32 + 40))
    width, depth = w * 32, h * 32
    x, y = 4, 24
    wood, light, dark = "a08158", "c6a778", "5b4b37"
    if kind == "rug":
        p.box(x, y, width, depth, "685e65"); p.box(x + 3, y + 3, width - 6, depth - 6, "a58b7a")
        for xx in range(x + 8, width, 12):
            for yy in range(y + 8, y + depth - 5, 12): p.polygon([(xx, yy - 3), (xx + 4, yy), (xx, yy + 3), (xx - 4, yy)], "c1ae88")
        return
    if kind in ["bed", "sofa"]:
        p.box(x, y - 14, width, depth + 15, dark)
        p.box(x + 2, y - 12, width - 4, 8, wood)
        p.box(x + 3, y, width - 6, depth - 5, "e0d7b6" if kind == "bed" else "5d7b71")
        if kind == "bed":
            p.box(x + 7, y + 4, width - 14, 14, "eee2c1")
            p.box(x + 8, y + 18, width - 16, 2, "b9ae96")
            p.box(x + 5, y + 25, width - 10, max(3, depth - 32), "6e9190")
            for yy in range(y + 29, y + depth - 8, 8): p.box(x + 7, yy, width - 14, 2, "92b0a4")
        else:
            p.box(x + 7, y - 8, width - 14, 17, "9aaf92")
            for xx in range(x + 11, width - 10, 27):
                p.box(xx, y + 11, 23, max(6, depth - 19), "8da588")
                p.box(xx + 2, y + 12, 19, 1, "b9c3a1")
            for xx in [x, x + width - 8]: p.box(xx, y + 3, 8, depth - 6, "708c79")
        p.box(x + width - 5, y + 4, 3, depth - 4, "426965")
    elif kind in ["table", "chair", "desk", "counter"]:
        for xx in [x + 5, x + width - 9]: p.box(xx, y + 5, 4, depth + 9, dark)
        p.box(x + 2, y, width - 4, depth, dark); p.box(x + 2, y - 7, width - 4, depth, wood)
        p.box(x + 4, y - 6, width - 8, 2, light)
        p.grain(x + 6, y, max(1, width - 14), max(1, depth - 12), [light, "8d6b4b"], width + depth, width)
        if kind == "chair": p.box(x + 2, y - 20, width - 4, 16, wood); p.box(x + 4, y - 18, width - 8, 2, light)
        if kind == "table":
            p.oval(x + width // 2, y + depth // 2 - 5, 9, 5, "dbd6b8")
            p.oval(x + width // 2, y + depth // 2 - 6, 6, 3, "bea783")
        if kind == "desk":
            p.box(x + 9, y + 2, 20, 12, "e2dbc1")
            for yy in range(y + 5, y + 13, 3): p.box(x + 12, yy, 13, 1, "879788")
            p.box(x + width - 16, y, 3, 10, "465a56")
    elif kind in ["bookshelf", "stock", "cabinet", "crates", "tools", "seed_tray"]:
        p.box(x, y - 16, width, depth + 17, dark); p.box(x + 2, y - 14, width - 4, depth + 13, wood)
        for yy in range(y - 10, y + depth - 4, 23):
            p.box(x + 4, yy, width - 8, 19, "635b46")
            if kind == "bookshelf":
                for xx in range(x + 6, x + width - 9, 7):
                    color = ["b7a779", "78938b", "9a7968", "a3a68b"][(xx + yy) % 4]
                    p.box(xx, yy + 2, 5, 15, color); p.box(xx, yy + 3, 4, 1, "d9cfad")
                    for n in range(2): p.box(xx + 1, yy + 7 + n * 3, 2 + (xx + n) % 2, 1, "e0d7bc")
            elif kind == "cabinet":
                p.box(x + 5, yy + 2, width - 10, 16, "b39a71")
                for xx in range(x + 8, x + width - 7, 24): p.box(xx, yy + 8, 4, 2, "e2ce96")
            else:
                for xx in range(x + 7, x + width - 5, 13):
                    p.box(xx, yy + 6, 8, 11, "92a37a" if kind == "seed_tray" else "bea174")
                    p.box(xx + 1, yy + 4, 5, 3, "647957")
            p.box(x + 2, yy + 19, width - 4, 3, light)
    elif kind == "kitchen":
        p.box(x, y, width, depth, "7b8272"); p.box(x, y - 7, width, 10, "e1d9b9")
        for xx in range(x + 3, x + width - 8, 27):
            p.box(xx, y + 7, 23, depth - 12, "c0b290"); p.box(xx + 15, y + 12, 4, 2, "686f61")
        for xx in [x + 12, x + 30]: p.oval(xx, y - 2, 6, 4, "364b4b")
        p.oval(x + width - 17, y - 2, 11, 6, "758f8a"); p.oval(x + width - 17, y - 3, 8, 3, "a7b9a6")
        p.box(x + width - 17, y - 17, 2, 14, "cad1b7")
    elif kind in ["bath", "sink", "toilet"]:
        p.box(x + 3, y - 4, width - 6, depth + 5, "718b89")
        p.oval(x + width // 2, y + depth // 2 - 3, width // 2 - 3, depth // 2, "e4e1c9")
        p.oval(x + width // 2, y + depth // 2 - 5, max(3, width // 2 - 8), max(4, depth // 2 - 7), "7f9b96")
        p.oval(x + width // 2 - 1, y + depth // 2 - 6, max(2, width // 2 - 11), max(3, depth // 2 - 10), "c2d0b7")
        if kind == "toilet": p.box(x + 6, y - 14, width - 12, 17, "d9ddc5"); p.box(x + 8, y - 12, width - 16, 2, "f3ecd0")
        else: p.box(x + width // 2, y - 14, 2, 15, "d5ddc7")
    elif kind in ["reactor", "machine", "console", "radio"]:
        p.box(x, y - 16, width, depth + 16, "2e414b"); p.box(x + 3, y - 18, width - 6, 5, "aab7b3")
        p.box(x + 4, y - 11, width - 12, depth + 5, "647e83" if kind != "radio" else "94734b")
        if kind == "radio":
            p.box(x + 8, y - 7, max(8, width - 16), 12, "263f44")
            for xx in range(x + 8, x + width - 8, 6): p.box(xx, y + 10, 2, max(3, depth - 17), "4f5949")
        else:
            for xx in range(x + 8, x + width - 8, 10): p.box(xx, y + 7, 3, max(2, depth - 15), "3c535e")
    elif kind in ["art", "telescope", "plant"]:
        if kind == "art":
            p.box(x, y - 14, width, max(18, depth), wood)
            p.box(x + 3, y - 11, width - 6, max(12, depth - 6), "91aaa0")
            p.polygon([(x + 4, y + 8), (x + width // 2, y - 7), (x + width - 4, y + 8)], "53796b")
        elif kind == "plant":
            p.box(x + 8, y + 4, 17, depth - 1, "99704a")
            for dx, dy in [(6, -3), (20, -8), (14, -15)]: p.oval(x + dx, y + dy, 7, 10, "789553")
        else:
            for dx in [-8, 8]: p.polygon([(x + 16, y), (x + 16 + dx, y + depth), (x + 19 + dx, y + depth)], "ad9c74")
            p.polygon([(x + 4, y - 16), (x + 30, y - 4), (x + 24, y + 7), (x - 2, y - 6)], "91aaa9")
    p.box(x + width - 2, y + 4, 2, max(1, depth - 4), "45584c")
    if kind in ["bed", "sofa", "radio"]:
        cloth = add(f"cover_{w}x{h}", Pixels(width + 8, depth + 40))
        cloth.polygon([(2, 13), (width, 16), (width + 6, depth + 34), (1, depth + 32)], "b6b39c")
        for xx in range(8, width, 13):
            cloth.box(xx, 20, 2, depth + 10, "8e988b"); cloth.box(xx + 3, 22, 2, depth + 7, "d0c9ad")
        cloth.grain(6, 24, max(1, width - 8), depth, ["a3a892", "c4bfa5"], width + depth, 35)


def props():
    for ore in [False, True]:
        p = add("copper" if ore else "rock", Pixels(32, 48))
        p.oval(17, 42, 15, 5, "1f323855")
        p.polygon([(2, 34), (5, 15), (15, 6), (27, 17), (30, 35), (19, 43), (6, 41)], "65747a")
        p.polygon([(5, 15), (15, 6), (27, 17), (17, 24)], "a0a79e")
        p.grain(7, 21, 18, 15, ["75878a", "53686c", "89988e"], int(ore), 40)
        if ore:
            for x, y in [(7, 22), (18, 28), (22, 18)]:
                p.box(x, y, 5, 5, "9c6848"); p.box(x, y, 4, 2, "e1ad6b"); p.dot(x, y, "f2d09b")
    for kind in ["barrel", "chest", "cart", "sign", "lamp", "fountain", "chrysalis", "sparkfire", "sparkfire_bloom"]:
        w, h = {"cart": (96, 64), "fountain": (64, 80), "lamp": (32, 96), "sign": (64, 64)}.get(kind, (32, 48))
        p = add(kind, Pixels(w, h))
        if kind in ["barrel", "chest", "cart"]:
            p.box(3, h - 33, w - 6, 27, "644e35"); p.box(4, h - 39, w - 8, 27, "aa8753")
            for x in range(7, w - 5, 7): p.box(x, h - 35, 1, 24, "785c3d")
            for y in [h - 31, h - 13]: p.box(2, y, w - 4, 3, "60777a")
            if kind == "barrel": p.oval(w // 2, h - 38, w // 2 - 3, 5, "c2a06c")
            if kind == "chest": p.box(14, h - 23, 5, 7, "dfc48a")
            if kind == "cart":
                for x in [14, 74]: p.oval(x, h - 7, 7, 7, "3d4943"); p.oval(x, h - 7, 3, 3, "bba473")
                for x in range(9, 85, 15): p.oval(x, h - 42, 6, 6, "b8ab64" if x % 2 else "bf8661")
        elif kind == "lamp":
            p.box(15, 10, 4, 82, "586453"); p.box(9, 12, 17, 23, "434e45"); p.box(12, 15, 11, 15, "ead89a")
            p.box(7, 9, 21, 4, "7c8067")
        elif kind == "sign":
            p.box(30, 16, 5, 46, "755d3f")
            for y in [12, 31]: p.box(3, y, 58, 14, "b29b69"); p.box(5, y + 1, 54, 1, "dbc18a")
            for x in range(11, 48, 5): p.box(x, 18, 3, 2, "5e654a"); p.box(x, 36, 2, 2, "5e654a")
        elif kind == "fountain":
            p.oval(32, 57, 31, 18, "606f6d"); p.oval(32, 51, 29, 15, "a8ada0")
            p.oval(32, 50, 24, 11, "6e9c9d"); p.box(29, 16, 7, 35, "c2c5b0")
            p.oval(32, 18, 15, 6, "d9d2b6"); p.oval(32, 17, 10, 3, "83acac")
        elif kind == "chrysalis":
            p.box(15, 2, 1, 16, "97b2a5"); p.oval(16, 27, 5, 11, "9fbeb3")
            for y in range(20, 36, 4): p.box(13, y, 6, 1, "608b91")
        else:
            p.box(15, 22, 2, 20, "577343")
            for x, y in [(8, 29), (23, 33)]: p.oval(x, y, 7, 3, "91a55c")
            if kind.endswith("bloom"):
                for i in range(6): p.oval(16 + round(math.cos(i * math.tau / 6) * 6), 18 + round(math.sin(i * math.tau / 6) * 6), 4, 4, "e7bc50")
                p.oval(16, 18, 3, 3, "fff1af")
    for frame in range(3):
        p = add("rat" + str(frame), Pixels(32, 32))
        p.oval(17, 25, 12, 4, "25363a55"); p.box(0, 21, 10, 2, "c89b96")
        p.oval(17, 18, 10, 7, "8d8d85"); p.oval(25, 16, 5, 5, "b8ad9b")
        p.oval(23, 10, 4, 4, "bba6a0"); p.oval(23, 10, 2, 2, "d4b4ac")
        p.dot(28, 15, "17252c"); p.box(12, 24 + frame % 2, 4, 2, "c2b19a"); p.box(23, 24 - frame % 2, 4, 2, "c2b19a")
    for frame in range(5):
        for kind in ["console", "reactor", "machine"]:
            p = add(f"display_{kind}{frame}", Pixels(64, 32))
            p.box(2, 2, 60, 26, "1d3541")
            for y in range(5, 26, 4):
                for x in range(6, 58, 4):
                    color = "b8c9bf" if frame == 4 else "74b8b0" if (x + y + frame) % 7 else "d5bf7c"
                    if frame == 4 or (x + frame * 3) % 13 > 2: p.box(x, y, 2, 1, color)


def actors():
    palettes = {"player": ("6f9793", "5c5045", "d0a981"), "moss": ("a7834d", "d6cb9c", "d4a776"), "tavi": ("aa7262", "bd996b", "c0a070"), "iona": ("8885ad", "e3d7bd", "ae856c"), "finch": ("6d96a0", "765842", "d3ab88"), "vale": ("8b9baf", "b5a68e", "a97959"), "mayor": ("657b70", "c2c4b0", "d0a181"), "veteran": ("777a60", "b9b6a3", "b08f77"), "assistant": ("61758a", "c7cbcd", "65566d")}
    for name, (coat, hair, skin) in palettes.items():
        for direction in ["down", "up", "left", "right", "sleep"]:
            for frame in range(3 if direction != "sleep" else 1):
                p = add(f"actor_{name}_{direction}{frame}", Pixels(32, 64))
                p.oval(16, 60, 11, 3, "20383244")
                if direction == "sleep":
                    p.box(8, 12, 16, 16, skin); p.box(7, 10, 18, 6, hair)
                    p.box(10, 22, 4, 1, "51584c"); p.box(19, 22, 4, 1, "51584c")
                    continue
                step = [0, 2, -2][frame]
                for x, offset in [(10, step), (19, -step)]:
                    p.box(x, 43, 5, 15 + offset, "354c50"); p.box(x - 1, 55 + offset, 7, 4, "41473e")
                p.box(7, 28, 19, 19, coat); p.box(8, 29, 2, 14, "a4b6a0")
                p.box(5, 31 + step // 2, 4, 13, coat); p.box(24, 31 - step // 2, 4, 13, coat)
                p.box(5, 44 + step // 2, 4, 4, skin); p.box(24, 44 - step // 2, 4, 4, skin)
                p.box(9, 12, 15, 17, skin); p.box(8, 10, 17, 7, hair)
                p.box(8, 15, 3, 6, hair); p.box(21, 15, 3, 4, hair)
                if direction != "up":
                    for x in ([11, 19] if direction == "down" else [10] if direction == "left" else [21]):
                        p.box(x, 20, 2, 2, "2c4645"); p.dot(x, 19, "eee4c8")
                    p.box(15, 25, 4, 1, "b0806a")
                else: p.box(9, 15, 15, 11, hair)
                if name == "moss": p.box(4, 11, 26, 4, "9a915b"); p.box(9, 5, 15, 7, "b9ae70")
                if name in ["assistant", "tavi"]:
                    p.polygon([(6, 16), (9, 21), (11, 18)], skin); p.polygon([(23, 18), (26, 16), (25, 22)], skin)


def effects_and_ships():
    p = add("planet", Pixels(192, 192))
    for y in range(192):
        for x in range(192):
            nx, ny = (x - 96) / 94, (y - 96) / 94
            radius = nx * nx + ny * ny
            if radius > 1: continue
            if radius > .95: p.dot(x, y, "b0d3ce"); continue
            z = math.sqrt(1 - radius)
            land = math.sin(nx * 12 + math.sin(ny * 7) * 2) + math.cos(ny * 15 - nx * 6) * .6 > .1
            color = (116, 148, 90) if land else (65, 114, 132)
            if math.sin(ny * 30 + nx * 7) + math.sin(nx * 16) > 1.25: color = (200, 213, 185)
            shade = .4 + .6 * max(0, z * .8 - nx * .4 - ny * .2)
            p.dot(x, y, tuple(int(channel * shade) for channel in color) + (255,))
    p = add("particle", Pixels(3, 3)); p.box(0, 0, 3, 3, "ffffff")
    p = add("firefly", Pixels(8, 8)); p.oval(4, 4, 3, 3, "ecdb8744"); p.box(3, 3, 2, 2, "fff0b6")
    p = add("ripple", Pixels(16, 4)); p.box(2, 1, 11, 1, "b2d1c566"); p.box(0, 2, 3, 1, "b2d1c533")
    p = add("cable", Pixels(32, 64))
    for y in range(64):
        x = 10 + round(math.sin(y * .1) * 4)
        p.box(x, y, 4, 1, "213641"); p.box(x + 4, y, 1, 1, "b08c5a")
    for frame in range(3):
        p = add("bird" + str(frame), Pixels(16, 16))
        p.box(7, 8, 3, 3, "e8d9ac")
        for x in range(1, 15): p.box(x, 7 + abs(x - 8) * (frame - 1) // 3, 2, 1, "c4c6a3")
    for frame in range(6):
        p = add("explosion" + str(frame), Pixels(96, 96))
        rng = random.Random(frame)
        for i in range(18):
            angle = i * math.tau / 18
            radius = 7 + frame * 6
            x, y = 48 + math.cos(angle) * radius, 48 + math.sin(angle) * radius
            p.oval(x, y, max(2, 12 - frame), max(2, 10 - frame), rng.choice(["c78250", "e8b569", "f5db9a"]))
            if frame > 2 and i % 3 == 0: p.box(x, y, 4, 3, "796f69")
        p.oval(48, 48, max(2, 24 - frame * 4), max(2, 21 - frame * 3), "fff2bd")
        p = add("spark" + str(frame), Pixels(16, 16))
        for x, y in [(7, 7), (4, 6 - frame % 3), (10 + frame % 3, 5), (8, 11)]: p.box(x, y, 2, 2, "f2d58e")
    for name, color in [("bolt_friendly", "90d3dd"), ("bolt_enemy", "ed9b8e")]:
        p = add(name, Pixels(32, 8)); p.box(1, 2, 28, 4, color); p.box(6, 3, 24, 2, "fff1cb")
    for hostile in [False, True]:
        p = add("ship_enemy" if hostile else "ship_crew", Pixels(192, 96))
        p.polygon([(8, 18), (78, 26), (181, 48), (78, 69), (8, 77), (37, 48)], "736a7c" if hostile else "9eb3b3")
        p.polygon([(15, 23), (78, 30), (154, 47), (52, 46)], "a29da0" if hostile else "d5ddcc")
        for y in [8, 75]:
            p.box(4, y, 70, 11, "4b5d70"); p.box(4, y + 2, 8, 6, "a1d9df")
        p.box(110, 43, 23, 8, "406d80")
        p.grain(45, 35, 60, 25, ["7e959b", "d4d8bb"], int(hostile), 70)
        for x in range(44, 104, 9): p.box(x, 47, 3, 2, "efd4a0")
    p = add("bridge", Pixels(320, 155))
    p.box(0, 0, 320, 155, "253e4b"); p.polygon([(20, 132), (60, 40), (260, 40), (300, 132)], "71858a")
    p.box(30, 25, 260, 44, "a0afaa"); p.box(39, 30, 243, 32, "1a3348")
    p.grain(40, 31, 237, 28, ["a3c1c2", "6c909f"], 5, 35)
    for x in [95, 160, 225]: p.box(x, 30, 2, 32, "a7b7ac")
    for x in [48, 214]:
        p.box(x, 85, 57, 40, "334d5b"); p.box(x + 4, 88, 48, 16, "183c4d")
        for y in [91, 95, 99]: p.box(x + 7, y, 39, 1, "8ac4ba")
    p.box(146, 87, 28, 37, "3c565f"); p.box(149, 89, 22, 23, "749994")
    p.box(155, 80, 9, 11, "d0a981"); p.box(154, 79, 11, 4, "5c5045")
    p.box(153, 91, 14, 13, "6f9793"); p.box(145, 101, 6, 14, "a7b4a8"); p.box(170, 101, 6, 14, "a7b4a8")
    p.box(154, 104, 5, 16, "344a50"); p.box(162, 104, 5, 16, "344a50")


def item_icons():
    source = (ROOT / "src/native/items.gd").read_text()
    names = re.findall(r'^\t"(\w+)":\{"name"', source, re.MULTILINE)
    for name in names:
        p = add("item_" + name, Pixels(24, 24))
        if name in ["hoe", "pickaxe", "sickle", "rusty_sword"]:
            for i in range(4, 21): p.box(i, 24 - i, 2, 2, "aa8856")
            if name == "rusty_sword":
                for i in range(9, 22): p.box(i, 23 - i, 3, 2, "bbc6ba"); p.dot(i, 23 - i, "e1ddc3")
                p.polygon([(5, 11), (14, 20), (12, 22), (3, 13)], "bea16b")
            elif name == "sickle":
                p.oval(15, 8, 7, 7, "c4d0c5")
                p.oval(12, 7, 6, 5, "00000000")
                p.box(8, 12, 7, 2, "dce0c9")
            elif name == "pickaxe":
                p.polygon([(5, 7), (11, 2), (18, 3), (23, 10), (17, 6), (11, 5)], "a8b9b5")
            else:
                p.box(15, 3, 6, 9, "92a7a8"); p.box(15, 3, 5, 2, "d2d8c0")
        elif name in ["seeds", "star_seeds", "rations"]:
            p.box(4, 4, 16, 18, "8c734e"); p.box(5, 3, 13, 18, "c6ab77")
            p.box(7, 7, 9, 10, "87946d" if name != "star_seeds" else "8c85a0")
            p.oval(11, 12, 3, 3, "e5d7ac"); p.box(5, 3, 14, 2, "e1ca93")
        elif name in ["fish", "moon_pike", "sea_sprat", "blue_mackerel", "storm_eel", "fish_sticks"]:
            p.oval(11, 12, 8, 4, "a8bcad"); p.polygon([(17, 12), (22, 7), (22, 17)], "7f9da4")
            p.box(6, 10, 11, 1, "d6dbc1"); p.dot(5, 11, "283c3f")
            if name == "fish_sticks":
                for y in [5, 11, 17]: p.box(3, y, 18, 4, "c29a54"); p.box(4, y, 16, 1, "e5c87a")
        elif name in ["turnips", "star_bulbs", "golden_sparkfire_bloom", "star_seeds"]:
            p.oval(12, 15, 7, 6, "ddd2b0" if name == "turnips" else "e2c36a")
            p.box(11, 5, 2, 11, "668a4d"); p.oval(7, 7, 5, 2, "92ab5e"); p.oval(16, 5, 4, 2, "a6ba70")
        elif name in ["pot", "pan", "fish_stew", "watering_can"]:
            p.box(9, 2, 3, 11, "8d7854")
            p.oval(12, 14, 9, 6, "4b646d"); p.oval(11, 12, 8, 4, "b3c0b5")
            p.oval(11, 12, 6, 2, "a68b5e" if name == "fish_stew" else "6d8c8c")
            if name == "watering_can": p.polygon([(17, 12), (23, 7), (21, 14)], "91b2ae")
        elif name in ["health_elixir", "light_bulbs", "cave_moth_chrysalis"]:
            p.oval(12, 13, 6, 8, "b9c8b5" if name != "health_elixir" else "ad706b")
            p.box(9, 2, 6, 4, "c7ba8c"); p.box(9, 9, 2, 7, "e3dfc7")
        else:
            p.polygon([(3, 15), (7, 5), (15, 3), (22, 12), (18, 21), (7, 22)], "75858a")
            p.polygon([(7, 5), (15, 3), (20, 10), (10, 12)], "adb4a4")
            if name == "copper":
                for x, y in [(7, 9), (13, 16), (17, 10)]: p.box(x, y, 4, 3, "d2a367")


def main():
    argparse.ArgumentParser(description=__doc__).parse_args()
    terrain(); buildings(); trees_and_bushes(); props(); actors(); effects_and_ships(); item_icons()
    source = (ROOT / "src/native/interior_layouts.gd").read_text()
    kinds = {"rug", "bed", "sofa", "table", "chair", "desk", "counter", "bookshelf", "stock", "cabinet", "crates", "tools", "seed_tray", "kitchen", "bath", "sink", "toilet", "reactor", "machine", "console", "radio", "art", "telescope", "plant"}
    sizes = {(kind, int(w), int(h)) for kind, w, h in re.findall(r'\["(\w+)",Rect2i\([^,]+,[^,]+,(\d+),(\d+)\)\]', source) if kind in kinds and (kind != "kitchen" or h == "1")}
    for kind, w, h in sorted(sizes): furniture(kind, w, h)
    for crop in ["soil", "tilled", "wet", "sprout", "turnip", "bulb", "sprout_wet", "turnip_wet", "bulb_wet"]:
        p = add("crop_" + crop, Pixels(32, 32))
        p.box(2, 6, 28, 23, "57422f" if crop == "wet" or crop.endswith("_wet") else "8b6947")
        crop = crop.removesuffix("_wet")
        for x in [5, 12, 19, 26]: p.box(x, 8, 1, 18, "a08155" if crop == "soil" else "564b39")
        if crop in ["sprout", "turnip", "bulb"]:
            p.oval(16, 18, 7 if crop != "sprout" else 3, 5, "e3d5b2" if crop == "turnip" else "e8d784" if crop == "bulb" else "79a05b")
            p.box(15, 7, 2, 12, "4e753f"); p.oval(10, 9, 5, 3, "89a553"); p.oval(21, 6, 5, 3, "a4b867")
    width, x, y, row = 2048, 1, 1, 0
    manifest = {}
    for name, (image, metadata) in ASSETS.items():
        if x + image.w + 1 > width: x, y, row = 1, y + row + 2, 0
        manifest[name] = dict(rect=[x, y, image.w, image.h], **metadata)
        x += image.w + 2
        row = max(row, image.h)
    atlas = Pixels(width, y + row + 1)
    for name, (image, _) in ASSETS.items(): atlas.copy(image, *manifest[name]["rect"][:2])
    destination = ROOT / "src/native/art/option2"
    destination.mkdir(parents=True, exist_ok=True)
    atlas.png(destination / "sprites.png")
    (destination / "sprites.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Built {len(manifest)} pixel sprites in {atlas.w} x {atlas.h} atlas: {destination.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
