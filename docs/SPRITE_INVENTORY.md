# Sprite inventory for town-life expansion

Existing assets are reused without pixel edits: all terrain borders, trees, bushes, flowers, fish, player/NPC frames, buildings, furniture, tools, calendar rings, waves, birds, ladder, telescope, copper and stone. The two existing generator catalogs remain the full machine-readable inventory; do not send them to artwork services as context.

New option-3-only sprites needed: temple facade, priest, decorative beehive, bee frames, fishing pole icon, coal deposit/icon, cave stairs up/down, healing spell icon, fire spell icon, small general-store sign, smith sign, baker sign. New sprites go in a separate helper module; existing artwork stays unchanged. Track completed IDs here after generation.

Completed in `scripts/town_additions16.py`: `building_temple`, `actor_priest_down0`, `beehive`, `bee0`, `bee1`, `item_fishing_pole`, `item_coal`, `cave_coal`, `cave_stairs_down`, `cave_stairs_up`, `item_hearthmend`, `item_emberthread`, `sign_general_store`, `sign_smith`, `sign_baker`. The source produced fifteen sprites for $1.1476732 in reported API-equivalent usage. No further artwork request is needed for this batch. The existing item generator also supplies a silver-ingot icon. An extra rug-size variant was generated for the priest's home.

All 23,403 preexisting option-3 sprites were compared pixel-for-pixel against the pre-task git atlas; none changed. Option 2's atlas and generator are untouched. Runtime fallbacks reuse existing assets when a selected older pack lacks the new additions.

Beehive construction, honey and beeswax production remain future features. The priest can teach the blueprint for two silver ingots. Future blueprint year gates must be explicit per blueprint.
