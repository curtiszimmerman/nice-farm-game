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
	check(game.Art.available_packs().size()>=2,"built-in packs remain discoverable without a custom pack folder")
	for pack in ["option2","option3","option2","option3"]:
		game.change_art_pack("res://art/"+pack+"/pack.json")
		game.state.player_position=game.Grid.center(Vector2i(90,70))
		game.world.refresh()
		await process_frame
		game.state.player_position=game.Grid.center(Vector2i(17,45))
		game.world.facing="up"
		game.world.refresh()
		await process_frame
		check(game.world.find_nearest().get("id")=="chest","farmhouse chest remains interactive after pack changes and a trip away")
	check(game.outdoors.scenery_layer.get_children().any(func(node):return node.kind=="chest"),"chest has its own retained depth-sorted scene object")
	game.state.met_mayor=true
	game.enter_building("home")
	var home=game.world
	game.state.house_tasks.guest_bed=true
	game.state.player_position=game.Grid.center(Vector2i(5,3))
	home.facing="up"
	check(home.find_nearest().get("id")=="bed","uncovered guest bed offers sleep rather than a completed cover task")
	game.state.learned_spells.append("hearthmend")
	game.state.assign_slot(3,"hearthmend")
	game.open_storage("cabinet")
	check(game.ui.inventory_slots.size()==16 and game.ui.inventory_slots[0].get_parent().columns==8,"storage shows the same two inventory rows as the quick bar")
	var spell=game.ui.inventory_slots.filter(func(slot):return slot.get_meta("item_id","")=="hearthmend")
	if not spell.is_empty(): spell[0].pressed.emit()
	check(game.chest_selected=="" and game.state.active_item()=="hearthmend","spell shortcuts in the carried grid remain actions rather than stored objects")
	game.state.cabinet[1]={"id":"bread","count":2}
	check(game.perform_drop({"id":"bread","storage":"cabinet","index":1},{"inventory_index":3},1) and game.state.inventory_order[3]=="bread" and game.state.cabinet[1].count==1,"a stored item can replace a spell shortcut without trying to store the spell")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
