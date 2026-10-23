extends SceneTree
const Game=preload("res://game.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	game.enter_building("cave")
	game.close_window()
	game.state.player_position=game.Grid.center(Vector2i(4,5))
	game.world.facing="up"
	check(game.world.find_nearest().get("id")=="cave_pickaxe","facing the visible pickaxe selects it instead of its neighboring barrel")
	game.world.facing="down"
	check(game.world.find_nearest().get("id")!="cave_pickaxe","objects behind the player do not offer activation")
	game.world.facing="up"
	game.interact()
	check(game.state.pickaxe==1,"activating the facing pickaxe collects it")
	game.state.player_position=game.Grid.center(Vector2i(4,4))
	game.world.facing="left"
	check(game.world.find_nearest().get("id")=="cave_barrel","facing the barrel independently offers its storage")
	game.leave_building()
	game.enter_building("home")
	game.state.player_position=game.Grid.center(Vector2i(2,12))
	game.world.facing="left"
	check(game.world.find_nearest().get("id")=="living_light","facing the standing lamp offers its repair")
	game.world.facing="right"
	check(game.world.find_nearest().get("id")!="living_light","a nearby lamp cannot be repaired while facing away")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
