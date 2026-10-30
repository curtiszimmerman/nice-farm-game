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
	check(s.stock("seeds")==80 and s.stock("star_seeds")==48,"seasonal seed supplies are quadrupled")
	s.money=10000
	s.purchase("bread")
	s.purchase("pan")
	s.advance(1440-s.minute)
	check(s.stock("bread")==20 and s.stock("pan")==0,"food restocks overnight while cookware stays seasonal")
	var w=game.outdoors
	var actor=w.villagers.moss
	var target=w.Grid.world_to_cell(actor.position)+Vector2i.RIGHT
	var sentinel=w.Grid.center(Vector2i(-100,-100))
	w.routes.moss={"target":w.Grid.center(target),"path":[sentinel],"blocked":true,"retry_at":w.elapsed+1}
	var position=actor.position
	for i in range(60): w.Bodies.walk_to(w,"moss",target,0.016,56)
	check(actor.position==position and w.routes.moss.path==[sentinel],"blocked NPCs wait for their retry deadline instead of replanning each frame")
	w.routes.moss.path=[]
	w.routes.moss.obstruction_signature=w.Bodies.obstruction_signature(w)
	w.routes.moss.retry_at=w.elapsed-1
	w.Bodies.walk_to(w,"moss",target,0.016,56)
	check(w.routes.moss.path.is_empty() and w.routes.moss.retry_at>w.elapsed,"unchanged obstructions do not trigger another full route search after the deadline")
	s.rusty_sword=1
	s.assign_active("primary","rusty_sword")
	s.weather_override="sunny"
	var harvested=false
	for cell in w.forage_nodes.berries:
		if w.blocked(w.Grid.center(cell+Vector2i.DOWN)): continue
		s.player_position=w.Grid.center(cell+Vector2i.DOWN)
		w.facing="up"
		var before=s.berries
		game.interact()
		harvested=s.berries==before+1
		break
	check(harvested,"a selected sword still lets the player gather ripe berries")
	game.development_materials()
	check(["wood","stones","coal","copper","star_bulbs","turnips"].all(func(id):return s.chest.any(func(stack):return stack.get("id","")==id and stack.get("count",0)>=500)),"development materials arrive in the farmhouse chest")
	s.needs.hardcore=true
	s.needs.without_water=100
	s.energy=20
	check(s.purchase_drink("mead") and s.energy>20 and s.needs.without_water==0,"a tavern drink is served immediately and restores hydration and some energy")
	game.close_window()
	s.minute=600
	w.update_villagers(0,true)
	game.enter_building("windmill")
	for id in ["miller","miller_wife"]:
		game.world.villagers[id].visible=true
		game.world.villagers[id].data.sleeping=false
		preload("res://neighbors.gd").talk(game,id)
		var options=game.ui.modal_box.get_children().filter(func(node):return node is Button and node.text=="What have you got for sale?")
		check(options.size()==1,"either Bell offers flour while at the mill: "+id)
	game.close_window()
	game.leave_building()
	game.enter_building("tavern")
	game.world.villagers.barkeep.visible=true
	game.world.villagers.barkeep.data.sleeping=false
	preload("res://neighbors.gd").talk(game,"barkeep")
	var sale=game.ui.modal_box.get_children().filter(func(node):return node is Button and node.text=="What have you got for sale?")
	check(sale.size()==1,"Rafe offers his drinks from the tavern")
	if not sale.is_empty():
		sale[0].pressed.emit()
		check(game.ui.modal_box.get_child(2).text.contains("winter wheel repair"),"Wrenlight has a local origin story")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
