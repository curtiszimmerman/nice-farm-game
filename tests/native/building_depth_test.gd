extends SceneTree
const Game=preload("res://game.gd")
const World=preload("res://world.gd")
const Grid=preload("res://grid.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")

# Walks the captain from the door in straight steps, the way a player holding a direction would.
func walk(game: Node2D,cell: Vector2i) -> bool:
	var goal=Grid.center(cell)
	while game.state.player_position.distance_to(goal)>0.5:
		if not game.try_player_step((goal-game.state.player_position).limit_length(2.0)): return false
	return true

func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	var world=game.outdoors
	for b in world.buildings:
		var base=b.cell.y+b.tiles.y-2
		var solid=true
		var open=true
		for y in range(b.cell.y,b.cell.y+b.tiles.y):
			for x in range(b.cell.x,b.cell.x+b.tiles.x):
				var cell=Vector2i(x,y)
				if y>=base: solid=solid and world.solid_cells.get(cell,"")=="building"
				else: open=open and world.solid_cells.get(cell,"")!="building" and world.reserved_cells.has(cell)
		check(solid,"%s blocks the bottom two rows of its footprint" % b.id)
		check(open,"%s leaves the rows above its base walkable and free of scenery" % b.id)
	# Fences and neighbours close off some sides, so the captain takes the shortest walk to the open one.
	# The tavern touches the mayor's house, and the smith's fence faces the square.
	for pair in [["hall","left"],["tavern","right"],["smithy","right"],["finch","left"],["tavi","left"]]:
		var id=pair[0]
		var b=world.buildings.filter(func(item):return item.id==id)[0]
		var prop=world.scenery_layer.get_children().filter(func(n):return n is World.Prop and n.kind=="building" and n.data.id==id)[0]
		var door=b.cell+Vector2i(int(b.tiles.x/2),b.tiles.y)
		game.state.player_position=Grid.center(door)
		var edge=b.cell.x if pair[1]=="left" else b.cell.x+b.tiles.x-1
		var behind=Vector2i(edge,b.cell.y+b.tiles.y-3)
		var route=world._route(door,behind)
		var walked=not route.is_empty()
		for point in route:
			if walked: walked=walk(game,Grid.world_to_cell(point))
		check(walked,"the captain walks from %s's door around the side and behind it" % id)
		check(world.prop_hides_player(prop),"%s fades while the captain stands behind it" % id)
	# The bakery's back wall is two rows from the square, so walking the square must not fade it.
	var bakery=world.scenery_layer.get_children().filter(func(n):return n is World.Prop and n.kind=="building" and n.data.id=="bakery")[0]
	game.state.player_position=Grid.center(Vector2i(67,51))
	check(not world.prop_hides_player(bakery),"walking along the south edge of the square leaves the bakery solid")
	game.state.player_position=Grid.center(Vector2i(68,54))
	check(world.prop_hides_player(bakery),"standing in the bakery's back yard fades it")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
