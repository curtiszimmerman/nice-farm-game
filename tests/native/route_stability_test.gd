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
	game.state.met_mayor=true
	var w=game.outdoors
	var moss=w.villagers.moss
	var start=Vector2i.ZERO
	for cell in w.road_cells:
		var straight=true
		for x in range(9):
			if not w.road_cells.has(cell+Vector2i(x,0)) or w.blocked(game.Grid.center(cell+Vector2i(x,0))): straight=false
		if straight:
			start=cell
			break
	check(start!=Vector2i.ZERO,"the connected road network provides a clear straight route for the movement regression")
	var destination=start+Vector2i(8,0)
	moss.position=game.Grid.center(start)
	w.routes.erase("moss")
	w.story_destinations.moss={"cell":destination,"sleeping":false,"room":""}
	var reversals=0
	var clear=true
	for i in range(200):
		game.state.player_position=game.Grid.center(start+Vector2i(i%20,2))
		var previous=moss.position
		w.update_villagers(0.04)
		if moss.position.x<previous.x-0.01: reversals+=1
		if w.blocked(moss.position): clear=false
	check(clear and reversals==0,"a moving player does not make Moss reverse repeatedly between path tiles")
	check(moss.position.distance_to(game.Grid.center(destination))<1,"Moss finishes his route while the player keeps changing cells")
	game.enter_building("hall")
	var room=game.world
	var actor=room.villagers.mayor
	actor.position=game.Grid.center(Vector2i(11,4))
	actor.visible=true
	room.routes.erase("mayor")
	var backwards=false
	for i in range(180):
		game.state.player_position=game.Grid.center(Vector2i(2+i%4,10))
		var previous=actor.position
		room.walk_actor("mayor",Vector2i(11,10),0.04,65)
		if actor.position.y<previous.y-0.01: backwards=true
	check(not backwards and actor.position.distance_to(game.Grid.center(Vector2i(11,10)))<1,"indoor routes also retain forward progress while the player moves")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
