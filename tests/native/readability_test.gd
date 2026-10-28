extends SceneTree

const Game = preload("res://game.gd")
const World = preload("res://world.gd")
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
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game)
	preload("fixture.gd").tools(game.state)
	var world=game.world
	game.state.player_position=world.plot_position(6)
	for pair in [["up",1],["down",11],["left",5],["right",7]]:
		world.facing=pair[0]
		check(world.find_nearest().get("index",-1)==pair[1],"farming targets the adjacent %s square" % pair[0])
	game.state.player_position=world.plot_position(0)
	world.facing="up"
	check(world.find_nearest().get("type")!="plot","facing out of the garden never falls back to the occupied square")
	game.state.player_position=world.plot_position(6)
	world.facing="right"
	for slot in [0,3,1]:
		game.select_quick_slot(slot)
		preload("fixture.gd").activate(game)
	game.select_quick_slot(5)
	game.state.day=2
	game.cast_growth()
	game.select_quick_slot(2)
	preload("fixture.gd").activate(game)
	check(game.state.harvested==1 and game.state.plots[6].tilled==false and game.state.plots[7].tilled,"tending and casting affect the highlighted forward square")
	game.state.minute=720.0
	world.refresh()
	check(world.night_tint.color.is_equal_approx(Color.WHITE),"daylight preserves the original world colors")
	game.state.minute=0.0
	world.refresh()
	var grass=Color("748c53")*world.night_tint.color
	check(grass.b>grass.g and grass.g>grass.r,"midnight turns the green meadow visibly blue")
	check(game.ui.purse.modulate==Color.WHITE,"world night tint leaves interface colors unchanged")
	var tree=null
	var house=null
	for child in world.scenery_layer.get_children():
		if child is World.Prop:
			if child.kind=="tree" and tree==null: tree=child
			if child.kind=="building" and house==null: house=child
	game.state.player_position=tree.position-Vector2(0,45)
	for i in range(10): world.refresh()
	check(tree.modulate.a<0.4,"a tree fades when its canopy hides the avatar")
	game.state.player_position=tree.position+Vector2(0,30)
	for i in range(10): world.refresh()
	check(tree.modulate.a==1.0,"a tree becomes opaque again when the avatar is in front")
	game.state.player_position=Vector2(house.data.x+house.data.w*0.5,house.data.y-8)
	for i in range(10): world.refresh()
	check(house.modulate.a<0.4,"a house fades when its roof hides the avatar")
	game.state.player_position=Vector2(900,700)
	for i in range(10): world.refresh()
	check(house.modulate.a==1.0,"unrelated houses stay opaque")
	for segment in world.road_segments:
		var continuous=true
		for i in range(21):
			var p=segment[0].lerp(segment[1],i/20.0)
			if world.road_mask.get_pixel(int(p.x),int(p.y)).r<0.99: continuous=false
		check(continuous,"road segment has an unbroken center through its junctions: %s to %s" % [segment[0],segment[1]])
	var corner=world.road_segments[0][0]-Vector2(20,20)
	check(world.road_mask.get_pixel(int(corner.x),int(corner.y)).r<0.25,"rounded road shoulders do not retain rectangular corner blocks")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	print("%d readability checks passed" % count)
	quit(1 if failed else 0)
