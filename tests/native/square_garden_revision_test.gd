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
	var w=game.outdoors
	for seed_value in [1,123456,917]:
		game.state.world_seed=seed_value
		w.rebuild_visit(game.state)
		for home in w.garden_cells_by_home:
			var cells=w.garden_cells_by_home[home]
			var bounds=Rect2i(cells[0],Vector2i.ONE) if not cells.is_empty() else Rect2i()
			for cell in cells: bounds=bounds.merge(Rect2i(cell,Vector2i.ONE))
			check(cells.size()>=2 and cells.size()<=6 and bounds.get_area()==cells.size() and mini(bounds.size.x,bounds.size.y)<=2 and maxi(bounds.size.x,bounds.size.y)<=3,"one compact rectangular garden: %s seed %d" % [home,seed_value])
		check(w.yard_fences.keys().all(func(cell):return not w.SQUARE.has_point(cell)),"yard fencing stays outside the square")
		var bench_cells=w.Neighbors.BENCHES
		var mirrored=true
		for cell in bench_cells:
			mirrored=mirrored and bench_cells.has(Vector2i(w.SQUARE.position.x+w.SQUARE.end.x-cell.x-2,cell.y))
		check(mirrored,"benches form matching pairs on both sides of the square")
		check(w.solid_cells.get(w.SQUARE.position+Vector2i(3,4))=="fountain" and not w.blocked(w.Grid.center(w.SQUARE.position+Vector2i(3,3))),"the centered fountain leaves its upper artwork walkable")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
