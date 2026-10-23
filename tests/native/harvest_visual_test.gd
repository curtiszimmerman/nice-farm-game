extends "visual_test.gd"

func run() -> void:
	prefix="harvest-"
	game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	game.state.met_mayor=true
	game.state.ladder_requested=true
	game.state.minute=600
	game.state.player_position=game.Grid.center(Vector2i(21,48))
	game.ui.toggle_log()
	await capture("calendar-and-crossroads")
	game.ui.toggle_log()
	game.enter_building("mill_shed")
	game.state.player_position=game.Grid.center(Vector2i(4,3))
	await capture("bell-shed")
	game.leave_building()
	game.enter_building("cave")
	game.close_window()
	game.state.player_position=game.world.entry_position()+Vector2(0,64)
	await capture("cave-sky-exit")
	game.state.player_position=game.world.spider.position+Vector2(48,16)
	await capture("spider")
	game.leave_building()
	game.state.minute=1260
	game.state.player_position=game.Grid.center(Vector2i(-25,54))
	await capture("night-glints")
	game.state.minute=720
	var berry=game.outdoors.forage_nodes.berries.keys()[0]
	game.state.player_position=game.Grid.center(berry+Vector2i.DOWN)
	game.outdoors.facing="up"
	await capture("spring-berries")
	game.state.day=57
	var apple=game.outdoors.forage_nodes.apples.keys()[0]
	game.state.player_position=game.Grid.center(apple+Vector2i.DOWN)
	game.outdoors.facing="up"
	await capture("autumn-apples")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
