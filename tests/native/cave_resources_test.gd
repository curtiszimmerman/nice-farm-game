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
	var enough=true
	for seed_value in range(1,61):
		var cave=game.Cave.new()
		cave.state=game.State.new()
		cave.state.cave_seed=seed_value
		cave.outdoors=game.outdoors
		cave.building={"id":"cave"}
		game.add_child(cave)
		if cave.rocks.values().filter(func(rock):return rock.ore).size()<6 or cave.rocks.size()<10: enough=false
		cave.queue_free()
	check(enough,"sixty cave seeds provide enough ore and stone for the first crucible and three bars")
	var s=game.State.new()
	s.pickaxe=1
	s.assign_active("primary","pickaxe")
	for id in s.Items.CATALOG:
		if id in ["copper","stones"]: continue
		if s.carried_slots()<11: s.set(id,1)
	var energy=s.energy
	check(not s.mine("copper") and s.copper==0 and s.stones==0 and s.energy==energy,"ore mining reserves room for both ore and its stone before spending energy")
	s.bread=0
	check(s.mine("copper") and s.copper==1 and s.stones==1,"a copper-bearing rock yields ore and stone together")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
