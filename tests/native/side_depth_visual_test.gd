extends "visual_test.gd"
const World=preload("res://world.gd")
const Interior=preload("res://interior.gd")
const Cave=preload("res://cave.gd")
func run() -> void:
	prefix="side-depth-"
	game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	var house=game.outdoors.scenery_layer.get_children().filter(func(n):return n is World.Prop and n.kind=="building" and n.data.id=="home")[0]
	game.state.player_position=house.position+Vector2(-1,-16)
	await capture("house-left")
	game.state.player_position=house.position+Vector2(house.data.w+1,-16)
	await capture("house-right")
	game.enter_building("home")
	var table=game.world.get_children().filter(func(n):return n is Interior.Furniture and n.item.kind=="table")[0]
	game.state.player_position=table.position+Vector2(-1,-16)
	await capture("table-left")
	game.leave_building()
	game.enter_building("cave")
	game.close_window()
	var rock=game.world.get_children().filter(func(n):return n is Cave.CaveObject and n.info.kind=="rock")[0]
	game.state.player_position=rock.position+Vector2(-17,-8)
	await capture("rock-left")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
