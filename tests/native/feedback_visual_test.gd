extends "visual_test.gd"

func run() -> void:
	prefix="feedback-"
	game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	game.state.met_mayor=true
	game.state.minute=840
	game.state.player_position=game.Grid.center(Vector2i(63,49))
	await capture("square")
	var normal_zoom=game.camera.zoom
	game.camera.zoom=Vector2(0.62,0.62)
	game.state.player_position=game.Grid.center(Vector2i(38,53))
	await capture("farm-town-road")
	game.camera.zoom=normal_zoom
	game.state.player_position=game.Grid.center(Vector2i(48,62))
	await capture("temple")
	game.state.player_position=game.Grid.center(Vector2i(54,47))
	await capture("hall-sign")
	game.state.player_position=game.Grid.center(Vector2i(69,38))
	await capture("tavern-sign")
	game.state.minute=1200
	game.state.player_position=game.Grid.center(Vector2i(13,52))
	await capture("lanterns")
	game.state.day=29
	game.outdoors.ambient.clear()
	var motion=preload("res://outdoor_motion.gd")
	motion.update(game.outdoors)
	var mote=game.outdoors.ambient.fireflies[0]
	game.state.player_position=mote.position+Vector2(0,48)
	game.outdoors.elapsed=19
	mote.phase=PI/2.0-19*mote.speed
	game.world.refresh()
	await capture("summer-fireflies")
	if DisplayServer.get_name()!="headless":
		var screen=root.get_canvas_transform()*(mote.position+Vector2(sin(PI*0.35)*10,cos(PI*0.65)*7))
		var picture=root.get_texture().get_image()
		var glowing=false
		for y in range(int(screen.y)-8,int(screen.y)+9):
			for x in range(int(screen.x)-8,int(screen.x)+9):
				if x<0 or y<0 or x>=picture.get_width() or y>=picture.get_height(): continue
				var pixel=picture.get_pixel(x,y)
				if pixel.r>0.65 and pixel.g>0.65 and pixel.b<0.6: glowing=true
		if not glowing:
			failed=true
			push_error("FAIL: fireflies remain visibly luminous through the night tint")
	game.state.woodcutter_axe_given=true
	game.state.requests.axe_due=game.state.total()+1440*3
	game.ui.toggle_log()
	game.ui.quest_opened.axe_repayment=true
	game.ui.render_quests()
	game.state.money=2000
	game.tavi_shop()
	await capture("wallet-quests")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
