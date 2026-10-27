extends SceneTree
const Art=preload("res://art.gd")
const Game=preload("res://game.gd")
var failed=false
func check(value: bool,label: String) -> void:
	if value: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	Art.load_atlas()
	check(Art.pack_path=="res://art/option3/pack.json" and Art.tile_size==16,"new visits start with the rustic 16-pixel artwork")
	var error=Art.select_pack("res://art/option3/pack.json")
	check(error.is_empty(),"the complete rustic 16-pixel pack loads")
	if not error.is_empty(): quit(1); return
	check(Art.tile_size==16 and Art.region("tile_grass0").size==Vector2(16,16) and Art.sprite_size("tile_grass0")==Vector2(32,32),"rustic pixels scale to the existing grid")
	var original=Image.load_from_file("res://art/option2/sprites.png")
	var catalog=Art.read_json("res://art/option2/sprites.json")
	var new_silhouettes=0
	for id in ["tree_oak_3","actor_player_down0","furniture_sofa_3x1"]:
		var r=catalog[id].rect
		var reduced=original.get_region(Rect2i(r[0],r[1],r[2],r[3]))
		var native=Art.pixels.get_region(Rect2i(Art.region(id)))
		reduced.resize(native.get_width(),native.get_height(),Image.INTERPOLATE_NEAREST)
		var different=false
		for y in range(native.get_height()):
			for x in range(native.get_width()):
				if (native.get_pixel(x,y).a>0)!=(reduced.get_pixel(x,y).a>0): different=true
		if different: new_silhouettes+=1
	check(new_silhouettes==3,"trees crew and furniture have newly drawn silhouettes")
	var tools=[]
	for id in ["hoe","sickle","pickaxe"]: tools.append(Art.pixels.get_region(Rect2i(Art.region("item_"+id))).get_data())
	check(tools[0]!=tools[1] and tools[1]!=tools[2] and tools[0]!=tools[2],"rustic tool icons retain distinct silhouettes")
	var wet_visible=true
	for crop in ["sprout","turnip","bulb"]:
		var dry=Art.pixels.get_region(Rect2i(Art.region("crop_"+crop)))
		var wet=Art.pixels.get_region(Rect2i(Art.region("crop_"+crop+"_wet")))
		var difference=0.0
		for y in range(dry.get_height()):
			for x in range(dry.get_width()):
				difference+=dry.get_pixel(x,y).get_luminance()*dry.get_pixel(x,y).a-wet.get_pixel(x,y).get_luminance()*wet.get_pixel(x,y).a
		if difference<=0: wet_visible=false
	check(wet_visible,"rustic planted crops preserve visibly darker watered soil")
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	await process_frame
	preload("fixture.gd").explore(game,true)
	game.state.day=2
	var clear=true
	for building in game.outdoors.buildings:
		game.state.minute=780
		game.enter_building(building.id)
		if game.world.blocked(game.state.player_position): clear=false
		game.world.refresh()
		await process_frame
		game.leave_building()
	check(clear,"every authored interior renders the new pack and preserves its entry geometry")
	game.enter_building("cave")
	game.world.refresh()
	await process_frame
	check(not game.world.blocked(game.state.player_position),"the generated cave renders with the rustic pack")
	game.leave_building()
	game.enter_building("ship")
	var art=Art.new()
	check(art.has_method("interior_wall"),"ship bulkheads have a distinct material selector")
	if art.has_method("interior_wall"):
		check(art.call("interior_wall",game.world)=="metal_wall" and Art.catalog.has("tile_metal_wall"),"the damaged ship uses metal bulkheads instead of household wallpaper")
	game.change_art_pack("res://art/option3/pack.json")
	check("Rustic 16-pixel artwork" in game.ui.message.text,"artwork selection identifies the chosen pack by name")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
