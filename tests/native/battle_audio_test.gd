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
	game.begin()
	var opening=game.opening
	check(opening.has_method("battle_events"),"battle sounds follow the same timeline as visible laser bolts")
	if opening.has_method("battle_events"):
		var first=opening.battle_events(-0.001,0.9)
		check(first.size()==2 and first[0].sound=="laser" and first[1].sound=="laser_hit" and is_equal_approx(first[1].time-first[0].time,0.82),"laser firing and impact sounds match the bolt travel duration")
		check(opening.battle_events(5.84,5.86).any(func(event):return event.friendly and event.sound=="laser"),"return fire has its own correctly timed shot")
		opening.caption_step=2
		opening.elapsed=3.4
		opening._process(0.02)
		check(game.sound.battle.laser.playing,"the opening actually plays the firing sound")
		check(is_equal_approx(game.sound.battle.laser.pitch_scale,0.93/4.0),"enemy lasers sound two octaves lower")
		game.sound.play_battle("laser_hit")
		check(is_equal_approx(game.sound.battle.laser_hit.pitch_scale,0.25),"hull hits sound two octaves lower")
		opening.elapsed=18
		opening.caption_step=5
		opening._process(0.02)
		check(game.sound.battle.explosion.playing and opening.explosion_played,"enemy destruction plays its explosion once")
		check(is_equal_approx(game.sound.battle.explosion.pitch_scale,0.25),"ship destruction sounds two octaves lower")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
