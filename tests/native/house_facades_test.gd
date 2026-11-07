extends SceneTree
const Game=preload("res://game.gd")
const World=preload("res://world.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")

# The pixels of a window tile that differ from the plain wall around it, in the building's drawn coordinates.
func window_pixels(Art,wall: String,column: int,row: int) -> Dictionary:
	var window=Art.region("tile_%s_window" % wall)
	var plain=Art.region("tile_%s_wall" % wall)
	var scale=32.0/window.size.x
	var cells={}
	for y in range(int(window.size.y)):
		for x in range(int(window.size.x)):
			if Art.pixels.get_pixel(int(window.position.x)+x,int(window.position.y)+y)!=Art.pixels.get_pixel(int(plain.position.x)+x,int(plain.position.y)+y):
				cells[Vector2i(column*32+int(x*scale),row*32+int(y*scale))]=true
	return cells

func lantern_overlaps(Art,lantern: Dictionary,window: Dictionary) -> bool:
	var region=Art.region(lantern.sprite)
	var rect: Rect2=lantern.rect
	for y in range(int(rect.size.y)):
		for x in range(int(rect.size.x)):
			var source=region.position+Vector2(x,y)*region.size/rect.size
			if Art.pixels.get_pixel(int(source.x),int(source.y)).a<0.5: continue
			var at=Vector2i(int(rect.position.x)+x,int(rect.position.y)+y)
			# Window pixels are recorded on the 2x2 grid the 16-pixel art is drawn at.
			if window.has(Vector2i(at.x-posmod(at.x,2),at.y-posmod(at.y,2))): return true
	return false

func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	var Art=game.Art
	var clear=true
	for b in game.outdoors.buildings:
		var facade=Art.facade(b)
		if facade.is_empty(): continue
		var window={}
		for column in facade.windows: window.merge(window_pixels(Art,facade.wall,column,-2))
		for lantern in facade.lanterns:
			if lantern_overlaps(Art,lantern,window):
				clear=false
				print("Lantern over a window on ",b.id," at ",lantern.rect)
	check(clear,"no lantern covers a window on any building")
	var homes=["tavi","assistant","finch","radio","mayor","mill_home"]
	var looks={}
	for id in homes:
		var facade=Art.facade(game.outdoors.buildings.filter(func(b):return b.id==id)[0])
		looks["%s/%s/%s" % [facade.wall,facade.lantern,facade.roof]]=id
	check(looks.size()==homes.size(),"Tavi's, Neral's, Finch's, the radio club's, the mayor's and the Bells' homes each look different (%s)" % str(looks.keys()))
	var walls={}
	for id in homes: walls[Art.facade(game.outdoors.buildings.filter(func(b):return b.id==id)[0]).wall]=true
	check(walls.size()==homes.size() and not walls.has("plaster"),"each of those homes has its own wall instead of the shared plaster (%s)" % str(walls.keys()))
	# The windmill is a tower mill drawn as one picture, and its sails turn on the cap.
	var mill=game.outdoors.buildings.filter(func(b):return b.id=="windmill")[0]
	check(Art.catalog.has("building_windmill") and Art.facade(mill).is_empty(),"the windmill is drawn as a tower mill, without house windows or lanterns")
	var sails=game.outdoors.moving_layer.get_children().filter(func(n):return n is World.Prop and n.kind=="mill_sails")[0]
	var picture=Art.region("building_windmill")
	var height=Art.building_height(mill)
	var top_left=Vector2(mill.x,mill.y+mill.h-height)
	var hub=(sails.position-top_left)*picture.size/Vector2(mill.w,height)
	var cap=Art.pixels.get_pixel(int(picture.position.x+hub.x),int(picture.position.y+hub.y))
	check(cap.a>0.5 and cap.r<0.5,"the sails' hub sits on the mill's dark cap (%s)" % hub)
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
