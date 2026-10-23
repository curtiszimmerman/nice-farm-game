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
	for x in [94,95]:
		for y in [74,75]:
			game.state.player_position=game.Grid.center(Vector2i(x,y))
			game.outdoors.facing="up"
			check(game.outdoors.find_nearest().get("door")=="cave","each visible cave-mouth column offers entry before and on its approach")
	game.development_weather()
	for label in ["Sunny","Partly cloudy","Rainy"]:
		check(game.ui.modal_box.get_children().any(func(node):return node is Button and node.text.to_lower()==label.to_lower()),"development weather selection already offers "+label)
	game.close_window()
	game.enter_building("cave")
	check(game.world.spider!=null and game.world.spider.visible and game.world.chambers.back().has_point(game.Grid.world_to_cell(game.world.spider.position)),"the spider already exists in the final cave room")
	game.close_window()
	game.leave_building()
	game.state.minute=1080
	game.state.abandoned_day.keeper=game.state.day
	game.outdoors.update_villagers(0,true)
	game.enter_building("keeper")
	game.leave_building()
	game.state.player_position=game.Grid.center(Vector2i(-20,53))
	var popped=false
	for i in range(600):
		game._process(0.05)
		if game.outdoors.villagers.keeper.visible: popped=true
	check(not popped,"a keeper sent home never loops back outdoors during his scheduled evening walk")
	check(game.ui.log_panel.position.x<100,"the Crew Log occupies the left side")
	check(game.ui.season_word.get_theme_font_size("font_size")>=16 and game.ui.calendar_details.get_theme_font_size("font_size")>=16,"calendar season and weekday labels are legible")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
