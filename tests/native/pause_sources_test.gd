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
	game.inventory()
	var time=game.state.total()
	game.toggle_pause()
	game._process(1)
	game.toggle_pause()
	game._process(1)
	check(game.state.total()==time and game.window_open,"Space cannot release the inventory's own pause")
	game.close_window()
	game._process(1)
	check(game.state.total()>time,"time resumes once both inventory and manual pause are released")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
