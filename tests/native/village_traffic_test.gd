extends SceneTree
const Game=preload("res://game.gd")
const Bodies=preload("res://npc_bodies.gd")
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
	# A home's front yard is how its family gets to the gate, so gardens and the gardener stay out of it.
	var front_clear=true
	var gardener_visible=true
	for world_seed in range(1,13):
		game.state.world_seed=world_seed
		world.rebuild_visit(game.state)
		for home in world.garden_cells_by_home:
			var b=world.buildings.filter(func(item):return item.id==home)[0]
			var door_row=b.cell.y+b.tiles.y
			for cell in world.garden_cells_by_home[home]:
				if cell.y>=door_row and cell.x>=b.cell.x-1 and cell.x<=b.cell.x+b.tiles.x:
					front_clear=false
					print("Seed ",world_seed,": ",home,"'s garden at ",cell," sits in front of the house")
			var work=world.garden_work.get(home,Vector2i(-99,-99))
			if world.buildings.any(func(other):return Rect2i(other.cell,other.tiles).has_point(work)):
				gardener_visible=false
				print("Seed ",world_seed,": ",home,"'s gardener stands behind a wall at ",work)
	check(front_clear,"home gardens are planted beside or behind the house, never in the front yard")
	check(gardener_visible,"nobody tends a garden from behind a building's walls")
	# Two villagers meeting head-on in the one-cell lane between the square and the smith's fence must get past each other.
	for id in world.villagers:
		if id not in ["smith","farmer_father"]: world.villagers[id].visible=false
	game.state.player_position=world.Grid.center(Vector2i(20,52))
	var smith=world.villagers.smith
	var farmer=world.villagers.farmer_father
	smith.visible=true
	farmer.visible=true
	smith.position=world.Grid.center(Vector2i(68,46))
	farmer.position=world.Grid.center(Vector2i(68,50))
	world.routes.clear()
	var arrived={}
	for tick in range(1200):
		world.elapsed+=0.1
		if Bodies.walk_to(world,"smith",Vector2i(68,52),0.1,56.0): arrived.smith=true
		if Bodies.walk_to(world,"farmer_father",Vector2i(68,44),0.1,56.0): arrived.farmer_father=true
		if arrived.size()==2: break
	check(arrived.size()==2,"villagers meeting head-on in a one-cell lane find a way past each other (arrived: %s)" % str(arrived.keys()))
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
