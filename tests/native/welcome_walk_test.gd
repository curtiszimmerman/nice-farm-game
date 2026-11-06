extends SceneTree
const Game=preload("res://game.gd")
var failed=false
func check(value: bool,label: String) -> void:
	if value: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game)
	var w=game.outdoors
	game.state.player_position=w.Grid.center(w.MOSS_ENCOUNTER_CELL)
	game.talk("moss")
	while game.window_open: game.ui.modal_box.get_child(3).pressed.emit()
	check(game.escort_path.any(func(p): return w.Grid.world_to_cell(p)==Vector2i(18,34)),"the captain follows the painted bend around the farmhouse")
	var moss=w.villagers.moss.position
	game._process(0.1)
	check(w.villagers.moss.position.distance_to(moss)<25,"Moss begins walking rather than jumping to another appointment")
	var last_outside=game.state.player_position
	var entered=false
	var locked_at_entry=false
	var indoor_distance=0.0
	var smooth_inside=true
	var checkpoint={}
	for i in range(1200):
		var was_inside=game.current_room=="home"
		var previous=game.state.player_position
		if not was_inside: last_outside=previous
		game._process(0.05)
		if game.window_open: preload("fixture.gd").advance_dialogue(game)
		if game.current_room=="home":
			if not entered:
				locked_at_entry=game.welcome_control_locked()
				checkpoint=game.state.to_dict()
			entered=true
			if was_inside:
				var step=previous.distance_to(game.state.player_position)
				indoor_distance+=step
				smooth_inside=smooth_inside and step<=9.1
			if game.state.welcome_phase=="waiting": break
	check(entered and last_outside.distance_to(w.Grid.center(Vector2i(13,51)))<12,"the captain walks up to the actual farmhouse door before entering")
	check(locked_at_entry and indoor_distance>=95,"the guided walk continues three squares into the farmhouse")
	check(smooth_inside,"the captain walks smoothly indoors without a position jump")
	check(game.state.player_position==w.Grid.center(Vector2i(7,9)) and not game.welcome_control_locked(),"control returns in the central hallway after the entry walk")
	if not checkpoint.is_empty():
		var restored=game.State.new()
		check(restored.restore(checkpoint),"a save can capture the guided walk just inside the door")
		var resumed=Game.new()
		resumed.state=restored
		resumed.testing=true
		root.add_child(resumed)
		resumed.set_process(false)
		for i in range(120):
			resumed._process(0.05)
			if resumed.state.welcome_phase=="waiting": break
		check(resumed.state.player_position==w.Grid.center(Vector2i(7,9)) and not resumed.welcome_control_locked(),"loading an indoor entry walk finishes it before returning control")
		await resumed.sound.shutdown()
		resumed.queue_free()
		await process_frame
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
