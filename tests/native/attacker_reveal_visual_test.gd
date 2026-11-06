extends "visual_test.gd"
func run() -> void:
	prefix="attacker-"
	game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	game.opening.set_process(false)
	for shot in [[3.15,1,"appearing"],[4.0,1,"settled"],[21.5,6,"window-glare"]]:
		game.opening.elapsed=shot[0]
		game.opening.caption_step=shot[1]
		game.opening.view.queue_redraw()
		await capture(shot[2])
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
