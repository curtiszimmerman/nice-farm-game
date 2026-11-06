extends "visual_test.gd"
func run() -> void:
	prefix="town-systems-"
	game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	game.state.met_mayor=true
	game.state.minute=1200
	game.state.money=1000
	game.outdoors.update_villagers(0,true)
	game.enter_building("tavern")
	await capture("tavern-groups")
	game.talk("barkeep")
	preload("fixture.gd").greet(game)
	game.ui.modal_box.get_children().filter(func(b):return b is Button and b.text=="What have you got for sale?")[0].pressed.emit()
	game.ui.modal_box.find_children("*","Button",true,false).filter(func(b):return b.text.begins_with("Valley ale"))[0].pressed.emit()
	game.close_window()
	await capture("drunk")
	game.leave_building()
	game.state.player_position=game.Grid.center(Vector2i(63,47))
	await capture("evening-lanterns")
	game.state.minute=100
	await capture("late-lanterns")
	game.state.crucible_known=true
	game.state.beehive_known=true
	game.inventory()
	game.ui.inventory_tabs.current_tab=3
	await capture("crafting-tab")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
