extends SceneTree
const Game=preload("res://game.gd")
const Cave=preload("res://cave.gd")
const State=preload("res://state.gd")
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
	check(not world.garden_cells.keys().any(func(cell):return Rect2i(8,44,12,10).has_point(cell)),"the player farmhouse has no decorative garden")
	var gardens=world.garden_cells_by_home
	var garden_sets=[]
	var gardens_fit=true
	for id in gardens:
		var building=world.buildings.filter(func(value):return value.id==id)[0]
		var bounds=Rect2i(building.cell-Vector2i(2,2),building.tiles+Vector2i(4,5))
		if id=="veteran": bounds.size.x=12
		if gardens[id].size()<2 or not gardens[id].all(func(cell):return bounds.has_point(cell)): gardens_fit=false
		garden_sets.append(str(gardens[id]))
	var unique_gardens={}
	for pattern in garden_sets: unique_gardens[pattern]=true
	check(gardens_fit and garden_sets.size()>=6 and unique_gardens.size()==garden_sets.size(),"residential gardens each have varied placements inside their own yards")
	check(not world.yard_fences.keys().any(func(cell):return world.yard_fences[cell]=="iron" and Rect2i(53,58,9,10).has_point(cell)),"Finch's house has no perimeter fence")
	check(not game.Grid.farmable(Vector2i(23,54)) and not world.can_build_crucible(Vector2i(23,54)),"Moss's land rejects player construction")
	var request_types={}
	for request in game.state.requests.POOL: request_types[request[4]]=true
	check(request_types.size()==20,"the weekly request pool contains twenty distinct task types")
	var square_flowers=preload("res://neighbors.gd").FLOWERS
	check(square_flowers.all(func(cell):return not world.road_cells.has(cell) and not world.paved_cells.has(cell)),"town-square flowerbeds stay clear of the connected paved routes")
	check(preload("res://neighbors.gd").BENCHES.all(func(cell):
		var footprint=Rect2i(cell,Vector2i(2,1))
		return square_flowers.all(func(flower):return not footprint.has_point(flower)) and world.road_cells.keys().all(func(road):return not footprint.has_point(road)) and not footprint.intersects(Rect2i(world.BOARD_CELL,Vector2i(2,1)))
	),"town-square benches stay clear of flowerbeds, roads, and the bulletin board")
	var tree=world.trees[0]
	world.facing="up"
	game.state.player_position=game.Grid.center(tree.cell+Vector2i.DOWN)
	game.state.axe=1
	game.state.inventory_selection="axe"
	game.state.selected_slot=8
	check(world.find_nearest().get("type")=="tree","the action square selects a tree over nearby water actions")
	game.state.player_position=game.Grid.center(world.POND_CELL+Vector2i.LEFT)
	world.facing="right"
	game.state.inventory_selection=""
	check(world.find_nearest().get("id")=="drink_pond","empty-handed drinking is offered only on the pond action square")
	game.state.fishing_pole=1
	game.state.inventory_selection="fishing_pole"
	check(world.find_nearest().get("id")=="pond","an equipped fishing pole overrides the pond drinking prompt")
	var inventory_state=State.new()
	inventory_state.apples=1
	for index in range(8): inventory_state.inventory_order[index]="turnips" if index==0 else ""
	check(inventory_state.can_carry("apples"),"an existing apple stack fits even when the first inventory row is occupied")
	var repair_checkin=game.vale_checkin_choices()
	if not repair_checkin.is_empty(): repair_checkin[0][1].call()
	check(repair_checkin[0][0]=="What's the status on repairs?" and game.state.health==100 and game.state.energy==100 and game.state.mana==60,"Vale's repair check-in uses natural dialogue and does not heal the crew")
	check(game.vale_checkin_choices().is_empty(),"Vale's repair check-in reward is limited to once per day")
	game.state.abandoned_day["finch"]=game.state.day
	game.state.minute=800
	check(not world.stop_for("finch").sleeping,"an interrupted conversation does not lock Finch's house during daytime")
	var cave=Cave.new()
	cave.state=State.new()
	cave.state.cave_seed=91
	cave.generate()
	check(cave.chambers.all(func(room):return room.size.x>=2 and room.size.y>=2 and room.size.x<=6 and room.size.y<=6),"mine chambers stay between two and six tiles per side")
	check(cave.rat_cells.size()==4 and cave.rat_cells.all(func(cell):return cave.floor_cells.has(cell) and not cave.solid_cells.has(cell)),"cave rat spawn cells are reserved as open floor")
	check(cave.rocks.values().all(func(rock):return rock.cell!=cave.chambers.back().get_center()),"mine deposits leave stairways clear")
	var final_cave=Cave.new()
	final_cave.state=State.new()
	final_cave.state.cave_seed=92
	final_cave.level=2
	final_cave.generate()
	check(final_cave.floor_cells.has(final_cave.spider_cell) and not final_cave.solid_cells.has(final_cave.spider_cell) and final_cave.spider_cell!=final_cave.chambers.back().position+Vector2i.ONE,"the final-room spider spawns clear of rocks and the chrysalis")
	cave.free()
	final_cave.free()
	var state=State.new()
	state.weather_override="sunny"
	state.plots=[{"x":12,"y":53,"tilled":true,"planted":0.0,"watered":false,"crop":"turnips","growth":0.0,"water_day":0,"dry_days":0,"withered":false}]
	state.advance(1440)
	state.advance(1440)
	check(state.plots.is_empty() or (state.plots[0].planted<0 and state.plots[0].growth<0),"two dry midnights wither an unwatered crop")
	state.day=28
	state.minute=1439
	state.plots=[{"x":12,"y":53,"tilled":true,"planted":0.0,"watered":false,"crop":"turnips","growth":0.0,"water_day":28,"dry_days":0,"withered":false}]
	state.advance(2)
	check(state.plots.is_empty() or state.plots.all(func(plot):return plot.planted<0),"season changes clear crops that cannot grow across seasons")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
