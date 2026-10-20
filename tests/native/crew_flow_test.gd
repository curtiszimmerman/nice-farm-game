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
	game.opening.finish()
	var lines=[]
	while game.window_open:
		lines.append(game.ui.modal_box.get_child(2).text)
		game.ui.modal_box.get_child(3).pressed.emit()
	check(lines.any(func(line): return "reinforcements" in line.to_lower()),"Vale warns of the enemy's signal before the captain prioritizes the cloak")
	game.leave_building()
	var moss=game.outdoors.villagers.moss
	var waiting=moss.position
	game.state.player_position=waiting+Vector2(0,40)
	game._process(0)
	check(game.window_open and moss.position==waiting,"Moss starts at the trail foot and never teleports into the encounter")
	while game.window_open: game.ui.modal_box.get_child(3).pressed.emit()
	check(game.state.welcome_phase=="escorting" and game.clock_held(),"Moss's invitation starts a guided walk without releasing the clock")
	for i in range(1000):
		game._process(0.05)
		if game.current_room=="home": break
	check(game.current_room=="home" and game.state.welcome_phase=="waiting","the guided walk brings the captain inside the farmhouse automatically")
	var s=game.State.new()
	s.hoe=1
	s.seeds=1
	s.assign_slot(0,"seeds")
	s.plots[0].tilled=true
	s.farm(0)
	check(s.seeds==0 and s.quick_slots[0]=="","planting the final seed clears its assigned slot")
	s.money=100
	s.buy_utensil("pan")
	s.fish=3
	check(s.cook("fish_sticks"),"carried cookware works without a selected quick slot")
	s.storage_transfer("chest",6,"pan")
	check(not s.cook("fish_sticks"),"cookware in an outdoor chest does not enable cooking")
	s.storage_transfer("chest",6)
	s.storage_transfer("cabinet",6,"pan")
	check(s.cook("fish_sticks"),"cookware in the connected cabinet enables its recipe")
	game.toast("A visible status message")
	check(game.ui.message.get_parent() is PanelContainer,"status messages have a framed background")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
