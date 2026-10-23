"""Hand-painted 16-pixel-grid observatory instruments and domestic lamps.

Imported by both atlas builders; no external packages or model calls.
"""
import math


def sprites(Pixels):
    result = {}
    silhouettes = {
        "head": [(4, 3, 8, 3), (3, 6, 10, 5), (3, 11, 3, 2), (10, 11, 3, 2)],
        "chest": [(3, 3, 4, 3), (9, 3, 4, 3), (4, 5, 8, 8), (6, 3, 4, 10)],
        "arms": [(2, 4, 4, 8), (10, 4, 4, 8), (3, 3, 2, 10), (11, 3, 2, 10)],
        "hands": [(5, 3, 2, 9), (8, 2, 2, 10), (11, 4, 2, 8), (3, 7, 10, 6)],
        "legs": [(4, 2, 8, 4), (4, 6, 3, 8), (9, 6, 3, 8)],
        "feet": [(3, 3, 4, 8), (9, 3, 4, 8), (2, 10, 5, 3), (9, 10, 5, 3)]}
    for name, boxes in silhouettes.items():
        icon = Pixels(16, 16)
        for x, y, w, h in boxes: icon.box(x, y, w, h, "667b72")
        for y in range(16):
            for x in range(16):
                if icon.get(x, y)[3] and (y == 0 or not icon.get(x, y - 1)[3]): icon.dot(x, y, "a2afa0")
        result["equipment_" + name] = icon
    ring = Pixels(16, 16)
    ring.oval(8, 9, 5, 5, "8d9d8f")
    ring.oval(8, 9, 3, 3, "293f38")
    ring.polygon([(8, 1), (11, 4), (8, 7), (5, 4)], "b2b9a3")
    result["equipment_left_ring"] = ring
    result["equipment_right_ring"] = ring
    necklace = Pixels(16, 16)
    for x, y in [(3, 3), (3, 6), (4, 9), (12, 3), (12, 6), (11, 9)]: necklace.box(x, y, 1, 2, "9aa995")
    necklace.polygon([(8, 9), (11, 12), (8, 15), (5, 12)], "8d9d8f")
    necklace.dot(8, 11, "c0c7ac")
    result["equipment_necklace"] = necklace
    sign = Pixels(96, 16)
    sign.box(0, 0, 96, 16, "302d30")
    sign.box(1, 1, 94, 14, "a27b45")
    sign.box(2, 2, 92, 12, "34483d")
    sign.hline(2, 93, 2, "d9b778")
    from calendar_sprites16 import font_glyphs
    glyphs = font_glyphs()
    text = "GENERAL STORE"
    x = (96 - sum(glyphs[ord(ch)][0] + 1 for ch in text)) // 2
    for ch in text:
        width, rows = glyphs[ord(ch)]
        for y, row in enumerate(rows):
            for dx, cell in enumerate(row):
                if cell == "#": sign.dot(x + dx, y + 3, "f2d699")
        x += width + 1
    for x in [4, 90]: sign.dot(x, 8, "d2ae6f")
    result["general_store_sign"] = sign
    lamp = Pixels(20, 28)
    lamp.oval(10, 25, 6, 2, "302c38")
    lamp.oval(10, 24, 5, 2, "84613d")
    lamp.hline(7, 12, 23, "d6ad65")
    lamp.box(9, 9, 3, 15, "594632")
    lamp.vline(10, 10, 22, "deb970")
    lamp.polygon([(5, 2), (14, 2), (18, 11), (1, 11)], "413037")
    lamp.polygon([(6, 3), (13, 3), (16, 9), (3, 9)], "c1a17a")
    lamp.polygon([(7, 3), (9, 3), (8, 9), (4, 9)], "edcf97")
    lamp.hline(2, 17, 10, "805f42")
    lamp.vline(14, 10, 14, "ba8b4b")
    lamp.dot(14, 15, "ebc779")
    result["furniture_floor_lamp_1x1"] = lamp

    p = Pixels(68, 60)
    # A low timber observing platform with boards and recessed brass screws.
    p.polygon([(10, 48), (45, 45), (59, 52), (25, 58), (8, 53)], "302831")
    p.polygon([(10, 47), (45, 44), (59, 50), (24, 55), (8, 51)], "775039")
    for y in range(47, 54, 2):
        p.line(14, y, 49, y - 3, "a4784f")
    for x, y in [(13, 49), (43, 46), (52, 50), (25, 53)]:
        p.dot(x, y, "dfbf7b")
        p.dot(x + 1, y + 1, "422b27")
    # Splayed iron feet carry a warm brass equatorial mount.
    for x, y in [(17, 50), (45, 49), (34, 44)]:
        p.polygon([(29, 30), (33, 30), (x + 2, y), (x - 2, y)], "27323b")
        p.line(31, 33, x, y - 1, "6d8288")
    p.box(28, 27, 7, 15, "4d3a32")
    p.box(29, 28, 4, 13, "a87742")
    p.vline(30, 29, 39, "e1bd78")
    p.oval(31, 29, 9, 8, "26313a")
    p.oval(31, 28, 8, 7, "9a713f")
    p.oval(31, 28, 6, 5, "d1a660")
    p.oval(31, 28, 4, 3, "554238")
    for angle in range(0, 360, 30):
        a = math.radians(angle)
        p.dot(31 + round(math.cos(a) * 7), 28 + round(math.sin(a) * 6), "f0d498")
    p.line(31, 28, 42, 35, "41464b")
    p.oval(43, 36, 4, 4, "27313a")
    p.oval(43, 35, 3, 3, "ad854a")
    p.line(40, 35, 46, 35, "efcc80")
    p.vline(43, 32, 38, "efcc80")
    # Main optical tube: shaded brass planes, retaining bands and a deep blue lens.
    p.polygon([(11, 28), (49, 5), (60, 19), (22, 39)], "292b34")
    p.polygon([(13, 27), (49, 7), (57, 18), (22, 36)], "805331")
    p.polygon([(14, 27), (49, 8), (52, 12), (18, 32)], "ebc77d")
    p.polygon([(18, 32), (52, 12), (55, 16), (21, 35)], "ba8a48")
    p.line(15, 27, 49, 8, "fff0b2")
    p.line(23, 36, 56, 18, "4a3330")
    for x, y in [(23, 22), (39, 13)]:
        p.polygon([(x, y), (x + 3, y - 2), (x + 11, y + 10), (x + 8, y + 12)], "3d4247")
        p.line(x + 1, y, x + 9, y + 10, "d2ba80")
        p.dot(x + 4, y + 3, "fff0b2")
    p.oval(53, 12, 7, 9, "37343c")
    p.oval(53, 11, 6, 8, "d2a967")
    p.oval(53, 11, 4, 6, "142e43")
    p.oval(53, 10, 3, 5, "245b71")
    p.line(52, 7, 54, 11, "a1d7df")
    p.dot(51, 6, "edf4e5")
    p.line(15, 32, 8, 37, "c6a268")
    p.oval(8, 37, 3, 2, "28313c")
    # Finder scope, adjustment screws, counterweight and the astronomer's notebook.
    p.line(29, 17, 39, 11, "3c4048")
    p.line(29, 16, 39, 10, "c5b38a")
    p.box(28, 18, 2, 4, "9c7448")
    p.box(38, 12, 2, 3, "9c7448")
    p.line(27, 31, 19, 40, "6c7780")
    p.oval(18, 41, 4, 3, "30343f")
    p.hline(15, 20, 40, "77878d")
    p.polygon([(44, 44), (52, 43), (57, 47), (48, 49)], "d6c49a")
    p.line(49, 44, 52, 47, "79644d")
    for x, y in [(47, 45), (51, 45), (53, 46)]: p.dot(x, y, "5f7180")
    result["furniture_great_telescope_4x3"] = p
    pendulum = Pixels(16, 32)
    pendulum.box(7, 0, 2, 24, "654831")
    pendulum.vline(7, 1, 24, "ddbd76")
    pendulum.oval(8, 25, 6, 6, "493a37")
    pendulum.oval(8, 24, 5, 5, "c59143")
    pendulum.oval(7, 23, 3, 3, "efcf80")
    pendulum.dot(6, 21, "fff2b5")
    result["clock_pendulum"] = pendulum
    warm = Pixels(16, 16)
    warm.box(4, 4, 8, 8, "f2b95f")
    warm.box(5, 5, 3, 6, "ffde94")
    warm.vline(8, 4, 11, "775136")
    warm.hline(4, 11, 8, "775136")
    result["window_warm"] = warm
    halo = Pixels(64, 32)
    for y in range(32):
        for x in range(64):
            radius = ((x - 31.5) / 31.5) ** 2 + ((y - 15.5) / 15.5) ** 2
            if radius < 1:
                halo.dot(x, y, (255, 211, 115, int(46 * (1 - radius) ** 2)))
    result["lamp_halo"] = halo
    for frame in range(4):
        smoke = Pixels(16, 16)
        for y in range(16):
            for x in range(16):
                radius = ((x - 7) / (4 + frame * .5)) ** 2 + ((y - 8) / (5 + frame * .4)) ** 2
                if radius < 1 and (x * 7 + y * 13 + frame) % 9 != 0:
                    smoke.dot(x, y, (175 + y * 2, 180 + y * 2, 183 + y * 2, int(115 * (1 - radius))))
        result[f"chimney_smoke{frame}"] = smoke
    dome = Pixels(96, 112)
    dome.box(5, 65, 86, 45, "343943")
    for y in range(66, 109, 6):
        for x in range(6 - (y // 6 % 2) * 7, 90, 14):
            dome.box(x + 1, y, 12, 5, ("85847e", "77777b", "96938a")[(x + y) % 3])
            dome.hline(x + 2, x + 11, y, "b5ad99")
    dome.box(2, 103, 92, 8, "52565d")
    dome.hline(3, 92, 103, "a5a49a")
    for y in range(10, 76):
        for x in range(4, 92):
            radius = ((x - 48) / 44) ** 2 + ((y - 53) / 43) ** 2
            if radius > 1 or y > 73:
                continue
            shade = max(0, min(4, int((x - 4) / 22 + (y - 10) / 60)))
            dome.dot(x, y, ["a6b5a8", "819e98", "5f8289", "456775", "314d60"][shade])
            if (x * 7 + y * 11) % 53 == 0:
                dome.dot(x, y, "95aba2")
    for x in [17, 32, 49, 67, 80]:
        for y in range(15, 74):
            if dome.get(x, y)[3]:
                dome.dot(x, y, "344a58")
                dome.dot(x + 1, y, "9da895")
    dome.polygon([(43, 10), (55, 11), (66, 71), (49, 72)], "243340")
    dome.polygon([(46, 14), (52, 15), (61, 68), (52, 68)], "0f202d")
    for x, y in [(49, 23), (53, 39), (57, 58)]:
        dome.dot(x, y, "a8d6df")
    dome.box(2, 72, 92, 5, "344951")
    dome.hline(4, 91, 72, "b1b7a1")
    dome.hline(3, 92, 76, "233a45")
    dome.box(44, 85, 19, 26, "393235")
    dome.box(46, 86, 15, 24, "765337")
    for x in [49, 54, 59]: dome.vline(x, 87, 108, "4d3c32")
    dome.box(47, 87, 13, 2, "b99861")
    dome.dot(58, 99, "efce80")
    for x in [17, 73]:
        dome.box(x, 84, 10, 13, "30333e")
        dome.box(x + 1, 85, 8, 10, "739696")
        dome.box(x + 2, 85, 2, 9, "a1c0b2")
        dome.vline(x + 5, 85, 95, "3e4d56")
        dome.box(x - 2, 97, 14, 2, "b3a790")
    result["observatory_exterior"] = dome
    from town_sprites16 import actor
    spec = ("586b9b", "d0cdc4", "b3927d", "373e50", "d6bf82", ("beard", "coat"))
    for direction in ("down", "up", "left", "right"):
        for frame in range(3):
            result[f"actor_astronomer_{direction}{frame}"] = actor(Pixels, "astronomer", spec, direction, frame)
    result["actor_astronomer_sleep0"] = actor(Pixels, "astronomer", spec, "sleep", 0)
    return result
