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
	var tasks=game.ui.quest_lines()[0].tasks
	check(not tasks.any(func(t):return "Build a stone crucible" in t.text),"crucible construction stays unknown before asking the smith")
	game.talk("smith")
	preload("fixture.gd").greet(game)
	for node in game.ui.modal_box.get_children():
		if node is Button and node.text=="How could I refine copper ore?": node.pressed.emit(); break
	check(game.ui.quest_lines()[0].tasks[0].text=="Build a stone crucible","asking about refining reveals crucible construction without its material cost")
	game.close_window()
	game.state.assign_active("primary","")
	var cell=game.outdoors.SQUARE.position+Vector2i(3,5)
	game.state.player_position=game.Grid.center(cell)
	game.outdoors.facing="up"
	check(game.outdoors.find_nearest().get("id","")=="drink_fountain","the fountain basin can be activated from its southern edge")
	game.state.hoe=1
	game.state.assign_active("primary","hoe")
	check(game.outdoors.find_nearest().get("id","")=="drink_fountain","an idle equipped tool does not prevent fountain drinking")
	game.state.needs.hardcore=true
	game.ui.update_hud()
	check(game.ui.quick_tray.get_theme_stylebox("panel").border_width_top==0,"hardcore opens the tray border beneath the survival extension")
	check(game.ui.tray_top.points[0].x==160,"only the border under the survival extension is removed")
	game.ui.update_hud()
	check(game.ui.music_label.text.begins_with("NP: "),"the HUD identifies the playing music")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
