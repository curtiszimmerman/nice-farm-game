extends "visual_test.gd"
const Interior=preload("res://interior.gd")
func run() -> void:
	prefix="stable-depth-"
	game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	game.state.met_mayor=true
	for task in game.state.house_tasks: game.state.house_tasks[task]=true
	game.enter_building("home")
	for kind in ["sofa","bookshelf","chair"]:
		var object=game.world.get_children().filter(func(n):return n is Interior.Furniture and n.item.kind==kind)[0]
		game.state.player_position=object.position+Vector2(-1 if kind=="chair" else object.item.bounds.size.x*32+1,-16)
		await capture(kind+"-side")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
