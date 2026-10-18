# First landing: native Debian prototype

Somewhere, the Sun Still Rises is a small native Godot game. It runs directly on the host with the OpenGL Compatibility renderer. There is no browser or web server involved in playing.

## Playing

Town now has a paved square with a fountain, nearby homes, and the provisions shop. Villagers walk between their daily stops. Tavi opens 08:00–20:00, takes lunch 12:30–13:00, and walks around before and after work. Iona wakes at noon and sleeps around 05:00 in the coastal tower northeast of town. Most neighbors wake 06:00–07:00 and sleep 22:00–23:00. Sleeping villagers disappear inside their homes; interiors are not yet playable. The map menu includes the new landmarks.

The project-local launcher is `scripts/play.sh`. It starts the pinned Godot executable under `vendor/godot/`. F11 toggles fullscreen. The game opens at its title screen.

| Control | Action |
| --- | --- |
| WASD / arrows | Walk |
| Shift | Run |
| E | Talk, tend soil, gather, fish, or rest |
| Q | Wildgrowth on a nearby watered crop |
| I | Satchel |
| J | Crew notes and objectives |
| M | Local directions |
| Escape | Close a window / settings |
| F11 | Fullscreen / windowed |

The bottom action buttons also work with the mouse. Music, environmental ambience, and spell effects have separate sliders under Settings → Sound. Audio starts when you enter the game. [Sound direction and current profiles](AUDIO.md).

## A good first visit

1. Walk east to Moss, the farmer at your gate, and press E. Agree to meet the mayor tomorrow at noon.
2. Tend the garden southwest of the house. Face the adjacent square you want to work; the highlight, E actions, and Q spell all target that square. E tills, plants, waters, and harvests. Q grows a watered crop immediately, using regenerating attunement.
3. Follow the lane east into town. Meet Tavi at the market cart and sell your turnips. Iona and Finch have things to say, too.
4. Follow the south lane west to fish from the pond jetty. E casts; E again reels in while the meter is between 35 and 70. Misses cost no bait.
5. Find the quiet copper seam southeast of town. Bring three copper to Chief Vale in the hidden clearing northwest of your farm.
6. At the farmhouse door, choose rest until the appointment. The world advances continuously to Spring 02 at 11:45. Stay near the farmhouse for the mayor's noon visit. If you're late, the meeting remains available.

The clock runs through midnight and conversations by default. One real second is three game minutes; a full ordinary day is eight real minutes. Rest speeds up the continuous clock. Crops mature three game hours after watering. There is no hard day transition or mandatory bedtime.

Night shifts the world into a blue moonlit palette while interface colors stay readable. Houses and trees fade when their drawn shape covers the avatar, then return to opaque when you step clear. Village dirt roads have connected junctions, worn shoulders, and wheel tracks.

The map is populated on a shared invisible 32-pixel tile grid, including buildings, trees, resources, roads, and farm plots. Walking stays smooth between tiles. Objects occupy whole-tile collision footprints; farm gates and the fishing jetty remain walkable. [World grid details](WORLD_GRID.md).

Three menu-time modes are in settings. Calendar-only pause allows active simulation such as attunement recovery while crops and appointments wait. Full pause stops simulation; decorative rendering continues. The local interacting player remains in their menu. Multiplayer is not implemented yet.

## Development shortcuts

Development builds move three times faster: walking at 315 world units/second and running at 480. Release exports retain the original speeds.

Open Escape → Development tools to advance by 1 hour, 12 hours, 24 hours, or 1 season. These controls work even with menu time paused, advance actual crops and appointments, and save the resulting state. They stop an active rest or gathering action. The tools are hidden in release builds.

One season provisionally means 28 days. Season jumps preserve the time of day and day within the season. The calendar label and environmental audio follow spring, summer, autumn, and winter; final season length, seasonal art, and seasonal gameplay remain undecided.

## Saves and files

All writes stay inside this project. Saves live at `internal/first-landing.json`; runtime logs, cache, configuration, and temporary files live in `internal/runtime/`. The launcher sets XDG paths and TMPDIR before starting the engine. Use the launcher to preserve that behavior.

Progress autosaves every twelve seconds, at milestones, and on exit. Settings includes manual saving and a confirmed reset. Saving uses a temporary file and rename. Invalid saves are preserved and automatic saving is disabled until a new visit is explicitly confirmed. Runtime and vendor directories are ignored by Git.

## What this is

A single-player atmosphere and interaction study. Names, dialogue, crop timing, art, and the working title are provisional.

Included: exploration, farming, growth magic, inventory, trading, fishing, safe mining, a crew-link repair errand, day/night lighting, a scheduled introduction, menu-time settings, native saving, playful music, environmental ambience, and Wildgrowth audio.

Network play, combat, cooking, relationships, full seasonal gameplay and lunar magic, the 52-person town, and the later attack-ship storyline remain future work. The calendar uses a provisional 28-day season for development; terrain and crops do not yet change seasonally. The copper errand is a small prototype objective, not a finalized main-story repair chain. The three pause modes are exercised locally; their multiplayer behavior is not yet proven.

## Development and checks

Godot 4.5.1, Linux x86-64, official executable:

`vendor/godot/Godot_v4.5.1-stable_linux.x86_64`

Its archive was verified against the release's SHA-512 checksum file. Both remain under `vendor/godot/`. Engine source and license: [Godot](https://github.com/godotengine/godot/tree/4.5.1-stable). The project requires no third-party game assets or libraries.

```sh
bash scripts/check.sh
bash scripts/play.sh --headless --script ../../tests/native/state_test.gd
bash scripts/play.sh --headless --script ../../tests/native/integration_test.gd
bash scripts/play.sh --headless --script ../../tests/native/save_test.gd
bash scripts/play.sh --headless --script ../../tests/native/audio_test.gd
bash scripts/play.sh --headless -- --smoke-test
bash scripts/play.sh --script ../../tests/native/visual_test.gd
```

The last command briefly uses the host display to capture native screenshots into `internal/verification/`, checks optional audio start/stop, and exits. It uses a fresh in-memory game without touching the real save. Headless checks cover simulation, actual interface choices, resource transactions, scheduled events, layout regressions, and reachability of every interaction destination.

The native build has been rendered on the development host's Quadro P3200. Performance on the target GeForce 940MX is still unverified.

The development helper `scripts/restart.py` sends the normal close request to existing game windows on the current X11 desktop, waits for them to save and close, and starts the updated native build. It preserves the gameplay save and writes its launch log inside `internal/runtime/`.
