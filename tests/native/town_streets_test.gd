extends SceneTree
const Game=preload("res://game.gd")
const Grid=preload("res://grid.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")

const STEPS=[Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]
const PAVED_DOORS=["hall","radio","mayor","tavern","store","smithy","finch","bakery","widow","herbalist"]
const DIRT_DOORS=["tavi","assistant","windmill","mill_home","mill_shed","reed_farm","iona","observatory","moss"]

# Every cell of streets, roads and paths that can be reached on foot from the square.
func network_from_square(world: Node2D) -> Dictionary:
	var start=Vector2i(62,52)
	var seen={start:true}
	var frontier=[start]
	while not frontier.is_empty():
		var cell: Vector2i=frontier.pop_back()
		for step in STEPS:
			var next=cell+step
			if seen.has(next) or not world.path_cells.has(next) or world.blocked(Grid.center(next)): continue
			seen[next]=true
			frontier.append(next)
	return seen

func approach(world: Node2D,id: String) -> Vector2i:
	var b=world.buildings.filter(func(item):return item.id==id)[0]
	var door=b.cell+Vector2i(int(b.tiles.x/2),b.tiles.y)
	return door if world.path_cells.has(door) else door+Vector2i.DOWN

# Walks the open cells reachable from a starting cell without passing through any gate.
func enclosed(world: Node2D,start: Vector2i,limit: int) -> Dictionary:
	var seen={start:true}
	var frontier=[start]
	while not frontier.is_empty() and seen.size()<limit:
		var cell: Vector2i=frontier.pop_back()
		for step in STEPS:
			var next=cell+step
			if seen.has(next) or world.blocked(Grid.center(next)) or world.yard_gates.has(next): continue
			seen[next]=true
			frontier.append(next)
	return seen

func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	var world=game.outdoors
	var network=network_from_square(world)
	for id in PAVED_DOORS+DIRT_DOORS+["mining_shack","temple","priest"]:
		check(network.has(approach(world,id)),"%s's door is reached by a street, road or path from the square" % id)
	check(PAVED_DOORS.all(func(id):return world.paved_cells.has(approach(world,id))),"doors in town open onto paved streets")
	check(DIRT_DOORS.all(func(id):var cell=approach(world,id); return world.road_cells.has(cell) and not world.paved_cells.has(cell) and not world.trail_cells.has(cell)),"homes and workplaces outside the centre open onto packed-dirt roads")
	var cave=world.Grid.world_to_cell(world.site_position("ore"))
	check(network.has(cave) and world.trail_cells.has(cave),"a faint path leads to the copper cave entrance")
	check(world.trail_cells.has(approach(world,"mining_shack")),"a faint path leads to the old mining shack")
	var neral=approach(world,"assistant")
	check(world.trail_cells.has(Vector2i(neral.x+2,neral.y+2)) or world.trail_cells.has(Vector2i(neral.x+2,neral.y+1)),"the faint path to the cave leaves the road beside Neral's house")
	var hidden=[]
	for b in world.buildings:
		for y in range(b.cell.y,b.cell.y+b.tiles.y):
			for x in range(b.cell.x,b.cell.x+b.tiles.x):
				if world.path_cells.has(Vector2i(x,y)): hidden.append(Vector2i(x,y))
	check(hidden.is_empty(),"no street, road or path runs underneath or behind a building")
	if not hidden.is_empty(): print("Routes under buildings: ",hidden.slice(0,8))
	# Back yards face the street around the square only across a fence.
	for pair in [["finch",Rect2i(55,54,6,1)],["bakery",Rect2i(66,54,6,1)]]:
		var open_to_square=false
		for x in range(pair[1].position.x,pair[1].end.x):
			if world.yard_fences.get(Vector2i(x,pair[1].position.y-1),"")=="": open_to_square=true
		check(not open_to_square,"a fence separates %s's back yard from the square" % pair[0])
	var smithy_fenced=true
	for y in range(46,51):
		if world.yard_fences.get(Vector2i(69,y),"")=="": smithy_fenced=false
	check(smithy_fenced,"a fence separates the smithy's side from the square")
	var widow_yard=enclosed(world,Vector2i(50,49),200)
	check(widow_yard.keys().all(func(cell):return Rect2i(48,48,8,3).has_point(cell)),"Widow Marsh's yard is fenced on every side")
	check(world.yard_gates.has(approach(world,"widow")+Vector2i.UP),"Widow Marsh's front gate opens at her door")
	check(widow_yard.has(Vector2i(48,48)) and widow_yard.has(Vector2i(50,50)),"Widow Marsh keeps a sliver behind her house and a strip of garden to the west")
	var clear_yards=true
	for world_seed in [1,6,9,15,16,18,21,23]:
		game.state.world_seed=world_seed
		world.rebuild_visit(game.state)
		var yard=enclosed(world,Vector2i(50,49),200)
		if not yard.has(Vector2i(48,48)) or not yard.has(Vector2i(50,50)):
			clear_yards=false
			print("Blocked widow yard in seed ",world_seed)
		await process_frame
	check(clear_yards,"random vegetation never blocks Widow Marsh's small backyard across eight regression layouts")
	# The temple complex has one forecourt for the temple and the priest's house, entered from South Street.
	var gates=world.TownPaths.TEMPLE_GATES
	check(gates.size()==3 and not gates.any(func(cell):return cell.y==54),"the temple keeps its east, west and south gates and loses the north gate")
	var forecourt=true
	for x in range(42,54):
		if not world.blocked(Grid.center(Vector2i(x,62))) and not world.paved_cells.has(Vector2i(x,62)): forecourt=false
	check(forecourt,"one paved forecourt runs in front of the priest's house and the temple")
	var hive_clear=true
	for hive in world.Neighbors.HIVES:
		for dy in range(-1,2):
			for dx in range(-1,2):
				if world.path_cells.has(hive+Vector2i(dx,dy)): hive_clear=false
	check(hive_clear,"the beehives stand away from every walkway")
	var beds=world.Neighbors.TEMPLE_GARDEN
	check(beds.all(func(cell):return cell.y>62),"the temple garden lies south of the forecourt")
	check(world.Neighbors.HIVES.all(func(hive):return beds.any(func(bed):return hive.distance_to(bed)<=2.0)),"the hives stand beside the garden beds")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
