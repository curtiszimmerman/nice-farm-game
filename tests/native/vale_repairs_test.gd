extends SceneTree
const Game=preload("res://game.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")

func buttons(game: Node2D) -> Array:
	return game.ui.modal_box.get_children().filter(func(node):return node is Button and node.visible)

func press(game: Node2D,label: String) -> bool:
	var found=buttons(game).filter(func(node):return node.text==label)
	if found.is_empty():
		print("No button '",label,"' among ",buttons(game).map(func(node):return node.text))
		return false
	found[0].pressed.emit()
	return true

func said(game: Node2D) -> String:
	return game.ui.modal_box.get_child(2).text

func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	game.state.copper_bars=3
	game.talk("vale")
	check(press(game,"Hand over three copper bars."),"Vale takes the copper bars")
	check(said(game).begins_with("This looks great!") and "Thanks for bringing me dinner" in said(game),"Vale thanks the captain and explains the repeater needs a day of work")
	check(buttons(game).size()==1 and press(game,"No problem, Chief!"),"the captain can only answer 'No problem, Chief!'")
	check(not game.window_open and game.state.delivered and game.state.copper_bars==0,"that answer ends the conversation with the bars handed over")
	check(not game.state.repeater_working(),"the repeater isn't working until Vale has had a day with it")
	game.talk("vale")
	check(press(game,"What's the status on repairs?") and "commlink" not in said(game),"asking too soon, Vale is still building the parts")
	game.close_window()
	game.state.day+=1
	check(game.state.repeater_working(),"a day later the repeater works")
	game.talk("vale")
	check(press(game,"What's the status on repairs?") and said(game).begins_with("Give your commlink a try. Hear that? Much better than guessing what one another's thinking!"),"Vale's status update has the captain try the commlink")
	check(buttons(game).size()==1 and press(game,"Much better, Chief. Next we need to get the replicator up, for food and water."),"the captain moves on to the replicator")
	check(said(game).begins_with("My thoughts exactly, Captain.") and "Two of them" in said(game) and "a quartz crystal of exceptional quality" in said(game),"Vale lists what the replicator needs")
	check(buttons(game).size()==1 and press(game,"Then that's the plan, Chief. Nice work."),"the captain agrees to the plan")
	check(not game.window_open and game.state.replicator_briefed,"agreeing ends the conversation with the replicator plan set")
	game.talk("vale")
	check(said(game)=="How are things, Captain? Still kind of a mess around here.","Vale now opens by asking how things are")
	check(press(game,"What's the status on repairs?") and said(game).begins_with("I'm going to need those supplies to get the replicator going again: Two vacuum tubes, five copper bars, and a quartz crystal of exceptional quality."),"the status reminds the captain what the replicator needs")
	game.close_window()
	game.talk("vale")
	check(press(game,"How are things holding up otherwise?") and said(game).begins_with("The cloak is holding steady, and as the gravitic sink stabilizes") and "any signals that aren't from the locals" in said(game),"Vale reports on the cloak, power and sensors")
	game.close_window()
	var restored=game.State.new()
	check(restored.restore(game.state.to_dict()) and restored.repeater_working() and restored.replicator_briefed,"the repairs' progress survives a save")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
