extends Node

signal lightning

const TRACKS = ["music","birds","crickets","drips","wreck","wildgrowth","crash","laser","laser_hit","explosion","rain","thunder","mining","bridge_electrical","bridge_klaxon","decloak"]
# The original theme is built by make_audio.py. The other songs come from generate_music.py, which
# stores them as Ogg Vorbis and lists each one's theme and menu label in this manifest.
const MUSIC_MANIFEST = "res://audio/music/tracks.json"
const MUSIC_FADE_SECONDS = 1.5
var mining: AudioStreamPlayer
var rain: AudioStreamPlayer
var thunder: AudioStreamPlayer
var rain_weight=0.0
var thunder_wait=18.0
var thunder_pending=-1.0
var weather_rng=RandomNumberGenerator.new()
var battle: Dictionary={}
var crash: AudioStreamPlayer
var cinematic=false
var bridge_electrical: AudioStreamPlayer
var bridge_klaxon: AudioStreamPlayer
var testing = false
var music: AudioStreamPlayer
var birds: AudioStreamPlayer
var crickets: AudioStreamPlayer
var drips: AudioStreamPlayer
var wreck: AudioStreamPlayer
var spell: AudioStreamPlayer
var streams: Dictionary = {}
# id -> {label, theme, path}
var music_tracks: Dictionary = {}
# "auto" shuffles songs that suit the moment; a track id plays only that song, on repeat.
var music_choice = "auto"
var music_track = ""
var music_theme = ""
var wanted_theme = "spring"
var music_fade = 1.0
var music_rng = RandomNumberGenerator.new()
var music_level = 0.35
var ambience_level = 0.65
var effects_level = 0.65
var dirty = false
var active = false
var current_mix = {"birds":0.0,"crickets":0.0,"drips":0.0,"wreck":0.0}

func _ready() -> void:
	weather_rng.randomize()
	music_rng.randomize()
	load_music_tracks()
	for name in TRACKS:
		var stream=AudioStreamWAV.load_from_file("res://audio/"+name+".wav")
		if name not in ["wildgrowth","crash","laser","laser_hit","explosion","thunder","mining","decloak"]:
			stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
			stream.loop_end=stream.data.size()/2
		streams[name]=stream
	music=_player("music")
	music.finished.connect(_on_music_finished)
	birds=_player("birds")
	crickets=_player("crickets")
	drips=_player("drips")
	wreck=_player("wreck")
	crash=_player("crash")
	spell=_player("wildgrowth")
	rain=_player("rain")
	thunder=_player("thunder")
	mining=_player("mining")
	bridge_electrical=_player("bridge_electrical")
	bridge_klaxon=_player("bridge_klaxon")
	mining.max_polyphony=4
	spell.max_polyphony=4
	for name in ["laser","laser_hit","explosion","decloak"]:
		battle[name]=_player(name)
		battle[name].max_polyphony=8
	if not testing: load_preferences()
	_apply_volumes()

func _player(track: String) -> AudioStreamPlayer:
	var player=AudioStreamPlayer.new()
	player.stream=streams[track]
	player.volume_db=-80.0
	add_child(player)
	return player

func mix_for(minute: float,environment: String,season: String,cave_weight = 0.0) -> Dictionary:
	if environment=="wreck": return {"birds":0.0,"crickets":0.0,"drips":0.0,"wreck":1.0}
	if environment in ["ship","indoors"]: return {"birds":0.0,"crickets":0.0,"drips":0.0,"wreck":0.0}
	if environment in ["cave","mine"]: return {"birds":0.0,"crickets":0.0,"drips":1.0,"wreck":0.0}
	var day=smoothstep(330.0,420.0,minute)*(1.0-smoothstep(1110.0,1200.0,minute))
	var bird_season={"spring":1.0,"summer":0.85,"autumn":0.25,"winter":0.25}.get(season,1.0)
	var insect_season={"spring":0.55,"summer":1.0,"autumn":0.65,"winter":0.0}.get(season,0.55)
	var shelter=clampf(cave_weight,0.0,1.0)
	return {"birds":day*bird_season*(1.0-shelter),"crickets":(1.0-day)*insect_season*(1.0-shelter),"drips":shelter,"wreck":0.0}

func load_music_tracks() -> void:
	# The original theme has a theme of its own that nothing shuffles, so it only plays when chosen.
	music_tracks={"original":{"label":"Original","theme":"classic","path":"res://audio/music.wav"}}
	if not FileAccess.file_exists(MUSIC_MANIFEST): return
	var manifest=JSON.parse_string(FileAccess.get_file_as_string(MUSIC_MANIFEST))
	if not manifest is Dictionary: return
	for id in manifest:
		var entry=manifest[id]
		if entry is Dictionary and entry.get("label") is String and entry.get("theme") is String and entry.get("file") is String:
			music_tracks[id]={"label":entry.label,"theme":entry.theme,"path":MUSIC_MANIFEST.get_base_dir().path_join(entry.file)}

# An empty theme means no music at all.
static func music_theme_for(environment: String,season: String,weather: String) -> String:
	if environment=="wreck": return ""
	if environment=="ship": return "ship"
	if environment in ["cave","mine"]: return "cave"
	# Winter rain falls as snow, so it keeps the winter songs.
	if weather=="rainy" and season!="winter": return "rain"
	return season

func tracks_for_theme(theme: String) -> Array:
	return music_tracks.keys().filter(func(id):return music_tracks[id].theme==theme)

func choose_music(choice: String) -> bool:
	if choice!="auto" and not music_tracks.has(choice): return false
	music_choice=choice
	dirty=true
	_play_fitting(wanted_theme)
	return true

# Picks a random song for the theme, avoiding the one that just played when there's another choice.
func _play_next_for(theme: String) -> void:
	var ids=tracks_for_theme(theme)
	if ids.is_empty(): ids=tracks_for_theme("spring")
	if ids.size()>1: ids.erase(music_track)
	music_theme=theme
	_play_track(ids[music_rng.randi_range(0,ids.size()-1)],false)

func _play_track(id: String,repeat: bool) -> void:
	var stream: AudioStream
	if id=="original":
		stream=streams.music
		stream.loop_mode=AudioStreamWAV.LOOP_FORWARD if repeat else AudioStreamWAV.LOOP_DISABLED
	else:
		stream=AudioStreamOggVorbis.load_from_file(music_tracks[id].path)
		stream.loop=repeat
	music.stream=stream
	music_track=id
	if active: music.play()
	_apply_volumes()

func _on_music_finished() -> void:
	if active and wanted_theme!="" and _chosen_song(wanted_theme)=="": _play_next_for(wanted_theme)

# The song that should play right now: inside the ship it's always the ship music, elsewhere a
# chosen song wins, and "" means any song of the current theme will do.
func _chosen_song(theme: String) -> String:
	return music_choice if music_choice!="auto" and theme!="ship" else ""

# Fades the current song out when the moment calls for something else, starts what fits, and
# fades it in. This also brings the music back up after the cutscene.
func update_music(theme: String,dt: float) -> void:
	wanted_theme=theme
	if theme=="":
		music_fade=maxf(0.0,music_fade-dt/MUSIC_FADE_SECONDS)
		_apply_volumes()
		return
	var chosen=_chosen_song(theme)
	var fits=music_track==chosen if chosen!="" else music_track!="" and theme==music_theme
	# A song can finish while a silent location suppresses its successor.
	if music_track=="" or (active and not music.playing): _play_fitting(theme)
	elif not fits:
		music_fade=maxf(0.0,music_fade-dt/MUSIC_FADE_SECONDS)
		if music_fade==0.0: _play_fitting(theme)
		_apply_volumes()
		return
	music_fade=minf(1.0,music_fade+dt/MUSIC_FADE_SECONDS)
	_apply_volumes()

func _play_fitting(theme: String) -> void:
	var chosen=_chosen_song(theme)
	if chosen=="": _play_next_for(theme)
	else:
		music_theme=""
		_play_track(chosen,true)

func update_context(minute: float,environment: String,season: String,cave_weight: float,dt: float,weather: String="") -> void:
	update_music(music_theme_for(environment,season,weather),dt)
	var target=mix_for(minute,environment,season,cave_weight)
	var blend=1.0-exp(-dt*1.8)
	for name in current_mix: current_mix[name]=lerpf(current_mix[name],target[name],blend)
	_apply_volumes()

func _db(value: float) -> float:
	return linear_to_db(value) if value>0.0001 else -80.0

func update_weather(mode: String,outdoors: bool,dt: float,allow_lightning: bool=true,snow: bool=false) -> void:
	var wet=outdoors and mode=="rainy" and not cinematic
	rain_weight=lerpf(rain_weight,1.0 if wet and not snow else 0.0,1-exp(-dt*1.8))
	if wet and active and allow_lightning:
		if thunder_pending>=0:
			thunder_pending-=dt
			if thunder_pending<=0:
				thunder.play()
				thunder_pending=-1
		thunder_wait-=dt
		if thunder_wait<=0:
			thunder_pending=weather_rng.randf_range(1.0,3.0)
			lightning.emit()
			thunder_wait=weather_rng.randf_range(24,45)
	else:
		thunder.stop()
		thunder_wait=18
		thunder_pending=-1
	_apply_volumes()

func _apply_volumes() -> void:
	music.volume_db=_db(music_level*music_fade if not cinematic else 0.0)
	crash.volume_db=_db(effects_level)
	birds.volume_db=_db(ambience_level*current_mix.birds if not cinematic else 0.0)
	crickets.volume_db=_db(ambience_level*current_mix.crickets if not cinematic else 0.0)
	drips.volume_db=_db(ambience_level*current_mix.drips if not cinematic else 0.0)
	wreck.volume_db=_db(ambience_level*current_mix.wreck if not cinematic else 0.0)
	spell.volume_db=_db(effects_level)
	mining.volume_db=_db(effects_level if not cinematic else 0.0)
	rain.volume_db=_db(ambience_level*rain_weight if not cinematic else 0.0)
	thunder.volume_db=_db(ambience_level*0.65 if not cinematic else 0.0)
	for player in battle.values(): player.volume_db=_db(effects_level)
	bridge_electrical.volume_db=_db(effects_level*0.65)
	bridge_klaxon.volume_db=_db(effects_level*0.55)

func set_bridge_ambience(interior: bool,descent: bool) -> void:
	for pair in [[bridge_electrical,interior],[bridge_klaxon,interior and descent]]:
		if pair[1] and not pair[0].playing: pair[0].play()
		elif not pair[1] and pair[0].playing: pair[0].stop()

func set_cinematic(value: bool) -> void:
	cinematic=value
	if not value: set_bridge_ambience(false,false)
	# The intro has only sound effects. Whatever song keeps running underneath starts from silence
	# afterwards, so the next theme fades in cleanly instead of that song cutting back in.
	if value: music_fade=0.0
	_apply_volumes()

func start() -> void:
	if active: return
	active=true
	for player in [music,birds,crickets,drips,wreck,rain]: player.play()

func stop() -> void:
	active=false
	for player in [music,birds,crickets,drips,wreck,spell,crash,rain,thunder,mining]: player.stop()
	for player in battle.values(): player.stop()
	set_bridge_ambience(false,false)

func shutdown() -> void:
	# Playback can be queued until the next frame, including a just-cast spell.
	await get_tree().process_frame
	await get_tree().process_frame
	stop()
	# Let the audio thread release its playback references before the scene exits.
	await get_tree().create_timer(0.5).timeout

func set_level(channel: String,value: float) -> void:
	if not is_finite(value): return
	match channel:
		"music": music_level=clampf(value,0.0,1.0)
		"ambience": ambience_level=clampf(value,0.0,1.0)
		"effects": effects_level=clampf(value,0.0,1.0)
		_: return
	dirty=true
	_apply_volumes()

func play_spell(id: String) -> bool:
	if id not in ["wildgrowth","hearthmend","emberthread"] or effects_level<=0.0: return false
	spell.pitch_scale={"wildgrowth":1.0,"hearthmend":0.85,"emberthread":1.3}[id]
	spell.play()
	return true

func play_battle(id: String,friendly: bool=false) -> void:
	if not battle.has(id) or effects_level<=0: return
	battle[id].pitch_scale=1.0 if id=="decloak" else (1.06 if id=="laser" and friendly else 0.93 if id=="laser" else 1.0)/4.0
	battle[id].play()

func preferences_path() -> String:
	return ProjectSettings.globalize_path("res://../../internal/audio.cfg").simplify_path()

func load_preferences() -> void:
	var config=ConfigFile.new()
	if config.load(preferences_path())!=OK: return
	for name in ["music","ambience","effects"]:
		var value=config.get_value("volume",name,null)
		if (value is float or value is int) and is_finite(float(value)): set_level(name,value)
	var choice=config.get_value("music","choice","auto")
	if choice is String: choose_music(choice)
	dirty=false

func save_preferences() -> void:
	if testing or not dirty: return
	var config=ConfigFile.new()
	config.set_value("volume","music",music_level)
	config.set_value("volume","ambience",ambience_level)
	config.set_value("volume","effects",effects_level)
	config.set_value("music","choice",music_choice)
	if config.save(preferences_path())==OK: dirty=false
