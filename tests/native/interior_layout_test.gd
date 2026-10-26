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
	preload("fixture.gd").explore(game,true)
	check(game.camera.zoom.is_equal_approx(Vector2.ONE*1.9125),"zoom reduces the previous setting by another 15 percent")
	game.enter_building("store")
	game.leave_building()
	check(not game.world.blocked(game.state.player_position),"leaving the store never places the player inside the wagon")
	check(not game.world._route(game.world.Grid.world_to_cell(game.state.player_position),game.world.Grid.SPAWN_CELL).is_empty(),"store exit connects to the outdoor walking network")
	var shapes={}
	var room_shapes={}
	var compact=true
	var private_baths=true
	var routes_clear=true
	var exits_clear=true
	for b in game.outdoors.buildings:
		game.state.minute=780
		game.enter_building(b.id)
		var room=game.world
		var beds=room.furnishings.filter(func(item):return item.kind=="bed").size()
		var budget=210+maxi(0,beds-1)*32
		if b.id in ["reed_farm","mill_home"]: budget=274
		if b.id in ["smithy","bakery"]: budget=240
		if b.id=="tavern": budget=300
		if room.ROOM_CELLS.x*room.ROOM_CELLS.y>budget: compact=false
		var shape=JSON.stringify(room.layout)
		shapes[shape]=true
		var geometry=[]
		for area in room.layout.areas: geometry.append(area[1])
		room_shapes[str(geometry)]=true
		for cell in room.layout.work:
			if room.blocked(room.Grid.center(cell)) or room._route(room.layout.entry,cell).is_empty():
				routes_clear=false
				print("Unreachable work cell: ",b.id," ",cell)
		var bath_doors=0
		for door in room.layout.doors:
			if "bathroom" in [door[0],door[1]]:
				bath_doors+=1
				if "kitchen" in [door[0],door[1]]: private_baths=false
		if bath_doors!=(0 if b.id in ["mill_shed","priest","priest_outhouse"] else 1): private_baths=false
		for cell in room.floor_cells:
			if room.floor_cells[cell]=="bathroom": room.solid_cells[cell]="closed bathroom"
		for site in room.sites:
			if site.id=="exit" or room.floor_cells.get(site.cell)=="bathroom": continue
			if room._route(room.Grid.world_to_cell(room.entry_position()),site.cell).is_empty():
				routes_clear=false
				print("Unreachable interior site: ",b.id," ",site.id)
		game.leave_building()
		if game.world.blocked(game.state.player_position): exits_clear=false
	check(compact,"interiors use compact building-sized floor plans")
	check(shapes.size()==game.outdoors.buildings.size(),"every building has a distinct interior plan")
	check(room_shapes.size()==game.outdoors.buildings.size(),"each interior has its own room geometry, beyond furniture and names")
	check(private_baths,"each bathroom has one private doorway and no kitchen connection")
	check(routes_clear,"bedrooms kitchens and public spaces remain reachable with bathrooms closed")
	check(exits_clear,"every building returns the player to a clear outdoor tile")
	var named=false
	for person in game.outdoors.people:
		if person.id=="veteran": named=person.name=="Bram"
	check(named,"the veteran is named Bram")
	var garden_clear=true
	for y in range(game.outdoors.VETERAN_GARDEN.position.y,game.outdoors.VETERAN_GARDEN.end.y):
		for x in range(game.outdoors.VETERAN_GARDEN.position.x,game.outdoors.VETERAN_GARDEN.end.x):
			if not game.outdoors.reserved_cells.has(Vector2i(x,y)) or game.outdoors.blocked(game.outdoors.Grid.center(Vector2i(x,y))): garden_clear=false
	check(garden_clear,"Bram's planted garden reserves its tiles against trees and obstacles")
	var before=game.state.plots.duplicate(true)
	game.state.player_position=game.world.Grid.center(game.world.VETERAN_GARDEN.position)
	game.interact()
	check(before==game.state.plots,"Bram's garden is decorative and cannot be farmed")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
