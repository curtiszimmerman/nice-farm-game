#!/usr/bin/env python3
"""Draw a top-down map of the outdoor world from the game's real layout data.

When to use: planning or checking building placement, streets, roads, paths, fences and gardens.
It runs the game headless to dump the layout (scripts/town_map_dump.gd), then writes an SVG with
one square per cell. Buildings are labelled with their id, and doors are marked.

  python3 scripts/town_map.py                       full map -> internal/verification/town_map.svg
  python3 scripts/town_map.py --crop 20,25,95,85    only that cell rectangle (x0,y0,x1,y1)
  python3 scripts/town_map.py --json saved.json     redraw a saved dump without running the game
  python3 scripts/town_map.py --overlay plan.json   draw planned buildings and routes on top

An overlay is {"buildings":[{"id","cell":[x,y],"tiles":[w,h],"label"}], "routes":[{"kind":
"paved|road|path","cells":[[x,y],...]}], "fences":[[x,y],...], "notes":[{"cell":[x,y],"text"}]}.
"""
import argparse
import json
import pathlib
import subprocess
import sys
from xml.sax.saxutils import escape

ROOT = pathlib.Path(__file__).resolve().parents[1]
CELL = 10
COLORS = {"grass": "#7fa65a", "paved": "#9a9a92", "road": "#c4a272", "path": "#d8c79a", "trail": "#cdbf8f",
          "water": "#4f86b0", "tree": "#2f5a2c", "fence": "#6b4a2a", "gate": "#d9a441", "garden": "#a7c46a",
          "farm": "#8a6a44", "building": "#b5835a", "building_line": "#3d2a1a", "rock": "#7d7a74", "solid": "#5c6b52",
          "square": "#e6d9b0", "plan": "#d9442e"}


def dump(path):
    command = ["bash", str(ROOT / "scripts/play.sh"), "--headless", "--script", "../../scripts/town_map_dump.gd", "--", str(path)]
    result = subprocess.run(command, capture_output=True, text=True, timeout=300)
    if result.returncode or not path.exists():
        log = ROOT / "internal/verification/town_map_dump.log"
        log.write_text(result.stdout + result.stderr)
        sys.exit(f"The layout dump failed; see {log}")


def draw(data, overlay, crop, output, solid_depth=0):
    x0, y0, x1, y1 = crop or (data["origin"][0], data["origin"][1], data["origin"][0] + data["size"][0] + 28, data["origin"][1] + data["size"][1])
    width, height = (x1 - x0) * CELL, (y1 - y0) * CELL
    inside = lambda c: x0 <= c[0] < x1 and y0 <= c[1] < y1
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" width="{width}" height="{height}" font-family="sans-serif">',
           f'<rect width="{width}" height="{height}" fill="{COLORS["grass"]}"/>']

    def box(c, color, inset=0, opacity=1.0):
        if inside(c):
            out.append(f'<rect x="{(c[0]-x0)*CELL+inset}" y="{(c[1]-y0)*CELL+inset}" width="{CELL-2*inset}" height="{CELL-2*inset}" fill="{color}" fill-opacity="{opacity}"/>')

    sq = data["square"]
    out.append(f'<rect x="{(sq[0]-x0)*CELL}" y="{(sq[1]-y0)*CELL}" width="{sq[2]*CELL}" height="{sq[3]*CELL}" fill="{COLORS["square"]}"/>')
    for kind, color in (("farm", "farm"), ("trails", "trail"), ("paths", "path"), ("roads", "road"), ("paved", "paved"), ("gardens", "garden")):
        for c in data[kind]: box(c, COLORS[color])
    for key, kind in data["solid"].items():
        c = [int(v) for v in key.split(",")]
        if kind == "water": box(c, COLORS["water"])
        elif kind in ("rock",): box(c, COLORS["rock"])
        elif kind not in ("building", "yard fence", "tree", "flowerbed"): box(c, COLORS["solid"], 2)
    for c in data["trees"]: box(c, COLORS["tree"], 1)
    for c in data["fences"]: box(c, COLORS["fence"], 3)
    for c in data["gates"]: box(c, COLORS["gate"], 3)
    for b in data["buildings"]:
        bx, by = b["cell"]
        w, h = b["tiles"]
        if not (bx + w > x0 and bx < x1 and by + h > y0 and by < y1): continue
        out.append(f'<rect x="{(bx-x0)*CELL}" y="{(by-y0)*CELL}" width="{w*CELL}" height="{h*CELL}" fill="{COLORS["building"]}" stroke="{COLORS["building_line"]}" stroke-width="1.5"/>')
        if solid_depth and h > solid_depth:
            # Only the bottom rows block movement; the rest is artwork the player can walk behind.
            out.append(f'<rect x="{(bx-x0)*CELL}" y="{(by-y0)*CELL}" width="{w*CELL}" height="{(h-solid_depth)*CELL}" fill="#e8d2b0" fill-opacity="0.75"/>')
        label = b.get("resident") or b["id"]
        out.append(f'<text x="{(bx-x0+w/2)*CELL}" y="{(by-y0+h/2)*CELL+3}" font-size="8" text-anchor="middle" fill="#1d130b">{escape(label)}</text>')
    for site in data["sites"]:
        if site["id"].startswith("door_"): box(site["cell"], "#1d130b", 3)
    if overlay:
        for route in overlay.get("routes", []):
            for c in route["cells"]: box(c, COLORS[{"paved": "paved", "road": "road", "path": "path"}[route["kind"]]], 0, 0.9)
        for c in overlay.get("fences", []): box(c, COLORS["fence"], 3)
        for b in overlay.get("buildings", []):
            bx, by = b["cell"]
            w, h = b["tiles"]
            out.append(f'<rect x="{(bx-x0)*CELL}" y="{(by-y0)*CELL}" width="{w*CELL}" height="{h*CELL}" fill="none" stroke="{COLORS["plan"]}" stroke-width="2" stroke-dasharray="4 2"/>')
            out.append(f'<text x="{(bx-x0+w/2)*CELL}" y="{(by-y0)*CELL-2}" font-size="8" text-anchor="middle" fill="{COLORS["plan"]}">{escape(b.get("label", b["id"]))}</text>')
        for note in overlay.get("notes", []):
            c = note["cell"]
            out.append(f'<text x="{(c[0]-x0)*CELL}" y="{(c[1]-y0)*CELL}" font-size="8" fill="{COLORS["plan"]}">{escape(note["text"])}</text>')
    for gx in range(x0 - x0 % 10 + 10, x1, 10):
        out.append(f'<text x="{(gx-x0)*CELL+1}" y="8" font-size="7" fill="#203018">{gx}</text>')
    for gy in range(y0 - y0 % 10 + 10, y1, 10):
        out.append(f'<text x="1" y="{(gy-y0)*CELL+7}" font-size="7" fill="#203018">{gy}</text>')
    out.append("</svg>")
    output.write_text("\n".join(out))
    print(f"Wrote {output.relative_to(ROOT)} ({x1-x0}x{y1-y0} cells)")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--json", help="Draw this saved dump instead of running the game.")
    parser.add_argument("--save-json", default="internal/verification/town_map.json", help="Where the fresh dump is kept.")
    parser.add_argument("--overlay", help="Planned buildings and routes to draw on top.")
    parser.add_argument("--crop", help="Cell rectangle x0,y0,x1,y1 to draw.")
    parser.add_argument("--output", default="internal/verification/town_map.svg", help="SVG file to write.")
    parser.add_argument("--solid-depth", type=int, default=0, help="Shade all but this many bottom rows of each building as walk-behind artwork.")
    args = parser.parse_args()
    source = pathlib.Path(args.json) if args.json else ROOT / args.save_json
    if not args.json:
        source.parent.mkdir(parents=True, exist_ok=True)
        dump(source.resolve())
    data = json.loads(source.read_text())
    overlay = json.loads(pathlib.Path(args.overlay).read_text()) if args.overlay else None
    crop = tuple(int(v) for v in args.crop.split(",")) if args.crop else None
    draw(data, overlay, crop, (ROOT / args.output).resolve(), args.solid_depth)


if __name__ == "__main__":
    main()
