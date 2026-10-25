extends "visual_test.gd"

func run() -> void:
	prefix="finished-terrain-"
	game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	game.state.met_mayor=true
	game.state.minute=720
	game.state.weather_override="sunny"
	game.state.player_position=game.Grid.center(Vector2i(62,49))
	await capture("town-paving")
	game.state.player_position=game.Grid.center(Vector2i(13,27))
	await capture("mountain-trail")
	game.state.player_position=game.Grid.center(Vector2i(19,67))
	await capture("pond-shore")
	game.state.player_position=game.Grid.center(Vector2i(-24,53))
	await capture("coast-and-jetty")
	game.state.player_position=game.Grid.center(Vector2i(11,51))
	for i in range(6):
		game.state.plots[i].tilled=true
		game.state.plots[i].watered=i<3
		game.state.plots[i].water_day=game.state.day
		game.state.plots[i].planted=game.state.total()
	game.state.plots[1].growth=game.state.CROP_MINUTES
	await capture("connected-field")
	game.state.day=57
	game.state.weather_override="rainy"
	await capture("autumn-rain-field")
	game.state.day=85
	game.state.weather_override="partly_cloudy"
	game.state.player_position=game.Grid.center(Vector2i(19,67))
	await capture("winter-pond")
	game.state.player_position=game.Grid.center(Vector2i(-24,53))
	await capture("winter-coast")
	game.state.day=1
	game.state.weather_override="sunny"
	game.enter_building("cave")
	game.close_window()
	game.state.player_position=game.world.entry_position()+Vector2(32,48)
	await capture("cavern-walls")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
