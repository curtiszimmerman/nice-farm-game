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
	game.state.cave_seed=7411
	game.enter_building("cave")
	var cave=game.world
	var rows={}
	for rock in cave.rocks.values():
		if cave.chambers[0].has_point(rock.cell): rows[rock.cell.y]=true
	check(rows.size()>1,"entrance-room deposits scatter across the cave instead of lining up in one row")
	var before={}
	for id in cave.rocks: before[id]={"cell":cave.rocks[id].cell,"ore":cave.rocks[id].ore}
	var first=cave.rocks.keys()[0]
	game.state.pickaxe=1
	game.state.select_inventory("pickaxe")
	game.state.player_position=game.Grid.center(cave.rocks[first].cell)+Vector2(0,32)
	check(cave.mine_rock(first),"a generated deposit can be mined")
	var restored=game.State.new()
	check(restored.restore(game.state.to_dict()),"randomized world state survives a save round trip")
	var rebuilt=game.Cave.new()
	rebuilt.state=restored
	rebuilt.outdoors=game.outdoors
	rebuilt.building={"id":"cave"}
	root.add_child(rebuilt)
	var stable=true
	for id in rebuilt.rocks:
		if rebuilt.rocks[id].cell!=before[id].cell or rebuilt.rocks[id].ore!=before[id].ore: stable=false
	check(stable and not rebuilt.rocks.has(first),"mining and reloading do not reshuffle the remaining deposits")
	rebuilt.queue_free()
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
