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
	game.state.minute=1200
	game.outdoors.update_villagers(0,true)
	game.enter_building("tavern")
	var positions=[]
	var distinct=true
	for id in game.world.villagers:
		var actor=game.world.villagers[id]
		if not actor.visible: continue
		if actor.position in positions: distinct=false
		positions.append(actor.position)
		if id!="barkeep" and actor.position.y<9*32: distinct=false
	check(positions.size()>4 and distinct,"tavern patrons have distinct places in the public taproom")
	var schedule=game.outdoors.Schedule
	check(schedule.TAVERN_DAYS.moss.size()==4 and schedule.TAVERN_DAYS.miller.size()>4 and schedule.TAVERN_DAYS.assistant.size()<4,"weekly attendance varies between residents")
	check(schedule.stop("priest",1200,1).room!="tavern","the priest never visits the tavern")
	check(schedule.ROUTINES.keys().all(func(id):return id=="iona" or schedule.stop(id,0,1).sleeping),"all residents except Iona sleep at midnight")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
