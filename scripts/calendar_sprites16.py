#!/usr/bin/env python3
"""Calendar, seasonal, fence, wall, mill-prop, woodcutter and pixel-font artwork for the rustic16 pack.

sprites(Pixels) returns {sprite_id: image} at 16 pixels per cell; write_font(directory, Pixels)
writes pixel-font.png and pixel-font.fnt (BMFont text) into the given directory.
"""
import math
import pathlib
import random
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import make_sprites16 as base  # noqa: E402
import town_sprites16 as town  # noqa: E402

B = base.Pixels
shade, mix, fade, rgba, h01, dither = base.shade, base.mix, base.fade, base.rgba, base.hash01, base.dither
WOOD, STONE, BARK, BIRCH_BARK = base.WOOD, base.STONE, base.BARK, base.BIRCH_BARK
SH = base.SHADOW
INK = "2a1d22"
SNOW = ["6a7488", "8d98ab", "b4bfcf", "dfe6ee", "eef2f7", "ffffff"]
IRON = ["1c1f26", "2e333b", "474d55", "6a7076", "9aa0a0"]
PLASTER = ["9a8c78", "b8aa92", "d2c6ae", "e2d8c2", "ece4d2", "f6f0e2"]

SUMMER = {"oak": ["1a3322", "264c28", "35682c", "4a8632", "6aa23c", "94c052"],
          "birch": ["223a22", "35582c", "4c7a32", "6a9a3a", "90b848", "bcd466"],
          "pine": ["11262a", "1a3a34", "265240", "366c4c", "4f8a58", "78a86a"],
          "grass": ["1f3a22", "2c5329", "3d6e2f", "548a34", "74a43c", "9cbd52"]}
AUTUMN = {"oak": ["3a1c16", "5e2a1a", "8a3a1e", "b55a24", "d8812e", "f0b250"],
          "oak2": ["3a1618", "5a2020", "7e2a24", "a33a2a", "c4563a", "e08458"],
          "birch": ["3e3018", "6a5020", "9a7826", "c8a232", "e6c444", "f8e27a"],
          "pine": ["14262a", "1f3a33", "2e4f3e", "41664a", "5c7e55", "849a6a"],
          "grass": ["3a3220", "5a4a26", "7d6a30", "9c8a3c", "bba650", "d8c473"]}
WINTER = {"oak": ["2a3036", "3d4650", "56606a", "7a8590", "a3adb6", "cdd4da"],
          "pine": ["0f2028", "163030", "1f4040", "2c5450", "3e6a60", "5a8478"],
          "grass": ["8d98ab", "a8b3c4", "c6d0dc", "e3e9f0", "f2f5f9", "ffffff"]}
FALL_LEAVES = ["c4563a", "d8812e", "e6c444", "a33a2a"]


def conv(P, img):
    q = P(img.w, img.h)
    q.copy(img, 0, 0)
    return q


def tones(ramp):
    return [rgba(c) for c in ramp]


# ----------------------------------------------------------------- calendar
DAYS = [("Root", ["4e7a3a", "7aa64a", "c8e08a"], [".##.##.", "..###..", "...#...", "...#...", "..###..", ".#.#.#.", "#..#..#"]),
        ("Ember", ["8a2e1e", "d0582a", "ffd27a"], ["...#...", "..##...", "..###..", ".#####.", ".##.##.", ".#...#.", "..###.."]),
        ("Tide", ["1f4e78", "3a86b8", "bfe8f0"], [".##....", "#..#..#", "....##.", ".......", ".##....", "#..#..#", "....##."]),
        ("Stone", ["44424b", "817b78", "e2dacb"], ["...##..", "..####.", ".......", ".#####.", ".......", "#######", "#######"]),
        ("Gale", ["2e6a64", "6ab0a0", "e0f6ea"], [".####..", "#....#.", ".....#.", "######.", ".......", "#####.#", ".....#."]),
        ("Star", ["8a6a1a", "d8a830", "fff2a6"], ["...#...", "...#...", "#######", ".#####.", "..###..", ".##.##.", "#.....#"]),
        ("Veil", ["4a2a6a", "7e52a8", "e8d4ff"], ["..###..", ".#...#.", "#..#..#", "#.###.#", "#..#..#", ".#...#.", "..###.."])]


def ring(k):
    p = B(64, 64)
    cx = cy = 31.5
    rot = -k * math.tau / 7
    rim = ["2e2620", "4a3a2c", "6a5440", "8a7058", "a88c6c", "c8ae88"]
    for y in range(64):
        for x in range(64):
            dx, dy = x - cx, y - cy
            r = math.hypot(dx, dy)
            if r < 18.5 or r > 30.5:
                continue
            a = (math.atan2(dy, dx) + math.pi / 2 - rot) % math.tau
            seg = a / (math.tau / 7)
            frac = seg - math.floor(seg)
            light = (-dx * 0.6 - dy * 0.8) / r
            v = 3 + light * 1.4 + (dither(x, y) - 0.5) * 0.6
            if r > 29.5 or r < 19.5: v = 0.5
            elif r > 28.5: v -= 1
            elif r < 20.5: v += 0.6
            if abs(frac - 0.5) < 0.04 and 19.5 < r < 29.5: v = 1
            if h01(int(a * 40), int(r), 7) > 0.92: v -= 0.7
            c = rim[max(0, min(5, int(v)))]
            p.dot(x, y, c)
    for i, (_, ramp, glyph) in enumerate(DAYS):
        ang = (i - k) * math.tau / 7 - math.pi / 2
        mx, my = round(cx + math.cos(ang) * 24.5), round(cy + math.sin(ang) * 24.5)
        p.oval(mx, my, 5.6, 5.6, INK)
        p.oval(mx, my, 4.8, 4.8, ramp[0])
        p.oval(mx - 0.4, my - 0.4, 4.0, 4.0, ramp[1])
        for gy, row in enumerate(glyph):
            for gx, ch in enumerate(row):
                if ch == "#":
                    p.dot(mx - 3 + gx, my - 3 + gy, ramp[2])
        p.dot(mx - 3, my - 4, shade(ramp[1], 1.2)); p.dot(mx - 4, my - 3, shade(ramp[1], 1.2))
    for i, w in enumerate((5, 3, 1)):
        p.hline(32 - w // 2 - (1 if w > 1 else 0), 31 + w // 2, i, "f0c850" if i else "fff0a0")
    p.dot(31, 3, "c89a30"); p.dot(32, 3, "c89a30")
    return p


def season_icon(kind):
    p = B(16, 16)
    if kind == "spring":
        p.line(8, 15, 8, 9, "3d6e2f"); p.polygon([(8, 12), (12, 9), (14, 10), (11, 13)], "62953f")
        p.line(9, 12, 13, 10, "2f4f2c")
        for a in range(5):
            t = a * math.tau / 5 - math.pi / 2
            p.oval(7.5 + math.cos(t) * 3, 6 + math.sin(t) * 3, 2.2, 2.2, "f0a0b8")
        for a in range(5):
            t = a * math.tau / 5 - math.pi / 2
            p.dot(round(7.5 + math.cos(t) * 3.6), round(6 + math.sin(t) * 3.6) - 1, "fcd8e2")
        p.oval(7.5, 6, 1.4, 1.4, "f2c94a"); p.dot(7, 5, "fff2a6")
    elif kind == "summer":
        for a in range(8):
            t = a * math.tau / 8
            p.line(round(7.5 + math.cos(t) * 5), round(7.5 + math.sin(t) * 5), round(7.5 + math.cos(t) * 7), round(7.5 + math.sin(t) * 7), "f0a030")
        p.oval(7.5, 7.5, 4.4, 4.4, "e08a2a"); p.oval(7.5, 7.5, 3.6, 3.6, "f2c94a"); p.oval(6.5, 6.5, 2, 2, "fff2a6")
    elif kind == "autumn":
        pts = [(8, 1), (10, 5), (14, 4), (12, 8), (15, 10), (10, 11), (9, 13), (7, 13), (6, 11), (1, 10), (4, 8), (2, 4), (6, 5)]
        p.polygon(pts, "d8812e")
        p.polygon([(8, 2), (9, 6), (7, 12), (6, 6)], "f0b250")
        p.line(8, 4, 8, 15, "7a3a1a"); p.line(8, 9, 12, 6, "a85020"); p.line(8, 9, 4, 6, "a85020")
        for x, y in ((11, 9), (12, 8), (4, 9)): p.dot(x, y, "b55a24")
    else:
        for a in range(6):
            t = a * math.tau / 6 - math.pi / 2
            ex, ey = round(7.5 + math.cos(t) * 6.5), round(7.5 + math.sin(t) * 6.5)
            p.line(8 if ex >= 8 else 7, 8 if ey >= 8 else 7, ex, ey, "cfe4f4")
            mx, my = 7.5 + math.cos(t) * 4, 7.5 + math.sin(t) * 4
            for s in (-1, 1):
                u = t + s * 0.9
                p.line(round(mx), round(my), round(mx + math.cos(u) * 2), round(my + math.sin(u) * 2), "a8c8e8")
        p.box(7, 7, 2, 2, "ffffff")
    p.outline(k=-2.4)
    return p


def moon(i, ivory):
    p = B(24, 24)
    lit = ["8a6ab8", "a486d0", "c0a6e4", "dcc8f6"] if not ivory else ["c8bc9c", "ddd2b4", "efe6cc", "fffaea"]
    dark = ["241a34", "33264a"] if not ivory else ["2e2c34", "424048"]
    phi = i / 16 * math.tau
    L = (math.sin(phi), -0.15, -math.cos(phi))
    c, r = 11.5, 10.6
    for y in range(24):
        for x in range(24):
            nx, ny = (x - c) / r, (y - c) / r
            q = nx * nx + ny * ny
            if q > 1:
                continue
            nz = math.sqrt(1 - q)
            d = nx * L[0] + ny * L[1] + nz * L[2]
            crater = h01(x // 2, y // 2, 31) > 0.82 or (x - 8) ** 2 + (y - 14) ** 2 < 5 or (x - 15) ** 2 + (y - 8) ** 2 < 3
            if d > 0.02:
                v = 0.6 + d * 2.6 + (0.4 - nx * 0.3 - ny * 0.4) * 0.6 + (dither(x, y) - 0.5) * 0.7
                if crater: v -= 0.9
                p.dot(x, y, lit[max(0, min(3, int(v)))])
            else:
                rim = q > 0.82
                p.dot(x, y, dark[1] if rim or (crater and h01(x, y, 3) > 0.5) else dark[0])
    p.outline("140e1c" if not ivory else "1c1a20")
    return p


# ----------------------------------------------------------------- seasons
def patched(mod_vars, fn):
    old = {k: getattr(base, k) for k in mod_vars}
    for k, v in mod_vars.items(): setattr(base, k, v)
    try:
        return fn()
    finally:
        for k, v in old.items(): setattr(base, k, v)


def grass(v, season):
    p = B(16, 16)
    patched({"GRASS": {"summer": SUMMER, "autumn": AUTUMN, "winter": WINTER}[season]["grass"]},
            lambda: base.grass_tile(p, 0 if season == "winter" and v == 2 else v, seed=v))
    rng = random.Random(70 + v * 5 + len(season))
    if season == "summer":
        for _ in range(2 + v % 2):
            x, y = rng.randrange(16), rng.randrange(16)
            p.dot(x, y, "f2c94a" if v % 2 else "f3ead0"); p.dot(x, (y + 1) % 16, SUMMER["grass"][1])
    elif season == "autumn":
        for _ in range(3 + v):
            x, y, c = rng.randrange(16), rng.randrange(16), rng.choice(FALL_LEAVES)
            p.dot(x, y, c); p.dot((x + 1) % 16, y, shade(c, -1)); p.dot(x, (y + 1) % 16, shade(c, -1.6))
    else:
        for _ in range(3 + v % 2):
            x, y = rng.randrange(16), rng.randrange(1, 16)
            p.dot(x, y, "6f7a4a"); p.dot(x, y - 1, "8a8a5a"); p.dot(x, (y + 1) % 16, SNOW[2])
        if v == 2:
            p.dot(5, 6, "a83a3a"); p.dot(6, 6, "c84a3e"); p.dot(5, 7, "3d5a3a")
    return p


def flowerbed(v, season):
    p = B(16, 16)
    soil = ["3e281c", "4e3324", "5e3e2a"]
    for y in range(13):
        for x in range(16):
            p.dot(x, y, soil[int(h01(x, y, 90) * 3)])
    stem = ["2c5329", "3d6e2f", "548a34"]
    if season == "summer":
        blooms = (("e8c04a", "6a3a1a"), ("9a7ad8", "f2ece0"))[v]
        for i in range(9):
            cx, cy = int(1 + h01(i, v, 93) * 13), int(2 + h01(v, i, 94) * 8)
            p.vline(cx, cy + 1, cy + 3, stem[1]); p.dot(cx + 1, cy + 2, stem[2]); p.dot(cx - 1, cy + 3, stem[0])
            c = blooms[0] if i % 3 else blooms[1]
            for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1), (-1, -1), (1, -1)):
                p.dot(cx + dx, cy + dy, c)
            p.dot(cx, cy, "6a3a1a" if v == 0 else "f6e08a"); p.dot(cx - 1, cy - 1, shade(c, 1.4))
    elif season == "autumn":
        blooms = (("d8812e", "a33a2a"), ("b84a6a", "e6c444"))[v]
        for i in range(7):
            cx, cy = int(1 + h01(i, v, 95) * 13), int(2 + h01(v, i, 96) * 8)
            p.vline(cx, cy + 1, cy + 3, "6a6a2a"); p.dot(cx + 1, cy + 2, "8a7a30")
            c = blooms[i % 2]
            p.box(cx - 1, cy - 1, 3, 2, c); p.dot(cx, cy - 1, shade(c, 1.3)); p.dot(cx, cy + 1, shade(c, -1.2))
        for i in range(4):
            x, y = int(h01(i, 7, v) * 15), int(h01(7, i, v) * 12)
            p.dot(x, y, FALL_LEAVES[i]); p.dot(x + 1, y, shade(FALL_LEAVES[i], -1.2))
    else:
        for y in range(13):
            for x in range(16):
                if h01(x, y, 97) > 0.12 or y < 2:
                    p.dot(x, y, SNOW[4] if h01(x, y, 98) > 0.3 else SNOW[3])
        for i in range(6):
            cx, cy = int(1 + h01(i, v, 99) * 13), int(3 + h01(v, i, 100) * 7)
            p.vline(cx, cy, cy + 3, "6a5a3a"); p.dot(cx - 1, cy, "8a7448"); p.dot(cx + 1, cy - 1, "8a7448")
            p.dot(cx, cy + 4, SNOW[2])
        if v == 1:
            p.dot(10, 6, "c84a3e"); p.dot(11, 6, "a83a3a"); p.dot(11, 7, "2c5329")
    p.box(0, 13, 16, 3, STONE[3]); p.hline(0, 15, 13, STONE[5]); p.hline(0, 15, 15, STONE[1])
    for x in (4, 10, 15): p.vline(x, 13, 15, STONE[1])
    if season == "winter":
        for x in range(16): p.dot(x, 13, SNOW[5]); p.dot(x, 12, SNOW[4]) if h01(x, 1, 3) > 0.4 else None
    return p


def snow_cap(p, ramp_tones, depth=2, chance=1.0, seed=0, skip=lambda x, y: False):
    marks = []
    for y in range(1, p.h):
        for x in range(p.w):
            c = p.get(x, y)
            if c[3] != 255 or skip(x, y):
                continue
            above = p.get(x, y - 1)
            idx = ramp_tones.index(c) if c in ramp_tones else -1
            if above[3] == 0 or (idx >= 2 and above in ramp_tones and ramp_tones.index(above) <= 1):
                if h01(x, y, seed) < chance:
                    marks.append((x, y))
    for x, y in marks:
        p.dot(x, y, SNOW[5] if p.get(x, y - 1)[3] == 0 else SNOW[4])
        for k in range(1, depth):
            if p.get(x, y + k)[3] == 255 and h01(x, y + k, seed + 1) > 0.3:
                p.dot(x, y + k, SNOW[3] if k == 1 else SNOW[2])


def ground_snow(p, cx, y, half):
    for x in range(cx - half, cx + half + 1):
        t = abs(x - cx) / half
        for k in range(1 if t > 0.7 else 2):
            yy = y - k
            if p.get(x, yy)[3] == 0 or k == 0:
                p.dot(x, yy, SNOW[4] if k == 0 else SNOW[5])


def ground_leaves(p, cx, y, half, seed):
    for i in range(half * 2):
        x = cx - half + int(h01(i, seed, 5) * half * 2)
        yy = y - int(h01(seed, i, 6) * 2)
        c = FALL_LEAVES[i % 4]
        p.dot(x, yy, c)


def bare_tree(species, rows):
    w, h = 48, rows * 16 + 32
    p = B(w, h)
    birch = species == "birch"
    ramp = BIRCH_BARK if birch else BARK
    base_y = h - 3
    canopy_bottom = rows * 16 + 8
    top = canopy_bottom - 12
    base.trunk(p, 24, top, base_y, 6 if birch else 8, ramp, birch)
    rng = random.Random(rows * 13 + len(species))
    ch = canopy_bottom - 2
    cy0, ry, rx = ch / 2 + 1, ch / 2 - 2, 19

    def limb(x, y, ang, length, depth):
        ex, ey = x + math.cos(ang) * length, y + math.sin(ang) * length
        ex = max(3, min(44, ex)); ey = max(2, ey)
        if ((ex - 24) / rx) ** 2 + ((ey - cy0) / (ry + 2)) ** 2 > 1.15:
            ex, ey = x + (ex - x) * 0.7, y + (ey - y) * 0.7
        thick = 2 if depth <= 1 else 1
        col = ramp[3] if birch else ramp[2 if depth < 3 else 3]
        for o in range(thick):
            p.line(round(x) + o, round(y), round(ex) + o, round(ey), col)
        if birch and depth < 2:
            p.dot(round((x + ex) / 2), round((y + ey) / 2), ramp[0])
        if depth < 4:
            n = 2 if depth < 3 else 3
            for j in range(n):
                limb(ex, ey, ang + rng.uniform(-0.65, 0.65) + (j - (n - 1) / 2) * 0.5, length * rng.uniform(0.55, 0.75), depth + 1)
    trunk_w = 3 if birch else 4
    p.box(24 - trunk_w // 2, top - 6, trunk_w, 8, ramp[3])
    p.vline(24 - trunk_w // 2, top - 6, top + 2, ramp[4])
    for ang in (-math.pi / 2 - 0.1, -math.pi / 2 - 0.9, -math.pi / 2 + 0.85, -math.pi + 0.5, -0.5):
        limb(24, top - 4 + (2 if abs(ang + math.pi / 2) > 0.8 else 0), ang, ch * 0.32 + rng.uniform(-1, 2), 1)
    bt = tones(ramp)
    snow_cap(p, bt, 2, 0.75, rows, lambda x, y: y > top + 3)
    p.outline(k=-2.6)
    base.contact_shadow(p, 24 - 8, 24 + 7, base_y + 1, 2, 130)
    ground_snow(p, 24, base_y, 9)
    return p


def seasonal_tree(species, rows, season):
    if season == "winter" and species != "pine":
        return bare_tree(species, rows)
    pal = {"summer": SUMMER, "autumn": AUTUMN, "winter": WINTER}[season]
    key = {"oak": "LEAF_OAK", "birch": "LEAF_BIRCH", "pine": "LEAF_PINE"}[species]
    ramp = pal[species]
    patched({key: ramp}, lambda: base.tree(species, rows))
    p = base.ASSETS.pop(f"tree_{species}_{rows}")[0]
    rt = tones(ramp)
    h = p.h
    base_y = h - 3
    rng = random.Random(rows * 7 + len(species) * 3 + len(season))
    canopy_y = rows * 16 + 4
    if season == "summer":
        if species == "oak":
            for _ in range(rows * 3):
                x, y = rng.randrange(8, 40), rng.randrange(6, canopy_y)
                if p.get(x, y) in rt and p.get(x + 1, y + 1) in rt:
                    p.dot(x, y, "c83a32"); p.dot(x + 1, y, "a82a2a"); p.dot(x, y - 1, "f08a6a"); p.dot(x + 1, y + 1, ramp[0])
        elif species == "birch":
            for _ in range(rows * 5):
                x, y = rng.randrange(8, 40), rng.randrange(8, canopy_y)
                if p.get(x, y) in rt and p.get(x, y + 2) in rt:
                    p.vline(x, y, y + 2, "c8c45a"); p.dot(x, y + 2, "8a8a3a")
        else:
            for _ in range(rows * 4):
                x, y = rng.randrange(10, 38), rng.randrange(6, canopy_y)
                if p.get(x, y) in rt and p.get(x, y - 1) in rt:
                    p.dot(x, y, "6a4028"); p.dot(x, y + 1, "4a2a1c"); p.dot(x, y - 1, ramp[5])
        for _ in range(rows * 30):
            x, y = rng.randrange(4, 44), rng.randrange(2, canopy_y)
            if p.get(x, y) == rt[4] and p.get(x - 1, y - 1)[3] == 0:
                p.dot(x, y, ramp[5])
    elif season == "autumn":
        if species == "oak":
            other = AUTUMN["oak2"]
            for y in range(h):
                for x in range(48):
                    c = p.get(x, y)
                    if c in rt and base.vnoise(x / 6, y / 6, rows) > 0.55:
                        p.dot(x, y, other[rt.index(c)])
        if species != "pine":
            for _ in range(rows * 40):
                x, y = rng.randrange(2, 46), rng.randrange(1, canopy_y)
                c = p.get(x, y)
                if c[3] and (p.get(x, y - 1)[3] == 0 or p.get(x - 1, y)[3] == 0 or p.get(x + 1, y)[3] == 0):
                    p.clear(x, y)
            for _ in range(rows * 6):
                x, y = rng.randrange(14, 34), rng.randrange(canopy_y // 2, canopy_y)
                if p.get(x, y)[3]:
                    p.dot(x, y, BARK[2] if species == "oak" else BIRCH_BARK[3]); p.dot(x + 1, y - 1, BARK[1] if species == "oak" else BIRCH_BARK[2])
            for _ in range(rows * 2):
                x, y = rng.randrange(4, 44), rng.randrange(canopy_y, base_y - 4)
                if p.get(x, y)[3] == 0:
                    p.dot(x, y, rng.choice(FALL_LEAVES))
            ground_leaves(p, 24, base_y + 1, 13, rows)
        else:
            for _ in range(rows * 14):
                x, y = rng.randrange(6, 42), rng.randrange(4, canopy_y)
                if p.get(x, y) in rt[2:4]:
                    p.dot(x, y, "8a6a3a")
            ground_leaves(p, 24, base_y + 1, 7, rows)
    else:
        snow_cap(p, rt, 3, 1.0, rows * 3, lambda x, y: y > canopy_y + 4)
        for _ in range(rows * 12):
            x, y = rng.randrange(4, 44), rng.randrange(2, canopy_y)
            if p.get(x, y) in rt[1:3]:
                p.dot(x, y, SNOW[3])
        ground_snow(p, 24, base_y, 10)
    return p


def seasonal_bushes(season):
    pal = {"summer": SUMMER, "autumn": AUTUMN, "winter": WINTER}[season]
    w = {"summer": pal, "autumn": {"oak": AUTUMN["oak"], "birch": AUTUMN["birch"], "pine": AUTUMN["oak2"]},
         "winter": {"oak": WINTER["oak"], "birch": WINTER["pine"], "pine": WINTER["pine"]}}[season]
    patched({"LEAF_OAK": w["oak"], "LEAF_BIRCH": w["birch"], "LEAF_PINE": w["pine"]}, base.bushes)
    out = []
    for v in range(4):
        img = base.ASSETS.pop(f"bush{v}")[0]
        if v < 3:
            out.append(img)
    ramps = [w["oak"], w["oak"], w["birch"]]
    for v, p in enumerate(out):
        rt = tones(ramps[v])
        rng = random.Random(800 + v + len(season))
        if season == "summer":
            for _ in range(6):
                x, y = rng.randrange(5, 27), rng.randrange(5, 17)
                if p.get(x, y) in rt:
                    c = ("f3ead0", "f2c94a", "e0708a")[v]
                    for dx, dy in ((0, 0), (1, 0), (0, -1)): p.dot(x + dx, y + dy, c)
                    p.dot(x, y + 1, ramps[v][0])
        elif season == "autumn":
            for _ in range(60):
                x, y = rng.randrange(2, 30), rng.randrange(1, 20)
                c = p.get(x, y)
                if c[3] and (p.get(x, y - 1)[3] == 0 or p.get(x + 1, y)[3] == 0):
                    p.clear(x, y)
            for i in range(5):
                x, y = rng.randrange(8, 24), rng.randrange(9, 18)
                if p.get(x, y)[3]: p.line(x, y, x + rng.choice((-2, 2)), y - 2, BARK[2])
            ground_leaves(p, 16, 22, 11, v)
        else:
            snow_cap(p, rt, 3, 1.0, 900 + v)
            for _ in range(10):
                x, y = rng.randrange(4, 28), rng.randrange(6, 18)
                if p.get(x, y)[3] and p.get(x, y - 1)[3]:
                    p.line(x, y, x + rng.choice((-1, 1)), y - 2, "4a3a2c")
            for x in range(4, 28):
                for y in range(23, 18, -1):
                    if p.get(x, y)[3] == 255 and p.get(x, y)[:3] != SH:
                        break
                p.dot(x, 22, SNOW[3]) if p.get(x, 22)[3] < 255 else None
    return out


def roof_snow():
    p = B(16, 16)
    for x in range(16):
        depth = 4 + round(1.5 * math.sin(x * math.tau / 16 * 2) + h01(x, 0, 41) * 1.2)
        for y in range(depth + 1):
            p.dot(x, y, SNOW[5] if y < 2 else SNOW[4] if y < depth - 1 else SNOW[3] if y < depth else SNOW[2])
        if x % 5 == 2:
            for y in range(depth + 1, depth + 3 + x % 3):
                p.dot(x, y, fade("cfe4f4", 220))
        p.dot(x, depth + 1, fade(SNOW[1], 90))
    for x in range(0, 16, 3): p.dot(x, 1, "e6f2ff")
    return p


# ------------------------------------------------------------------ fences
def iron_post(p, x):
    p.box(x - 1, 13, 4, 3, STONE[3]); p.hline(x - 1, x + 2, 13, STONE[5]); p.hline(x - 1, x + 2, 15, STONE[1])
    p.box(x, 3, 2, 10, IRON[2]); p.vline(x, 3, 12, IRON[3]); p.vline(x + 1, 4, 12, IRON[1])
    p.box(x - 1, 2, 4, 1, IRON[2]); p.hline(x, x + 1, 1, IRON[4]); p.dot(x, 0, IRON[4])


def iron_run(p, x0, x1):
    for y in (4, 11):
        p.hline(x0, x1, y, IRON[3]); p.hline(x0, x1, y + 1, IRON[1])
    for x in range(x0, x1 + 1):
        if x % 3 == 1:
            p.vline(x, 3, 13, IRON[2]); p.dot(x, 2, IRON[4]); p.dot(x, 14, fade(SH, 110))
        if x % 6 == 4:
            p.dot(x, 8, IRON[4]); p.dot(x - 1, 7, IRON[2]); p.dot(x + 1, 7, IRON[2])


def iron_vrun(p, y0, y1):
    p.vline(7, y0, y1, IRON[3]); p.vline(8, y0, y1, IRON[1])
    for y in range(y0, y1 + 1):
        if y % 3 == 0:
            p.dot(6, y, IRON[2]); p.dot(9, y, IRON[1]); p.dot(7, y - 1, IRON[4])


def wood_post(p, x):
    p.box(x, 3, 3, 12, WOOD[3]); p.vline(x, 3, 14, WOOD[4]); p.vline(x + 2, 3, 14, WOOD[1])
    p.dot(x + 1, 2, WOOD[5]); p.hline(x, x + 2, 3, WOOD[4]); p.dot(x + 1, 9, WOOD[2])
    base.contact_shadow(p, x - 1, x + 3, 15, 1)


def wood_run(p, x0, x1):
    for y in (6, 11):
        p.hline(x0, x1, y, WOOD[3]); p.hline(x0, x1, y + 1, WOOD[1])
    for x in range(x0, x1 + 1):
        if x % 4 in (1, 2):
            top = 4 if x % 4 == 1 else 5
            p.vline(x, top + 1, 13, WOOD[4] if x % 4 == 1 else WOOD[2])
            p.dot(x, top, WOOD[5] if x % 4 == 1 else WOOD[3])
            p.dot(x, 14, fade(SH, 100))


def wood_vrun(p, y0, y1):
    p.vline(7, y0, y1, WOOD[4]); p.vline(8, y0, y1, WOOD[2])
    for y in range(y0, y1 + 1):
        if y % 4 == 0: p.dot(7, y, WOOD[5]); p.dot(8, y, WOOD[1])


def fence(kind, mask):
    p = B(16, 16)
    run, vrun, post = (iron_run, iron_vrun, iron_post) if kind == "iron" else (wood_run, wood_vrun, wood_post)
    if mask & 4: vrun(p, 0, 4)
    if mask & 1: run(p, 0, 6)
    if mask & 2: run(p, 9, 15)
    post(p, 7 if kind == "iron" else 6)
    if mask & 8: vrun(p, 12 if kind == "wood" else 13, 15)
    return p


def gate(kind):
    p = B(16, 16)
    if kind == "iron":
        iron_post(p, 0); iron_post(p, 14)
        for i, x in enumerate(range(3, 7)):
            p.vline(x, 3 + i, 12 + i, IRON[3] if i % 2 == 0 else IRON[1]); p.dot(x, 2 + i, IRON[4])
        p.line(3, 4, 6, 7, IRON[2]); p.line(3, 11, 6, 14, IRON[2])
        p.oval(4.5, 8.5, 1.2, 1.6, IRON[3])
        p.dot(2, 5, IRON[4]); p.dot(2, 11, IRON[4])
    else:
        wood_post(p, 0); wood_post(p, 13)
        for i, x in enumerate(range(3, 7)):
            p.vline(x, 5 + i, 12 + i, WOOD[4] if i % 2 == 0 else WOOD[2]); p.dot(x, 4 + i, WOOD[5])
        p.line(3, 6, 6, 9, WOOD[1]); p.line(3, 11, 6, 14, WOOD[1]); p.line(3, 11, 6, 9, WOOD[2])
        p.dot(3, 7, base.METAL[4]); p.dot(3, 11, base.METAL[4])
        p.dot(7, 15, fade(SH, 90)); p.dot(6, 15, fade(SH, 70))
    return p


# ------------------------------------------------------------------- walls
def wall(mask):
    p = B(16, 32)
    cap = set()
    for x in range(4, 12):
        for y in range(8, 16): cap.add((x, y))
    if mask & 1: cap |= {(x, y) for x in range(0, 4) for y in range(8, 16)}
    if mask & 2: cap |= {(x, y) for x in range(12, 16) for y in range(8, 16)}
    if mask & 4: cap |= {(x, y) for x in range(4, 12) for y in range(0, 8)}
    if mask & 8: cap |= {(x, y) for x in range(4, 12) for y in range(16, 32)}
    face = {(x, y) for x in range(16) for y in range(16, 32) if (x, 15) in cap and (x, 16) not in cap}
    for x, y in face:
        n = h01(x, y, 61)
        c = PLASTER[4] if n > 0.25 else PLASTER[3]
        if n > 0.93: c = PLASTER[2]
        if y == 16: c = PLASTER[1]
        elif y == 17: c = PLASTER[2]
        p.dot(x, y, c)
    for x, y in face:
        if (x - 1, y) not in face and x > 0 or (x == 0 and not mask & 1):
            p.dot(x, y, PLASTER[2] if y > 17 else PLASTER[1])
        if ((x + 1, y) not in face and x < 15) or (x == 15 and not mask & 2):
            p.dot(x, y, PLASTER[1])
        if y >= 28:
            p.dot(x, y, [WOOD[4], WOOD[3], WOOD[2], WOOD[1]][y - 28])
            if x % 8 == 3 and y > 28: p.dot(x, y, WOOD[1])
    capc = ["5a4a3c", "7a6450", "8e7860", "a48c70"]
    for x, y in cap:
        v = 2 if h01(x, y, 62) > 0.15 else 1
        p.dot(x, y, capc[v])
    for x, y in cap:
        up, dn, lf, rt = (x, y - 1) in cap or y == 0, (x, y + 1) in cap or (x, y + 1) in face or y == 31, \
            (x - 1, y) in cap or x == 0, (x + 1, y) in cap or x == 15
        if not up: p.dot(x, y, capc[3])
        elif not lf: p.dot(x, y, capc[3])
        if not rt: p.dot(x, y, capc[0])
        if not dn: p.dot(x, y, capc[0])
    for x, y in cap:
        if (x, y + 1) in face: p.dot(x, y, capc[1])
    p.outline("3a2e26")
    return p


# ------------------------------------------------------------------- props
def gear(p, cx, cy, r, teeth, ramp, rot=0.0):
    for i in range(teeth):
        a = rot + i * math.tau / teeth
        for d in (r + 0.6, r + 1.6):
            p.dot(round(cx + math.cos(a) * d), round(cy + math.sin(a) * d), ramp[2])
    p.oval(cx, cy, r, r, ramp[1]); p.oval(cx - 0.3, cy - 0.3, r - 1, r - 1, ramp[3])
    p.oval(cx, cy, r - 2.2, r - 2.2, ramp[1])
    for i in range(4):
        a = rot + i * math.pi / 2 + 0.4
        p.line(round(cx), round(cy), round(cx + math.cos(a) * (r - 1.5)), round(cy + math.sin(a) * (r - 1.5)), ramp[3])
    p.oval(cx, cy, 1.4, 1.4, ramp[0]); p.dot(round(cx) - 1, round(cy) - 1, ramp[4])


def cylinder(p, cx, top, rx, ry, height, ramp, seed):
    for y in range(int(top - ry), int(top + height + ry) + 1):
        for x in range(int(cx - rx), int(cx + rx) + 1):
            dx = (x + 0.5 - cx) / rx
            if abs(dx) > 1: continue
            e = ry * math.sqrt(1 - dx * dx)
            if top - e <= y <= top + height + e:
                v = 3.2 - dx * 1.3 + (dither(x, y) - 0.5) * 0.6 - (0.6 if h01(x, y, seed) > 0.9 else 0)
                p.dot(x, y, ramp[max(0, min(5, int(v - 0.6)))])
    for y in range(int(top - ry), int(top + ry) + 1):
        for x in range(int(cx - rx), int(cx + rx) + 1):
            if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - top) / ry) ** 2 <= 1:
                v = 4 + (dither(x, y) - 0.5) * 0.8 - (0.8 if h01(x, y, seed + 1) > 0.88 else 0)
                p.dot(x, y, ramp[max(0, min(5, int(v)))])


def millstone():
    p = B(48, 56)
    for x in (5, 41):
        p.box(x, 6, 3, 44, WOOD[2]); p.vline(x, 6, 49, WOOD[4]); p.vline(x + 2, 6, 49, WOOD[1])
    p.box(4, 5, 41, 3, WOOD[3]); p.hline(4, 44, 5, WOOD[5]); p.hline(4, 44, 7, WOOD[1])
    p.polygon([(15, 9), (33, 9), (27, 20), (21, 20)], WOOD[3])
    p.polygon([(15, 9), (20, 9), (22, 20), (21, 20)], WOOD[4])
    p.hline(15, 33, 9, WOOD[5]); p.hline(16, 32, 10, "d8ccb0"); p.hline(18, 30, 11, WOOD[1])
    p.line(33, 9, 27, 20, WOOD[1]); p.vline(24, 9, 20, WOOD[2])
    cylinder(p, 24, 40, 20, 8, 5, STONE, 3)
    cylinder(p, 24, 32, 16, 6.5, 5, base.ROCK, 5)
    p.oval(24, 32, 3, 1.6, base.ROCK[0]); p.box(23, 20, 3, 12, WOOD[2]); p.vline(23, 20, 31, WOOD[4])
    for a in range(6):
        t = a * math.pi / 3 + 0.3
        p.line(24 + round(math.cos(t) * 5), 32 + round(math.sin(t) * 2), 24 + round(math.cos(t) * 13), 32 + round(math.sin(t) * 5), base.ROCK[2])
    gear(p, 10, 22, 5.5, 10, WOOD, 0.2)
    p.hline(15, 22, 22, WOOD[1]); p.hline(15, 22, 21, WOOD[3])
    p.box(36, 43, 5, 3, WOOD[2]); p.hline(36, 40, 43, WOOD[4]); p.dot(40, 46, "efe6d0"); p.dot(41, 47, "efe6d0")
    town.sack(p, 9, 53, 9, 9); town.sack(p, 39, 53, 8, 8); town.sack(p, 16, 54, 6, 6)
    p.outline(k=-2.6)
    base.contact_shadow(p, 4, 44, 50, 2, 110)
    return p


def mill_gears():
    p = B(32, 40)
    p.box(24, 0, 3, 36, WOOD[2]); p.vline(24, 0, 35, WOOD[4]); p.vline(26, 0, 35, WOOD[1])
    for y in (6, 18, 30): p.hline(24, 26, y, base.METAL[3])
    gear(p, 12, 16, 9.5, 14, WOOD, 0.1)
    gear(p, 23, 29, 5.2, 8, WOOD, 0.35)
    p.box(1, 33, 30, 4, WOOD[3]); p.hline(1, 30, 33, WOOD[5]); p.hline(1, 30, 36, WOOD[1])
    for x in (2, 29): p.box(x - 1, 30, 3, 8, WOOD[2]); p.vline(x - 1, 30, 37, WOOD[4])
    p.box(10, 26, 4, 8, WOOD[2]); p.vline(10, 26, 33, WOOD[4])
    for x in (6, 16, 26): p.dot(x, 34, base.METAL[4])
    p.outline(k=-2.6)
    base.contact_shadow(p, 1, 30, 38, 2, 110)
    return p


def bulletin():
    p = B(48, 48)
    for x in (5, 40):
        p.box(x, 4, 4, 41, WOOD[2]); p.vline(x, 4, 44, WOOD[4]); p.vline(x + 3, 4, 44, WOOD[1])
        for y in range(8, 44, 5): p.dot(x + 1, y, WOOD[1])
    p.polygon([(1, 6), (5, 1), (42, 1), (46, 6)], base.QUILT[2] if hasattr(base, "QUILT") else "8c3a33")
    p.hline(5, 42, 1, "c4614a"); p.hline(1, 46, 6, "4a1f1f"); p.hline(2, 45, 5, "6e2a28")
    p.box(3, 8, 42, 26, WOOD[1]); p.box(5, 10, 38, 22, "8a6440")
    for y in range(10, 32):
        for x in range(5, 43):
            if h01(x, y, 71) > 0.85: p.dot(x, y, "7a5636")
    p.hline(3, 44, 8, WOOD[4]); p.hline(3, 44, 33, WOOD[0])
    notes = [(7, 12, 9, 10, "efe6cc"), (18, 11, 10, 8, "f4ecd8"), (30, 12, 10, 12, "e8dcb8"), (9, 23, 8, 7, "f0e4c0"), (19, 21, 9, 9, "e2d6c0")]
    for i, (x, y, w, h, c) in enumerate(notes):
        p.box(x + 1, y + 1, w, h, fade(SH, 120))
        p.box(x, y, w, h, c); p.hline(x, x + w - 1, y + h - 1, shade(c, -0.8)); p.vline(x + w - 1, y, y + h - 1, shade(c, -0.8))
        for ly in range(y + 2, y + h - 2, 2):
            for lx in range(x + 1, x + w - 2):
                if h01(lx, ly, i + 72) > 0.3 and not (lx == x + w - 3 and ly == y + h - 3):
                    p.dot(lx, ly, "6a5a4a" if i != 2 else "5a4a6a")
        p.dot(x + w // 2, y, ("c84a3e", "4a6ea8", "e8c04a", "4a8a4a", "c84a3e")[i])
    p.box(31, 28, 6, 3, "c84a3e"); p.dot(33, 29, "f2c94a")
    p.outline(k=-2.6)
    for x in (5, 40): base.contact_shadow(p, x - 1, x + 4, 45, 2, 120)
    return p


def woodpile():
    p = B(32, 24)
    p.box(2, 19, 28, 2, WOOD[1])
    rows = [(4, 16, 3.6), (3, 10, 3.6), (2, 4, 3.6)]
    for n, cy, r in rows:
        start = 16 - (n - 1) * 3.6
        for i in range(n):
            cx = start + i * 7.2 + (h01(i, n, 3) - 0.5)
            p.oval(cx, cy, r, r, BARK[1])
            p.oval(cx - 0.4, cy - 0.3, r - 1, r - 1, "c8995e")
            p.oval(cx, cy, r - 2.2, r - 2.2, "a87a48")
            p.dot(round(cx), round(cy), "7a5434"); p.dot(round(cx) - 1, round(cy) - 2, "e0b67c")
            p.dot(round(cx + r - 1), round(cy + 1), BARK[0])
    p.outline(k=-2.6)
    base.contact_shadow(p, 3, 28, 21, 2, 120)
    return p


WOODCUTTER = ("4e7a3e", "6a2a1e", "d8a47e", "4a3e34", "d8c8a8", ("long", "rolled"))


def write_font(directory, Pixels):
    directory = pathlib.Path(directory)
    glyphs = font_glyphs()
    cols, cw, chh = 16, 8, 10
    order = sorted(glyphs)
    rows = (len(order) + cols - 1) // cols
    img = Pixels(cols * cw, rows * chh)
    lines = []
    for n, code in enumerate(order):
        w, cells = glyphs[code]
        gx, gy = (n % cols) * cw, (n // cols) * chh
        for y, row in enumerate(cells):
            for x, ch in enumerate(row):
                if ch == "#": img.dot(gx + x, gy + y, "ffffff")
        lines.append(f"char id={code} x={gx} y={gy} width={max(w, 1)} height={chh} xoffset=0 yoffset=0 xadvance={w + 1} page=0 chnl=15")
    directory.mkdir(parents=True, exist_ok=True)
    img.png(directory / "pixel-font.png")
    head = ['info face="NiceFarmPixel" size=10 bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=1,1 outline=0',
            f"common lineHeight={chh} base=8 scaleW={img.w} scaleH={img.h} pages=1 packed=0 alphaChnl=0 redChnl=4 greenChnl=4 blueChnl=4",
            'page id=0 file="pixel-font.png"', f"chars count={len(lines)}"]
    (directory / "pixel-font.fnt").write_text("\n".join(head + lines) + "\n")


# Rows: cap height rows 1..7, x-height rows 3..7, descenders rows 8..9; '|' separates rows, top-aligned at row 1.
FONT = {
    "A": ".##.|#..#|#..#|####|#..#|#..#|#..#", "B": "###.|#..#|#..#|###.|#..#|#..#|###.",
    "C": ".###|#...|#...|#...|#...|#...|.###", "D": "###.|#..#|#..#|#..#|#..#|#..#|###.",
    "E": "####|#...|#...|###.|#...|#...|####", "F": "####|#...|#...|###.|#...|#...|#...",
    "G": ".###|#...|#...|#.##|#..#|#..#|.###", "H": "#..#|#..#|#..#|####|#..#|#..#|#..#",
    "I": "###|.#.|.#.|.#.|.#.|.#.|###", "J": "..##|...#|...#|...#|#..#|#..#|.##.",
    "K": "#..#|#..#|#.#.|##..|#.#.|#..#|#..#", "L": "#...|#...|#...|#...|#...|#...|####",
    "M": "#...#|##.##|#.#.#|#.#.#|#...#|#...#|#...#", "N": "#..#|##.#|##.#|#.##|#.##|#..#|#..#",
    "O": ".##.|#..#|#..#|#..#|#..#|#..#|.##.", "P": "###.|#..#|#..#|###.|#...|#...|#...",
    "Q": ".##.|#..#|#..#|#..#|#..#|#.#.|.#.#", "R": "###.|#..#|#..#|###.|#.#.|#..#|#..#",
    "S": ".###|#...|#...|.##.|...#|...#|###.", "T": "#####|..#..|..#..|..#..|..#..|..#..|..#..",
    "U": "#..#|#..#|#..#|#..#|#..#|#..#|.##.", "V": "#...#|#...#|#...#|.#.#.|.#.#.|.#.#.|..#..",
    "W": "#...#|#...#|#...#|#.#.#|#.#.#|##.##|#...#", "X": "#..#|#..#|.##.|.##.|.##.|#..#|#..#",
    "Y": "#...#|#...#|.#.#.|..#..|..#..|..#..|..#..", "Z": "####|...#|..#.|.#..|#...|#...|####",
    "a": "....|....|.##.|...#|.###|#..#|.###", "b": "#...|#...|###.|#..#|#..#|#..#|###.",
    "c": "...|...|.##|#..|#..|#..|.##", "d": "...#|...#|.###|#..#|#..#|#..#|.###",
    "e": "....|....|.##.|#..#|####|#...|.###", "f": "..#|.#.|###|.#.|.#.|.#.|.#.",
    "g": "....|....|.###|#..#|#..#|#..#|.###|...#|.##.", "h": "#...|#...|###.|#..#|#..#|#..#|#..#",
    "i": "#|.|#|#|#|#|#", "j": "..#|...|..#|..#|..#|..#|..#|..#|##.",
    "k": "#...|#...|#..#|#.#.|##..|#.#.|#..#", "l": "#.|#.|#.|#.|#.|#.|.#",
    "m": ".....|.....|##.#.|#.#.#|#.#.#|#.#.#|#.#.#", "n": "....|....|###.|#..#|#..#|#..#|#..#",
    "o": "....|....|.##.|#..#|#..#|#..#|.##.", "p": "....|....|###.|#..#|#..#|#..#|###.|#...|#...",
    "q": "....|....|.###|#..#|#..#|#..#|.###|...#|...#", "r": "...|...|#.#|##.|#..|#..|#..",
    "s": "...|...|.##|#..|.#.|..#|##.", "t": ".#.|.#.|###|.#.|.#.|.#.|..#",
    "u": "....|....|#..#|#..#|#..#|#..#|.###", "v": "...|...|#.#|#.#|#.#|#.#|.#.",
    "w": ".....|.....|#...#|#.#.#|#.#.#|#.#.#|.#.#.", "x": "...|...|#.#|#.#|.#.|#.#|#.#",
    "y": "....|....|#..#|#..#|#..#|#..#|.###|...#|.##.", "z": "...|...|###|..#|.#.|#..|###",
    "0": ".##.|#..#|#.##|##.#|#..#|#..#|.##.", "1": ".#.|##.|.#.|.#.|.#.|.#.|###",
    "2": ".##.|#..#|...#|..#.|.#..|#...|####", "3": "###.|...#|...#|.##.|...#|...#|###.",
    "4": "#..#|#..#|#..#|####|...#|...#|...#", "5": "####|#...|#...|###.|...#|...#|###.",
    "6": ".##.|#...|#...|###.|#..#|#..#|.##.", "7": "####|...#|..#.|..#.|.#..|.#..|.#..",
    "8": ".##.|#..#|#..#|.##.|#..#|#..#|.##.", "9": ".##.|#..#|#..#|.###|...#|...#|.##.",
    " ": "..", "!": "#|#|#|#|#|.|#", '"': "#.#|#.#", "#": ".....|.#.#.|#####|.#.#.|#####|.#.#.",
    "$": "..#..|.####|#.#..|.###.|..#.#|####.|..#..", "%": "##..#|##.#.|..#..|.#...|#..##|...##",
    "&": ".#..|#.#.|#.#.|.#..|#.##|#..#|.##.", "'": "#|#", "(": ".#|#.|#.|#.|#.|#.|.#", ")": "#.|.#|.#|.#|.#|.#|#.",
    "*": "...|#.#|.#.|#.#", "+": "...|...|.#.|###|.#.", ",": ".|.|.|.|.|.|#|#", "-": "...|...|...|###",
    ".": ".|.|.|.|.|.|#", "/": "...#|...#|..#.|.##.|.#..|#...|#...", ":": ".|.|#|.|.|.|#", ";": ".|.|#|.|.|.|#|#",
    "<": "...|..#|.#.|#..|.#.|..#", "=": "...|...|###|...|###", ">": "...|#..|.#.|..#|.#.|#..",
    "?": ".##.|#..#|...#|..#.|.#..|....|.#..", "@": ".###.|#...#|#.###|#.#.#|#.##.|#....|.###.",
    "[": "##|#.|#.|#.|#.|#.|##", "\\": "#...|#...|.#..|.##.|..#.|...#|...#", "]": "##|.#|.#|.#|.#|.#|##",
    "^": ".#.|#.#", "_": "....|....|....|....|....|....|....|####", "`": "#.|.#",
    "{": "..#|.#.|.#.|#..|.#.|.#.|..#", "|": "#|#|#|#|#|#|#|#", "}": "#..|.#.|.#.|..#|.#.|.#.|#..",
    "~": "....|....|.#.#|#.#.",
    "ß": ".##.|#..#|#.#.|#..#|#..#|#..#|#.#.", "æ": ".....|.....|.##.#|...#.|.####|#..#.|.##.#",
    "Æ": ".####|#.#..|#.#..|####.|#.#..|#.#..|#.###", "ø": "....|....|.###|#.##|##.#|#..#|###.",
    "Ø": ".###|#.##|#.##|##.#|##.#|#..#|###.", "¡": "#|.|#|#|#|#|#", "¿": ".#..|....|.#..|#...|#...|#..#|.##.",
    "«": ".....|.....|.#.#.|#.#..|.#.#.", "»": ".....|.....|.#.#.|..#.#|.#.#.", "°": ".#.|#.#|.#.",
    "—": ".....|.....|.....|#####", "–": "....|....|....|####", "‘": ".#|#.", "’": ".#|#.", "“": ".#.#|#.#.", "”": ".#.#|#.#.",
    "✓": ".....|....#|...##|#.##.|###..|.#...", "○": ".###.|#...#|#...#|#...#|.###.", "▸": "#..|##.|###|##.|#..",
    "▾": "#####|.###.|..#..", "→": ".....|...#.|#####|...#.", "←": ".....|.#...|#####|.#...",
    "↑": "..#..|.###.|#.#.#|..#..|..#..|..#..", "↓": "..#..|..#..|..#..|#.#.#|.###.|..#..",
    "✦": "..#..|..#..|.###.|#####|.###.|..#..|..#..", "·": ".|.|.|#", "…": ".....|.....|.....|.....|.....|.....|#.#.#",
}
SYMBOL_TOP = {"✓": 2, "○": 2, "▸": 2, "▾": 3, "→": 2, "←": 2, "↑": 1, "↓": 1, "✦": 1, "·": 2, "«": 1, "»": 1,
              "°": 1, "—": 1, "–": 1, "+": 1, "=": 1, "-": 1, "~": 1, "*": 1, "<": 1, ">": 1, "#": 1}
ACCENTS = {"grave": ["#.", ".#"], "acute": [".#", "#."], "circ": [".#.", "#.#"], "tilde": [".#.#", "#.#."],
           "diaer": ["#.#"], "ring": [".#.", "#.#", ".#."]}
COMPOSED = {"À": ("A", "grave"), "Á": ("A", "acute"), "Â": ("A", "circ"), "Ã": ("A", "tilde"), "Ä": ("A", "diaer"),
            "Å": ("A", "ring"), "È": ("E", "grave"), "É": ("E", "acute"), "Ê": ("E", "circ"), "Ë": ("E", "diaer"),
            "Ì": ("I", "grave"), "Í": ("I", "acute"), "Î": ("I", "circ"), "Ï": ("I", "diaer"), "Ñ": ("N", "tilde"),
            "Ò": ("O", "grave"), "Ó": ("O", "acute"), "Ô": ("O", "circ"), "Õ": ("O", "tilde"), "Ö": ("O", "diaer"),
            "Ù": ("U", "grave"), "Ú": ("U", "acute"), "Û": ("U", "circ"), "Ü": ("U", "diaer"), "Ý": ("Y", "acute"),
            "à": ("a", "grave"), "á": ("a", "acute"), "â": ("a", "circ"), "ã": ("a", "tilde"), "ä": ("a", "diaer"),
            "å": ("a", "ring"), "è": ("e", "grave"), "é": ("e", "acute"), "ê": ("e", "circ"), "ë": ("e", "diaer"),
            "ì": ("ı", "grave"), "í": ("ı", "acute"), "î": ("ı", "circ"), "ï": ("ı", "diaer"), "ñ": ("n", "tilde"),
            "ò": ("o", "grave"), "ó": ("o", "acute"), "ô": ("o", "circ"), "õ": ("o", "tilde"), "ö": ("o", "diaer"),
            "ù": ("u", "grave"), "ú": ("u", "acute"), "û": ("u", "circ"), "ü": ("u", "diaer"), "ý": ("y", "acute"),
            "ÿ": ("y", "diaer")}
FONT["ı"] = ".|.|#|#|#|#|#"


def place(rows, top, width):
    cells = [["."] * width for _ in range(10)]
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if 0 <= top + y < 10 and x < width:
                cells[top + y][x] = ch
    return ["".join(r) for r in cells]


def font_glyphs():
    out = {}
    for ch, pat in FONT.items():
        rows = pat.split("|")
        w = max(len(r) for r in rows)
        out[ord(ch)] = (w, place(rows, SYMBOL_TOP.get(ch, 1), w))
    for ch, (letter, acc) in COMPOSED.items():
        w, cells = out[ord(letter)]
        cells = [list(r) for r in cells]
        mark = ACCENTS[acc]
        lower = letter.islower() or letter == "ı"
        aw = len(mark[0])
        ox = max(0, (w - aw + 1) // 2)
        if lower:
            for y in range(1, 3): cells[y] = ["."] * w
            top = 1 if len(mark) < 3 else 0
        else:
            top, mark = 0, mark[-1:] if acc != "ring" else [".#."]
        for y, row in enumerate(mark):
            for x, c in enumerate(row):
                if c == "#" and 0 <= ox + x < w: cells[top + y][ox + x] = "#"
        out[ord(ch)] = (w, ["".join(r) for r in cells])
    out[ord("Ç")] = cedilla(out[ord("C")])
    out[ord("ç")] = cedilla(out[ord("c")])
    out.pop(ord("ı"))
    return out


def cedilla(g):
    w, cells = g
    cells = [list(r) for r in cells]
    cells[8][1] = "#"; cells[9][0] = "#"
    return (w, ["".join(r) for r in cells])


# ------------------------------------------------------------------- entry
def sprites(Pixels):
    out = {}
    for k in range(7): out[f"calendar_ring{k}"] = ring(k)
    for s in ("spring", "summer", "autumn", "winter"): out[f"season_{s}"] = season_icon(s)
    for i in range(16):
        out[f"moon_purple{i}"] = moon(i, False); out[f"moon_white{i}"] = moon(i, True)
    for season in ("summer", "autumn", "winter"):
        for v in range(4): out[f"tile_grass{v}_{season}"] = grass(v, season)
        for v in range(2): out[f"tile_flowerbed{v}_{season}"] = flowerbed(v, season)
        for v, img in enumerate(seasonal_bushes(season)): out[f"bush{v}_{season}"] = img
        for species in ("oak", "birch", "pine"):
            for rows in (2, 3, 4):
                out[f"tree_{species}_{rows}_{season}"] = seasonal_tree(species, rows, season)
    out["tile_roof_snow"] = roof_snow()
    for kind in ("iron", "wood"):
        for m in range(16): out[f"tile_town_{kind}_mask{m}"] = fence(kind, m)
        out[f"tile_town_{kind}_gate"] = gate(kind)
    for m in range(16): out[f"wall_house_mask{m}"] = wall(m)
    out["furniture_millstone_3x3"] = millstone()
    out["furniture_mill_gears_2x2"] = mill_gears()
    out["bulletin_board"] = bulletin()
    out["woodpile"] = woodpile()
    for d in ("down", "up", "left", "right"):
        for f in range(3): out[f"actor_woodcutter_{d}{f}"] = town.actor(B, "woodcutter", WOODCUTTER, d, f)
    out["actor_woodcutter_sleep0"] = town.actor(B, "woodcutter", WOODCUTTER, "sleep", 0)
    return {k: conv(Pixels, v) for k, v in out.items()}
