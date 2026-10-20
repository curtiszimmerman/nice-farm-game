# First landing: native Debian prototype

Somewhere, the Sun Still Rises is a small native Godot game. It runs directly on the host with the OpenGL Compatibility renderer. There is no browser or web server involved in playing.

## Playing

New visits open at 09:00 on Spring 01 with a ship battle. Individual laser shots leave gaps between volleys and burst against each hull. Every introductory line waits for a click, E or Space; stars and ships keep animating while you read. The final impact fade waits until the captain's order is acknowledged. The attacker explodes, but the crew must crash-land. Vale warns that it sent a signal; the captain prioritizes the cloak. Time remains halted until you leave the ship. Follow the mountain descent to Moss, already waiting at its foot. He asks about the flash and crash, then offers the abandoned farmhouse. Accepting follows the faint path around the house and inside without releasing control or the clock.

Your first entry into the farmhouse begins a required welcome sequence. Finish removing all covers and replacing both bulbs. After a short pause, the visitors walk over and enter through the door. You cannot leave during this first visit. Neral remains suspicious about your arrival and the flash on the mountain. Alder and Neral walk out after the meeting; Moss stays to explain farming and recommend Iona's tower. Movement and the clock resume after Moss leaves too.

The farmhouse initially has dusty covers on the sofa, both beds and radio. Press E at each furnishing to remove its cover. Take the two spare bulbs from the kitchen cabinet, then press E at the broken living-room and bathroom lights. The crew log tracks the remaining jobs. Alder offers permission to stay if you promise to keep the house clean, and suggests working the garden to support yourselves.

Town has a cobbled square with a fountain, nearby homes, and the provisions shop. Tavi works inside his grocery from 08:00–20:00 with lunch and walks. Finch spends his workday inside the Radio Club, moving between equipment and shelves. Moss tends his decorative southern fields; those crops cannot be harvested by the player. The wizard wakes at noon and sleeps before sunrise. Sleeping residents can be seen in their own bedrooms. The mayor's appointment still takes priority.

Press E beside a door to enter its separate furnished interior; press E at the front exit to return outside. Each building has a distinct compact plan. Bathrooms are private rooms entered from halls. The shop has stock shelves and a storeroom, the club has a workshop and reception, and the tower has a small study. Homes have appropriately sized beds, seating, kitchens and personal belongings. Bram lives in an unmarked log cabin in the southern woods, without a road to his door, with a small decorative garden outside. Talk to him about his army service and the other kingdom, and accept your first rusty sword. Exits check for a clear outdoor landing tile, including beside the shop wagon.

Press I for the satchel. Hover for details; left-click selects and highlights an item without consuming it. Its picture appears in the separate active-item display between the health bars and quick slots. Drag a carried item onto one of the eight quick slots to assign it; 1–8 selects those shortcuts. Right-click food for Eat, or an elixir for Drink. The active tool must be carried: hoe to till, seeds to plant, watering can to water, sickle to harvest, sword to equip, axe to chop. Assign Wildgrowth through Actions → Spells and skills. Turnips restore 8 HP and 12 energy; silverfin restores 5 HP and 8 energy; star bulbs restore 15 mana; health elixirs restore 25 HP. Food is kept if all relevant resources are full. HP and energy cap at 100, mana at 60. The camera remains at 1.9125×.

Your satchel has twelve slots; the farmhouse chest has eighteen, and the kitchen cabinet and ship locker each have twelve. Quick slots start empty and clear when their carried stack is depleted. Starting seeds are in the chest with the tools; the can is empty. Quantities appear only above one. Storage offers quantity selection and whole-stack swaps.

Click the farmhouse oven while standing nearby, or press E beside it, to cook. Its menu expands according to cookware physically present in your satchel or kitchen cabinet. A pan enables fish sticks (one fish); a pot enables fish stew (one fish, one moon turnip, one star bulb). Neither needs a quick slot. Cookware in the outdoor chest or ship does not enable oven recipes. Ingredients come from carried supplies and the kitchen cabinet. Tavi sells each utensil for 20 crowns and health elixirs for 15 crowns.

Rustic 16-pixel artwork is the default. Settings → Artwork also offers the 32-pixel modular pack, the preserved original artwork, and installed player packs. Houses, trees, cliffs, furniture, actors and other objects use the atlas; see [ART.md](ART.md) for component rules, pack installation and reproducible asset builders. Status notifications use a compact framed panel.

Enter the cloaked ship through its southern hatch. Vale works in engineering among damaged equipment, hanging sparking cables and three glitching displays. The crew section has usable bunks and a twelve-slot supply locker with six rations. Vale consumes one ration per new day, then a cooked fish-sticks or fish-stew meal when rations are gone. Leave meals in that locker. A late delivery feeds him that day if he has not eaten. Missed meals appear in the crew log and dialogue; there is no starvation penalty in this slice.

The project-local launcher is `scripts/play.sh`. It starts the pinned Godot executable under `vendor/godot/`. F11 toggles fullscreen. The game opens at its title screen.

| Control | Action |
| --- | --- |
| WASD / arrows | Walk |
| Shift | Run |
| Click / E / Space during the introduction | Advance the current dialogue step |
| Space during ordinary play | Pause / resume the world |
| 1–8 | Select quick slot |
| E | Enter/leave buildings, talk, tend soil, gather, fish, or rest |
| Q / right mouse | Use the auxiliary item, spell or skill |
| I | Satchel |
| J | Crew notes and objectives |
| M | Local directions |
| Escape | Close a window / game menu |
| F11 | Fullscreen / windowed |

E / left mouse uses the primary assignment or nearby interaction. Q / right mouse uses the auxiliary assignment. Drag carried items or known spells/skills onto either active slot or any quick slot. Selecting a quick slot changes the primary assignment. Key bubbles sit above the icons; stack quantities and watering-can charges sit below. Spells occupy their own learned-ability list and never consume satchel slots. The inventory includes a character silhouette with head, chest, arms, hands, legs, feet, necklace and two ring slots, reserved for future equipment.

Escape opens a short game menu with Controls, Settings, Development, Save and Quit submenus. Controls lets you rebind keys; conflicting bindings swap, and preferences are stored in `internal/controls.cfg`. Single-player menus and conversations pause the entire world by default. Settings retains the other clock policies for deliberate selection.

The bottom Actions button groups inventory, spells, notes, map and settings. Health, energy and mana sit left of the two active slots and eight quick slots. This tray fades when it covers the avatar. The crew log starts collapsed under the clock and slowly pulses gold when a new quest arrives; click it to acknowledge the new quests. Status banners and interaction prompts have compact backgrounds. Music, ambience and spell effects have separate sliders under Game menu → Settings → Sound. [Sound direction and current profiles](AUDIO.md).

People take priority over nearby doorways. Walking against an NPC pushes them if the ground behind them is clear; they route around you to return to work. A conversation holds its speakers in place. Solid flowerbeds leave clear door approaches. The town fountain has an animated spray and only its base blocks walking; select Sit or interact at a bench for a seat.

East of town, Elin, Jory and Pip Reed tend two fields beside their family farmhouse. Northeast, Tomas and Mara Bell work at their windmill; their daughter Nessa joins the radio club in the afternoon. Dain Rusk works at his smithy. Rafe Fen runs the Wayward Wren beside the square, and his childhood friend Tomas visits in the evening. Corin Hale's bakery connects the farmers, millers, Moss and Rafe through bread and conversation. Each new building has its own furnished interior; family members sleep in assigned beds.

## A good first visit

1. Complete the ship briefing, follow the mountain descent to Moss, and enter the farmhouse. Remove every cover and install both cabinet bulbs. Meet the mayor and Neral, then hear Moss's farming advice after they leave. Time is held throughout the welcome.
2. Take the seeds, hoe, watering can and sickle from the chest outside the farmhouse. Assign them to quick slots yourself. Face the adjacent garden square and select the appropriate slot before pressing E. Tilling costs 2 energy, watering 1, harvesting 1. Watered soil turns dark brown, including beneath crops. The can starts empty and holds twenty charges; select it and press E on the pond shoreline to refill. Every dock square offers fishing, including with the can selected. Energy restores through food or rest in a farmhouse bed or ship bunk.
3. Meet Tavi inside the grocery; his wagon stands beside it. Ask him where to find tools: Rowan the forest woodcutter offers an axe, Bram offers a sword, and Dain offers a spare pickaxe inside the smithy. Visit Iona's northern tower to learn Wildgrowth free, then assign the spell yourself. You cannot cast before learning. Iona explains regional magic and the unusual components she wants for further lessons.
4. Fish from the pond jetty. E casts; E again reels in while the marker crosses the gold band. Hard fish move faster and more erratically. Misses cost no bait. The southern ocean and dock have been removed.
5. Enter the copper cave southeast of town. Search the four-slot barrel just inside, take its pickaxe, then assign and select it. Press E beside rocks to mine stone or copper for five energy. Bring Vale three copper. Rats approach within five tiles and bite for four HP. Bram's selected rusty sword swings with E for two energy; two hits defeat a rat. If overwhelmed, you stagger to the cave entrance with 25 HP. These combat values are provisional.
6. After the welcome, keep the house clean and work the garden. Ordinary conversations follow your chosen time policy. Tavi keeps selling after closing while his dialogue stays open.

| Water | Fish | Difficulty | Sale value |
| --- | --- | --- | --- |
| Pond | Silverfin | Easy | 10 crowns |
| Pond | Moon pike | Hard | 35 crowns |
| Ocean shore / stone jetty | Sea sprat | Easy | 12 crowns |
| Ocean shore / stone jetty | Blue mackerel | Easy | 16 crowns |
| Ocean shore / stone jetty | Storm eel | Hard | 50 crowns |
| Sea end of stone jetty only | Lantern ray | Hard, rare | 90 crowns |

Shore fishing works along reachable pond and ocean banks. Follow the faint western path from the farm to the stone jetty. Oren, a friendly old keeper, lives in the lighthouse at its sea end and needs firewood. Ask Rowan, the woodcutter in the southern forest, for an axe. Three blows fell a tree and yield three wood; each blow costs four energy. Bring six wood to Oren for 25 crowns, once. The town square bulletin board also lists the job. Tree clearings persist when reloading. Cooking accepts every fish species from your satchel and kitchen cabinet.

The cave's rooms and passages are generated once per new visit and preserved by their saved seed. Mined rocks, defeated rats, the barrel and the deep Cave Moth Chrysalis persist. A Golden Sparkfire plant grows near Iona's tower; its flower opens from 05:30–07:00 during sunrise, with one bloom available per day. Components are available for future advanced lessons; only Wildgrowth is currently taught.

The clock runs through midnight and conversations by default. One real second is three game minutes; a full ordinary day is eight real minutes. Rest speeds up the continuous clock. Crops mature three game days after watering. Wildgrowth can mature a watered crop immediately for 15 mana. There is no hard day transition or mandatory bedtime.

Night shifts the world into a blue moonlit palette while interface colors stay readable. Houses and trees fade when their drawn shape covers the avatar, then return to opaque when you step clear. Village dirt roads have connected junctions, worn shoulders, and wheel tracks.

The mainland occupies 120 × 90 tiles; a 28-tile extension west adds the coast and lighthouse, for a total extent of 148 × 90. The farmhouse lies west of town, the hidden ship northwest, the wizard's tower far north, and copper caves southeast. Faint paths lead west to the jetty and south around the pond to Bram's cabin. The stone town hall has a civic banner; Alder and his assistant Neral work there and sleep in separate homes. Briar Glen belongs to Aldermere; Veyr lies across the politically troubled border.

Each visit has saved seeds for its natural scenery and caves. Grass variants, tree and bush placement, interior floor variation, room sizes, branching passages and deposits vary while doors, plots, paths and key landmarks remain usable. Mining or felling a tree does not move the remaining resources on reload. The current save schema is version 10; older unsupported saves are preserved rather than automatically migrated.

The map is populated on a shared invisible 32-pixel tile grid, including buildings, trees, resources, roads, and farm plots. Walking stays smooth between tiles. Objects occupy whole-tile collision footprints; the round tower uses a square base independent of its drawing height. Farm gates and the fishing jetty remain walkable. [World grid details](WORLD_GRID.md).

Three menu-time modes are in settings. Calendar-only pause allows active simulation such as attunement recovery while crops and appointments wait. Full pause stops simulation; decorative rendering continues. The local interacting player remains in their menu. Multiplayer is not implemented yet.

## Development shortcuts

Development builds move three times faster: walking at 315 world units/second and running at 480. Release exports retain the original speeds.

Open Escape → Development tools to advance by 1 hour, 12 hours, 24 hours, or 1 season. These controls work even with menu time paused, advance actual crops and appointments, and save the resulting state. They stop an active rest or gathering action. The tools are hidden in release builds.

One season provisionally means 28 days. Season jumps preserve the time of day and day within the season. Seasonal scenery and audio follow spring, summer, autumn, and winter. The calendar ring shows seven symbol days around the season icon, with the date and clock alongside. Purple Sael orbits in 56 days and white Iri in 28; the phase preview uses illumination relative to the 112-day year, pending confirmation. Lunar spell effects and full seasonal gameplay remain future work.

Crew Log starts collapsed and pulses bright gold when a quest is added. Click it to acknowledge new quests; click individual quest titles to expand descriptions and checklists. The farmhouse checklist groups furniture covers separately from lightbulbs. Once both are finished, the mayor group starts its arrival after a four-second pause. Central town streets and door approaches are paved; routes out to farms remain dirt. Residential yards have open gates. Tavern customers enter the taproom directly; its rear apartment is private.

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
