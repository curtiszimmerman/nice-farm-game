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
	var observatories=game.outdoors.buildings.filter(func(b):return b.id=="observatory")
	check(observatories.size()==1,"an observatory stands in the northern mountain area")
	if not observatories.is_empty():
		var building=observatories[0]
		check(building.cell.y<20 and not game.outdoors._route(game.Grid.SPAWN_CELL,building.cell+Vector2i(3,4)).is_empty(),"the northern observatory is reachable from town")
		game.enter_building("observatory")
		check(game.world.furnishings.any(func(f):return f.kind=="great_telescope" and f.bounds.size==Vector2i(4,3)),"the observatory contains a huge telescope")
		game.talk("astronomer")
		check(game.ui.modal_box.get_child(2).text.contains("stars"),"the astronomer recognizes where the captain came from")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
