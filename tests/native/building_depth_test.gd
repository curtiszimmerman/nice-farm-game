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
	# The tavern touches the mayor's house on its left, so the captain goes around its right side instead.
	for pair in [["hall","left"],["tavern","right"],["smithy","left"]]:
		var id=pair[0]
		var b=world.buildings.filter(func(item):return item.id==id)[0]
		var prop=world.scenery_layer.get_children().filter(func(n):return n is World.Prop and n.kind=="building" and n.data.id==id)[0]
		var front=b.cell.y+b.tiles.y
		var door=b.cell+Vector2i(int(b.tiles.x/2),b.tiles.y)
		game.state.player_position=Grid.center(door)
		var edge=b.cell.x if pair[1]=="left" else b.cell.x+b.tiles.x-1
		var outward=-1 if pair[1]=="left" else 1
		var side=Vector2i(edge+outward,front)
		var behind=Vector2i(edge,front-3)
		# The flowerbeds beside the door fill the front row, so the captain steps out one row before going around.
		var walked=walk(game,door+Vector2i.DOWN) and walk(game,side+Vector2i.DOWN) and walk(game,side+Vector2i(0,-3)) and walk(game,behind)
		check(walked,"the captain walks from %s's door around the side and behind it" % id)
		check(world.prop_hides_player(prop),"%s fades while the captain stands behind it" % id)
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
