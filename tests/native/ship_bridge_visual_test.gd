extends "visual_test.gd"
func run() -> void:
	prefix="ship-decks-"
	game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	game.opening.finish()
	await capture("upper-bridge")
	game.leave_building()
	game.state.player_position=game.Grid.center(Vector2i(6,9))
	await capture("engineering-wiring")
	game.talk("vale")
	await capture("vale-report")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
