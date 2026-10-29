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
	game.state.cave_seed=12345
	preload("fixture.gd").garden(game.state)
	check(not game.state.assign_slot(0,"wildgrowth"),"untrained captains cannot assign magic")
	game.state.plots[0].planted=game.state.total()
	game.state.plots[0].watered=true
	check(not game.state.grow(0),"untrained captains cannot cast magic")
	game.enter_building("cave")
	var cave=game.world
	check(game.current_room=="cave" and cave.chambers.size()==7,"the southeast cave opens a generated seven-room floor")
	var paths=true
	for room in cave.chambers:
		if cave._route(cave.layout.entry,room.get_center()).is_empty(): paths=false
	check(paths,"every generated room is connected by grid passages")
	check(game.state.cave_barrel.size()==4 and game.state.cave_barrel.all(func(stack):return stack.is_empty()),"the entrance barrel offers four empty storage slots beside the pickaxe")
	game.close_window()
	var ore=cave.rocks.values().filter(func(rock): return rock.ore)[0]
	game.state.player_position=game.Grid.center(ore.cell+Vector2i.DOWN)
	cave.facing="up"
	var before=game.state.energy
	check(not cave.mine_rock(ore.id) and game.state.energy==before,"mining requires the selected carried pickaxe")
	var ore_position=game.state.player_position
	preload("fixture.gd").face_site(game,"cave_pickaxe")
	game.interact()
	game.state.player_position=ore_position
	game.state.clear_empty_slots()
	check("pickaxe" in game.state.quick_slots,"the collected pickaxe appears in its matching inventory-row position")
	game.state.assign_slot(0,"pickaxe")
	game.state.selected_slot=0
	preload("fixture.gd").activate(game)
	preload("fixture.gd").activate(game)
	preload("fixture.gd").activate(game)
	preload("fixture.gd").activate(game)
	check(game.state.copper==1 and game.state.stones==1 and game.state.energy==before-8,"ore and stone require a two-hit mining swing and two floor pickups")
	check(not cave.mine_rock(ore.id),"a mined rock cannot yield resources repeatedly")
	var rat=cave.rats[0]
	var rat_cell=game.Grid.world_to_cell(rat.position)
	var adjacent=Vector2i.ZERO
	for offset in [Vector2i.RIGHT,Vector2i.LEFT,Vector2i.UP,Vector2i.DOWN]:
		if cave.floor_cells.has(rat_cell+offset) and not cave.solid_cells.has(rat_cell+offset):
			adjacent=offset
			break
	game.state.player_position=game.Grid.center(rat_cell+adjacent)
	var distance=rat.position.distance_to(game.state.player_position)
	cave.update_enemies(0.5)
	check(rat.position.distance_to(game.state.player_position)<=distance,"nearby rats approach the captain")
	game.state.player_position=rat.position+Vector2(0,20)
	var health=game.state.health
	cave.update_enemies(1)
	check(game.state.health<health,"rats bite within reach")
	game.state.rusty_sword=1
	game.state.assign_slot(1,"rusty_sword")
	game.select_quick_slot(1)
	rat_cell=game.Grid.world_to_cell(rat.position)
	game.state.player_position=game.Grid.center(rat_cell+adjacent)
	cave.facing="right" if adjacent==Vector2i.LEFT else "left" if adjacent==Vector2i.RIGHT else "down" if adjacent==Vector2i.UP else "up"
	before=game.state.energy
	check(cave.attack(),"the selected sword strikes a rat")
	cave.swing_cooldown=0
	var second_strike=cave.attack()
	check(second_strike and not rat.visible and game.state.energy==before-4,"two selected-sword strikes defeat a rat and consume energy")
	var snapshot=game.state.to_dict()
	var restored=game.State.new()
	check(restored.restore(snapshot) and restored.cave_broken==game.state.cave_broken and restored.cave_defeated==game.state.cave_defeated,"save data preserves cave seed, mined rocks and defeated rats")
	var loaded_cave=game.Cave.new()
	loaded_cave.state=restored
	loaded_cave.outdoors=game.outdoors
	loaded_cave.building={"id":"cave"}
	game.add_child(loaded_cave)
	check(loaded_cave.chambers==cave.chambers and not loaded_cave.rocks.has(ore.id) and not loaded_cave.rats[0].visible,"a freshly loaded cave reconstructs the same layout and cleared objects")
	loaded_cave.queue_free()
	for field in ["cave_seed","cave_broken","cave_defeated","cave_barrel","day"]:
		var bad=snapshot.duplicate(true)
		bad[field]={"cave_seed":0,"cave_broken":["unknown"],"cave_defeated":[999],"cave_barrel":[{}],"day":"invalid"}[field]
		check(not restored.restore(bad),"invalid %s is rejected without mutating progress" % field)
	preload("fixture.gd").face_site(game,"exit")
	game.interact()
	check(game.current_room=="","an armed sword still allows using the cave exit")
	game.enter_building("cave")
	check(not cave.rocks.has(ore.id) and not rat.visible,"reentering preserves cleared cave objects")
	game.leave_building()
	game.state.minute=780
	game.enter_building("iona")
	game.talk("iona")
	game.ui.modal_box.get_child(3).pressed.emit()
	for choice in game.ui.modal_box.get_children():
		if choice is Button and choice.text=="Learn the local lore": choice.pressed.emit(); break
	for choice in game.ui.modal_box.get_children():
		if choice is Button and choice.text=="Teach me Wildgrowth": choice.pressed.emit(); break
	check(game.state.magic_learned and game.state.assign_slot(2,"wildgrowth"),"Iona's free tower lesson unlocks manually assigned Wildgrowth")
	game.close_window()
	game.leave_building()
	preload("fixture.gd").face_site(game,"sparkfire")
	game.state.minute=720
	game.interact()
	check(game.state.golden_sparkfire_bloom==0,"the sparkfire plant cannot be harvested outside dawn")
	game.state.minute=360
	game.interact()
	game.interact()
	check(game.state.golden_sparkfire_bloom==1,"sunrise opens one harvestable bloom per day")
	game.enter_building("cave")
	game.change_cave_level(1)
	game.change_cave_level(1)
	game.state.assign_active("primary","")
	preload("fixture.gd").face_site(game,"chrysalis")
	game.interact()
	game.interact()
	check(game.state.cave_moth_chrysalis==1 and game.state.cave_chrysalis_taken,"the deep cave component is collected only once")
	var generated={}
	var connected=true
	for seed_value in range(1,31):
		var instance=game.Cave.new()
		instance.state=game.State.new()
		instance.state.cave_seed=seed_value
		instance.outdoors=game.outdoors
		instance.building={"id":"cave"}
		game.add_child(instance)
		generated[str(instance.chambers)]=true
		for site in instance.sites:
			if instance.blocked(game.Grid.center(site.cell)): connected=false
		instance.queue_free()
	check(connected and generated.size()==30,"thirty generated seeds have varied rooms and clear interaction sites")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
