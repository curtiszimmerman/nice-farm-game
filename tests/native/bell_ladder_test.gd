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
	check(game.outdoors.buildings.any(func(b):return b.id=="mill_shed"),"the Bells have a shed beside their farmhouse")
	if game.outdoors.buildings.any(func(b):return b.id=="mill_shed"):
		game.enter_building("mill_shed")
		check(game.world.layout.size.x<=8 and game.world.furnishings.any(func(f):return f.kind=="shed_ladder"),"a compact tool-filled shed holds the missing ladder")
		game.state.player_position=game.Grid.center(Vector2i(5,2))
		game.world.facing="right"
		check(game.world.find_nearest().get("id")=="ladder","the visible ladder is interactable from its side")
		game.interact()
		check(game.state.ladder==1 and game.state.ladder_taken and not game.world.solid_cells.has(Vector2i(6,2)),"collecting the ladder clears its physical footprint")
		var restored=game.State.new()
		check(restored.restore(game.state.to_dict()) and restored.ladder==1 and restored.ladder_taken,"the collected ladder and shed location survive saving")
		game.return_bell_ladder()
		check(game.state.ladder==0 and game.state.ladder_returned,"returning the ladder completes Mrs Bell's quest")
		check(restored.restore(game.state.to_dict()) and restored.ladder_returned and restored.ladder==0,"the completed ladder quest survives saving")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
