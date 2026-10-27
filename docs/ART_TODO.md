# Border artwork follow-up

Claude calls are paused at Z's request after the session limit. Do not retry or resume automatically; wait for Z to say usage has reset. All new pixels remain Claude-authored. Integration, atlas packing and tests can continue without generating or repairing artwork.

Z subsequently authorized one small, separate option-3 artwork request for the town-life additions. That pass is complete and cataloged in `SPRITE_INVENTORY.md`. The unfinished border work below remains deferred; the town request did not resume it.

The later authorized survival/faith pass is also complete: thirteen new sprites and seven revised weekday rings, cataloged in the same inventory. It did not resume the paused border work.

## Available for this integration

- Paving and stone-jetty center surfaces: 96 tiles covering both materials, four seasons, three weather states and four variants. The jetty's repeated recessed-box motif was revised; coverage, opaque centers, variant seam anchors and repeatability pass.
- Dirt paths, pond shores, ocean shores, cliffs, raw soil, tilled soil and cavern walls: 47 eight-neighbor shapes per material, four seasons, three weather states and four variants, plus oriented 8×8 quarter pieces. The source was written before the limit and passes direct library checks.
- Three plant-only overlays, allowing farm soil to connect without the old individual soil rectangles covering the new artwork.

## Remaining after usage resets

- Finish `scripts/border_tiles16.py`: dedicated paved-road and stone-jetty straight borders, convex/concave corners, end caps and narrow junctions. That pass did not produce its source file. Its prepared request is `internal/claude-borders/02-corners/prompt.txt`.
- Replace the interim stone-jetty legacy edge strips with the completed dedicated corner artwork. Do not describe the paving/jetty corner set as finished before this step.
- Run the deferred stone-border assembly checks retained in `internal/claude-borders/todo/test_border_tiles.py`, then expand runtime atlas coverage to those two complete corner families.
- Have Claude review actual in-game views of all terrain families across seasons and weather, especially cliff/cavern depth, shoreline joins, narrow paths and winter/rain readability. Keep any further pixel revisions with Claude.
- Continue the requested artwork refinement/usage work only after Z explicitly resumes Claude. The session limit was reached; the weekly allowance was not verified exhausted.

The working branch is `wip/seasonal-border-pixelart`. Prior atlases are preserved in git and under `internal/claude-borders/before/`. Public artwork-pass records belong under `internal/claude-review/borders/`; private reasoning is excluded from that export. The initial long material pass was interrupted without a source artifact; the later tested/revised material study became `scripts/border_surfaces16.py` by a byte-identical rename.
