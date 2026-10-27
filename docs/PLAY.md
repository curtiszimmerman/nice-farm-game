# First landing: native Debian prototype

Somewhere, the Sun Still Rises is a small native Godot game. It runs directly on the host with the OpenGL Compatibility renderer. There is no browser or web server involved in playing.

## Playing

New journeys first offer a gentler or hardcore mode, then open at 09:00 on Spring 01 with a ship battle. Hardcore adds water and food bars. Drink from the pond edge or face the town fountain and choose Drink; a health elixir also fully hydrates. A prepared meal fully restores nourishment. Three days without water or twenty-one without a meal blocks all energy and mana recovery, including sleep, and costs ten HP each hour. Settings can toggle hardcore during play. Individual laser shots leave gaps between volleys and burst against each hull. Buttonless cinematic captions wait for a click, E or Space; dialogue with a visible choice or Continue button requires clicking that button. Stars and ships keep animating while you read. The final impact fade waits until the captain's order is acknowledged. The attacker explodes, but the crew must crash-land. Vale warns that it sent a signal; the captain prioritizes the cloak. With scanners dead and the crew link down, he can only suggest that the settlement might have a metalworker. Time remains halted until you leave the ship. Follow the mountain descent to Moss, already waiting at its foot. He asks about the flash and crash, then offers the abandoned farmhouse. Accepting follows the faint path around the house and inside without releasing control or the clock.

Your first entry into the farmhouse begins a required welcome sequence. Finish removing all covers and replacing both bulbs. The visitors approach during cleanup, then enter one at a time after a one-second pause. The ordinary HUD stays hidden throughout their arrival and meeting. You cannot leave during this first visit. Neral remains suspicious about your arrival and the flash on the mountain. Alder and Neral walk out after the meeting; Moss stays to explain farming and recommend Iona's tower. Movement and the clock resume after Moss leaves too.

The farmhouse initially has dusty covers on the sofa, both beds and radio. Press E at each furnishing to remove its cover. Take the two spare bulbs from the kitchen cabinet, then press E at the broken living-room and bedroom lamps. The crew log tracks the remaining jobs. Alder offers permission to stay if you promise to keep the house clean, and suggests working the garden to support yourselves.

Town has a cobbled square with a fountain, nearby homes, and the provisions shop. Shopkeepers generally work from morning until sundown, with Tavi taking a short lunch break. Finch works inside the Radio Club; Moss tends his decorative fields. Residents visit the tavern on different weekday schedules, usually for two or three hours after sunset. Rafe closes at midnight. Everyone sleeps at night except Iona; Corin rises at four to bake. Sleeping households lock their exterior doors. A loved relationship permits late visits, and leaving is always allowed. Quest rewards improve friendship; rude dismissal can reduce it. The mayor's appointment takes priority.

Brother Aven tends the temple south of town hall and its small bee garden. His one-room home is west of the temple, with a separate outhouse. He never visits the tavern. He teaches beehive plans for two silver ingots; construction, honey and beeswax production remain future work. Later blueprints may have explicit year gates. Tavi's seasonal delivery contains twenty moon-turnip seed packets, twelve star-bulb packets, ten elixirs, one pan and one pot. Every offer lists remaining stock and replenishes at the next 28-day season.

Press E beside a door to enter its separate furnished interior; press E at the front exit to return outside. Each building has a distinct compact plan. Bathrooms are private rooms entered from halls. The shop has stock shelves and a storeroom, the club has a workshop and reception, and the tower has a small study. Homes have appropriately sized beds, seating, kitchens and personal belongings. Bram lives in an unmarked log cabin in the southern woods, with a small decorative garden outside. Talk about the mines to arrange a trade: three moon turnips for his rusty sword. He loves turnip gifts and retains his stories about Veyr. Exits check for a clear outdoor landing tile, including beside the shop wagon.

Press I for the satchel. Hover for details; left-click selects and highlights an item without consuming it. Its picture appears in the separate active-item display between the health bars and quick slots. Drag a carried item onto one of the eight quick slots to assign it; 1–8 selects those shortcuts. Right-click food for Eat, or an elixir for Drink. The active tool must be carried: hoe to till, seeds to plant, watering can to water, sickle to harvest, sword to equip, axe to chop. Assign Wildgrowth through Actions → Spells and skills. Turnips restore 8 HP and 12 energy; silverfin restores 5 HP and 8 energy; star bulbs restore 15 mana; health elixirs restore 25 HP. Food is kept if all relevant resources are full. HP and energy cap at 100, mana at 60. The camera remains at 1.9125×.

Your satchel has sixteen slots in two rows of eight; the farmhouse chest has eighteen, and the kitchen cabinet and ship locker each have twelve. New stacks fill the first empty slot; drag to reorder them. With the inventory closed, Tab switches which row appears in the eight quickslots. Spell shortcuts can occupy these positions without becoming counted items. Drag between storage and the satchel to transfer, choosing a quantity for stacks. Whole stacks can swap with occupied slots. Starting seeds are in the chest with the tools; the can is empty. Quantities appear only above one. Equipment is on the left, supplies above the spell list, and the People tab lists portraits of everyone you have met and their relationship status.

Corin sells fresh bread inside his bakery for six crowns. A loaf restores twenty base energy. After one full day without six continuous hours of sleep, a Zzz indicator appears: energy costs multiply by n+1 and energy recovery divides by n+1, where n is the number of full days since restorative sleep. Six consecutive game hours asleep clears tiredness. Short naps do not postpone the elapsed-day count. Food HP and mana gains stay unchanged.

The final cave chamber has a spider guarding the chrysalis. It takes four sword hits and each bite has a twenty-percent chance to poison you. Poison's purple skull has pulsing red eyes; hover for its remaining duration. It deals two HP every five game minutes for one hour. Another bite can refresh the duration, but does not stack damage or postpone the next tick. Pausing the world pauses status timers too.

Vale needs three copper bars. Trade ten carried star bulbs to Dain inside the smithy to learn the crucible blueprint. Drag it from the inventory's known abilities onto an active or quick slot. Carry ten stone, face clear ground within fifteen squares of the farmhouse, and activate the blueprint. Each crucible occupies one square. Face it to start a batch: five copper ore and two coal, thirty game minutes, one bar. Close the menu while it works, then return to collect the bar. A full satchel leaves the finished bar safely in the crucible. A selected hoe can create new farm plots on clear ground throughout the same farmhouse radius.

Click the farmhouse oven while standing nearby, or press E beside it, to cook. Its menu expands according to cookware physically present in your satchel or kitchen cabinet. A pan enables fish sticks (one fish); a pot enables fish stew (one fish, one moon turnip, one star bulb). Neither needs a quick slot. Cookware in the outdoor chest or ship does not enable oven recipes. Ingredients come from carried supplies and the kitchen cabinet. Tavi sells each utensil for 20 crowns and health elixirs for 15 crowns.

Rustic 16-pixel artwork is the default. Settings → Artwork also offers the 32-pixel modular pack, the preserved original artwork, and installed player packs. Houses, trees, cliffs, furniture, actors and other objects use the atlas; see [ART.md](ART.md) for component rules, pack installation and reproducible asset builders. Status notifications use a compact framed panel.

Connected terrain borders now follow neighboring grid cells, including diagonal corners, and select seasonal/weather artwork. Paving and the stone jetty use new material surfaces; their dedicated corner set remains on the [artwork to-do list](ART_TODO.md).

Enter the cloaked ship along its three southern boarding squares. Its hull blocks walking. Vale works in engineering among damaged equipment, hanging sparking cables and three glitching displays. The crew section has metal bunks, lockers and a worktable in the default artwork. Face any locker square to open the twelve-slot supplies with six rations. Vale consumes one prepared food item per day, preferring emergency rations first. Bread, fish dishes, preserves and cobbler also count; raw fruit and fish do not. Depositing food completes the supply milestone, which starts unfinished. A late delivery feeds him that day if he has not eaten.

Tavi sells sugar and butter; Tomas sells flour while working at the windmill. With a pot, two berries and one sugar make preserves. With a pan, preserves, flour, sugar and butter make berry cobbler. Kitchen-cabinet ingredients and cookware count together with carried supplies.

Iona explains Rift, Bough, Ember, Gale, Tide, Gleam and Veil. Favored magic is ×1.5 and weakened magic ×0.5; Gleam strengthens every school ×1.15 and Veil weakens them ×0.85. Rift chooses independent favored and weakened schools once per world/day; matching choices resolve to ×2 or zero. Hearthmend, Emberthread and Wildgrowth follow these rules. On Veil mornings, several neighbors attend Brother Aven's communion from 10:00 until noon.

Daily conversation grants one friendship point per person. With an item selected, ordinary NPC dialogue offers a weekly gift; preferences range from −5 to +5 friendship. Saeren's truth-or-lie reply records the captain's claim separately from friendship. The People tab shows portraits. Completed subtasks pulse the Crew Log until it is expanded.

Spring precipitation is 50% more frequent than summer; autumn is 50% less frequent. Winter precipitation falls as snow, with thunder permitted on only ten percent of snow days. Winter sparkblooms can be gathered all day during those rare storms. Outdoor thunder follows lightning by a varied one to three seconds. Bird crossings and birdsong are less frequent.

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

E / left mouse uses the primary assignment or nearby interaction. Q / right mouse uses the auxiliary assignment. Drag carried items or known spells/skills onto either active slot or any quick slot. Selecting a quick slot changes the primary assignment. Key bubbles sit above the icons; stack quantities and watering-can charges sit below. Spells remain weightless learned abilities; placing a shortcut uses one inventory-row position without creating a counted item. The inventory includes a character silhouette with head, chest, arms, hands, legs, feet, necklace and two ring slots, reserved for future equipment.

Escape opens a short game menu with Controls, Settings, Development, Save and Quit submenus. Controls lets you rebind keys; conflicting bindings swap, and preferences are stored in `internal/controls.cfg`. Single-player menus and conversations pause the entire world by default. Settings retains the other clock policies for deliberate selection.

The bottom Actions button groups inventory, spells, notes, map and settings. Health, energy and mana sit left of the two active slots and eight quick slots. This tray fades when it covers the avatar. The Crew Log starts collapsed on the left and pulses gold when a quest arrives or a subtask is completed; expand it to acknowledge the update. Status banners and interaction prompts have compact backgrounds. Music, ambience and spell effects have separate sliders under Game menu → Settings → Sound. [Sound direction and current profiles](AUDIO.md).

People take priority over nearby doorways. Walking against an NPC pushes them if the ground behind them is clear; they route around you to return to work. A conversation holds its speakers in place. Solid flowerbeds leave clear door approaches. The town fountain has an animated spray and only its base blocks walking; select Sit or interact at a bench for a seat.

East of town, Elin, Jory and Pip Reed tend two fields beside their family farmhouse. Northeast, Tomas and Mara Bell work at their windmill; their daughter Nessa joins the radio club in the afternoon. Dain Rusk works at his smithy. Rafe Fen runs the Wayward Wren beside the square, and his childhood friend Tomas visits in the evening. Corin Hale's bakery connects the farmers, millers, Moss and Rafe through bread and conversation. Each new building has its own furnished interior; family members sleep in assigned beds.

## A good first visit

1. Complete the ship briefing, follow the mountain descent to Moss, and enter the farmhouse. Remove every cover and install both cabinet bulbs. Meet the mayor and Neral, then hear Moss's farming advice after they leave. Time is held throughout the welcome.
2. Take the seeds, hoe, watering can and sickle from the chest outside the farmhouse. Assign them to quick slots yourself. Face the adjacent garden square and select the appropriate slot before pressing E. Tilling costs 2 energy, watering 1, harvesting 1. Watered soil turns dark brown, including beneath crops. The can starts empty and holds twenty charges; select it and press E on the pond shoreline to refill. Every dock square offers fishing, including with the can selected. Energy restores through food or rest in a farmhouse bed or ship bunk.
3. Meet Tavi inside the grocery; his wagon stands beside it. Rowan the forest woodcutter offers an axe and Bram offers a sword. Dain discusses tool upgrades at the smithy. Tavi explains that the stove uses cookware and food from either your satchel or the kitchen cabinet. Visit Iona's northern tower to learn Wildgrowth free, then assign the spell yourself. You cannot cast before learning.
4. Fish from the pond jetty. E casts; E again reels in while the marker crosses the gold band. Hard fish move faster and more erratically. Misses cost no bait. The southern ocean and dock have been removed.
5. Enter the copper cave southeast of town. On the first visit the captain notices a pickaxe leaning against the entrance barrel. Pick it up separately, then select it; the barrel has four empty storage slots. Press E beside rocks to mine stone or copper ore for five rested energy. Refine ore in your crucible and bring Vale three bars. Rats approach within five tiles and bite for four HP. Bram's selected rusty sword swings with E for two rested energy; two hits defeat a rat, four defeat the final-room spider. If overwhelmed, you stagger to the cave entrance with 25 HP. These combat values are provisional.
6. After the welcome, keep the house clean and work the garden. Ordinary conversations follow your chosen time policy. Tavi keeps selling after closing while his dialogue stays open.

| Water | Fish | Difficulty | Sale value |
| --- | --- | --- | --- |
| Pond | Silverfin | Easy | 10 crowns |
| Pond | Moon pike | Hard | 35 crowns |
| Ocean shore / stone jetty | Sea sprat | Easy | 12 crowns |
| Ocean shore / stone jetty | Blue mackerel | Easy | 16 crowns |
| Ocean shore / stone jetty | Storm eel | Hard | 50 crowns |
| Sea end of stone jetty only | Lantern ray | Hard, rare | 90 crowns |

Select a fishing pole to fish along reachable pond and ocean banks or from either dock. Follow the faint western path from the farm to the stone jetty. Oren lives in the lighthouse and needs six logs. His notice is first on the board; ask him about it to hear the reward and directions to Rowan south of Moss's farm. Rowan gives you an axe on the condition that you bring ten logs within one week, seven days. Missing the deadline costs five friendship once; the axe stays yours and late repayment is possible. Three blows fell a tree and yield three wood; each blow costs four base energy. Bring six wood to Oren for his spare pole and 25 crowns, once. Tree clearings persist when reloading. Cooking accepts every fish species from your satchel and kitchen cabinet.

Moss is the local guide: his first post-welcome topic is copper, with a warning about mine dangers and directions to Bram. He also explains the bulletin board, Rowan's axe and the missing ladder when those topics are known. Bram suggests Iona's growth magic if you are waiting for turnips; her tower is north of town, east of Saeren's observatory. Alder and Neral point newcomers toward Moss and the board. Dain offers mining advice and an alternative rusty sword for 250 crowns, or suggests asking Moss and Bram when that price is too high. Essential farming and utility tools cannot be given as gifts.

The board holds four notices. Oren's firewood request and Mrs. Bell's ladder stay until completed; available positions draw from twenty small jobs. Accept a job, carry the supplies to its author, and use their delivery dialogue. Rewards give crowns and three friendship points. Unfinished weekly jobs expire at the next week and remain in character quest history; expired and completed jobs leave the active Crew Log. Seasonal and equipment requirements filter the pool. The complete twenty-job list is in [LOCAL_GUIDANCE_WORK.md](LOCAL_GUIDANCE_WORK.md).

The copper caverns have three seeded floors, each with twelve rooms and roughly six times the previous walkable area. Stairs connect them. Deposits are about 85% stone, 10% copper and 5% coal. Cleared rocks and creatures persist, including through a JSON save. The spider guards the chrysalis on the third floor. Rare Golden Sparkfire plants are spread across reachable land; their saved locations stay fixed and flowers open from 05:30–07:00. Iona teaches Hearthmend for one bloom (15 HP for 10 mana), and Emberthread for one chrysalis plus ten wood (2 fire damage for 12 mana). Wildgrowth remains free.

The clock runs continuously through midnight. Ordinary play advances one game minute per real second; the display changes in ten-minute steps with a slowly settling pendulum swing. Single-player menus and dialogue pause by default. Rest speeds up the continuous clock. Crops mature three game days after watering. Wildgrowth can mature a watered crop immediately for 15 mana. There is no hard day transition or mandatory bedtime.

Night shifts the world into a blue moonlit palette while interface colors stay readable. Houses and trees fade when their drawn shape covers the avatar, then return to opaque when you step clear. Village dirt roads have connected junctions, worn shoulders, and wheel tracks.

The mainland occupies 120 × 90 tiles; a 28-tile extension west adds the coast and lighthouse, for a total extent of 148 × 90. The farmhouse lies west of town, the hidden ship northwest, the wizard's tower far north, and copper caves southeast. Faint paths lead west to the jetty and south around the pond to Bram's cabin. The stone town hall has a civic banner; Alder and his assistant Neral work there and sleep in separate homes. Briar Glen belongs to Aldermere; Veyr lies across the politically troubled border.

Each visit has saved seeds for its natural scenery and caves. Grass variants, tree and bush placement, interior floor variation, room sizes, branching passages and deposits vary while doors, plots, paths and key landmarks remain usable. Mining or felling a tree does not move the remaining resources on reload. Save schema 18 includes axe agreements and weekly request history; older unsupported saves are preserved rather than automatically migrated.

The Crew Log opens on the left and grows downward as questlines expand, using scrolling when the list would reach the action bar. Development → Weather selects automatic weather, sunshine, partly cloudy skies or rain. The larger calendar shows season, date, weekday/year and time in framed green windows. Mayor Alder, Moss and Neral enter the welcome meeting in a spaced procession without waiting for each visitor to finish crossing the room. The guided captain faces his walking direction; visitors turn toward him once they arrive.

Select the watering can to water any garden square, including bare ground and already wet or mature crops. Each watering still spends one charge and its normal energy cost. Around 7.5% of bushes bear spring/summer berries, and 7.5% of oak-like trees bear autumn apples. Face the trunk or bush to gather; each plant replenishes seven full days after picking. Other seasons have no harvest. Nessa borrowed Mrs. Bell's ladder for a radio aerial; search the compact tool shed east of the Bell family home and return it to Mara.

Both visible cave-mouth columns offer entry. Inside, the exit is an opening onto sky and treetops. The spider guards the final chamber's chrysalis. Golden glints appear immediately around the western jetty's sea end after 19:00 and before 06:00; lantern rays join that fishing pool during those hours, while remaining rare catches.

The farmhouse has a separate tiled kitchen and standing lamps in the bedroom and living room. Spare bulbs are in the kitchen cabinet. Quick slots reference carried stacks: moving an assignment clears its previous slot without transferring or duplicating items. The shorter HUD stays above the inventory as a drag target. Untrained players see “[ None Known ]” in the abilities list; sitting remains an ordinary bench action. Inventory has separate Inventory and Stats & Quests tabs. The latter lists experience and all assigned questlines, with active quests above completed history. Completed lines disappear from the small Crew Log.

Face physical objects to interact with the square directly ahead: doors, furniture, containers, lamps and the cave pickaxe use their actual grid footprints. The target square is visible by default; toggle it under Settings. Nearby NPCs retain priority over doors. Cutscenes hide the ordinary HUD, calendar, Crew Log and area labels. Opening inventory pauses single-player time even if Space toggles the separate manual pause.

Doorways offer both the threshold and the square beyond it, so walking onto a doorway retains the enter/exit prompt. The cave mouth is two squares wide; the bulletin board has two usable squares. Equipment slots have individual hover descriptions around the larger character figure.

Plant seeds, then water them. Each watered midnight earns one of three growth days; dry days do not count. Watered soil fades from sunset to midnight, when the next watering day begins. The daily forecast brings sunshine with ground shadows, drifting cloud shadows, or rain with a darker blue cast. Occasional lightning flashes for two rendered frames; thunder follows two real seconds later. Rain waters outdoor crops automatically. Escape → Development → Weather previews each condition or restores the daily forecast.

Defeating a rat earns 10 experience. Green experience gains and damage values rise and fade near the affected character. Experience is saved and shown in Stats & Quests.

Homes have warm windows after sunset until their residents sleep. Street lamps cast soft yellow pools from sunset to sunrise. Winter nights bring chimney smoke; the bakery and forge smoke throughout the year. Saeren's observatory stands among the northern mountain ridges. Visit its large telescope and speak with the master observer during the day or early evening.

The map is populated on a shared invisible 32-pixel tile grid, including buildings, trees, resources, roads, and farm plots. Walking stays smooth between tiles. Objects occupy whole-tile collision footprints; the round tower uses a square base independent of its drawing height. Farm gates and the fishing jetty remain walkable. [World grid details](WORLD_GRID.md).

Three menu-time modes are in settings. Calendar-only pause allows active simulation such as attunement recovery while crops and appointments wait. Full pause stops simulation; decorative rendering continues. The local interacting player remains in their menu. Multiplayer is not implemented yet.

## Development shortcuts

Development builds move three times faster: walking at 315 world units/second and running at 480. Release exports retain the original speeds.

Open Escape → Development tools to advance by 1 hour, 12 hours, 24 hours, or 1 season. These controls work even with menu time paused, advance actual crops and appointments, and save the resulting state. They stop an active rest or gathering action. The tools are hidden in release builds.

One season provisionally means 28 days. Season jumps preserve the time of day and day within the season. Seasonal scenery and audio follow spring, summer, autumn, and winter. The calendar ring shows seven symbol days around the season icon, with the date and clock alongside. Purple Sael orbits in 56 days and white Iri in 28; the phase preview uses illumination relative to the 112-day year, pending confirmation. Lunar spell effects and full seasonal gameplay remain future work.

Crew Log starts collapsed and pulses bright gold when a quest is added. Click it to acknowledge new quests; click individual quest titles to expand descriptions and checklists. The farmhouse checklist groups furniture covers separately from lightbulbs. Once both are finished, the mayor group starts its arrival after a one-second pause. Central town streets and door approaches are paved; routes out to farms remain dirt. Residential yards have open gates. Tavern customers enter the taproom directly; its rear apartment is private.

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
