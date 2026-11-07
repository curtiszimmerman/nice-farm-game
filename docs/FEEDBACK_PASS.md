Current requested pass, November 2026. Check items only after implementation and relevant verification.

- [x] Planet independent of weapon-impact bridge shake.
- [x] Dain refining topic, ordered blueprint gate and learned-option removal.
- [x] Finch location dialogue and radio-project conversation.
- [x] Remove Wildgrowth assignment instruction from Iona.
- [x] Mara introduction and mechanism dialogue.
- [x] Rafe travel and Corin dialogue.
- [x] Individual tavern and town-hall signs.
- [x] Bram greeting before sword discussion.
- [x] Crew Log horizontal scroll, padding and remaining axe deadline.
- [x] Early summer-night woodland fireflies.
- [x] Expand square outward around stationary fountain; keep circulation clear.
- [x] Jory town dialogue.
- [x] Replace dead-end useful-to-know replies with an explicit farewell.
- [x] Corin introduction and town dialogue.
- [x] Tavi shopping return only while at work.
- [x] Bell family doorway collision, pathing and pushing.
- [x] Exterior lantern flame alignment.
- [x] Sleep completion text works across midnight.
- [x] Shop crowns overlay and purchase pulse.
- [x] Empty jar required for berry preserves.
- [x] Direct farmhouse-square road; temple south with western woodland connection.
- [x] Crop-specific planting prompt.
- [x] Sparser cave rocks, protected exit/stair routes, no cave dripping audio.

The temple moved four tiles south and three west so its facade stays clear of Finch's house. Its western gate joins the Moss-side road, while the farmhouse road continues straight into the expanded square. The fountain remains in its original world position.

Cave rock density falls from 17% to 9% of floor cells, with three-tile clear areas around entrances, exits and stairs. All remaining floor cells must stay connected. Existing minimums of six copper deposits and three coal deposits per level remain, so smaller floors have a higher ore share than the usual 10% copper / 5% coal target.

Verification: `scripts/check.sh` passes with clean output. Additional native captures cover the square, farmhouse road, temple, both signs, lanterns, summer fireflies, expanded Crew Log and shopping balance. Multi-seed checks cover cave access and garden placement around temple gates; resource-allocation checks retain coverage of the nominal copper/coal proportions.
