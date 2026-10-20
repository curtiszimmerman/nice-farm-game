# Game design plan

This is the working design document, incorporating `premise.txt` and Z's subsequent decisions. The original premise remains as source material. Unresolved choices below require discussion before implementation.

## Direction and collaboration

Fun comes first. Build a comfortable pixel art farming and adventure game for 1–4 players, with cooperation in multiplayer. Stardew Valley and Graveyard Keeper inform everyday life and farming; World of Warcraft and Diablo inform the visual presentation of combat and the breadth of magic.

Avoid grind, excessive routine chores, and constant pressure. Combat and particular social encounters can be tense. Players should enjoy ordinary days without being forced to advance the main story.

Development proceeds through small playable increments. Z decides major technical, gameplay, and storyline choices. The agent drives routine implementation, reports small design decisions before commits, and commits autonomously. Never push without Z's explicit permission.

## Platform and presentation

- Target Debian and comfortable performance on a GeForce 940MX.
- Use pixel art. The setting is explicitly not steampunk; do not introduce steampunk themes.
- Populate the world on a shared invisible tile grid, including the farm, buildings, trees, resources, and roads. Movement remains smooth between cells, in the style of Stardew Valley. The native slice uses 32-pixel tiles and whole-tile collision footprints.
- Build and run natively on the Debian host. Z explicitly rejected a browser game.
- The first playable slice uses Godot 4.5.1 with its OpenGL Compatibility renderer. The engine executable is project-local under `vendor/`; all runtime writes remain inside this project.
- Windows/Proton is not the current delivery approach. Later distribution choices remain open.
- Establish CPU, RAM, resolution, and performance criteria before making performance claims.

## Audio

Music should be playful and comfortable. Keep it separate from environmental ambience. Farm and town areas have daytime birds and quiet nighttime crickets; caves and mines have echoing water drops regardless of daylight. Ambience responds to location, time of day, and season. Each castable spell has its own sound.

The native slice provides separate music, ambience, and spell-effect volumes, a Wildgrowth sound, seasonal outdoor wildlife, and localized mine-entrance drips. A provisional 28-day development calendar drives the seasonal profiles. Full cave audio is ready for later interiors. See `docs/AUDIO.md`.

## Setting

The crew of a spacecraft crash-lands near a small frontier town on a planet where magic is real. Local technology resembles 1920s America: automobiles, telephones, radios, airplanes, crop dusters, and airships coexist with practical magic.

The town sits within sparsely populated agrarian surroundings. People generally know one another. Farmers hire a magician to treat their fields just as they hire a pilot to spray insecticide. Seasons resemble Earth's, while the sun, moons, calendar, and time of day matter to life and magic.

The full town is intended to include 52 varied NPCs across occupations, social positions, and circumstances. Examples include farmers, a magician, a pilot, a radio station and Radio Club, a town drunk, a person living in poverty, and a small military garrison of four or five soldiers. Begin with only the characters needed for the first playable slice.

## Kingdoms and people

The local kingdom faces a hostile opposing kingdom. Humans, elves, dwarves, and halflings populate the local society; orcs, goblins, trolls, and dark elves are associated with the opposing kingdom.

The deliberate narrative device is to challenge the player's learned assumption that a visually recognizable fantasy race is automatically an enemy. Individuals have their own motives, relationships, loyalties, and disagreements with their governments. Encounters should invite critical thought about how to treat people.

Life continues across the border despite military tension. Merchants trade, pilgrims visit shrines, and relatives travel home for festivals. Khajit merchants can be welcomed locally despite their government's relationship with the kingdom. Final names and terminology can be settled later.

Border skirmishes and political escalation usually remain in the background. Main-story events bring them into focus. Players can farm, gather, take local quests, learn magic, craft artifacts, trade as traveling merchants, or join border patrols for money and combat experience.

## Story outline

### Arrival and the first appointment

The player characters are starfleet officers fleeing an automated attack ship. A short opening animation cuts between their intact bridge and the ship taking fire in space. The captain orders evasive maneuvers; Chief Vale reports overwhelming damage and attempts to land on a nearby planet. The captain orders everyone to brace. A white fade and crashing rumble lead into the damaged ship interior.

The captain asks for a status report. Vale explains that major systems, including long-range communications and the distress transmitter, are down; repairs require substantial supplies and constant work. The captain prioritizes the cloak, then food, water and their local commlink repeater. Vale initializes an emergency gravitic power sink: the cloak remains stable while the planet's gravity well remains stable, using all currently available system capacity. Pre-crash scans found copper a couple of kilometers southeast of the inhabited area. Three pieces will restore the local repeater. The six ship rations are finite; Vale stays aboard and needs a ration or cooked meal each day.

The crew's Prime Directive requires avoiding interference with intelligent local life, but survival forces them to seek help. A universal translator handles communication. Familiar science fiction tropes are welcome where they support the experience.

The ship rests on an irregular mountain ridge with one winding descent and a meadow approach leading to the farmhouse rear. Coming around either side forces an on-screen meeting with Moss. He asks about the flash and crashing sound on the mountain, wonders whether someone cast a spell, and asks if they are travelers. The captain reacts with surprise, confirms their cover story and asks about lodging. There is no hotel; Moss offers the abandoned farmhouse while he fetches the mayor.

The prologue begins at 09:00 on Spring 01. Time stays halted through the opening, briefing and time aboard until the captain first leaves the ship. The Moss introduction also halts time. The first farmhouse visit is a required paused sequence: players remove every furniture cover and replace both bulbs before the visitors arrive shortly afterward. All three visitors enter together; the meeting cannot be dismissed or escaped. After the final choice, the captain waits while Alder and Neral walk out. Moss stays to explain tools, water, crop growth and energy, then recommends visiting Iona at her northern tower for local magic. Movement and normal time resume after his advice. Later ordinary conversations retain the selected shared-clock policy.

The farmhouse begins neglected: covers protect its sofa, beds and radio, while living-room and bathroom lights need replacement bulbs. Players remove covers and take spare bulbs from the kitchen cabinet to repair the lights. Moss returns with Mayor Alder and Neral, his dark-elf assistant. Alder permits the crew to stay if they promise to keep the farmhouse clean, and suggests gardening to earn their keep and provide for themselves.

### The new star

After the first year, the radio reports a new star that grows brighter over time. It is the automated attack ship that has tracked the crew to the planet. It can wait indefinitely for its prey. Its presence must not create a deadline that forces story advancement or prevents comfortable everyday play. The details of its arrival and subsequent progression remain to be designed.

Using the crew's own scanning technology risks revealing their location. Working with the town's Radio Club to develop radar provides a way to investigate through local technology and relationships.

Authorities in both kingdoms interpret the star as an omen, increasing tensions. The crew supplies the engineer with materials such as sulfur, copper, zinc, and iron to repair the ship and attempt to call for rescue. These tasks must produce meaningful developments and avoid repetitive delivery grind.

The ending is intentionally undecided.

## Time, calendar, and sleep

Everyone shares the same clock. Days flow continuously, with a moving sun and moons. Sleep is individual; there is no mandatory group bedtime or hard transition between days. Graveyard Keeper is the closer reference for this structure.

Calendar dates and time of day are important to appointments, seasons, and magic. Exact day length, calendar structure, lunar cycles, sleep benefits, and missed-appointment behavior remain undecided.

Provide three options for dialogue, menus, and cutscenes:

1. Stop time and suspend other players' actions while the interacting player uses the window or scene.
2. Stop the calendar clock while other players can continue moving, fighting, and acting.
3. Keep time and gameplay running for everyone, including players in inventories, conversations, or cutscenes. This is the default.

The scope of each option and overlapping interactions need specification. In particular, calendar time and action simulation must be distinguishable to support the second option; effects on crops, schedules, cooldowns, and other timed systems require a deliberate decision.

## Cooperative play

- Support 1–4 players on separate computers over LAN or internet, connecting directly to friends. No shared-screen play or public matchmaking requirement.
- One player hosts and plays the captain. The host must be present for others to play that saved game. A separate dedicated server is not required.
- This is a shared crew and shared story on one planet. Character transfer between unrelated saves is not a requested feature.
- The host is the main character for story decisions. Any player may initiate story progression; how captain decisions are requested when another player initiates an event remains to be designed.
- Choose shared money or individual money at the beginning.
- Support both party and personal quests, and both party and personal relationships.
- A client disconnect does not stop the remaining session. Reconnection, inventory persistence, and handling a disconnected character need explicit rules.
- Design for friends choosing to play together. Occasional solo activity is acceptable, including while another player falls asleep. Do not build elaborate systems to compensate for disengaged participants.

### Shared story scenes: idea to explore

Crew communications could transmit one character's view over a hyper-local radio network, allowing distant party members to experience a story scene. This is a promising idea, not a finalized feature.

Decide how players opt in, whether their characters remain vulnerable, how shared scenes interact with the three time modes, and how the captain makes decisions. The result should make participation fun without unnecessarily interrupting everyone.

## Gameplay systems

### Farming and everyday production

Use approachable farming comparable to Stardew Valley or Graveyard Keeper. Harvests feed cooking, trade, quests, and other useful activities. Provide variety without making maintenance a grind. Exact tools, growth rules, recipes, and economy come later.

### Combat and progression

Combat is real time. Players have individual inventories, quick-use slots, equipment such as swords and handguns, potions, and spells. Characters gain experience and levels.

WoW and Diablo are visual references. Targeting, aiming, movement, ability controls, death consequences, and cooperative combat rules remain undecided.

### Mining

Include both safe ore-gathering locations and dangerous areas occupied by enemies. Gathering should not always require combat.

### Fishing

Include seasonal fish, different fishing difficulties, and fish-derived ingredients for food and spellcasting. The fishing interaction remains undecided.

### Magic

Magic is a substantial system with mana, spells, scrolls, spellbooks, and powerful artifacts. It affects everyday life as well as combat. Calendar and celestial conditions matter, with their exact effects still to be designed.

Routine, natural design details can be proposed during implementation, such as heavy metal armor penalizing spellcasting. Such examples are not a finalized class or equipment system.

## Incremental development

Z authorized autonomous work on a small playable prototype, with major storyline and technical decisions continuing to require discussion. Z subsequently specified a native host application and all writes confined to this directory. The native prototype uses Godot, keyboard movement, contextual interactions, and project-local saves. Its working title, character names, dialogue, visuals, and tuning remain provisional.

First slice:

- A small farm and nearby area with a few NPCs.
- A continuous clock and the neighbor's same-day appointment with the mayor.
- One satisfying planting, harvesting, and cooking-or-selling loop.
- A short excursion to judge movement and exploration.

Establish cooperation early enough to test the chosen hosting and time model before expanding content. The exact order and extent of multiplayer work need agreement with Z.

Expand only after the small version feels good to play. The 52 NPCs, broader world, full magic system, fishing, combat, and later story arcs are long-term scope, not requirements for the initial slice.

## Next decisions with Z

The current native slice occupies 120 × 90 tiles, four times the original area. It includes a grid-aligned town square, fountain, provisions shop, and distinct compact furnished interiors with private bathrooms opening onto halls. The round wizard tower sits among mountain cliffs far north of town. The farmhouse is west, the ship northwest, and copper caves southeast, clear of homes. The eastern ocean is removed. Fishing works along the full dock. The camera uses 1.9125× zoom after Z's latest 15% reduction.

The satchel has pictured slots, quantities, native hover descriptions and click actions. Turnips and silverfin restore modest health and energy; star bulbs restore mana and can be grown from purchased seeds. Bram, an army veteran, lives in a roadless southern log cabin with a small decorative garden, introduces his experience of the other kingdom and offers the first sword. Sword combat against cave rats is implemented; broader combat and his deeper history need Z's direction.

Villagers walk between outdoor and indoor daily destinations. Tavi spends most working hours at the market, Finch works in the Radio Club, and Moss tends decorative crops that players cannot farm. Sleeping residents lie along their beds beneath the covers. The mandatory first farmhouse welcome follows the paused arrival, meeting and departure sequence above. Tavi continues selling after closing until dialogue ends. Abandoned optional multi-part conversations send participants home to bed for the day. Seasonal schedule variations remain future work. Existing-save upgrade approval is pending under CLAUDE.md's explicit compatibility rule.

Interior art uses a three-quarter 2D perspective, shaded object faces and shadows, distinct partition walls, and small details such as book-spine title marks. Furniture has independent positions and footprints in preparation for player decoration; editing is not implemented yet. Storage transfers offer quantities across the twelve-slot satchel, eighteen-slot farmhouse chest and twelve-slot kitchen/ship containers. Item quantities appear only for stacks larger than one. Eight quick slots start empty and never receive automatic assignments when supplies are collected; 1–8 selects the active slot. Seeds start in the chest with the tools. Farming requires the corresponding selected, carried tool. Tilling costs 2 energy, watering and harvesting 1 each. Crops mature in three days. The watering can starts empty, holds twenty charges and refills at the pond; well construction remains future work. Energy restores through player beds, ship bunks or explicit restorative items/effects, never idle time. The HUD groups commands under Actions and places a collapsible crew log below the upper-right clock.

Right-click inventory food for Eat, or health elixirs for Drink (25 HP). Tavi sells a pan and pot which permanently unlock fish sticks (one fish) and fish stew (one fish, one moon turnip, one star bulb). Cooking uses the farmhouse stove and pulls ingredients from carried supplies and its connected twelve-slot cabinet. Cookware costs 20 crowns each; cooked food values remain provisional.

The cloaked ship has an enterable damaged engineering section, three intermittently glitching displays, blinking machine lights, hanging sparking cables, an original low hum/beep ambience, and crew bunks. Vale works inside. Its twelve-slot locker starts with six rations; he consumes one ration daily, or one cooked meal when rations are gone. A late delivery can satisfy that day's need. Dialogue and crew notes report missed meals; starvation penalties have not been designed.

Bunks and the supply locker occupy the ship's upper rear section; broken machinery and displays occupy the front section. An armed watering can refills along the reachable freshwater pond border. Pond fishing offers easy silverfin and difficult, more valuable moon pike. The invented southern ocean and its dock are removed. Coastal species remain in the item catalog without a fishing location, pending approved geography. Hard catches move the gauge faster and less predictably.

## Cave, magic and rendering slice

Copper is inside the southeastern cave. A saved per-visit seed generates six varied grid rooms linked by orthogonal passages. Rocks and copper deposits occupy grid cells; cleared rocks and defeated rats persist. A four-slot entrance barrel contains the pickaxe, which must be carried and manually assigned and selected. Mining costs five energy, more than any single farm action. Two basic rats approach nearby players and bite; selected sword swings cost two energy. Current damage and recovery tuning are provisional.

Players start without magic. Iona offers Wildgrowth free at her tower and explains that spells depend on the region's gods and goddesses. More lessons require strange components: a Cave Moth Chrysalis deep in the cave, or a Golden Sparkfire Bloom that opens only during sunrise. Both are collectible; additional spells and component prices still require design with Z.

Each town interior has independently authored room geometry and furnishings. Static terrain and scenery retain Godot CanvasItem draw lists. Moving actors, crop changes, ambient particles and spell effects update separately; ship displays animate over retained machinery bodies. Furniture covers and repaired lights invalidate drawings only when their state changes.

1. Review the native Godot slice and agree on the next playable increment.
2. Camera perspective, movement, input devices, and combat controls.
3. Initial playable slice and its acceptance criteria.
4. Precise clock behavior under each pause option, including simultaneous interactions.
5. Save ownership, reconnect behavior, and captain approval of story choices.
6. Shared-scene participation through crew communications.

Resolve other large story and system choices when they become relevant, rather than designing the entire game in advance.
