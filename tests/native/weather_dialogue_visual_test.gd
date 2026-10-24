extends "visual_test.gd"

func save_frame(label: String) -> Image:
	var image=root.get_texture().get_image()
	var path=ProjectSettings.globalize_path("res://../../internal/verification/native-weather-dialogue-"+label+".png").simplify_path()
	assert(image.save_png(path)==OK)
	print("Captured native "+label)
	return image

func click_point(point: Vector2) -> void:
	for pressed in [true,false]:
		var click=InputEventMouseButton.new()
		click.position=point
		click.button_index=MOUSE_BUTTON_LEFT
		click.pressed=pressed
		Input.parse_input_event(click)
		await process_frame

func run() -> void:
	prefix="weather-dialogue-"
	game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	game.opening.finish()
	await process_frame
	var before=game.ui.modal_box.get_child(2).text
	await press_key(KEY_SPACE)
	await press_key(KEY_E)
	await click_point(Vector2(8,8))
	assert(game.ui.modal_box.get_child(2).text==before,"real key presses and an outside click must not skip a dialogue button")
	await click_point(game.ui.modal_box.get_child(3).get_global_rect().get_center())
	assert(game.ui.modal_box.get_child(2).text!=before,"a real mouse click on Continue must advance the dialogue")
	print("PASS: native GUI dialogue advances only through its actual button")
	preload("fixture.gd").explore(game,true)
	game.state.met_mayor=true
	game.state.minute=720
	game.state.player_position=game.Grid.center(Vector2i(21,48))
	game.state.weather_override="sunny"
	await capture("sunny")
	game.state.weather_override="rainy"
	await capture("rain")
	var rain=root.get_texture().get_image()
	game.outdoors.weather_effects.strike()
	for i in range(3):
		await RenderingServer.frame_post_draw
		var image=save_frame("lightning-"+str(i+1))
		var bright=image.get_pixel(640,300).get_luminance()>rain.get_pixel(640,300).get_luminance()+0.3
		assert(bright==(i<2),"lightning must brighten exactly two rendered frames")
	game.ui.toggle_log()
	game.ui.quest_rows.get_child(0).pressed.emit()
	await capture("expanded-log")
	game.ui.toggle_log()
	game.state.met_mayor=false
	game.state.welcome_phase="unvisited"
	game.enter_building("home")
	for task in game.state.house_tasks: game.state.house_tasks[task]=true
	for i in range(600):
		game._process(0.05)
		if game.state.welcome_phase=="meeting": break
	assert(game.state.welcome_phase=="meeting")
	await capture("welcome-facing")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
