"""Option-3 town additions: hand-authored 16px-grid pixel art.

sprites(P) -> dict[str, P]; P(w, h) supplies dot/box/line/... primitives.
Top-left warm light, purple shadows, transparent backgrounds.
"""

OL = '2a1e33'
SHADOW = '2a1e3350'

_FONT = {
    'A': ('010', '101', '111', '101', '101'),
    'B': ('110', '101', '110', '101', '110'),
    'E': ('111', '100', '110', '100', '111'),
    'G': ('011', '100', '101', '101', '011'),
    'H': ('101', '101', '111', '101', '101'),
    'I': ('111', '010', '010', '010', '111'),
    'K': ('101', '101', '110', '101', '101'),
    'L': ('100', '100', '100', '100', '111'),
    'M': ('101', '111', '111', '101', '101'),
    'N': ('110', '101', '101', '101', '101'),
    'O': ('010', '101', '101', '101', '010'),
    'R': ('110', '101', '110', '101', '101'),
    'S': ('011', '100', '010', '001', '110'),
    'T': ('111', '010', '010', '010', '010'),
}


class _G:
    """Bounds-checked drawing over P that remembers what it painted."""

    def __init__(s, P, w, h):
        s.p = P(w, h)
        s.w = w
        s.h = h
        s.px = {}

    def d(s, x, y, c):
        x = int(x)
        y = int(y)
        if 0 <= x < s.w and 0 <= y < s.h:
            s.p.dot(x, y, c)
            s.px[(x, y)] = c

    def u(s, x, y, c):
        if (int(x), int(y)) not in s.px:
            s.d(x, y, c)

    def b(s, x, y, w, h, c):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                s.d(xx, yy, c)

    def l(s, x0, y0, x1, y1, c):
        dx = abs(x1 - x0)
        dy = -abs(y1 - y0)
        sx = 1 if x0 < x1 else -1
        sy = 1 if y0 < y1 else -1
        err = dx + dy
        while True:
            s.d(x0, y0, c)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy

    def e(s, cx, cy, rx, ry, c, under=False):
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                    (s.u if under else s.d)(x, y, c)

    def arch(s, x0, y0, w, h, c):
        r = w / 2.0
        cx = x0 + (w - 1) / 2.0
        cy = y0 + r
        for y in range(y0, y0 + h):
            for x in range(x0, x0 + w):
                if y >= cy or ((x - cx) / r) ** 2 + ((y + 0.5 - cy) / r) ** 2 <= 1.0:
                    s.d(x, y, c)

    def spans(s, rows, fn):
        for y, (a, b) in rows.items():
            for x in range(a, b + 1):
                s.d(x, y, fn(x, y))

    def outline(s, c=OL):
        add = set()
        for (x, y), v in list(s.px.items()):
            if len(v) != 6:
                continue
            for q in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if q not in s.px:
                    add.add(q)
        for x, y in add:
            s.d(x, y, c)

    def text(s, msg, x, y, c):
        for ch in msg:
            if ch == ' ':
                x += 2
                continue
            for ry, row in enumerate(_FONT[ch]):
                for rx, bit in enumerate(row):
                    if bit == '1':
                        s.d(x + rx, y + ry, c)
            x += 4


def _temple(P):
    T = _G(P, 112, 112)
    # mossy slate roof, staggered courses, lit from the left
    for y in range(13, 49):
        t = (y - 12) / 37.0
        x0 = int(round(26 - 20 * t))
        x1 = int(round(85 + 20 * t))
        k = (y - 13) % 5
        off = 4 * (((y - 13) // 5) % 2)
        for x in range(x0, x1 + 1):
            c = '6e7a8e'
            if k == 4:
                c = '4a5066'
            elif k == 0:
                c = '808ca0'
            elif (x - off) % 8 == 0:
                c = '59617a'
            if x < x0 + 3 and k != 4:
                c = '8f9cb0'
            elif x > x1 - 4:
                c = '4e5470' if k != 4 else '3e445a'
            T.d(x, y, c)
    T.b(26, 11, 60, 2, '9aa6b8')
    T.b(27, 11, 58, 1, 'b4c0cc')
    T.b(6, 49, 100, 1, '3e445a')
    for cx, cy in ((30, 20), (18, 40), (40, 15), (72, 16), (84, 30), (96, 44), (28, 33), (90, 22)):
        for dx, dy in ((0, 0), (1, 0), (-1, 1), (0, 1), (1, 1), (2, 1)):
            T.d(cx + dx, cy + dy, '6f9a44')
        T.d(cx, cy, '9cc25a')
        T.d(cx + 2, cy + 1, '3f6233')
        T.d(cx - 1, cy + 1, '4f7a42')
    # sun finial on the ridge
    T.b(55, 7, 2, 4, '8a5a32')
    T.e(55.5, 5, 2.5, 2.5, 'e8b440')
    T.d(55, 4, 'fff4c0')

    # stone gable with sun motif
    for y in range(24, 50):
        h = (y - 24) * 20 // 26
        x0 = 55 - h
        x1 = 56 + h
        for x in range(x0, x1 + 1):
            c = 'd2c9b8' if x <= 55 else 'b4aa9c'
            if y % 6 == 0:
                c = '9a90a0'
            T.d(x, y, c)
        T.d(x0 - 2, y, '5a6478')
        T.d(x0 - 1, y, '3e445a')
        T.d(x1 + 1, y, '3e445a')
        T.d(x1 + 2, y, '3e445a')
    T.b(54, 22, 4, 2, '5a6478')
    for x, y in ((55, 34), (56, 34), (55, 46), (56, 46), (49, 40), (62, 40),
                 (51, 36), (60, 36), (51, 44), (60, 44)):
        T.d(x, y, 'c88a30')
    T.e(55.5, 40, 4.3, 4.3, 'b07830')
    T.e(55.5, 40, 3.6, 3.6, 'e8b440')
    T.e(55.5, 40, 2.2, 2.2, 'f8d870')
    T.d(54, 38, 'fff4c0')

    # cornice
    T.b(9, 50, 94, 1, 'ddd4c2')
    T.b(9, 51, 94, 1, '8e8494')

    # coursed stone walls
    for y in range(52, 98):
        k = (y - 52) % 6
        off = 6 if ((y - 52) // 6) % 2 else 0
        for x in range(12, 100):
            if k == 5 or (x - 12 + off) % 12 == 0:
                c = '8a8090'
            elif x < 20:
                c = 'd6ccba' if k == 0 else 'c6bcaa'
            elif x >= 90:
                c = 'aea2ac' if k == 0 else 'a094a0'
            else:
                c = 'd2c9b8' if k == 0 else 'b8ae9e'
                if (x * 7 + y * 13) % 23 == 0:
                    c = '9e94a0'
            T.d(x, y, c)
    T.b(12, 52, 88, 1, '5e5270')
    T.b(12, 53, 88, 1, '7a6f88')
    for x in range(12, 100, 2):
        T.d(x, 54, '8a7f96')

    # moon plaque over the entry
    T.e(55.5, 56, 5, 4.6, '8a8090')
    T.e(55.5, 56, 4, 3.6, '4a4a7a')
    for ry, row in enumerate(('.XXX.', 'XX...', 'X....', 'XX...', '.XXX.')):
        for rx, ch in enumerate(row):
            if ch == 'X':
                T.d(53 + rx, 54 + ry, 'f0eef8')
    T.d(58, 55, 'f8d878')

    # arched windows with warm interior glow
    for x, y in ((20, 64), (80, 64)):
        T.arch(x, y, 12, 18, OL)
        T.arch(x + 1, y + 1, 10, 17, 'ddd4c2')
        T.arch(x + 2, y + 2, 8, 15, '4a4a7a')
        T.b(x + 2, y + 9, 8, 1, 'c88a48')
        T.b(x + 2, y + 10, 8, 7, 'e8b050')
        T.b(x + 2, y + 11, 3, 2, 'f4c878')
        T.l(x + 5, y + 3, x + 5, y + 16, '5e3a26')
        T.l(x + 6, y + 3, x + 6, y + 16, '7a4a2a')
        T.l(x + 2, y + 9, x + 9, y + 9, '5e3a26')
        T.d(x + 3, y + 5, '8a8ac0')
        T.d(x + 3, y + 6, '8a8ac0')
        T.d(x + 4, y + 4, '8a8ac0')
        T.b(x - 1, y + 18, 14, 1, 'e6dece')
        T.b(x - 1, y + 19, 14, 1, 'a39aa0')
        T.l(x - 1, y + 20, x + 12, y + 20, '6a5e78')

    # centered arch entry, doors open onto a lit hall
    T.arch(42, 62, 28, 36, OL)
    T.arch(43, 63, 26, 35, 'd8cfbe')
    for (x, y), v in list(T.px.items()):
        if v == 'd8cfbe' and x >= 60:
            T.d(x, y, 'b4aa9c')
    T.arch(47, 67, 18, 31, '3a2a40')
    T.arch(50, 71, 12, 27, 'b8743a')
    T.arch(52, 73, 8, 25, 'e0a050')
    T.b(50, 94, 12, 4, 'f0c070')
    T.b(47, 77, 3, 21, '7a4a2a')
    T.b(62, 77, 3, 21, '6a3e26')
    T.l(48, 77, 48, 97, '5e3a26')
    T.l(63, 77, 63, 97, '4e2e1e')
    for y in (80, 92):
        T.d(47, y, '3a3644')
        T.d(64, y, '3a3644')
    for y in (80, 86, 92):
        T.l(43, y, 46, y, '9a90a0')
        T.l(65, y, 68, y, '857a92')
    T.l(44, 72, 47, 73, '9a90a0')
    T.l(64, 73, 67, 72, '857a92')
    T.l(47, 66, 49, 68, '9a90a0')
    T.l(62, 68, 64, 66, '857a92')
    T.b(53, 62, 6, 5, 'ece4d4')
    T.b(56, 63, 2, 3, 'd2c9b8')
    T.l(52, 62, 52, 66, OL)
    T.l(59, 62, 59, 66, OL)
    T.l(53, 67, 58, 67, OL)

    # lanterns flanking the door
    for x in (36, 71):
        T.l(x, 70, x + 4, 70, '3a3644')
        T.b(x, 71, 5, 5, '3a3644')
        T.b(x + 1, 72, 3, 3, 'f8d878')
        T.d(x + 2, 73, 'fff4c0')

    # ivy on the left corner
    for i, (x, y) in enumerate(((13, 84), (14, 86), (13, 88), (14, 90), (15, 92), (13, 94), (14, 96), (15, 95))):
        T.d(x, y, '7fa64a' if i % 2 else '4f7a42')

    # integrated foundation and steps
    for y in range(98, 108):
        for x in range(8, 104):
            if y == 98:
                c = 'c6bcaa'
            elif y >= 106:
                c = '6a5e78'
            elif y == 102:
                c = '7a6f88'
            elif (x + (5 if y > 102 else 0)) % 10 == 0:
                c = '7a6f88'
            else:
                c = '8e8494' if x < 92 else '7e7290'
            T.d(x, y, c)
    T.b(40, 98, 32, 1, 'ece4d4')
    T.b(40, 99, 32, 2, 'b8ae9e')
    T.b(40, 101, 32, 1, '8e8494')
    T.b(50, 98, 12, 1, 'f8e0a8')
    T.b(36, 102, 40, 1, 'ddd4c2')
    T.b(36, 103, 40, 4, 'b0a696')
    T.b(36, 107, 40, 1, '7a6f88')
    T.b(68, 99, 4, 2, '9e94a0')
    T.b(70, 103, 6, 4, '958a9a')
    T.l(39, 98, 39, 101, OL)
    T.l(72, 98, 72, 101, OL)
    T.l(35, 102, 35, 107, OL)
    T.l(76, 102, 76, 107, OL)

    # shrubs with blossoms
    for cx, flower in ((14, 'f0a0c0'), (97, 'f8e080')):
        T.e(cx, 103, 7, 5, '4f7a42')
        T.e(cx - 1, 101, 5, 3, '6f9a44')
        T.d(cx - 3, 99, '9cc25a')
        T.d(cx - 2, 100, '9cc25a')
        T.d(cx - 4, 101, '9cc25a')
        T.l(cx - 4, 107, cx + 5, 107, '35552e')
        T.d(cx + 5, 104, '35552e')
        T.d(cx + 4, 105, '35552e')
        for dx, dy in ((2, -2), (-4, 2), (4, 1), (-1, 4)):
            T.d(cx + dx, 103 + dy, flower)

    T.outline(OL)
    for x in range(8, 104):
        T.u(x, 109, SHADOW)
        T.u(x, 110, '2a1e3330')
    return T.p


def _priest(P):
    A = _G(P, 16, 32)
    HR, HH = '2a1c18', '4a3428'
    SK, SL, SS = '8a5634', 'a86c44', '5e3824'
    IV, IVL, IVS, IVP = 'ece3c8', 'fff8e8', 'cbbfa2', 'a495a8'
    GR, GRL, GRD = '4f7a42', '6f9a54', '35552e'
    # head and short hair
    A.b(5, 3, 6, 1, HR)
    A.b(4, 4, 8, 2, HR)
    A.d(5, 4, HH)
    A.d(6, 4, HH)
    A.d(5, 5, HH)
    A.b(4, 6, 8, 6, SK)
    A.b(4, 6, 2, 1, HR)
    A.b(10, 6, 2, 1, HR)
    A.d(4, 7, '6a605a')
    A.d(11, 7, '6a605a')
    A.b(5, 12, 6, 1, SK)
    A.d(5, 7, SL)
    A.d(6, 7, SL)
    A.d(5, 8, SL)
    A.b(11, 8, 1, 4, SS)
    A.d(10, 11, SS)
    A.b(9, 12, 2, 1, SS)
    A.d(6, 8, '3a2418')
    A.d(9, 8, '3a2418')
    A.d(6, 9, '1a1014')
    A.d(9, 9, '1a1014')
    A.d(8, 10, SS)
    A.d(7, 11, '6e3a26')
    A.d(8, 11, '6e3a26')
    A.b(6, 13, 4, 1, SS)
    # robe
    A.b(4, 14, 8, 8, IV)
    A.b(3, 22, 10, 8, IV)
    A.b(3, 15, 1, 6, IV)
    A.b(12, 15, 1, 6, IVS)
    A.b(4, 15, 1, 6, IVL)
    A.b(3, 23, 1, 6, IVL)
    A.b(11, 14, 1, 8, IVS)
    A.b(11, 22, 1, 7, IVS)
    A.b(12, 22, 1, 7, IVP)
    A.d(3, 21, SK)
    A.d(12, 21, SS)
    A.b(6, 14, 4, 1, GRD)
    A.b(5, 15, 1, 13, GR)
    A.b(10, 15, 1, 13, GRD)
    A.d(5, 15, GRL)
    A.b(4, 21, 8, 1, GRD)
    A.d(7, 22, GR)
    A.d(7, 23, GRD)
    A.l(7, 24, 7, 28, IVS)
    A.l(9, 24, 9, 28, IVS)
    # copper sun pendant
    A.d(6, 15, 'a85a2a')
    A.d(9, 15, 'a85a2a')
    A.d(7, 16, 'a85a2a')
    A.d(8, 16, 'a85a2a')
    A.b(7, 17, 2, 2, 'c8743a')
    A.d(7, 17, 'f0a860')
    A.d(8, 18, '8a4a22')
    A.b(3, 29, 10, 1, GR)
    A.d(12, 29, GRD)
    A.b(5, 30, 2, 1, '5e3a26')
    A.b(9, 30, 2, 1, '5e3a26')
    A.outline(OL)
    for x in range(4, 12):
        A.u(x, 31, SHADOW)
    return A.p


def _beehive(P):
    B = _G(P, 16, 24)
    for y in range(2, 17):
        for x in range(16):
            dx = (x - 7.5) / 6.8
            dy = (y - 11.5) / 10.5
            if dx * dx + dy * dy > 1:
                continue
            k = y % 3
            c = 'a8742e' if k == 0 else ('ecc470' if k == 1 and x < 8 else 'd8a650')
            if x >= 13:
                c = '7a5a5a' if k == 0 else '9a7058'
            elif x >= 11:
                c = {'a8742e': '8a5a3a', 'ecc470': 'c8903e', 'd8a650': 'c08c40'}[c]
            B.d(x, y, c)
    B.b(7, 1, 2, 1, 'a8742e')
    B.d(7, 1, 'c8903e')
    B.d(5, 4, 'f8dc90')
    B.d(4, 7, 'f8dc90')
    B.b(7, 13, 2, 1, '2a1a1a')
    B.b(6, 14, 4, 3, '2a1a1a')
    B.d(9, 16, '4a2a2a')
    B.b(1, 17, 14, 1, 'c98f52')
    B.b(1, 18, 14, 1, '8a5a32')
    B.d(14, 17, '8a5a32')
    B.b(2, 19, 2, 4, '8a5a32')
    B.b(3, 19, 1, 4, '6e4426')
    B.b(12, 19, 2, 4, '8a5a32')
    B.b(13, 19, 1, 4, '5e3a4a')
    B.outline(OL)
    for x in range(1, 15):
        B.u(x, 23, SHADOW)
    return B.p


def _bee(P, wings):
    g = _G(P, 8, 8)
    g.d(2, 4, '2a2228')
    g.d(2, 5, '2a2228')
    g.d(3, 4, 'ffd860')
    g.d(4, 4, '2a2228')
    g.d(5, 4, 'f0b030')
    g.d(6, 4, 'c88420')
    g.d(3, 5, 'f0b030')
    g.d(4, 5, '2a2228')
    g.d(5, 5, 'd89a28')
    g.outline('1a1218')
    for x, y in wings:
        g.d(x, y, 'e4f2ffd0')
    return g.p


def _fishing_pole(P):
    F = _G(P, 16, 16)
    F.l(4, 11, 14, 1, 'a8713e')
    for x, y in ((6, 9), (8, 7), (10, 5), (12, 3)):
        F.d(x, y, 'c98f52')
    F.l(1, 14, 4, 11, 'c89a60')
    F.d(1, 14, '5e3a26')
    F.d(3, 12, '8a5a32')
    F.b(5, 12, 2, 2, '9a96a8')
    F.d(5, 12, 'd8d4e4')
    F.d(6, 13, '5a5668')
    F.outline(OL)
    F.l(15, 2, 15, 9, 'dcd8ec')
    F.d(15, 6, 'f4f0f0')
    F.d(15, 7, 'd04030')
    F.d(14, 7, 'a02820')
    for x, y in ((15, 10), (15, 11), (14, 11), (13, 10)):
        F.d(x, y, 'b8b8c8')
    return F.p


def _coal(P):
    C = _G(P, 16, 16)
    rows = {4: (6, 9), 5: (4, 11), 6: (3, 12), 7: (3, 12), 8: (2, 13),
            9: (2, 13), 10: (3, 13), 11: (3, 12), 12: (4, 11), 13: (6, 9)}

    def shade(x, y):
        if x + y < 14:
            return '54506a'
        if x + y > 20:
            return '2a2632'
        return '3a3644'
    C.spans(rows, shade)
    C.l(5, 5, 8, 5, '7a7894')
    C.l(3, 7, 3, 9, '6a6884')
    C.l(8, 6, 10, 10, '1e1a24')
    C.l(4, 10, 7, 12, '1e1a24')
    C.d(9, 6, '6a6884')
    C.d(5, 6, 'c8c8e0')
    C.d(9, 8, '9a9ab8')
    C.d(6, 10, '8a88a4')
    C.outline('141018')
    for x in range(4, 12):
        C.u(x, 15, SHADOW)
    return C.p


def _cave_coal(P):
    K = _G(P, 16, 16)
    rows = {3: (5, 10), 4: (3, 12), 5: (2, 13), 14: (2, 13)}
    for y in range(6, 14):
        rows[y] = (1, 14)

    def rock(x, y):
        if y == 14:
            return '5a4e66'
        if x + y < 12:
            return 'b0a696'
        if x + y > 22:
            return '6a5e78'
        return '8e8494'
    K.spans(rows, rock)
    K.l(2, 11, 4, 13, '6a5e78')
    K.l(11, 4, 13, 6, 'a39aa0')
    K.l(3, 8, 8, 6, '1e1a24')
    K.l(3, 9, 8, 7, '2a2632')
    K.l(8, 11, 12, 9, '1e1a24')
    K.l(8, 12, 12, 10, '2a2632')
    K.b(10, 4, 2, 2, '1e1a24')
    K.b(4, 12, 2, 1, '1e1a24')
    K.d(4, 8, '9a9ab8')
    K.d(6, 7, 'e8e8ff')
    K.d(10, 10, 'e8e8ff')
    K.d(11, 9, '9a9ab8')
    K.d(10, 4, 'c8c8e0')
    K.outline(OL)
    return K.p


def _stairs(P, up):
    S = _G(P, 16, 16)
    S.b(0, 0, 16, 16, '7a6f88')
    S.b(0, 0, 16, 2, 'a89e8e')
    S.b(0, 0, 2, 16, '9a90a0')
    S.b(14, 0, 2, 16, '5a4e66')
    S.d(0, 0, 'b8ae9e')
    S.d(1, 0, 'c6bcaa')
    S.b(2, 2, 12, 14, '4a3e58')
    if up:
        S.b(2, 2, 12, 3, 'f2d890')
        S.b(5, 2, 6, 2, 'fff4c8')
        steps = ((5, 5, 'f0dca8', 'b09a80'), (8, 4, 'ddd0b4', '978c92'),
                 (11, 3, 'c8bea8', '857a8e'), (14, 2, 'b8ae9e', '7a6f88'))
        for y, x0, tread, riser in steps:
            S.b(x0, y, 16 - 2 * x0, 1, tread)
            S.b(x0, y + 1, 16 - 2 * x0, 2, riser)
            S.d(x0, y, 'fff4dc')
    else:
        steps = ((2, 'b8ae9e', '7a6f88'), (5, '948a96', '5e5270'),
                 (8, '6e6280', '463a58'), (11, '4e4262', '2e2440'))
        for i, (y, tread, riser) in enumerate(steps):
            S.b(2 + i, y, 12 - 2 * i, 2, tread)
            S.b(2 + i, y + 2, 12 - 2 * i, 1, riser)
            S.d(2 + i, y, 'd2c9b8' if i < 2 else '857a92')
        S.b(2, 14, 12, 2, '1a1224')
        S.b(6, 14, 4, 1, '2a1e33')
    return S.p


def _hearthmend(P):
    H = _G(P, 16, 16)
    left = {9: (2, 4), 10: (2, 6), 11: (3, 7), 12: (4, 7), 13: (5, 7)}
    right = {9: (11, 13), 10: (9, 13), 11: (8, 12), 12: (8, 11), 13: (8, 10)}
    tone = {9: 'f8d878', 10: 'e8b048', 11: 'e8b048', 12: 'b07830', 13: 'c88a3a'}
    H.spans(left, lambda x, y: tone[y])
    H.spans(right, lambda x, y: 'd09838' if y in (10, 11) else tone[y])
    H.d(3, 10, 'f8d878')
    H.d(12, 12, '8a5a2a')
    H.outline('6a3a1e')
    H.e(7.5, 5.5, 3.2, 3.2, 'f8d878')
    H.e(7.5, 5.5, 2, 2, 'fff4c0')
    H.d(7, 5, 'ffffff')
    H.d(8, 5, 'ffffff')
    H.e(7.5, 5.5, 4.8, 4.8, 'f8d87870', under=True)
    for x, y, c in ((2, 2, 'fff4c0'), (13, 3, 'fff4c0'), (12, 0, 'f8d878'),
                    (1, 6, 'f8d878'), (14, 7, 'f8d878'), (7, 0, 'fff0a080')):
        H.d(x, y, c)
    return H.p


def _emberthread(P):
    E = _G(P, 16, 16)
    path = ((2, 14), (3, 13), (4, 12), (5, 12), (6, 11), (7, 10), (8, 9), (9, 9),
            (10, 8), (11, 7), (12, 6), (12, 5), (12, 4), (11, 3), (10, 2), (9, 2),
            (8, 3), (7, 4), (7, 5), (8, 6), (9, 6), (10, 5))
    for x, y in path[:9]:
        E.d(x, y + 1, 'a82818')
    for x, y in path:
        E.d(x, y, 'f08a28')
    for x, y in ((2, 14), (3, 13), (9, 6), (10, 5), (11, 3)):
        E.d(x, y, 'd8481e')
    for x, y in ((5, 12), (8, 9), (12, 5), (10, 2)):
        E.d(x, y, 'ffd860')
    E.outline('4a1414')
    E.d(9, 4, 'c8381e')
    E.d(14, 9, 'ffb040')
    E.d(13, 12, 'f08a28')
    E.d(4, 8, 'ffd860')
    E.d(1, 10, 'f08a2880')
    return E.p


def _sign_general_store(P):
    G = _G(P, 56, 12)
    G.b(1, 1, 54, 10, 'c48a50')
    G.b(1, 1, 54, 1, 'e0ad6e')
    G.b(1, 10, 54, 1, '8a5a32')
    G.b(54, 2, 1, 8, 'a06a3e')
    for x0, x1, y in ((4, 14, 3), (20, 34, 9), (38, 50, 3), (8, 18, 9)):
        G.l(x0, y, x1, y, 'b67e48')
    for x, y in ((3, 2), (52, 2), (3, 9), (52, 9)):
        G.d(x, y, '5a4e66')
    G.text('GENERAL STORE', 3, 5, 'f0c890')
    G.text('GENERAL STORE', 3, 4, '3a2418')
    G.outline(OL)
    return G.p


def _sign_smith(P):
    S = _G(P, 32, 16)
    for x in (7, 24):
        for y in range(3):
            S.d(x, y, '8a8698' if y % 2 == 0 else '5a5668')
    S.b(2, 3, 28, 12, '3a3644')
    S.b(2, 3, 28, 1, '5a5668')
    S.b(2, 3, 1, 12, '4e4a5c')
    S.b(2, 14, 28, 1, '26222e')
    S.b(29, 4, 1, 10, '2e2a38')
    for x, y in ((3, 4), (28, 4), (3, 13), (28, 13)):
        S.d(x, y, 'a8a4b8')
    S.text('SMITH', 6, 6, '1e1a24')
    S.text('SMITH', 6, 5, 'd8d2c8')
    S.b(11, 11, 9, 1, '9a96a8')
    S.b(12, 11, 4, 1, 'c8c4d4')
    S.b(14, 12, 4, 1, '6e6a80')
    S.b(13, 13, 6, 1, '6e6a80')
    S.outline(OL)
    return S.p


def _sign_baker(P):
    K = _G(P, 32, 16)
    for x in (7, 24):
        K.d(x, 0, '8a5a32')
        K.d(x, 1, '6e4426')
    K.b(1, 2, 30, 13, 'efe0c0')
    K.b(1, 2, 30, 1, 'b07a48')
    K.b(1, 14, 30, 1, '8a5a32')
    K.b(1, 2, 1, 13, 'c48a50')
    K.b(30, 2, 1, 13, '8a5a32')
    K.b(2, 3, 28, 1, 'fff4dc')
    K.b(29, 4, 1, 10, 'd8c6a8')
    for sx in (3, 28):
        K.l(sx, 6, sx, 12, 'a87a30')
        for x, y in ((sx, 4), (sx - 1, 5), (sx + 1, 5), (sx - 1, 7), (sx + 1, 7), (sx - 1, 9), (sx + 1, 9)):
            K.d(x, y, 'd8a838')
        K.d(sx - 1, 5, 'f0c858')
        K.d(sx + 1, 11, '7a9a4a')
    K.text('BAKER', 6, 5, '8a3a22')
    for x in range(8, 24, 2):
        K.d(x, 11, 'c8a060')
    K.outline(OL)
    return K.p


def sprites(P):
    return {
        'building_temple': _temple(P),
        'actor_priest_down0': _priest(P),
        'beehive': _beehive(P),
        'bee0': _bee(P, ((3, 2), (4, 2), (4, 1), (5, 1))),
        'bee1': _bee(P, ((4, 3), (5, 3), (5, 2), (6, 2))),
        'item_fishing_pole': _fishing_pole(P),
        'item_coal': _coal(P),
        'cave_coal': _cave_coal(P),
        'cave_stairs_down': _stairs(P, False),
        'cave_stairs_up': _stairs(P, True),
        'item_hearthmend': _hearthmend(P),
        'item_emberthread': _emberthread(P),
        'sign_general_store': _sign_general_store(P),
        'sign_smith': _sign_smith(P),
        'sign_baker': _sign_baker(P),
    }
