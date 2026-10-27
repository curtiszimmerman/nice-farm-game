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
	var w=game.outdoors
	var houses=w.buildings.filter(func(b): return b.kind=="lighthouse")
	check(houses.size()==1 and houses[0].cell.x<0,"a lighthouse stands beyond the old western boundary")
	var trails_clear=true
	for path in w.Coast.PATHS:
		for i in range(path.size()-1):
			for y in range(mini(path[i].y,path[i+1].y),maxi(path[i].y,path[i+1].y)+1):
				for x in range(mini(path[i].x,path[i+1].x),maxi(path[i].x,path[i+1].x)+1):
					if w.blocked(w.Grid.center(Vector2i(x,y))): trails_clear=false
	check(trails_clear,"both faint trails stay clear of fences water and buildings")
	check(w.has_method("coastal_fishing"),"shore fishing is available outside the pond dock")
	if w.has_method("coastal_fishing"):
		var tip=w.call("coastal_fishing",w.Grid.center(Vector2i(-26,53)))
		check(tip.get("id")=="ocean_tip" and not w.blocked(w.Grid.center(Vector2i(-20,52))),"the stone jetty is walkable and its outer end offers deep-water fishing")
	game.state.minute=1260
	check("lantern_ray" in game.fish_pool("ocean_tip") and "lantern_ray" not in game.fish_pool("ocean"),"the rare lantern ray is exclusive to the jetty's sea end at night")
	var catches={}
	game.state.fishing_pole=1
	game.state.assign_active("primary","fishing_pole")
	game.fishing_rng.seed=31
	for i in range(500):
		game.state.energy=100
		game.start_fishing("ocean_tip")
		catches[game.fishing_species]=catches.get(game.fishing_species,0)+1
	check(catches.get("lantern_ray",0)>0 and catches.lantern_ray<catches.sea_sprat and catches.lantern_ray<catches.blue_mackerel,"lantern rays are rarer than either common coastal fish")
	var shore_cells={}
	var shore_fishable=true
	for water in w.water_cells:
		if water.x>=0 or water.y<40 or water.y>70: continue
		for direction in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
			var cell=water+direction
			if w.blocked(w.Grid.center(cell)) or w.Coast.JETTY.has_point(cell) or w.Coast.PLATFORM.has_point(cell): continue
			shore_cells[cell]=true
			if w.call("coastal_fishing",w.Grid.center(cell)).get("id")!="ocean": shore_fishable=false
	check(shore_cells.size()>20 and shore_fishable,"every reachable stretch of the western shoreline supports ocean fishing")
	if houses.size()==1:
		game.enter_building("keeper")
		check(game.current_room=="keeper" and not game.world.blocked(game.state.player_position),"the keeper has an enterable lighthouse home")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
