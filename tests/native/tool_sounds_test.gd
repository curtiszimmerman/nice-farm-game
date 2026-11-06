extends SceneTree
const Game=preload("res://game.gd")
var failed=false
var game: Node2D
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")

# Stops every effect, stands the captain just below a cell facing it, and acts through the real
# interaction path. Returns the effects that started playing.
func act_on(cell: Vector2i) -> Array:
	for player in game.sound.effects.values(): player.stop()
	game.state.player_position=game.Grid.center(cell+Vector2i.DOWN)
	game.world.facing="up"
	game.world.player.data.erase("chop_started")
	preload("fixture.gd").activate(game)
	return game.sound.effects.keys().filter(func(id):return game.sound.effects[id].playing)

func use(item: String) -> void:
	game.state.set(item,maxi(1,int(game.state.get(item))))
	game.state.assign_active("primary",item)

func run() -> void:
	game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	preload("fixture.gd").tools(game.state)
	var s=game.state
	var w=game.world
	check(game.sound.EFFECTS.all(func(id):return game.sound.effects[id].stream!=null and game.sound.effects[id].stream.get_length()>0.1),"every tool sound loads")
	s.energy=100.0
	var plot=s.plot_cell(0)
	use("hoe")
	check(act_on(plot)==["till"],"the hoe tilling a garden patch sounds like a shovel in dirt")
	var ground=Vector2i(-1,-1)
	var area: Rect2i=game.Grid.BUILD_AREA
	for y in range(area.position.y,area.end.y):
		for x in range(area.position.x,area.end.x):
			var cell=Vector2i(x,y)
			if ground.x<0 and w.can_build_crucible(cell) and not w.blocked(game.Grid.center(cell+Vector2i.DOWN)) and s.plots.all(func(p):return Vector2i(p.x,p.y)!=cell): ground=cell
	var heard=act_on(ground) if ground.x>=0 else []
	check(heard==["till"],"breaking new ground with the hoe makes the same digging sound: %s at %s" % [heard,ground])
	use("seeds")
	act_on(plot)
	use("watering_can")
	s.water=20
	check(act_on(plot)==["water_pour"],"watering a planted patch sounds like water sprinkling on plants")
	s.plots[0].growth=s.crop_minutes(s.plots[0].crop)
	use("sickle")
	check(act_on(plot)==["scythe"],"harvesting with the sickle sounds like cutting through stalks")
	var shore=Vector2i(-1,-1)
	for y in range(w.POND_CELL.y-6,w.POND_CELL.y+7):
		for x in range(w.POND_CELL.x-8,w.POND_CELL.x+9):
			var cell=Vector2i(x,y)
			if shore.x<0 and w.in_water(game.Grid.center(cell)) and not w.in_water(game.Grid.center(cell+Vector2i.DOWN)) and not w.blocked(game.Grid.center(cell+Vector2i.DOWN)) and game.Grid.center(cell).distance_to(game.Grid.center(w.POND_CELL))<190: shore=cell
	use("watering_can")
	s.water=0
	check(shore.x>=0 and act_on(shore)==["water_fill"],"filling the watering can at the pond sounds like water pouring into a jug")
	use("axe")
	var tree=w.trees.filter(func(t):return not w.blocked(game.Grid.center(t.cell+Vector2i.DOWN)))[0]
	check(act_on(tree.cell)==["chop"],"the axe biting into a tree sounds like chopping wood")
	var open=Vector2i(-1,-1)
	for y in range(40,60):
		for x in range(20,40):
			var cell=Vector2i(x,y)
			if open.x<0 and not w.blocked(game.Grid.center(cell)) and not w.blocked(game.Grid.center(cell+Vector2i.DOWN)) and s.plots.all(func(p):return Vector2i(p.x,p.y)!=cell) and not w.trees.any(func(t):return t.cell==cell):
				game.state.player_position=game.Grid.center(cell+Vector2i.DOWN)
				w.facing="up"
				if w.find_nearest().is_empty(): open=cell
	for tool in ["axe","pickaxe","sickle","rusty_sword"]:
		use(tool)
		check(open.x>=0 and act_on(open)==["whoosh"],"swinging the %s at nothing makes a whoosh" % tool)
	for player in game.sound.effects.values(): player.stop()
	s.fishing_pole=1
	use("fishing_pole")
	game.start_fishing("pond")
	check(game.sound.effects.cast.playing,"casting the fishing line makes a cast and splash")
	game.activity=""
	game.state.cave_seed=12345
	game.enter_building("cave")
	game.close_window()
	w=game.world
	var rat=w.rats[0]
	rat.info.health=99
	use("rusty_sword")
	w.swing_cooldown=0
	check(act_on(game.Grid.world_to_cell(rat.position))==["sword_hit"],"the sword striking a rat makes a wet, meaty hit")
	var rock=w.rocks.values().filter(func(r):return not w.blocked(game.Grid.center(r.cell+Vector2i.DOWN)))[0]
	use("pickaxe")
	check(act_on(rock.cell)==["pickaxe_stone"],"the pickaxe striking stone rings out")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
