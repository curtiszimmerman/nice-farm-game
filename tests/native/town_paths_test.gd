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
	check(w.get("paved_cells")!=null,"town streets distinguish paving from rural dirt paths")
	if w.get("paved_cells")!=null:
		var clear=true
		for cell in w.road_cells:
			if w.solid_cells.has(cell): clear=false; print("Road intersects solid: ",cell," ",w.solid_cells[cell])
		check(clear,"roads do not run under flowerboxes fences or buildings")
		var connected=true
		for b in w.buildings:
			if b.id in ["keeper","veteran","woodcutter"]: continue
			var cell=b.cell+Vector2i(b.tiles.x/2,b.tiles.y)
			if not w.road_cells.has(cell) or not w.paved_cells.has(cell):
				print("Missing approach: ",b.id," / ",cell," blocked=",w.solid_cells.get(cell,"")," reserved=",w.reserved_cells.has(cell)," garden=",w.garden_cells.has(cell)," fence=",w.yard_fences.has(cell))
				connected=false
		check(connected,"all front-door approaches join the connected road network and are paved")
		check(w.get("yard_fences")!=null and w.yard_fences.size()>80,"town homes have actual fenced yards")
		var segments={}
		var unique=true
		for segment in w.road_segments:
			var a=w.Grid.world_to_cell(segment[0])
			var b=w.Grid.world_to_cell(segment[1])
			if a.x>b.x or (a.x==b.x and a.y>b.y):
				var swap=a
				a=b
				b=swap
			var key="%d,%d:%d,%d"%[a.x,a.y,b.x,b.y]
			if segments.has(key): unique=false
			segments[key]=true
		check(unique,"authored road connections contain no duplicate segments")
	var cart=w.CART_CELLS
	var around=true
	for bounds in [Rect2i(cart.position-Vector2i.ONE,cart.size+Vector2i(2,2))]:
		for y in range(bounds.position.y,bounds.end.y):
			for x in range(bounds.position.x,bounds.end.x):
				if not cart.has_point(Vector2i(x,y)) and w.blocked(w.Grid.center(Vector2i(x,y))): around=false
	check(around,"the relocated shopping wagon has a full tile of clearance on every side")
	game.state.minute=600
	game.state.met_mayor=true
	w.update_villagers(0,true)
	check(w.villagers.tavi.data.get("room")=="store","Tavi spends the working day inside his grocery store")
	check(w.villagers.mayor.position==w.site_position("door_hall"),"indoor work schedules enter through the building's actual front door")
	check(w.sites.any(func(site):return site.id=="bulletin_board"),"the square has an interactable local bulletin board")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
