"""Option-3 farm additions: icons and field sprites for the seasonal vegetables.

sprites(Pixels) -> dict[str, Pixels]. make_sprites16.py calls this while building the
rustic16 atlas, so run that script rather than this one.

Each crop gets a seed packet icon, a produce icon, and two transparent 16px field
overlays: "growing" while it matures (and while tomatoes and cucumbers regrow) and
"ripe" when it can be harvested.
"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import make_sprites16 as base  # noqa: E402

LEAF = base.LEAF_OAK
PAPER = base.LINEN
SCUFF = (58, 38, 26)
TOMATO = ["7a2418", "a83a2c", "d8503a", "f08a6a", "f6b096"]
CUCUMBER = ["2e4a24", "3f6630", "4f7a35", "6f9a48", "a8cc78"]
GLADAIN = ["6a4a1e", "8a6a2a", "c9a24a", "ead17a", "f6e6a8"]
ONION_WHITE = ["b8a888", "d8d0b8", "f2eedc", "fffcf0"]


def scuff(p, y, x0=6, x1=10):
    for x in range(x0, x1 + 1):
        p.dot(x, y, SCUFF + (70 if x in (x0, x1) else 110,))


def packet(p, background):
    p.box(2, 1, 8, 10, PAPER[3]); p.hline(2, 9, 1, PAPER[5]); p.vline(9, 2, 10, PAPER[1]); p.hline(2, 9, 10, PAPER[1])
    p.hline(2, 9, 2, PAPER[2])
    p.box(3, 4, 6, 5, background)


def onion_stalks(p, xs, top, bottom):
    for i, x in enumerate(xs):
        p.vline(x, top + i % 2, bottom, LEAF[3] if i % 2 else LEAF[4])
        p.dot(x, top + i % 2, LEAF[5])


def tomato(p, x, y):
    p.dot(x, y, TOMATO[2]); p.dot(x + 1, y, TOMATO[1]); p.dot(x, y + 1, TOMATO[1]); p.dot(x + 1, y + 1, TOMATO[0])
    p.dot(x, y, TOMATO[3])


def leaf(p, x, y, shade=3):
    p.dot(x, y, LEAF[shade]); p.dot(x + 1, y, LEAF[shade + 1]); p.dot(x, y + 1, LEAF[shade - 1])


def items(Pixels):
    out = {}

    p = Pixels(12, 12)
    onion_stalks(p, (4, 5, 7, 8), 1, 6)
    p.hline(4, 8, 5, GLADAIN[2])
    p.box(4, 7, 5, 3, ONION_WHITE[2]); p.vline(4, 7, 9, ONION_WHITE[3]); p.hline(5, 8, 9, ONION_WHITE[1])
    for x in (4, 6, 8): p.dot(x, 10, ONION_WHITE[0])
    out["item_green_onions"] = p

    p = Pixels(12, 12)
    p.oval(6.4, 7.3, 4, 3.4, TOMATO[1]); p.oval(5.8, 6.8, 3.6, 3, TOMATO[2])
    p.dot(4, 5, TOMATO[4]); p.dot(5, 5, TOMATO[3]); p.dot(4, 6, TOMATO[3])
    for x, y in ((5, 3), (6, 3), (7, 3), (6, 2)): p.dot(x, y, LEAF[2])
    p.dot(4, 4, LEAF[3]); p.dot(8, 4, LEAF[3])
    out["item_tomatoes"] = p

    p = Pixels(12, 12)
    for t in range(8):
        p.oval(3 + t * 0.85, 9 - t * 0.85, 1.8, 1.8, CUCUMBER[1])
    p.line(3, 8, 8, 3, CUCUMBER[3])
    for x, y in ((4, 7), (6, 5), (8, 4)): p.dot(x, y, CUCUMBER[4])
    p.dot(10, 2, GLADAIN[1])
    out["item_cucumbers"] = p

    p = Pixels(12, 12)
    p.oval(6.3, 7.3, 4, 3, GLADAIN[1]); p.oval(6, 7, 3.8, 2.8, GLADAIN[2])
    p.dot(4, 5, GLADAIN[4]); p.dot(5, 5, GLADAIN[3]); p.dot(3, 6, GLADAIN[3])
    for x, y in ((7, 7), (4, 8), (8, 6)): p.dot(x, y, GLADAIN[0])
    p.dot(8, 3, LEAF[3]); p.dot(9, 2, LEAF[4])
    out["item_gladain"] = p

    p = Pixels(12, 12)
    packet(p, "cfe3b0")
    for x in (4, 5, 7): p.vline(x, 4, 6, LEAF[3] if x % 2 else LEAF[4])
    p.hline(4, 7, 7, ONION_WHITE[2]); p.hline(4, 7, 8, ONION_WHITE[1])
    out["item_green_onion_seeds"] = p

    p = Pixels(12, 12)
    packet(p, "f2d7b0")
    p.oval(6, 6.6, 2.2, 1.8, TOMATO[2]); p.dot(5, 6, TOMATO[3])
    for x in (5, 6, 7): p.dot(x, 4, LEAF[2])
    out["item_tomato_seeds"] = p

    p = Pixels(12, 12)
    packet(p, "e0eccc")
    p.line(4, 8, 8, 4, CUCUMBER[1]); p.line(4, 7, 7, 4, CUCUMBER[3]); p.dot(5, 6, CUCUMBER[4])
    out["item_cucumber_seeds"] = p

    p = Pixels(12, 12)
    packet(p, "efe0c0")
    p.oval(6, 6.6, 2.4, 1.7, GLADAIN[2]); p.dot(5, 6, GLADAIN[3]); p.dot(7, 7, GLADAIN[0])
    p.dot(7, 4, LEAF[3])
    out["item_gladain_seeds"] = p

    for icon in out.values(): icon.outline(k=-3.0)
    return out


def plants(Pixels):
    out = {}

    p = Pixels(16, 16)
    scuff(p, 12)
    onion_stalks(p, (6, 8, 10), 5, 11)
    out["plant_overlay_green_onions_growing"] = p

    p = Pixels(16, 16)
    scuff(p, 13, 4, 12)
    onion_stalks(p, (5, 6, 8, 9, 11), 1, 10)
    p.hline(5, 11, 10, ONION_WHITE[2]); p.hline(5, 11, 11, ONION_WHITE[1])
    for x in (5, 8, 11): p.dot(x, 11, ONION_WHITE[3])
    out["plant_overlay_green_onions_ripe"] = p

    for ripe in (False, True):
        p = Pixels(16, 16)
        scuff(p, 13)
        p.vline(8, 2, 12, "a8845a"); p.vline(9, 3, 12, "7a5c3a")
        for x, y in ((5, 4), (10, 5), (6, 7), (10, 8), (5, 10), (10, 11), (7, 3)): leaf(p, x, y, 3 if x < 8 else 2)
        if ripe:
            for x, y in ((6, 5), (11, 7), (5, 8), (11, 10)): tomato(p, x, y)
        else:
            p.dot(11, 4, "e2c84f"); p.dot(5, 9, "e2c84f")
        out["plant_overlay_tomatoes_" + ("ripe" if ripe else "growing")] = p

    for ripe in (False, True):
        p = Pixels(16, 16)
        scuff(p, 13, 3, 13)
        for cx, cy in ((5, 9), (11, 8), (8, 11)):
            p.oval(cx, cy, 2.2, 1.6, LEAF[3]); p.dot(cx - 1, cy - 1, LEAF[4]); p.dot(cx + 1, cy + 1, LEAF[1])
        p.line(5, 9, 8, 6, LEAF[2]); p.line(11, 8, 12, 5, LEAF[2]); p.dot(13, 4, LEAF[3])
        if ripe:
            # Darker rind and a pale stripe so the fruit stands out from the leaves around it.
            for cx, cy, rx in ((6, 12, 3), (11, 11, 2.6)):
                p.oval(cx, cy, rx, 1.3, CUCUMBER[0])
                p.hline(round(cx - rx + 1), round(cx + rx - 1), cy, CUCUMBER[2])
                p.hline(round(cx - rx + 2), round(cx + rx - 2), cy - 1, CUCUMBER[4])
        else:
            p.dot(8, 6, "f0d050"); p.dot(12, 5, "f0d050")
        out["plant_overlay_cucumbers_" + ("ripe" if ripe else "growing")] = p

    for ripe in (False, True):
        p = Pixels(16, 16)
        scuff(p, 13, 4, 12)
        # Gladain leaves yellow off once the tubers underneath are ready.
        ramp = ["5a5a2a", "8a8a3a", "b8b04a", "d8cc6a", "ecdf8a"] if ripe else LEAF[1:]
        for cx, cy in ((8, 5), (5, 7), (11, 7), (7, 9), (10, 10)):
            p.oval(cx, cy, 1.8, 1.4, ramp[2]); p.dot(cx - 1, cy - 1, ramp[3]); p.dot(cx + 1, cy, ramp[1])
        p.vline(8, 7, 11, ramp[1])
        if ripe:
            for cx, cy in ((5, 12), (10, 12)):
                p.oval(cx, cy, 1.8, 1.1, GLADAIN[2]); p.dot(cx - 1, cy - 1, GLADAIN[3]); p.dot(cx + 1, cy, GLADAIN[1])
        out["plant_overlay_gladain_" + ("ripe" if ripe else "growing")] = p
    return out


def sprites(Pixels):
    return dict(items(Pixels), **plants(Pixels))
