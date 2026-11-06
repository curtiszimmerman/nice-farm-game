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
	game.enter_building("ship")
	for kind in ["bed","console","cabinet"]:
		var object=game.world.get_children().filter(func(n):return n is Interior.Furniture and n.item.kind==kind)[0]
		game.state.player_position=object.position+Vector2(object.item.bounds.size.x*32+1,-16)
		game.world.refresh()
		var rear=game.world.get_children().filter(func(n):return n is Interior.Wall and n.position.y<=object.item.bounds.position.y*32+32 and n.position.x>=object.position.x and n.position.x<object.position.x+object.item.bounds.size.x*32)
		check(not rear.is_empty() and rear.all(func(wall):return wall.z_index<=object.z_index),kind+" remains above the rear bulkhead when the captain stands beside it")
		check(object.z_index<game.world.player.z_index,kind+" still renders below the captain at its side")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
