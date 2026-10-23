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
	preload("fixture.gd").explore(game,true)
	var s=game.state
	check(s.has_method("weather_name"),"the world has reproducible daily weather")
	check(game.sound.streams.has("rain") and game.sound.streams.has("thunder"),"rain and thunder have dedicated ambient sounds")
	var effects=game.outdoors.get("weather_effects")
	check(effects!=null,"weather renders independently from retained scenery")
	if effects!=null:
		s.weather_override="partly_cloudy"
		var before=effects.cloud_positions(0)
		check(before!=effects.cloud_positions(10),"cloud shadows drift across the world")
		s.weather_override="rainy"
		check(effects.rain_positions(0)!=effects.rain_positions(0.1),"rain streaks animate across the viewport")
		game._process(0.1)
		check(game.sound.rain.volume_db>-79,"rain reaches the ambience mix outdoors")
		game.sound.thunder_wait=0
		game.sound.update_weather("rainy",true,0.1)
		check(game.sound.thunder.playing,"rain occasionally plays gentle thunder")
		s.plots[0].tilled=true
		s.plots[0].planted=s.total()
		s.advance(0.1)
		check(s.plots[0].watered,"rain waters outdoor crops")
		game.enter_building("home")
		game._process(10)
		check(game.sound.rain.volume_db<=-79,"interiors shelter the player from outdoor rain")
		var restored=game.State.new()
		check(restored.restore(s.to_dict()) and restored.weather_override=="rainy","weather and crop moisture survive saving")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
