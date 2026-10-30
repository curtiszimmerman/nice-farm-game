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
	check(["farmer_mother","farmer_father","farmer_son","smith","miller","miller_wife","miller_daughter","barkeep","baker"].all(func(id): return w.villagers.has(id)),"two families and three tradespeople join the town")
	check(["reed_farm","windmill","mill_home","smithy","tavern","bakery"].all(func(id): return w.buildings.any(func(b):return b.id==id)),"east farm windmill family home smithy tavern and bakery have world footprints")
	var routes=true
	for b in w.buildings:
		var door=b.cell+Vector2i(b.tiles.x/2,b.tiles.y)
		if w._route(w.Grid.SPAWN_CELL,door).is_empty():
			print("Unreachable door ",b.id," at ",door," terrain ",w.solid_cells.get(door))
			if b.id in ["veteran","woodcutter"]:
				for cell in [Vector2i(23,67),Vector2i(23,78),Vector2i(29,78),Vector2i(29,79),Vector2i(29,80),Vector2i(29,81),Vector2i(29,82),Vector2i(42,82),Vector2i(42,81),Vector2i(42,80)]: print("Route cell ",cell," blocked=",w.blocked(w.Grid.center(cell))," solid=",w.solid_cells.get(cell,"")," gate=",w.yard_gates.has(cell))
			routes=false
	check(routes,"every new building entrance connects to the town")
	check(not w.blocked(w.Grid.center(w.SQUARE.position+Vector2i(3,3))) and w.blocked(w.Grid.center(w.SQUARE.position+Vector2i(3,4))),"the fountain's upper artwork permits walking behind its base")
	check(w.sites.filter(func(s):return s.id.begins_with("bench")).size()>=2,"town square has usable benches")
	if w.villagers.has("miller_daughter"):
		game.state.minute=900
		w.update_villagers(0,true)
		check(w.villagers.miller_daughter.data.room=="radio","Nessa spends afternoons at the radio club")
	var signatures={}
	var interiors_clear=true
	for id in ["reed_farm","windmill","mill_home","smithy","tavern","bakery"]:
		if not w.buildings.any(func(b):return b.id==id): continue
		game.enter_building(id)
		signatures[hash(game.world.layout)]=true
		for site in game.world.sites:
			if site.id!="exit" and game.world._route(game.world.Grid.world_to_cell(game.world.entry_position()),site.cell).is_empty():
				print("Blocked ",id," / ",site.id)
				interiors_clear=false
		game.leave_building()
	check(signatures.size()==6 and interiors_clear,"new buildings have six distinct interiors with reachable interactions")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
