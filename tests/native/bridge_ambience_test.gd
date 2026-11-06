extends SceneTree
const Game=preload("res://game.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	var intro=game.opening
	check(intro.has_method("bridge_planet_rect"),"the planet has independent motion within the bridge window")
	if intro.has_method("bridge_planet_rect"):
		intro.elapsed=21.5
		var different=0
		var gentle=true
		for i in range(60):
			intro.animation_time=i/60.0
			var planet=intro.bridge_planet_rect().position-intro.bridge_composition().planet.position+intro.bridge_offset()
			gentle=gentle and planet.length()<=2.5
			if planet!=intro.bridge_offset(): different+=1
		check(different>40,"the planet does not follow the bridge's rapid rattling")
		check(gentle,"the distant planet moves gently during descent")
	check(game.sound.has_method("set_bridge_ambience"),"bridge ambience is controlled separately from exterior battle audio")
	if game.sound.has_method("set_bridge_ambience"):
		check(is_equal_approx(game.sound.bridge_klaxon.stream.get_length(),4.5),"the klaxon loop is twenty-five percent shorter")
		check(is_equal_approx(db_to_linear(game.sound.bridge_klaxon.volume_db)/game.sound.effects_level,0.6875),"the klaxon output is twenty-five percent louder")
		for pair in [[2.0,0,false,false],[5.0,2,true,true],[13.0,4,true,true],[18.5,5,false,false],[21.5,6,true,true],[24.5,7,false,false]]:
			intro.elapsed=pair[0]
			intro.caption_step=pair[1]
			intro._process(0)
			check(game.sound.bridge_electrical.playing==pair[2] and game.sound.bridge_klaxon.playing==pair[3],"electrical and klaxon audio follow bridge cuts at "+str(pair[0]))
		game.sound.set_level("effects",0)
		check(game.sound.bridge_klaxon.volume_db<=-70,"effects mute silences the klaxon")
		intro.finish()
		check(not game.sound.bridge_electrical.playing and not game.sound.bridge_klaxon.playing,"finishing the intro stops bridge-only sounds")
	game.sound.choose_music("auto")
	game.sound.update_music("spring",2)
	var before=game.sound.music_track
	game.sound.update_music("cave",0.3)
	check(game.sound.music_track==before and game.sound.music_fade>0 and game.sound.music_fade<1,"area music still fades smoothly before switching")
	game.sound.update_music("cave",0.4)
	game.sound.update_music("cave",0.6)
	check(game.sound.music_theme=="cave" and is_equal_approx(game.sound.music_fade,1),"the faster area transition completes its fade out and fade in")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
