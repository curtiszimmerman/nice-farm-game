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
	game.state.money=1000
	game.tavi_shop()
	var button=game.ui.modal_box.find_children("*","Button",true,false).filter(func(b):return b.text.begins_with("Five moon-turnip"))[0]
	button.button_down.emit()
	await create_timer(0.6).timeout
	check(game.ui.modal_box.get_child(0).text=="BUY QUANTITY","holding a shop row opens a quantity selector")
	game.ui.quantity_control.value=16
	game.ui.modal_box.get_children().filter(func(child):return child is Button and child.text.begins_with("Buy "))[0].pressed.emit()
	check(game.state.seeds==80 and game.state.money==840 and game.state.stock("seeds")==64,"one confirmation buys sixteen packets containing eighty seeds")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
