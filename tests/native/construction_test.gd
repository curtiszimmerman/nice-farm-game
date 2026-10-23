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
	game.interact()
	check(game.window_open and game.ui.modal_box.get_child(1).text.contains("crucible"),"facing the built crucible opens its smelting menu")
	game.close_window()
	var sign=game.outdoors.sites.filter(func(site):return site.id=="sign")[0]
	check(sign.cell.x in range(20,25) and sign.cell.y in range(44,49),"the road sign stands at the crossroads east of the farmhouse")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
