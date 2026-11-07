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
	var w=game.outdoors
	check(w.SQUARE==Rect2i(58,43,10,9),"square expands one tile outward on all four sides")
	var direct=true
	for x in range(18,64):
		var cell=Vector2i(x,52)
		if w.blocked(w.Grid.center(cell)) or not w.road_cells.has(cell): direct=false
	check(direct,"farmhouse road runs directly to the square without a temple detour")
	var single_road=true
	for x in [40,45]:
		var crossings=[]
		for y in range(44,54):
			if w.road_cells.has(Vector2i(x,y)): crossings.append(y)
		if crossings!=[52]: single_road=false
	check(single_road,"the farm-town approach has one road across each western boundary")
	var temple=w.buildings.filter(func(b):return b.id=="temple")[0]
	check(temple.cell.y==56,"temple moves four tiles south")
	for seed_value in range(1,9):
		for level in range(3):
			var cave=game.Cave.new()
			cave.state=game.State.new()
			cave.state.cave_seed=seed_value
			cave.state.cave_level=level
			cave.outdoors=w
			cave.building={"id":"cave"}
			game.add_child(cave)
			var rocks=cave.rocks.values().map(func(r):return r.cell)
			check(rocks.size()<cave.floor_cells.size()*0.12 and rocks.all(func(cell):return cell.distance_to(cave.layout.entry)>3 and cell.distance_to(cave.layout.exit)>3 and cell.distance_to(cave.chambers.back().get_center())>3),"sparse rocks leave generous entrance and stair landings: %d/%d"%[seed_value,level])
			check(cave.floor_connected_without(rocks),"every cave floor remains reachable: %d/%d"%[seed_value,level])
			cave.queue_free()
		await process_frame
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
