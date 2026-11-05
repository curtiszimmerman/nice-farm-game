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
	game.state.minute=800
	game.state.chat_days.iona=1
	for flags in [[false,false],[true,false],[false,true],[true,true]]:
		game.state.magic_learned=flags[0]
		game.state.chat_days.erase("wildgrowth_lore")
		if flags[0]: game.state.chat_days.wildgrowth_lore=1
		game.state.chat_days.erase("weekday_lore")
		if flags[1]: game.state.chat_days.weekday_lore=1
		game.talk("iona")
		var advanced=game.ui.modal_box.find_children("*","Button",true,false).any(func(b):return b.text.contains("Hearthmend") or b.text.contains("Emberthread"))
		check(advanced==(flags[0] and flags[1]),"further spell lessons require both foundational lessons")
	game.state.magic_learned=false
	game.state.chat_days.erase("wildgrowth_lore")
	game.local_magic_lore()
	game.ui.modal_box.find_children("*","Button",true,false).filter(func(b):return b.text=="Teach me Wildgrowth")[0].pressed.emit()
	check(game.state.magic_learned and not game.state.chat_days.has("wildgrowth_lore"),"learning the spell still requires finishing its explanation")
	game.ui.modal_box.find_children("*","Button",true,false).filter(func(b):return b.text=="I've got it.")[0].pressed.emit()
	check(game.state.chat_days.has("wildgrowth_lore"),"the final reply completes the Wildgrowth lesson")
	game.state.day=1
	game.next_rift_omen()
	check(game.ui.modal_box.get_child(2).text.contains("Today is Rift") and game.ui.modal_box.get_child(2).text.contains("equally strong"),"the first Rift describes today's neutral magic with certainty")
	game.state.day=4
	game.next_rift_omen()
	check(game.ui.modal_box.get_child(2).text.contains("in 4 days") and game.ui.modal_box.get_child(2).text.contains("I think"),"a future Rift is explicitly dated and described as a prediction")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
