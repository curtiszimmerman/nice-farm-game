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

Aldermere, the local kingdom, faces political and military hostility from Veyr. Humans, elves, dwarves, and halflings populate Aldermere; orcs, goblins, trolls, and dark elves are associated with Veyr.

The deliberate narrative device is to challenge the player's learned assumption that a visually recognizable fantasy race is automatically an enemy. Individuals have their own motives, relationships, loyalties, and disagreements with their governments. Encounters should invite critical thought about how to treat people.

Life continues across the border despite military tension. Merchants trade, pilgrims visit shrines, and relatives travel home for festivals. Khajit merchants such as Tavi are welcomed in Aldermere despite their government's relationship with the kingdom. Tavi travels home to Veyr for his sister's festival. These names are the current working choices.

Border skirmishes and political escalation usually remain in the background. Main-story events bring them into focus. Players can farm, gather, take local quests, learn magic, craft artifacts, trade as traveling merchants, or join border patrols for money and combat experience.

## Story outline

### Arrival and the first appointment

The player characters are starfleet officers attacked by an automated ship. The opening cuts between their intact bridge and a back-and-forth space battle. The captain orders evasion and return fire; the enemy explodes, but the crew's ship has taken too much damage to remain in space. Vale attempts a landing on a nearby planet. The captain orders everyone to brace. A white fade and crashing rumble lead into the damaged ship interior.

The captain asks for a status report. Major systems are down and repairs require substantial supplies and work. Vale is sure the attacker sent a signal before its destruction; reinforcements will probably arrive eventually. The captain therefore makes the cloak the first priority, then food, water and their local commlink repeater. Vale initializes the emergency gravitic power sink, sustaining the cloak through the planet's gravity well. Three refined copper bars restore the repeater. Dain teaches the crucible blueprint for ten star bulbs; the crew builds it with stone and smelts ore from the southeastern cave. The six ship rations are finite; Vale needs a ration or cooked meal each day.

The crew's Prime Directive requires avoiding interference with intelligent local life, but survival forces them to seek help. A universal translator handles communication. Familiar science fiction tropes are welcome where they support the experience.

The ship rests on an irregular mountain ridge with one winding descent. Bushes soften its lower slopes, and the farmhouse stands farther beyond the trail. Moss waits visibly at the foot of the trail. He asks about the mountain flash, wonders whether someone cast a spell, and asks if they are travelers. The captain confirms their cover story and asks about lodging. Moss offers the abandoned farmhouse. Accepting starts a guided walk inside; movement control and time remain held until the required welcome is complete.

The prologue begins at 09:00 on Spring 01. Time stays halted through the opening, briefing and time aboard until the captain first leaves the ship. The Moss introduction also halts time. The first farmhouse visit is a required paused sequence: players remove every furniture cover and replace both bulbs before the visitors arrive shortly afterward. All three visitors enter one after another; the meeting cannot be dismissed or escaped. After the final choice, the captain waits while Alder and Neral walk out. Moss stays to explain tools, water, crop growth and energy, then recommends visiting Iona at her northern tower for local magic. Movement and normal time resume after his advice. Later ordinary conversations retain the selected shared-clock policy.

The farmhouse begins neglected: covers protect its sofa, beds and radio, while standing corner lamps in the living room and bedroom need replacement bulbs. Players remove covers and take spare bulbs from the separate kitchen's cabinet to repair the lamps. Moss returns with Mayor Alder and Neral, his dark-elf assistant. Alder permits the crew to stay if they promise to keep the farmhouse clean, and suggests gardening to earn their keep and provide for themselves.

### The new star

After the first year, the radio reports a new star that grows brighter over time. It is a reinforcement attack ship that has tracked the crew to the planet. It can wait indefinitely for its prey. Its presence must not create a deadline that forces story advancement or prevents comfortable everyday play. The details of its arrival and subsequent progression remain to be designed.

Using the crew's own scanning technology risks revealing their location. Working with the town's Radio Club to develop radar provides a way to investigate through local technology and relationships.

Authorities in both kingdoms interpret the star as an omen, increasing tensions. The crew supplies the engineer with materials such as sulfur, copper, zinc, and iron to repair the ship and attempt to call for rescue. These tasks must produce meaningful developments and avoid repetitive delivery grind.

The ending is intentionally undecided.

## Time, calendar, and sleep

Everyone shares the same clock. Days flow continuously, with a moving sun and moons. Sleep is individual; there is no mandatory group bedtime or hard transition between days. Graveyard Keeper is the closer reference for this structure.

Calendar dates and time of day are important to appointments, seasons, and magic. The development calendar uses seven symbol days (Root, Ember, Tide, Stone, Gale, Star, Veil), 28-day seasons and a 112-day year. Purple Sael orbits in 56 days and white Iri in 28. The current phase display provisionally measures illumination against that year, allowing both moons to be new or full together; this interpretation awaits confirmation. Lunar spell effects, final day length, sleep benefits and missed-appointment behavior remain undecided.

Provide three options for dialogue, menus, and cutscenes:

1. Stop time and suspend other players' actions while the interacting player uses the window or scene.
2. Stop the calendar clock while other players can continue moving, fighting, and acting.
3. Keep time and gameplay running for everyone, including players in inventories, conversations, or cutscenes. This is the multiplayer default. Single-player defaults to stopping the entire world for menus and dialogue.

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

The native slice spans 148 × 90 tiles, including a 28-tile western coast extension beside the 120 × 90 mainland. The town has a square, fountain, provisions shop, a civic stone town hall and individual homes. Alder and Neral work in the hall and sleep in their own houses. Compact furnished interiors have private bathrooms opening onto halls. Iona's round tower is in the northern mountains; the farmhouse is west, the ship northwest and copper caves southeast. The western stone jetty ends at Oren's lighthouse, with a distinct interior. Faint paths lead from the farm to the coast and Bram's cabin. The camera remains at 1.9125×.

The satchel has pictured slots and hover descriptions. Left click selects an active item, shown separately beside the health bars; dragging onto a quick slot assigns it. Right click offers eating and drinking. Turnips and fish restore modest health and energy; star bulbs restore mana. Bram, an Aldermere army veteran, lives down a faint woodland path in a log cabin with a decorative garden. He speaks of people who helped him in Veyr and offers the first sword. Broader combat and his deeper history need Z's direction.

Primary (E / left click) and auxiliary (Q / right click) actions have independent assignments. Carried items and learned abilities can be dragged to either active slot or the eight quick slots. Spells, skills and learned blueprints have a separate scrollable inventory list and do not count as items. The character panel reserves head, chest, arms, hands, legs, feet, necklace and two ring positions; actual armor content remains future work. Controls are remappable, and the game menu has Controls, Settings, Development, Save and Quit submenus. The strict current save format is 15, with no older-save migration.

The eastern Reed farm houses Elin, Jory and their son Pip, displaced by a river flood and rebuilding with saved orchard cuttings and seeds. Tomas and Mara Bell work at the northeastern windmill; Nessa spends afternoons at the Radio Club. Dain Rusk left a foundry turning from canal hardware to weapons and now works in his smithy. Rafe Fen runs the Wayward Wren beside the square and grew up with Tomas. Corin Hale's bakery supplies and socially connects the millers, Reeds, Moss and Rafe. Families sleep in assigned beds and follow individual work, field and town routines. The square has solid flowerbeds, paved approaches, seats and a depth-sorted animated fountain whose upper portion can be walked behind.

Villagers walk between outdoor and indoor daily destinations. Tavi spends most working hours inside the grocery, Finch works in the Radio Club, and Moss tends decorative crops that players cannot farm. Sleeping residents lie along their beds beneath the covers. The mandatory first farmhouse welcome follows the paused arrival, meeting and departure sequence above, with visitors approaching during cleanup and entering one at a time. Tavi continues selling after closing until dialogue ends; shopping never triggers story-abandonment behavior. Abandoned optional multi-part story conversations send participants home to bed for the day. Seasonal schedule variations remain future work. Save format 14 is strict; earlier unsupported saves remain untouched, with no migration implemented.

Interior art uses a three-quarter 2D perspective, shaded object faces and shadows, distinct partition walls, and small details such as book-spine title marks. Furniture has independent positions and footprints in preparation for player decoration; editing is not implemented yet. Storage transfers offer quantities across the twelve-slot satchel, eighteen-slot farmhouse chest and twelve-slot kitchen/ship containers. Item quantities appear only for stacks larger than one. Eight quick slots start empty and never receive automatic assignments when supplies are collected; 1–8 selects the active slot. Seeds start in the chest with the tools. Farming requires the corresponding selected, carried tool. Tilling costs 2 energy, watering and harvesting 1 each. Crops mature after three watered midnights; dry days earn no growth. Soil moisture fades overnight and is gone by sunrise. The watering can starts empty, holds twenty charges and refills at the pond; well construction remains future work. Energy restores through player beds, ship bunks or explicit restorative items/effects, never idle time. The HUD groups commands under Actions and places a collapsible crew log below the upper-right clock.

Daily weather is reproducible for each visit: sunny skies produce grounded tree, fence and lamp shadows; partly cloudy skies have slow moving cloud shadows; rain adds a darker blue tint, gentle ambience and animated streaks and splashes. Occasional lightning flashes across two rendered frames, then thunder rolls two real seconds later. Rain waters outdoor crops automatically. Weather has separate rendering nodes so it does not invalidate static environment drawing.

Right-click inventory food for Eat, or health elixirs for Drink (25 HP). Tavi sells a pan and pot which enable fish sticks (one fish) and fish stew (one fish, one moon turnip, one star bulb) while physically carried or stored in the kitchen cabinet. Cooking opens at the farmhouse stove and pulls ingredients from carried supplies and its connected twelve-slot cabinet. Cookware costs 20 crowns each; cooked food values remain provisional.

The cloaked ship has an enterable damaged engineering section, three intermittently glitching displays, blinking machine lights, hanging sparking cables, an original low hum/beep ambience, and crew bunks. Vale works inside. Its twelve-slot locker starts with six rations; he consumes one ration daily, or one cooked meal when rations are gone. A late delivery can satisfy that day's need. Dialogue and crew notes report missed meals; starvation penalties have not been designed.

Bunks and the supply locker occupy the ship's upper rear section; broken machinery and displays occupy the front. An armed watering can refills along freshwater pond banks. Pond fishing offers silverfin and moon pike. Western shore fishing offers sprat, mackerel and storm eel. The sea end of the stone jetty adds a rarer Lantern ray. The southern ocean remains removed. Oren requests six firewood; Rowan the forest woodcutter provides an axe. Three energy-costing blows fell a tree for three wood. Clearings persist. The introductory dialogue waits for acknowledgement, keeps the background animated and preserves Neral's suspicion. Characters walk through scene transitions rather than appearing at their meeting positions.

Town doors connect to the square through shortest traversable routes, paved centrally and dirt toward farms. Spaced residential yards have side openings for circulation. Tavi works inside the grocery with the wagon alongside; he gives directions to Rowan and Bram for an axe and sword, and Dain for tool upgrades. The square bulletin board carries local postings. Married parents share a bed. The tavern has a public taproom and private rear apartment; the windmill uses wooden gears and a millstone. Neral's suspicion comes from protecting his adopted home after migrating from Veyr; that background is reserved for a later reveal. Saeren, a master observer at the northern mountain observatory, witnessed the arrival from the stars and keeps the crew's secret without understanding their technology.

## Cave, magic and rendering slice

Copper is inside the southeastern cave. A saved per-visit seed generates six varied grid rooms linked by orthogonal passages. Rocks and copper deposits occupy grid cells; cleared rocks and defeated creatures persist. A pickaxe leans against the four-slot entrance barrel and is noticed on the first visit. It must be collected, carried and selected directly or through a manually assigned quick slot. Rested mining costs five energy. Copper deposits yield ore and stone together; generated caves supply enough for the first crucible and three bars. Two basic rats take two sword hits; a spider guarding the final chamber takes four and has a twenty-percent poison chance per bite. Rested sword swings cost two energy. Rat kills award ten experience and the spider twenty; damage and experience appear as rising, fading values. Current damage and recovery tuning are provisional.

Corin sells fresh bread at the bakery for six crowns, restoring twenty base energy. More than twenty-four hours awake applies tiredness, doubling all energy costs and halving energy recovery. Six consecutive game hours asleep clears it. Poison deals two HP every five game minutes for sixty minutes; another application refreshes duration without stacking or delaying its next tick. Top-center indicators show a Zzz symbol and a purple skull with pulsing red eyes; hover text explains each status. Status time follows the world clock.

Dain teaches a permanent crucible blueprint in exchange for ten carried star bulbs. A twelve-by-eight-square building yard east of the garden is reserved for construction. Selecting the blueprint and activating a clear facing square builds a one-by-one stone crucible for ten carried stone. Each batch refines two copper ore into one bar in thirty game minutes without fuel; bars remain in the crucible until collected. Blueprint knowledge, placed structures and pending batches persist. The crossroads east of the farmhouse has a directional sign.

Carried inventory retains twelve ordered positions, with newly acquired stacks appended. Dragging supports carried/storage transfers with quantities, reordering, and active/quick assignments for items and learned abilities. The inventory has an equipment diagram and a Stats & Quests tab showing experience and full quest history. The small Crew Log lists active questlines only. Physical objects activate from the facing square, shown by default. Interior partitions are one cell wide, with clear door approaches and separated cooking, sleeping and bathing rooms. Cutscenes hide the ordinary HUD. Battle sound events share the intro animation clock.

Players start without magic. Iona offers Wildgrowth free at her tower and explains that spells depend on the region's gods and goddesses. More lessons require strange components: a Cave Moth Chrysalis deep in the cave, or a Golden Sparkfire Bloom that opens only during sunrise. Both are collectible; additional spells and component prices still require design with Z.

Each town interior has independently authored room geometry and furnishings. Static terrain and scenery retain Godot CanvasItem draw lists. Moving actors, crop changes, ambient particles and spell effects update separately; ship displays animate over retained machinery bodies. Furniture covers and repaired lights invalidate drawings only when their state changes.

Terrain artwork connects across all eight neighboring grid cells with seasonal/weather variants. Completed dirt, shoreline, cliff, field and cavern-wall families are integrated. New paving/jetty centers are integrated; their dedicated corner artwork is tracked in `docs/ART_TODO.md`, with external artwork calls paused until Z resumes them.

The Crew Log opens on the left. Calendar labels use larger pixel text and gold-framed green windows. Development weather choices already support automatic, sunny, partly cloudy and rainy days. Welcome visitors enter in a spaced procession as soon as the preceding visitor clears the doorway. Indoor departures follow the same effective schedule as outdoor movement, including story overrides and abandoned conversations.

Quest details expand the Crew Log downward until it reaches the action bar, then scroll within that limit. The captain faces his guided walking direction and the welcome visitors turn to face him after arriving. Buttonless cinematic captions accept click, Space or the primary-action key; visible dialogue buttons require an actual button click. Before the repeater works, Vale has only the last pre-crash scan and cannot name local people or services. The starting crew quest likewise asks players to find a way to refine ore without revealing an unknown smith.

Garden plots can be watered at any stage, preserving normal charge and energy costs. A seeded sample of about 7.5% of bushes offers berries in spring and summer; about 7.5% of oak-like trees offers apples in autumn. Each plant replenishes seven full days after harvesting, with timers saved. Mara Bell is Mrs. Bell, the millwright. Nessa borrowed her ladder for a radio aerial without asking and left it inside the family's tool shed east of their home. Returning it completes a small local quest.

The cave mouth's two visible columns match its usable footprint. Its interior exit is a rocky opening showing sky and treetops. The existing spider guards the final-room chrysalis. Golden glints mark rare lantern-ray water at the western jetty's sea end from 19:00 to 06:00; the fish joins that habitat only during those hours.

1. Review the native Godot slice and agree on the next playable increment.
2. Camera perspective, movement, input devices, and combat controls.
3. Initial playable slice and its acceptance criteria.
4. Precise clock behavior under each pause option, including simultaneous interactions.
5. Save ownership, reconnect behavior, and captain approval of story choices.
6. Shared-scene participation through crew communications.

Resolve other large story and system choices when they become relevant, rather than designing the entire game in advance.
