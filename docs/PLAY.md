# First landing: native Debian prototype

Somewhere, the Sun Still Rises is a small native Godot game. It runs directly on the host with the OpenGL Compatibility renderer. There is no browser or web server involved in playing.

## Playing

Town has a cobbled square with a fountain, nearby homes, and the provisions shop. Tavi works at his market cart from 08:00–20:00 with lunch and walks. Finch spends his workday inside the Radio Club, moving between equipment and shelves. Moss tends his decorative southern fields; those crops cannot be harvested by the player. The wizard wakes at noon and sleeps before sunrise. Sleeping residents can be seen in their own bedrooms. The mayor's appointment still takes priority.

Press E beside a door to enter its separate furnished interior; press E at the front exit to return outside. Each building has a distinct compact plan. Bathrooms are private rooms entered from halls. The shop has stock shelves and a storeroom, the club has a workshop and reception, and the tower has a small study. Homes have appropriately sized beds, seating, kitchens and personal belongings. Bram lives in an unmarked log cabin in the southern woods, without a road to his door, with a small decorative garden outside. Talk to him about his army service and the other kingdom, and accept your first rusty sword. Exits check for a clear outdoor landing tile, including beside the shop wagon.

Press I for the satchel. Hover for details; click an item to save it to a quick slot. Right-click food for Eat, or an elixir for Drink. Select one of eight quick slots with 1–8 or the mouse. The selected tool must also be carried: hoe to till, seeds to plant, watering can to water, sickle to harvest, sword to equip. Assign Wildgrowth through Actions → Spells and skills. Turnips restore 8 HP and 12 energy; silverfin restores 5 HP and 8 energy; star bulbs restore 15 mana; health elixirs restore 25 HP. Food is kept if all relevant resources are full. HP and energy cap at 100, mana at 60. The camera remains at 1.9125×.

The farmhouse chest has eighteen storage slots; the kitchen cabinet and ship locker each have twelve. Select a carried stack and a storage slot to deposit, or click a stored stack to withdraw. A quantity chooser offers a number or the full stack. Swapping different item types requires the whole carried stack. The kitchen stove draws ingredients from both the satchel and cabinet. Buy Tavi's pan to unlock fish sticks (one fish), or his pot to unlock fish stew (one fish, one moon turnip, one star bulb). Each utensil costs 20 crowns; storing it keeps the recipe unlocked. Tavi also sells health elixirs for 15 crowns.

Enter the cloaked ship through its southern hatch. Vale works in engineering among damaged equipment, hanging sparking cables and three glitching displays. The crew section has usable bunks and a twelve-slot supply locker with six rations. Vale consumes one ration per new day, then a cooked fish-sticks or fish-stew meal when rations are gone. Leave meals in that locker. A late delivery feeds him that day if he has not eaten. Missed meals appear in the crew log and dialogue; there is no starvation penalty in this slice.

The project-local launcher is `scripts/play.sh`. It starts the pinned Godot executable under `vendor/godot/`. F11 toggles fullscreen. The game opens at its title screen.

| Control | Action |
| --- | --- |
| WASD / arrows | Walk |
| Shift | Run |
| 1–8 | Select quick slot |
| E | Enter/leave buildings, talk, tend soil, gather, fish, or rest |
| Q | Wildgrowth, when its quick slot is selected |
| I | Satchel |
| J | Crew notes and objectives |
| M | Local directions |
| Escape | Close a window / settings |
| F11 | Fullscreen / windowed |

The bottom Actions button groups inventory, spells, notes, map and settings. Health, energy and mana sit left of the eight quick slots. The crew log is collapsible under the clock at the upper right. Music, ambience and spell effects have separate sliders under Actions → Settings → Sound. [Sound direction and current profiles](AUDIO.md).

## A good first visit

1. Walk east to Moss, the farmer at your gate, and press E. Agree to meet the mayor tomorrow at noon.
2. Take the hoe, watering can and sickle from the chest outside the farmhouse. Face the adjacent garden square and select the appropriate quick slot before pressing E. Tilling costs 2 energy, watering 1, harvesting 1. The can holds twenty charges; select it and press E at the pond jetty to refill. Select another slot to fish. Energy restores through food or rest in a farmhouse bed or ship bunk.
3. Follow the lane east into town. Meet Tavi at the market cart and sell your turnips. Iona and Finch have things to say, too.
4. Follow the south lane west to fish from the pond jetty. E casts; E again reels in while the meter is between 35 and 70. Misses cost no bait.
5. Find the quiet copper seam southeast of town. Bring three copper to Chief Vale inside the cloaked ship northwest of your farm.
6. Use the farmhouse bed to rest until the appointment. Moss, Alder and Neral arrive around ten and wait until four the day after the invitation. The introduction begins at noon; an unfinished conversation holds them in place until completed or abandoned.

The clock runs through midnight and conversations by default. One real second is three game minutes; a full ordinary day is eight real minutes. Rest speeds up the continuous clock. Crops mature three game days after watering. Wildgrowth can mature a watered crop immediately for 15 mana. There is no hard day transition or mandatory bedtime.

Night shifts the world into a blue moonlit palette while interface colors stay readable. Houses and trees fade when their drawn shape covers the avatar, then return to opaque when you step clear. Village dirt roads have connected junctions, worn shoulders, and wheel tracks.

The 120 × 90 tile map has four times its original area. The farmhouse lies west of town, the hidden ship northwest, the wizard's tower far north, and the copper cave far southeast. The eastern ocean has been removed. The radio is on a table directly outside the Radio Club. Fishing works along the full dock.

The map is populated on a shared invisible 32-pixel tile grid, including buildings, trees, resources, roads, and farm plots. Walking stays smooth between tiles. Objects occupy whole-tile collision footprints; the round tower uses a square base independent of its drawing height. Farm gates and the fishing jetty remain walkable. [World grid details](WORLD_GRID.md).

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

Network play, combat, relationships, full seasonal gameplay and lunar magic, the 52-person town, and the later attack-ship storyline remain future work. The calendar uses a provisional 28-day season for development; terrain and crops do not yet change seasonally. The copper errand is a small prototype objective, not a finalized main-story repair chain. The three pause modes are exercised locally; their multiplayer behavior is not yet proven.

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
