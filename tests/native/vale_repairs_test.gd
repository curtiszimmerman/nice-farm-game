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
	game.state.copper_bars=2
	game.talk("vale")
	check(press(game,"Hand over two copper bars."),"Vale takes two copper bars")
	check(said(game).begins_with("This looks great!") and "replicator" in said(game) and "minor damage" in said(game),"Vale explains the replicator's small repair needs a day of work")
	check(buttons(game).size()==1 and press(game,"No problem, Chief!"),"the captain can only answer 'No problem, Chief!'")
	check(not game.window_open and game.state.delivered and game.state.copper_bars==0,"that answer ends the conversation with the bars handed over")
	check(not game.state.replicator_working(),"the replicator isn't working until Vale has had a day with it")
	game.talk("vale")
	check(press(game,"What's the status on repairs?") and "commlink" not in said(game),"asking too soon, Vale is still building the parts")
	game.close_window()
	game.state.ship_water=0
	game.state.ship_storage[0].clear()
	game.state.advance(1440)
	check(game.state.replicator_working(),"a day later the replicator works")
	check(game.state.ship_water==game.state.SHIP_WATER and game.state.ship_storage.any(func(slot):return slot.get("id")=="rations" and slot.count>=13),"repair completion replenishes rations and water")
	game.talk("vale")
	check(press(game,"What's the status on repairs?") and said(game).begins_with("Try the dispenser, Captain."),"Vale's status update confirms food and water are available")
	check(buttons(game).size()==1 and press(game,"Good work, Chief. Let's get our local commlink working next."),"the captain moves on to the commlink repeater")
	check("two vacuum tubes" in said(game) and "five copper bars" in said(game) and "a quartz crystal of exceptional quality" in said(game),"Vale lists the commlink's requirements")
	check(buttons(game).size()==1 and press(game,"Then that's the plan, Chief. Nice work."),"the captain agrees to the plan")
	check(not game.window_open and game.state.repeater_briefed,"agreeing ends the conversation with the repeater plan set")
	game.talk("vale")
	check(said(game)=="How are things, Captain? Still kind of a mess around here.","Vale now opens by asking how things are")
	check(press(game,"What's the status on repairs?") and "two vacuum tubes, five copper bars, and a quartz crystal of exceptional quality" in said(game) and "replicator's keeping us supplied" in said(game),"the status reminds the captain what the repeater needs")
	game.close_window()
	game.talk("vale")
	check(press(game,"How are things holding up otherwise?") and said(game).begins_with("The cloak is holding steady, and as the gravitic sink stabilizes") and "any signals that aren't from the locals" in said(game),"Vale reports on the cloak, power and sensors")
	game.close_window()
	var restored=game.State.new()
	game.ui.quest_lines()
	check(restored.restore(game.state.to_dict()) and restored.replicator_working() and restored.repeater_briefed,"the repair and quest progress survive a save")
	game.state.ship_water=0
	game.state.ship_storage[0].clear()
	game.state.advance(1440)
	check(game.state.ship_water==game.state.SHIP_WATER and game.state.ship_storage.any(func(slot):return slot.get("id")=="rations" and slot.count>=13),"the working replicator maintains the crew's daily supplies")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
