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
	game.state.chest_transfer(3)
	game.state.assign_slot(0,"seeds")
	game.state.assign_slot(3,"seeds")
	check(game.state.quick_slots[0]=="" and game.state.quick_slots[3]=="seeds","reassigning a shortcut moves the reference without duplicating seeds")
	check(preload("res://skills.gd").learned(game.state).is_empty(),"untrained players have no learned spell or skill entries")
	game.state.minute=617
	game.ui.update()
	check(game.ui.clock.text=="10:10","clock display advances in ten-minute steps")
	check(game.ui.calendar_ring.has_method("pendulum_angle"),"the calendar includes a clock-driven pendulum")
	check(game.ui.quick_tray.scale.is_equal_approx(Vector2(1.2,1.2)),"HUD tray is enlarged by twenty percent")
	game.state.magic_learned=true
	var quests=game.ui.quest_lines()
	check(quests.back().id=="meet_wizard" and quests.back().complete,"completed quest lines sort below unfinished quests")
	game.enter_building("home")
	var room=game.world
	var lamps=room.furnishings.filter(func(f):return f.kind=="floor_lamp")
	check(lamps.size()==2,"farmhouse has two standing lamps")
	if lamps.size()==2:
		check(lamps.any(func(f):return room.floor_cells[f.bounds.position]=="bedroom") and lamps.any(func(f):return room.floor_cells[f.bounds.position]=="living"),"broken lamps occupy the bedroom and living room")
	check(room.floor_cells.values().has("kitchen") and room.layout.doors.any(func(d):return "kitchen" in d),"farmhouse kitchen is a separate room with a doorway")
	var kitchen=room.furnishings.filter(func(f):return f.kind=="kitchen")[0].bounds
	var cabinet=room.furnishings.filter(func(f):return f.kind=="cabinet")[0].bounds
	check(not kitchen.grow(1).intersects(cabinet),"a clear tile separates the cabinet from the oven and counter")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
