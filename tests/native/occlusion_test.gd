extends SceneTree
const Game=preload("res://game.gd")
const World=preload("res://world.gd")
const Interior=preload("res://interior.gd")
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
	var house=game.outdoors.scenery_layer.get_children().filter(func(n):return n is World.Prop and n.kind=="building")[0]
	for x in [-1,house.data.w+1]:
		game.state.player_position=house.position+Vector2(x,-16)
		check(not game.outdoors.prop_hides_player(house),"standing alongside a house never fades it")
	game.state.player_position=house.position+Vector2(house.data.w/2,-16)
	check(game.outdoors.prop_hides_player(house),"standing behind the house still fades it")
	for i in range(10): game.outdoors.refresh()
	game.state.player_position=house.position+Vector2(-1,-16)
	game.outdoors.refresh()
	check(house.modulate.a==1,"stepping to the side immediately restores full opacity")
	var tree=game.outdoors.scenery_layer.get_children().filter(func(n):return n is World.Prop and n.kind=="tree")[0]
	var size=game.outdoors.Art.sprite_size(game.outdoors.Art.tree_id(tree.data))
	game.state.player_position=tree.position+Vector2(-47,-size.y+26)
	check(not game.outdoors.prop_hides_player(tree),"transparent canopy corners do not hide the player")
	game.enter_building("home")
	var table=game.world.get_children().filter(func(n):return n is Interior.Furniture and n.item.kind=="table")[0]
	for x in [-1,table.item.bounds.size.x*32+1]:
		game.state.player_position=table.position+Vector2(x,-16)
		game.world.refresh()
		check(table.modulate.a==1,"standing alongside furniture never fades it")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
