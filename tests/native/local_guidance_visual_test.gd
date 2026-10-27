extends "visual_test.gd"

func run() -> void:
	prefix="local-guidance-"
	game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	game.state.met_mayor=true
	game.ui.show_title()
	await capture("title")
	game.ui.title_screen.queue_free()
	game.ui.title_screen=null
	game.bulletin_board()
	await capture("board")
	game.close_window()
	game.state.firewood_requested=true
	game.talk("keeper")
	await capture("oren")
	game.close_window()
	game.talk("woodcutter")
	await capture("axe-terms")
	game.close_window()
	game.state.watering_can=1
	game.state.assign_active("primary","watering_can")
	game.talk("moss")
	await capture("moss")
	game.close_window()
	game.talk("veteran")
	game.ui.modal_box.get_children().filter(func(node):return node is Button)[0].pressed.emit()
	await capture("sword-terms")
	game.close_window()
	game.enter_building("smithy")
	game.talk("smith")
	var mining=game.ui.modal_box.get_children().filter(func(node):return node is Button and "mining copper" in node.text)
	mining[0].pressed.emit()
	await capture("smith")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
