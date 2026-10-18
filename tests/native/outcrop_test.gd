extends SceneTree

const Game = preload("res://game.gd")
var failed = false
var count = 0

func check(value: bool,description: String) -> void:
	if value:
		count+=1
		print("PASS: "+description)
	else:
		failed=true
		push_error("FAIL: "+description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	game.state.player_position=game.world.site_position("ore")+Vector2(0,80)
	var event=InputEventKey.new()
	event.physical_keycode=KEY_W
	event.keycode=KEY_W
	event.pressed=true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	for i in range(30): game._move(1.0/60.0)
	event=event.duplicate()
	event.pressed=false
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	check(not game.world.blocked(game.state.player_position),"walking up to the outcrop stops at its visible rock face")
	check(game.world.find_nearest().get("id")=="ore","the visible rock face offers copper interaction")
	for i in range(3):
		game.interact()
		game._process(1.2)
	check(game.state.copper==3 and game.state.energy==85.0,"three interactions at the visible seam collect copper and charge energy")
	game.state.player_position=game.world.Grid.center(game.world.COPPER_CELLS.position)
	check(game.world.find_nearest().get("id")=="ore","the left exposed copper veins are also interactive")
	game.state.player_position=game.world.Grid.center(game.world.COPPER_CELLS.end-Vector2i.ONE)
	check(game.world.find_nearest().get("id")=="ore","the right exposed copper veins are also interactive")
	game.state.player_position=game.world.site_position("ore")+Vector2(0,140)
	check(game.world.find_nearest().get("id")!="ore","copper cannot be gathered far down the road")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	print("%d outcrop checks passed" % count)
	quit(1 if failed else 0)
