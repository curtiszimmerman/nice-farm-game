extends SceneTree

const Game=preload("res://game.gd")
var failed=false
func check(value: bool,label: String) -> void:
	if value: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	var w=game.world
	var tower={}
	for b in w.buildings:
		if b.kind=="tower": tower=b
	check(tower.cell.x<45 and tower.cell.y<12,"wizard tower stands north of the town square")
	var homes=true
	for id in ["moss","tavi","iona","finch","mayor"]:
		var assigned=[]
		for b in w.buildings:
			if b.get("resident","")==id: assigned.append(b)
		if assigned.size()!=1: homes=false; continue
		var home=assigned[0]
		var door=home.cell+Vector2i(home.tiles.x/2,home.tiles.y)
		for stop in w.Schedule.ROUTINES[id]:
			if stop[3] and Vector2i(stop[1],stop[2])!=door: homes=false
	check(homes,"each town resident sleeps at the door of their own assigned home")
	check(w.mountain_cells.size()>15,"tower sits among solid mountain and cliff terrain")
	var clear=true
	for cell in w.mountain_cells:
		if not w.blocked(w.Grid.center(cell)): clear=false
	check(clear,"mountain artwork occupies matching collision tiles")
	check(not w._route(w.Grid.SPAWN_CELL,tower.cell+Vector2i(1,6)).is_empty(),"the northern tower has a reachable entrance")
	var image=w.terrain.get_image()
	var mineral=image.get_pixelv(Vector2i(w.Grid.center(Vector2i(49,30))))
	var grass=image.get_pixelv(Vector2i(w.Grid.center(Vector2i(31,28))))
	check(mineral.g-mineral.r<grass.g-grass.r,"mine ground transitions from meadow green to mineral soil")
	check(w.blocked(w.Grid.center(Vector2i(50,26))),"the copper hillside connects to the coastal ridge")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
