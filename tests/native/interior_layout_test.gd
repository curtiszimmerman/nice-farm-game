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
	check(game.camera.zoom.is_equal_approx(Vector2.ONE*1.9125),"zoom reduces the previous setting by another 15 percent")
	game.enter_building("store")
	game.leave_building()
	check(not game.world.blocked(game.state.player_position),"leaving the store never places the player inside the wagon")
	check(not game.world._route(game.world.Grid.world_to_cell(game.state.player_position),game.world.Grid.SPAWN_CELL).is_empty(),"store exit connects to the outdoor walking network")
	var shapes={}
	var compact=true
	var private_baths=true
	var routes_clear=true
	var exits_clear=true
	for b in game.outdoors.buildings:
		game.enter_building(b.id)
		var room=game.world
		if room.ROOM_CELLS.x*room.ROOM_CELLS.y>210: compact=false
		var shape=JSON.stringify(room.layout)
		shapes[shape]=true
		var bath_doors=0
		for door in room.layout.doors:
			if "bathroom" in [door[0],door[1]]:
				bath_doors+=1
				if "kitchen" in [door[0],door[1]]: private_baths=false
		if bath_doors!=1: private_baths=false
		for cell in room.floor_cells:
			if room.floor_cells[cell]=="bathroom": room.solid_cells[cell]="closed bathroom"
		for site in room.sites:
			if site.id=="exit": continue
			if room._route(room.Grid.world_to_cell(room.entry_position()),site.cell).is_empty(): routes_clear=false
		game.leave_building()
		if game.world.blocked(game.state.player_position): exits_clear=false
	check(compact,"interiors use compact building-sized floor plans")
	check(shapes.size()==game.outdoors.buildings.size(),"every building has a distinct interior plan")
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
