extends SceneTree
const Game=preload("res://game.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func button(game: Node2D,needle: String) -> Button:
	for child in game.ui.modal_box.get_children():
		if child is Button and child.text.contains(needle): return child
	return null
func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	game.state.briefing_complete=true
	var greetings=preload("res://npc_greetings.gd").LINES
	check(game.outdoors.people.all(func(person):return greetings.has(person.id)),"every town NPC has a distinct first-meeting line")
	game.talk("smith")
	check(game.ui.modal_box.get_child(2).text.contains("Dain") and game.ui.modal_box.get_child(1).get_child_count()>0,"the first meeting has a tailored greeting and a prominent portrait")
	button(game,"Go on.").pressed.emit()
	check(button(game,"Tell me about your work")!=null,"the greeting leads to the ordinary conversation root")
	button(game,"Tell me about your work").pressed.emit()
	check(game.ui.modal_box.get_children().filter(func(child):return child is Button).size()>=2,"an informational reply remains in dialogue")
	game.ui.modal_box.get_children().filter(func(child):return child is Button)[0].pressed.emit()
	check(button(game,"Tell me about your work")!=null,"an informational reply returns to the root")
	game.ui.modal_box.get_children().filter(func(child):return child is Button).back().pressed.emit()
	check(not game.window_open,"the explicit last option disengages")
	game.talk("vale")
	check(button(game,"I'll look for someone who works metal.")==null and button(game,"Hand over three copper bars.")==null,"Vale does not offer a dead-end copper reply")
	button(game,"What's the status on repairs?").pressed.emit()
	check(game.ui.modal_box.get_child(2).text.contains("cloak is steady"),"Vale explains the current repairs in dialogue")
	game.ui.modal_box.get_children().filter(func(child):return child is Button)[0].pressed.emit()
	check(button(game,"What's the status on repairs?")!=null,"Vale's repair update returns to the conversation root")
	button(game,"Goodbye.").pressed.emit()
	game.state.copper_bars=3
	game.talk("vale")
	check(button(game,"Hand over three copper bars.")!=null,"Vale offers the handover when the bars are ready")
	game.close_window()
	game.state.minute=800
	game.outdoors.update_villagers(0,true)
	game.talk("iona")
	button(game,"Go on.").pressed.emit()
	var iona_options=game.ui.modal_box.get_children().filter(func(child):return child is Button)
	check(iona_options[0].text.contains("seven days") and iona_options[1].text.contains("local lore"),"Iona leads with the seven days and local lore before spell lessons")
	check(button(game,"next Rift")==null,"Iona's forecast is hidden before a weekday lesson")
	button(game,"Tell me about the seven days").pressed.emit()
	var days=["RIFT","BOUGH","EMBER","GALE","TIDE","GLEAM","VEIL"]
	var openings=["A day of chaos","A day of growth","A day of fire","A day of air","A day of water","A day of light","A day of darkness"]
	for i in range(days.size()):
		check(game.ui.modal_box.get_child(0).text==days[i] or game.ui.modal_box.get_child(0).text=="Iona","the first day lesson follows weekday order")
		check(game.ui.modal_box.get_child(2).text.begins_with(openings[i]),"each day lesson names its nature first")
		game.ui.modal_box.get_children().filter(func(child):return child is Button)[0].pressed.emit()
	check(game.state.chat_days.has("weekday_lore"),"finishing the seven-day chain records the lesson")
	check(button(game,"next Rift")!=null,"Iona offers the next Rift forecast after the full lesson")
	var learned_options=game.ui.modal_box.get_children().filter(func(child):return child is Button)
	check(learned_options[0].text.contains("seven days") and learned_options[1].text.contains("next Rift") and learned_options[2].text.contains("local lore"),"Iona orders lore, forecast, then local magic")
	button(game,"Tell me about the seven days").pressed.emit()
	check(button(game,"Ember")!=null,"a completed lesson unlocks the individual-day menu")
	button(game,"Ember").pressed.emit()
	check(game.ui.modal_box.get_child(2).text.begins_with("A day of fire"),"individual-day lore retains the day introduction")
	game.close_window()
	game.state.meet_person("baker")
	game.talk("baker")
	check(button(game,"Go on.")!=null,"hearing about someone through town does not consume their first spoken greeting")
	game.close_window()
	game.state.needs.hardcore=true
	game.ui.update_hud()
	check(game.ui.needs_panel.position.x==0 and game.ui.quick_tray.size.y>70.4 and game.ui.health_label.get_theme_font_size("font_size")>=13,"survival bars attach above legible vitals inside one HUD")
	game.show_title_backdrop()
	check(game.title_backdrop_active and game.outdoors.visible and game.camera.position.x>game.Grid.center(Vector2i(90,0)).x,"the title backdrop views the eastern farm")
	game.restore_title_backdrop()
	check(not game.title_backdrop_active and game.world.visible,"starting play restores the actual game world")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
