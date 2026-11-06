extends SceneTree
const Game=preload("res://game.gd")
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
	game.enter_building("home")
	var objects=game.world.get_children().filter(func(n):return n is Interior.Furniture or n is Interior.Wall)
	var layers={}
	for object in objects: layers[object]=object.z_index
	for kind in ["sofa","bookshelf","chair"]:
		var object=objects.filter(func(n):return n is Interior.Furniture and n.item.kind==kind)[0]
		game.state.player_position=object.position+Vector2(-1 if kind=="chair" else object.item.bounds.size.x*32+1,-16)
		game.world.refresh()
		check(objects.all(func(n):return n.z_index==layers[n]),kind+" side approach preserves every furnishing and wall's draw layer")
		check(game.world.player.position.y>object.position.y,kind+" side approach places the avatar after the furnishing in depth order")
		if game.world.player.has_node("Avatar"):
			check(game.world.player.get_node("Avatar").global_position==game.state.player_position.round(),"depth adjustment keeps the visible avatar at its physical position")
	game.state.ship_departed=false
	game.state.house_tasks.bed=true
	game.state.house_tasks.guest_bed=true
	game.rest_options()
	check(game.ui.message.text=="Now is not the time for sleep!","introductory rest prompt uses the captain's urgent wording")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
