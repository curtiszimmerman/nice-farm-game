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
	game.state.world_seed=123456
	game.outdoors.rebuild_visit(game.state)
	game.state.met_mayor=true
	var world=game.outdoors
	for index in range(world.people.size()):
		var id=world.people[index].id
		if id in ["vale","smith","baker","barkeep","keeper"]: continue
		game.state.day=posmod(index+1,7)+1
		game.state.minute=900
		var stop=world.stop_for(id)
		check(stop.room=="" and not stop.sleeping,"weekly afternoon garden tending: "+id)
		check(world.reserved_cells.has(stop.cell),"random scenery leaves room at the scheduled garden spot: "+id)
		check(not world.blocked(game.Grid.center(stop.cell)) and not world._route(game.Grid.SPAWN_CELL,stop.cell).is_empty(),"the garden work spot is reachable: "+id)
		var home=world.Schedule.home_stop(id).room
		var house=world.buildings.filter(func(b):return b.id==home)[0]
		check(stop.cell.distance_to(house.cell)<12,"garden tending remains near the resident's own home: "+id)
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
