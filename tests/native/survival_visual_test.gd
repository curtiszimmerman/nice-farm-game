extends "visual_test.gd"

func run() -> void:
	prefix="survival-"
	game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	game.state.met_mayor=true
	game.state.minute=780
	game.state.needs.hardcore=true
	game.state.player_position=game.Grid.center(Vector2i(62,48))
	await capture("square")
	game.enter_building("ship")
	game.state.player_position=game.Grid.center(Vector2i(8,4))
	await capture("ship")
	game.inventory()
	await capture("inventory")
	game.ui.inventory_tabs.current_tab=2
	await capture("people")
	game.close_window()
	game.leave_building()
	game.state.day=7
	game.state.minute=630
	for id in game.world.Schedule.COMMUNION+["priest"]:
		game.outdoors.villagers[id].data.room="temple"
		game.outdoors.villagers[id].data.sleeping=false
	game.enter_building("temple")
	game.state.player_position=game.Grid.center(Vector2i(5,5))
	await capture("temple")
	game.leave_building()
	game.state.needs.without_water=4320
	game.state.needs.without_food=30240
	await capture("deprivation")
	game.choose_journey_mode()
	await capture("mode-choice")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
