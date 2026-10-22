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
	preload("fixture.gd").explore(game)
	game.enter_building("cave")
	check(game.window_open and game.ui.modal_box.get_child(2).text.contains("pickaxe"),"first cave entry notices the abandoned pickaxe")
	check(game.state.cave_barrel.all(func(stack):return stack.is_empty()),"the pickaxe leans outside the four-slot barrel")
	game.close_window()
	check(game.world.site_position("cave_pickaxe")!=Vector2.ZERO,"the leaning pickaxe has a physical pickup site")
	game.state.player_position=game.world.site_position("cave_pickaxe")
	game.interact()
	check(game.state.pickaxe==1 and game.state.quick_slots.all(func(id):return id==""),"picking up the cave tool carries it without assigning a shortcut")
	game.leave_building()
	game.enter_building("cave")
	check(not game.window_open,"the cave arrival thought only appears once")
	var restored=game.State.new()
	check(restored.restore(game.state.to_dict()) and restored.cave_intro_seen and restored.cave_pickaxe_taken,"cave discovery and pickup survive a save round trip")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
