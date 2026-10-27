extends SceneTree

const Grid = preload("res://grid.gd")
const Game = preload("res://game.gd")
var count = 0
var failed = false

func check(value: bool,description: String) -> void:
	if value:
		count+=1
		print("PASS: "+description)
	else:
		failed=true
		push_error("FAIL: "+description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	check(Grid.world_to_cell(Vector2(-0.1,-0.1))==Vector2i(-1,-1),"grid conversion floors negative coordinates")
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game)
	var world=game.world
	check(not world.blocked(Grid.center(Grid.SPAWN_CELL)),"the shared spawn tile is walkable")
	var aligned=true
	for p in world.people+world.sites:
		if Vector2(p.x,p.y)!=Grid.center(p.cell): aligned=false
	check(aligned,"NPCs and interaction anchors use tile centers")
	var footprints=true
	for b in world.buildings:
		var expected=Grid.rect(b.cell,b.tiles)
		if Rect2(b.x,b.y,b.w,b.h)!=expected: footprints=false
		for y in range(b.cell.y,b.cell.y+b.tiles.y):
			for x in range(b.cell.x,b.cell.x+b.tiles.x):
				if not world.blocked(Grid.center(Vector2i(x,y))): footprints=false
	check(footprints,"buildings render and collide using the same whole-tile footprints")
	var tree_cells={}
	var tree_alignment=true
	for tree in world.trees:
		var cell=Grid.world_to_cell(tree.pos)
		if tree.pos!=Grid.center(cell) or tree_cells.has(cell): tree_alignment=false
		if not world.blocked(tree.pos): tree_alignment=false
		tree_cells[cell]=true
	check(tree_alignment,"trees occupy unique grid cells with matching collision")
	var crops_aligned=true
	for i in range(20):
		var p=world.plot_position(i)
		if p!=Grid.center(world.FARM_CELL+Vector2i(i%5,int(i/5.0))): crops_aligned=false
		if world.blocked(p): crops_aligned=false
	check(crops_aligned,"all farm plots are walkable cells of the shared world grid")
	var roads_aligned=true
	for segment in world.road_segments:
		if segment[0]!=Grid.center(Grid.world_to_cell(segment[0])) or segment[1]!=Grid.center(Grid.world_to_cell(segment[1])): roads_aligned=false
		if segment[0].x!=segment[1].x and segment[0].y!=segment[1].y: roads_aligned=false
	check(roads_aligned,"roads connect tile centers along grid rows and columns")
	var valid_population=true
	for cell in tree_cells:
		if world.road_cells.has(cell) or world.water_cells.has(cell): valid_population=false
	check(valid_population,"population does not place trees on roads or water")
	check(world.blocked(Grid.center(world.fence_cells[0])),"fences occupy solid grid cells")
	check(not world.blocked(Grid.center(world.FARM_CELL+Vector2i(5,-2))),"farm gate leaves a walkable grid opening")
	check(world.in_water(Grid.center(world.POND_CELL)) and world.blocked(Grid.center(world.POND_CELL)),"pond water occupies solid terrain cells")
	var jetty_clear=true
	for x in range(world.JETTY_CELLS.position.x,world.JETTY_CELLS.end.x):
		if world.blocked(Grid.center(Vector2i(x,world.JETTY_CELLS.position.y))): jetty_clear=false
	check(jetty_clear,"the jetty reserves walkable cells over pond water")
	var edge_save=game.state.to_dict()
	var boundary=Grid.origin(Grid.SPAWN_CELL)+Vector2(0.1,16)
	edge_save.x=boundary.x
	edge_save.y=boundary.y
	var restored=game.state.get_script().new()
	check(not world.blocked(Vector2(edge_save.x,edge_save.y)) and restored.restore(edge_save),"a valid position near the new tile boundary survives saving and loading")
	game.state.player_position=world.plot_position(6)+Vector2(10,-8)
	world.facing="right"
	check(world.target_plot()==7,"smooth movement within a tile keeps targeting its adjacent cell")
	var start=Grid.center(Grid.SPAWN_CELL)
	game.state.player_position=start
	var event=InputEventKey.new()
	event.physical_keycode=KEY_D
	event.keycode=KEY_D
	event.pressed=true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	game._move(0.01)
	event=event.duplicate()
	event.pressed=false
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	check(game.state.player_position.x>start.x and game.state.player_position.x<start.x+Grid.TILE_SIZE,"walking remains smooth rather than jumping between tile centers")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	print("%d shared-grid checks passed" % count)
	quit(1 if failed else 0)
