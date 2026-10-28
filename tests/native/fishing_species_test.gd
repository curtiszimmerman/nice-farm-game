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
	preload("fixture.gd").tools(game.state)
	var w=game.world
	game.select_quick_slot(1)
	var shores=[]
	for cell in w.water_cells:
		if w.Grid.center(cell).distance_to(w.Grid.center(w.POND_CELL))>190: continue
		for direction in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
			var shore=cell+direction
			if not w.blocked(w.Grid.center(shore)) and not w.JETTY_CELLS.has_point(shore): shores.append({"cell":shore,"facing":{Vector2i.UP:"down",Vector2i.DOWN:"up",Vector2i.LEFT:"right",Vector2i.RIGHT:"left"}[direction]})
	var filled=true
	for shore in shores:
		game.state.water=0
		game.state.player_position=w.Grid.center(shore.cell)
		w.facing=shore.facing
		preload("fixture.gd").activate(game)
		if game.state.water!=20: filled=false
	check(shores.size()>10 and filled,"an armed can fills along the reachable pond shoreline")
	check(game.fish_pool("pond").size()==2 and game.fish_pool("ocean").size()==3,"pond and ocean have distinct two- and three-species pools")
	var easy=0
	var hard=0
	for id in game.fish_pool("ocean"):
		if game.ui.Items.FISH[id].hard: hard+=1
		else: easy+=1
	check(easy==2 and hard==1,"the ocean offers two easy fish and one hard fish")
	game.fishing_rng.seed=31
	game.state.fishing_pole=1
	game.state.assign_active("primary","fishing_pole")
	game.start_fishing("pond")
	var first_marker=game.fishing_position()
	game.start_fishing("pond")
	check(not is_equal_approx(first_marker,game.fishing_position()),"new casts vary their opening position instead of guaranteeing an instant catch")
	var variation={}
	for id in ["fish","moon_pike"]:
		game.fishing_species=id
		var previous=0.5
		var total=0.0
		for i in range(250):
			game.activity_time=1.2+i*0.02
			var marker=game.fishing_position()
			check_bounds(marker)
			total+=absf(marker-previous)
			previous=marker
		variation[id]=total
	check(variation.moon_pike>variation.fish*2 and game.ui.Items.FISH.moon_pike.price>game.ui.Items.FISH.fish.price,"the expensive pond fish moves faster and more erratically")
	for id in game.ui.Items.FISH:
		game.fishing_species=id
		game.activity="fishing"
		for i in range(1000):
			game.activity_time=1.2+i*0.01
			if game.fishing_position()>0.4 and game.fishing_position()<0.6: break
		game._finish_fishing()
		check(game.state.get(id)==1,"catching %s produces its own inventory item" % id)
	var before=game.state.money
	game.state.sell()
	check(game.state.money>before+50,"Tavi buys the distinct fish at their species prices")
	game.state.money=100
	game.state.buy_utensil("pan")
	game.state.storm_eel=1
	check(game.state.cook("fish_sticks") and game.state.storm_eel==0,"cooking accepts fish from the ocean")
	check(not w.sites.any(func(site): return site.id=="ocean") and not w.in_water(w.Grid.center(Vector2i(75,85))),"the invented southern ocean and its dock have been removed")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
func check_bounds(value: float) -> void:
	if value<0 or value>1: failed=true; push_error("Fishing marker left its gauge")
