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
	preload("fixture.gd").garden(game.state)
	game.state.hoe=1
	game.state.assign_slot(0,"hoe")
	game.state.selected_slot=0
	game.state.player_position=game.world.plot_position(0)+Vector2.UP*32
	game.world.facing="down"
	game.interact()
	check(game.world.player.data.get("tool_motion","")=="hoe","successful tilling animates the player's hoe")
	game.state.rusty_sword=1
	game.state.assign_slot(0,"rusty_sword")
	var energy=game.state.energy
	game.world.elapsed+=0.61
	game.interact()
	check(game.world.player.data.get("tool_motion","")=="rusty_sword" and game.state.energy==energy-2,"swords also swing outdoors and spend energy")
	game.enter_building("cave")
	game.close_window()
	game.state.rusty_sword=1
	game.state.assign_slot(0,"rusty_sword")
	game.world.attack()
	check(game.world.player.data.get("tool_motion","")=="rusty_sword","sword attacks animate a swing in front of the player")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
