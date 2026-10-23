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
	game.state.met_mayor=true
	for site in game.outdoors.sites:
		if site.has("door"):
			var cells=game.outdoors.activation_cells(site)
			check(site.cell in cells and site.cell+Vector2i.UP in cells,"door remains usable before and on its threshold: "+site.id)
			for offset in [Vector2i.DOWN,Vector2i.ZERO]:
				game.state.player_position=game.Grid.center(site.cell+offset)
				game.outdoors.facing="up"
				if game.outdoors.blocked(game.state.player_position): continue
				var target=game.outdoors.find_nearest()
				check(target.get("door")==site.door or target.get("type")=="person","walking onto a doorway retains its real activation: "+site.id)
	var board=game.outdoors.sites.filter(func(site):return site.id=="bulletin_board")[0]
	check(Vector2i(60,50) in game.outdoors.activation_cells(board) and Vector2i(61,50) in game.outdoors.activation_cells(board),"both visible bulletin-board squares offer the postings")
	for x in range(10,13): check(game.outdoors.blocked(game.Grid.center(Vector2i(x,12))),"the ship hull blocks walking through its center")
	for cell in [Vector2i(8,11),Vector2i(14,11),Vector2i(11,10)]: check(game.outdoors.blocked(game.Grid.center(cell)),"the visible outer hull blocks walking too")
	for x in range(10,13):
		for y in [14,15]:
			game.state.player_position=game.Grid.center(Vector2i(x,y))
			game.outdoors.facing="up"
			check(game.outdoors.find_nearest().get("door")=="ship","all lower boarding squares activate the ship")
	for building in game.outdoors.buildings:
		game.enter_building(building.id)
		var exit=game.world.sites.filter(func(site):return site.id=="exit")[0]
		var cells=game.world.activation_cells(exit)
		check(exit.cell in cells and exit.cell+Vector2i.DOWN in cells,"interior exit includes the forward square from its threshold: "+building.id)
		for offset in [Vector2i.UP,Vector2i.ZERO]:
			game.state.player_position=game.Grid.center(exit.cell+offset)
			game.world.facing="down"
			var target=game.world.find_nearest()
			check(target.get("id")=="exit" or target.get("type")=="person","the real interior exit prompt works before and on the threshold: "+building.id)
		game.leave_building()
	game.enter_building("ship")
	for x in range(10,13):
		game.state.player_position=game.Grid.center(Vector2i(x,2))
		game.world.facing="up"
		check(game.world.find_nearest().get("id")=="ship_storage","each locker shelf square opens crew supplies")
	game.interact()
	check(game.window_open and game.storage_name=="ship_storage","the physical ship shelves open their storage")
	game.close_window()
	game.leave_building()
	game.enter_building("cave")
	game.close_window()
	for x in [4,5]:
		for y in [1,2]:
			game.state.player_position=game.Grid.center(Vector2i(x,y))
			game.world.facing="up"
			check(game.world.find_nearest().get("id")=="exit","both cave exit columns work before and on the doorway")
	game.leave_building()
	game.enter_building("veteran")
	check(not game.world.blocked(game.Grid.center(Vector2i(5,7))),"Bram's main passage stays clear of his table")
	game.leave_building()
	game.enter_building("home")
	game.state.cabinet[2]={"id":"pot","count":1}
	game.state.cabinet[3]={"id":"pan","count":1}
	game.state.cabinet[4]={"id":"fish","count":2}
	game.state.cabinet[5]={"id":"turnips","count":1}
	game.state.cabinet[6]={"id":"star_bulbs","count":1}
	game.state.player_position=game.Grid.center(Vector2i(9,7))
	game.world.facing="up"
	game.interact()
	check(game.window_open and game.ui.modal_box.get_children().any(func(node):return node is Button and node.text.contains("Fish stew")),"oven exposes recipes using cabinet cookware")
	check(game.state.cook("fish_stew") and game.state.fish_stew==1 and game.state.fish==0,"a meal cooks entirely from cabinet ingredients and cookware")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
