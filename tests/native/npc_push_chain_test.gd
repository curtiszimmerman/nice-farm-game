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
	for y in range(72,81):
		for x in range(73,79): w.solid_cells.erase(Vector2i(x,y))
	var family=["miller","miller_wife","miller_daughter"]
	for index in range(3):
		var actor=w.villagers[family[index]]
		actor.visible=true
		actor.data.sleeping=false
		actor.position=w.Grid.center(Vector2i(75,75))+Vector2(0,index*w.Bodies.RADIUS)
	game.state.player_position=w.villagers.miller.position-Vector2(0,w.Bodies.RADIUS)
	var start=game.state.player_position
	for frame in range(30): w.Bodies.player_step(w,Vector2(0,2),{})
	if game.state.player_position.y<start.y+50:
		failed=true
		push_error("FAIL: the player can push a touching column of three NPCs")
	else: print("PASS: the player can push a touching column of three NPCs")
	for id in family:
		for other in family:
			if id!=other and w.villagers[id].position.distance_to(w.villagers[other].position)<w.Bodies.RADIUS-0.01:
				failed=true
				push_error("FAIL: pushing preserves NPC separation")
	preload("fixture.gd").explore(game,true)
	game.state.met_mayor=true
	game.state.day=2
	game.state.minute=430
	w.update_villagers(0,true)
	game.enter_building("mill_home")
	game.state.player_position=game.world.Grid.center(game.world.layout.entry)+Vector2(64,0)
	var room=game.world
	game.state.minute=500
	var overlap=false
	var waiting=false
	for frame in range(1600):
		w.elapsed+=0.05
		room.elapsed=w.elapsed
		room.prepare_departures()
		w.update_villagers(0.05)
		room.update_villagers(0.05)
		if not waiting and w.villagers.miller.visible:
			w.conversation_holds.miller=true
			waiting=true
		if frame==300: w.conversation_holds.erase("miller")
		for id in family:
			for other in family:
				if id!=other and w.villagers[id].visible and w.villagers[other].visible and w.villagers[id].position.distance_to(w.villagers[other].position)<w.Bodies.RADIUS-0.01: overlap=true
	if overlap or not family.all(func(id):return w.villagers[id].data.room=="windmill"):
		failed=true
		push_error("FAIL: the Bell family leaves through one doorway and reaches the mill without overlap")
	else: print("PASS: the Bell family leaves through one doorway and reaches the mill without overlap")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
