extends SceneTree
const Game=preload("res://game.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	game.state.met_mayor=true
	game.state.welcome_phase="complete"
	game.state.world_seed=123456
	game.outdoors.rebuild_visit(game.state)
	for phase in [[600,0],[900,1],[1200,2],[1320,2],[480,-1],[1320,-2]]:
		if game.current_room!="": game.leave_building()
		game.state.minute=phase[0]
		if phase[1]>=0:
			game.state.cave_level=phase[1]
			game.enter_building("cave")
		game.close_window()
		if phase[1]== -2:
			game.resting=480
			game.rest_return_position=game.Grid.center(game.Grid.SPAWN_CELL)
			while game.resting>0:
				game._process(0.1)
				await process_frame
		game.outdoors.route_profile={"calls":0,"max_us":0,"expanded":0,"actor":""}
		var longest=0
		var total=0
		var spikes=0
		for frame in range(120):
			var start=Time.get_ticks_usec()
			game._process(0.1)
			var duration=Time.get_ticks_usec()-start
			longest=maxi(longest,duration)
			total+=duration
			if duration>50000: spikes+=1
			await process_frame
		print("PERFORMANCE minute=",phase[0]," cave=",phase[1]," after_sleep=",phase[1]== -2," mean_ms=",total/120000.0," max_ms=",longest/1000.0," spikes=",spikes)
		print("ROUTES ",game.outdoors.route_profile)
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit()
