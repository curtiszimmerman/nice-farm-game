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
	game.enter_building("smithy")
	game.talk("smith")
	check(game.ui.modal_box.get_children().any(func(node):return node is Button and node.text.contains("10 star bulbs")),"Dain offers the blueprint in exchange for ten star bulbs")
	game.close_window()
	game.leave_building()
	game.state.star_bulbs=10
	game.state.learn_crucible()
	game.state.stones=20
	game.state.assign_active("primary","build_crucible")
	var cell=game.Grid.BUILD_AREA.position+Vector2i(2,2)
	game.state.player_position=game.Grid.center(cell+Vector2i.DOWN)
	game.world.facing="up"
	game.interact()
	check(game.state.crucibles.size()==1 and game.outdoors.blocked(game.Grid.center(cell)),"activating a selected blueprint places a solid one-square crucible")
	game.state.assign_active("primary","")
	game.world.elapsed+=0.61
	game.interact()
	check(game.window_open and game.ui.modal_box.get_child(1).text.contains("crucible"),"facing the built crucible opens its smelting menu")
	game.close_window()
	var body=game.outdoors.scenery_layer.get_children().filter(func(node):return node.kind=="crucible")[0]
	await process_frame
	var draws=body.draw_count
	game.state.copper=2
	game.state.start_smelting(0)
	for i in range(4):
		game.outdoors.elapsed+=0.1
		game.outdoors.refresh()
		await process_frame
	check(body.draw_count==draws,"the crucible's moving heat does not redraw its retained stone body")
	var loaded=game.State.new()
	check(loaded.restore(game.state.to_dict()),"a working crucible saves its pending batch")
	var rebuilt=game.World.new()
	rebuilt.state=loaded
	game.add_child(rebuilt)
	check(rebuilt.blocked(game.Grid.center(cell)) and rebuilt.sites.any(func(site):return site.id=="crucible"),"loading reconstructs the crucible's collision and interaction")
	rebuilt.queue_free()
	var sign=game.outdoors.sites.filter(func(site):return site.id=="sign")[0]
	check(sign.cell.x in range(20,25) and sign.cell.y in range(50,53),"the road sign stands at the crossroads east of the farmhouse")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
