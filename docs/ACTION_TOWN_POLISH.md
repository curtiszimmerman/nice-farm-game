# Action and town revision

Z requested 26 changes covering action duration and energy, tree falling and dropped logs, clock/HUD geometry, resource-disabled dialogue, shop location checks, Iona/Saeren routines, village signs/fences/gardens, the farmhouse road and empty starting farm.

Work is on `wip/action-town-polish`. No extra models or art services are authorized for this pass. Existing sprites will be reused.

Day-one target: 100 energy, with 20 till actions at 1.2, 20 water actions at 0.8, 20 plant actions at 0.3, one refill at 0.2, five berry harvests at 0.4, 18 axe swings at 2 (six trees), and five casts at 1. Total 89.2, leaving 10.8 for errors. Tired multipliers still apply.

Non-sword actions have a shared 0.6-second execution interval. Sword animation keeps its existing faster duration.

Implemented: action cooldown and energy, falling trees with persistent collectible logs, the tapered clock plate, survival bars above vitals, disabled resource choices, thousand-crown sword and consolidated smith topic, actual-shop checks, Iona's awake lessons and routine, Saeren's Rift closure and truth/lie friendship, house labels, signs, removed exterior radio, tavern social facing, mayor corner, wooden temple perimeter and consistent fence connections, farmhouse moved seven tiles south with a straight west road, no predefined fields or plot fence, garden decorations and weekly tending, and development supplies.

New behavioral checks pass in `action_balance_test.gd` and `action_town_revision_test.gd`. Four native visual captures were inspected under `internal/verification/native-action-town-*.png`. Full existing suite audit is running, with results under `internal/verification/action-town-audit/`. Legacy tests need explicit test gardens, elapsed action intervals, and day-two observatory visits. These are test fixtures only; new games have no predefined fields.

Save schema 19 uses explicitly located plots, including an empty starting list. Older saves remain unsupported and protected from overwrite. Fallen-log collection is persisted as wood harvest entries alongside existing forage harvest timestamps.

Remaining: finish the full audit, resolve every failure, verify all resource choices and garden schedules, inspect final signs/animations, update player/development docs, and commit the completed work. Do not merge or push without Z's request.
