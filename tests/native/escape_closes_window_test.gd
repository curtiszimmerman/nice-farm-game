extends SceneTree
const Game=preload("res://game.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")

func press_escape() -> void:
	var event=InputEventKey.new()
	event.physical_keycode=KEY_ESCAPE
	event.keycode=KEY_ESCAPE
	event.pressed=true
	root.push_input(event)
	var release=event.duplicate()
	release.pressed=false
	root.push_input(release)

func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	game.inventory()
	check(game.window_open,"the inventory opens")
	# When a hover tooltip is showing, the GUI uses up Escape to dismiss it before the game's
	# unhandled-key handling runs. A focused control that swallows every key stands in for that here.
	var swallower=Control.new()
	swallower.focus_mode=Control.FOCUS_ALL
	swallower.gui_input.connect(func(event):if event is InputEventKey: swallower.accept_event())
	game.ui.add_child(swallower)
	swallower.grab_focus()
	await process_frame
	press_escape()
	await process_frame
	check(not game.window_open,"Escape closes the whole inventory even when the GUI uses the key")
	swallower.queue_free()
	await process_frame
	press_escape()
	await process_frame
	check(game.window_open,"Escape with nothing open still brings up the settings menu")
	game.close_window()
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
