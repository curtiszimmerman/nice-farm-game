extends SceneTree

const Game = preload("res://game.gd")
var failed=false
func check(value: bool,label: String) -> void:
	if value: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game)
	var w=game.world
	game.state.minute=540
	w.update_villagers(0.0,true)
	check(w.villagers.tavi.visible,"Tavi is awake at the cart in the morning")
	check(not w.villagers.iona.visible,"the wizard sleeps through the morning")
	game.state.minute=750
	w.update_villagers(0.0,true)
	var lunch=w.villagers.tavi.position
	game.state.minute=840
	w.update_villagers(0.0,true)
	check(lunch!=w.villagers.tavi.position,"Tavi takes a lunch break and returns to his cart")
	check(w.villagers.iona.visible,"the wizard wakes at noon")
	game.state.minute=60
	w.update_villagers(0.0,true)
	check(w.villagers.iona.visible and not w.villagers.tavi.visible,"wizard studies at night while Tavi sleeps")
	game.state.minute=540
	w.update_villagers(0.0,true)
	var start=w.villagers.tavi.position
	game.state.minute=750
	w.update_villagers(0.1)
	check(w.villagers.tavi.position.distance_to(start)>0 and w.villagers.tavi.position.distance_to(start)<10,"villagers walk toward their next stop")
	var clear=true
	for i in range(500):
		w.update_villagers(0.1)
		for actor in w.villagers.values():
			if w.blocked(actor.position): clear=false
	check(clear,"villager routes avoid buildings, water, and fences")
	check(w.villagers.tavi.position.distance_to(lunch)<1,"Tavi reaches the lunch stop")
	var reachable=true
	for id in w.Schedule.ROUTINES:
		for stop in w.Schedule.ROUTINES[id]:
			var cell=Vector2i(stop[1],stop[2])
			if w.blocked(w.Grid.center(cell)) or w._route(w.Grid.SPAWN_CELL,cell).is_empty(): reachable=false
	check(reachable,"every scheduled destination is walkable and connected to the farm")
	game.state.minute=540
	w.update_villagers(0.0,true)
	game.state.minute=750
	game.window_open=true
	game.state.pause_mode="all"
	start=w.villagers.tavi.position
	game._process(0.1)
	check(w.villagers.tavi.position==start,"full pause stops villagers")
	game.state.pause_mode="clock"
	game._process(0.1)
	check(game.state.minute==750 and w.villagers.tavi.position!=start,"clock pause permits movement without advancing the schedule")
	game.window_open=false
	game.state.invited=true
	game.state.day=2
	game.state.minute=720
	game.state.mayor_due=2160
	w.update_villagers(0.0,true)
	check(w.villagers.mayor.position==w.Grid.center(w.Grid.SPAWN_CELL+Vector2i(1,0)),"the mayor keeps the farmhouse appointment")
	game.state.minute=0
	w.update_villagers(0.0,true)
	game.state.player_position=w.villagers.tavi.position
	check(w.find_nearest().get("id","")!="tavi","sleeping villagers cannot be talked to through their house")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
