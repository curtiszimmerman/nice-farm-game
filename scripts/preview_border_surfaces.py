"""Arrange existing source tiles in seasonal/weather contact sheets without editing pixels."""
import argparse
import importlib.util
from pathlib import Path
import sys

from make_sprites16 import Pixels


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path(__file__).resolve().parents[1] / "internal/claude-borders/previews")
    parser.add_argument("--source", type=Path, default=Path(__file__).with_name("border_surfaces16.py"))
    args = parser.parse_args()
    source = args.source
    if not source.exists():
        parser.error("border_surfaces16.py has not been created yet")
    spec = importlib.util.spec_from_file_location("border_surfaces16", source)
    art = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = art
    spec.loader.exec_module(art)
    args.output.mkdir(parents=True, exist_ok=True)
    for material in ("paving", "jetty"):
        sheet = Pixels(272 * 3, 204 * 3)
        for row, weather in enumerate(("sunny", "partly_cloudy", "rainy")):
            for col, season in enumerate(("spring", "summer", "autumn", "winter")):
                for ty in range(4):
                    for tx in range(4):
                        tile = art.surface(Pixels, material, season, weather, (tx + ty * 3) % 4)
                        for y in range(16):
                            for x in range(16):
                                sheet.box((col * 68 + tx * 16 + x) * 3, (row * 68 + ty * 16 + y) * 3, 3, 3, tile.get(x, y))
        path = args.output / f"{material}-surfaces.png"
        sheet.png(path)
        print(path)
    (args.output / "legend.txt").write_text("Columns: spring, summer, autumn, winter. Rows: sunny, partly cloudy, rainy. Each panel joins four variants in a 4x4 sample. Nearest-neighbor enlargement: 3x.\n")


if __name__ == "__main__":
    main()
