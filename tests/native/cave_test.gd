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
	check(not game.state.assign_slot(0,"wildgrowth"),"untrained captains cannot assign magic")
	game.state.plots[0].planted=game.state.total()
	game.state.plots[0].watered=true
	check(not game.state.grow(0),"untrained captains cannot cast magic")
	game.enter_building("cave")
	var cave=game.world
	check(game.current_room=="cave" and cave.chambers.size()==6,"the southeast cave opens a generated six-room interior")
	var paths=true
	for room in cave.chambers:
		if cave._route(cave.layout.entry,room.get_center()).is_empty(): paths=false
	check(paths,"every generated room is connected by grid passages")
	check(game.state.cave_barrel.size()==4 and game.state.cave_barrel[0].id=="pickaxe","the entrance barrel holds a pickaxe in four storage slots")
	var ore=cave.rocks.values().filter(func(rock): return rock.ore)[0]
	game.state.player_position=game.Grid.center(ore.cell+Vector2i.DOWN)
	cave.facing="up"
	var before=game.state.energy
	check(not cave.mine_rock(ore.id) and game.state.energy==before,"mining requires the selected carried pickaxe")
	game.state.storage_transfer("cave_barrel",0)
	check(game.state.quick_slots.all(func(id): return id==""),"taking the pickaxe never assigns a quick slot")
	game.state.assign_slot(0,"pickaxe")
	game.state.selected_slot=0
	game.interact()
	check(game.state.copper==1 and game.state.energy==before-5,"activated pickaxe mines copper and costs more energy than tilling")
	check(not cave.mine_rock(ore.id),"a mined rock cannot yield resources repeatedly")
	var rat=cave.rats[0]
	game.state.player_position=rat.position+Vector2(64,0)
	var distance=rat.position.distance_to(game.state.player_position)
	cave.update_enemies(0.5)
	check(rat.position.distance_to(game.state.player_position)<distance,"nearby rats approach the captain")
	game.state.player_position=rat.position+Vector2(20,0)
	var health=game.state.health
	cave.update_enemies(1)
	check(game.state.health<health,"rats bite within reach")
	game.state.rusty_sword=1
	game.state.assign_slot(1,"rusty_sword")
	game.select_quick_slot(1)
	cave.facing="left"
	before=game.state.energy
	game.interact()
	cave.update_enemies(0.4)
	game.interact()
	check(not rat.visible and game.state.energy==before-4,"two selected-sword strikes defeat a rat and consume energy")
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
		bad[field]={"cave_seed":0,"cave_broken":["unknown"],"cave_defeated":[9],"cave_barrel":[{}],"day":"invalid"}[field]
		check(not restored.restore(bad),"invalid %s is rejected without mutating progress" % field)
	game.state.player_position=cave.site_position("exit")
	game.interact()
	check(game.current_room=="","an armed sword still allows using the cave exit")
	game.enter_building("cave")
	check(not cave.rocks.has(ore.id) and not rat.visible,"reentering preserves cleared cave objects")
	game.leave_building()
	game.enter_building("iona")
	game.talk("iona")
	game.ui.modal_box.get_child(3).pressed.emit()
	check(game.state.magic_learned and game.state.assign_slot(2,"wildgrowth"),"Iona's free tower lesson unlocks manually assigned Wildgrowth")
	game.leave_building()
	game.state.player_position=game.outdoors.site_position("sparkfire")
	game.state.minute=720
	game.interact()
	check(game.state.golden_sparkfire_bloom==0,"the sparkfire plant cannot be harvested outside dawn")
	game.state.minute=360
	game.interact()
	game.interact()
	check(game.state.golden_sparkfire_bloom==1,"sunrise opens one harvestable bloom per day")
	game.enter_building("cave")
	game.state.selected_slot=0
	game.state.player_position=game.world.site_position("chrysalis")
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
		for chamber in instance.chambers:
			if instance._route(instance.layout.entry,chamber.get_center()).is_empty(): connected=false
		for site in instance.sites:
			if instance.blocked(game.Grid.center(site.cell)): connected=false
		instance.queue_free()
	check(connected and generated.size()==30,"thirty generated seeds have varied rooms and connected passages without blocked sites")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
