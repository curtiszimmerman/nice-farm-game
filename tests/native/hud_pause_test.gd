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
	var intro=game.opening
	var pause_key=InputEventKey.new()
	pause_key.pressed=true
	pause_key.physical_keycode=KEY_SPACE
	game._input(pause_key)
	var intro_time=intro.elapsed
	await process_frame
	await process_frame
	check(not intro.is_processing() and intro.elapsed==intro_time and game.ui.pause_shield.visible and game.ui.pause_badge.is_visible_in_tree(),"space pauses the opening with a visible indicator and blocks menu clicks")
	game._input(pause_key)
	preload("fixture.gd").explore(game,true)
	game.ui.update()
	check(not game.ui.log_expanded and not game.ui.objective.visible,"crew log starts collapsed")
	check(game.ui.message_panel.size.x<500,"status banner uses a compact width")
	check(game.ui.hint.get_parent() is PanelContainer,"interaction prompt has a background")
	check(game.ui.quest_unread,"new quests flag the crew log")
	game.ui._process(0.5)
	check(game.ui.log_toggle.modulate!=Color.WHITE,"unread quests give the log a gold pulse")
	game.ui.toggle_log()
	game.ui._process(0)
	check(game.ui.log_toggle.modulate==Color.WHITE,"acknowledging quests stops the gold pulse")
	check(not game.ui.quest_unread,"opening the log acknowledges its quests")
	game.ui.update()
	check(not game.ui.quest_unread,"unchanged quests do not repeatedly flag the log")
	game.state.met_mayor=true
	game.ui.update()
	check(game.ui.quest_unread,"a newly assigned farming quest flags the log again")
	game.ui.quick_tray.position=game.get_viewport().get_canvas_transform()*game.state.player_position-Vector2(100,100)
	game.ui.quick_tray.size=Vector2(1280,720)
	game.ui._process(1)
	check(game.ui.quick_tray.modulate.a<0.3,"quick slots fade when they cover the avatar")
	var w=game.outdoors
	game.state.watering_can=1
	game.state.assign_slot(0,"watering_can")
	game.select_quick_slot(0)
	var dock_clear=true
	for x in range(w.JETTY_CELLS.position.x,w.JETTY_CELLS.end.x):
		game.state.player_position=w.Grid.center(Vector2i(x,w.JETTY_CELLS.position.y))
		game.state.water=0
		game.interact()
		if game.activity!="fishing" or game.state.water!=0 or w.at_pond_edge(game.state.player_position): dock_clear=false
		game.activity=""
	check(dock_clear,"every dock cell fishes while an armed can cannot steal the action")
	check(w.fence_mask(Vector2i(9,46))==3 and not w.blocked(w.Grid.center(Vector2i(14,46))),"fence rails connect across an open walkable gate")
	var minute=game.state.minute
	var elapsed=game.elapsed
	var key=InputEventKey.new()
	key.pressed=true
	key.physical_keycode=KEY_SPACE
	game._unhandled_key_input(key)
	game._process(5)
	check(game.state.minute==minute and game.elapsed==elapsed,"space freezes world time and animation time")
	game._unhandled_key_input(key)
	game._process(1)
	check(game.state.minute>minute,"space resumes the shared clock")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
