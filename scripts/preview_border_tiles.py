"""Lay supplied border tiles into corner/junction review maps; no pixels are authored here."""
import argparse
import importlib.util
from pathlib import Path
import sys

from make_sprites16 import Pixels

NEIGHBORS = ((0, -1, 1), (1, 0, 2), (0, 1, 4), (-1, 0, 8),
             (1, -1, 16), (1, 1, 32), (-1, 1, 64), (-1, -1, 128))


def review_cells():
    cells = set()
    for y in range(1, 8):
        for x in range(1, 9):
            if not (3 <= x <= 6 and 3 <= y <= 5):
                cells.add((x, y))
    for y in range(2, 7):
        for x in range(11, 16):
            if x == 13 or y == 4:
                cells.add((x, y))
    for y in range(1, 8):
        for x in range(18, 24):
            if x in (18, 19, 22, 23) or y >= 6:
                cells.add((x, y))
    cells.update((x, 10) for x in range(1, 8))
    cells.update((10, y) for y in range(9, 14))
    cells.update((x, y) for y in (10, 11) for x in (13, 14))
    cells.update(((17, 10), (20, 10), (21, 11), (23, 13)))
    return cells


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path(__file__).resolve().parents[1] / "internal/claude-borders/previews")
    parser.add_argument("--source", type=Path, default=Path(__file__).with_name("terrain_edges16.py"))
    parser.add_argument("--materials", nargs="+")
    args = parser.parse_args()
    source = args.source
    if not source.exists():
        parser.error("the requested terrain artwork source does not exist")
    spec = importlib.util.spec_from_file_location("border_tiles16", source)
    art = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = art
    spec.loader.exec_module(art)
    args.output.mkdir(parents=True, exist_ok=True)
    cells = review_cells()
    for material in (args.materials or art.MATERIALS):
        for season in ("spring", "summer", "autumn", "winter"):
            for weather in ("sunny", "partly_cloudy", "rainy"):
                image = Pixels(26 * 16 * 2, 15 * 16 * 2)
                for x, y in sorted(cells):
                    mask = sum(bit for dx, dy, bit in NEIGHBORS if (x + dx, y + dy) in cells)
                    tile = art.tile(Pixels, material, mask, season, weather, (x * 7 + y * 3) % 4)
                    for py in range(16):
                        for px in range(16):
                            image.box((x * 16 + px) * 2, (y * 16 + py) * 2, 2, 2, tile.get(px, py))
                target = args.output / f"{material}-{season}-{weather}-connections.png"
                image.png(target)
                print(target)


if __name__ == "__main__":
    main()
