# Pixel artwork

The default artwork is option 2: an original, lossless RGBA PNG sprite atlas with integer-pixel edges and nearest-neighbor filtering. No SVG assets or image-generation services are involved. All assets and build outputs stay in the project.

The previous artwork is preserved as option 1. Its source snapshot is [original-art.tar](../src/native/art/option1/original-art.tar), from commit `9527b38`. The original renderers remain available under Settings → Artwork. Switching options redraws the retained scenery and changes the inventory icons; the choice currently lasts for the session.

## Grid composition

- Terrain and exterior building components are exactly 32 × 32 pixels. House facades combine wall, corner, foundation, door and window tiles. Roofs combine field, ridge and sloping edge tiles, with separate chimney tiles. Porch lights, flowerbeds, fences and walkways are separate components.
- Tree sprites have a one-tile-wide, two-tile-high trunk area, beneath a three-tile-wide canopy that is two, three or four tiles high. Oak, birch and pine have different silhouettes, bark and leaf clusters. Roots still occupy one collision cell; the taller drawing represents the upright tree.
- Cliffs use connected 32-pixel sprites. Exposed edge variants follow the same solid-cell map as collision. The cave entrance combines arch components with dark interior tiles.
- Interior floors and partitions use tiles. Furniture has separate sprites for each footprint, with shaded faces, grain, upholstery, book-spine marks and shadows. Dust covers overlay furniture. Glitching screens and sparks remain separate animated sprites.
- Actors have facing, walking and sleeping frames. Crops, bushes, cave rocks, copper, rats, inventory icons, opening ships, bridge, planet, explosions and particles all use the atlas.

Each object's geometry and collision still follow the existing invisible grid. Sprites are retained draw commands; changing the art does not require repainting static scenery every frame.

## Rebuild

```sh
python3 -B scripts/make_sprites.py
python3 -B tests/test_sprite_assets.py
```

The generator uses only the Python standard library. It writes `src/native/art/option2/sprites.png` and `sprites.json`. The catalog records each atlas region, and tree entries include their trunk and canopy dimensions. Furniture footprints are collected from the authored interior layouts. New furniture sizes need a generated sprite before they can render.

`art.gd` assembles sprites at runtime. Its atlas cache is shared by the world, rooms, opening and item slots. The editable generator, palettes and atlas metadata are the sources for further art work; screenshots remain under ignored `internal/verification/`.

## Player sprite packs

Place a pack folder under `src/native/art/packs/`, then open Settings → Artwork. The menu discovers its `pack.json` each time it opens. A pack contains a PNG atlas, the complete sprite catalog, and this manifest:

```json
{
  "id": "my-artwork",
  "name": "My artwork",
  "tile_size": 16,
  "atlas": "sprites.png",
  "sprites": "sprites.json"
}
```

Use option 2's `sprites.json` as the required sprite list. Each entry has an integer `rect: [x, y, width, height]` in native atlas pixels. Packs must supply every sprite. With `tile_size: 32`, keep the original dimensions; with `tile_size: 16`, halve each dimension, rounding up. The engine scales the artwork with nearest-neighbor filtering, retaining the 32-unit world grid, furniture anchors, collision and depth ordering. Both file paths must stay inside the pack folder. Invalid manifests, missing sprites, invalid dimensions and out-of-bounds rectangles leave the current pack active.

Fence sprites `tile_fence_mask0` through `tile_fence_mask15` connect toward their neighbors: left = 1, right = 2, up = 4, down = 8. A tile has one centered post. Open gates occupy separate walkable tiles. Watered planted crops use the `_wet` variants so their soil remains visibly dark beneath the plant. Furniture uses its own shaded faces and feet without a detached oval shadow.
