extends SceneTree
const Game=preload("res://game.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func buttons(game: Node2D) -> Array: return game.ui.modal_box.get_children().filter(func(n):return n is Button)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	var intro=game.opening
	intro.elapsed=5
	intro.shake_remaining=0.2
	check((intro.bridge_planet_rect().position+intro.bridge_offset()).is_equal_approx(intro.bridge_composition().planet.position),"incoming fire shakes the bridge while the planet stays still")
	preload("fixture.gd").explore(game,true)
	game.enter_building("smithy")
	game.state.chat_days.smith=game.state.day
	game.talk("smith")
	check(buttons(game)[0].text=="How can I refine copper ore?" and not buttons(game).any(func(b):return "Learn crucible" in b.text),"refining is Dain's first topic and the blueprint is initially hidden")
	buttons(game)[0].pressed.emit()
	game.talk("smith")
	check(buttons(game)[0].text=="What have you got for sale?" and "Learn crucible" in buttons(game)[1].text,"asking about refining puts the blueprint directly below shopping")
	game.state.star_bulbs=10
	game.learn_crucible()
	game.talk("smith")
	check(not buttons(game).any(func(b):return "Learn crucible" in b.text),"the learned blueprint disappears from Dain's choices")
	var restored=game.State.new()
	check(restored.restore(game.state.to_dict()) and restored.chat_days.has("smith_refining"),"refining conversation progress survives saving")
	game.close_window()
	game.leave_building()
	game.state.chat_days.finch=game.state.day
	game.talk("finch")
	buttons(game).filter(func(b):return "What's on the air" in b.text)[0].pressed.emit()
	check("Veyr" in game.ui.modal_box.get_child(2).text and not buttons(game).any(func(b):return "Tune" in b.text),"Finch talks about programming and his Veyr project without becoming a radio menu")
	game.close_window()
	game.talk("veteran")
	check(game.ui.modal_box.get_child(2).text.begins_with("Come in. Mind the boots by the door.") and not game.state.requests.bram_requested,"Bram welcomes visitors before discussing his sword")
	game.close_window()
	var useful=false
	var farewell=false
	for i in range(16):
		game.begin_conversation(["finch"])
		game.dialog("Finch","A THOUGHT","A clear signal is worth waiting for. "+str(i))
		useful=useful or buttons(game).any(func(b):return b.text=="That's useful to know.")
		var exits=buttons(game).filter(func(b):return b.text=="Thanks. Goodbye.")
		if not exits.is_empty(): exits[0].pressed.emit(); farewell=farewell or not game.window_open
		game.close_window()
	check(not useful and farewell,"empty useful-to-know acknowledgements become a working explicit farewell")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
