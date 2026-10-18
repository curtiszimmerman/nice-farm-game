# Invisible world grid

The world uses 32-pixel tiles across a 120 × 90 tile map (3840 × 2880 pixels). This is four times the original area: a 300% increase. The grid is invisible during play. Walking and running remain smooth; placement, population, collision footprints, and adjacent farming targets share the tile coordinates.

`src/native/grid.gd` owns tile size, map dimensions, spawn tile, and conversion between world pixels and cell coordinates. Cell conversion floors positions; cell centers are half a tile from each cell's origin.

`src/native/world.gd` authors the layout in cells:

- Buildings specify a starting cell and a ground footprint in tiles. Drawing height can differ: the round wizard tower has a 3 × 3 solid base and a separate 192-pixel cylinder height. Roofs and upper stories can overhang walkable ground and fade when they hide the player.
- Trees occupy unique solid cells. Population reserves space around roads, buildings, and interaction destinations, and excludes water and occupied footprints. Canopies retain visual variation and can overhang neighboring cells.
- NPCs and interaction sites have tile-center anchors. Copper uses the row of exposed front cells, keeping the full seam interactive.
- The garden's twenty plots use the same grid. Facing selects the adjacent cell from the avatar's current cell, even between tile centers.
- Road routes connect grid cells along rows and columns. Their rendering retains rounded junctions, worn shoulders, and wheel tracks.
- Fences, lamps, the sign, radio, merchant cart, mine, ship clearing, and fishing jetty are anchored to cells or whole-tile footprints.
- River and pond cells supply terrain collision. The jetty reserves walkable cells over water. Shoreline detail softens the visible tile corners.
- Decorative flower and grass clumps use cell centers. Fine ground texture, sprite detail, particles, and flying insects remain visual detail within or above the layout.

Collision reads the populated cell map. Static solid footprints reject overlapping placement; trees reserve their cells after checking the same map. Farm gates and the jetty reserve traversal space. Native checks verify alignment, population exclusions, footprints, route connectivity, interaction reachability, copper collection, and smooth movement.

The map layout moves slightly as objects align to tiles. Gameplay save structure is unchanged: crops retain their plot indices, and the existing blocked-position recovery places an avatar at the shared spawn if its saved position is now obstructed.
