#!/usr/bin/env python3
"""Connected eight-neighbour terrain borders for the rustic16 pack.

Seven materials (dirt, pond, ocean, cliff, soil, tilled, cave) are painted as
8x8 quarter pieces. Each quarter is drawn in global 16x16 tile coordinates, so a
fill quarter is an exact crop of a seamless tile and edge quarters continue the
same texture. Shapes, per quarter:
  fill        both side neighbours and the diagonal match
  inner       both side neighbours match, the diagonal does not
  outer       neither side neighbour matches
  horizontal  the E/W side neighbour matches; the N/S side is exposed, so the
              rim runs horizontally
  vertical    the N/S side neighbour matches; the E/W side is exposed
Nothing is mirrored or rotated: light stays top-left, north rims are lips, west
rims lit, east rims shaded and south edges carry the tall faces.

Edge silhouettes come from smooth 16-periodic curves that ignore variant,
season and weather, so every combination shares one footprint. Multi-pixel
details (pebbles, clods, reeds, rocks, cracks) stay inside their own quarter
and never cross an 8px anchor.

Public API: quarter(), tile(), sprites(), plant_overlays(). Nothing renders at
import time.
"""
import math
from functools import lru_cache

MATERIALS = ("dirt", "pond", "ocean", "cliff", "soil", "tilled", "cave")
SEASONS = ("spring", "summer", "autumn", "winter")
WEATHERS = ("sunny", "partly_cloudy", "rainy")
VARIANTS = (0, 1, 2, 3)
QUADRANTS = ("nw", "ne", "sw", "se")
SHAPES = ("fill", "horizontal", "vertical", "outer", "inner")
ORIGIN = {"nw": (0, 0), "ne": (8, 0), "sw": (0, 8), "se": (8, 8)}
QUARTER_BITS = {"nw": (1, 8, 128), "ne": (1, 2, 16), "sw": (4, 8, 64), "se": (4, 2, 32)}
BIG = 99.0
IN = ("in",)

# Shared rustic16 ramps, darkest first.
GRASS = ["263f2b", "345a31", "48783a", "62953f", "84b04a", "b2cb68"]
STONE = ["2b2a33", "44424b", "615d62", "817b78", "a59d91", "cbc2ad"]
CAVE = ["17161e", "24232d", "34323d", "47434f", "5e5865", "7b737f"]
DIRT = ["38231a", "573826", "7a5034", "9b6b44", "bb8c5c", "d6ad7a"]
ROCK = ["2b231f", "43372f", "5e4e42", "7b6857", "9a8470", "bba58a"]
LEAF_OAK = ["1f3526", "2f4f2c", "426f33", "5f9139", "86b046", "b5cf62"]
LEAF_BIRCH = ["2a4128", "3f6233", "5c873c", "7fa845", "a8c556", "d4e07a"]
GOLD = ["4e3a1c", "7c5e26", "a88634", "d4b250", "ead07a", "f8ecb8"]
LOAM = ["3a2618", "4f331f", "664229", "7d5434", "946742", "ab7d54"]
LOAM_WET = ["22160f", "2e1f16", "3c2a1d", "4b3424", "5b412d", "6c4f38"]

TUFTS = {
    "spring": (GRASS[1], GRASS[3], GRASS[5]),
    "summer": ("4c6e32", "7c9a44", "bab65e"),
    "autumn": ("6c6034", "a48a4a", "d4b266"),
    "winter": ("5c685e", "9caaa0", "dae2dc"),
}
REEDS = {
    "spring": ("3a6432", "5e9244", "9cc462", None),
    "summer": ("365e2e", "568a3c", "88b456", "6a4428"),
    "autumn": ("6e6236", "a08a4a", "ccb068", "7a4e2c"),
    "winter": ("5e584c", "847c6a", "d6dcd8", None),
}
LEAVES = ("8e3f26", "c4682c", "e0a03e")
SNOW = ("a9b7c7", "d3dde6", "ecf1f3")
SLUSH = ("7e8486", "9ea4a4", "bcc2c0")
FLOWER = ("f0e6cc", "e6b94e")
# Base, stem, left tip, right tip of a small blade tuft; (dx, dy, tone).
TUFT_PTS = ((-1, 0, 0), (0, 0, 0), (1, 0, 1), (0, -1, 1), (-1, -1, 2), (1, -2, 2))

_CACHE = {}
_PALETTES = {}


# ---------------------------------------------------------------- colour + noise

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


def hash01(x, y, seed=0):
    n = (x * 374761393 + y * 668265263 + seed * 2246822519 + 1013904223) & 0xFFFFFFFF
    n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((n ^ (n >> 16)) & 0xFFFF) / 65535


def pnoise(gx, gy, seed, cell=4):
    """Smooth value noise that repeats every 16 pixels, sampled at pixel centres."""
    size = 16 // cell
    u, v = (gx % 16 + 0.5) / cell - 0.5, (gy % 16 + 0.5) / cell - 0.5
    xi, yi = math.floor(u), math.floor(v)
    xf, yf = u - xi, v - yi
    xf, yf = xf * xf * (3 - 2 * xf), yf * yf * (3 - 2 * yf)
    x0, x1, y0, y1 = xi % size, (xi + 1) % size, yi % size, (yi + 1) % size
    a, b = hash01(x0, y0, seed), hash01(x1, y0, seed)
    c, d = hash01(x0, y1, seed), hash01(x1, y1, seed)
    return a + (b - a) * xf + (c - a) * yf + (a - b - c + d) * xf * yf


@lru_cache(maxsize=None)
def _curve(seed):
    """A smooth 0..1 profile that repeats every 16 pixels; used for shorelines and strata."""
    p1, p2, p3 = hash01(seed, 1, 77), hash01(seed, 2, 77), hash01(seed, 3, 77)
    out = []
    for c in range(16):
        v = (0.5 + 0.3 * math.sin(2 * math.pi * (2 * c / 16 + p1))
             + 0.15 * math.sin(2 * math.pi * (3 * c / 16 + p2))
             + 0.08 * math.sin(2 * math.pi * (5 * c / 16 + p3)))
        out.append(min(1.0, max(0.0, v)))
    return tuple(out)


@lru_cache(maxsize=None)
def _steps(seed):
    return tuple(1 if v > 0.5 else 0 for v in _curve(seed))


class _Rng:
    """Tiny deterministic xorshift stream seeded from integers only."""

    def __init__(self, *seed):
        s = 0x9E3779B9
        for v in seed:
            s = ((s ^ (v & 0xFFFFFFFF)) * 0x01000193 + 0x7F4A7C15) & 0xFFFFFFFF
        self.s = s or 1
        for _ in range(4):
            self.next()

    def next(self):
        s = self.s
        s ^= (s << 13) & 0xFFFFFFFF
        s ^= s >> 17
        s ^= (s << 5) & 0xFFFFFFFF
        self.s = s & 0xFFFFFFFF
        return self.s / 4294967296

    def int(self, lo, hi):
        return lo + int(self.next() * (hi - lo + 1))


# ---------------------------------------------------------------- geometry

def _sides(n, e, s, w):
    return {"N": n, "E": e, "S": s, "W": w}


class Geometry:
    """Edge footprint of one material: transparent margin, rim band, ragged profile and corner radii.

    Face materials raise the south margin by the face height; pixels below the
    cap that sit under its silhouette become the "face" zone.
    """

    def __init__(self, key, margin, band, amp, radius, face=0, fillet=2.0):
        self.margin, self.band, self.amp, self.radius = margin, band, amp, radius
        self.face, self.fillet = face, fillet
        self.curve = {side: _curve(key * 8 + i) for i, side in enumerate("NESW")}

    def t(self, side, gx, gy):
        if side == "N":
            dist, along = gy + 0.5, gx
        elif side == "S":
            dist, along = 15.5 - gy, gx
        elif side == "W":
            dist, along = gx + 0.5, gy
        else:
            dist, along = 15.5 - gx, gy
        return dist - self.margin[side] - self.amp[side] * self.curve[side][along % 16]

    def classify(self, quadrant, shape, gx, gy):
        """Return (zone, depth, tv, th); zone is in/out/face or the exposed side N/E/S/W."""
        if shape == "fill":
            return ("in", BIG, BIG, BIG)
        V = "N" if quadrant[0] == "n" else "S"
        H = "W" if quadrant[1] == "w" else "E"
        tv = self.t(V, gx, gy) if shape != "vertical" else BIG
        th = self.t(H, gx, gy) if shape != "horizontal" else BIG
        bv, bh = self.band[V], self.band[H]
        if shape == "horizontal":
            res = ("out", tv) if tv < 0 else (V, tv) if tv < bv else ("in", BIG)
        elif shape == "vertical":
            res = ("out", th) if th < 0 else (H, th) if th < bh else ("in", BIG)
        elif shape == "outer":
            res = self._outer(V, tv, th, bv, bh, H)
        else:
            res = self._inner(V, H, tv, th, bv, bh)
        if res[0] == "out" and self.face and V == "S" and tv < 0:
            if (shape == "horizontal" or (shape == "inner" and th < 0)
                    or (shape == "outer" and th >= 0 and not (gy == 15 and th < 1))):
                return ("face", -tv, tv, th)
        return (res[0], res[1], tv, th)

    def _outer(self, V, tv, th, bv, bh, H):
        if tv < 0 or th < 0:
            return ("out", min(tv, th))
        R = self.radius[V]
        rr = BIG
        if tv < R and th < R:
            rr = R - math.hypot(R - tv, R - th)
            if rr < 0:
                return ("out", rr)
        dv, dh = min(tv, rr), min(th, rr)
        if dv >= bv and dh >= bh:
            return ("in", BIG)
        return (V, dv) if tv / bv <= th / bh else (H, dh)

    def _inner(self, V, H, tv, th, bv, bh):
        if tv < 0 and th < 0:
            return ("out", max(tv, th))
        f = self.fillet
        if not (self.face and V == "S") and 0 <= tv < f and 0 <= th < f and math.hypot(f - tv, f - th) > f:
            return ("out", -0.5)
        if th < 0:
            return (V, tv) if tv < bv else ("in", BIG)
        if tv < 0:
            return (H, th) if th < bh else ("in", BIG)
        a, b = tv / bv, th / bh
        e = math.hypot(a, b)
        if e >= 1:
            return ("in", BIG)
        return (H, e * bh) if b > a else (V, e * bv)


GEOMETRY = {
    "dirt": Geometry(1, _sides(1, 1, 1, 1), _sides(2, 2, 2, 2), _sides(1.5, 1.5, 1.5, 1.5), {"N": 3.5, "S": 3.5}),
    "pond": Geometry(2, _sides(1, 1, 1, 1), _sides(4, 3, 3, 3), _sides(1.2, 1.2, 1.2, 1.2), {"N": 3.5, "S": 3.5}),
    "ocean": Geometry(3, _sides(1, 1, 1, 1), _sides(5, 4, 4, 4), _sides(1.6, 1.6, 1.6, 1.6), {"N": 4.0, "S": 4.0}),
    "cliff": Geometry(4, _sides(1, 1, 6, 1), _sides(2, 2, 2, 2), _sides(1.0, 0.8, 0.0, 0.8), {"N": 3.0, "S": 1.5}, face=6),
    "soil": Geometry(5, _sides(1, 1, 1, 1), _sides(2, 2, 2, 2), _sides(1.0, 1.0, 1.0, 1.0), {"N": 2.5, "S": 2.5}),
    "cave": Geometry(6, _sides(1, 1, 6, 1), _sides(2, 2, 2, 2), _sides(1.2, 1.0, 0.0, 1.0), {"N": 2.5, "S": 1.5}, face=6),
}
GEOMETRY["tilled"] = GEOMETRY["soil"]
STRATA = {"cliff": (4101, 4102), "cave": (6101, 6102)}
FOAM_SEEDS = {"N": 901, "E": 902, "S": 903, "W": 904}


# ---------------------------------------------------------------- palettes

def _keys(p, names, fn):
    for k in names:
        p[k] = fn(p[k])


def _pal_dirt(season, weather):
    base = dict(core=DIRT[4], hi=mix(DIRT[4], DIRT[5], 0.4), lo=mix(DIRT[3], DIRT[4], 0.5),
                loose=DIRT[3], dark=mix(DIRT[2], DIRT[3], 0.5))
    target, t = {"spring": ("94704a", 0.14), "summer": ("cfa978", 0.2),
                 "autumn": ("9c6a44", 0.16), "winter": ("9a9089", 0.3)}[season]
    p = {k: mix(v, target, t) for k, v in base.items()}
    stone = (rgba(STONE[4]), rgba(STONE[3]), rgba(STONE[2]))
    if weather == "rainy":
        p = {k: mix(shade(v, -1.1), "4c3b33", 0.15) for k, v in p.items()}
        stone = tuple(shade(s, -0.6) for s in stone)
    p["stone"] = stone
    p["puddle"] = mix(p["dark"], "5a6a74", 0.45)
    return p


def _pal_pond(season, weather):
    water = {"spring": ("29605e", "33706a", "4c8878", "7cae98"), "summer": ("296252", "36785e", "528f70", "88ba90"),
             "autumn": ("2a5858", "336662", "4b7c6e", "7aa48e"), "winter": ("2f5866", "3a6874", "56848c", "8cb0b4")}[season]
    sand = {"spring": "b39a70", "summer": "bea47a", "autumn": "a8906a", "winter": "a49e92"}[season]
    deep, mid, shallow, hi = (rgba(x) for x in water)
    p = dict(deep=deep, mid=mid, shallow=shallow, hi=hi, deepmid=mix(deep, mid, 0.5), shade=shade(deep, -0.6),
             shallow_dk=mix(shallow, deep, 0.4), sand_hi=shade(sand, 0.8), sand=rgba(sand),
             wet_sand=mix(sand, "5e4a36", 0.4), mud=mix(sand, "4e3a28", 0.55), mud_dk=mix(sand, "3a2a20", 0.7))
    if weather == "rainy":
        _keys(p, ("deep", "mid", "shallow", "hi", "deepmid", "shade", "shallow_dk"),
              lambda v: mix(shade(v, -0.25), "3e5a5e", 0.2))
        _keys(p, ("sand_hi", "sand", "wet_sand", "mud", "mud_dk"), lambda v: shade(v, -0.9))
    p["ring"] = mix(p["mid"], p["hi"], 0.5)
    p["sparkle"] = rgba("cfe5d6")
    p["ice"], p["ice_hi"], p["frost"] = rgba("b2cad0"), rgba("d8e6ea"), rgba("d2d8d4")
    p["reed"] = tuple(rgba(x) if x else None for x in REEDS[season])
    return p


def _pal_ocean(season, weather):
    water = {"spring": ("1e4e6e", "265f7e", "32748e", "5c9eb0"), "summer": ("1c5272", "24668a", "2e7d98", "60aabc"),
             "autumn": ("1f4866", "285876", "336c86", "5a92a4"), "winter": ("223e56", "2b4e66", "386078", "688ea0")}[season]
    sand = {"spring": "c6ad86", "summer": "d0b78c", "autumn": "b9a07a", "winter": "aca69a"}[season]
    deep, mid, light, crest = (rgba(x) for x in water)
    p = dict(deep=deep, mid=mid, light=light, crest=crest, deepmid=mix(deep, mid, 0.45),
             shallow=mix(light, "86b4a6", 0.35), foam=rgba("d4e6e0"), foam_dk=rgba("a6c6c6"),
             sand_hi=shade(sand, 0.7), sand=rgba(sand), sand_lo=shade(sand, -0.6),
             wet=mix(sand, "65584a", 0.45), wet_dk=mix(sand, "4a4440", 0.6))
    rock = tuple(rgba(x) for x in ("3c3a3e", "58545a", "7a746e", "9e9688"))
    p["sparkle"] = rgba("d2eaea")
    if weather == "rainy":
        _keys(p, ("deep", "mid", "light", "crest", "deepmid", "shallow"), lambda v: mix(shade(v, -0.3), "3a4e5a", 0.15))
        _keys(p, ("foam", "foam_dk"), lambda v: mix(v, p["mid"], 0.22))
        _keys(p, ("sand_hi", "sand", "sand_lo", "wet", "wet_dk"), lambda v: shade(v, -0.9))
        rock = tuple(shade(r, -0.5) for r in rock)
        p["sparkle"] = rgba("9eb4ba")
    p["rock"] = rock
    p["ice"] = rgba("c2d4da")
    return p


def _pal_cliff(season, weather):
    target, t = {"spring": ("7c6a58", 0.0), "summer": ("a8987a", 0.14),
                 "autumn": ("8a6a52", 0.1), "winter": ("8a92a2", 0.16)}[season]
    r = [mix(x, target, t) for x in ROCK]
    wet = weather == "rainy"
    if wet:
        r = [mix(shade(x, -0.6), "3a3c46", 0.12) for x in r]
    cap = {"spring": (GRASS[1], GRASS[2], GRASS[3]), "summer": ("66743a", "8a9248", "b2aa64"),
           "autumn": ("6e5e34", "9a804a", "c49a52"), "winter": SNOW}[season]
    cap = tuple(rgba(x) for x in cap)
    if wet:
        cap = tuple(rgba(x) for x in SLUSH) if season == "winter" else tuple(shade(x, -0.4) for x in cap)
    ledge = {"spring": (GRASS[2], GRASS[4]), "summer": ("9a9a58", "c4bc78"),
             "autumn": (LEAVES[0], LEAVES[1]), "winter": (SNOW[1], SNOW[2])}[season]
    return dict(r=r, cap=cap, ledge=tuple(rgba(x) for x in ledge), damp=shade(r[1], -0.6))


def _pal_cave(season, weather):
    target, t = {"spring": ("3a4a46", 0.1), "summer": ("4c463e", 0.1),
                 "autumn": ("4e4234", 0.12), "winter": ("384254", 0.14)}[season]
    cv = [mix(x, target, t) for x in CAVE]
    if weather == "rainy":
        cv = [mix(shade(x, -0.25), "2a3642", 0.12) for x in cv]
    mineral = {"spring": "5a6e5e", "summer": "8a8270", "autumn": "8a6c42", "winter": "9aaabb"}[season]
    return dict(c=cv, top=mix(cv[1], cv[2], 0.3), top_lo=cv[1], vein=cv[2], fleck=cv[3],
                shadow=(14, 12, 20, 96), mineral=rgba(mineral), seep=mix(cv[2], "3a5464", 0.5),
                wetglint=rgba("8eaec2"))


def _pal_soil(season, weather):
    wet = weather == "rainy"
    target, t = {"spring": ("6a4630", 0.06), "summer": ("a2805c", 0.14),
                 "autumn": ("6c4630", 0.06), "winter": ("6a605a", 0.16)}[season]
    L = [mix(x, target, t * (0.4 if wet else 1.0)) for x in (LOAM_WET if wet else LOAM)]
    stone = (rgba(STONE[4]), rgba(STONE[3]), rgba(STONE[2]))
    if wet:
        stone = tuple(shade(s, -0.7) for s in stone)
    return dict(L=L, stone=stone, frost=(rgba("a8b2b6"), rgba("ccd4d8")), sheen=rgba("7e7a78"),
                puddle=mix(L[1], "4e5a62", 0.4))


_PALETTE_BUILDERS = {"dirt": _pal_dirt, "pond": _pal_pond, "ocean": _pal_ocean, "cliff": _pal_cliff,
                     "soil": _pal_soil, "tilled": _pal_soil, "cave": _pal_cave}


def _palette(material, season, weather):
    key = (material, season, weather)
    if key not in _PALETTES:
        p = _PALETTE_BUILDERS[material](season, weather)
        wet = weather == "rainy"
        tuft = tuple(rgba(x) for x in TUFTS[season])
        p["tuft"] = tuple(shade(x, -0.5) for x in tuft) if wet else tuft
        p["snow"] = tuple(rgba(x) for x in (SLUSH if wet else SNOW))
        p["leaf"] = tuple(rgba(x) for x in LEAVES)
        p["glint"] = rgba("b4c4c8")
        _PALETTES[key] = p
    return _PALETTES[key]


# ---------------------------------------------------------------- quarter buffer

class _Ctx:
    pass


class _Quarter:
    def __init__(self, c):
        self.c = c
        self.geo = [[c.g.classify(c.q, c.shape, c.ox + lx, c.oy + ly) for lx in range(8)] for ly in range(8)]
        self.px = [[None] * 8 for _ in range(8)]

    def zone(self, lx, ly):
        if 0 <= lx < 8 and 0 <= ly < 8:
            return self.geo[ly][lx][0]
        return None

    def depth(self, lx, ly):
        return self.geo[ly][lx][1]

    def ground(self, lx, ly):
        z = self.zone(lx, ly)
        return z is not None and z != "out"

    def put(self, lx, ly, col, zones=None):
        if 0 <= lx < 8 and 0 <= ly < 8 and (zones is None or self.geo[ly][lx][0] in zones):
            self.px[ly][lx] = None if col is None else rgba(col)
            return True
        return False

    def all_zone(self, pts, zones):
        return all(self.zone(x, y) in zones for x, y in pts)

    def all_ground(self, pts):
        return all(self.ground(x, y) for x, y in pts)

    def rng(self, stream):
        c = self.c
        return _Rng(c.mi, c.qi, c.variant, stream)

    def corner(self):
        c = self.c
        return (0 if c.H == "W" else 7, 0 if c.V == "N" else 7, 1 if c.H == "W" else -1, 1 if c.V == "N" else -1)

    def open_sides(self):
        c = self.c
        return {"horizontal": [c.V], "vertical": [c.H], "outer": [c.V, c.H]}.get(c.shape, [])

    def edge_point(self, side, a):
        """First ground pixel met when walking in from the exposed side along local row/column a."""
        if side == "N":
            seq = [(a, y) for y in range(8)]
        elif side == "S":
            seq = [(a, y) for y in range(7, -1, -1)]
        elif side == "W":
            seq = [(x, a) for x in range(8)]
        else:
            seq = [(x, a) for x in range(7, -1, -1)]
        for x, y in seq:
            if self.ground(x, y):
                return (x, y)
        return None

    def water_point(self, side, a):
        """First interior pixel past the shore band along local row/column a."""
        pt = self.edge_point(side, a)
        if pt is None:
            return None
        x, y = pt
        dx, dy = {"N": (0, 1), "S": (0, -1), "W": (1, 0), "E": (-1, 0)}[side]
        while 0 <= x < 8 and 0 <= y < 8:
            if self.zone(x, y) == "in":
                return (x, y)
            x, y = x + dx, y + dy
        return None

    def gap_points(self):
        if self.c.shape not in ("inner", "outer"):
            return []
        cx, cy, sx, sy = self.corner()
        return [(cx + sx * i, cy + sy * j) for i, j in ((0, 0), (1, 0), (0, 1), (1, 1), (2, 0), (0, 2))]

    def tuft(self, lx, ly, cols):
        for dx, dy, k in TUFT_PTS:
            self.put(lx + dx, ly + dy, cols[k])

    def edge_tufts(self, r, cols, chance, sides=None):
        for side in self.open_sides():
            roll, a = r.next(), r.int(2, 5)
            if roll > chance or (sides and side not in sides):
                continue
            pt = self.edge_point(side, a)
            if pt is None:
                continue
            lx, ly = pt
            if side in ("N", "S") and ly < 7:
                ly += 1
            self.tuft(lx, ly, cols)

    def pebble(self, lx, ly, big, stone, shadow):
        s0, s1, s2 = stone
        if big:
            pts = [(lx, ly, s0), (lx + 1, ly, s1), (lx, ly + 1, s1), (lx + 1, ly + 1, s2),
                   (lx + 2, ly + 1, shadow), (lx + 1, ly + 2, shadow)]
        else:
            pts = [(lx, ly, s0), (lx + 1, ly, s2), (lx + 1, ly + 1, shadow)]
        if self.all_ground([(x, y) for x, y, _ in pts]):
            for x, y, col in pts:
                self.put(x, y, col)

    def debris(self, r, puddle=None):
        """Seasonal litter collected in inner gaps and at outer corners."""
        c, p = self.c, self.c.pal
        gap = self.gap_points()
        roll, roll2 = r.next(), r.next()
        if c.season == "autumn":
            spots = [gap[0]] if gap else []
            for _ in range(1 + c.variant % 2):
                spots.append((r.int(1, 5), r.int(1, 6)))
            for i, (x, y) in enumerate(spots):
                if self.zone(x, y) not in ("in", None) or (i > 0 and self.ground(x, y)):
                    self.put(x, y, p["leaf"][1 + (i + c.variant) % 2])
                    self.put(x + 1, y, p["leaf"][0])
        elif c.season == "winter" and gap:
            snow = p["snow"]
            for i, (x, y) in enumerate(gap[:5]):
                z = self.zone(x, y)
                if z == "out" or (z not in ("in", "face", None) and self.depth(x, y) < 1.2):
                    self.put(x, y, snow[2] if i == 0 else snow[1] if i < 3 else snow[0])
        elif c.season == "spring" and gap and roll < 0.5:
            cx, cy, sx, sy = self.corner()
            fx, fy = cx + sx, cy + sy
            for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                self.put(fx + dx, fy + dy, FLOWER[0])
            self.put(fx, fy, FLOWER[1])
        if puddle and c.weather == "rainy" and c.shape == "inner" and roll2 < 0.7:
            cx, cy, sx, sy = self.corner()
            pts = [(cx + sx * i, cy + sy * j) for i, j in ((2, 1), (1, 2), (2, 2), (3, 2))]
            pts = [pt for pt in pts if self.zone(*pt) not in ("out", None)]
            for i, (x, y) in enumerate(pts):
                self.put(x, y, p["glint"] if i == 0 else puddle)


# ---------------------------------------------------------------- dirt

def _paint_dirt(c, gx, gy, geo):
    zone, d = geo[0], geo[1]
    p = c.pal
    if zone == "out":
        return None
    n = hash01(gx, gy, 511 + c.variant * 7)
    if zone == "in":
        pn = pnoise(gx, gy, 510)
        col = p["hi"] if pn > 0.64 else p["lo"] if pn < 0.3 else p["core"]
        if n > 0.95:
            col = p["hi"]
        elif n < 0.04:
            col = p["loose"]
        return col
    lit = zone in ("S", "E")
    if d < 1:
        col = p["loose"] if lit else p["dark"]
    else:
        col = p["lo"] if lit else p["loose"]
    if n > 0.92:
        col = p["lo"] if d < 1 else p["core"]
    if c.season == "winter" and d < 1 and hash01(gx, gy, 513) > 0.6:
        col = mix(col, "c8d0d4", 0.45)
    return col


def _deco_dirt(Q):
    c, p = Q.c, Q.c.pal
    rg = Q.rng(1)
    for _ in range(3 if c.variant == 3 else 2):
        Q.pebble(rg.int(1, 5), rg.int(1, 5), rg.next() > 0.55, p["stone"], p["dark"])
    lx, ly = rg.int(1, 4), rg.int(1, 5)
    if c.variant in (1, 2):
        pts = [(lx, ly), (lx + 1, ly), (lx + 2, ly + 1)]
        if Q.all_zone(pts, IN):
            for x, y in pts:
                Q.put(x, y, p["hi"])
    Q.edge_tufts(Q.rng(2), p["tuft"], 0.8 if c.season == "summer" else 0.6)
    Q.debris(Q.rng(3), puddle=p["puddle"])
    if c.weather == "rainy" and c.variant == 2 and c.shape == "fill":
        pts = [(3, 4), (4, 4), (5, 4), (4, 5), (3, 5)]
        if Q.all_zone(pts, IN):
            for x, y in pts:
                Q.put(x, y, p["puddle"])
            Q.put(3, 4, p["glint"])


# ---------------------------------------------------------------- pond

def _paint_pond(c, gx, gy, geo):
    zone, d = geo[0], geo[1]
    p = c.pal
    if zone == "out":
        return None
    if zone == "in":
        pn = pnoise(gx, gy, 520)
        col = p["deepmid"] if pn < 0.36 else p["mid"]
        if pn > 0.74:
            col = mix(p["mid"], p["shallow"], 0.3)
        return col
    seq = {"N": ("sand_hi", "sand", "mud", "shade"), "S": ("sand", "wet_sand", "shallow"),
           "W": ("sand_hi", "mud_dk", "shallow_dk"), "E": ("sand", "mud", "shallow")}[zone]
    i = min(int(d), len(seq) - 1)
    name = seq[i]
    n = hash01(gx, gy, 521)
    if name in ("sand", "sand_hi") and n > 0.9:
        name = "wet_sand" if name == "sand" else "sand"
    col = p[name]
    if c.season == "winter":
        if i == len(seq) - 1:
            col = p["ice_hi"] if hash01(gx, gy, 522) > 0.6 else p["ice"]
        elif name == "sand_hi" and n > 0.4:
            col = p["frost"]
    return col


def _reeds(Q, side, a, cols):
    dark, mid, tip, head = cols
    pt = Q.edge_point(side, a)
    if pt is None:
        return
    lx, ly = pt
    bx, by = {"N": (lx, ly + 3), "S": (lx, ly), "W": (lx + 2, ly), "E": (lx - 2, ly)}[side]
    stalks = ((0, 4), (1, 3), (-1, 2))[:2 + a % 2]
    for dx, h in stalks:
        for k in range(h):
            Q.put(bx + dx, by - k, dark if k == 0 else mid if k < h - 1 else tip)
    if head:
        Q.put(bx, by - 2, head)
        Q.put(bx, by - 3, shade(head, 0.6))


def _deco_pond(Q):
    c, p = Q.c, Q.c.pal
    rf = Q.rng(2)
    if c.weather == "rainy":
        for _ in range(1 + c.variant % 2):
            lx, ly = rf.int(1, 6), rf.int(1, 6)
            ring = [(lx - 1, ly), (lx + 1, ly), (lx, ly - 1), (lx, ly + 1)]
            if Q.all_zone(ring + [(lx, ly)], IN):
                for x, y in ring:
                    Q.put(x, y, p["ring"])
    else:
        roll, lx, ly = rf.next(), rf.int(1, 5), rf.int(1, 6)
        if roll < (0.8 if c.weather == "sunny" else 0.35) and Q.all_zone([(lx, ly), (lx + 1, ly)], IN):
            Q.put(lx, ly, p["sparkle"])
            Q.put(lx + 1, ly, p["hi"])
    rs = Q.rng(3)
    lx, ly = rs.int(1, 5), rs.int(1, 6)
    if c.season == "autumn" and c.variant in (1, 3) and Q.all_zone([(lx, ly), (lx + 1, ly)], IN):
        Q.put(lx, ly, p["leaf"][2])
        Q.put(lx + 1, ly, p["leaf"][0])
    if c.season == "summer" and c.variant == 2 and Q.all_zone([(lx, ly), (lx + 1, ly), (lx, ly + 1)], IN):
        for x, y in ((lx, ly), (lx + 1, ly), (lx, ly + 1)):
            Q.put(x, y, mix(p["shallow"], "6a9a4c", 0.5))
    rg = Q.rng(1)
    sides = Q.open_sides()
    roll, pick, a = rg.next(), rg.next(), rg.int(2, 5)
    if sides and roll < 0.6:
        _reeds(Q, sides[int(pick * len(sides))], a, p["reed"])
    if c.variant in (0, 2):
        Q.edge_tufts(rg, p["tuft"], 0.5, sides=("N", "W", "E"))
    if c.season == "winter":
        Q.debris(Q.rng(4))


# ---------------------------------------------------------------- ocean

def _paint_ocean(c, gx, gy, geo):
    zone, d = geo[0], geo[1]
    p = c.pal
    if zone == "out":
        return None
    if zone == "in":
        big, small = pnoise(gx, gy, 530, 8), pnoise(gx, gy, 531)
        col = p["deepmid"] if big < 0.42 else p["mid"]
        if small > 0.76:
            col = p["light"]
        elif small < 0.2 and big < 0.5:
            col = p["deep"]
        return col
    seq = {"N": ("sand_hi", "sand", "wet", "FOAM", "shallow"), "S": ("sand", "wet", "FOAM", "shallow"),
           "W": ("sand_hi", "wet", "FOAM", "shallow"), "E": ("sand", "wet_dk", "FOAM", "shallow")}[zone]
    name = seq[min(int(d), len(seq) - 1)]
    along = gx if zone in ("N", "S") else gy
    if name == "FOAM":
        f = _curve(FOAM_SEEDS[zone])[along % 16] + 0.15 * hash01(along % 16, 7, 532)
        if f > 0.62:
            return p["foam"]
        if f > 0.5:
            return p["foam_dk"]
        return mix(p["shallow"], p["wet"], 0.3)
    col = p[name]
    if name.startswith("sand") and hash01(gx, gy, 533) > 0.9:
        col = p["sand_lo"]
    if c.season == "winter" and name in ("wet", "wet_dk") and hash01(gx, gy, 534) > 0.45:
        col = p["ice"]
    return col


def _rock(Q, side, a, ramp, sand_shadow, big):
    pt = Q.edge_point(side, a)
    if pt is None:
        return
    lx, ly = pt
    lx, ly = {"N": (lx, ly + 1), "S": (lx, ly - 2), "W": (lx, ly), "E": (lx - 2, ly)}[side]
    r0, r1, r2, r3 = ramp
    pts = [(lx, ly, r3), (lx + 1, ly, r2), (lx, ly + 1, r2), (lx + 1, ly + 1, r1), (lx + 2, ly + 1, sand_shadow)]
    if big:
        pts = [(lx + 1, ly - 1, r3), (lx + 2, ly, r1), (lx + 2, ly + 1, r0), (lx + 3, ly + 1, sand_shadow)] + pts[:4]
    for x, y, col in pts:
        Q.put(x, y, col)


def _deco_ocean(Q):
    c, p = Q.c, Q.c.pal
    sides = Q.open_sides()
    rg = Q.rng(1)
    roll, pick, a = rg.next(), rg.next(), rg.int(2, 3)
    if sides and c.variant in (1, 2, 3) and roll < 0.75:
        _rock(Q, sides[int(pick * len(sides))], a, p["rock"], p["wet_dk"], c.variant != 1)
    rf = Q.rng(2)
    for side in sides:
        a = rf.int(1, 5)
        pt = Q.water_point(side, a)
        if pt:
            x, y = pt
            nxt = (x + 1, y) if side in ("N", "S") else (x, y + 1)
            if Q.zone(*nxt) == "in":
                Q.put(x, y, p["foam_dk"])
                Q.put(*nxt, p["foam_dk"])
    rw = Q.rng(3)
    roll, lx, ly = rw.next(), rw.int(0, 4), rw.int(1, 6)
    if c.variant != 3 or roll < 0.3:
        crest = [(lx + 1, ly), (lx + 2, ly), (lx, ly + 1)]
        trough = [(lx + 1, ly + 1), (lx + 2, ly + 1)]
        if Q.all_zone(crest + trough + [(lx + 3, ly + 1)], IN):
            ccol = mix(p["crest"], p["mid"], 0.35) if c.weather == "rainy" else p["crest"]
            for x, y in crest:
                Q.put(x, y, ccol)
            for x, y in trough:
                Q.put(x, y, p["deep"])
            Q.put(lx + 3, ly + 1, p["light"])
            if c.weather != "partly_cloudy" or c.variant == 0:
                Q.put(lx + 1, ly, p["sparkle"])
    if c.season == "winter":
        Q.debris(Q.rng(4))


# ---------------------------------------------------------------- cliff + cave faces

def _strata(material, gx):
    s1, s2 = STRATA[material]
    return 1 + _steps(s1)[gx % 16], 3 + _steps(s2)[gx % 16]


def _paint_cliff(c, gx, gy, geo):
    zone, d, tv, th = geo
    p = c.pal
    r = p["r"]
    if zone == "out":
        return None
    n = hash01(gx, gy, 540 + c.variant * 11)
    if zone == "face":
        rb, (c1, c2) = 15 - gy, _strata("cliff", gx)
        if d < 1:
            col = mix(r[1], r[2], 0.35)
        elif rb == 0:
            col = r[1]
        elif rb in (c1, c2):
            col = r[1]
        elif rb in (c1 - 1, c2 - 1):
            col = r[4]
        elif rb > c2:
            col = r[3]
        elif rb > c1:
            col = mix(r[3], r[2], 0.5)
        else:
            col = r[2]
        if d >= 1 and rb not in (0, c1, c2):
            if n > 0.93:
                col = shade(col, 0.5)
            elif n < 0.05:
                col = shade(col, -0.5)
            if c.weather == "rainy" and rb < c1:
                col = p["damp"]
        if c.shape == "outer" and th < 1 and d >= 1 and rb not in (c1, c2):
            col = r[4] if c.H == "W" else r[0]
        if c.shape == "inner" and th > -1:
            col = r[0]
        return col
    if zone == "in":
        pn = pnoise(gx, gy, 541)
        col = r[3] if pn > 0.3 else mix(r[3], r[2], 0.55)
        if n > 0.94:
            col = r[4]
        elif n < 0.05:
            col = r[2]
        pg = pnoise(gx, gy, 542)
        cap = p["cap"]
        if c.season == "winter":
            if pg > 0.42:
                col = cap[2] if pg > 0.62 else cap[1]
            elif pg > 0.36:
                col = cap[0]
        elif pg > 0.64:
            col = cap[2] if pg > 0.74 and hash01(gx, gy, 543) > 0.4 else cap[1]
        elif pg > 0.6:
            col = cap[0]
        return col
    if zone == "N":
        col = mix(r[2], r[3], 0.4) if d < 1 else r[5]
    elif zone == "W":
        col = r[3] if d < 1 else r[4]
    elif zone == "E":
        col = r[1] if d < 1 else r[2]
    else:
        col = r[5] if d < 1 else r[4]
    if c.season == "winter":
        cap = p["cap"]
        if zone == "S":
            col = cap[2] if d < 1 else cap[1]
        elif zone == "N" and d >= 1:
            col = cap[2]
        elif zone == "W" and d >= 1 and n > 0.35:
            col = cap[1]
    return col


def _face_rows(Q, lx):
    """Local rows of face pixels in a column, top first."""
    return [ly for ly in range(8) if Q.zone(lx, ly) == "face"]


def _deco_cliff(Q):
    c, p = Q.c, Q.c.pal
    r = p["r"]
    rg = Q.rng(1)
    lx, ly, roll = rg.int(1, 4), rg.int(1, 4), rg.next()
    if c.variant in (0, 2, 3):
        pts = [(lx, ly), (lx + 1, ly + 1), (lx + 1, ly + 2), (lx + 2, ly + 3)][:3 + (c.variant == 2)]
        if Q.all_zone(pts + [(lx + 1, ly)], IN):
            for x, y in pts:
                Q.put(x, y, r[1])
            Q.put(lx + 1, ly, r[4])
    lx, ly = rg.int(1, 5), rg.int(1, 6)
    if roll < 0.6 and Q.all_zone([(lx, ly), (lx + 1, ly), (lx + 1, ly + 1)], IN):
        Q.put(lx, ly, r[5])
        Q.put(lx + 1, ly, r[4])
        Q.put(lx + 1, ly + 1, r[1])
    if c.season != "winter":
        Q.edge_tufts(Q.rng(2), p["tuft"], 0.55, sides=("N", "W", "E"))
    if any(_face_rows(Q, x) for x in range(8)):
        _face_details(Q, rg, r, "cliff")
        fx = rg.int(2, 5)
        if 7 in _face_rows(Q, fx) and _face_rows(Q, fx - 1) and _face_rows(Q, fx + 1):
            if c.season == "winter":
                for x, col in ((fx - 1, p["snow"][1]), (fx, p["snow"][2]), (fx + 1, p["snow"][1])):
                    Q.put(x, 7, col)
                Q.put(fx, 6, p["snow"][1])
            elif rg.next() < 0.75:
                Q.tuft(fx, 7, p["tuft"])
    else:
        Q.debris(Q.rng(3))


def _face_details(Q, rg, ramp, material):
    """Fractures, ledge litter and seepage on south faces; positions ignore weather and season."""
    c, p = Q.c, Q.c.pal
    fx, which = rg.int(1, 6), rg.next()
    c1, c2 = _strata(material, c.ox + fx)
    for ly in _face_rows(Q, fx):
        rb = 15 - (c.oy + ly)
        lo, hi = (c1, c2) if which < 0.5 else (0, c1)
        if lo < rb < hi and Q.depth(fx, ly) >= 1:
            Q.put(fx, ly, ramp[1] if material == "cliff" else ramp[0])
            if Q.zone(fx - 1, ly) == "face":
                Q.put(fx - 1, ly, ramp[3] if material == "cliff" else ramp[4])
    lx = rg.int(1, 5)
    roll = rg.next()
    for i, x in enumerate((lx, lx + 1)):
        c1, c2 = _strata(material, c.ox + x)
        ly = 15 - (c2 - 1) - c.oy
        if Q.zone(x, ly) != "face" or Q.depth(x, ly) < 1:
            continue
        if material == "cliff":
            Q.put(x, ly, p["ledge"][i % 2])
        elif c.season == "winter" or (c.season == "autumn" and i == 0):
            Q.put(x, ly, p["mineral"])
        if c.weather == "rainy" and i == 0 and roll < 0.6:
            Q.put(x, ly, p["glint"] if material == "cliff" else p["wetglint"])
    sx = rg.int(1, 6)
    if c.weather == "rainy":
        rows = [ly for ly in _face_rows(Q, sx) if Q.depth(sx, ly) >= 1][:3]
        for i, ly in enumerate(rows):
            if material == "cliff":
                Q.put(sx, ly, p["damp"])
            else:
                Q.put(sx, ly, p["wetglint"] if i == 0 else p["seep"])


def _paint_cave(c, gx, gy, geo):
    zone, d, tv, th = geo
    p = c.pal
    cv = p["c"]
    if zone == "out":
        if d > -1 and not (c.V == "S" and tv < 0):
            return p["shadow"]
        return None
    n = hash01(gx, gy, 560 + c.variant * 13)
    if zone == "face":
        rb, (c1, c2) = 15 - gy, _strata("cave", gx)
        if d < 1:
            col = cv[1]
        elif rb == 0:
            col = mix(cv[0], cv[1], 0.5)
        elif rb in (c1, c2):
            col = cv[1]
        elif rb in (c1 - 1, c2 - 1):
            col = cv[4]
        elif rb > c2:
            col = mix(cv[3], cv[4], 0.5)
        elif rb > c1:
            col = cv[3]
        else:
            col = mix(cv[2], cv[3], 0.6)
        if d >= 1 and rb not in (0, c1, c2):
            if n > 0.93:
                col = shade(col, 0.4)
            elif n < 0.05:
                col = shade(col, -0.4)
            if c.weather == "rainy" and rb < c1:
                col = mix(col, p["seep"], 0.5)
        if c.shape == "outer" and th < 1 and d >= 1 and rb not in (c1, c2):
            col = cv[4] if c.H == "W" else cv[1]
        if c.shape == "inner" and th > -1:
            col = cv[0]
        return col
    if zone == "in":
        pn = pnoise(gx, gy, 561)
        col = p["top"]
        if pn > 0.7:
            col = p["vein"]
        elif pn < 0.26:
            col = p["top_lo"]
        if n > 0.96:
            col = p["fleck"]
        return col
    if zone == "N":
        return cv[3] if d < 1 else cv[4]
    if zone == "W":
        return cv[3] if d < 1 else mix(cv[3], cv[4], 0.5)
    if zone == "E":
        return cv[2] if d < 1 else mix(cv[1], cv[2], 0.6)
    return cv[5] if d < 1 else cv[4]


def _deco_cave(Q):
    c, p = Q.c, Q.c.pal
    cv = p["c"]
    rg = Q.rng(1)
    lx, ly = rg.int(1, 4), rg.int(1, 5)
    pts = [(lx, ly), (lx + 1, ly), (lx + 2, ly + 1)]
    if c.variant != 2 and Q.all_zone(pts, IN):
        for x, y in pts:
            Q.put(x, y, p["fleck"])
        if c.variant == 3 or c.weather == "rainy":
            Q.put(lx, ly, p["mineral"] if c.weather != "rainy" else p["wetglint"])
    if any(_face_rows(Q, x) for x in range(8)):
        _face_details(Q, rg, cv, "cave")
    elif c.season == "spring" and c.variant in (0, 3):
        for side in Q.open_sides():
            pt = Q.edge_point(side, 3)
            if pt:
                Q.put(*pt, mix(cv[3], p["mineral"], 0.6))


# ---------------------------------------------------------------- soil + tilled

FURROW = {3: 4, 0: 3, 1: 1, 2: 2}


def _soil_rim(c, gx, gy, zone, d):
    L = c.pal["L"]
    if zone in ("N", "W"):
        col = L[1] if d < 1 else L[2]
    else:
        col = L[2] if d < 1 else L[3]
    if d < 1 and hash01(gx, gy, 571) > 0.8:
        col = L[3] if zone in ("S", "E") else L[2]
    if c.season == "winter" and d < 1 and hash01(gx, gy, 572) > 0.5:
        col = mix(col, c.pal["frost"][0], 0.55)
    return col


def _paint_soil(c, gx, gy, geo):
    zone, d = geo[0], geo[1]
    L = c.pal["L"]
    if zone == "out":
        return None
    if zone == "in":
        pn = pnoise(gx, gy, 570)
        col = L[4] if pn > 0.68 else L[2] if pn < 0.3 else L[3]
        n = hash01(gx, gy, 573 + c.variant * 5)
        if n > 0.95:
            col = L[4]
        elif n < 0.05:
            col = L[2]
        return col
    return _soil_rim(c, gx, gy, zone, d)


def _furrow(c, gx, gy):
    L = c.pal["L"]
    k = FURROW[gy % 4]
    col = L[k]
    n = hash01(gx, gy, 580 + c.variant * 5)
    if k == 4 and n > 0.84:
        col = L[5]
    elif k == 1 and n > 0.9:
        col = L[2]
    elif k == 3 and n < 0.06:
        col = L[2]
    return col


def _paint_tilled(c, gx, gy, geo):
    zone, d = geo[0], geo[1]
    if zone == "out":
        return None
    f = _furrow(c, gx, gy)
    if zone == "in":
        return f
    rim = _soil_rim(c, gx, gy, zone, d)
    return rim if d < 1 else mix(rim, f, 0.45)


def _deco_soil(Q, tilled=False):
    c, p = Q.c, Q.c.pal
    L = p["L"]
    rg = Q.rng(1)
    tops = []
    for _ in range(2 + c.variant % 2):
        lx, ly = rg.int(1, 5), rg.int(1, 6)
        if tilled:
            ly = (c.oy + ly) // 4 * 4 + 3 - c.oy
            if ly > 6:
                ly -= 4
            pts = [(lx, ly, L[5]), (lx + 1, ly, L[4]), (lx + 1, ly + 1, L[1])]
        else:
            pts = [(lx, ly, L[5]), (lx + 1, ly, L[4]), (lx, ly + 1, L[3]), (lx + 1, ly + 1, L[1])]
        if Q.all_ground([(x, y) for x, y, _ in pts]):
            for x, y, col in pts:
                Q.put(x, y, col)
            tops.append((lx, ly))
    lx, ly = rg.int(1, 5), rg.int(1, 5)
    if c.variant == 2 and not tilled:
        Q.pebble(lx, ly, False, p["stone"], L[1])
    for ly in range(8):
        for lx in range(8):
            if Q.zone(lx, ly) == "out" and Q.depth(lx, ly) > -1 and hash01(c.ox + lx, c.oy + ly, 574) > 0.8:
                Q.put(lx, ly, L[2])
    if c.weather == "rainy":
        for x, y in tops[:2]:
            Q.put(x, y, p["sheen"])
    rv = Q.rng(2)
    if c.season == "spring" and c.variant in (1, 3):
        for side in Q.open_sides()[:1]:
            pt = Q.edge_point(side, rv.int(2, 5))
            if pt:
                x, y = pt
                Q.put(x, y, GRASS[2])
                Q.put(x, y - 1, GRASS[4])
                Q.put(x + 1, y - 1, GRASS[5])
    elif c.season == "summer":
        Q.edge_tufts(rv, p["tuft"], 0.45)
    Q.debris(Q.rng(3), puddle=p["puddle"])


# ---------------------------------------------------------------- dispatch

PAINTERS = {
    "dirt": (_paint_dirt, _deco_dirt),
    "pond": (_paint_pond, _deco_pond),
    "ocean": (_paint_ocean, _deco_ocean),
    "cliff": (_paint_cliff, _deco_cliff),
    "soil": (_paint_soil, lambda Q: _deco_soil(Q, False)),
    "tilled": (_paint_tilled, lambda Q: _deco_soil(Q, True)),
    "cave": (_paint_cave, _deco_cave),
}


def _render(material, quadrant, shape, season, weather, variant):
    c = _Ctx()
    c.material, c.q, c.shape, c.season, c.weather, c.variant = material, quadrant, shape, season, weather, variant
    c.mi, c.qi = MATERIALS.index(material) + 1, QUADRANTS.index(quadrant) + 1
    c.ox, c.oy = ORIGIN[quadrant]
    c.V = "N" if quadrant[0] == "n" else "S"
    c.H = "W" if quadrant[1] == "w" else "E"
    c.g = GEOMETRY[material]
    c.pal = _palette(material, season, weather)
    Q = _Quarter(c)
    paint, deco = PAINTERS[material]
    for ly in range(8):
        for lx in range(8):
            col = paint(c, c.ox + lx, c.oy + ly, Q.geo[ly][lx])
            Q.px[ly][lx] = rgba(col) if col is not None else None
    deco(Q)
    out = bytearray(8 * 8 * 4)
    for ly in range(8):
        for lx in range(8):
            col = Q.px[ly][lx]
            if col:
                o = (ly * 8 + lx) * 4
                out[o:o + 4] = bytes(col)
    return bytes(out)


def _check(material, season, weather, quadrant=None, shape=None):
    if material not in MATERIALS:
        raise ValueError("unknown material %r" % (material,))
    if season not in SEASONS:
        raise ValueError("unknown season %r" % (season,))
    if weather not in WEATHERS:
        raise ValueError("unknown weather %r" % (weather,))
    if quadrant is not None and quadrant not in QUADRANTS:
        raise ValueError("unknown quadrant %r" % (quadrant,))
    if shape is not None and shape not in SHAPES:
        raise ValueError("unknown shape %r" % (shape,))


def quarter(Pixels, material, quadrant, shape, season, weather, variant=0):
    """One 8x8 quarter piece in the quadrant's global tile coordinates."""
    _check(material, season, weather, quadrant, shape)
    key = (material, quadrant, shape, season, weather, variant % 4)
    data = _CACHE.get(key)
    if data is None:
        data = _CACHE[key] = _render(*key)
    p = Pixels(8, 8)
    p.data[:] = data
    return p


# ---------------------------------------------------------------- assembly

def _normalize(raw_mask):
    m = raw_mask & 15
    for bit, a, b in ((16, 1, 2), (32, 4, 2), (64, 4, 8), (128, 1, 8)):
        if raw_mask & bit and raw_mask & a and raw_mask & b:
            m |= bit
    return m


def _canonical_masks():
    return sorted({_normalize(i) for i in range(256)})


def _quarter_shape(mask, quadrant):
    v, h, diag = QUARTER_BITS[quadrant]
    sv, sh = bool(mask & v), bool(mask & h)
    if sv and sh:
        return "fill" if mask & diag else "inner"
    if not sv and not sh:
        return "outer"
    return "horizontal" if sh else "vertical"


def _assemble(Pixels, mask, quarter_function):
    out = Pixels(16, 16)
    for quadrant, (ox, oy) in ORIGIN.items():
        piece = quarter_function(quadrant, _quarter_shape(mask, quadrant))
        for y in range(8):
            o = ((oy + y) * 16 + ox) * 4
            out.data[o:o + 32] = piece.data[y * 32:(y + 1) * 32]
    return out


try:
    from border_tiles16 import normalize, canonical_masks, assemble
except ImportError:
    normalize, canonical_masks, assemble = _normalize, _canonical_masks, _assemble


def tile(Pixels, material, mask, season, weather, variant=0):
    """Full 16x16 connected tile for an eight-neighbour mask (N1 E2 S4 W8 NE16 SE32 SW64 NW128)."""
    _check(material, season, weather)
    return assemble(Pixels, normalize(mask),
                    lambda q, s: quarter(Pixels, material, q, s, season, weather, variant))


# ---------------------------------------------------------------- plant overlays

def plant_overlays(Pixels):
    """Transparent plant-only sprites drawn over the connected soil/tilled layer."""
    out = {}
    scuff = (58, 38, 26)

    p = Pixels(16, 16)
    for x, a in ((7, 120), (8, 170), (9, 120)):
        p.dot(x, 11, scuff + (a,))
    p.vline(8, 7, 10, LEAF_OAK[3])
    p.dot(8, 10, LEAF_OAK[2])
    p.hline(5, 7, 7, LEAF_OAK[4])
    p.dot(5, 6, LEAF_OAK[5])
    p.dot(6, 8, LEAF_OAK[2])
    p.dot(7, 8, LEAF_OAK[2])
    p.hline(9, 11, 6, LEAF_OAK[3])
    p.dot(11, 5, LEAF_OAK[4])
    p.dot(9, 7, LEAF_OAK[1])
    p.dot(10, 7, LEAF_OAK[1])
    out["plant_overlay_sprout"] = p

    p = Pixels(16, 16)
    for x in range(6, 11):
        p.dot(x, 13, scuff + (70 if x in (6, 10) else 110,))
    for x, y in ((12, 3), (10, 2)):
        p.line(8, 7, x, y, LEAF_OAK[2])
        p.dot(x, y, LEAF_OAK[4])
    for x, y in ((4, 3), (6, 2), (8, 1)):
        p.line(8, 7, x, y, LEAF_OAK[3])
        p.dot(x, y, LEAF_OAK[5])
    p.dot(8, 6, LEAF_OAK[1])
    p.dot(8, 7, LEAF_OAK[1])
    p.oval(8, 10, 3.5, 2.6, "efe6dc")
    p.hline(5, 11, 9, "a75a9a")
    p.hline(6, 10, 8, "c27ab4")
    p.dot(6, 8, "d79ac8")
    p.vline(11, 10, 11, "d2c4b8")
    p.hline(6, 10, 12, "cdbfb1")
    p.dot(10, 12, "b8a898")
    p.dot(6, 10, "fbf6ee")
    p.dot(8, 13, "b8a898")
    out["plant_overlay_turnip"] = p

    p = Pixels(16, 16)
    for x in range(6, 11):
        p.dot(x, 12, scuff + (60 if x in (6, 10) else 100,))
    for x, y in ((11, 3), (8, 2)):
        p.line(8, 7, x, y, LEAF_BIRCH[2] if x == 11 else LEAF_BIRCH[3])
        p.dot(x, y, LEAF_BIRCH[4])
    p.line(8, 7, 5, 3, LEAF_BIRCH[3])
    p.dot(5, 3, LEAF_BIRCH[5])
    p.dot(8, 7, LEAF_BIRCH[1])
    for dx, dy in ((0, 0), (-1, 0), (1, 0), (0, -1), (0, 1), (-2, 1), (2, 1), (-1, 2), (1, 2), (-2, 0), (2, 0)):
        p.dot(8 + dx, 9 + dy, GOLD[3])
    for x, y in ((10, 9), (10, 10), (9, 11), (9, 10)):
        p.dot(x, y, GOLD[2])
    p.dot(7, 8, GOLD[5])
    p.dot(6, 9, GOLD[4])
    p.dot(8, 9, "fbf0c4")
    p.hline(7, 9, 11, GOLD[1])
    p.dot(4, 6, "fff4bf88")
    p.dot(12, 7, "fff4bf88")
    out["plant_overlay_bulb"] = p
    return out


# ---------------------------------------------------------------- export

def sprites(Pixels):
    """All quarter pieces, all 47-mask tiles for every material/season/weather/variant, and plant overlays."""
    out = {}
    masks = list(canonical_masks())
    for material in MATERIALS:
        for season in SEASONS:
            for weather in WEATHERS:
                for variant in VARIANTS:
                    pieces = {}
                    for q in QUADRANTS:
                        for s in SHAPES:
                            img = quarter(Pixels, material, q, s, season, weather, variant)
                            pieces[(q, s)] = img
                            out["border_quarter_%s_%s_%s_%s_%s_%d" % (material, q, s, season, weather, variant)] = img
                    for mask in masks:
                        out["tile_border_%s_m%d_%s_%s_%d" % (material, mask, season, weather, variant)] = \
                            assemble(Pixels, mask, lambda q, s: pieces[(q, s)])
    out.update(plant_overlays(Pixels))
    return out
