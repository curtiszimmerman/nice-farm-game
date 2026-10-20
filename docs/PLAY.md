# First landing: native Debian prototype

Somewhere, the Sun Still Rises is a small native Godot game. It runs directly on the host with the OpenGL Compatibility renderer. There is no browser or web server involved in playing.

## Playing

New visits open at 09:00 on Spring 01 with an animated ship attack, emergency landing and Vale's status report. Time remains halted until you first leave the ship. Bunks and supplies are in the upper rear; damaged machinery is in front. Follow the single mountain descent and longer meadow approach. Coming around either side of the farmhouse forces an on-screen meeting with Moss. He asks about the mountain flash and crash, wonders about spellcasting and asks if you are travelers. The captain reacts with surprise and asks about lodging. Moss offers the abandoned farmhouse while he fetches Alder and Neral; this dialogue also holds time.

Your first entry into the farmhouse begins a required welcome sequence. Finish removing all covers and replacing both bulbs; the visitors arrive eight real seconds after the house is ready. You cannot leave during this first visit. All three visitors meet you inside. Alder and Neral leave after the meeting; Moss stays to explain farming and recommend Iona's tower. Finish his advice to resume movement and the normal clock.

The farmhouse initially has dusty covers on the sofa, both beds and radio. Press E at each furnishing to remove its cover. Take the two spare bulbs from the kitchen cabinet, then press E at the broken living-room and bathroom lights. The crew log tracks the remaining jobs. Alder offers permission to stay if you promise to keep the house clean, and suggests working the garden to support yourselves.

Town has a cobbled square with a fountain, nearby homes, and the provisions shop. Tavi works at his market cart from 08:00–20:00 with lunch and walks. Finch spends his workday inside the Radio Club, moving between equipment and shelves. Moss tends his decorative southern fields; those crops cannot be harvested by the player. The wizard wakes at noon and sleeps before sunrise. Sleeping residents can be seen in their own bedrooms. The mayor's appointment still takes priority.

Press E beside a door to enter its separate furnished interior; press E at the front exit to return outside. Each building has a distinct compact plan. Bathrooms are private rooms entered from halls. The shop has stock shelves and a storeroom, the club has a workshop and reception, and the tower has a small study. Homes have appropriately sized beds, seating, kitchens and personal belongings. Bram lives in an unmarked log cabin in the southern woods, without a road to his door, with a small decorative garden outside. Talk to him about his army service and the other kingdom, and accept your first rusty sword. Exits check for a clear outdoor landing tile, including beside the shop wagon.

Press I for the satchel. Hover for details; click an item to save it to a quick slot. Right-click food for Eat, or an elixir for Drink. Select one of eight quick slots with 1–8 or the mouse. The selected tool must also be carried: hoe to till, seeds to plant, watering can to water, sickle to harvest, sword to equip. Assign Wildgrowth through Actions → Spells and skills. Turnips restore 8 HP and 12 energy; silverfin restores 5 HP and 8 energy; star bulbs restore 15 mana; health elixirs restore 25 HP. Food is kept if all relevant resources are full. HP and energy cap at 100, mana at 60. The camera remains at 1.9125×.

Your satchel has twelve slots. The farmhouse chest has eighteen storage slots; the kitchen cabinet and ship locker each have twelve. Quick slots start empty; collecting an item never assigns it automatically. Starting seeds are in the chest with the tools, and the watering can is empty. Stack quantities appear only above one. Select a carried stack and a storage slot to deposit, or click a stored stack to withdraw. A quantity chooser offers a number or the full stack; single items transfer directly. Swapping different item types requires the whole carried stack. The kitchen stove draws ingredients from both the satchel and cabinet. Buy Tavi's pan to unlock fish sticks (one fish), or his pot to unlock fish stew (one fish, one moon turnip, one star bulb). Each utensil costs 20 crowns; storing it keeps the recipe unlocked. Tavi also sells health elixirs for 15 crowns.

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

1. Complete the ship briefing, follow the mountain descent to Moss, and enter the farmhouse. Remove every cover and install both cabinet bulbs. Meet the mayor and Neral, then hear Moss's farming advice after they leave. Time is held throughout the welcome.
2. Take the seeds, hoe, watering can and sickle from the chest outside the farmhouse. Assign them to quick slots yourself. Face the adjacent garden square and select the appropriate slot before pressing E. Tilling costs 2 energy, watering 1, harvesting 1. The can starts empty and holds twenty charges; select it and press E at the pond jetty to refill. Select another slot to fish. Energy restores through food or rest in a farmhouse bed or ship bunk.
3. Meet Tavi at the market cart. Visit Iona's northern tower to learn Wildgrowth free, then assign the spell yourself. You cannot cast before learning. Iona explains regional magic and the unusual components she wants for further lessons.
4. Fish from the pond jetty. E casts; E again reels in while the marker crosses the gold band. Hard fish move faster and more erratically. Misses cost no bait. The southern ocean and dock have been removed.
5. Enter the copper cave southeast of town. Search the four-slot barrel just inside, take its pickaxe, then assign and select it. Press E beside rocks to mine stone or copper for five energy. Bring Vale three copper. Rats approach within five tiles and bite for four HP. Bram's selected rusty sword swings with E for two energy; two hits defeat a rat. If overwhelmed, you stagger to the cave entrance with 25 HP. These combat values are provisional.
6. After the welcome, keep the house clean and work the garden. Ordinary conversations follow your chosen time policy. Tavi keeps selling after closing while his dialogue stays open.

| Water | Fish | Difficulty | Sale value |
| --- | --- | --- | --- |
| Pond | Silverfin | Easy | 10 crowns |
| Pond | Moon pike | Hard | 35 crowns |

Coastal fish remain in the item catalog without a playable location. Cooking accepts any fish species from your satchel and connected kitchen cabinet.

The cave's rooms and passages are generated once per new visit and preserved by their saved seed. Mined rocks, defeated rats, the barrel and the deep Cave Moth Chrysalis persist. A Golden Sparkfire plant grows near Iona's tower; its flower opens from 05:30–07:00 during sunrise, with one bloom available per day. Components are available for future advanced lessons; only Wildgrowth is currently taught.

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

Included: exploration, farming, a free first magic lesson, inventory, trading, pond fishing, generated caves, pickaxe mining, basic rat combat, a crew-link repair errand, day/night lighting, a staged introduction, native saving, and layered audio.

Network play, broader combat, relationships, advanced spells, full seasonal gameplay and lunar magic, the 52-person town, and the later attack-ship storyline remain future work. The calendar uses a provisional 28-day season. The three pause modes are exercised locally; multiplayer remains unproven.

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
