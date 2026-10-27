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
	var world=game.outdoors
	var square=world.SQUARE
	check(square.get_area()>=54,"town square has about fifty percent more space")
	var board=world.sites.filter(func(site):return site.id=="bulletin_board")[0]
	check(board.cell.y<=square.position.y,"the notice board is on the north side of town square")
	check(world.TownPaths.TEMPLE_GATES.all(func(cell):return not world.blocked(game.Grid.center(cell)) and world.road_cells.has(cell)),"all temple gates connect to traversable roads")
	var outhouse=world.buildings.filter(func(building):return building.id=="priest_outhouse")[0]
	var home=world.buildings.filter(func(building):return building.id=="priest")[0]
	check(outhouse.cell.distance_to(home.cell)>6,"the outhouse stands away from the priest's home and main approach")
	game.state.minute=630
	game.state.day=7
	game.enter_building("temple")
	check(game.Art.catalog.has("temple_altar"),"the default pack supplies a dedicated temple altar")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
