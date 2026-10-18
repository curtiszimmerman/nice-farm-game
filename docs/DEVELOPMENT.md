# Development notes

## Agreed direction

Z drives major story and technical decisions. The agent drives routine work and commits without pushing. Fun takes priority over grind, deadlines, or systems that reward disengaging from a cooperative session. Build in small playable increments.

The approaching ship is automated and can wait indefinitely. Its presence must not force progression. Fantasy races deliberately challenge learned assumptions about enemies; individual people complicate political conflict. Ordinary cross-border life continues.

Multiplayer means separate computers connecting directly over LAN/internet, with a player-host captain. The shared clock has three menu-time policies; time always continuing is default. Sleep is individual, with continuous days. Host/captain leads story choices, while any player can initiate progression. Money is shared or personal by initial choice; quests and relationships can be both. Disconnects do not halt the remaining session. Networking remains future work.

## Native prototype decision

Z explicitly rejected a browser game and required a native host application. The active implementation is Godot 4.5.1 with OpenGL Compatibility, downloaded into the project's ignored vendor directory and verified against the official SHA-512 sums. The abandoned browser experiment is preserved under ignored `internal/archive/browser/` and is not part of the active application.

All further writable paths belong inside this project. The launcher configures XDG paths, temporary files, and graphics shader caches accordingly. Do not install project tools or write artifacts elsewhere. Do not ask Z to run shell commands; run and verify the work directly within the authorized scope.

## Current implementation

Town population follows `src/native/villager_schedule.gd`, using the shared clock. Villagers walk tile routes around solid scenery; full pauses stop them, clock-only pauses allow walking. Development time jumps and loading resolve their current scheduled location. Actor positions are derived, not added to save data. Sleep hides villagers at their assigned home door; house interiors are not implemented. Chief Vale stays with the ship. Moss and Alder override their routines for the recoverable farmhouse appointment. All schedule destinations have reachability coverage.

The square has a fountain, the shop/cart, and three nearby homes. Buildings explicitly name their resident, with door plaques identifying each home. Iona's tower now sits in the northern mountain hollow, with matching revised night routines and a path around the ridge. Moss owns the south cottage, Tavi the southeast house, Finch the southwest house, and Alder the north house. Vale remains at the crashed ship.

The world is now 120 × 90 tiles, four times the original area. Town remains compact; the farmhouse sits west, the hidden ship northwest, the tower far north and the copper cave far southeast. The eastern ocean and cliff guardrails are removed. Northern cliffs form one continuous eroded ridge with coherent strata. Mine rock stays at least three tiles away from houses. Trees and ground decoration populate the expanded bounds with the same approximate density.

The tower has a square 3 × 3 collision footprint and a separate 192-pixel drawing height, with cylinder shading. The radio sits on a table one tile beyond the radio-club foundation. The full dock rectangle supplies fishing interactions. Geometry tests cover these clearances and interactions; older integration tests now derive moved destinations from the world layout. The mayor starts the farmhouse journey at 09:30 to account for the longer route. No save migration or reset is performed. No new external assets or tools. No season-specific schedules yet.

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

## Next discussion

Play and critique the slice before expanding it. Decide the next milestone, combat controls and feel, art direction, calendar/lunar rules, and the first actual networked cooperative interaction. Do not mistake placeholder content for approved final story or mechanics.
