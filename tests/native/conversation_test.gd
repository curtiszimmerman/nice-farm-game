extends SceneTree
const Game=preload("res://game.gd")
var failed=false
func check(value: bool,label: String) -> void:
	if value: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game)
	game.state.met_mayor=true
	game.state.minute=600
	game.outdoors.update_villagers(0,true)
	game.enter_building("store")
	game.talk("tavi")
	var position=game.outdoors.villagers.tavi.position
	game.state.minute=1300
	game.outdoors.update_villagers(1)
	check(game.outdoors.villagers.tavi.position==position,"Tavi stays put through closing time while talking")
	game.state.money=50
	var before=game.state.seeds
	var sale_option=game.ui.modal_box.get_children().filter(func(node):return node is Button and node.text=="What have you got for sale?")
	if not sale_option.is_empty(): sale_option[0].pressed.emit()
	var seeds=game.ui.modal_box.get_children().filter(func(node):return node is Button and node.text.contains("moon-turnip seeds"))
	if not seeds.is_empty(): seeds[0].pressed.emit()
	check(game.state.seeds==before+5 and game.window_open,"seed sales remain available after closing and keep the conversation open")
	game.close_window()
	game.outdoors.update_villagers(1)
	check(game.outdoors.villagers.tavi.position!=position,"closing the conversation releases Tavi to his routine")
	game.leave_building()
	game.state.invited=true
	game.state.met_mayor=false
	game.state.day=2
	game.state.minute=600
	game.state.mayor_due=2040
	game.outdoors.update_villagers(0,true)
	check(["moss","mayor","assistant"].all(func(id): return game.outdoors.villagers[id].position.distance_to(game.outdoors.site_position("bed"))<170),"Moss Alder and his assistant wait at the arranged visit time")
	game.state.minute=720
	game.state.player_position=game.outdoors.site_position("bed")+Vector2(0,32)
	game.mayor()
	check(not game.state.met_mayor and game.conversation_members.size()==3,"the introduction holds all three participants without completing the quest early")
	var positions={}
	for id in game.conversation_members: positions[id]=game.outdoors.villagers[id].position
	game.state.minute=1000
	game.outdoors.update_villagers(1)
	check(positions.keys().all(func(id): return positions[id]==game.outdoors.villagers[id].position),"the entire group waits beyond four while the conversation continues")
	for i in range(3): game.ui.modal_box.get_child(3).pressed.emit()
	check(game.state.met_mayor and game.conversation_members.is_empty(),"the final dialogue option completes the introduction and releases everyone")
	game.state.met_mayor=false
	game.state.minute=750
	game.mayor()
	game.state.player_position+=Vector2(300,0)
	game._process(0.1)
	check(game.conversation_members.is_empty() and not game.window_open and game.state.abandoned_day.has("assistant"),"walking away abandons a multi-person conversation and sends the participants home")
	game.outdoors.update_villagers(0,true)
	check(game.outdoors.stop_for("assistant").room=="assistant" and not game.outdoors.villagers.assistant.data.sleeping,"abandoned participants return home without locking their house during daytime")
	game.state.player_position=game.outdoors.site_position("bed")
	game._process(0.1)
	check(not game.window_open,"an abandoned introduction does not immediately restart at the farm")
	game.state.invited=true
	game.state.abandoned_day.erase("veteran")
	game.talk("veteran")
	game.state.player_position+=Vector2(300,0)
	game._process(0.1)
	check(game.state.abandoned_day.get("veteran")==game.state.day,"leaving the first box of an optional multi-part conversation sends its speaker home")
	game.state.day=3
	game.state.minute=960
	game.outdoors.update_villagers(0,true)
	check(game.outdoors.villagers.mayor.position.distance_to(game.outdoors.site_position("bed"))>170,"the group leaves after four when no conversation is active")
	game.state.met_mayor=true
	game.state.minute=600
	game.state.abandoned_day.iona=game.state.day
	game.outdoors.update_villagers(0,true)
	check(game.outdoors.villagers.iona.position==game.outdoors.Grid.center(Vector2i(61,15)),"abandoned night owls return to their bed instead of their midnight work spot")
	game.enter_building("radio")
	game.talk("finch")
	var finch=game.world.villagers.finch
	var indoor_position=finch.position
	game.state.minute=1430
	game.outdoors.update_villagers(2)
	game.world.update_villagers(2)
	check(finch.visible and finch.position==indoor_position,"indoor conversations keep their speaker present past bedtime")
	game.close_window()
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
