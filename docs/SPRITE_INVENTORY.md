# Sprite inventory for town-life expansion

Glass jars use a small cached inventory bitmap from `items.gd`. Southern beach terrain reuses the current pack's grass texture with a sand palette; surf uses the existing ripple sprite. Northern coastal cliffs use the current pack's connected cliff tiles. No atlas sprites were replaced for this pass.

Seasonal crop sprites: `src/native/crop_art.gd` supplies eight 16×16 bitmap icons (green onion, tomato, cucumber and gladain produce plus their seed packets). Mature crops reuse their produce sprite in the field; immature plants use the existing sprout. These are generated and cached locally without changing atlas artwork. Existing moon turnip and star bulb sprites remain in their packs.

The survival/faith pass adds thirteen option-3 sprites and replaces the seven requested weekday-ring designs. `scripts/journey_sprites16.py` contains metal ship bunks/lockers/table, a temple altar, thirsty/starving icons, winter sparkbloom world/item sprites, and preserves/flour/sugar/butter/cobbler icons. Its small artwork request reported $0.4766336 API-equivalent usage. Public prompt and exchange records are in `internal/claude-review/borders/06-survival-faith/`. Border work remains deferred separately. The default atlas now has 23,432 entries.

Existing assets are reused without pixel edits: all terrain borders, trees, bushes, flowers, fish, player/NPC frames, buildings, furniture, tools, calendar rings, waves, birds, ladder, telescope, copper and stone. The two existing generator catalogs remain the full machine-readable inventory; do not send them to artwork services as context.

The town-life artwork request covered the temple facade, priest, decorative beehive, bee frames, fishing pole, coal deposit/icon, cave stairs, spell icons and three shop signs. These are complete, in a separate option-3 helper. Existing artwork stays unchanged. Exact names and dense border-family patterns are listed in [SPRITE_CATALOG.md](SPRITE_CATALOG.md), generated with `python3 -B scripts/sprite_inventory.py`.

Completed in `scripts/town_additions16.py`: `building_temple`, `actor_priest_down0`, `beehive`, `bee0`, `bee1`, `item_fishing_pole`, `item_coal`, `cave_coal`, `cave_stairs_down`, `cave_stairs_up`, `item_hearthmend`, `item_emberthread`, `sign_general_store`, `sign_smith`, `sign_baker`. The source produced fifteen sprites for $1.1476732 in reported API-equivalent usage. No further artwork request is needed for this batch. A silver-ingot icon copies the existing copper bar's shape with a cool metal palette; its original source stays unchanged. Interiors reuse existing furniture sizes.

All 23,403 preexisting option-3 sprites were compared pixel-for-pixel against the pre-task git atlas; none changed. Option 2's atlas and generator are untouched. Runtime fallbacks reuse existing assets when a selected older pack lacks the new additions.

Beehive construction, honey and beeswax production remain future features. The priest can teach the blueprint for two silver ingots. Future blueprint year gates must be explicit per blueprint.

No further town-life sprites are pending. The older dedicated paving/jetty corner work remains listed in [ART_TODO.md](ART_TODO.md).
