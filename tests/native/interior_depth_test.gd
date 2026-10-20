extends SceneTree
const Game=preload("res://game.gd")
const Interior=preload("res://interior.gd")
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
	preload("fixture.gd").explore(game,true)
	game.enter_building("home")
	var room=game.world
	game.state.energy=10
	game.begin_rest(240)
	room.refresh()
	check(room.player.data.get("sleeping",false) and room.player.rotation==0,"player rests lengthwise beneath the bed covers")
	game._process(1)
	check(game.state.energy>10,"sleeping in the player's bed restores energy")
	game.interact()
	room.refresh()
	check(not room.player.data.get("sleeping",false) and not room.blocked(game.state.player_position),"waking returns the player to walkable floor")
	var table: Node2D
	for child in room.get_children():
		if child is Interior.Furniture and child.item.kind=="table": table=child; break
	game.state.player_position=table.position+Vector2(16,-16)
	room.refresh()
	check(table.modulate.a<0.5,"furniture fades when it hides the player")
	game.state.player_position=table.position+Vector2(16,48)
	room.refresh()
	check(table.modulate.a==1,"furniture stays solid when the player is in front")
	game.resting=0
	game.leave_building()
	game.state.minute=60
	game.outdoors.update_villagers(0,true)
	game.enter_building("finch")
	var sleeper=game.world.villagers.finch
	check(sleeper.visible and sleeper.rotation==0 and sleeper.position==game.world.bed_position(),"sleeping villagers lie along their bed instead of across the pillows")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
