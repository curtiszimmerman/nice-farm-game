extends SceneTree
# Dumps the outdoor world's layout as JSON for scripts/town_map.py to draw. Run that script rather
# than this one; it passes the output path after "--".

func _initialize() -> void: call_deferred("run")

func cells(dictionary: Dictionary) -> Array:
	return dictionary.keys().map(func(cell):return [cell.x,cell.y])

func run() -> void:
	var output=OS.get_cmdline_user_args()[0]
	var game=preload("res://game.gd").new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("res://../../tests/native/fixture.gd").explore(game)
	var w=game.outdoors
	var solid={}
	for cell in w.solid_cells: solid["%d,%d" % [cell.x,cell.y]]=String(w.solid_cells[cell])
	var buildings=w.buildings.map(func(b):return {"id":b.id,"kind":b.kind,"cell":[b.cell.x,b.cell.y],"tiles":[b.tiles.x,b.tiles.y],"resident":b.get("resident","")})
	var sites=w.sites.filter(func(site):return site.has("cell")).map(func(site):return {"id":site.id,"cell":[site.cell.x,site.cell.y]})
	var data={
		"size":[w.Grid.MAP_SIZE.x,w.Grid.MAP_SIZE.y],
		"origin":[w.Grid.WORLD_CELLS.position.x,w.Grid.WORLD_CELLS.position.y],
		"square":[w.SQUARE.position.x,w.SQUARE.position.y,w.SQUARE.size.x,w.SQUARE.size.y],
		"buildings":buildings,"solid":solid,"sites":sites,
		"paved":cells(w.paved_cells),"roads":cells(w.road_cells),"paths":cells(w.path_cells),"trails":cells(w.trail_cells),
		"fences":cells(w.yard_fences),"gates":cells(w.yard_gates),"gardens":cells(w.garden_cells),"farm":cells(w.farm_cells),
		"trees":w.trees.map(func(t):return [t.cell.x,t.cell.y]),
	}
	var file=FileAccess.open(output,FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	print("Dumped town layout to ",output)
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit()
