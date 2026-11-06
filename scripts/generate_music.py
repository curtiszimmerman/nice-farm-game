#!/usr/bin/env python3
"""Generate candidate soundtrack pieces with Google's Lyria 3 Pro through OpenRouter, then install one.

When to use: making or replacing an alternative music track. Lyria costs about $0.08 per
full song, so generating a few candidates and picking the best by ear is cheap.

  generate   python3 scripts/generate_music.py generate --count 3
             Saves each candidate under internal/music/ with the prompt and API usage beside it.
  install    python3 scripts/generate_music.py install internal/music/<file> --name meadow
             Converts a candidate to src/native/audio/<name>.ogg (needs ffmpeg) at a steady loudness.

The API key is read from OPENROUTER_API_KEY, or from ~/projects/ai/general/.env if the
variable isn't set. It is never printed.
"""
import argparse
import base64
import json
import os
import pathlib
import subprocess
import sys
import time
import urllib.error
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
CANDIDATES = ROOT / "internal/music"
AUDIO = ROOT / "src/native/audio/music"
MANIFEST = AUDIO / "tracks.json"
ENV_FILE = pathlib.Path.home() / "projects/ai/general/.env"
MODEL = "google/lyria-3-pro-preview"
ACOUSTIC = """Instrumentation: fingerpicked nylon-string acoustic guitar carrying the harmony, a soft felt piano, \
a warm wooden flute or recorder, a light string section holding long sustained chords underneath, and a round \
upright bass. Very light brushed percussion or none at all. Everything has soft attacks and a little natural \
room reverb. Entirely instrumental."""
FORM = """Composition: one clear, memorable melody that is stated, then answered by a contrasting second \
section, then the main melody returns with a fuller arrangement. Smooth, lyrical phrases with real development \
and variation between sections rather than a short loop repeated. The ending settles gently back on the home \
chord so the piece can loop."""
AVOID = """Avoid: vocals, lyrics, humming, synthesizers, chiptune or 8-bit sounds, electronic drums, harsh or \
staccato stabbing notes, sudden loud dynamics, and repetitive one-bar riffs."""
GAME = "Instrumental background music for a cozy pixel-art farming and village life game, in the spirit of gentle pastoral game soundtracks."


def acoustic(mood, music):
    return "\n\n".join([GAME + " " + mood, ACOUSTIC, music + " " + FORM, AVOID])


NIGHT = """The night songs use the same ensemble but feel very different from the daytime music: slow, \
hushed and introspective, a quiet night-owl mood rather than a bright morning one. The piano and guitar lead; the \
flute appears rarely, low and breathy, or not at all. Harmony leans on minor chords and moves slowly, lingering on \
each chord, with long sustained string notes and plenty of space and silence between phrases. There is a gentle, \
subconscious pull toward going home to bed: a little lonely, a little heavy, never frightening."""
NIGHT_AVOID = " Also avoid bright, bouncy or plucky playing, cheerful flute melodies, fast tempos and anything energetic."


def night(mood, music):
    return "\n\n".join([GAME + " " + mood, ACOUSTIC, NIGHT, music + " " + FORM, AVOID + NIGHT_AVOID])


# Each theme lists one prompt per variant, so two songs of the same theme differ in key, tempo and lead voice.
THEMES = {
    "spring": [acoustic("Warm, calm, hopeful and unhurried, like a sunny morning walking between the farmhouse fields and a small friendly village.",
                        "About 92 BPM, in F major, a lilting 4/4 feel. The flute plays the main melody; the contrasting section moves to the relative minor and back, and the piano and strings join the flute when the melody returns.")],
    "rain": [acoustic("A soft rainy day: rain on the farmhouse window, a warm cup of tea, a quiet walk under a drizzle. Reflective, cozy and a little wistful but comforting.",
                      "About 74 BPM, in D major, gently swaying. The felt piano leads with the melody, the guitar answers with rippling arpeggios like falling drops, and the flute enters softly in the second section, which leans toward B minor."),
             acoustic("A long gray rainy afternoon in a small village: puddles on the paths, everyone indoors, peaceful and contemplative.",
                      "About 80 BPM, in G major with moments in E minor, a slow 3/4 waltz feel. The guitar carries the melody, low strings and upright bass sustain underneath, and the piano adds sparse, glistening answers.")],
    "summer": [acoustic("A bright summer day: long golden afternoons, tall crops, warm breezes and cheerful neighbors in the village square. Lively, sunny and carefree, but still relaxed.",
                        "About 104 BPM, in C major, a bouncy, light-footed 4/4 with a soft shaker and brushes. The flute plays a playful, skipping melody over strummed and picked guitar; the second section brightens toward G major."),
               acoustic("A slow, lazy summer evening on the farm: fireflies, warm air, the sun setting over the fields. Content, golden and easygoing.",
                        "About 96 BPM, in A major with a gentle swing. The piano and guitar trade the melody, the strings swell warmly underneath, and the flute adds a high countermelody when the theme returns.")],
    "autumn": [acoustic("Autumn harvest: golden and russet leaves falling, baskets of apples and pumpkins, a crisp breeze. Nostalgic, warm and grateful, with a gentle hint of melancholy.",
                        "About 88 BPM, in A minor moving to C major, a rolling 6/8 feel. A cello-like low string line carries the opening melody, the guitar picks steady arpeggios, and the flute takes over the melody when it returns."),
               acoustic("A cool, clear autumn morning: mist over the fields, smoke from chimneys, the village preparing for winter. Thoughtful, cozy and steady.",
                        "About 84 BPM, in E-flat major with turns toward C minor. The piano leads with a warm, singing melody, the guitar and upright bass keep a walking pulse, and the strings rise gently under the second section.")],
    "winter": [acoustic("A quiet snowy winter day: fresh snow on the rooftops, crackling hearths, hushed and peaceful, with a feeling of warmth indoors.",
                        "About 70 BPM, in E major, spacious and slow. The piano plays a delicate melody in its high register, the guitar adds soft harmonics, and the strings hold long, glowing chords; the flute appears low and breathy in the second section."),
               acoustic("A clear, starry winter night over a sleeping village: cold air, bright stars, smoke curling from chimneys. Serene, tender and a little magical.",
                        "About 66 BPM, in B-flat major, a slow 3/4. The flute carries a gentle, lullaby-like melody, the piano answers with soft chords, and the upright bass and low strings give a warm, steady floor.")],
    "cave": [acoustic("Exploring dark underground caverns beneath a peaceful farming valley: dripping water, glowing crystals, echoing tunnels. Dark and mysterious, but curious and wondrous rather than frightening.",
                      "About 66 BPM, in D Dorian, slow and spacious with long cavernous reverb. Low sustained strings and a bowed upright bass form a deep floor, the piano plays sparse low notes and quiet clusters of high notes like dripping water, and a breathy low flute plays a searching, modal melody. Use the same instruments as a gentle pastoral game soundtrack, but darker and sparser."),
             acoustic("Deep in the old copper mines: lantern light on stone walls, distant echoes, ancient secrets. Brooding and enigmatic, with a sense of slow discovery.",
                      "About 72 BPM, in C minor with Phrygian colour, patient and steady. The guitar picks slow, hollow open-string patterns, the strings swell and recede like breathing, the piano answers with low, resonant chords, and the flute enters only in the second section with a haunting line. Use the same instruments as a gentle pastoral game soundtrack, but darker and sparser.")],
    "spring_night": [night("A cool spring night after the planting: frogs by the pond, damp earth, the village lights going out one by one.",
                           "About 62 BPM, in A minor moving through F major and back, a slow 4/4. The felt piano carries a simple, unhurried melody over soft guitar arpeggios; long string chords swell under the second section."),
                     night("A misty spring midnight on the farm: the fields asleep, a thin moon, the last lantern in the farmhouse window.",
                           "About 58 BPM, in D minor, a slow, rocking 3/4. The guitar leads with a quiet, searching melody, the piano answers with soft low chords, and a low, breathy flute appears once in the second section.")],
    "summer_night": [night("A warm, still summer night: crickets, fireflies drifting over the fields, heat slowly leaving the stones of the village square.",
                           "About 66 BPM, in E minor with turns to C major, slow and swaying. The piano plays a drowsy, lingering melody, the guitar keeps a soft, sparse pulse, and the strings hold long, warm chords."),
                     night("A late summer night under a sky full of stars: the tavern long closed, a warm breeze through the tall crops, everyone else asleep.",
                           "About 60 BPM, in B minor moving to G major, a slow 4/4 with lots of space. The guitar leads with a tender, wandering melody, the upright bass plays a few long notes, and the piano adds quiet, high answers.")],
    "autumn_night": [night("A long autumn night: cold wind, dry leaves skittering across the paths, a harvest moon, smoke from the last warm chimneys.",
                           "About 60 BPM, in C minor, slow and heavy-hearted. The piano carries a melancholy melody in its middle register, low strings sustain beneath, and the guitar plays sparse, falling arpeggios."),
                     night("A foggy autumn midnight: the fields stripped after harvest, an owl calling, the farmhouse dark and quiet.",
                           "About 56 BPM, in F minor with moments in A-flat major, a slow 3/4. The guitar leads with a hushed, searching line, a low, breathy flute answers once in the second section, and the strings breathe slowly underneath.")],
    "winter_night": [night("A deep, cold winter night: snow falling silently on the rooftops, frozen fields, every window dark, the world holding its breath.",
                           "About 54 BPM, in E minor, very slow and spacious. The piano plays a sparse, fragile melody with long silences, the strings hold cold, glassy chords, and the guitar adds a few soft harmonics."),
                     night("A long midwinter night: wind over the frozen pond, a faint glow from a banked hearth, the village asleep under heavy snow.",
                           "About 58 BPM, in G minor moving to E-flat major, a slow 4/4. The guitar and piano share a quiet, lullaby-like melody, the upright bass and low strings form a deep, steady floor, and nothing hurries.")],
    "rain_night": [night("A rainy night in the village: steady rain on the roofs, water running in the gutters, warm windows going dark one by one.",
                         "About 60 BPM, in D minor moving to B-flat major, a slow 4/4. The felt piano plays a soft, rain-like melody of gently falling notes, the guitar adds quiet arpeggios underneath, and low strings hold long chords like the sound of the downpour."),
                   night("A stormy night on the farm: rain against the farmhouse, a distant rumble over the hills, the fields soaked and dark.",
                         "About 56 BPM, in G minor, a slow, heavy 3/4. The guitar leads with a low, brooding melody, the upright bass and low strings swell and recede like gusts of wind, and the piano answers with a few quiet, high notes.")],
    "snow_night": [night("Snow falling at night: big soft flakes drifting past the lanterns, the whole valley muffled and still, footprints filling in behind you.",
                         "About 54 BPM, in C-sharp minor moving to E major, very slow and weightless. The piano plays delicate, high, chime-like notes like falling snow, the strings hold hushed, airy chords, and the guitar adds a few soft harmonics; the flute appears once, low and breathy.")],
    "ship": ["""Chillout ambient science-fiction background music for the interior of a small crashed starship and its \
opening cutscene in a cozy pixel-art farming game. Calm, curious and a little lonely: soft console lights, the \
hum of engines, a planet glowing outside the window.

Instrumentation: modern warm analog synthesizer pads, a soft rounded synth bassline with a gentle groove, \
slowly evolving arpeggiated synths, airy textures, and a very soft downtempo beat with muted kick and light \
hi-hats. Wide stereo and spacious reverb. Entirely instrumental.

Composition: about 86 BPM, in D minor moving to F major, downtempo. A clear, memorable melodic motif played \
by a soft synth lead, a contrasting middle section where the beat drops out to just pads and bass, then the \
motif returns fuller. Real development across the piece rather than a short loop. The ending settles gently so \
the piece can loop.

Avoid: vocals, lyrics, harsh or aggressive EDM drops, distorted synths, loud drums, and repetitive one-bar riffs."""],
}


def api_key():
    if os.environ.get("OPENROUTER_API_KEY"): return os.environ["OPENROUTER_API_KEY"]
    if ENV_FILE.exists():
        for line in ENV_FILE.read_text().splitlines():
            name, _, value = line.partition("=")
            if name.strip().removeprefix("export ").strip() == "OPENROUTER_API_KEY":
                return value.strip().strip("\"'")
    sys.exit(f"No OPENROUTER_API_KEY in the environment or {ENV_FILE}")


def audio_extension(data):
    if data[:4] == b"RIFF": return "wav"
    if data[:4] == b"OggS": return "ogg"
    if data[:4] == b"fLaC": return "flac"
    if data[:3] == b"ID3" or data[:2] in (b"\xff\xfb", b"\xff\xf3", b"\xff\xf2"): return "mp3"
    return "bin"


def request_song(key, prompt, seed):
    body = {"model": MODEL, "messages": [{"role": "user", "content": prompt}], "modalities": ["text", "audio"],
            "audio": {"format": "wav"}, "stream": True, "seed": seed}
    request = urllib.request.Request("https://openrouter.ai/api/v1/chat/completions", data=json.dumps(body).encode(),
                                     headers={"Authorization": "Bearer " + key, "Content-Type": "application/json"})
    # Audio arrives as base64 pieces spread over the stream. Pieces may split the base64 text anywhere,
    # so we join the text first and decode once at the end.
    pieces, text, usage = [], [], None
    try:
        with urllib.request.urlopen(request, timeout=600) as response:
            for raw in response:
                line = raw.decode().strip()
                if not line.startswith("data:") or line == "data: [DONE]": continue
                chunk = json.loads(line[5:])
                if "error" in chunk: sys.exit(f"OpenRouter error: {chunk['error']}")
                usage = chunk.get("usage") or usage
                for choice in chunk.get("choices", []):
                    delta = choice.get("delta", {})
                    if delta.get("content"): text.append(delta["content"])
                    if (delta.get("audio") or {}).get("data"): pieces.append(delta["audio"]["data"])
    except urllib.error.HTTPError as error:
        sys.exit(f"OpenRouter returned HTTP {error.code}: {error.read().decode()[:800]}")
    if not pieces: sys.exit("The response had no audio. Text received: " + "".join(text)[:800])
    return base64.b64decode("".join(pieces)), "".join(text), usage


def generate(args):
    key = api_key()
    CANDIDATES.mkdir(parents=True, exist_ok=True)
    for index in range(args.count):
        seed = args.seed + index
        variants = THEMES[args.theme]
        prompt = pathlib.Path(args.prompt_file).read_text() if args.prompt_file else variants[(args.variant + index) % len(variants)]
        print(f"Requesting {args.theme} candidate {index + 1}/{args.count} (seed {seed})...", flush=True)
        audio, text, usage = request_song(key, prompt, seed)
        stem = CANDIDATES / f"{args.theme}-{time.strftime('%Y%m%d-%H%M%S')}-seed{seed}"
        path = stem.with_suffix("." + audio_extension(audio))
        path.write_bytes(audio)
        stem.with_suffix(".json").write_text(json.dumps({"model": MODEL, "theme": args.theme, "seed": seed, "prompt": prompt, "text": text, "usage": usage}, indent=2))
        print(f"  saved {path.relative_to(ROOT)} ({len(audio) // 1024} KB){' · cost ' + str(usage.get('cost')) if usage else ''}")


def install(args):
    source = pathlib.Path(args.candidate).resolve()
    if not source.exists(): sys.exit(f"No such candidate: {source}")
    details = source.with_suffix(".json")
    theme = args.theme or (json.loads(details.read_text()).get("theme") if details.exists() else None)
    if theme not in THEMES: sys.exit(f"Can't tell which theme {source.name} belongs to; pass --theme.")
    AUDIO.mkdir(parents=True, exist_ok=True)
    target = AUDIO / f"{args.name}.ogg"
    # Loudness normalisation keeps the new track at a similar level to the rest of the soundtrack.
    command = ["ffmpeg", "-loglevel", "error", "-y", "-i", str(source), "-af", "loudnorm=I=-20:TP=-2:LRA=11",
               "-ar", "44100", "-ac", "2", "-c:a", "libvorbis", "-q:a", "5", str(target)]
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode: sys.exit("ffmpeg failed:\n" + result.stderr[-1500:])
    # The game reads this manifest to know each track's theme and menu label.
    manifest = json.loads(MANIFEST.read_text()) if MANIFEST.exists() else {}
    manifest[args.name] = {"label": args.label, "theme": theme, "file": target.name}
    MANIFEST.write_text(json.dumps(dict(sorted(manifest.items())), indent=2) + "\n")
    print(f"Installed {target.relative_to(ROOT)} as {theme} track \"{args.label}\" ({target.stat().st_size // 1024} KB)")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    commands = parser.add_subparsers(dest="command", required=True)
    make = commands.add_parser("generate", help="Request new candidate songs from Lyria 3 Pro.")
    make.add_argument("--theme", choices=THEMES, required=True, help="Which kind of song to request; candidates cycle through the theme's prompt variants.")
    make.add_argument("--count", type=int, default=1, help="How many candidates to request (about $0.08 each).")
    make.add_argument("--variant", type=int, default=0, help="Which of the theme's prompt variants the first candidate uses (0-based).")
    make.add_argument("--seed", type=int, default=1, help="Seed of the first candidate; later ones count up from it.")
    make.add_argument("--prompt-file", help="Use the text of this file instead of the built-in prompt.")
    put = commands.add_parser("install", help="Convert a chosen candidate into the game's audio folder.")
    put.add_argument("candidate", help="Path to a file in internal/music/.")
    put.add_argument("--name", required=True, help="Track id; the file becomes src/native/audio/music/<name>.ogg.")
    put.add_argument("--label", required=True, help="Name shown in the development menu's music list.")
    put.add_argument("--theme", choices=THEMES, help="Override the theme recorded with the candidate.")
    args = parser.parse_args()
    generate(args) if args.command == "generate" else install(args)


if __name__ == "__main__":
    main()
