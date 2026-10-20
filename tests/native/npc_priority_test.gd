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
	game.state.minute=1320
	game.outdoors.update_villagers(0,true)
	var iona=game.outdoors.villagers.iona
	iona.visible=true
	iona.data.sleeping=false
	iona.position=game.outdoors.site_position("door_iona")
	game.state.player_position=iona.position+Vector2(0,25)
	check(game.outdoors.find_nearest().get("id")=="iona","Iona takes activation priority over her tower door")
	game.state.magic_learned=true
	game.state.assign_active("primary","wildgrowth")
	game.activate_channel("primary")
	check(game.window_open and game.ui.modal_box.get_child(1).text=="Iona","a selected primary spell still permits talking to Iona at her door")
	game.close_window()
	var door=game.outdoors.site_position("door_iona")
	iona.position=door+Vector2(35,0)
	check(game.outdoors.find_nearest().get("door")=="iona","moving Iona clear of the doorway permits entering even while she is nearby")
	iona.position=door
	check(game.has_method("try_player_step"),"player movement resolves NPC bodies and pushing")
	if game.has_method("try_player_step"):
		var start=iona.position
		game.call("try_player_step",Vector2(0,-6))
		check(iona.position.distance_to(start)>0 and game.state.player_position.distance_to(iona.position)>=18,"walking against Iona pushes her without overlapping")
		var stop=iona.position
		game.outdoors.conversation_holds.iona=true
		game.call("try_player_step",Vector2(0,-6))
		check(iona.position==stop,"an engaged conversation protects its speaker from pushing")
		game.outdoors.conversation_holds.erase("iona")
		iona.position=game.Grid.center(Vector2i(59,46))
		game.state.player_position=game.Grid.center(Vector2i(61,46))
		game.outdoors.story_destinations.iona={"cell":Vector2i(63,46),"room":"","sleeping":false}
		game.outdoors.routes.erase("iona")
		var clearance=true
		for i in range(240):
			game.outdoors.update_villagers(0.05)
			if iona.position.distance_to(game.state.player_position)<21.9: clearance=false
		check(clearance and iona.position.distance_to(game.Grid.center(Vector2i(63,46)))<1,"a displaced villager routes around the player and returns to the intended stop")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
