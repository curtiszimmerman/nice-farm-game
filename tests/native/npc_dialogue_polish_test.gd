extends SceneTree
const Game=preload("res://game.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func buttons(game: Node2D) -> Array:
	return game.ui.modal_box.get_children().filter(func(child):return child is Button)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	game.state.silver_bars=2
	game.talk("priest")
	check(buttons(game)[0].text=="Still learning, but it's going well, thanks!","Aven's first question has a conversational answer")
	preload("fixture.gd").greet(game)
	check(not buttons(game).any(func(b):return b.text.contains("blueprint")),"Aven does not offer plans before being asked about the hives")
	buttons(game).filter(func(b):return b.text.contains("beehives"))[0].pressed.emit()
	check(game.ui.modal_box.get_child(2).text.contains("before I became a priest"),"Aven explains his lifelong beekeeping")
	buttons(game).filter(func(b):return b.text.contains("blueprint"))[0].pressed.emit()
	check(game.state.beehive_known and game.state.silver_bars==0,"the beekeeping conversation unlocks the blueprint exchange")
	game.close_window()
	game.talk("farmer_son")
	check(buttons(game)[0].text=="The plants I know are much different than the ones growing here.","Pip gets a reply about unfamiliar plants")
	preload("fixture.gd").greet(game)
	check(not buttons(game).any(func(b):return b.text=="Goodbye."),"Pip's travel encouragement replaces the generic farewell")
	buttons(game).filter(func(b):return b.text.begins_with("Maybe one day"))[0].pressed.emit()
	check(not game.window_open,"encouraging Pip to travel ends the conversation")
	game.state.glass_jars=1
	var friendship=int(game.state.friendships.get("farmer_son",0))
	check(game.state.give_gift("farmer_son","glass_jars") and int(game.state.friendships.get("farmer_son",0))==friendship+5,"Pip loves a glass jar gift")
	game.talk("baker")
	check(buttons(game)[0].text=="I'm doing a lot better knowing where to get fresh bread!","Corin's greeting gets the requested reply")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
