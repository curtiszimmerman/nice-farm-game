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
	var w=game.outdoors
	var weather=preload("res://weather.gd").new()
	weather.world=w
	game.state.player_position=Vector2(1100,1700)
	var before=weather.rain_positions(2)
	game.state.player_position.x+=12
	check(weather.rain_positions(2)==before,"raindrops retain their world positions when the player moves")
	check(weather.rain_positions(3)!=before,"raindrops move independently with time")
	weather.free()
	game.state.fishing_pole=1
	game.state.assign_active("primary","fishing_pole")
	var north=Vector2i(w.Coast.shoreline(20,game.state.world_seed),20)
	var south=Vector2i(w.Coast.shoreline(65,game.state.world_seed),65)
	check(w.blocked(w.Grid.center(north)) and w.cliff_cells.has(north) and w.Coast.fishing_site(w,w.Grid.center(north+Vector2i.LEFT)).is_empty(),"northern coastal cliffs have terrain artwork, are impassable and cannot be shore-fished")
	check(not w.blocked(w.Grid.center(south)) and w.Coast.is_beach(south,game.state.world_seed) and not w.Coast.fishing_site(w,w.Grid.center(south+Vector2i.LEFT)).is_empty(),"the southern sandy beach permits shore fishing")
	check(w.Coast.beach_width(65,game.state.world_seed) in [2,3],"the beach is two or three squares wide")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
