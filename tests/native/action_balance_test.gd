extends SceneTree
const State=preload("res://state.gd")
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
	var world=game.outdoors
	s.met_mayor=true
	s.weather_override="sunny"
	check(s.plots.is_empty(),"new farms start as grass without predefined plots")
	s.hoe=1
	s.watering_can=1
	s.seeds=20
	s.assign_active("primary","watering_can")
	s.refill_water()
	for i in range(20):
		s.assign_active("primary","hoe")
		var cell=Vector2i(8+i%10,54+int(i/10))
		check(not world.blocked(game.Grid.center(cell)) and s.prepare_plot(cell),"clear southern ground can be tilled")
		s.assign_active("primary","seeds")
		s.farm(i)
		s.assign_active("primary","watering_can")
		s.farm(i)
	var berries=world.forage_nodes.berries.keys()
	check(berries.size()>=5,"the world supplies five separate spring berry bushes")
	for cell in berries.slice(0,5): check(world.harvest_forage("berries",cell),"a real berry harvest spends its energy")
	s.axe=1
	s.assign_active("primary","axe")
	var trees=world.trees.filter(func(tree):return not world.blocked(game.Grid.center(tree.cell+Vector2i.DOWN))).slice(0,6)
	check(trees.size()==6,"six accessible trees are available for the day's work")
	for tree in trees:
		world.facing="up"
		s.player_position=game.Grid.center(tree.cell+Vector2i.DOWN)
		for i in range(3):
			world.elapsed+=0.61
			check(world.chop_tree(tree.cell),"a timed axe swing spends its energy")
		preload("fixture.gd").activate(game)
	check(s.wood==18,"six fallen trees leave eighteen collected logs")
	s.fishing_pole=1
	s.assign_active("primary","fishing_pole")
	for i in range(5):
		game.start_fishing("pond")
		check(game.activity=="fishing","a real fishing cast starts and spends energy")
		game.activity=""
	check(is_equal_approx(s.energy,21.6),"the day-one activity budget leaves 21.6 energy after reduced axe costs")
	s=State.new()
	s.money=999
	check(not s.buy_sword(),"Dain requires the full thousand crowns")
	s.money=1000
	check(s.buy_sword() and s.money==0,"Dain sells the sword for one thousand crowns")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
