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
	game.state.world_seed=1442
	game.bulletin_board()
	var buttons=game.ui.modal_box.get_children().filter(func(node):return node is Button)
	buttons[2].pressed.emit()
	game.ui.modal_box.get_children().filter(func(node):return node is Button)[0].pressed.emit()
	var active=game.state.requests.jobs.filter(func(job):return job.status=="active")
	check(active.size()==1,"the notice-board Accept button creates a real active request")
	var job=active[0]
	var terms=game.state.requests.POOL[int(job.template)]
	var id=game.state.requests.quest_id(job)
	game.close_window()
	game.state.set(terms[1],terms[2])
	game.talk(terms[0])
	var deliveries=game.ui.modal_box.get_children().filter(func(node):return node is Button and node.text.begins_with("Deliver "))
	check(deliveries.size()==1,"the actual recipient offers to receive the notice-board supplies")
	var money=game.state.money
	if not deliveries.is_empty(): deliveries[0].pressed.emit()
	check(job.status=="complete" and game.state.money==money+terms[3],"NPC dialogue delivers the actual items and pays the reward")
	check(game.ui.quest_lines().any(func(quest):return quest.id==id and quest.complete),"completed weekly requests remain in character quest history")
	game.close_window()
	game.bulletin_board()
	check(game.ui.modal_box.get_children().filter(func(node):return node is Button).size()==4,"a delivery immediately makes room for another board notice")
	var next=game.state.requests.jobs.filter(func(entry):return entry.status=="offered")[0]
	game.state.requests.accept(game.state,game.state.requests.quest_id(next))
	game.state.day=8
	game.ui.update()
	var expired_id=game.state.requests.quest_id(next)
	check(game.ui.quest_lines().any(func(quest):return quest.id==expired_id and quest.get("inactive",false)),"expired requests remain available as inactive quest history")
	check(not game.ui.quest_rows.get_children().any(func(node):return node.get_meta("quest_id","")==expired_id),"expired weekly jobs leave the active Crew Log")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
