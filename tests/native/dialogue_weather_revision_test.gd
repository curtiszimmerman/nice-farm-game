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
	game.opening.finish()
	var body=game.ui.modal_box.get_child(2).text
	for code in [KEY_SPACE,KEY_E]:
		var key=InputEventKey.new()
		key.pressed=true
		key.physical_keycode=code
		game._input(key)
		check(game.ui.modal_box.get_child(2).text==body and not game.world_paused,"button dialogue ignores global advance key "+str(code))
	var click=InputEventMouseButton.new()
	click.pressed=true
	click.button_index=MOUSE_BUTTON_LEFT
	click.position=Vector2(2,2)
	game._input(click)
	check(game.ui.modal_box.get_child(2).text==body,"clicking outside a dialogue button does not advance it")
	game.ui.modal_box.get_child(3).pressed.emit()
	check(game.ui.modal_box.get_child(2).text!=body,"the actual Continue button still advances briefing dialogue")
	preload("fixture.gd").explore(game,true)
	game.ui.update()
	var crew=game.ui.quest_lines().filter(func(q):return q.id=="crew_supplies")[0]
	check(not crew.description.contains("Dain") and not crew.tasks[0].text.contains("Dain"),"the initial crew log does not reveal an unknown local smith")
	game.ui.toggle_log()
	await process_frame
	await process_frame
	var short_height=game.ui.log_panel.size.y
	game.ui.quest_rows.get_child(0).pressed.emit()
	for i in range(5): await process_frame
	check(game.ui.log_panel.size.y>short_height and game.ui.quest_scroll.size.y>214,"expanding a quest grows the Crew Log downward")
	check(game.ui.log_panel.get_global_rect().end.y<game.ui.quick_tray.position.y,"the growing Crew Log stays above the action bar")
	game.state.minute=720
	game.state.weather_override="sunny"
	game.world.refresh()
	var sunny=game.world.night_tint.color
	game.state.weather_override="rainy"
	game.world.refresh()
	var rainy=game.world.night_tint.color
	check(rainy.get_luminance()<sunny.get_luminance() and rainy.b>rainy.r,"rain darkens the world with a blue cast")
	game.sound.thunder_wait=0
	game.sound.thunder.stop()
	game.sound.update_weather("rainy",true,0.1)
	check(not game.sound.thunder.playing,"lightning precedes thunder instead of playing it immediately")
	var weather=game.world.weather_effects
	check(weather.get("lightning_frames")==2,"a lightning strike requests two bright render frames")
	game.sound.update_weather("rainy",true,1.9)
	check(not game.sound.thunder.playing,"the thunder remains silent before its two-second delay")
	game.sound.update_weather("rainy",true,0.2)
	check(game.sound.thunder.playing,"thunder follows the lightning after two seconds")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
