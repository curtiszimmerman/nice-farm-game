extends "visual_test.gd"
func run() -> void:
	prefix="town-polish-"
	game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	game.state.met_mayor=true
	game.state.minute=800
	var coast=game.outdoors.Coast
	game.state.player_position=game.Grid.center(Vector2i(coast.shoreline(65,game.state.world_seed)+1,65))
	game.outdoors.elapsed=3
	await capture("southern-beach")
	game.state.player_position=game.Grid.center(Vector2i(coast.shoreline(30,game.state.world_seed)+4,30))
	await capture("northern-cliffs")
	game.state.weather_override="rainy"
	game.state.player_position=game.Grid.center(Vector2i(63,47))
	await capture("rain")
	game.state.weather_override="sunny"
	game.state.money=1000
	game.tavi_shop()
	await capture("shop")
	var button=game.ui.modal_box.find_children("*","Button",true,false).filter(func(b):return b.text.begins_with("Five moon-turnip"))[0]
	var down=InputEventMouseButton.new()
	down.button_index=MOUSE_BUTTON_LEFT
	down.pressed=true
	down.position=button.get_global_rect().get_center()
	Input.parse_input_event(down)
	await create_timer(0.65).timeout
	var up=InputEventMouseButton.new()
	up.button_index=MOUSE_BUTTON_LEFT
	up.position=down.position
	Input.parse_input_event(up)
	await capture("bulk-purchase")
	if game.ui.modal_box.get_child(0).text!="BUY QUANTITY":
		failed=true
		push_error("FAIL: holding a real GUI shop row opens quantity selection")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
