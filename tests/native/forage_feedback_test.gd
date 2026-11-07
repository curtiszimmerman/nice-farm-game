extends SceneTree
const Game=preload("res://game.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")

func face_bush(game: Node2D,cell: Vector2i) -> void:
	# Eating from the satchel leaves the inventory open, as it does in play.
	if game.window_open: game.close_window()
	game.state.player_position=game.Grid.center(cell+Vector2i.DOWN)
	game.outdoors.facing="up"
	game.elapsed=maxf(game.elapsed,game.outdoors.elapsed)+2.0
	game.outdoors.elapsed=game.elapsed

func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	var world=game.outdoors
	game.state.day=40
	game.state.needs.hardcore=true
	game.state.berries=2
	var bushes=world.forage_nodes.berries.keys()
	# Out of energy, with berries already carried and empty slots, the captain is told the real reason.
	game.state.energy=0
	face_bush(game,bushes[0])
	game.interact()
	check("satchel" not in game.ui.message.text.to_lower() and "exhausted" in game.ui.message.text.to_lower(),"gathering with no energy says you're exhausted, not that the satchel is full (%s)" % game.ui.message.text)
	check(game.state.berries==2,"nothing is gathered without the energy to do it")
	# Thirst stops food from restoring energy, and eating says so.
	game.state.needs.without_water=game.state.needs.WATER_MINUTES+10
	game.state.fish_stew=1
	game.state.health=50
	game.use_inventory_item("fish_stew")
	check(game.state.energy==0 and "thirst" in game.ui.message.text.to_lower(),"eating while parched explains that thirst is keeping energy from coming back (%s)" % game.ui.message.text)
	face_bush(game,bushes[1])
	game.interact()
	check("thirst" in game.ui.message.text.to_lower(),"trying to gather while parched points at thirst (%s)" % game.ui.message.text)
	game.drink_freshwater()
	game.state.fish_stew=1
	game.use_inventory_item("fish_stew")
	face_bush(game,bushes[2])
	game.interact()
	check(game.state.berries==3,"once watered and fed, the captain gathers berries again")
	# A truly full satchel still gets the satchel message.
	game.state.berries=0
	game.state.energy=100
	var filler=["turnips","star_bulbs","fish","copper","stones","coal","wood","flour","sugar","butter","bread","tomatoes","cucumbers","gladain","green_onions","apples","rations","pot","pan","glass_jars"]
	for id in filler:
		if game.state.occupied_inventory_slots()>=game.state.INVENTORY_SLOTS: break
		if int(game.state.get(id))==0: game.state.set(id,1)
	if game.state.occupied_inventory_slots()<game.state.INVENTORY_SLOTS: push_error("FAIL: test could not fill the satchel")
	face_bush(game,bushes[3])
	game.interact()
	check("satchel" in game.ui.message.text.to_lower(),"a full satchel is still reported as full (%s)" % game.ui.message.text)
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
