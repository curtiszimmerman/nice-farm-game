extends Node

const TRACKS = ["music","birds","crickets","drips","wildgrowth"]
var testing = false
var music: AudioStreamPlayer
var birds: AudioStreamPlayer
var crickets: AudioStreamPlayer
var drips: AudioStreamPlayer
var spell: AudioStreamPlayer
var streams: Dictionary = {}
var music_level = 0.35
var ambience_level = 0.65
var effects_level = 0.65
var dirty = false
var active = false
var current_mix = {"birds":0.0,"crickets":0.0,"drips":0.0}

func _ready() -> void:
	for name in TRACKS:
		var stream=AudioStreamWAV.load_from_file("res://audio/"+name+".wav")
		if name!="wildgrowth":
			stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
			stream.loop_end=stream.data.size()/2
		streams[name]=stream
	music=_player("music")
	birds=_player("birds")
	crickets=_player("crickets")
	drips=_player("drips")
	spell=_player("wildgrowth")
	spell.max_polyphony=4
	if not testing: load_preferences()
	_apply_volumes()

func _player(track: String) -> AudioStreamPlayer:
	var player=AudioStreamPlayer.new()
	player.stream=streams[track]
	player.volume_db=-80.0
	add_child(player)
	return player

func mix_for(minute: float,environment: String,season: String,cave_weight = 0.0) -> Dictionary:
	if environment=="indoors": return {"birds":0.0,"crickets":0.0,"drips":0.0}
	if environment in ["cave","mine"]: return {"birds":0.0,"crickets":0.0,"drips":1.0}
	var day=smoothstep(330.0,420.0,minute)*(1.0-smoothstep(1110.0,1200.0,minute))
	var bird_season={"spring":1.0,"summer":0.85,"autumn":0.5,"winter":0.18}.get(season,1.0)
	var insect_season={"spring":0.55,"summer":1.0,"autumn":0.65,"winter":0.0}.get(season,0.55)
	var shelter=clampf(cave_weight,0.0,1.0)
	return {"birds":day*bird_season*(1.0-shelter),"crickets":(1.0-day)*insect_season*(1.0-shelter),"drips":shelter}

func update_context(minute: float,environment: String,season: String,cave_weight: float,dt: float) -> void:
	var target=mix_for(minute,environment,season,cave_weight)
	var blend=1.0-exp(-dt*1.8)
	for name in current_mix: current_mix[name]=lerpf(current_mix[name],target[name],blend)
	_apply_volumes()

func _db(value: float) -> float:
	return linear_to_db(value) if value>0.0001 else -80.0

func _apply_volumes() -> void:
	music.volume_db=_db(music_level)
	birds.volume_db=_db(ambience_level*current_mix.birds)
	crickets.volume_db=_db(ambience_level*current_mix.crickets)
	drips.volume_db=_db(ambience_level*current_mix.drips)
	spell.volume_db=_db(effects_level)

func start() -> void:
	if active: return
	active=true
	for player in [music,birds,crickets,drips]: player.play()

func stop() -> void:
	active=false
	for player in [music,birds,crickets,drips,spell]: player.stop()

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
	if id!="wildgrowth" or effects_level<=0.0: return false
	spell.play()
	return true

func preferences_path() -> String:
	return ProjectSettings.globalize_path("res://../../internal/audio.cfg").simplify_path()

func load_preferences() -> void:
	var config=ConfigFile.new()
	if config.load(preferences_path())!=OK: return
	for name in ["music","ambience","effects"]:
		var value=config.get_value("volume",name,null)
		if (value is float or value is int) and is_finite(float(value)): set_level(name,value)
	dirty=false

func save_preferences() -> void:
	if testing or not dirty: return
	var config=ConfigFile.new()
	config.set_value("volume","music",music_level)
	config.set_value("volume","ambience",ambience_level)
	config.set_value("volume","effects",effects_level)
	if config.save(preferences_path())==OK: dirty=false
