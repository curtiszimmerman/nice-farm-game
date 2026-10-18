# Development notes

## Agreed direction

Z drives major story and technical decisions. The agent drives routine work and commits without pushing. Fun takes priority over grind, deadlines, or systems that reward disengaging from a cooperative session. Build in small playable increments.

The approaching ship is automated and can wait indefinitely. Its presence must not force progression. Fantasy races deliberately challenge learned assumptions about enemies; individual people complicate political conflict. Ordinary cross-border life continues.

Multiplayer means separate computers connecting directly over LAN/internet, with a player-host captain. The shared clock has three menu-time policies; time always continuing is default. Sleep is individual, with continuous days. Host/captain leads story choices, while any player can initiate progression. Money is shared or personal by initial choice; quests and relationships can be both. Disconnects do not halt the remaining session. Networking remains future work.

## Native prototype decision

Z explicitly rejected a browser game and required a native host application. The active implementation is Godot 4.5.1 with OpenGL Compatibility, downloaded into the project's ignored vendor directory and verified against the official SHA-512 sums. The abandoned browser experiment is preserved under ignored `internal/archive/browser/` and is not part of the active application.

All further writable paths belong inside this project. The launcher configures XDG paths, temporary files, and graphics shader caches accordingly. Do not install project tools or write artifacts elsewhere. Do not ask Z to run shell commands; run and verify the work directly within the authorized scope.

## Current implementation

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

Z found the original music disturbing and requested playful music with separate environment/time/season ambience and per-spell effects. The replacement uses major-key plucked notes; bird, cricket, and echoed water layers have independent loop lengths and smooth transitions. Spring is still the active map season. Other seasonal and cave profiles are ready and tested, without implementing new calendar or cave gameplay.

## Next discussion

Play and critique the slice before expanding it. Decide the next milestone, combat controls and feel, art direction, calendar/lunar rules, and the first actual networked cooperative interaction. Do not mistake placeholder content for approved final story or mechanics.
