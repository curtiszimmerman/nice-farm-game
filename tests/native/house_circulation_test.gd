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
	game.state.day=2
	for building in game.outdoors.buildings:
		game.state.minute=780
		game.enter_building(building.id)
		var room=game.world
		var sensible=true
		for item in room.furnishings:
			if item.kind=="kitchen" and room.floor_cells[item.bounds.position]!="kitchen" and building.id!="priest": sensible=false
		for door in room.layout.doors:
			var approaches={}
			for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
				var cell=door[2]+direction
				if not room.blocked(game.Grid.center(cell)): approaches[room.floor_cells.get(cell,"")]=true
			if not approaches.has(door[0]) or not approaches.has(door[1]):
				print("Blocked doorway: ",building.id," ",door)
				sensible=false
		check(sensible,"separate kitchen and clear doorway approaches in "+building.id)
		if building.id=="home":
			var straight=true
			for y in range(1,13):
				if room.floor_cells.get(Vector2i(7,y),"")!="hall": straight=false
			check(straight,"farmhouse hallway follows one straight axis from the entrance")
		game.leave_building()
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
