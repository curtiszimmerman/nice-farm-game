def sprites(Pixels):
    WD, WM, WL, WH = "3e2616", "6e4a2c", "93683f", "b88a55"
    IRD, IRM, IRL = "2a2a30", "5c5f68", "a0a6b0"
    SD, SM, SL, SH = "2b2f39", "454b58", "636b7a", "8a93a3"
    LD, LM, LL = "2f5a2a", "4a8238", "7cb84e"
    RD, RM, RL, RH = "5a0f1c", "9a1e2e", "c8343e", "f4b0a8"
    SHADOW = "00000055"
    out = {}

    def planks(p, x0, y0, w, h, step, base=WM):
        p.box(x0, y0, w, h, base)
        for x in range(x0, x0 + w):
            if (x - x0) % step == step - 1:
                p.vline(x, y0, y0 + h - 1, WD)
            elif (x - x0) % step == 0:
                p.vline(x, y0, y0 + h - 1, WL)
        for i in range(w * h // 9):
            x, y = x0 + (i * 7 + 3) % w, y0 + (i * 5 + 1) % h
            if (x - x0) % step not in (0, step - 1):
                p.dot(x, y, WD if i % 3 else WH)

    p = Pixels(16, 16)
    planks(p, 0, 0, 16, 16, 4)
    for x in (1, 5, 9, 13):
        p.dot(x + 1, 2, IRM)
        p.dot(x + 1, 13, IRM)
    p.hline(0, 15, 15, WD)
    out["tile_shed_wall"] = p

    p = Pixels(16, 16)
    p.box(0, 0, 16, 16, "3a3438")
    for r in range(4):
        y, off = r * 4, (r % 2) * 2
        p.hline(0, 15, y, "5a5058")
        p.hline(0, 15, y + 3, "221e26")
        for x in range(off, 16, 4):
            p.vline(x, y, y + 2, "221e26")
            p.dot(x + 1, y + 1, "4a444c")
    for x, y in ((2, 1), (3, 1), (3, 2), (9, 5), (10, 5), (10, 6), (13, 9), (5, 13), (6, 13), (6, 14), (12, 14)):
        p.dot(x, y, "4f6b34" if (x + y) % 2 else "6b8a40")
    out["tile_shed_roof"] = p

    def door(top):
        p = Pixels(16, 16)
        planks(p, 2, 0, 12, 16, 3, "7a5232")
        p.vline(1, 0, 15, WD)
        p.vline(14, 0, 15, WD)
        p.vline(0, 0, 15, WM)
        p.vline(15, 0, 15, WM)
        if top:
            p.box(0, 0, 16, 2, WD)
            p.hline(1, 14, 2, WH)
            p.hline(2, 13, 10, WD)
            p.hline(2, 13, 9, WL)
            p.line(3, 9, 12, 3, WL)
        else:
            p.hline(2, 13, 6, WL)
            p.hline(2, 13, 7, WD)
            p.box(10, 3, 3, 4, IRD)
            p.dot(10, 3, IRL)
            p.hline(7, 11, 5, IRM)
            p.dot(7, 5, IRL)
            p.box(0, 15, 16, 1, SM)
        return p

    out["tile_shed_door_top"] = door(True)
    out["tile_shed_door_bottom"] = door(False)

    p = Pixels(48, 32)
    p.box(3, 3, 42, 18, WM)
    for y in range(3, 21, 4):
        p.hline(3, 44, y, WL)
        p.hline(3, 44, y + 3, WD)
    for i in range(30):
        p.dot(4 + (i * 11) % 40, 4 + (i * 7) % 16, WD)
    p.box(1, 1, 3, 30, WD)
    p.box(44, 1, 3, 30, WD)
    p.vline(2, 1, 30, WL)
    p.vline(45, 1, 30, WL)
    p.box(1, 21, 46, 3, WH)
    p.box(1, 24, 46, 3, WD)
    p.hline(1, 46, 23, WL)
    p.box(4, 27, 2, 4, WD)
    p.box(42, 27, 2, 4, WD)
    p.hline(2, 46, 31, SHADOW)
    for x in (7, 16, 25, 34, 41):
        p.dot(x, 4, IRD)
    p.vline(7, 5, 20, WL)
    p.vline(8, 5, 20, WD)
    p.hline(4, 11, 6, IRM)
    for x in range(4, 12, 2):
        p.vline(x, 7, 9, IRD)
    p.vline(16, 5, 14, WL)
    p.hline(14, 18, 5, WH)
    p.box(14, 14, 5, 6, IRM)
    p.vline(14, 14, 18, IRL)
    p.hline(15, 17, 20, IRD)
    p.line(22, 6, 26, 14, IRM)
    p.line(28, 6, 24, 14, IRL)
    p.oval(22, 15, 1, 1, "8a2a1a")
    p.oval(26, 15, 1, 1, "8a2a1a")
    p.dot(24, 10, IRD)
    p.oval(34, 11, 4, 5, "c8a46a")
    p.oval(34, 11, 2, 3, "8a6a3a")
    p.oval(34, 11, 1, 1, WD)
    p.vline(34, 5, 6, "c8a46a")
    for gx in (38, 42):
        p.box(gx, 8, 3, 6, "a07a4a")
        p.box(gx, 14, 3, 2, "7a5a32")
        p.vline(gx, 6, 8, "a07a4a")
        p.dot(gx + 2, 9, "c89a62")
    p.dot(10, 22, IRM)
    p.box(30, 21, 4, 1, "c8a46a")
    out["furniture_shed_rack_3x1"] = p

    p = Pixels(32, 24)
    p.box(2, 13, 2, 10, WD)
    p.box(28, 13, 2, 10, WD)
    p.vline(3, 13, 22, WM)
    p.vline(29, 13, 22, WM)
    p.hline(3, 28, 19, WM)
    p.hline(3, 28, 20, WD)
    p.box(0, 6, 32, 4, WH)
    p.hline(0, 31, 6, "d8a868")
    p.hline(3, 9, 8, WL)
    p.hline(15, 24, 7, WL)
    p.box(0, 10, 32, 3, WM)
    p.hline(0, 31, 12, WD)
    p.dot(6, 11, WD)
    p.dot(19, 11, WD)
    p.hline(1, 30, 23, SHADOW)
    p.box(2, 3, 6, 3, IRM)
    p.hline(2, 7, 3, IRL)
    p.box(4, 6, 2, 6, IRD)
    p.hline(0, 4, 4, IRD)
    p.hline(10, 15, 5, WL)
    p.box(15, 3, 3, 3, IRM)
    p.dot(15, 3, IRL)
    p.line(18, 5, 20, 4, IRL)
    p.box(23, 1, 5, 5, "7aa8b8")
    p.box(23, 0, 5, 1, IRM)
    p.vline(24, 2, 4, "d8f0f0")
    p.box(25, 3, 2, 2, "5a7a3a")
    out["shed_workbench"] = p

    p = Pixels(16, 32)
    lx = lambda y: 2 + (31 - y) * 3 // 31
    rx = lambda y: 11 + (31 - y) * 2 // 31
    for y in range(0, 31):
        p.dot(lx(y), y, WL)
        p.dot(lx(y) + 1, y, WD)
        p.dot(rx(y), y, WL)
        p.dot(rx(y) + 1, y, WD)
    for y in (3, 8, 13, 18, 23, 28):
        p.hline(lx(y) + 2, rx(y) - 1, y, WH)
        p.hline(lx(y) + 2, rx(y) - 1, y + 1, WD)
    p.hline(1, 14, 31, SHADOW)
    out["shed_ladder"] = p

    p = Pixels(16, 16)
    for x in (3, 11):
        p.vline(x, 1, 14, WL)
        p.vline(x + 1, 1, 14, WD)
    for y in (3, 6, 9, 12):
        p.hline(5, 10, y, WH)
        p.hline(5, 10, y + 1, WM)
    p.hline(2, 13, 15, SHADOW)
    out["item_ladder"] = p

    def berry(p, x, y, r=2):
        p.oval(x, y, r, r, RM)
        p.dot(x + 1, y + 1, RD)
        p.dot(x + r - 1, y + r - 1, RD) if r > 1 else None
        p.dot(x - 1, y - 1, RH)

    p = Pixels(16, 16)
    p.polygon([(6, 2), (9, 1), (10, 4), (7, 5)], LM)
    p.line(7, 3, 9, 2, LL)
    p.polygon([(9, 4), (13, 3), (12, 6)], LD)
    p.line(8, 5, 8, 7, "5a4020")
    berry(p, 6, 9)
    berry(p, 10, 8)
    berry(p, 8, 12)
    berry(p, 4, 12, 1)
    p.hline(4, 11, 15, SHADOW)
    out["item_berries"] = p

    p = Pixels(16, 16)
    p.oval(8, 9, 5, 5, RL)
    p.oval(6, 8, 2, 3, "e0a03a")
    p.dot(5, 6, "f8e0a0")
    p.dot(5, 7, "f8d070")
    p.hline(5, 11, 13, RD)
    p.hline(4, 12, 12, RM)
    p.dot(12, 10, RM)
    p.dot(7, 4, RD)
    p.dot(9, 4, RD)
    p.vline(8, 2, 4, "5a3a1c")
    p.polygon([(9, 2), (12, 1), (13, 2), (10, 4)], LM)
    p.dot(11, 2, LL)
    p.hline(5, 11, 15, SHADOW)
    out["item_apples"] = p

    p = Pixels(16, 16)
    for x, y in ((5, 6), (9, 5), (7, 9), (11, 9), (4, 10), (9, 12)):
        p.box(x, y, 2, 2, RM)
        p.dot(x + 1, y + 1, RD)
        p.dot(x, y, RH)
    p.dot(8, 4, LL)
    p.dot(10, 4, LM)
    out["berry_cluster"] = p

    p = Pixels(16, 16)
    p.polygon([(3, 3), (7, 2), (8, 5), (4, 6)], LM)
    p.polygon([(9, 2), (13, 3), (12, 6), (9, 5)], LD)
    p.dot(5, 4, LL)
    p.dot(11, 3, LM)
    for ax, ay in ((5, 9), (11, 10)):
        p.oval(ax, ay, 3, 3, RL)
        p.hline(ax - 2, ax + 2, ay + 3, RD)
        p.dot(ax + 2, ay + 1, RM)
        p.dot(ax - 1, ay - 1, "f8d070")
        p.dot(ax - 2, ay, "e0a03a")
        p.vline(ax, ay - 4, ay - 3, "5a3a1c")
    out["apple_cluster"] = p

    outer = [(0, 31), (0, 13), (2, 7), (6, 3), (12, 0), (20, 0), (26, 3), (30, 7), (31, 13), (31, 31)]
    mouth = [(3, 31), (3, 23), (3, 16), (5, 10), (10, 7), (17, 6), (23, 8), (27, 12), (29, 18), (29, 25), (29, 31)]

    def inside(x, y):
        return y >= 13 or ((x - 15.5) / 15.0) ** 2 + ((y - 14) / 13.0) ** 2 <= 0.85

    def cave(night):
        p = Pixels(32, 32)
        p.polygon(outer, SM)
        for i in range(70):
            x, y = (i * 13 + 5) % 31, (i * 7 + 2) % 31
            if inside(x, y) and inside(x + 1, y):
                c = (SL, SD, SH, SL)[i % 4]
                p.dot(x, y, c)
                if i % 2:
                    p.dot(x + 1, y, c)
        for x0, y0, x1, y1 in ((3, 14, 7, 18), (25, 12, 29, 16), (4, 24, 8, 23), (24, 22, 28, 27), (11, 3, 15, 4)):
            p.line(x0, y0, x1, y1, SD)
        sky0, sky1 = ("1a2650", "2c4278") if night else ("5aa8ec", "a4d8f8")
        p.polygon(mouth, sky1)
        p.polygon([(5, 10), (10, 7), (17, 6), (23, 8), (27, 12), (4, 13)], sky0)
        if night:
            for x, y in ((12, 9), (18, 8), (21, 13), (14, 14), (10, 16)):
                p.dot(x, y, "e8ecff")
            p.box(19, 10, 2, 2, "d8e4ff")
            p.dot(19, 10, "a8b8e8")
        else:
            p.hline(13, 16, 11, "f4fbff")
            p.hline(12, 17, 12, "e0f2fc")
        t0, t1, t2 = ("142a20", "1e3c2c", "2c5038") if night else (LD, LM, LL)
        p.oval(16, 22, 7, 4, t1)
        p.oval(13, 20, 3, 2, t1)
        p.oval(19, 19, 3, 3, t1)
        p.dot(18, 17, t2)
        p.dot(12, 18, t2)
        p.hline(10, 22, 25, t0)
        g0, g1 = ("3c3a42", "4c4a52") if night else ("8a7a52", "a8966a")
        p.polygon([(3, 31), (3, 26), (29, 26), (29, 31)], g0)
        p.polygon([(13, 31), (14, 27), (18, 27), (19, 31)], g1)
        rim = SD if not night else "1c1f28"
        for (x0, y0), (x1, y1) in zip(mouth, mouth[1:]):
            p.line(x0, y0, x1, y1, rim)
        p.line(3, 31, 4, 24, rim)
        p.line(29, 31, 28, 24, rim)
        for x, y in ((2, 16), (4, 10), (9, 6), (17, 5), (24, 7), (28, 12), (30, 18), (30, 25)):
            p.dot(x, y, SH)
        if night:
            p.box(0, 13, 4, 19, "1c1f2844")
            p.box(28, 13, 4, 19, "1c1f2844")
        return p

    out["cave_exit_day"] = cave(False)
    out["cave_exit_night"] = cave(True)

    p = Pixels(16, 16)
    p.vline(8, 3, 11, "f0c040")
    p.hline(4, 12, 7, "f0c040")
    p.vline(8, 5, 9, "ffe890")
    p.hline(6, 10, 7, "ffe890")
    p.dot(8, 7, "fffbe0")
    p.dot(8, 2, "f0c04088")
    p.dot(8, 12, "f0c04088")
    for x, y in ((6, 5), (10, 5), (6, 9), (10, 9)):
        p.dot(x, y, "d8a03088")
    p.hline(3, 5, 13, "7ac0f0aa")
    p.hline(11, 13, 13, "7ac0f0aa")
    p.hline(6, 10, 14, "4a90d088")
    p.dot(2, 12, "7ac0f066")
    p.dot(14, 12, "7ac0f066")
    out["fish_glint"] = p

    p = Pixels(16, 16)
    p.box(1, 2, 14, 13, "513527")
    for i in range(34):
        p.dot(2 + i * 7 % 12, 3 + i * 5 % 11, "674632" if i % 3 else "38251a")
    p.hline(1, 14, 14, "24170f")
    out["crop_soil_wet"] = p
    return out
