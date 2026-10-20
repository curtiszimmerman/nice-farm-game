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
	preload("fixture.gd").explore(game)
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
	check(game.world.find_nearest().get("door")=="cave","the visible cave mouth offers entry")
	game.interact()
	check(game.current_room=="cave" and game.state.copper==0,"outdoor activation enters the cave instead of generating copper")
	game.state.storage_transfer("cave_barrel",0)
	game.state.assign_slot(0,"pickaxe")
	var deposits=game.world.rocks.values().filter(func(rock): return rock.ore)
	for i in range(3):
		game.state.player_position=game.Grid.center(deposits[i].cell+Vector2i.DOWN)
		game.interact()
	check(game.state.copper==3 and game.state.energy==85.0,"three cave deposits supply Vale's copper and charge energy")
	var other=deposits[3]
	game.state.player_position=game.world.entry_position()
	check(not game.world.mine_rock(other.id),"ore cannot be mined from across the dungeon")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	print("%d outcrop checks passed" % count)
	quit(1 if failed else 0)
