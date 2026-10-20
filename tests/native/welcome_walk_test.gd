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
	preload("fixture.gd").explore(game)
	var w=game.outdoors
	game.state.player_position=w.Grid.center(w.MOSS_ENCOUNTER_CELL)
	game.talk("moss")
	while game.window_open: game.ui.modal_box.get_child(3).pressed.emit()
	check(game.escort_path.any(func(p): return w.Grid.world_to_cell(p)==Vector2i(18,34)),"the captain follows the painted bend around the farmhouse")
	var moss=w.villagers.moss.position
	game._process(0.1)
	check(w.villagers.moss.position.distance_to(moss)<25,"Moss begins walking rather than jumping to another appointment")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
