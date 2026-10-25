"""Alternative surface study for the eight-neighbour border set: flat, opaque 16x16 centre tiles.

paving: chunky warm hand-laid village setts in three jogged courses, rounded worn tops, warm mortar.
jetty:  cool dressed maritime flags in three staggered ashlar courses, flush faces with a shallow lit
        arris, thin joints, a little chisel, salt and lichen wear.

surface(P, material, season, weather, variant) paints one tileable tile.  The stone/joint skeleton,
its shading and all seasonal/weather dressing on the outer pixel ring depend only on
(material, season, weather); variants 0..3 alter pixels 1..14 only (wear, grain, lichen, debris).
sprites(P) returns the 96 tiles keyed tile_border_{material}_fill_{season}_{weather}_{variant}.
palette(material, season, weather) returns the colours later curb/coping art should reuse.
"""

MATERIALS = ("paving", "jetty")
SEASONS = ("spring", "summer", "autumn", "winter")
WEATHERS = ("sunny", "partly_cloudy", "rainy")
VARIANTS = 4


def rgb(c):
    if isinstance(c, tuple):
        return c if len(c) == 4 else tuple(c) + (255,)
    return tuple(bytes.fromhex(c)) + ((255,) if len(c) == 6 else ())


def mix(a, b, t):
    a, b = rgb(a), rgb(b)
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3)) + (255,)


# ---------------------------------------------------------------- skeletons
# Stone letters, '.' = joint.  Both maps wrap on all four sides.
MAPS = {
    "paving": (
        "aaa.bbbb.cccc.aa",
        "aaa.bbbb.cccc.aa",
        "aaa.bbbb.cccc.aa",
        "aaa.bbbb.cccc.aa",
        "................",
        "......eeeee.ffff",
        ".dddd.eeeee.ffff",
        ".dddd.eeeee.ffff",
        ".dddd.eeeee.ffff",
        ".dddd.eeeee.ffff",
        "................",
        "hhhhhh.....jjjj.",
        "hhhhhh.iii.jjjj.",
        "hhhhhh.iii.jjjj.",
        "hhhhhh.iii......",
        "................",
    ),
    "jetty": (
        "LLLLL.KKKKKKKK.L",
        "LLLLL.KKKKKKKK.L",
        "LLLLL.KKKKKKKK.L",
        "LLLLL.KKKKKKKK.L",
        "LLLLL.KKKKKKKK.L",
        "................",
        "NN.MMMMMMMMM.NNN",
        "NN.MMMMMMMMM.NNN",
        "NN.MMMMMMMMM.NNN",
        "NN.MMMMMMMMM.NNN",
        "................",
        ".OOOOOOOO.QQQQQQ",
        ".OOOOOOOO.QQQQQQ",
        ".OOOOOOOO.QQQQQQ",
        ".OOOOOOOO.QQQQQQ",
        "................",
    ),
}
ROUNDED = {"paving": True, "jetty": False}  # setts lose every corner; dressed flags stay square
CHIPS = {"paving": ((11, 3), (15, 7), (5, 12)), "jetty": ((13, 4), (3, 6), (10, 14))}

# Ramp index per edge role: 0 deepest shadow .. 6 top-left arris glint.
FORMS = {
    "dome": dict(tl=6, t=5, l=4, r=2, b=1, br=0, mid=3, dome=4),
    "flat": dict(tl=5, t=4, l=4, r=2, b=2, br=1, mid=3),
    "tilt": dict(tl=6, t=5, l=4, r=1, b=1, br=0, mid=3, low=2),
    "slab": dict(tl=6, t=5, l=4, r=2, b=2, br=1, mid=3),
    "flag": dict(tl=5, t=4, l=4, r=3, b=2, br=1, mid=3),  # flush flag: only the lit arris and lower lip read
}
STONES = {  # letter: (form, tint, tint amount)
    "paving": {
        "a": ("dome", "c89a64", .22), "b": ("flat", "a09484", .10), "c": ("tilt", "a87866", .24),
        "d": ("dome", "8c8a84", .28), "e": ("dome", "c4a274", .16), "f": ("flat", "9c7c68", .18),
        "h": ("tilt", "908e88", .22), "i": ("dome", "d0a46c", .30), "j": ("flat", "a87a60", .22),
    },
    "jetty": {
        "K": ("slab", "74888a", .14), "L": ("flag", "8c8476", .22), "M": ("flag", "687a90", .16),
        "N": ("slab", "7c8a7e", .16), "O": ("flag", "7a7c80", .05), "Q": ("flag", "807a70", .12),
    },
}
# Lead-set iron cramps across joints: (x, y, iron index).  None on the flush jetty surface.
FIXTURES = {"paving": (), "jetty": ()}
# Shallow marks shared by every variant, stone pixels only: (x, y, ramp index).
FACE = {
    "paving": (),
    "jetty": ((8, 2, 4), (9, 2, 4), (9, 3, 4),      # foot-polished patch on the long flag
              (6, 8, 2), (7, 7, 2), (8, 7, 2),      # hairline bedding crack
              (2, 2, 2), (3, 3, 4),                 # weathered pit, lit far wall
              (12, 12, 4), (13, 12, 4)),            # pale quartz streak
}

# Joint anchors for seasonal dressing: shared (may touch the ring), then per-variant interior ones.
ANCHORS = {
    "paving": (((8, 0), (0, 10), (13, 15), (15, 12), (0, 7), (11, 4), (5, 8), (10, 13)),
               (((3, 2), (9, 10), (12, 14)), ((6, 4), (11, 7), (2, 10)),
                ((13, 2), (5, 6), (6, 13)), ((3, 1), (14, 10), (10, 12)))),
    "jetty": (((0, 12), (7, 15), (15, 10), (14, 0), (5, 3), (9, 12), (12, 8)),
              (((3, 5), (2, 7), (9, 14)), ((11, 5), (2, 8), (6, 10)),
               ((14, 3), (4, 10), (9, 11)), ((8, 5), (5, 2), (12, 10)))),
}
STATE_PICK = {"spring": (0, 3, 6), "summer": (0, 1, 2, 4, 5, 7), "autumn": (1, 4, 6),
              "winter": (0, 2, 3, 5, 6, 7)}
VARIANT_PICK = {"spring": (0, 1), "summer": (0, 1, 2), "autumn": (1, 2), "winter": (0, 1, 2)}
# Winter snow (or rainy slush) lying along horizontal joints: (x0, x1, y).
SPANS = {"paving": ((5, 8, 4), (12, 14, 10), (1, 3, 15)), "jetty": ((7, 11, 5), (3, 7, 10), (11, 14, 15))}

# Interior-only variant treatments: (x, y, k); int k = ramp index of the stone/joint underneath,
# "m<i>" = mortar step, otherwise palette key + index.
WEAR = {
    "paving": (
        # 0 foot-polished hollows and a pit
        ((8, 7, 4), (9, 7, 4), (8, 8, 5), (2, 12, 4), (3, 12, 5), (13, 8, 1), (3, 8, 2)),
        # 1 cracked sett, chipped arrises
        ((7, 6, 1), (8, 7, 1), (8, 8, 0), (9, 8, 4), (4, 7, "m1"), (3, 7, 2), (3, 11, "m2"),
         (3, 12, 4), (12, 2, "m1"), (11, 2, 2)),
        # 2 lichen rosettes
        ((5, 1, "lichen2"), (6, 1, "lichen1"), (6, 2, "lichen0"), (4, 12, "lichen1"),
         (3, 13, "lichen1"), (4, 13, "lichen2"), (13, 7, "lichen0"), (14, 7, "lichen1")),
        # 3 soot stain, grain and pebbles in the joints
        ((2, 7, 2), (3, 7, 2), (2, 8, 2), (7, 8, 2), (8, 8, 2), (9, 7, 2), (12, 12, 2),
         (9, 4, "pebble1"), (10, 4, "pebble0"), (5, 10, "pebble1"), (6, 10, "pebble0"),
         (12, 10, "pebble1"), (13, 10, "pebble0")),
    ),
    "jetty": (
        # 0 short parallel chisel strokes on three faces
        ((2, 12, 2), (3, 13, 2), (5, 12, 2), (6, 13, 2), (14, 7, 2), (15, 8, 2),
         (11, 1, 2), (12, 2, 2)),
        # 1 salt crust along the lower lips and a chipped arris
        ((4, 9, "salt1"), (5, 9, "salt0"), (7, 4, "salt1"), (8, 4, "salt0"), (13, 13, "salt1"),
         (14, 13, "salt0"), (14, 12, "salt1"), (11, 7, "m1")),
        # 2 sea lichens: an orange rosette on the buff flag, grey on the neutral one
        ((2, 1, "lichen1"), (1, 2, "lichen1"), (2, 2, "lichen2"), (3, 2, "lichen0"),
         (2, 3, "lichen0"), (14, 8, "lichen0"), (15, 8, "lichen1"), (6, 13, "lgrey1"),
         (7, 13, "lgrey0"), (7, 12, "lgrey1")),
        # 3 rope-polished streak, a tar smear and a shell lodged in the joint
        ((3, 12, 4), (4, 12, 5), (5, 12, 4), (11, 3, "tar1"), (12, 3, "tar0"),
         (9, 13, "shell0"), (9, 14, 1)),
    ),
}
# Rain puddles (frozen to ice in dry winter) sitting in each variant's hollows: (x, y, puddle index).
PUDDLES = {
    "paving": (((8, 7, 0), (9, 7, 1), (8, 8, 1), (9, 8, 2)),
               ((9, 4, 0), (10, 4, 1), (11, 4, 1), (12, 4, 2)),
               ((2, 12, 0), (3, 12, 1), (3, 13, 2)),
               ((12, 14, 0), (13, 14, 1), (14, 14, 2))),
    "jetty": (((6, 8, 0), (7, 8, 1), (8, 8, 2)),
              ((3, 13, 0), (4, 13, 1), (5, 13, 2)),
              ((9, 3, 0), (10, 3, 1), (11, 3, 2)),
              ((11, 13, 0), (12, 13, 1), (13, 13, 2))),
}

# ---------------------------------------------------------------- palette
BASE = {
    "paving": (["3b2f2a", "5a4a3e", "7a6754", "988270", "b49d84", "cdb898", "e6d4b0"],
               ["30241e", "43342a", "5c4936", "72604a"]),
    "jetty": (["262a32", "3c434c", "56606a", "6f7983", "8b959b", "a9b1b2", "cad0ca"],
              ["1e1d22", "2c2a2c", "433e3a", "58524a"]),
}
SEASON_TINT = {  # stone tint, amount, mortar tint, amount
    "spring": ("8e9c78", .06, "46582e", .20),
    "summer": ("ead2a2", .13, "b8a070", .30),
    "autumn": ("a2683a", .08, "5c3a22", .14),
    "winter": ("a8b4c8", .16, "8a96a8", .20),
}
ACCENT = {
    "spring": ["3c5a2c", "5a7a36", "86a04a"],
    "summer": ["9a845e", "c4ac7c", "e0cc9e"],
    "autumn": ["8a3a22", "b8502a", "d88a2e", "e2b442"],
    "winter": ["a8b8ca", "d4dee8", "f2f6fa"],
}
LICHEN = {"paving": ["6e7448", "9a9c5e", "c4bc84"], "jetty": ["8e6226", "c08c30", "e4c462"]}
EXTRA = {
    "iron": ["2e3238", "4a5058", "7a848a"], "rust": ["6a4430", "8e5a36"],
    "salt": ["bcc4c0", "e0e6e0"], "tar": ["1e1c22", "34303a"], "shell": ["e6dece"],
    "pebble": ["5a4c40", "a49482"], "lgrey": ["7a846e", "a6ae90"],
}


def palette(material, season, weather):
    """Colours for one state, all RGBA tuples.

    stone:  7-step ramp, 0 deepest shadow, 1 lower edge, 2 right edge, 3 face, 4 left edge,
            5 top edge (frosted in dry winter, sky-tinted when wet), 6 top-left arris glint.
    mortar: 0 deep corner shadow, 1 shadow under a stone, 2 joint, 3 open joint.
    accent: seasonal joint dressing dark->light (moss, dust/wet sand, 4 leaf hues, snow/slush).
    puddle: 3 steps of rain water, slush or (dry winter) ice; None when there is none.
    lichen, lgrey, iron, rust, salt, tar, shell, pebble: detail colours.
    coping: [shadow, face, top, arris] suggested for future curbstones and jetty coping.
    """
    stone, mortar = BASE[material]
    st, sa, mt, ma = SEASON_TINT[season]
    stone = [mix(c, st, sa) for c in stone]
    mortar = [mix(c, mt, ma) for c in mortar]
    accent = [rgb(c) for c in ACCENT[season]]
    extra = {k: [rgb(c) for c in v] for k, v in EXTRA.items()}
    extra["lichen"] = [rgb(c) for c in LICHEN[material]]
    puddle = ["8ca2b6", "c2d2de", "eef4f8"] if season == "winter" else None
    if weather == "sunny":
        stone[5] = mix(stone[5], "fff0c8", .18)
        stone[6] = mix(stone[6], "fff4d4", .30)
    elif weather == "partly_cloudy":
        stone = [mix(c, "7c8490", .10) for c in stone]
        stone[5] = mix(stone[5], stone[4], .45)
        stone[6] = mix(stone[6], stone[4], .55)
        mortar = [mix(c, "5a5c64", .08) for c in mortar]
        accent = [mix(c, "8a8c90", .12) for c in accent]
        extra = {k: [mix(c, "7c8490", .08) for c in v] for k, v in extra.items()}
    else:
        stone = [mix(c, "1c2030", .14) for c in stone]
        stone[5] = mix(stone[5], "a8bccc", .30)
        stone[6] = mix(stone[6], "b8ccda", .55)
        mortar = [mix(c, "16141a", .38) for c in mortar]
        extra = {k: [mix(c, "1c2030", .14) for c in v] for k, v in extra.items()}
        if season == "winter":
            accent = [rgb(c) for c in ("56687a", "8494a2", "aebcc6")]
            puddle = ["4e5e6c", "7c8c98", "a8b8c2"]
        else:
            puddle = ["3a5064", "6a879e", "b4c8d6"]
            accent = ([rgb(c) for c in ("6e5a40", "8e7656", "a89070")] if season == "summer"
                      else [mix(c, "1a2414", .18) for c in accent])
    if season == "winter" and weather != "rainy":
        stone[5] = mix(stone[5], "e4ecf4", .45 if weather == "sunny" else .35)
        stone[6] = mix(stone[6], "f0f4f8", .70)
    pal = dict(stone=stone, mortar=mortar, accent=accent,
               puddle=puddle and [rgb(c) for c in puddle], **extra)
    pal["coping"] = [stone[1], stone[2], stone[4], stone[5]]
    return pal


# ---------------------------------------------------------------- painting
def _grid(material):
    rows = MAPS[material]
    raw = {(x, y): rows[y][x] for y in range(16) for x in range(16)}
    g = dict(raw)
    if ROUNDED[material]:
        for (x, y), s in raw.items():
            if s == ".":
                continue
            n = lambda dx, dy: raw[(x + dx) % 16, (y + dy) % 16] == s
            if (not n(0, -1) or not n(0, 1)) and (not n(-1, 0) or not n(1, 0)):
                g[x, y] = "."
    for q in CHIPS[material]:
        g[q] = "."
    return g


def _shade(g, x, y, s, f):
    n = lambda dx, dy: g[(x + dx) % 16, (y + dy) % 16] == s
    up, dn, lf, rt = n(0, -1), n(0, 1), n(-1, 0), n(1, 0)
    if not up and not lf:
        return f["tl"]
    if not dn and not rt:
        return f["br"]
    if not up:
        return f["t"]
    if not lf:
        return f["r"] if not dn else f["l"]
    if not dn:
        return f["b"]
    if not rt:
        return f["r"]
    if "dome" in f and not n(0, -2) and (not n(-2, 0) or not n(-3, 0)):
        return f["dome"]
    if "low" in f and not n(0, 2):
        return f["low"]
    if "margin" in f and not (n(0, -2) and n(0, 2) and n(-2, 0) and n(2, 0)):
        return f["margin"]
    return f["mid"]


def _mortar_step(g, x, y):
    st = lambda dx, dy: g[(x + dx) % 16, (y + dy) % 16] != "."
    if st(0, -1) and st(-1, 0):
        return 0
    if st(0, -1):
        return 1
    if not (st(-1, 0) or st(1, 0) or st(0, 1)):
        return 3
    return 2


def _cluster(g, x, y, n, skip):
    pts = [(x, y)]
    for dx, dy in ((1, 0), (0, 1), (-1, 0), (0, -1), (1, 1), (-1, 1)):
        q = ((x + dx) % 16, (y + dy) % 16)
        if len(pts) < n and g[q] == "." and q not in skip:
            pts.append(q)
    return pts


def _dress(dot, g, pal, season, x, y, k, skip):
    acc = pal["accent"]
    if season == "autumn":
        leaf = acc[k % 4]
        cols = (leaf, mix(leaf, pal["mortar"][0], .45))
    elif season == "winter":
        cols = (acc[2], acc[1], acc[0])
    elif season == "spring":
        cols = (acc[2], acc[1], acc[0])[:3 if k % 2 == 0 else 2]
    else:
        cols = (acc[2], acc[1])
    for (qx, qy), c in zip(_cluster(g, x, y, len(cols), skip), cols):
        dot(qx, qy, c)


def surface(P, material, season, weather, variant=0):
    pal = palette(material, season, weather)
    g = _grid(material)
    kinds = STONES[material]
    ramps = {s: [mix(c, t, a) for c in pal["stone"]] for s, (_, t, a) in kinds.items()}
    p = P(16, 16)
    p.box(0, 0, 16, 16, pal["mortar"][2])
    for y in range(16):
        for x in range(16):
            s = g[x, y]
            if s == ".":
                p.dot(x, y, pal["mortar"][_mortar_step(g, x, y)])
            else:
                p.dot(x, y, ramps[s][_shade(g, x, y, s, FORMS[kinds[s][0]])])
    for x, y, k in FACE[material]:
        if g[x, y] != ".":
            p.dot(x, y, ramps[g[x, y]][k])

    # shared state layer: fixtures, lying snow/slush, seasonal dressing on shared anchors
    fix = {(x, y) for x, y, _ in FIXTURES[material]}
    for x, y, k in FIXTURES[material]:
        p.dot(x, y, pal["iron"][k])
    if season == "winter":
        acc = pal["accent"]
        for x0, x1, y in SPANS[material]:
            for x in range(x0, x1 + 1):
                p.dot(x, y, acc[2] if x == x0 else acc[0] if x == x1 else acc[1])
    shared, inner = ANCHORS[material]
    for i in STATE_PICK[season]:
        if i < len(shared):
            _dress(p.dot, g, pal, season, shared[i][0], shared[i][1], i, fix)

    # variant layer: never touches the outer ring
    v = variant % VARIANTS

    def vdot(x, y, c):
        if 0 < x < 15 and 0 < y < 15:
            p.dot(x, y, c)

    def col(x, y, k):
        if isinstance(k, int):
            s = g[x, y]
            return pal["mortar"][min(k, 3)] if s == "." else ramps[s][k]
        name, i = k[:-1], int(k[-1])
        return pal["mortar" if name == "m" else name][i]

    for x, y, k in WEAR[material][v]:
        vdot(x, y, col(x, y, k))
    if pal["puddle"]:
        for x, y, k in PUDDLES[material][v]:
            vdot(x, y, pal["puddle"][k])
    for j in VARIANT_PICK[season]:
        x, y = inner[v][j]
        _dress(vdot, g, pal, season, x, y, j + v, fix)
    return p


def sprites(P):
    out = {}
    for m in MATERIALS:
        for s in SEASONS:
            for w in WEATHERS:
                for v in range(VARIANTS):
                    out["tile_border_%s_fill_%s_%s_%d" % (m, s, w, v)] = surface(P, m, s, w, v)
    return out
