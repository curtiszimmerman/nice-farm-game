extends "visual_test.gd"

func run() -> void:
	prefix="replicator-"
	game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	game.opening.finish()
	game.ui.toggle_log()
	game.ui.quest_opened.find_vale=true
	await capture("find-vale")
	preload("fixture.gd").explore(game,true)
	game.enter_building("ship")
	game.ui.quest_opened.crew_supplies=true
	game.talk("vale")
	await capture("food-first")
	game.close_window()
	game.state.copper_bars=2
	game.state.deliver_replicator_copper()
	game.state.advance(1440)
	game.talk("vale")
	game.ui.modal_box.get_children().filter(func(node):return node is Button and node.text=="What's the status on repairs?")[0].pressed.emit()
	await capture("replicator-online")
	game.ui.modal_box.get_children().filter(func(node):return node is Button)[0].pressed.emit()
	await capture("repeater-supplies")
	game.ui.modal_box.get_children().filter(func(node):return node is Button)[0].pressed.emit()
	game.ui.quest_opened.repeater=true
	await capture("commlink-quest")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
