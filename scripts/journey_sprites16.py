#!/usr/bin/env python3
"""Revised calendar ring, ship fixtures, temple altar, status icons, sparkbloom and baking items for the rustic16 pack.

sprites(P) returns {sprite_id: image} at 16 pixels per cell.
"""
import math
import pathlib
import random
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import calendar_sprites16 as cal  # noqa: E402

METAL = ["1e1a2a", "2e2c3a", "474a58", "646a78", "8a92a0", "b8c0c8"]
METAL_FRONT = ["1a1626", "28263a", "3a3c4c", "525868", "6e7686", "9aa2ae"]
STONE = ["241c2e", "3e3448", "5e5866", "827c86", "a8a2a8", "d0cac8"]
STONE_FRONT = ["1e1828", "342c40", "4c4656", "686270", "868090", "aaa4aa"]
RUST = ["4a2a2a", "6a3a2e", "8a5034"]
SHADOW = "24143a60"
OUT = "1a1222"

DAYS = [("Rift", ["4a1e6a", "8a3ec0", "f0c8ff"],
         ["######.", "#....#.", "#.##.#.", "#.#..#.", "#.####.", "#......", "#######"]),
        ("Bough", ["2e5a26", "5a9a3a", "d8f0a0"],
         ["....###", "..#####", ".###.##", ".##.###", "##.###.", ".#.##..", "#......"]),
        ("Ember", ["8a3a12", "e07a24", "ffe08a"],
         ["...#...", "..##...", "..###..", ".#####.", ".##.##.", ".#...#.", "..###.."]),
        ("Gale", ["4a8a98", "9ad8e0", "f4ffff"],
         ["..##...", ".###.#.", "..#.##.", ".##.#..", "..#.##.", "..#....", ".#....."]),
        ("Tide", ["1a3a7a", "3a6ac8", "c8e0ff"],
         [".......", ".##....", "#..#..#", "....##.", ".##....", "#..#..#", "....##."]),
        ("Gleam", ["8a6a10", "e0b830", "fff8c0"],
         ["#..#..#", ".#.#.#.", "..###..", "#######", "..###..", ".#.#.#.", "#..#..#"]),
        ("Veil", ["1a1440", "3a2a78", "c8c0ff"],
         ["..###..", ".##..#.", "##....#", "##....#", "##....#", ".##..#.", "..###.."])]


def calendar_rings(P):
    out, saved = {}, cal.DAYS
    try:
        cal.DAYS = [DAYS[0], *reversed(DAYS[1:])]
        for k in range(7):
            out[f"calendar_ring{k}"] = cal.conv(P, cal.ring(-k))
    finally:
        cal.DAYS = saved
    return out


def panel(p, x, y, w, h, r):
    p.box(x, y, w, h, r[0])
    p.box(x + 1, y + 1, w - 2, h - 2, r[2])
    p.line(x + 1, y + h - 2, x + w - 2, y + h - 2, r[1])
    p.line(x + w - 2, y + 1, x + w - 2, y + h - 2, r[1])
    p.line(x + 1, y + 1, x + w - 2, y + 1, r[4])
    p.line(x + 1, y + 1, x + 1, y + h - 2, r[3])


def rivet(p, x, y, r):
    p.dot(x, y, r[5])
    p.dot(x + 1, y + 1, r[0])


def grime(p, x, y, w, h, seed, n, cols):
    rnd = random.Random(seed)
    for _ in range(n):
        gx, gy = x + rnd.randrange(w), y + rnd.randrange(h)
        c = rnd.choice(cols)
        p.dot(gx, gy, c)
        if rnd.random() < 0.5:
            p.dot(gx + 1, gy, c)


# ------------------------------------------------------------------ ship
def ship_bunk(P):
    p = P(36, 68)
    p.oval(18, 64, 16, 3, SHADOW)
    for lx in (3, 29):
        p.box(lx, 58, 4, 8, METAL[0])
        p.box(lx + 1, 58, 2, 7, METAL[2])
    panel(p, 2, 2, 32, 44, METAL)
    p.box(5, 6, 26, 37, METAL[1])
    # mattress and pillow (head at top)
    p.box(6, 6, 24, 36, "4a4e5e")
    p.box(8, 8, 20, 7, "6a6478")
    p.box(9, 8, 18, 6, "c8ccd8")
    p.line(9, 8, 26, 8, "e8ecf2")
    p.line(9, 13, 26, 13, "9a9cb0")
    p.dot(17, 10, "a8acc0"); p.dot(18, 11, "a8acc0")
    # blanket, folded band at its head, foot at bottom
    p.box(6, 17, 24, 25, "3a5a6a")
    p.box(6, 17, 24, 3, "6a8a96")
    p.line(6, 17, 29, 17, "8aa8b2")
    p.line(29, 20, 29, 41, "2a3e4e")
    for cy in (25, 33):
        p.line(9, cy, 16, cy + 1, "2e4a5a")
        p.line(19, cy + 2, 26, cy + 1, "4e7080")
    # head and foot rails
    p.box(2, 2, 32, 3, METAL[3]); p.line(2, 2, 33, 2, METAL[5]); p.line(2, 4, 33, 4, METAL[1])
    p.box(2, 42, 32, 3, METAL[3]); p.line(2, 42, 33, 42, METAL[4]); p.line(2, 44, 33, 44, METAL[1])
    for rx, ry in ((3, 3), (31, 3), (3, 43), (31, 43)):
        rivet(p, rx, ry, METAL)
    # front face
    panel(p, 2, 46, 32, 13, METAL_FRONT)
    for vy in (49, 52, 55):
        p.line(9, vy, 26, vy, METAL_FRONT[0])
        p.line(9, vy + 1, 26, vy + 1, METAL_FRONT[4])
    for rx in (4, 30):
        rivet(p, rx, 48, METAL_FRONT); rivet(p, rx, 55, METAL_FRONT)
    p.box(28, 47, 4, 2, "c8a030"); p.dot(29, 47, OUT); p.dot(31, 48, OUT)
    grime(p, 4, 47, 28, 10, 11, 9, RUST)
    grime(p, 3, 5, 30, 38, 12, 6, [METAL[1], METAL[2]])
    return p


def ship_locker(P):
    p = P(52, 36)
    p.oval(26, 33, 25, 3, SHADOW)
    panel(p, 2, 2, 48, 12, METAL)
    p.line(4, 7, 47, 7, METAL[1]); p.line(4, 8, 47, 8, METAL[3])
    for rx in (4, 46):
        rivet(p, rx, 4, METAL); rivet(p, rx, 10, METAL)
    grime(p, 6, 4, 38, 8, 21, 7, RUST + [METAL[1]])
    panel(p, 2, 13, 48, 20, METAL_FRONT)
    tags = ("d8a030", "3ac8c0", "c84040")
    for i in range(3):
        x0 = 4 + i * 15
        p.box(x0, 15, 14, 16, METAL_FRONT[0])
        p.box(x0 + 1, 16, 12, 14, METAL_FRONT[2])
        p.line(x0 + 1, 16, x0 + 12, 16, METAL_FRONT[4])
        p.line(x0 + 1, 16, x0 + 1, 29, METAL_FRONT[3])
        p.line(x0 + 12, 17, x0 + 12, 29, METAL_FRONT[1])
        for vy in (18, 20, 22):
            p.line(x0 + 3, vy, x0 + 9, vy, METAL_FRONT[0])
            p.line(x0 + 3, vy + 1, x0 + 9, vy + 1, METAL_FRONT[4])
        p.box(x0 + 10, 24, 2, 4, METAL_FRONT[1])
        p.dot(x0 + 10, 24, METAL_FRONT[5]); p.dot(x0 + 10, 25, METAL_FRONT[4])
        p.box(x0 + 3, 26, 4, 2, tags[i]); p.dot(x0 + 6, 27, OUT)
    # dent on middle door and rust streaks
    p.oval(24, 26, 2, 1.5, METAL_FRONT[1]); p.dot(23, 25, METAL_FRONT[4])
    p.line(39, 29, 39, 31, RUST[1]); p.line(8, 30, 8, 31, RUST[0])
    grime(p, 4, 15, 44, 15, 22, 10, RUST)
    p.line(2, 32, 49, 32, OUT)
    return p


def ship_table(P):
    p = P(36, 36)
    p.oval(18, 33, 16, 2.5, SHADOW)
    for lx in (4, 28):
        p.box(lx, 22, 4, 11, METAL[0])
        p.box(lx + 1, 22, 2, 10, METAL[2]); p.line(lx + 1, 22, lx + 1, 31, METAL[3])
    p.line(8, 28, 27, 28, METAL[1]); p.line(8, 27, 27, 27, METAL[3])
    panel(p, 2, 3, 32, 18, METAL)
    p.line(18, 5, 18, 18, METAL[1]); p.line(19, 5, 19, 18, METAL[3])
    panel(p, 2, 19, 32, 4, METAL_FRONT)
    for rx in (4, 30):
        rivet(p, rx, 5, METAL); rivet(p, rx, 17, METAL)
    # datapad
    p.box(6, 6, 9, 7, OUT); p.box(7, 7, 7, 4, "1e6a70")
    p.line(8, 8, 11, 8, "a0fff0"); p.line(8, 9, 10, 9, "5ad8d0"); p.dot(12, 11, "ff5040")
    # mug
    p.oval(25, 8, 3, 2.5, METAL[0]); p.oval(25, 8, 2, 1.5, METAL[4]); p.dot(25, 8, "3a2420")
    p.dot(28, 9, METAL[3])
    # spanner
    p.line(21, 15, 28, 13, METAL[5]); p.line(21, 16, 28, 14, METAL[1])
    p.box(28, 12, 2, 3, METAL[4]); p.dot(29, 13, METAL[1])
    # power cell with led and cable
    p.box(7, 14, 6, 4, "5a5a3a"); p.line(7, 14, 12, 14, "8a8a5a"); p.dot(11, 15, "ff4040"); p.dot(9, 15, "40ff80")
    p.line(13, 16, 15, 17, OUT); p.line(15, 17, 17, 15, OUT)
    for bx, by in ((22, 10), (15, 6), (23, 17)):
        p.dot(bx, by, METAL[5]); p.dot(bx + 1, by, METAL[1])
    grime(p, 4, 5, 28, 13, 31, 5, RUST)
    return p


# ------------------------------------------------------------------ temple
def candle(p, x, top):
    p.oval(x + 1, top - 2, 2.5, 2.5, "ffe08a30")
    p.box(x, top, 3, 14 - top + 2, "f0e6d0")
    p.line(x + 2, top, x + 2, 15, "c8b8a0")
    p.dot(x, top, "fff8e8")
    p.dot(x + 1, top - 1, "e07a24"); p.dot(x + 1, top - 2, "ffd060"); p.dot(x + 1, top - 3, "fff4c0")
    p.dot(x + 1, 16, "8a7a60")


def temple_altar(P):
    p = P(52, 36)
    p.oval(26, 33, 25, 3, SHADOW)
    panel(p, 2, 6, 48, 12, STONE)
    panel(p, 2, 17, 48, 16, STONE_FRONT)
    for by in (21, 25, 29):
        p.line(3, by, 48, by, STONE_FRONT[1])
        off = 6 if by % 8 == 5 else 0
        for bx in range(8 + off, 48, 12):
            p.line(bx, by - 3, bx, by - 1, STONE_FRONT[1])
    grime(p, 4, 8, 44, 8, 41, 8, [STONE[1], STONE[4]])
    grime(p, 4, 19, 44, 12, 42, 8, [STONE_FRONT[1], "3a4a3a"])
    # cloth runner over top and front
    p.box(18, 6, 16, 26, "b8a888")
    p.box(19, 6, 14, 25, "e8dcc0")
    p.line(19, 6, 19, 30, "fff4dc")
    p.line(32, 7, 32, 30, "c8b898")
    p.line(19, 17, 32, 17, "c8b898")
    p.line(19, 30, 32, 30, "d8a830"); p.line(19, 31, 32, 31, "8a6a10")
    p.polygon([(22, 31), (30, 31), (26, 34)], "e8dcc0"); p.dot(26, 34, "d8a830")
    # sun emblem
    for a in range(8):
        t = a * math.tau / 8
        p.dot(round(26 + math.cos(t) * 5), round(24 + math.sin(t) * 4.5), "d8a830")
    p.oval(26, 24, 3, 3, "8a6a10"); p.oval(26, 24, 2.3, 2.3, "e0b830"); p.dot(25, 23, "fff8c0")
    # candles
    candle(p, 5, 7); candle(p, 10, 10); candle(p, 39, 10); candle(p, 44, 7)
    p.oval(26, 11, 3, 1.5, "8a6a10"); p.oval(26, 11, 2, 1, "e0b830")
    return p


# ------------------------------------------------------------------ status
def status_frame(p):
    p.box(0, 0, 16, 16, "140e1c")
    p.box(1, 1, 14, 14, "2a2038")
    p.line(1, 1, 14, 1, "463a58"); p.line(1, 1, 1, 14, "3a304a")
    p.line(2, 14, 14, 14, "1c1428"); p.line(14, 2, 14, 14, "1c1428")


def status_thirsty(P):
    p = P(16, 16)
    status_frame(p)
    p.polygon([(8, 2), (12, 9), (4, 9)], "0e2448")
    p.oval(8, 9.5, 4.5, 3.8, "0e2448")
    p.polygon([(8, 3), (11, 9), (5, 9)], "3a7ad8")
    p.oval(8, 9.5, 3.5, 2.8, "3a7ad8")
    p.oval(8.5, 10.5, 2.5, 1.8, "2a5ab0")
    p.dot(6, 8, "c8f0ff"); p.dot(6, 9, "c8f0ff"); p.dot(7, 6, "8ac8ff")
    p.dot(12, 3, "c84040"); p.dot(12, 4, "c84040"); p.dot(12, 6, "c84040")
    return p


def status_starving(P):
    p = P(16, 16)
    status_frame(p)
    p.polygon([(2, 8), (14, 8), (12, 13), (4, 13)], "4a2a1a")
    p.polygon([(3, 9), (13, 9), (11, 12), (5, 12)], "9a6438")
    p.line(4, 10, 6, 12, "c8905a")
    p.oval(8, 8, 6, 2, "4a2a1a")
    p.oval(8, 8, 5, 1.4, "c8905a")
    p.oval(8, 8.3, 4, 1, "2a1810")
    p.dot(10, 8, "6a4a30"); p.dot(5, 4, "c84040"); p.dot(5, 5, "c84040"); p.dot(5, 7, "c84040")
    p.line(10, 3, 12, 5, "8a92a0"); p.dot(13, 6, "b8c0c8")
    return p


# ------------------------------------------------------------------ sparkbloom
def bloom_head(p, cx, cy, r):
    pets = [(cx + math.cos(a * math.tau / 5 - math.pi / 2) * r, cy + math.sin(a * math.tau / 5 - math.pi / 2) * r)
            for a in range(5)]
    for px, py in pets:
        p.oval(px, py, 2.4, 2.4, "5a6a8a")
    for px, py in pets:
        p.oval(px, py, 1.7, 1.7, "c8d8f0")
        p.dot(round(px - 0.6), round(py - 0.6), "ffffff")
    p.oval(cx, cy, 1.6, 1.6, "4a2a7a")
    p.dot(cx, cy, "8a4ac8"); p.dot(cx - 1, cy - 1, "ffe060"); p.dot(cx + 1, cy, "fff8c0")


def winter_sparkbloom(P):
    p = P(16, 24)
    p.oval(8, 22.5, 5, 1.2, "8d98ab")
    p.oval(8, 22, 4, 1, "eef2f7")
    p.line(8, 22, 8, 11, "2e4a4a"); p.line(9, 21, 9, 13, "6a9a90")
    p.line(8, 18, 5, 15, "3a6a5a"); p.dot(5, 14, "b4d0d0")
    p.line(9, 16, 12, 14, "3a6a5a"); p.dot(12, 13, "b4d0d0")
    bloom_head(p, 8, 7, 3.2)
    for x, y, c in ((2, 2, "ffe8a0"), (13, 3, "c8a0ff"), (13, 11, "ffffff"), (2, 10, "c8a0ff"), (4, 0, "ffffff")):
        p.dot(x, y, c)
    return p


def item_winter_sparkbloom(P):
    p = P(16, 16)
    p.line(8, 15, 8, 10, "2e4a4a"); p.line(9, 14, 9, 11, "6a9a90")
    p.line(8, 13, 5, 12, "3a6a5a"); p.dot(4, 11, "b4d0d0")
    bloom_head(p, 8, 6, 3.4)
    p.dot(1, 2, "ffe8a0"); p.dot(14, 3, "c8a0ff"); p.dot(13, 12, "ffffff")
    return p


# ------------------------------------------------------------------ baking items
def item_berry_preserves(P):
    p = P(16, 16)
    p.box(3, 4, 10, 11, OUT)
    p.box(4, 5, 8, 9, "8a2040")
    p.line(11, 5, 11, 13, "5a1430"); p.line(5, 6, 5, 12, "e0a0c0")
    p.box(5, 9, 6, 3, "f0e0c0"); p.line(5, 11, 10, 11, "c8b490"); p.dot(7, 10, "a02040"); p.dot(8, 10, "6a2050")
    p.box(2, 2, 12, 3, OUT); p.box(3, 2, 10, 2, "c03a3a")
    for x in (3, 7, 11):
        p.dot(x, 2, "f0e0d0"); p.dot(x + 2, 3, "f0e0d0")
    p.line(3, 5, 12, 5, "6a3a2a")
    return p


def item_flour(P):
    p = P(16, 16)
    p.polygon([(3, 5), (12, 5), (14, 15), (2, 15)], OUT)
    p.polygon([(4, 6), (11, 6), (13, 14), (3, 14)], "d8c8a0")
    p.line(11, 7, 12, 13, "a89878"); p.line(4, 7, 4, 12, "f0e4c8")
    p.box(6, 3, 4, 3, "c8b890"); p.line(5, 5, 10, 5, "8a6a3a")
    p.dot(6, 1, "ffffff"); p.dot(8, 2, "ffffff"); p.dot(9, 1, "f0f0e8")
    p.line(8, 8, 8, 13, "c89a30")
    for y in (8, 10):
        p.dot(7, y, "e0b840"); p.dot(9, y + 1, "e0b840")
    return p


def item_sugar(P):
    p = P(16, 16)
    p.box(3, 2, 10, 13, OUT)
    p.box(4, 3, 8, 11, "eef2f7")
    p.box(4, 3, 8, 2, "c8d4e4"); p.line(4, 5, 11, 5, "8d98ab")
    p.line(11, 6, 11, 13, "b4bfcf")
    p.box(4, 8, 8, 3, "4a7ac8"); p.box(7, 8, 2, 2, "ffffff"); p.dot(8, 9, "c8d4e4")
    p.dot(2, 14, "ffffff"); p.dot(13, 14, "eef2f7"); p.dot(14, 13, "ffffff")
    return p


def item_butter(P):
    p = P(16, 16)
    p.polygon([(1, 11), (15, 11), (13, 14), (3, 14)], "8a8070")
    p.polygon([(2, 11), (14, 11), (12, 13), (4, 13)], "e8e0d0")
    p.line(4, 12, 11, 12, "4a6ab8")
    p.box(3, 5, 10, 7, "6a5020")
    p.box(4, 6, 8, 2, "fff0a0"); p.box(4, 8, 8, 3, "e8c850")
    p.line(4, 6, 11, 6, "fff8d0"); p.line(11, 8, 11, 10, "c8a030")
    p.line(5, 7, 8, 7, "fff8d0")
    return p


def item_berry_cobbler(P):
    p = P(16, 16)
    p.oval(8, 11, 7.5, 4, OUT)
    p.oval(8, 11, 6.8, 3.4, "7a3a2a")
    p.oval(8, 10, 6.5, 3, "b05a3a")
    p.oval(8, 10, 5.4, 2.4, "d89a48")
    for x, y in ((5, 10), (8, 9), (11, 10), (7, 11), (10, 11)):
        p.dot(x, y, "6a2050")
    p.dot(6, 9, "8a3070"); p.dot(9, 11, "8a3070")
    p.line(4, 9, 7, 11, "f0c070"); p.line(9, 9, 12, 11, "f0c070"); p.line(6, 8, 6, 8, "fff0c0")
    p.dot(5, 3, "e0e0f080"); p.dot(6, 2, "e0e0f080"); p.dot(10, 4, "e0e0f080"); p.dot(11, 2, "e0e0f080")
    return p


def sprites(P):
    out = calendar_rings(P)
    out.update({
        "ship_bunk_2x3": ship_bunk(P),
        "ship_locker_3x1": ship_locker(P),
        "ship_table_2x1": ship_table(P),
        "temple_altar": temple_altar(P),
        "status_thirsty": status_thirsty(P),
        "status_starving": status_starving(P),
        "winter_sparkbloom": winter_sparkbloom(P),
        "item_winter_sparkbloom": item_winter_sparkbloom(P),
        "item_berry_preserves": item_berry_preserves(P),
        "item_flour": item_flour(P),
        "item_sugar": item_sugar(P),
        "item_butter": item_butter(P),
        "item_berry_cobbler": item_berry_cobbler(P),
    })
    return out
