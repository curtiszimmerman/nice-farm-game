# Invisible world grid

The world uses 32-unit tiles. The mainland spans 120 × 90 cells; a 28-cell western extension brings the full extent to 148 × 90, from world X -896 through 3840. Interior maps keep their own local coordinates. The grid is invisible during play. Walking remains smooth; placement, collision footprints and farming targets share tile coordinates.

`src/native/grid.gd` owns tile size, map dimensions, spawn tile, and conversion between world pixels and cell coordinates. Cell conversion floors positions; cell centers are half a tile from each cell's origin.

`src/native/world.gd` authors the layout in cells:

- Buildings specify a starting cell and a ground footprint in tiles. Drawing height can differ: the round wizard tower has a 3 × 3 solid base and a separate 192-pixel cylinder height. Roofs and upper stories can overhang walkable ground and fade when they hide the player.
- Trees occupy unique solid cells. Population reserves space around roads, buildings, and interaction destinations, and excludes water and occupied footprints. Canopies retain visual variation and can overhang neighboring cells.
- NPCs and interaction sites have tile-center anchors. Moss starts at the mountain trail's foot, and accepting his invitation follows a real grid route into the farmhouse. Copper is mined from individual solid rocks inside the generated cave.
- The garden's twenty plots use the same grid. Facing selects the adjacent cell from the avatar's current cell, even between tile centers.
- Roads follow shortest traversable grid paths from building entrances to the square, avoiding fields, fences and flowerbeds. Central streets and door approaches are paved; rural routes retain dirt shoulders and wheel tracks. Open yard gates connect residential approaches.
- Fences, lamps, the sign, radio, merchant cart, mine, ship clearing, and fishing jetty are anchored to cells or whole-tile footprints.
- Ocean and pond cells supply terrain collision. Both jetties reserve walkable cells over water. The western jetty has a wide end platform and a lighthouse with a square ground footprint. Its outer cells provide the exclusive deep-water fishing habitat.
- Decorative flower and grass clumps use cell centers. Fine ground texture, sprite detail, particles, and flying insects remain visual detail within or above the layout.
- Artwork option 2 assembles 32 × 32 PNG components into houses and connected cliffs. Tree sprites combine a 1 × 2 trunk area with a 3 × 2–4 canopy. Decorative bushes reserve population space along the mountain's lower slopes. The farmhouse is two tiles farther south, and its entrance, chest, paths, field and spawn move with it.
- Doors link the outdoor map to distinct interior maps with their own solid cells, room partitions, furniture footprints and exits. The tower is 9 × 11 cells; shared family homes house three residents, and the tavern has a larger 19 × 15 plan. Bathrooms have a single private entrance. Exit landings check collision so the shop wagon cannot trap the player. Moss's fields, Bram's garden and the Reed fields occupy reserved decorative cells and never share player crop indices.

Collision reads the populated cell map. Static solid footprints reject overlapping placement; trees reserve their cells after checking the same map. Farm gates and the jetty reserve traversal space. Native checks verify alignment, population exclusions, footprints, route connectivity, interaction reachability, copper collection, and smooth movement.

Saved world and cave seeds vary decoration and resource placement between visits. Paths and interaction destinations remain clear. Resource generation consumes the same seeded choices after clearing a tree or rock, so reloading does not reshuffle the rest. Version 11 stores the woodcutter's axe gift, cave pickaxe pickup and first cave discovery. Unsupported older saves remain preserved; no automatic migration is implemented.

House walls occupy one ground cell and draw two cells high with connected plaster-and-timber sprites. Only overhangs above hallway cells can fade. Married parents share a two-person bed; children retain their own beds. The tavern entry leads into the taproom, with a private rear apartment. Its private doorway blocks visitors while allowing the resident to reach his rooms.

NPCs use a 22-unit separation distance from the player. Player movement can displace them onto clear terrain; routes retain their forward waypoint and replan for actual obstruction or destination changes. Conversations hold their speakers. Flowerbeds and bench bases occupy solid cells. Only the fountain's lower basin row is solid; its upper spray is a separate animated, depth-sorted prop. Eastern/northeastern buildings connect through the town road network. The Reed fields reserve decorative crop areas; parents share a bed while children have their own.
