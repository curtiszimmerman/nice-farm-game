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
	preload("fixture.gd").explore(game)
	var w=game.world
	check(w.Grid.MAP_SIZE.x*w.Grid.MAP_SIZE.y>=60*45*4,"map provides four times the previous area")
	var tower={}
	var club={}
	var home={}
	for b in w.buildings:
		if b.kind=="tower": tower=b
		if b.kind=="radio": club=b
		if b.kind=="home": home=b
	check(tower.tiles.x==tower.tiles.y,"round tower uses a square ground footprint")
	check(not w.blocked(w.Grid.center(tower.cell+Vector2i(-1,1))) and not w.blocked(w.Grid.center(tower.cell+Vector2i(tower.tiles.x,1))),"tower can be walked past on both sides of its base")
	check(tower.cell.y<club.cell.y-12 and home.cell.x<w.SQUARE.position.x-30 and w.OUTCROP_CELLS.position.x>w.SQUARE.end.x+20,"landmarks spread north west and southeast of town")
	var open=true
	for y in range(20,82):
		if w.in_water(w.Grid.center(Vector2i(w.Grid.MAP_SIZE.x-5,y))): open=false
	check(open,"the eastern map has no ocean or coastal barrier")
	var radio=w.site_position("radio")
	check(radio.y>=club.y+club.h+32 and radio.distance_to(Vector2(club.x+club.w/2,club.y+club.h))<80,"radio table clears the club foundation and stands immediately outside")
	var fishable=true
	game.state.fishing_pole=1
	game.state.assign_active("primary","fishing_pole")
	for x in range(w.JETTY_CELLS.position.x,w.JETTY_CELLS.end.x):
		game.state.player_position=w.Grid.center(Vector2i(x,w.JETTY_CELLS.position.y))
		if w.find_nearest().get("id","")!="pond": fishable=false
		game.interact()
		if game.activity!="fishing": fishable=false
		game.activity=""
	check(fishable,"the entire dock offers fishing")
	var gap=true
	for b in w.buildings:
		if w.Grid.rect(w.OUTCROP_CELLS.position,w.OUTCROP_CELLS.size).grow(96).intersects(w.Grid.rect(b.cell,b.tiles)): gap=false
	check(gap,"copper cave has at least three tiles of separation from houses")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
