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
	game.state.met_mayor=true
	game.state.minute=600
	game.outdoors.update_villagers(0,true)
	game.enter_building("store")
	game.state.money=200
	game.state.player_position=game.world.villagers.tavi.position+Vector2(0,32)
	game.talk("tavi")
	game.choose_dialogue(func():game.buy_cookware("pan"))
	game.ui.modal_box.get_child(3).pressed.emit()
	game.close_window()
	game._process(0.1)
	check(not game.state.abandoned_day.has("tavi"),"finishing cookware shopping never abandons a story sequence")
	check(game.world.villagers.tavi.visible,"Tavi stays in his grocery after shopping ends")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
