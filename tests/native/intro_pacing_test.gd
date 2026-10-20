extends SceneTree
const Game=preload("res://game.gd")
var failed=false
func check(value: bool,label: String) -> void:
	if value: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	var intro=game.opening
	intro.set_process(false)
	intro._process(100)
	check(game.opening==intro and intro.elapsed<3,"the first introduction caption waits indefinitely for acknowledgement")
	var key=InputEventKey.new()
	key.pressed=true
	key.physical_keycode=KEY_SPACE
	game._input(key)
	check(not game.world_paused and intro.elapsed>=3,"space advances intro dialogue instead of pausing it")
	check(intro.has_method("shots_at"),"battle shots have individual launch and impact times")
	if intro.has_method("shots_at"):
		var shots=intro.call("shots_at",11.0)
		check(shots.size()<=2,"battle volleys leave readable gaps between shots")
	intro.finish()
	var before=game.ui.modal_box.get_child(2).text
	key.physical_keycode=KEY_E
	game._input(key)
	check(game.ui.modal_box.get_child(2).text!=before,"briefing dialogue advances on E")
	game.close_window(true)
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
