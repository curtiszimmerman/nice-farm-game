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
	s.energy=100
	var cave=game.Cave.new()
	cave.state=s
	cave.outdoors=game.outdoors
	cave.building={"id":"cave"}
	game.add_child(cave)
	var copper=cave.rocks.values().filter(func(rock):return rock.resource=="copper")[0]
	var stand=copper.cell+Vector2i.DOWN
	s.player_position=game.Grid.center(stand)
	cave.facing="up"
	var energy=s.energy
	check(cave.mine_rock(copper.id) and copper.hits==1 and s.energy==energy-4 and s.copper==0,"copper ore takes two four-energy hits before dropping")
	check(cave.mine_rock(copper.id) and cave.floor_drops.size()==2 and s.copper==0 and s.stones==0,"ore and stone remain as separate floor pickups after mining")
	var drops=cave.floor_drops.duplicate()
	for drop in drops: check(cave.collect_drop("drop_"+drop.id),"mined "+drop.item+" can be collected from the floor")
	check(s.copper==1 and s.stones==1 and s.cave_broken.has(copper.id),"collecting both drops adds them to inventory and records the deposit")
	var stone=cave.rocks.values().filter(func(rock):return rock.resource=="stones")[0]
	s.player_position=game.Grid.center(stone.cell+Vector2i.DOWN)
	cave.facing="up"
	check(cave.mine_rock(stone.id) and cave.floor_drops.any(func(drop):return drop.item=="stones"),"ordinary stone breaks in one hit and drops stone")
	var coal=cave.rocks.values().filter(func(rock):return rock.resource=="coal")[0]
	s.player_position=game.Grid.center(coal.cell+Vector2i.DOWN)
	check(cave.mine_rock(coal.id) and coal.hits==1 and cave.mine_rock(coal.id),"coal takes two hits to mine")
	cave.queue_free()
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
