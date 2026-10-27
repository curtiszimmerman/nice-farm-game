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
	game.state.player_position=game.Grid.center(Vector2i(69,39))
	await capture("tavern-sign")
	game.state.player_position=game.Grid.center(Vector2i(54,39))
	await capture("radio-sign")
	var w=game.outdoors
	var tree=w.trees[0]
	game.state.axe=1
	game.state.assign_active("primary","axe")
	game.state.player_position=game.Grid.center(tree.cell+Vector2i.LEFT)
	w.facing="right"
	for i in range(3):
		w.elapsed+=0.61
		w.chop_tree(tree.cell)
	w.elapsed+=0.3
	await capture("falling-tree")
	game.state.minute=1200
	game.outdoors.update_villagers(0,true)
	game.enter_building("tavern")
	await capture("tavern")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
