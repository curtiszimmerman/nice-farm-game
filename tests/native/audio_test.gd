extends SceneTree

const Sound = preload("res://sound.gd")
const Game = preload("res://game.gd")
var failed = false
var count = 0

class IsolatedSound extends "res://sound.gd":
	var config_file = ""
	func preferences_path() -> String:
		return config_file

func check(condition: bool,description: String) -> void:
	if condition:
		count+=1
		print("PASS: "+description)
	else:
		failed=true
		push_error("FAIL: "+description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var sound=IsolatedSound.new()
	sound.config_file=ProjectSettings.globalize_path("res://../../internal/verification/audio-test-%d.cfg" % Time.get_ticks_usec()).simplify_path()
	sound.testing=true
	root.add_child(sound)
	var day=sound.mix_for(720.0,"farm","spring")
	var night=sound.mix_for(60.0,"town","spring")
	check(day.birds>0.9 and day.crickets==0.0 and night.birds==0.0 and night.crickets>0.0,"farm and town change from birds to crickets with daylight")
	var dawn=sound.mix_for(375.0,"farm","spring")
	check(dawn.birds>0 and dawn.birds<day.birds and dawn.crickets>0,"dawn blends environmental tracks instead of cutting abruptly")
	var summer=sound.mix_for(60.0,"farm","summer")
	var winter=sound.mix_for(60.0,"farm","winter")
	check(summer.crickets>night.crickets and winter.crickets==0.0,"season affects insect activity")
	check(sound.mix_for(720.0,"farm","winter").birds<day.birds,"winter birds are quieter than spring birds")
	var cave_day=sound.mix_for(720.0,"cave","spring")
	var cave_night=sound.mix_for(60.0,"mine","winter")
	check(cave_day==cave_night and cave_day.drips==1.0 and cave_day.birds==0.0 and cave_day.crickets==0.0,"cave and mine drips ignore daylight and exclude outdoor wildlife")
	check(sound.mix_for(60,"indoors","summer").crickets==0 and sound.mix_for(720,"indoors","spring").birds==0,"house walls exclude outdoor wildlife ambience")
	var entrance=sound.mix_for(720.0,"farm","spring",0.5)
	check(entrance.drips>0 and entrance.birds>0 and entrance.birds<day.birds,"a mine entrance blends nearby drips with outdoor sound")
	sound.start()
	await process_frame
	check(sound.music.playing and sound.birds.playing and sound.crickets.playing and sound.drips.playing,"music and environmental layers play independently")
	sound.set_level("music",0.0)
	check(sound.music.volume_db<=-79 and sound.ambience_level>0.0,"muting music leaves environmental ambience enabled")
	sound.set_level("ambience",0.0)
	sound.update_context(720.0,"farm","spring",0.0,10.0)
	check(sound.birds.volume_db<=-79 and sound.drips.volume_db<=-79,"ambient volume independently silences environmental layers")
	sound.set_level("effects",0.0)
	check(not sound.play_spell("wildgrowth"),"muted effects do not play a spell")
	sound.set_level("effects",0.6)
	check(sound.play_spell("wildgrowth") and sound.spell.playing,"Wildgrowth plays its dedicated one-shot sound")
	check(not sound.play_spell("unknown"),"unimplemented spells do not borrow another spell's sound")
	check(sound.music_theme_for("farm","summer","sunny")=="summer" and sound.music_theme_for("town","spring","rainy")=="rain","outdoor music follows the season, and rainy days get rain songs")
	check(sound.music_theme_for("farm","winter","rainy")=="winter","winter rain falls as snow, so winter songs keep playing")
	check(sound.music_theme_for("cave","summer","rainy")=="cave" and sound.music_theme_for("ship","spring","sunny")=="ship","caves and the ship interior have their own music")
	check(sound.music_theme_for("wreck","spring","sunny")=="","the first visit to the wrecked ship has no music")
	check(sound.mix_for(720.0,"wreck","spring").wreck==1.0 and sound.mix_for(720.0,"ship","spring").wreck==0.0 and sound.mix_for(720.0,"farm","spring").wreck==0.0,"wreck sounds belong to the first visit aboard only")
	var themes=["spring","summer","autumn","winter","rain","cave","ship"]
	check(themes.all(func(theme):return not sound.tracks_for_theme(theme).is_empty()),"every theme has songs to play")
	var songs=sound.music_tracks.keys().filter(func(id):return id!="original")
	check(songs.all(func(id):
		var stream=AudioStreamOggVorbis.load_from_file(sound.music_tracks[id].path)
		return stream!=null and stream.get_length()>120),"every generated song loads as a full-length piece")
	check(sound.music_tracks[sound.music_track].theme=="spring","a spring day outdoors plays a spring song")
	for i in range(4): sound.update_music("summer",0.5)
	check(sound.music_tracks[sound.music_track].theme=="summer" and not sound.music.stream.loop,"summer songs take over and hand over to the next song instead of repeating")
	var summer_song=sound.music_track
	for i in range(4): sound.update_music("summer",0.5)
	check(is_equal_approx(sound.music_fade,1.0),"the new song fades in rather than starting at full volume")
	sound.update_music("winter",0.5)
	check(sound.music_track==summer_song and sound.music_fade<1.0,"a change of theme fades the current song out first")
	for i in range(4): sound.update_music("winter",0.5)
	check(sound.music_tracks[sound.music_track].theme=="winter","once faded out, a winter song takes over")
	var winter_song=sound.music_track
	sound._on_music_finished()
	check(sound.music_track!=winter_song and sound.music_tracks[sound.music_track].theme=="winter","when a song ends, a different song of the same theme follows")
	check(sound.choose_music("cave_1") and sound.music_track=="cave_1" and sound.music.stream.loop,"choosing a song plays it on repeat")
	sound.update_music("summer",5.0)
	check(sound.music_track=="cave_1" and sound.music_fade==1.0,"a chosen song stays put whatever the season")
	for i in range(8): sound.update_music("ship",0.5)
	check(sound.music_tracks[sound.music_track].theme=="ship" and sound.music_choice=="cave_1","the ship interior always plays the ship music, even with a song chosen")
	sound._on_music_finished()
	check(sound.music_tracks[sound.music_track].theme=="ship","the ship music carries on inside the ship when a song ends")
	for i in range(8): sound.update_music("summer",0.5)
	check(sound.music_track=="cave_1" and sound.music.stream.loop and is_equal_approx(sound.music_fade,1.0),"leaving the ship brings the chosen song back")
	check(not sound.choose_music("missing") and sound.music_choice=="cave_1","unknown track names leave the current music alone")
	# Earlier checks muted the music channel, so turn it back up to prove the cutscene silences it.
	sound.set_level("music",0.5)
	sound.set_cinematic(true)
	check(sound.music.volume_db<=-79,"the intro cutscene has no music, even with a song chosen")
	sound.choose_music("auto")
	check(sound.music.volume_db<=-79,"switching to automatic music during the cutscene keeps it silent")
	sound.set_cinematic(false)
	sound.update_context(720.0,"ship","spring",0.0,0.1)
	check(sound.music_tracks[sound.music_track].theme=="ship" and sound.music.volume_db<-30,"after the cutscene the ship music starts quietly inside the ship instead of the song left playing underneath")
	for i in range(20): sound.update_context(720.0,"ship","spring",0.0,0.1)
	check(sound.music_tracks[sound.music_track].theme=="ship" and is_equal_approx(sound.music_fade,1.0),"the ship music fades up to full volume")
	await process_frame
	check(sound.music.playing,"switching songs keeps the music playing")
	sound.choose_music("winter_2")
	sound.testing=false
	sound.set_level("music",0.22)
	sound.set_level("ambience",0.41)
	sound.set_level("effects",0.55)
	sound.save_preferences()
	sound.set_level("music",1.0)
	sound.set_level("ambience",1.0)
	sound.set_level("effects",1.0)
	sound.choose_music("auto")
	sound.load_preferences()
	check(is_equal_approx(sound.music_level,0.22) and is_equal_approx(sound.ambience_level,0.41) and is_equal_approx(sound.effects_level,0.55),"all three volume preferences survive file save and reload")
	check(sound.music_choice=="winter_2","the chosen music survives file save and reload")
	check(DirAccess.remove_absolute(sound.config_file)==OK,"isolated audio preference test stays inside project and cleans up")
	for name in sound.TRACKS:
		var stream=sound.streams[name]
		var samples=stream.data
		var peak=0
		for i in range(0,samples.size(),34): peak=maxi(peak,absi(samples.decode_s16(i)))
		check(peak>100 and peak<30000 and absi(samples.decode_s16(0))<50 and absi(samples.decode_s16(samples.size()-2))<50,"%s has audible unclipped PCM and quiet boundaries" % name)
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game)
	preload("fixture.gd").tools(game.state)
	await process_frame
	game.state.player_position=game.world.plot_position(0)+Vector2.UP*game.world.Grid.TILE_SIZE
	for slot in [0,3,1]:
		game.select_quick_slot(slot)
		preload("fixture.gd").activate(game)
	game.select_quick_slot(5)
	game.state.day=2
	game.cast_growth()
	check(game.sound.spell.playing,"successful gameplay cast triggers spell audio")
	game.sound.spell.stop()
	game.cast_growth()
	check(not game.sound.spell.playing,"rejected cast stays silent")
	game.sound_settings()
	check(game.ui.modal_box.get_child(3).get_child(1) is HSlider,"sound menu exposes independent volume sliders")
	game.ui.modal_box.get_child(3).get_child(1).value=80
	check(is_equal_approx(game.sound.music_level,0.8) and is_equal_approx(game.sound.ambience_level,0.65),"native music slider changes music without changing ambience")
	var farm_context=game.world.audio_context(game.world.plot_position(0))
	var mine_context=game.world.audio_context(game.world.site_position("ore"))
	check(farm_context.cave_weight==0 and mine_context.cave_weight>0.5,"world routes localized drips to the mine entrance")
	game.close_window()
	await game.sound.shutdown()
	game.queue_free()
	await sound.shutdown()
	sound.queue_free()
	await process_frame
	print("%d native audio checks passed" % count)
	quit(1 if failed else 0)
