# Town-life work

Z's requested batch: fix pack discovery and disappearing chest; gate ladder clues; seasonal shop stock; midnight calendar transition; sixteen-slot/two-row inventory with Tab row switching and smaller equipment; repair Neral/Alder/Finch interiors; varied tavern evenings and sensible work/sleep; temple, priest, garden and decorative bees; bedtime locks with loved-friend access; met-NPC relationship tab; random nightly rotating gold glints; rare world-wide dawn blooms and dispersed bushes; healing/fire lessons; escalating sleeplessness; distinct smaller shop signs; sunset-to-midnight soil drying; restored farmhouse bed interactions; fishing-pole reward and requirement; subtle water and clearer faster birds; three cave levels, each about six times the old area, with 85% stone / 10% copper / 5% coal.

Confirmed design: three cave levels; only loved friendship grants entry to a sleeping resident's home. All seasons are 28 days. New artwork is option 3 only, with small-context, low-cost Claude requests. Existing sprites must not be repainted.

Randomness means a distribution suited to the feature: reproducible seeded world placement, spatial exclusion/clearance for vegetation, per-night seeded glint locations and independent bounded random intervals for flashes. Avoid uniform-looking placement or a fixed repeating position masquerading as random.

Existing pre-task change: scripts/play.sh executable mode; exclude it from commits. No save migrations are authorized.

## Implemented

All gameplay changes in this batch are implemented. The temple keeper is Brother Aven. His one-room home has a separate outhouse. Beehive construction, honey/beeswax production and later-year blueprint availability remain future features, as requested; the plans can already be learned for two silver ingots.

The old pack-switch chest disappearance was not reproduced with a precise original sequence. The chest now has its own depth-sorted retained scene object. Regression checks and native captures cover repeated pack switches, walking off-screen, returning and opening it.

Final screenshots revealed a separate stale-atlas problem in the calendar. Pack changes now refresh retained HUD drawing and status textures as well as world nodes; native pixel comparisons cover switching away and back.

The first audit found an unreachable random dawn plant. Placement now checks walking access, and bloom locations persist so tree felling cannot reshuffle them. JSON loading also normalizes defeated creature IDs so killed creatures stay defeated after saving. Storage shows the same two carried rows, treats spell shortcuts as actions, and supports replacing a shortcut with a physical item.

The guest bed now offers rest after its cover is removed, and resting uses the bed being faced rather than always choosing the first bed. Actor bed assignments remain unchanged. A failing regression reproduced the placement issue before the fix; sleep, interior depth, storage and pause checks pass afterward.

The complete clean run passed 2,574 native checks, ten Python checks and startup smoke. Follow-up focused checks cover the final storage/shortcut cases, cave progression, sleep, calendar, friendship and artwork. Native visual checks exercise real mouse drags and Tab input, revised interiors, the chest after pack switching, the evening tavern and the new cave floors. Verification files are under `internal/verification/`.

Artwork used one bounded request, producing fifteen new option-3 sprites for $1.1476732 in reported API-equivalent usage. The silver icon derives from existing bar pixels. All 23,403 preexisting sprite images are unchanged. The compact generated catalog is `docs/SPRITE_CATALOG.md`; dedicated paving/jetty corners from the previous task remain deferred in `docs/ART_TODO.md`.

Save format 16 is strict. Unsupported earlier saves stay untouched and require an explicitly started new visit. No migration was added. No push is automatic.

Commits: `c14ef4a` adds the new option-3 artwork, `282155f` adds the gameplay systems and regressions, and `d57c3a2` fixes faced-bed sleep placement. The final documentation commit records these results. Atlas rebuilding reproduces identical hashes, and the native renderer confirms calendar/scenery pixels remain identical after repeated pack switches. The only intentionally uncommitted change is the preexisting launcher executable mode.
