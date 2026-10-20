"""Town expansion artwork for the rustic16 pack, painted at 16 pixels per game cell.

sprites(Pixels) returns {sprite_id: image}; the caller registers them in its atlas.
"""
import math

SH = (38, 24, 40)
STONE = ["34353d", "4e4f55", "6c6a69", "8a8579", "aaa292", "cfc6ae"]
WOOD = ["3a2418", "5a3824", "7c5131", "a06c41", "c38d58", "e0b67c"]
IRON = ["1f2329", "343b42", "52595e", "7a8183", "a9adaa"]
ROOF = ["4a1f1f", "6e2a28", "8c3a33", "a84a3a", "c4614a", "d98a68"]
WATER = ["1d3448", "285468", "3a7886", "5ea2a6", "a3d4c9", "e4f4e6"]
ALGAE = ["24372a", "34502f", "4f6e36", "6d8a40"]


def rgb(c):
    if isinstance(c, tuple):
        return c if len(c) == 4 else tuple(c) + (255,)
    return tuple(bytes.fromhex(c)) + (255,)


def mix(a, b, t):
    a, b = rgb(a), rgb(b)
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3)) + (a[3],)


def shade(c, k):
    if k < 0:
        return mix(c, (46, 28, 56), min(1, -k * 0.22))
    return mix(c, (255, 242, 198), min(1, k * 0.2))


def fade(c, a):
    return rgb(c)[:3] + (a,)


def h01(x, y, s=0):
    n = (x * 374761393 + y * 668265263 + s * 2246822519 + 1013904223) & 0xFFFFFFFF
    n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((n ^ (n >> 16)) & 0xFFFF) / 65535


def flags(p, gx, gy, ramp, seed, mortar, moss=None, squash=1.0, w=16, h=16):
    """Tileable irregular stones from a jittered torus Voronoi; returns the cell map."""
    pts = [((i + 0.15 + 0.7 * h01(i, j, seed)) * w / gx + (j % 2) * w / gx / 2,
            (j + 0.2 + 0.6 * h01(j, i, seed + 1)) * h / gy) for i in range(gx) for j in range(gy)]
    cell = {}
    for y in range(h):
        for x in range(w):
            ds = []
            for i, (px, py) in enumerate(pts):
                dx = abs(x + 0.5 - px) % w; dy = abs(y + 0.5 - py) % h
                ds.append((math.hypot(min(dx, w - dx), min(dy, h - dy) * squash), i))
            ds.sort()
            cell[x, y] = -1 if ds[1][0] - ds[0][0] < 0.9 else ds[0][1]
    for (x, y), i in cell.items():
        if i < 0:
            p.dot(x, y, moss if moss and h01(x, y, seed + 7) > 0.72 else mortar)
            continue
        c = ramp[2 + (h01(i, 3, seed) > 0.5)]
        if cell[x, (y - 1) % h] != i:
            c = shade(c, 1.1)
        elif cell[(x - 1) % w, y] != i:
            c = shade(c, 0.5)
        elif cell[x, (y + 1) % h] != i or cell[(x + 1) % w, y] != i:
            c = shade(c, -0.9)
        r = h01(x, y, seed + 3)
        p.dot(x, y, shade(c, -0.7) if r > 0.9 else shade(c, 0.7) if r < 0.07 else c)
    return cell


def ground_shadow(p, cx, cy, rx, ry, a=90):
    p.oval(cx, cy, rx, ry, fade(SH, a))


# ---------------------------------------------------------------- coast & lighthouse
JETTY = ["2f3238", "4a4b50", "7a7770", "8d887c", "aca391", "cdc3aa"]


def jetty(P):
    p = P(16, 16)
    flags(p, 2, 2, JETTY, 41, "3e3d40")
    for x, y in ((3, 12), (12, 5), (9, 14)):
        if h01(x, y, 2) > 0.3: p.dot(x, y, "b9ad6e")
    return p


def jetty_edge(P, side):
    p = jetty(P)
    if side == "s":
        for x in range(16):
            p.dot(x, 10, shade(JETTY[4], 0.8)); p.dot(x, 11, JETTY[3])
            for y in range(12, 16):
                c = JETTY[2] if y < 14 else JETTY[1]
                if (x + (4 if y >= 14 else 0)) % 8 == 0 or y == 13: c = "33343a"
                if y >= 14 and h01(x, y, 5) > 0.35: c = ALGAE[1 + (h01(x, y, 6) > 0.6)]
                p.dot(x, y, c)
            if h01(x, 0, 9) > 0.75: p.dot(x, 12, ALGAE[2])
        p.hline(0, 15, 15, ALGAE[0])
        return p
    put = {"n": lambda u, v: (u, v), "e": lambda u, v: (15 - v, u), "w": lambda u, v: (v, u)}[side]
    for u in range(16):
        joint = u % 6 == (2 if side == "n" else 4)
        p.dot(*put(u, 0), ALGAE[0] if h01(u, 1, 3) > 0.45 else "2c3236")
        p.dot(*put(u, 1), ALGAE[2] if h01(u, 2, 3) > 0.7 else JETTY[2])
        p.dot(*put(u, 2), "3a3b3f" if joint else shade(JETTY[4], 0.6))
        p.dot(*put(u, 3), "3a3b3f" if joint else JETTY[3])
        p.dot(*put(u, 4), "3a3b3f")
    return p


LIME = ["8f8a7a", "b3ad98", "d4cdb4", "e6e0c8", "f4eed8"]
RED = ["5e2a26", "7a3530", "9c4538", "b45a46", "c97a62"]


def limewash(P, ramp=LIME, seed=0):
    p = P(16, 16)
    for y in range(16):
        for x in range(16):
            n = h01(x // 2, y, seed + 11)
            c = ramp[3] if n > 0.25 else ramp[2]
            row, off = y // 4, 0 if (y // 4) % 2 else 4
            if y % 4 == 3 or (x + off) % 8 == 7:
                c = ramp[2] if h01(x, y, seed) > 0.35 else c
            if h01(x // 3, y // 3, seed + 4) > 0.93: c = ramp[1]
            if h01(x, 0, seed + 8) > 0.86 and y > 6: c = mix(c, ramp[1], 0.4)
            p.dot(x, y, c)
    for x, y in ((3, 5), (11, 10), (6, 13)):
        p.dot(x, y, ramp[4]); p.dot(x + 1, y, ramp[4])
    return p


def lighthouse(P, kind):
    p = limewash(P, RED if kind == "stripe" else LIME, 3 if kind == "stripe" else 0)
    if kind == "stripe":
        p.hline(0, 15, 0, RED[1]); p.hline(0, 15, 15, RED[0])
    if kind == "window":
        p.box(3, 1, 10, 13, STONE[4]); p.vline(3, 1, 13, STONE[5]); p.hline(3, 12, 1, STONE[5])
        for y in (5, 9): p.hline(3, 4, y, STONE[2]); p.hline(11, 12, y, STONE[2])
        p.box(5, 3, 6, 9, "2b2e36")
        for y in range(4, 11):
            for x in range(6, 10):
                p.dot(x, y, mix("6f9aa4", "c8dccf", max(0, 1 - (y - 4 + x - 6) / 6)))
        p.vline(7, 4, 10, IRON[1]); p.hline(6, 9, 7, IRON[1]); p.dot(6, 4, WATER[5])
        p.box(2, 12, 12, 2, STONE[4]); p.hline(2, 13, 12, STONE[5]); p.hline(2, 13, 14, fade(SH, 110))
    if kind == "door_top":
        for y in range(16):
            for x in range(1, 15):
                d = math.hypot(x + 0.5 - 8, max(0, 9 - y) * 1.2)
                if d <= 7: p.dot(x, y, STONE[4] if (x + y) % 4 else STONE[3])
                if d <= 5.2: p.dot(x, y, WOOD[2] if (x - 3) % 3 else WOOD[1])
        p.box(7, 2, 2, 2, STONE[5]); p.dot(7, 3, STONE[3])
        p.hline(4, 11, 12, IRON[1]); p.dot(4, 12, IRON[3])
    if kind == "door_bottom":
        p.box(1, 0, 3, 14, STONE[4]); p.box(12, 0, 3, 14, STONE[3]); p.vline(1, 0, 13, STONE[5])
        for y in (4, 9): p.hline(1, 3, y, STONE[2]); p.hline(12, 14, y, STONE[2])
        for x in range(4, 12): p.vline(x, 0, 13, WOOD[2] if (x - 3) % 3 else WOOD[1])
        p.vline(4, 0, 13, WOOD[3]); p.hline(4, 11, 3, IRON[1]); p.hline(4, 11, 10, IRON[1])
        p.dot(10, 7, "d2a24c"); p.dot(10, 8, IRON[0])
        p.box(0, 14, 16, 2, STONE[3]); p.hline(0, 15, 14, STONE[5])
    return p


def lantern(P, idx):
    p = P(16, 16)
    for x in range(16):
        g = idx * 16 + x
        if 3 <= g <= 44:
            for y in range(2, 12):
                warm = 1 - min(1, abs(g - 23.5) / 22)
                p.dot(x, y, mix("d9a64e", "fff0b8", warm * 0.8 + (0.15 if y < 5 else 0)))
            if g in (3, 13, 23, 24, 34, 44):
                p.vline(x, 2, 11, IRON[1] if g != 3 else IRON[2])
            p.hline(x, x, 0, IRON[1]); p.dot(x, 1, IRON[3] if g < 24 else IRON[2])
            if (g + 1) % 5 == 0: p.dot(x, 3, fade("ffffff", 120))
        p.dot(x, 11, IRON[3]); p.dot(x, 14, IRON[2]); p.dot(x, 15, IRON[0])
        if g % 3 == 0: p.vline(x, 12, 13, IRON[1])
    if idx == 1:
        p.oval(7.5, 7, 4, 4.5, "fff6d6")
        for y in (4, 6, 8, 10): p.hline(5, 10, y, "f0cf7a")
        p.box(7, 6, 2, 2, "ffffff"); p.box(5, 11, 6, 1, IRON[1])
    return p


def cap(P, idx):
    p = P(16, 16)
    for x in range(16):
        g = idx * 16 + x
        top = int(2 + abs(g - 23.5) / 23.5 * 11)
        for y in range(top, 14):
            c = mix(ROOF[4], ROOF[2], g / 47)
            if y % 3 == 0 or (g + (y // 3) * 2) % 5 == 0: c = shade(c, -1.0)
            r = h01(g, y, 21)
            c = ROOF[5] if r > 0.92 else mix(c, "6d6a4a", 0.5) if r < 0.05 else c
            p.dot(x, y, shade(c, 1.2) if y == top else c)
        p.dot(x, 14, ROOF[1]); p.dot(x, 15, ROOF[0])
    if idx == 1:
        p.vline(7, 0, 2, IRON[1]); p.vline(8, 0, 2, IRON[2]); p.box(7, 0, 2, 1, "d2a24c")
    return p


# ------------------------------------------------------------------ town tiles
def sign(P, kind):
    p = P(16, 16)
    p.vline(1, 0, 3, IRON[1]); p.hline(1, 14, 1, IRON[2]); p.dot(14, 2, IRON[2]); p.dot(13, 2, IRON[1])
    p.vline(4, 2, 3, IRON[3]); p.vline(11, 2, 3, IRON[3])
    p.box(2, 4, 12, 10, WOOD[1]); p.box(3, 5, 10, 8, WOOD[3]); p.hline(3, 12, 5, WOOD[4])
    p.hline(2, 13, 14, fade(SH, 100))
    if kind == "smithy":
        p.box(5, 8, 7, 2, IRON[1]); p.hline(4, 11, 7, IRON[3]); p.box(7, 10, 3, 2, IRON[0])
        p.line(9, 6, 12, 9, WOOD[0]); p.box(8, 5, 2, 2, IRON[2])
    elif kind == "bakery":
        p.oval(7.5, 9, 4, 2.2, "c88a3c"); p.oval(7.5, 8.5, 3.5, 1.5, "e3ac5a")
        for x in (5, 7, 9): p.dot(x, 8, "f5d48a"); p.dot(x + 1, 9, "a0662a")
    else:
        p.box(5, 7, 5, 5, "d79a32"); p.vline(5, 7, 11, "f0c060"); p.box(10, 8, 2, 3, IRON[2])
        p.dot(11, 9, WOOD[3]); p.hline(4, 10, 6, "f6f0de"); p.dot(6, 5, "f6f0de"); p.dot(8, 5, "f6f0de")
    return p


def mill_wall(P):
    p = P(16, 16)
    flags(p, 3, 4, ["3a342e", "524a40", "8a7c68", "9a8c76", "b8a98e", "d6c8aa"], 57, "5a5248", squash=1.7)
    for x in range(16):
        if h01(x, 4, 1) > 0.8: p.dot(x, 15, ALGAE[2])
    return p


def sails(P, frame):
    p = P(48, 48)
    base = frame * math.pi / 8 + 0.3
    for y in range(48):
        for x in range(48):
            dx, dy = x + 0.5 - 24, y + 0.5 - 24
            for arm in range(4):
                a = base + arm * math.pi / 2
                al = dx * math.cos(a) + dy * math.sin(a)
                pe = -dx * math.sin(a) + dy * math.cos(a)
                if 2 <= al <= 23 and abs(pe) < 0.85:
                    p.dot(x, y, WOOD[2] if pe < 0 else WOOD[1]); break
                if 6 <= al <= 22 and 1 <= pe <= 7:
                    lattice = al % 3.2 < 0.9 or pe > 6.2
                    p.dot(x, y, WOOD[3] if lattice else mix("efe4c8", "b9ab8c", (pe - 1) / 7)); break
    p.oval(23.5, 23.5, 2.6, 2.6, WOOD[0]); p.oval(23.5, 23.5, 1.5, 1.5, WOOD[3]); p.dot(23, 23, IRON[4])
    return p


def paving(P, v):
    p = P(16, 16)
    ramp = ["3d3832", "57504a", "8e8476", "9e9282", "bbae98", "d6caae"]
    flags(p, 4, 3, ramp, 70 + v, "4c463e", moss=ALGAE[2] if v else None, squash=1.2)
    return p


def flowerbed(P, v):
    p = P(16, 16)
    for y in range(13):
        for x in range(16):
            p.dot(x, y, ["3e281c", "4e3324", "5e3e2a"][int(h01(x, y, 90) * 3)])
    blooms = (("c84a3e", "e8c04a"), ("6a7ad0", "f2ece0"))[v]
    for i in range(7):
        cx, cy = int(1 + h01(i, v, 91) * 13), int(1 + h01(v, i, 92) * 9)
        p.dot(cx, cy + 2, ALGAE[2]); p.dot(cx - 1, cy + 2, ALGAE[3]); p.dot(cx + 1, cy + 1, ALGAE[1])
        c = blooms[i % 2]
        for dx, dy in ((0, 0), (1, 0), (0, -1), (-1, 0), (0, 1)):
            p.dot(cx + dx, cy + dy, c if (dx or dy) else "f6e08a")
        p.dot(cx - 1, cy - 1, shade(c, 1.4))
    p.box(0, 13, 16, 3, STONE[3]); p.hline(0, 15, 13, STONE[5]); p.hline(0, 15, 15, STONE[1])
    for x in (4, 10, 15): p.vline(x, 13, 15, STONE[1])
    return p


# ------------------------------------------------------------------- props
def bench(P):
    p = P(32, 24)
    ground_shadow(p, 16, 21, 14, 2.4)
    for x in (3, 27):
        p.vline(x, 3, 21, IRON[1]); p.vline(x + 1, 3, 21, IRON[0]); p.dot(x, 3, IRON[3])
    for y0 in (4, 8):
        p.box(2, y0, 28, 3, WOOD[3]); p.hline(2, 29, y0, WOOD[4]); p.hline(2, 29, y0 + 2, WOOD[2])
    p.box(1, 12, 30, 3, WOOD[4]); p.hline(1, 30, 12, WOOD[5]); p.box(1, 15, 30, 2, WOOD[2])
    p.hline(1, 30, 17, WOOD[0])
    for x in range(4, 28, 5): p.vline(x, 12, 16, WOOD[3]); p.dot(x, 5, WOOD[1])
    p.line(3, 17, 6, 20, IRON[1]); p.line(28, 17, 25, 20, IRON[1])
    return p


def fountain(P, f):
    p = P(32, 40)
    st = STONE
    cx, cy, rx, ry = 15.5, 29, 15, 6
    ground_shadow(p, 15.5, 36.5, 15, 3)
    for x in range(1, 31):
        t = (x + 0.5 - cx) / rx
        yb = int(cy + ry * math.sqrt(max(0, 1 - t * t)))
        tone = st[4] if t < -0.4 else st[3] if t < 0.4 else st[2]
        p.vline(x, int(cy), yb + 4, tone); p.dot(x, yb + 5, st[1])
        if x % 6 == 3: p.vline(x, yb + 1, yb + 4, st[1])
    p.oval(cx, cy - 0.6, rx, ry, st[5]); p.oval(cx, cy, rx, ry, st[4])
    for a in range(0, 360, 37):
        r = math.radians(a); p.dot(cx + math.cos(r) * (rx - 0.7), cy + math.sin(r) * (ry - 0.5), st[3])
    p.oval(cx, cy + 0.4, rx - 2.2, ry - 1.8, WATER[1]); p.oval(cx, cy + 1.2, rx - 3.2, ry - 2.6, WATER[2])
    p.box(13, 17, 6, 13, st[3]); p.vline(13, 17, 29, st[5]); p.vline(18, 17, 29, st[1])
    p.hline(13, 18, 23, st[2])
    for x in range(9, 23):
        t = (x + 0.5 - 15.5) / 7
        p.vline(x, 17, int(17 + 2.2 * math.sqrt(max(0, 1 - t * t))) + 2, st[3] if x < 16 else st[2])
    p.oval(15.5, 16.6, 7, 2.2, st[5]); p.oval(15.5, 17, 7, 2.2, st[4]); p.oval(15.5, 16.9, 5, 1.3, WATER[3])
    p.box(15, 14, 2, 2, st[4]); p.dot(16, 15, st[2])
    # animated water only below this line
    for x in (8, 23):
        for y in range(18, 27):
            p.dot(x, y, WATER[4] if (y + f) % 4 == 0 else WATER[3])
    for x, y in ((8, 27), (23, 27), (7, 27), (24, 27)): p.dot(x, y, WATER[5] if (x + f) % 2 else WATER[4])
    r = 3 + f * 1.8
    for a in range(0, 180, 18):
        t = math.radians(a + f * 9)
        p.dot(cx + math.cos(t) * r, cy + 1.6 + math.sin(t) * r * 0.32, WATER[4])
    p.dot(int(6 + f * 5) % 22 + 5, 31, WATER[5]); p.dot(12 + f, 17, WATER[5])
    top = 5 + (f % 2)
    p.vline(15, top, 13, WATER[4]); p.vline(16, top + 1, 13, WATER[3]); p.dot(15, top, WATER[5])
    p.dot(15, top - 1, fade(WATER[5], 160))
    for k in range(3):
        t = ((f / 4) + k / 3) % 1
        for side in (-1, 1):
            x = 15.5 + side * (1 + t * 5)
            y = top + 1 - 4 * t + 9 * t * t
            if y <= 13.5: p.dot(x, y, WATER[5] if k == 0 else WATER[4])
    return p


def bricks(p, x0, y0, w, h, ramp, seed, bw=5, bh=3):
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            r, off = (y - y0) // bh, 0 if ((y - y0) // bh) % 2 else bw // 2
            joint = (y - y0) % bh == bh - 1 or (x - x0 + off) % bw == bw - 1
            tone = ramp[2 + (h01((x - x0 + off) // bw, r, seed) > 0.55)]
            p.dot(x, y, ramp[1] if joint else shade(tone, 0.6) if (y - y0) % bh == 0 else tone)


BRICK = ["3a2420", "5a3a30", "8a5444", "9c6250", "b87a60", "d49a7a"]


def forge(P):
    p = P(48, 40)
    ground_shadow(p, 24, 37.5, 23, 2.5, 100)
    bricks(p, 15, 0, 18, 17, BRICK, 5, 6, 3)
    p.vline(15, 0, 16, BRICK[4]); p.vline(32, 0, 16, BRICK[1])
    p.oval(24, 14, 6, 5, "1e1418"); p.box(18, 14, 13, 3, "1e1418")
    p.oval(24, 15.5, 4.5, 2.5, "a8402a"); p.oval(24, 16, 3, 1.5, "f09a3a"); p.box(23, 11, 2, 4, "f5c060")
    bricks(p, 3, 20, 42, 17, STONE, 8, 8, 4)
    p.vline(3, 20, 36, STONE[4]); p.vline(44, 20, 36, STONE[1]); p.hline(3, 44, 37, STONE[0])
    p.box(2, 16, 44, 4, STONE[4]); p.hline(2, 45, 16, STONE[5]); p.hline(2, 45, 19, STONE[2])
    p.oval(24, 17.5, 9, 1.6, "2a1d22")
    for i in range(22):
        x, y = 16 + int(h01(i, 1, 30) * 16), 17 + int(h01(i, 2, 30) * 2)
        p.dot(x, y, ["c4482c", "f08a3a", "ffd27a"][int(h01(i, 3, 30) * 3)])
    p.oval(24, 31, 4, 3.5, "1e1418"); p.box(20, 31, 9, 6, "1e1418"); p.hline(21, 27, 35, "7a3424")
    p.polygon([(3, 12), (12, 14), (12, 16), (3, 16)], "6a4a34")
    for x in (5, 8, 11): p.vline(x, 12, 15, "4a3224")
    p.hline(3, 11, 12, "8a6448"); p.line(12, 15, 15, 16, IRON[2])
    p.box(37, 11, 7, 6, WOOD[2]); p.hline(37, 43, 13, IRON[1]); p.vline(37, 11, 16, WOOD[3])
    p.oval(40, 11, 3.5, 1, WATER[2]); p.dot(39, 11, WATER[4])
    return p


def anvil(P):
    p = P(16, 24)
    ground_shadow(p, 8, 21.5, 6.5, 2)
    p.box(3, 14, 10, 8, WOOD[2]); p.vline(3, 14, 21, WOOD[3]); p.vline(12, 14, 21, WOOD[1])
    p.oval(7.5, 14, 5, 1.6, WOOD[4]); p.oval(7.5, 14, 2.5, 0.8, WOOD[3])
    p.box(6, 10, 4, 4, IRON[1]); p.box(4, 12, 8, 2, IRON[1]); p.hline(4, 11, 13, IRON[0])
    p.polygon([(1, 7), (5, 6), (13, 6), (13, 10), (5, 10), (3, 9)], IRON[2])
    p.hline(5, 13, 6, IRON[4]); p.hline(2, 4, 7, IRON[3]); p.hline(5, 13, 10, IRON[0])
    p.dot(11, 7, IRON[1])
    return p


def oven(P):
    p = P(32, 40)
    ground_shadow(p, 16, 37.5, 15, 2.5, 100)
    bricks(p, 2, 27, 28, 11, STONE, 9, 7, 4)
    p.hline(2, 29, 27, STONE[5]); p.vline(29, 27, 37, STONE[1])
    for y in range(6, 28):
        for x in range(2, 30):
            if ((x + 0.5 - 16) / 13.5) ** 2 + ((y + 0.5 - 24) / 18) ** 2 <= 1:
                light = 1 - (x - 2) / 28 * 0.8 - (y - 6) / 22 * 0.3
                c = mix("8a4a34", "c8805c", light)
                if y % 3 == 0 or (x + (y // 3) * 3) % 6 == 0: c = shade(c, -0.8)
                p.dot(x, y, c)
    p.box(21, 3, 4, 7, BRICK[2]); p.hline(20, 25, 3, BRICK[4]); p.vline(24, 4, 9, BRICK[1])
    p.oval(16, 21, 6, 4, STONE[4]); p.box(10, 21, 13, 7, STONE[4])
    p.oval(16, 21.5, 4.5, 3, "1e1418"); p.box(12, 21, 9, 6, "1e1418")
    p.oval(16, 25.5, 4, 1.2, "c4502c"); p.hline(13, 19, 26, "f09a3a")
    p.dot(14, 25, "ffd27a"); p.dot(18, 24, "ffd27a"); p.oval(16, 24, 2, 0.9, "d8a04c")
    p.hline(10, 22, 27, STONE[5])
    return p


def barrel(p, x0, y0, w, h):
    for x in range(x0, x0 + w):
        t = (x - x0) / (w - 1)
        c = mix(WOOD[4], WOOD[1], t)
        bulge = 1 if x in (x0, x0 + w - 1) else 0
        p.vline(x, y0 + 1 + bulge, y0 + h - 1 - bulge, shade(c, -0.6) if (x - x0) % 3 == 2 else c)
    for y in (y0 + 3, y0 + h - 4):
        p.hline(x0, x0 + w - 1, y, IRON[1]); p.dot(x0 + 1, y, IRON[3])
    p.oval(x0 + (w - 1) / 2, y0 + 1, w / 2 - 0.5, 1.4, WOOD[3]); p.hline(x0 + 2, x0 + w - 3, y0 + 1, WOOD[1])


def barrels(P):
    p = P(32, 24)
    ground_shadow(p, 16, 21.5, 15, 2)
    barrel(p, 1, 4, 14, 18); barrel(p, 17, 3, 14, 19)
    return p


def sack(p, cx, base, w, h):
    rx, ry = w / 2, h / 2
    for y in range(int(base - h), base + 1):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - (base - ry)) / ry) ** 2 <= 1:
                light = 1 - (x - cx + rx) / w * 0.7
                c = mix("a8977a", "eadfc4", light)
                p.dot(x, y, shade(c, -0.5) if h01(x, y, 44) > 0.85 else c)
    top = int(base - h)
    p.box(int(cx) - 1, top - 2, 3, 3, "c8b896"); p.hline(int(cx) - 2, int(cx) + 2, top, "7a5a3a")
    p.dot(int(cx), int(base - ry), "b8a27a"); p.dot(int(cx) - 1, int(base - ry) + 1, "b8a27a")


def flour(P):
    p = P(32, 24)
    ground_shadow(p, 16, 21.5, 15, 2)
    sack(p, 8, 21, 13, 12); sack(p, 23, 21, 13, 11); sack(p, 15.5, 13, 12, 9)
    for x, y in ((2, 22), (4, 23), (27, 22), (29, 23), (13, 22)): p.dot(x, y, "f4eedc")
    return p


def item_wildgrowth(P):
    p = P(16, 16)
    p.polygon([(3, 13), (5, 6), (10, 2), (13, 3), (11, 9), (6, 13)], "4f8a3a")
    p.polygon([(4, 12), (6, 6), (10, 3), (8, 8)], "7fb04a")
    p.line(4, 13, 11, 4, "2f5a2c"); p.dot(7, 8, "2f5a2c"); p.dot(9, 7, "a8d070")
    p.line(2, 14, 4, 12, WOOD[2])
    for x, y, c in ((12, 9, "f6e08a"), (13, 12, "fff6c8"), (5, 3, "f6e08a"), (2, 7, "c8f0a0")):
        p.dot(x, y, c); p.dot(x + 1, y, fade(c, 140)); p.dot(x - 1, y, fade(c, 140))
        p.dot(x, y + 1, fade(c, 140)); p.dot(x, y - 1, fade(c, 140))
    return p


def item_sit(P):
    p = P(16, 16)
    p.box(4, 2, 2, 12, WOOD[2]); p.box(10, 8, 2, 6, WOOD[1]); p.box(4, 2, 2, 1, WOOD[4])
    p.box(4, 3, 7, 2, WOOD[3]); p.box(4, 8, 8, 2, WOOD[4]); p.hline(4, 11, 8, WOOD[5])
    p.hline(4, 11, 10, WOOD[1]); p.vline(5, 10, 13, WOOD[1]); p.box(4, 14, 8, 1, fade(SH, 80))
    return p


# -------------------------------------------------------------------- people
HEAD_DOWN = ["......HHHH......", "....HLLHHHHH....", "...HLLHHHHHHh...", "...HHHHHHHHHh...",
             "...HHSSSSSSHh...", "...HSSSSSSSSh...", "...hSESSSSESh...", "...sSESSSSESs...",
             "....SrSSSSrS....", "....sSSmmSSs....", ".....ssSSss....."]
HEAD_UP = ["......HHHH......", "....HLLHHHHH....", "...HLLHHHHHHh...", "...HHHHHHHHHh...",
           "...HHHHHHHHHh...", "...HHHHHHHHHh...", "...hHHHHHHHHh...", "...shHHHHHHhs...",
           "....hHHHHHHh....", "....shhhhhhs....", ".....ssSSss....."]
HEAD_SIDE = ["......HHHH......", "....HLLHHHHH....", "...HLLHHHHHHH...", "...HHHHHHHHHH...",
             "...hHHHHSSSSS...", "...hHHHSSSSSS...", "...hHHsSSSSES...", "...hHhsSSSSESS..",
             "....hHSSSSSrS...", "....hsSSSSSm....", ".....ssSSSs....."]
BODY_DOWN = ["....CCWssWCC....", "...ACCWWWWCCa...", "..AACCCWWCCCaa..", "..AACCCCCCCCaa..",
             "..AACCCCCCCCaa..", "..kAbbbbbbbbak..", "..k.CCCCCCCc.k.."]
BODY_UP = ["....CCCssCCC....", "...ACCCCCCCCa...", "..AACCCCcCCCaa..", "..AACCCCcCCCaa..",
           "..AACCCCcCCCaa..", "..kAbbbbbbbbak..", "..k.CCCCCCCc.k.."]
BODY_SIDE = [".....CCsCCC.....", "....cCCCWCCC....", "....cCAACCCC....", "....cCAaCCCC....",
             "....cCAaCCCC....", "....cbAabbbb....", "....cCkkCCCc...."]

PEOPLE = {
    "farmer_mother": ("7a8a62", "1e1a20", "d4a580", "5b4a3a", "eadfc4", ("skirt", "apron:8b5a34", "braid")),
    "farmer_father": ("4f7a45", "6a4630", "cf9f78", "4d4538", "d8cfae", ("suspenders",)),
    "farmer_son": ("9a8a5e", "6e4a30", "dcae86", "4a5060", "c0443a", ("child", "scarf")),
    "smith": ("6a5a50", "9a9894", "6e4632", "3a3430", "7a6a5e", ("bare", "leather", "beard")),
    "miller": ("d8ccb0", "2e2624", "c8966e", "5a5048", "efe6d0", ("rolled", "vest")),
    "miller_wife": ("a07c5a", "c0643a", "e0b490", "5a4a40", "e8dcc6", ("long", "skirt", "headscarf")),
    "miller_daughter": ("6e4a8a", "3a2a2a", "d8a882", "3e3a4a", "d8c8a0", ("pony",)),
    "barkeep": ("8a3a34", "2a2224", "d09c7a", "2e2a30", "ece2cc", ("stripes", "moustache")),
    "baker": ("c9b89a", "b8452e", "e6b896", "6a5a4a", "f4efe4", ("rolled", "apron:f1ebde", "toque")),
}


def palette(coat, hair, skin, pants, accent):
    return {"H": hair, "h": shade(hair, -1.6), "L": shade(hair, 1.6), "S": skin, "s": shade(skin, -1.2),
            "r": mix(skin, "e0716a", 0.35), "m": shade(skin, -1.1), "E": "2a2230", "C": coat,
            "c": shade(coat, -1.3), "A": shade(coat, 0.4), "a": shade(coat, -1.0), "W": accent,
            "b": shade(coat, -3.0), "k": skin, "P": pants, "p": shade(pants, -1.2), "B": WOOD[1],
            "O": WOOD[0], "X": "e6dcc8", "x": "b8ae9c"}


def stamp(p, rows, y0, pal, shift, remap):
    for r, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch == ".": continue
            dx, dy = shift(x, r, ch)
            p.dot(x + dx, y0 + r + dy, pal[remap(x, r, ch)])


def legs(p, d, frame, pal):
    P_, pd, B, O = pal["P"], pal["p"], pal["B"], pal["O"]
    if d in ("down", "up"):
        p.hline(4, 11, 24, P_); p.hline(4, 11, 25, pd)
        for lx, lift in ((5, frame == 1), (8, frame == 2)):
            foot = 28 - lift
            p.vline(lx, 26, foot - 1, P_); p.vline(lx + 1, 26, foot - 1, P_); p.vline(lx + 2, 26, foot - 1, pd)
            bx = lx - 1 if lx == 5 else lx
            p.hline(bx, bx + 3, foot, B); p.hline(bx, bx + 3, foot + 1, O)
            p.dot(bx + (0 if lx == 5 else 3), foot, shade(B, 1.2))
        if d == "up": p.vline(7, 24, 25, pd)
        return
    p.hline(5, 10, 24, P_); p.hline(5, 10, 25, pd)
    if frame == 0:
        p.box(6, 26, 4, 2, P_); p.vline(9, 26, 27, pd)
        p.hline(6, 10, 28, B); p.hline(6, 11, 29, O); p.dot(10, 28, shade(B, 1.2))
        return
    front, back = (P_, pd) if frame == 1 else (pd, P_)
    p.line(8, 26, 10, 27, front); p.line(9, 26, 11, 27, front)
    p.line(7, 26, 5, 27, back); p.line(6, 26, 4, 27, back)
    p.hline(9, 12, 28, B); p.hline(9, 12, 29, O); p.dot(12, 28, shade(B, 1.2))
    p.hline(3, 6, 28, shade(B, -0.5)); p.hline(3, 6, 29, O)


def remapper(extras):
    def remap(x, r, ch):
        if ch in "Aa" and (("rolled" in extras and r >= 3) or ("bare" in extras and r >= 1)):
            return "S" if ch == "A" else "s"
        if "stripes" in extras:
            if ch in "Aa": return "X" if ch == "A" else "x"
            if ch == "C" and x % 2 == 0 and 1 <= r <= 4: return "c"
        return ch
    return remap


def overlay(p, kind, d, pal, y, frame):
    side, H, h = d == "right", pal["H"], pal["h"]
    if kind.startswith("apron"):
        c = kind.split(":")[1]
        if d == "down":
            p.box(5, 19 + y, 6, 7, c); p.hline(5, 10, 19 + y, shade(c, 1)); p.vline(10, 20 + y, 25 + y, shade(c, -1))
            p.dot(4, 22 + y, shade(c, -1.5)); p.dot(11, 22 + y, shade(c, -1.5))
        elif side:
            p.box(10, 19 + y, 2, 7, c); p.vline(11, 19 + y, 25 + y, shade(c, -1))
        else:
            p.dot(7, 22 + y, c); p.dot(8, 22 + y, shade(c, -1)); p.dot(7, 23 + y, c)
    elif kind == "skirt":
        c = pal["c"]
        if side: p.box(5, 24, 6, 3, c); p.hline(5, 10, 26, shade(c, -1))
        else: p.box(4, 24, 8, 2, c); p.hline(3, 12, 26, shade(c, -1))
    elif kind == "braid":
        pts = {"down": (11, 15, 22), "up": (7, 16, 23), "right": (4, 15, 21)}[d]
        for i, yy in enumerate(range(pts[1] + y, pts[2] + y)):
            p.dot(pts[0], yy, H if i % 2 else h); p.dot(pts[0] + 1, yy, h if i % 2 else H)
        p.dot(pts[0], pts[2] + y, "c84a3e")
    elif kind == "suspenders":
        c = "5a3a26"
        if d == "down": p.vline(5, 17 + y, 22 + y, c); p.vline(10, 17 + y, 22 + y, c)
        elif side: p.vline(9, 18 + y, 22 + y, c)
        else: p.line(5, 17 + y, 10, 22 + y, c); p.line(10, 17 + y, 5, 22 + y, c)
    elif kind == "scarf":
        c, dk = pal["W"], shade(pal["W"], -1.2)
        p.hline(5, 10, 17 + y, c); p.hline(5, 10, 18 + y, dk)
        if d == "down": p.box(9, 19 + y, 2, 2, c)
        else:
            tx = 4 if side else 6
            p.box(tx, 18 + y, 2, 2, c); p.dot(tx - (1 if frame else 0), 20 + y, dk)
    elif kind == "leather":
        c = "5a3a2a"
        if d == "down":
            p.box(4, 18 + y, 8, 8, c); p.hline(4, 11, 18 + y, "7a5440"); p.vline(11, 19 + y, 25 + y, "3e281e")
            p.dot(5, 19 + y, "c8a050"); p.dot(10, 19 + y, "c8a050"); p.hline(6, 9, 22 + y, "3e281e")
        elif side:
            p.box(9, 18 + y, 3, 8, c); p.vline(11, 18 + y, 25 + y, "3e281e")
        else:
            p.line(5, 17 + y, 10, 22 + y, c); p.line(10, 17 + y, 5, 22 + y, c)
    elif kind == "vest":
        c = "7a5a3a"
        if d == "down":
            for x0 in (4, 10): p.box(x0, 18 + y, 2, 5, c)
            p.vline(5, 18 + y, 22 + y, shade(c, 0.8))
        elif side: p.box(7, 18 + y, 3, 5, c)
        else: p.box(4, 18 + y, 8, 5, c); p.vline(8, 18 + y, 22 + y, shade(c, -1))
    elif kind == "beard":
        if d == "down":
            p.box(4, 14 + y, 8, 3, H); p.hline(5, 10, 17 + y, h); p.hline(6, 9, 15 + y, pal["m"])
        elif side:
            p.box(8, 14 + y, 5, 3, H); p.hline(9, 11, 17 + y, h)
    elif kind == "moustache":
        if d == "down": p.hline(5, 10, 15 + y, H); p.dot(5, 16 + y, H); p.dot(10, 16 + y, H)
        elif side: p.hline(10, 13, 15 + y, H); p.dot(13, 16 + y, H)
    elif kind == "long":
        if d == "down":
            for x, c in ((3, H), (12, h)): p.vline(x, 12 + y, 19 + y, c)
            p.vline(2, 13 + y, 18 + y, h); p.vline(13, 13 + y, 18 + y, h)
        elif d == "up":
            p.box(3, 12 + y, 10, 8, H); p.hline(4, 11, 20 + y, h)
            for x in (5, 8, 11): p.vline(x, 13 + y, 19 + y, h)
        else:
            p.box(3, 13 + y, 3, 7, H); p.vline(3, 13 + y, 19 + y, h)
    elif kind == "headscarf":
        c, dk, lt = "4a6ea8", "34507e", "7a9ccc"
        if d == "down":
            p.box(4, 5 + y, 8, 2, c); p.box(3, 7 + y, 10, 3, c); p.hline(5, 9, 5 + y, lt)
            p.hline(3, 12, 10 + y, dk); p.dot(5, 8 + y, "f2ece0"); p.dot(9, 7 + y, "f2ece0")
        elif side:
            p.box(4, 5 + y, 8, 2, c); p.box(3, 7 + y, 9, 3, c); p.hline(5, 9, 5 + y, lt)
            p.box(1, 10 + y, 3, 2, dk); p.dot(1, 12 + y, c); p.dot(7, 8 + y, "f2ece0")
        else:
            p.box(4, 5 + y, 8, 2, c); p.box(3, 7 + y, 10, 6, c); p.hline(4, 11, 13 + y, dk)
            p.box(7, 14 + y, 2, 3, dk); p.dot(6, 9 + y, "f2ece0"); p.dot(10, 11 + y, "f2ece0")
    elif kind == "pony":
        if d == "down": p.box(13, 10 + y, 1, 3, H); p.dot(13, 13 + y, h)
        elif side: p.box(1, 8 + y, 3, 2, H); p.vline(1, 10 + y, 13 + y, h); p.vline(2, 10 + y, 12 + y, H)
        else: p.vline(7, 10 + y, 18 + y, H); p.vline(8, 10 + y, 18 + y, h); p.hline(7, 8, 9 + y, "c84a8a")
    elif kind == "toque":
        c, dk = "f4efe4", "cfc6b4"
        p.oval(7.5, 3 + y, 4.2, 2.6, c); p.box(4, 4 + y, 8, 3, c); p.hline(4, 11, 7 + y, dk)
        p.dot(5, 2 + y, "ffffff"); p.vline(10, 3 + y, 6 + y, dk)


def actor(P, name, spec, d, frame):
    coat, hair, skin, pants, accent, extras = spec
    pal = palette(coat, hair, skin, pants, accent)
    p = P(16, 32)
    if d == "sleep":
        head = list(HEAD_DOWN)
        head[6], head[7] = "...hSSSSSSSSh...", "...sbbSSSSbbs..."
        stamp(p, head, 4, dict(pal, b=shade(skin, -2.6)), lambda *a: (0, 0), lambda x, r, ch: ch)
        if "toque" in extras: overlay(p, "toque", "down", pal, -2, 0)
        if "headscarf" in extras: overlay(p, "headscarf", "down", pal, -2, 0)
        p.box(3, 15, 10, 2, shade(coat, 0.3)); p.hline(3, 12, 15, shade(coat, 1.4))
        p.outline(k=-2.6)
        return p
    side = d in ("left", "right")
    face = "right" if side else d
    head = HEAD_SIDE if side else HEAD_UP if d == "up" else HEAD_DOWN
    body = BODY_SIDE if side else BODY_UP if d == "up" else BODY_DOWN
    child = "child" in extras
    if child: body = [body[i] for i in (0, 1, 2, 5, 6)]
    bob = 1 if frame else 0
    legs(p, face, frame, pal)

    def swing(x, r, ch):
        if ch not in "Aak" or frame == 0: return (0, 0)
        sign = 1 if frame == 1 else -1
        if side: return (sign if r >= (2 if child else 4) else 0, 0)
        return (0, -sign if x < 8 else sign) if r >= (2 if child else 4) else (0, 0)
    remap = remapper(extras)
    for k in extras:
        if k in ("skirt",): overlay(p, k, face, pal, bob, frame)
    stamp(p, body, (19 if child else 17) + bob, pal, swing, remap)
    stamp(p, head, (8 if child else 6) + bob, pal, lambda *a: (0, 0), lambda x, r, ch: ch)
    for k in extras:
        if k not in ("child", "rolled", "bare", "stripes", "skirt"):
            overlay(p, k, face, pal, bob + (2 if child else 0), frame)
    if d == "left": p.data = p.flipped().data
    p.outline(k=-3.0)
    return p


def sprites(P):
    out = {"tile_stone_jetty": jetty(P)}
    for s in "nesw": out[f"tile_stone_jetty_edge_{s}"] = jetty_edge(P, s)
    for kind in ("wall", "stripe", "window", "door_top", "door_bottom"):
        out[f"tile_lighthouse_{kind}"] = lighthouse(P, kind)
    for i, part in enumerate(("left", "center", "right")):
        out[f"tile_lantern_{part}"] = lantern(P, i); out[f"tile_cap_{part}"] = cap(P, i)
    for kind in ("smithy", "bakery", "tavern"): out[f"tile_{kind}_sign"] = sign(P, kind)
    out["tile_windmill_wall"] = mill_wall(P)
    for i in range(4): out[f"tile_mill_sails{i}"] = sails(P, i)
    for i in range(2):
        out[f"tile_paving{i}"] = paving(P, i); out[f"tile_flowerbed{i}"] = flowerbed(P, i)
    out["bench"] = bench(P)
    for i in range(4): out[f"fountain{i}"] = fountain(P, i)
    out["furniture_forge_3x2"] = forge(P); out["furniture_anvil_1x1"] = anvil(P)
    out["furniture_oven_2x2"] = oven(P); out["furniture_barrels_2x1"] = barrels(P)
    out["furniture_flour_2x1"] = flour(P)
    out["item_wildgrowth"] = item_wildgrowth(P); out["item_sit"] = item_sit(P)
    for name, spec in PEOPLE.items():
        for d in ("down", "up", "left", "right", "sleep"):
            for frame in range(1 if d == "sleep" else 3):
                out[f"actor_{name}_{d}{frame}"] = actor(P, name, spec, d, frame)
    return out
