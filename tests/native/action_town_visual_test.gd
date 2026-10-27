extends "visual_test.gd"
func run() -> void:
	prefix="action-town-"
	game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	game.state.day=2
	game.state.minute=800
	game.state.met_mayor=true
	game.state.needs.hardcore=true
	game.state.player_position=game.Grid.center(Vector2i(14,52))
	game.world.refresh()
	await capture("farm-and-clock")
	game.enter_building("mayor")
	await capture("mayor-wall")
	game.leave_building()
	game.state.player_position=game.Grid.center(Vector2i(59,52))
	game.world.refresh()
	await capture("temple-square")
	game.state.minute=1200
	game.outdoors.update_villagers(0,true)
	game.enter_building("tavern")
	await capture("tavern")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
