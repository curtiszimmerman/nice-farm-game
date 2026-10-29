extends SceneTree
const Game=preload("res://game.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func buttons(game: Node2D) -> Array:
	return game.ui.modal_box.get_children().filter(func(node):return node is Button)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	var s=game.state
	var w=game.outdoors
	s.met_mayor=true
	var night=preload("res://night_effects.gd").new()
	night.world=w
	s.day=85
	s.minute=1300
	check(not night.smoking(w.buildings.filter(func(b):return b.id=="priest_outhouse")[0]),"the chimney-free outhouse cannot emit winter smoke")
	night.free()
	s.day=1
	s.minute=600
	check(w.farm_cells.is_empty() and w.fence_cells.is_empty(),"the starting farm has no predefined field or field fencing")
	check(not game.Grid.farmable(Vector2i(13,40)) and not game.Grid.farmable(Vector2i(25,63)),"new plots exclude the north and Moss's farm")
	check(w.sites.all(func(site):return site.id!="radio"),"the exterior radio table has been removed")
	check(w.sites.filter(func(site):return site.id=="door_finch")[0].label=="Enter Finch's House","house prompts identify whose house it is")
	check(not w.yard_fences.keys().any(func(cell):return w.SQUARE.has_point(cell)),"the temple fence runs outside town square")
	for x in range(0,49):
		check(w.road_cells.has(Vector2i(x,52)) and not w.blocked(game.Grid.center(Vector2i(x,52))),"the farmhouse coastal road is clear at %d"%x)
	game.enter_building("observatory")
	check(game.current_room=="" and "closed to-day" in game.ui.modal_box.get_child(2).text,"the observatory is closed on the first Rift")
	game.close_window()
	s.day=2
	var truth=game.State.new()
	truth.record_star_origin(true)
	truth.record_star_origin(true)
	check(truth.friendships.astronomer==5,"trusting Saeren earns five friendship once")
	var lie=game.State.new()
	lie.record_star_origin(false)
	check(lie.friendships.astronomer== -5,"lying to Saeren costs five friendship")
	for day in [1,8,15]:
		for minute in [0,600,900,1200,1439]:
			check(w.Schedule.stop("astronomer",minute,day).room=="observatory","Saeren stays in the observatory throughout every Rift")
	s.minute=780
	w.update_villagers(0,true)
	game.talk("iona")
	buttons(game).filter(func(b):return b.text=="Go on.")[0].pressed.emit()
	check(buttons(game).any(func(b):return b.text=="Learn the local lore"),"Iona offers lessons away from her tower while awake")
	game.close_window()
	game.talk("tavi")
	buttons(game).filter(func(b):return b.text=="Go on.")[0].pressed.emit()
	check(not buttons(game).any(func(b):return b.text.begins_with("Buy") or b.text.begins_with("Sell")),"Tavi never trades outside the grocery")
	game.close_window()
	game.enter_building("smithy")
	s.money=999
	s.minute=600
	w.update_villagers(0,true)
	game.world.villagers.smith.visible=true
	game.world.villagers.smith.data.sleeping=false
	game.talk("smith")
	buttons(game).filter(func(b):return b.text=="Go on.")[0].pressed.emit()
	check(buttons(game).filter(func(b):return "work" in b.text).size()==1,"the smith has one topic about his work")
	var sale=buttons(game).filter(func(b):return b.text=="What have you got for sale?")
	if not sale.is_empty(): sale[0].pressed.emit()
	var sword=buttons(game).filter(func(b):return b.text.contains("Rusty sword"))
	check(not sword.is_empty() and sword[0].modulate.r<1.0 and "1,000" in sword[0].text,"unaffordable sword purchase is visibly faded in the shop list")
	game.close_window()
	game.leave_building()
	s.health=10
	s.energy=0
	s.mana=0
	s.needs.without_food=9999
	s.needs.without_water=999
	var money=s.money
	game.development_supplies()
	check(s.health==100 and s.energy==100 and s.mana==60 and s.money==money+100000 and s.needs.without_food==0 and s.needs.without_water==0,"development supplies restore vitals and add crowns")
	check(["rusty_sword","pickaxe","axe","hoe","watering_can","sickle","fishing_pole"].all(func(id):return s.get(id)>=1),"development supplies grant every basic tool")
	game.close_window()
	s.assign_active("primary","axe")
	var tree=w.trees[0]
	w.elapsed=10
	check(w.chop_tree(tree.cell),"a fresh axe swing executes")
	var energy=s.energy
	check(not w.chop_tree(tree.cell) and s.energy==energy,"a repeat chop during the animation consumes no energy")
	w.elapsed+=0.61
	w.chop_tree(tree.cell)
	w.elapsed+=0.61
	w.chop_tree(tree.cell)
	check(s.wood==0 and s.felled_trees.size()==1,"felling leaves logs on the ground instead of awarding them immediately")
	check(w.moving_layer.get_children().any(func(node):return node.kind=="logs"),"a felled tree leaves a visible log pickup")
	var falling=w.scenery_layer.get_children().filter(func(node):return node.data.get("falling",false))[0]
	w.elapsed+=0.3
	w.refresh()
	check(absf(falling.rotation)>0.1 and falling.modulate.a<0.6,"a falling tree rotates at its base and fades halfway through its action")
	var rotation=falling.rotation
	w.refresh()
	check(falling.rotation==rotation,"tree falls use world animation time and remain still while it is paused")
	check(s.restore(JSON.parse_string(JSON.stringify(s.to_dict()))),"the empty starting farm and fallen trees survive JSON saving")
	game.enter_building("mayor")
	if game.current_room=="mayor":
		check(game.world.solid_cells.has(Vector2i(9,6)) and game.world.solid_cells.has(Vector2i(9,5)) and game.world.solid_cells.has(Vector2i(9,7)),"the mayor's central corner connects both wall segments")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
