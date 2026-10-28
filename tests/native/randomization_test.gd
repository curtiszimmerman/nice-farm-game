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
		rows[rock.cell.y]=true
	check(rows.size()>1,"entrance-room deposits scatter across the cave instead of lining up in one row")
	var before={}
	for id in cave.rocks: before[id]={"cell":cave.rocks[id].cell,"ore":cave.rocks[id].ore}
	var first=cave.rocks.keys()[0]
	game.state.pickaxe=1
	game.state.select_inventory("pickaxe")
	game.state.player_position=game.Grid.center(cave.rocks[first].cell)+Vector2(0,32)
	var hits=2 if cave.rocks[first].resource in ["copper","coal"] else 1
	var mined=true
	for _hit in range(hits): mined= cave.mine_rock(first) and mined
	var drops=cave.floor_drops.duplicate()
	for drop in drops: mined=cave.collect_drop("drop_"+drop.id) and mined
	check(mined,"a generated deposit breaks, drops materials, and records after pickup")
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
