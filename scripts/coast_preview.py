#!/usr/bin/env python3
"""Preview the west beach as the game draws it: baked ground plus each frame of the surf animation.

When to use: after changing beach sand, ocean edge or shore_wash art. It runs the game headless
(scripts/coast_dump.gd) to bake the real coast for a season and weather, crops the beach, and lays
the surf frames from the rustic16 atlas over it. Output goes to internal/verification/coast/.

  python3 scripts/coast_preview.py                       spring, sunny
  python3 scripts/coast_preview.py --season winter --weather rainy
  python3 scripts/coast_preview.py --rows 54,66           which map rows to show

Writes <season>_<weather>.png (the ground) and <season>_<weather>_surf.png (all eight surf frames
side by side). Regenerate art first with scripts/make_sprites16.py and reimport with
`bash scripts/play.sh --headless --import`, or Godot serves stale tiles.
"""
import argparse
import json
import math
import pathlib
import subprocess
import sys

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[1]
MIN_X = -28
FRAMES = 8


def shoreline(row, seed):
    # Mirrors Coast.shoreline in src/native/coast.gd.
    return math.floor(-5 + math.sin(row * 0.08 + seed * 0.001) * 2 + math.sin(row * 0.23 + seed * 0.003))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--season", default="spring", choices=["spring", "summer", "autumn", "winter"])
    parser.add_argument("--weather", default="sunny", choices=["sunny", "partly_cloudy", "rainy"])
    parser.add_argument("--rows", default="54,66", help="First and last map row to show.")
    parser.add_argument("--seed", type=int, default=None, help="World seed the dump used; read from the log if omitted.")
    args = parser.parse_args()
    out = ROOT / "internal/verification/coast"
    out.mkdir(parents=True, exist_ok=True)
    name = f"{args.season}_{args.weather}"
    ground_path = out / f"{name}_full.png"
    log = out / f"{name}.log"
    with log.open("w") as handle:
        result = subprocess.run(["bash", "scripts/play.sh", "--headless", "--script", "../../scripts/coast_dump.gd", "--",
                                 str(ground_path), args.season, args.weather], cwd=ROOT, stdout=handle, stderr=subprocess.STDOUT, timeout=300)
    text = log.read_text()
    if result.returncode != 0 or "SCRIPT ERROR" in text:
        sys.exit(f"Coast dump failed; see {log}")
    seed = args.seed
    for line in text.splitlines():
        if line.startswith("Saved coast") and "seed" in line:
            seed = int(line.rsplit("seed ", 1)[1].split()[0])
    if seed is None:
        sys.exit(f"No world seed in {log}; pass --seed")
    first, last = (int(v) for v in args.rows.split(","))
    ground = Image.open(ground_path).convert("RGBA")
    left = min(shoreline(r, seed) for r in range(first, last + 1)) - 3
    right = max(shoreline(r, seed) for r in range(first, last + 1)) + 5
    box = ((left - MIN_X) * 32, first * 32, (right - MIN_X) * 32, (last + 1) * 32)
    crop = ground.crop(box)
    crop.save(out / f"{name}.png")
    atlas = Image.open(ROOT / "src/native/art/option3/sprites.png").convert("RGBA")
    regions = json.loads((ROOT / "src/native/art/option3/sprites.json").read_text())
    strip = Image.new("RGBA", (crop.width * FRAMES + 8 * (FRAMES - 1), crop.height), (0, 0, 0, 0))
    for frame in range(FRAMES):
        canvas = crop.copy()
        for row in range(first, last + 1):
            # Mirrors Coast.wash_frame at elapsed=frame/(0.18*8), so row 0 shows `frame` and later rows lag behind.
            index = math.floor((frame / (0.18 * FRAMES) * 0.18 - row * 0.035) * FRAMES) % FRAMES
            x, y, w, h = regions[f"shore_wash_{index}"]["rect"]
            sprite = atlas.crop((x, y, x + w, y + h)).resize((64, 32), Image.NEAREST)
            canvas.alpha_composite(sprite, ((shoreline(row, seed) - 1 - left) * 32, (row - first) * 32))
        strip.paste(canvas, (frame * (crop.width + 8), 0))
    strip.save(out / f"{name}_surf.png")
    print(f"Wrote {out / (name + '.png')} and {out / (name + '_surf.png')} (seed {seed}, rows {first}-{last})")


if __name__ == "__main__":
    main()
