extends SceneTree
const Game=preload("res://game.gd")
var game: Node2D
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func buttons() -> Array: return game.ui.modal_box.get_children().filter(func(node):return node is Button)
func choose(fragment: String) -> void:
	var matches=buttons().filter(func(button):return fragment in button.text)
	check(not matches.is_empty(),"dialogue offers: "+fragment)
	if not matches.is_empty(): matches[0].pressed.emit()
func body() -> String: return game.ui.modal_box.get_child(2).text
func _initialize() -> void: call_deferred("run")
func run() -> void:
	game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	game.state.met_mayor=true
	game.state.watering_can=1
	game.state.assign_active("primary","watering_can")
	game.talk("moss")
	check(not buttons().any(func(button):return button.text.begins_with("Give ")),"Moss never offers to take the watering can")
	check("copper" in buttons()[0].text,"Moss's first post-welcome topic is the captain asking for copper")
	choose("copper")
	check("southeast" in body() and "protect" in body() and "Bram" in body(),"Moss warns about the mines and directs the captain to Bram")
	game.close_window()
	game.bulletin_board()
	check("firewood" in buttons()[0].text and buttons().size()==4,"the four-position board puts Oren ahead of the ladder")
	choose("firewood")
	check(game.state.firewood_requested,"reading Oren's notice activates his firewood mission")
	game.close_window()
	game.state.firewood_requested=true
	game.state.bread=1
	game.state.assign_active("primary","bread")
	game.talk("keeper")
	check(buttons().size()==1 and "need of some firewood" in buttons()[0].text,"Oren starts an active unfinished mission with exactly the firewood question")
	choose("firewood")
	choose("don't have an axe")
	check("Moss" in body() and "fishing pole" in body() and "food in your belly" in body(),"Oren supplies directions and explains the fishing reward")
	game.close_window()
	game.talk("woodcutter")
	choose("ten logs in one week")
	check(game.state.axe==1 and game.state.requests.axe_due>game.state.total(),"accepting Rowan's terms starts the axe agreement")
	game.close_window()
	game.talk("veteran")
	choose("Moss thought")
	choose("waiting for them to grow")
	check("Iona" in body() and "night owl" in body() and "astronomer" in body(),"Bram hints at growth magic, Iona's hours and Saeren")
	game.close_window()
	game.state.turnips=3
	game.talk("veteran")
	choose("Moss thought")
	choose("Trade three")
	check(game.state.rusty_sword==1 and game.state.turnips==0,"Bram trades the sword through actual dialogue")
	game.close_window()
	game.talk("veteran")
	check(buttons().any(func(button):return "Veyr" in button.text),"Bram retains his Veyr conversation after the trade")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
