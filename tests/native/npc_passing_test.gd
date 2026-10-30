extends SceneTree
const Game=preload("res://game.gd")
var failed=false
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	var w=game.outdoors
	for actor in w.villagers.values(): actor.visible=false
	var origin=Vector2i(75,75)
	for y in range(73,78):
		for x in range(73,82): w.solid_cells.erase(Vector2i(x,y))
	game.state.player_position=w.Grid.center(Vector2i(85,80))
	for trial in range(6):
		seed(trial+1)
		w.routes.clear()
		var a=w.villagers.moss
		var b=w.villagers.mayor
		a.visible=true
		b.visible=true
		a.position=w.Grid.center(origin)
		b.position=w.Grid.center(origin+Vector2i(4,0))
		for frame in range(600):
			w.elapsed+=0.04
			w.Bodies.walk_to(w,"moss",origin+Vector2i(4,0),0.04,56)
			w.Bodies.walk_to(w,"mayor",origin,0.04,56)
			if a.position.distance_to(b.position)<w.Bodies.RADIUS-0.1: failed=true
		if a.position.distance_to(w.Grid.center(origin+Vector2i(4,0)))>1 or b.position.distance_to(w.Grid.center(origin))>1: failed=true
	if failed: push_error("FAIL: head-on NPCs pass without overlap across six random encounters")
	else: print("PASS: head-on NPCs pass without overlap across six random encounters")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
