extends SceneTree
const Game=preload("res://game.gd")
const State=preload("res://state.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var s=State.new()
	s.money=100
	s.energy=50
	s.needs.hardcore=true
	s.needs.without_water=300
	s.needs.without_food=500
	check(s.purchase_drink("ale") and s.energy==51 and s.needs.without_water==0 and s.needs.without_food<500,"ale hydrates and lightly feeds while restoring only one energy")
	check(s.movement_multiplier()==0.5 and s.damage_multiplier()==0.5,"drunkenness halves speed and inflicted damage")
	s.advance(30)
	s.purchase_drink("mead")
	check(s.status_effects.drunk.remaining==60,"another drink refreshes the hour")
	var restored=State.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(s.to_dict()))) and restored.damage_multiplier()==0.5,"drunkenness survives saving")
	s.advance(60)
	check(not s.status_effects.has("drunk") and s.damage_multiplier()==1,"drunkenness expires after an hour")
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	s=game.state
	s.star_bulbs=1
	s.assign_active("primary","star_bulbs")
	preload("fixture.gd").face_site(game,"bed")
	preload("fixture.gd").activate(game)
	check(game.current_room=="home" and s.star_bulbs==1,"a selected edible item cannot swallow a house-door activation")
	game.leave_building()
	for world_seed in [1,123456,917]:
		s.world_seed=world_seed
		game.outdoors.rebuild_visit(s)
		var reached=game.outdoors.Foraging.reachable_cells(game.outdoors)
		check(game.outdoors.forage_nodes.berries.keys().all(func(cell):return game.outdoors.Foraging.can_harvest(cell,reached)),"every berry bush has a reachable facing tile")
	s.crucible_known=true
	s.beehive_known=true
	game.inventory()
	check(game.ui.inventory_tabs.get_children().any(func(tab):return tab.name=="Crafting") and game.ui.crafting_buttons.size()==1,"known blueprints live on a Crafting tab")
	check(not game.ui.skill_buttons.any(func(b):return b.get_meta("item_id","")=="build_crucible"),"blueprints no longer appear among spells and skills")
	game.close_window()
	s.stones=10
	var cell=Vector2i.ZERO
	for y in range(49,58):
		for x in range(20,35):
			var candidate=Vector2i(x,y)
			if game.outdoors.can_build_crucible(candidate) and not game.outdoors.blocked(game.Grid.center(candidate+Vector2i.DOWN)): cell=candidate; break
		if cell!=Vector2i.ZERO: break
	check(cell!=Vector2i.ZERO and s.build_crucible(cell),"a clear crucible site can be built")
	game.outdoors.add_crucible(0)
	s.copper=1
	s.coal=1
	s.assign_active("primary","copper")
	preload("fixture.gd").face_site(game,"crucible")
	preload("fixture.gd").activate(game)
	check(game.window_open and s.copper==1,"insufficient smelting resources show a modal without consuming anything")
	game.close_window()
	s.copper=2
	preload("fixture.gd").activate(game)
	check(not game.window_open and s.copper==0 and s.coal==0 and s.crucibles[0].ready_at>0,"active copper loads two ore and one coal without opening a menu")
	s.advance(30)
	preload("fixture.gd").activate(game)
	check(not game.window_open and s.copper_bars==1,"finished bars are collected directly")
	game.close_window()
	s.minute=600
	s.money=100
	game.enter_building("windmill")
	game.world.villagers.miller.visible=true
	game.world.villagers.miller.data.sleeping=false
	preload("res://neighbors.gd").talk(game,"miller")
	game.ui.modal_box.get_children().filter(func(node):return node is Button and node.text=="What have you got for sale?")[0].pressed.emit()
	game.ui.modal_box.find_children("*","Button",true,false).filter(func(node):return node.text.begins_with("Sack of flour"))[0].pressed.emit()
	check(s.flour==1 and game.ui.message.text=="Bought Sack of flour.","buying flour reports success instead of a false full-satchel warning")
	game.close_window()
	game.leave_building()
	s.cave_level=0
	game.enter_building("cave")
	game.close_window()
	s.rusty_sword=1
	s.energy=100
	s.assign_active("primary","rusty_sword")
	s.status_effects.drunk={"remaining":60.0}
	game.world.facing="down"
	var rat=game.world.rats[0]
	rat.visible=true
	rat.info.health=2
	rat.position=s.player_position+Vector2(0,32)
	check(game.world.attack() and is_equal_approx(rat.info.health,1.5),"an actual sword hit inflicts half damage while drunk")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
