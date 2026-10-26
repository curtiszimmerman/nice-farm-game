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
	game.enter_building("cave")
	game.close_window()
	var first=game.world
	check(first.floor_cells.size()>1800,"each cave floor has several times the old walkable area")
	var resources={"copper":0,"coal":0,"stones":0}
	for rock in first.rocks.values(): resources[rock.resource]+=1
	var total=float(first.rocks.size())
	check(abs(resources.copper/total-0.1)<0.02 and abs(resources.coal/total-0.05)<0.02,"deposit population is about ten percent copper and five percent coal")
	game.change_cave_level(1)
	check(game.state.cave_level==1 and game.world!=first,"stairs enter a distinct second floor")
	game.change_cave_level(1)
	check(game.state.cave_level==2 and game.world.spider!=null,"third floor holds the chrysalis guardian")
	game.change_cave_level(-1)
	game.change_cave_level(-1)
	check(game.world==first,"ascending returns to the retained first floor")
	game.state.cave_defeated=[0,299]
	var loaded=game.State.new()
	check(loaded.restore(JSON.parse_string(JSON.stringify(game.state.to_dict()))) and loaded.cave_defeated.has(0) and loaded.cave_defeated.has(299),"defeated creatures remain defeated across an actual JSON save round trip")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
