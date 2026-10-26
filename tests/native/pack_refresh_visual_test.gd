extends "visual_test.gd"
func run() -> void:
	prefix="pack-refresh-"
	game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	game.state.minute=780
	game.state.weather_override="sunny"
	await capture("before")
	var region=Rect2i(1038,8,190,255)
	var before=root.get_texture().get_image().get_region(region).get_data()
	var scenery=Rect2i(700,200,280,350)
	var scenery_before=root.get_texture().get_image().get_region(scenery).get_data()
	for pack in ["option2","option3","option2","option3"]: game.change_art_pack("res://art/"+pack+"/pack.json")
	await capture("after")
	var after=root.get_texture().get_image().get_region(region).get_data()
	if before!=after:
		failed=true
		push_error("FAIL: switching away and back must redraw calendar sprites from the selected atlas")
	else: print("PASS: repeated pack switches preserve the calendar's rendered pixels")
	if scenery_before!=root.get_texture().get_image().get_region(scenery).get_data():
		failed=true
		push_error("FAIL: repeated pack switches must refresh retained scenery textures too")
	else: print("PASS: retained scenery keeps identical pixels after switching away and back")
	game.state.apply_poison()
	game.state.awake_minutes=1500
	game.ui.update()
	for pack in ["option2","option3"]: game.change_art_pack("res://art/"+pack+"/pack.json")
	var statuses_current=game.ui.status_icons.values().all(func(button):return button.get_child(0).texture.atlas==game.Art.atlas)
	if not statuses_current:
		failed=true
		push_error("FAIL: active status icons must use the selected atlas after pack changes")
	else: print("PASS: active status icons refresh their atlas bindings")
	await capture("statuses")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
