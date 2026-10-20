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
	preload("fixture.gd").explore(game,true)
	game.state.met_mayor=true
	game.state.minute=600
	game.outdoors.update_villagers(0,true)
	game.enter_building("hall")
	game.state.player_position=game.Grid.center(Vector2i(8,11))
	var room=game.world
	var mayor=room.villagers.mayor
	var previous=mayor.position
	game.state.minute=1320
	game._process(0.1)
	check(mayor.visible and mayor.position.distance_to(previous)<12,"a closing-time schedule change starts a walk instead of making the mayor disappear")
	for i in range(400):
		if not mayor.visible: break
		game._process(0.1)
	if mayor.visible: print("Departure stalled at ",mayor.position," toward ",room.Grid.center(room.layout.exit)," route ",room.routes.get("mayor")," held ",game.outdoors.indoor_departures)
	check(not mayor.visible and mayor.position.distance_to(room.Grid.center(room.layout.exit))<1,"the mayor leaves his office through its actual doorway")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
