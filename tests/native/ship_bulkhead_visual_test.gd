extends "visual_test.gd"
const Interior=preload("res://interior.gd")
func run() -> void:
	prefix="bulkhead-"
	game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	game.enter_building("ship")
	for kind in ["bed","console","cabinet"]:
		var object=game.world.get_children().filter(func(n):return n is Interior.Furniture and n.item.kind==kind)[0]
		game.state.player_position=object.position+Vector2(object.item.bounds.size.x*32+1,-16)
		await capture(kind+"-side")
	game.leave_building()
	game.enter_building("smithy")
	game.smith_shop()
	await capture("metal-shop")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
