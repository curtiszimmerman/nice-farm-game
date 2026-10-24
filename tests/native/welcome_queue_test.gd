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
	game.state.welcome_phase="unvisited"
	game.enter_building("home")
	game.outdoors.story_destinations.clear()
	for task in game.state.house_tasks: game.state.house_tasks[task]=true
	game._process(1.5)
	check(game.state.welcome_phase=="arriving","cleanup begins the welcome promptly")
	check(game.WELCOME_MEMBERS.all(func(id):return game.outdoors.story_destinations.has(id)),"resuming cleanup reconstructs every visitor's walking destination")
	if game.state.welcome_phase=="waiting": game.mayor()
	check(not game.ui.quick_tray.visible and not game.ui.calendar_ring.visible and not game.ui.log_panel.visible and not game.ui.place.visible,"the arrival hides every ordinary HUD element immediately")
	var first_entry=-1.0
	var seen=[]
	var separated=true
	var overlapping_arrival=false
	var followed_motion=true
	game.world.facing="up"
	for i in range(600):
		var previous=game.state.player_position
		game._process(0.05)
		var motion=game.state.player_position-previous
		if motion.y>0.1 and absf(motion.y)>absf(motion.x) and game.world.facing!="down": followed_motion=false
		if game.world.villagers.moss.visible and game.world.villagers.mayor.position.distance_to(game.Grid.center(game.WELCOME_POSITIONS[0]))>1: overlapping_arrival=true
		var visible=[]
		for id in game.WELCOME_MEMBERS:
			if game.world.villagers[id].visible:
				visible.append(id)
				if id not in seen:
					if first_entry<0: first_entry=i*0.05
					seen.append(id)
		for a in visible:
			for b in visible:
				if a!=b and game.world.villagers[a].position.distance_to(game.world.villagers[b].position)<28: separated=false
		if game.state.welcome_phase=="meeting": break
	check(first_entry>=0 and first_entry<10,"the first visitor enters within ten seconds of cleanup")
	check(seen==game.WELCOME_MEMBERS and separated,"visitors enter in order and remain physically separated")
	check(overlapping_arrival,"the next visitor enters before the leader reaches his final meeting position")
	check(game.state.welcome_phase=="meeting","all visitors reach their meeting positions")
	check(followed_motion,"the guided captain faces the direction he is walking")
	var facing_player=true
	for id in game.WELCOME_MEMBERS:
		var actor=game.world.villagers[id]
		var delta=game.state.player_position-actor.position
		var expected=("right" if delta.x>0 else "left") if absf(delta.x)>absf(delta.y) else ("down" if delta.y>0 else "up")
		if actor.data.get("direction","")!=expected: facing_player=false
	check(facing_player,"all welcome visitors turn toward the captain after arriving")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
