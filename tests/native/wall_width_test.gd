extends SceneTree
const Game=preload("res://game.gd")
var failed=false
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	for building in game.outdoors.buildings:
		game.state.minute=780
		game.enter_building(building.id)
		var room=game.world
		var thin=true
		for cell in room.floor_cells:
			if room.floor_cells[cell] in ["doorway","entry"]: continue
			for direction in [Vector2i.RIGHT,Vector2i.DOWN]:
				if room.floor_cells.get(cell+direction*3,"") in ["doorway","entry"]: continue
				if room.floor_cells.has(cell+direction*3) and not room.floor_cells.has(cell+direction) and not room.floor_cells.has(cell+direction*2):
					thin=false
					print("Double partition: ",building.id," ",cell," ",direction)
		if thin: print("PASS: single-cell partitions in "+building.id)
		else: failed=true; push_error("FAIL: double-width partition in "+building.id)
		game.leave_building()
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
