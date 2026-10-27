# Sound direction

The tone is playful and comfortable. Music and environmental sound are separate layers. Z rejected the original sustained synthetic pad as disturbing; it has been replaced by a short-note, major-key composition with plucked melody, chord accompaniment, and a light bass pulse at 108 BPM.

## Current mix

- Music: a 16-bar, roughly 36-second original piece. No sustained drone.
- Farm/town by day: four quiet, varied bird phrases across a 67-second loop, fading in around dawn. Short trills, pitch bends and uneven spacing replace the dense repeated chirps.
- Farm/town by night: quiet cricket chirps, fading in at dusk.
- Mine entrance: water drops with several soft, decaying echoes. Proximity blends them with the outdoor wildlife.
- Cave/mine interiors: the same dripping-water profile at every time of day, with outdoor wildlife excluded.
- Wildgrowth: a brief rustle and rising four-note flourish, played only on successful casting. Hearthmend and Emberthread use distinct pitch treatments of the spell layer.
- Mining: a short metallic pick-on-stone clink, played only when mining succeeds and controlled by effects volume.
- Ship engineering: a separate sixteen-second low machinery hum with quiet paired console beeps. Entering the ship fades out music and wildlife and brings in this ambience; its volume follows the ambience slider.
- Opening impact: a separate 3.6-second crashing/rumbling effect during the white fade. The opening silences music and environmental layers, including when replayed through a confirmed new visit; its crash follows the effects volume.
- Opening battle: laser reports, hull-hit thuds and an enemy-ship explosion follow the same battle clock and event schedule as the visible shots and impacts. Playback is two octaves below the original effects; friendly and enemy lasers retain slightly different pitches. These effects use the effects volume and allow overlapping shots.
- Rain: a gentle twelve-second ambience loop with occasional soft thunder, controlled by the ambience slider. Thunder rolls one to three seconds after lightning. Entering an interior fades out rain and stops outdoor thunder. Snow has no rain loop; only rare thundersnow days permit winter lightning/thunder. Weather stays silent during the space introduction.

The music, ambience, and spell effects each have a volume slider under Settings → Sound. Zero mutes that layer. Preferences persist at `internal/audio.cfg`, independently of the gameplay save. Audio begins when entering the game, not at the title screen.

Wildlife and water loops have different lengths to reduce synchronized repetition. Dawn and dusk blend profiles smoothly; mine proximity also fades rather than switching at a hard boundary. The tracks are quiet at loop boundaries and leave mixing headroom. Playback uses prebuilt PCM assets, so synthesis does not run during gameplay.

## Calendar and map boundaries

The audio controller accepts farm/town or cave/mine context, time of day, and season. Summer has more insect activity; autumn has less; winter has no cricket chorus and quieter birds. The world supplies the season from the provisional 28-day calendar. Entering the generated cave selects echoing water drops at every time of day and excludes outdoor wildlife. Full seasonal gameplay remains future work.

## Editing the sound

Original WAV files live in `src/native/audio/`. Their reproducible source is `scripts/make_audio.py`, which uses the Python standard library. Rebuild all assets with:

```sh
python3 scripts/make_audio.py
```

Use `--only` with `music`, `birds`, `crickets`, `drips`, `wildgrowth`, `ship`, `crash`, `laser`, `laser_hit`, `explosion`, `rain`, `thunder`, or `mining` for one asset. No packages or external recordings are required. Composition and sound quality remain subject to play feedback.

The audio controller is `src/native/sound.gd`. The world supplies environmental context; the game triggers spell sounds. A new spell needs its own sound and a successful-cast trigger. The controller does not substitute Wildgrowth for unknown spells.

Native tests cover daylight/season/cave selection, transitions, independent volume controls, preference persistence, actual spell triggering, asset levels and boundaries, and the native slider bindings. Tests use isolated preference files inside the project. Playback is stopped and allowed to release on the audio thread before scenes exit.
