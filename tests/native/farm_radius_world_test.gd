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
	var s=game.state
	s.hoe=1
	s.assign_active("primary","hoe")
	var selected=Vector2i(-100,-100)
	for y in range(53,65):
		for x in range(1,25):
			var cell=Vector2i(x,y)
			if not game.world.can_build_crucible(cell) or game.world.blocked(game.Grid.center(cell+Vector2i.DOWN)): continue
			s.player_position=game.Grid.center(cell+Vector2i.DOWN)
			game.world.facing="up"
			if game.world.target_plot()<0 and game.world.find_nearest().is_empty(): selected=cell; break
		if selected.x!= -100: break
	check(selected.x!= -100,"the expanded farmhouse area contains reachable new farmland")
	game.interact()
	check(s.plots.size()==1 and game.world.target_plot()==0 and game.world.farm_cells.has(selected),"activating a carried hoe creates the first real targetable plot")
	s.seeds=1
	s.assign_active("primary","seeds")
	game.world.elapsed+=0.61
	game.interact()
	check(s.plots.back().planted>=0 and s.seeds==0,"the new plot supports normal planting and inventory consumption")
	s.watering_can=1
	s.water=2
	s.assign_active("primary","watering_can")
	game.world.elapsed+=0.61
	game.interact()
	check(s.plots.back().watered and s.water==1,"the new plot supports normal watering")
	game.world.refresh()
	await process_frame
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
