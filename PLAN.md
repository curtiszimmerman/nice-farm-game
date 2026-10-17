# Game design plan

This is the working design document, incorporating `premise.txt` and Z's subsequent decisions. The original premise remains as source material. Unresolved choices below require discussion before implementation.

## Direction and collaboration

Fun comes first. Build a comfortable pixel art farming and adventure game for 1–4 players, with cooperation in multiplayer. Stardew Valley and Graveyard Keeper inform everyday life and farming; World of Warcraft and Diablo inform the visual presentation of combat and the breadth of magic.

Avoid grind, excessive routine chores, and constant pressure. Combat and particular social encounters can be tense. Players should enjoy ordinary days without being forced to advance the main story.

Development proceeds through small playable increments. Z decides major technical, gameplay, and storyline choices. The agent drives routine implementation, reports small design decisions before commits, and commits autonomously. Never push without Z's explicit permission.

## Platform and presentation

- Target Debian and comfortable performance on a GeForce 940MX.
- Use pixel art. The setting is explicitly not steampunk; do not introduce steampunk themes.
- Build and run natively on the Debian host. Z explicitly rejected a browser game.
- The first playable slice uses Godot 4.5.1 with its OpenGL Compatibility renderer. The engine executable is project-local under `vendor/`; all runtime writes remain inside this project.
- Windows/Proton is not the current delivery approach. Later distribution choices remain open.
- Establish CPU, RAM, resolution, and performance criteria before making performance claims.

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

The player characters are starfleet officers fleeing an automated attack ship. Their damaged spacecraft cannot leave the planet. A cloak powered by ambient energy from the planet's gravity well conceals it. The chief engineer, an NPC member of the crew, stays aboard to maintain the cloak.

The crew's Prime Directive requires avoiding interference with intelligent local life, but survival forces them to seek help. A universal translator handles communication. Familiar science fiction tropes are welcome where they support the experience.

The crew finds an abandoned farm near town. A neighboring farmer discovers them and cautiously allows them to stay overnight. He promises to return with the mayor at noon the next day. This establishes early that appointments and the calendar matter: at least one player should be home to receive them. Consequences for missing the appointment remain to be designed.

The crew claims to be travelers from far away seeking somewhere to settle. The mayor welcomes people who can help the economy. A member of the mayor's entourage raises the possibility that they are spies, introducing the border conflict. The crew begins making a life at the farm.

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
- A continuous clock and the neighbor's noon appointment with the mayor.
- One satisfying planting, harvesting, and cooking-or-selling loop.
- A short excursion to judge movement and exploration.

Establish cooperation early enough to test the chosen hosting and time model before expanding content. The exact order and extent of multiplayer work need agreement with Z.

Expand only after the small version feels good to play. The 52 NPCs, broader world, full magic system, fishing, combat, and later story arcs are long-term scope, not requirements for the initial slice.

## Next decisions with Z

1. Review the native Godot slice and agree on the next playable increment.
2. Camera perspective, movement, input devices, and combat controls.
3. Initial playable slice and its acceptance criteria.
4. Precise clock behavior under each pause option, including simultaneous interactions.
5. Save ownership, reconnect behavior, and captain approval of story choices.
6. Shared-scene participation through crew communications.

Resolve other large story and system choices when they become relevant, rather than designing the entire game in advance.
