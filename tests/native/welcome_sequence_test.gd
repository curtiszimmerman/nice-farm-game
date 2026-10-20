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
	var now=game.state.total()
	game._process(20)
	check(game.state.total()==now,"time stays halted throughout the ship briefing")
	while game.window_open: game.ui.modal_box.get_child(3).pressed.emit()
	game._process(20)
	check(game.state.total()==now,"time remains halted after briefing until leaving the ship")
	game.leave_building()
	game._process(1)
	check(game.state.total()>now,"leaving the crashed ship starts the planet clock")
	game.state.player_position=game.Grid.center(game.World.MOSS_ENCOUNTER_CELL)
	game._process(0)
	check(game.window_open and game.world.villagers.moss.position.distance_to(game.state.player_position)<75,"Moss challenges the captain on-screen beside the farmhouse")
	now=game.state.total()
	game._process(10)
	check(game.state.total()==now,"Moss's first conversation halts time")
	var lines=[]
	while game.window_open:
		lines.append(game.ui.modal_box.get_child(2).text)
		game.ui.modal_box.get_child(3).pressed.emit()
	check(lines.any(func(line): return "spell" in line) and lines.any(func(line): return "hotel" in line),"Moss asks about the mountain flash and offers the abandoned house")
	while game.state.welcome_phase=="escorting": game._process(0.1)
	game.enter_building("home")
	game.leave_building()
	check(game.current_room=="home","the first farmhouse visit cannot be exited before the welcome")
	game._process(9)
	check(game.state.welcome_phase=="waiting" and not game.window_open,"the mayor waits until every cover and bulb is finished")
	game.state.house_tasks.living_light=true
	game._process(20)
	check(game.state.welcome_phase=="waiting","partial cleanup never starts the welcome")
	for task in game.state.house_tasks: game.state.house_tasks[task]=true
	game._process(7)
	check(game.state.welcome_phase=="waiting","the visitors allow a short pause after cleanup")
	game._process(2)
	check(game.state.welcome_phase=="arriving" and not game.window_open,"the mayor's party walks over before the meeting begins")
	preload("fixture.gd").await_visitors(game)
	check(game.state.welcome_phase=="meeting" and game.window_open,"the mayor's party arrives during the paused first visit")
	check(["moss","mayor","assistant"].all(func(id): return game.world.villagers[id].visible),"all three visitors are inside the farmhouse together")
	check(game.state.total()==now,"arrival and meeting leave the clock unchanged")
	var resumed=game.State.new()
	check(resumed.restore(game.state.to_dict()) and resumed.welcome_phase=="meeting" and resumed.ship_departed,"saving preserves the locked meeting stage and ship departure")
	game.close_window()
	game.leave_building()
	check(game.window_open and game.current_room=="home","the required meeting cannot be dismissed or escaped")
	while game.window_open: game.ui.modal_box.get_child(3).pressed.emit()
	check(game.state.welcome_phase=="departing","the final choice begins the group's walk to the door")
	game.leave_building()
	check(game.current_room=="home","the captain waits while the visitors leave")
	var captain=game.state.player_position
	var key=InputEventKey.new()
	key.physical_keycode=KEY_RIGHT
	key.pressed=true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	game._process(0.25)
	check(game.state.player_position==captain and game.state.total()==now,"movement input and time remain held during the departure")
	var released=InputEventKey.new()
	released.physical_keycode=KEY_RIGHT
	released.pressed=false
	Input.parse_input_event(released)
	Input.flush_buffered_events()
	for i in range(60):
		if game.state.welcome_phase=="moss_lesson":
			check(game.world.villagers.moss.visible and not game.world.villagers.mayor.visible and not game.world.villagers.assistant.visible,"Moss stays physically inside after both officials leave")
			check("energy" in game.ui.modal_box.get_child(2).text and game.clock_held(),"Moss explains farm work while the introductory clock stays held")
			game.ui.modal_box.get_child(3).pressed.emit()
			check("Iona" in game.ui.modal_box.get_child(2).text and "deities" in game.ui.modal_box.get_child(2).text,"Moss introduces the tower wizard and regional magic")
		if game.window_open: game.ui.modal_box.get_child(3).pressed.emit()
		if game.state.welcome_phase=="complete": break
		game._process(0.25)
	check(game.state.welcome_phase=="complete" and ["mayor","assistant"].all(func(id): return not game.world.villagers[id].visible),"Moss gives farming advice after the mayor and assistant leave")
	now=game.state.total()
	var outside_positions={}
	for id in game.WELCOME_MEMBERS: outside_positions[id]=game.outdoors.villagers[id].position
	game._process(1)
	check(game.state.total()>now,"time resumes after the entire group has left")
	check(["mayor","assistant"].all(func(id): return game.outdoors.villagers[id].position!=outside_positions[id]),"departing officials resume their outdoor routes")
	game.state.welcome_phase="waiting"
	game.reset_confirmation()
	game.ui.modal_box.get_child(3).pressed.emit()
	check(game.current_room=="ship" and game.opening!=null,"a confirmed new visit can restart even from a locked welcome")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
