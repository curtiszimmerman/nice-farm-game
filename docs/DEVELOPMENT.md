# Development notes

## Agreed direction

Z drives major story and technical decisions. The agent drives routine work and commits without pushing. Fun takes priority over grind, deadlines, or systems that reward disengaging from a cooperative session. Build in small playable increments.

The approaching ship is automated and can wait indefinitely. Its presence must not force progression. Fantasy races deliberately challenge learned assumptions about enemies; individual people complicate political conflict. Ordinary cross-border life continues.

Multiplayer means separate computers connecting directly over LAN/internet, with a player-host captain. The shared clock has three menu-time policies; time always continuing is default. Sleep is individual, with continuous days. Host/captain leads story choices, while any player can initiate progression. Money is shared or personal by initial choice; quests and relationships can be both. Disconnects do not halt the remaining session. Networking remains future work.

## Native prototype decision

Z explicitly rejected a browser game and required a native host application. The active implementation is Godot 4.5.1 with OpenGL Compatibility, downloaded into the project's ignored vendor directory and verified against the official SHA-512 sums. The abandoned browser experiment is preserved under ignored `internal/archive/browser/` and is not part of the active application.

All further writable paths belong inside this project. The launcher configures XDG paths, temporary files, and graphics shader caches accordingly. Do not install project tools or write artifacts elsewhere. Do not ask Z to run shell commands; run and verify the work directly within the authorized scope.

## Current implementation

Town population follows `src/native/villager_schedule.gd`, using the shared clock. Villagers walk tile routes around solid scenery; full pauses stop them, clock-only pauses allow walking. Development time jumps and loading resolve their current scheduled location. Actor positions are derived. Moss tends his decorative fields after the initial invitation. Finch works inside the Radio Club. Sleeping residents appear in their bedroom; outdoor actors disappear only after reaching the door. Chief Vale stays with the ship. Moss and Alder override their routines for the recoverable farmhouse appointment. All schedule destinations have reachability coverage.

The square has a fountain, the shop/cart, and three nearby homes. Buildings explicitly name their resident, with door plaques identifying each home. Iona's tower now sits in the northern mountain hollow, with matching revised night routines and a path around the ridge. Moss owns the south cottage, Tavi the southeast house, Finch the southwest house, and Alder the north house. Vale remains at the crashed ship.

The world is now 120 × 90 tiles, four times the original area. Town remains compact; the farmhouse sits west, the hidden ship northwest, the tower far north and the copper cave far southeast. The eastern ocean and cliff guardrails are removed. Northern cliffs form one continuous eroded ridge with coherent strata. Mine rock stays at least three tiles away from houses. Trees and ground decoration populate the expanded bounds with the same approximate density.

The tower has a square 3 × 3 collision footprint and a separate 192-pixel drawing height, with cylinder shading. The radio sits on a table one tile beyond the radio-club foundation. The full dock rectangle supplies fishing interactions. Geometry tests cover these clearances and interactions. Alder and Neral leave town early enough to arrive at the farm around ten; Moss joins from nearby. No new external assets or tools. No season-specific schedules yet.

The camera uses 1.9125× zoom, following Z's additional 15% reduction from 2.25×. `interior_layouts.gd` describes compact building plans, ranging from a 9 × 11 tower to 17 × 12 public buildings, plus the 15 × 14 ship. Homes have separate sleeping areas; the farmhouse has guest beds, Moss a potting bench and reversed kitchen, Finch a home radio hobby desk, Tavi stored merchant supplies, and Alder a writing desk. Neral has a separate home. The club has a workshop and reception; the store has retail shelves, a counter and storeroom; the hall has a meeting table and office. Every town bathroom has one hallway entrance and is excluded from routes between other rooms. Tests close bathrooms and verify remaining destinations stay reachable.

The outdoor world remains loaded while indoor maps are active. Furniture dimensions, NPC work points and sleeping positions use the individual plan. Camera bounds center interiors smaller than the viewport and reset outdoors. The store-exit bug came from blindly adding a tile in front of its door, which landed inside the cart. `world.exit_position` checks candidate landing cells instead, and all building exits have a regression check. The veteran is now Bram, with a decorative 3 × 3 vegetable/herb garden outside his roadless log cabin. Neither his garden nor Moss's fields share player crop state. His deeper history remains open for Z's direction.

`items.gd` owns original pixel icons, item text and provisional food values. Satchel slots show quantities, native hover tooltips and click actions for food, planting selection and equipment. Star-bulb seeds can be bought, planted, watered, grown with time or Wildgrowth, harvested and sold. Food cannot be consumed when it would restore nothing. Separate health has no combat damage system yet; the rusty sword is equippable and visible, with combat behavior still future work.

Save format 6 includes first ship departure, the farmhouse welcome phase/timer and separate fish quantities, alongside opening completion, resources, storage and cleanup state. Round trips and welcome-stage persistence are tested; oversized carried inventories are rejected. Sleeping saves record the walkable position beside the bed. Approval to upgrade old saves is pending: CLAUDE.md explicitly requires approval before any backward compatibility. The original gameplay save has not been migrated, reset or overwritten.

## Arrival and first home

Z specified the opening story and its sequence. `opening.gd` renders a 28-second native animation alternating ship exteriors and an intact bridge with a seated captain. Incoming fire precedes evasive orders, Vale's landing attempt and the brace command. A white fade, original crash/rumble WAV and fade into engineering lead to the status-report conversation. The clock starts at 09:00 Spring 01 and stays held until the first ship departure, including after the briefing. The briefing covers major repairs, emergency gravitic cloak power, copper, food, water and rations. New visits begin aboard; confirmed resets replay the opening. Existing visits resume their saved stage.

The wreck's ridge has an irregular silhouette, weathered shading and one descent exit at (13,28). A longer meadow path separates it from the farmhouse. Coming around either side forces Moss's encounter, positioning him on nearby clear ground within view. He challenges the flash/crash as possible spellcasting, asks whether they are travelers and offers the empty farmhouse because town has no hotel. Initial dialogue panels sit above the characters so the panel does not hide them.

The first farmhouse visit uses saved phases: unvisited, waiting, meeting, departing, complete. The captain can explore during the eight-second arrival wait but cannot leave; the calendar stays held. Meeting placement explicitly makes Alder, Moss and Neral visible at three distinct clear floor positions. Required dialogue cannot be dismissed or replaced by menus. The final choice starts each visitor's actual tile route to the exit. Captain movement and time stay held until every actor has left. Saving preserves the phase; resets can bypass an old lock only to start the new opening. Ordinary later interactions retain normal pause settings. Regression tests use real movement input, actual dialogue buttons, visibility, door attempts, departure routes and saved-state round trips.

Farmhouse furnishings have individual cover tasks for sofa, bed, guest bed and radio. The kitchen cabinet starts with two light bulbs; E at the bathroom/living-room fixtures consumes one bulb and restores that area's lighting. Covers and room dimming update immediately. Cleanup is recorded independently of the mayor conversation. Tests perform every cleanup through the real interaction and storage interface.

Quick slots always start empty, including spells; collecting items never assigns a slot. Starter seeds are in the chest and the can starts empty. The satchel has twelve slots, enforced for transfers, gathering, rewards, purchases, cooking and saves. Single-item quantities are hidden; single-item transfers bypass the quantity chooser. Regression fixtures explicitly complete the real opening/briefing and manually assign tools for tests of later gameplay.

## Interior depth, conversations and farming supplies

Interior partitions have continuous dark tops, lighter vertical faces and baseboards, distinct from warm wooden floorboards. Furniture remains individually positioned with independent collision footprints for future decoration work. Tables and chairs have separate tops, aprons, legs and shadows; beds, shelving, bathroom fixtures and cabinets use shaded faces. Book spines have tiny title marks and binding highlights. Walls and furniture fade when they hide the avatar. Sleepers face along the mattress, with their bodies beneath the blanket; waking returns the player beside the bed.

Neral is Mayor Alder's dark-skinned dark-elf assistant. He has a cottage southeast of town and a town-hall work schedule. Moss fetches him and Alder for the same-day farmhouse welcome. Conversation holds apply to indoor and outdoor actors, including development time jumps. Tavi keeps trading beyond closing until the conversation ends. Walking more than 160 pixels away or closing an unfinished narrative releases its participants to go home and sleep for that day. Finished choices release them to normal routines. An abandoned introduction cannot restart that same day.

The farmhouse chest has eighteen stack slots, beside twelve carried slots. Withdraw or deposit a chosen quantity; different item types swap only as whole stacks. It starts with seeds, a hoe, empty watering can and sickle. Farming requires that tool in a manually assigned and selected quick slot, with 1–8 selection. Tilling costs 2 energy, watering 1, harvesting 1; planting and waiting are free. Crops mature after 4,320 game minutes. Wildgrowth stores a separate growth bonus so a day-one cast never needs a negative planting timestamp. The can holds twenty charges and refills at the pond; well construction remains future work. Exhaustion prevents spending unavailable energy. Only explicit restorative food/effects or sleep in a farmhouse bed/ship bunk restore energy.

Tavi sells cookware (20 crowns each) and health elixirs (15 crowns). Purchased pot/pan unlocks persist even when the utensils are stored. The farmhouse stove draws ingredients atomically from the satchel and connected twelve-slot kitchen cabinet. Fish sticks use one fish; stew uses one fish, turnip and star bulb. Provisional cooked values: sticks +12 HP/+20 energy; stew +20 HP/+30 energy/+15 mana. Inventory context menus expose Eat/Drink and quick-slot assignments. Actions groups the command buttons; the crew log collapses below the clock.

The ship interior is a compact 15 × 14 engineering/bunk map accessed through a virtual building entry at the cloaked hull. Vale's outdoor schedule resolves into this room. Its twelve-slot locker starts with six rations. Each day consumes a ration first, otherwise one cooked meal. Time jumps process every crossed day; late supply deposits feed an unfed Vale immediately, once that day. Missing meals are reported without an invented penalty. Three console props animate intermittent snow, machinery lights pulse slowly, and ceiling cables spark. Ship ambience is a separate reproducible WAV hum/beep layer; the normal music and wildlife fade out inside.

Bunks and the locker are in the upper rear; broken machinery, displays, cables and Vale's work positions occupy the lower/front section. Pond refilling checks adjacent freshwater tiles, covering reachable shores beyond the jetty. The southern coast has an enterable dock; the eastern inland edge remains clear of ocean barriers. Pond species: silverfin (easy, 10 crowns) and moon pike (hard, 35). Ocean species: sea sprat (easy, 12), blue mackerel (easy, 16), storm eel (hard, 50). A cast randomizes its opening phase. The hard gauge combines a faster oscillation with a second changing phase and jitter; it remains bounded. Fish retain distinct quantities/icons and work interchangeably in recipes, including cabinet ingredients. Tests cover shoreline activation, pools, difficulty, actual catches, sale prices, cooking and freshwater-only refilling.

Z explicitly requested attribution of all repository commits to curtiszimmerman <curtis.zimmerman@gmail.com>, a GitHub SSH origin and publication of this task's history. Preserve an ignored local bundle before rewriting author and committer records. Keep the existing uncommitted executable permission on scripts/play.sh. This explicit publication request overrides the usual local-only workflow for this task.

- `src/native/state.gd`: resource transactions, crops, clock, story prerequisites, save schema.
- `src/native/world.gd`: deterministic original pixel scenery, collision, proximity selection, actors, effects.
- `src/native/interface.gd`: native HUD, menus, dialogue choices, title screen, fishing gauge.
- `src/native/game.gd`: input, continuous simulation, interactions, story scenes, persistence, sound context and successful spell triggers.
- `src/native/sound.gd`: independent music/ambience/effects playback, daylight/season/interior mix profiles, volume preferences, clean audio shutdown. See `AUDIO.md`.
- `scripts/make_audio.py`: reproducible original WAV assets; synthesis runs during asset creation, not gameplay.
- `scripts/play.sh`: native launch with project-local runtime paths.
- `scripts/check.sh`: repeatable headless verification.
- `tests/native/`: simulation, controller/interface integration, reachability, isolated file persistence, and real rendered visual checks.

Content and tuning are provisional. Local menu-time options exercise shared simulation policy without claiming to implement multiplayer. The first story meeting is recoverable when missed. Native state saves use validation and atomic replacement; corrupt files are preserved. No remote services or browser runtime are used.

## Findings from verification

The development host exposes a Quadro P3200, not the target GeForce 940MX. Native OpenGL rendering works here; target-device performance remains unmeasured.

Godot's initial ProgressBar sizing can retain the default theme's minimum height even after compact styles are applied. Apply explicit dimensions after overriding styles. The regression is covered in integration checks.

The terrain is drawn by the parent world node. Putting crops at a negative z-index hid them beneath it. Crops now share z-index zero and sort before world objects; the regression is covered in integration checks.

Native visual tests wait briefly after stopping audio before destroying the scene, allowing audio playback resources to release cleanly. The latest verbose render run ended without leak warnings.

Audio playback can be queued until the next frame. Shutdown lets pending playback start before stopping, then gives the audio thread time to release references. This also keeps fast headless tests from exiting with queued playback resources.

Z found the original music disturbing and requested playful music with separate environment/time/season ambience and per-spell effects. The replacement uses major-key plucked notes; bird, cricket, and echoed water layers have independent loop lengths and smooth transitions. The provisional development calendar drives seasonal profiles. Cave profiles are tested, while cave interiors remain future gameplay.

## Development shortcuts

Z requested three-times movement and menu time jumps during development. Debug builds multiply walking and running by three, with small collision steps to prevent tunneling. Escape → Development tools advances actual simulation by 1, 12, or 24 hours, or one provisional 28-day season. Jumps update calendar labels, seasonal audio, crops, and saved time, while canceling active rest/gathering. Release exports hide these tools and use original movement speeds. The 28-day season length is a development placeholder, not a finalized calendar decision.

## World readability

Z requested unmistakably blue nights, forward-facing garden targeting, scenery transparency behind occluders, and connected roads. World-only CanvasModulate lighting now blends through dawn/dusk into blue moonlight. The interface keeps its own colors. A garden target is the adjacent cell in the avatar's facing direction; highlighting, tending, and Wildgrowth share this selection, with no fallback to the occupied cell.

Trees and buildings fade when their visual bounds overlap an avatar drawn behind them; opacity restores when the avatar moves clear. Collision remains unchanged. Roads use a merged capsule mask with rounded joins, irregular worn shoulders, scattered texture, and subtle wheel tracks. The same segment geometry keeps trees clear of roads. Main routes skirt town hall and connect the farmhouse lane, market, pond, and mine approach. Native checks cover directional actions, occlusion, night color, road continuity, and rounded shoulders; screenshots cover the corresponding rendered scenes.

## Copper interaction regression

The copper interaction point was at (1585,1090), below the visible veins around y=1000–1030. Approaching the rock face placed the avatar outside its 55-unit interaction radius. Copper now uses the exposed front seam's rectangular bounds, so the center and both sides work from reachable ground. A regression test walks into the rock collision with real movement input, collects three copper through the game loop, checks energy costs, and rejects gathering far down the road. The older integration test now approaches the visible seam rather than the former invisible hotspot.

## Shared world grid

Z requested invisible grid-based population throughout the world, like the farm. `grid.gd` now owns 32-pixel tiles on a 60 × 45 map. Layout data is authored in cells; population and collision share an occupancy map. Building dimensions, tree roots, resource bounds, NPC anchors, road routes, fences, scenery, and terrain derive from that grid. Movement remains smooth, and farming targets the adjacent cell. Gates and the jetty reserve walkable space. See `WORLD_GRID.md` for the placement model and tests.

## Cave and town-life implementation

Z's latest scope adds cleanup-gated arrival, Moss's post-mayor farming lesson, learned magic, generated cave mining/combat, distinct authored interiors, and retained scenery drawing. Work is on `wip/caves-and-town-life`. The preceding 17 commits were rewritten to curtiszimmerman / curtis.zimmerman@gmail.com and published to GitHub main at 67d1ebd; the original history bundle remains ignored in internal/. New work is not automatically published.

Save format 7 strictly includes magic learning, the cave seed/barrel/cleared rocks/defeated rats/component flags, and the Moss lesson phase. No migration was added; old saves remain protected. Cave generation uses six nonoverlapping room bins joined by orthogonal corridors; deposits skip corridor cells. Two rats use existing grid routing. Current combat tuning is provisional: mining 5 energy, sword swings 2, rats take two hits and bite for 4 HP. Defeat returns the player to the cave entrance with 25 HP and no inventory loss.

Rendering uses explicit static scenery and moving-object nodes with recursive y sorting. Terrain and static CanvasItem drawing lists are retained; GPU scene rendering still happens each frame. Crop drawings change only when plot data or ripeness changes. Furniture covers and room lights use change detection; ship machinery has separate animated display children. Actual draw callbacks are counted in regression tests. This avoids rebuilding static geometry each frame without allocating an enormous world-sized viewport cache.

All house geometries are individually authored. Reachability checks cover interaction points, NPC work cells, and circulation with bathroom doors closed. A failed route check found blocked doorways behind beds, shelves and dining chairs; furniture positions were corrected instead of weakening the checks. The southern ocean and dock are removed; unused coastal fish remain catalog entries pending approved geography.

## Modular sprites and guided arrival

Z explicitly requested replacing the vector-like composition with actual pixel sprites while preserving option 1. The pre-change art source was archived from 9527b38 before edits in `src/native/art/option1/original-art.tar`. Its renderers remain selectable. Option 2 uses a generated RGBA PNG atlas and JSON regions, loaded once through `art.gd`. `scripts/make_sprites.py` writes only inside the project and uses no external packages. The image-generation tool was not used because its default output path conflicts with Z's no-writes-outside-project rule. Native geometry, collision and retained draw lists remain intact.

Moss now waits at (13,30), below the trail exit, instead of teleporting beside the captain. The farmhouse, front landing, chest, roads and fields move two tiles south. The saved `escorting` welcome phase follows an actual path into the farmhouse with control/time held; it then joins the existing cleanup gate. No save migration was added. The intro now exchanges fire, destroys the attacker and preserves the crew's forced landing; Vale's signal warning precedes the captain's cloak priority.

Empty carried stacks clear their quick-slot references on use, transfer, selling, cooking and interface refresh. Cookware must be physically carried or in the kitchen cabinet, and cooking opens only at the oven. A regression caught selected food taking priority over the oven; oven interaction now opens its menu without consuming the ingredient. Purchase history no longer grants cooking access by itself. Notifications have a bordered, opaque panel.

An early atlas import check exposed an RGB/RGBA blit mismatch, corrected by giving the retained terrain texture the atlas's RGBA format. Native art checks also account for JSON numeric values loading as floats when validating tree dimensions. Asset tests verify PNG bounds, exact tile dimensions, tree contracts and the original-art archive. Full native visual runs inspect both the new sprite work and the preserved render option.

The final atlas contains 356 sprites at 2048 × 1157 pixels. The oven supports both nearby left clicks and E; cookware selection is unnecessary. Final verification passed 565 native checks, two PNG/archive checks, startup smoke, and the host visual/audio run without warnings or errors. Screenshots include both sides firing, the enemy explosion, the status banner, the planted mountain foot with Moss, and every house interior. The existing launcher executable-bit modification remains outside these commits.

## Next discussion

Play and critique the slice before expanding it. Decide the next milestone, combat controls and feel, art direction, calendar/lunar rules, and the first actual networked cooperative interaction. Do not mistake placeholder content for approved final story or mechanics.
