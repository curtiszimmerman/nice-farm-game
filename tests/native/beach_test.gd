extends SceneTree
const Game=preload("res://game.gd")
const Coast=preload("res://coast.gd")
const Grid=preload("res://grid.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")

func grassy(color: Color) -> bool:
	return color.g>color.r+0.04 and color.g>color.b+0.04

func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	var world=game.outdoors
	var seed_value=game.state.world_seed
	for season_day in [1,85]:
		game.state.day=season_day
		world.rebuild_visit(game.state)
		var image: Image=Coast.build_connected_image(world)
		var seams=[]
		var bare=[]
		for row in range(Coast.JETTY.end.y,Grid.MAP_SIZE.y-1):
			var shore=Coast.shoreline(row,seed_value)
			# The last column of sea and the first column of sand meet here.
			for dx in [-2,-1,0,1]:
				var pixel=Vector2i((shore-Coast.MIN_X)*32+dx,row*32+16)
				if grassy(image.get_pixelv(pixel)): seams.append(Vector2i(shore,row))
			var middle=image.get_pixelv(Vector2i((shore+1-Coast.MIN_X)*32+16,row*32+16))
			if grassy(middle): bare.append(row)
		check(seams.is_empty(),"no grass shows between the sea and the beach in %s (%s)" % [game.state.season_name(),str(seams.slice(0,4))])
		check(bare.is_empty(),"the beach is sand all the way along in %s" % game.state.season_name())
	var seen={}
	for step in range(200): seen[Coast.wash_frame(60,step*0.05)]=true
	check(seen.size()==Coast.WASH_FRAMES,"surf at the waterline plays through all %d frames" % Coast.WASH_FRAMES)
	var staggered=false
	for step in range(200):
		if Coast.wash_frame(60,step*0.05)!=Coast.wash_frame(70,step*0.05): staggered=true
	check(staggered,"each wave sweeps along the beach instead of breaking on every row at once")
	check(range(Coast.WASH_FRAMES).all(func(frame):return game.Art.catalog.has("shore_wash_%d" % frame)),"the art pack has every surf frame")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
