extends SceneTree

const Game = preload("res://game.gd")
var game: Node2D
var count = 0
var failed = false

func check(condition: bool, description: String) -> void:
	if not condition:
		failed = true
		push_error("FAIL: "+description)
	else:
		count+=1
		print("PASS: "+description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game)
	preload("fixture.gd").tools(game.state)
	check(game.started and game.world.player!=null and game.ui.root!=null,"native world and interface initialize")
	check(game.world.crops.z_index>=0,"garden is drawn above terrain")
	check(game.ui.energy_bar.size.y==4 and game.ui.mana_bar.size.y==4,"resource bars preserve compact layout")
	game.state.player_position=game.world.villagers.moss.position+Vector2(0,20)
	game.interact()
	check(game.window_open and game.ui.modal_box.get_child(1).text=="Moss","proximity opens neighbor conversation")
	for i in range(3): game.ui.modal_box.get_child(3).pressed.emit()
	check(game.state.invited and not game.window_open,"dialogue choice records the same-day appointment")
	preload("fixture.gd").finish_welcome(game)
	game.state.player_position=game.world.plot_position(0)+Vector2.UP*game.world.Grid.TILE_SIZE
	var seeds_before=game.state.seeds
	for slot in [0,3,1]:
		game.select_quick_slot(slot)
		preload("fixture.gd").activate(game)
	check(game.state.plots[0].watered and game.state.seeds==seeds_before-1,"contextual input tills plants and waters")
	game.select_quick_slot(5)
	game.state.day=2
	game.cast_growth()
	game.select_quick_slot(2)
	preload("fixture.gd").activate(game)
	check(game.state.turnips==1 and game.state.harvested==1,"growth magic and harvest connect to inventory")
	game.enter_building("store")
	game.state.player_position=game.world.villagers.tavi.position+Vector2(0,12)
	preload("fixture.gd").activate(game)
	for choice in game.ui.modal_box.get_children():
		if choice is Button and choice.text=="Go on.": choice.pressed.emit(); break
	for choice in game.ui.modal_box.get_children():
		if choice is Button and choice.text.begins_with("Sell produce"): choice.pressed.emit(); break
	check(game.state.turnips==0 and game.state.money==32,"merchant dialogue actually sells inventory")
	game.close_window()
	game.leave_building()
	preload("fixture.gd").face_site(game,"ore")
	game.interact()
	check(game.current_room=="cave","the copper entrance enters its own cave map")
	game.close_window()
	preload("fixture.gd").face_site(game,"cave_pickaxe")
	game.interact()
	game.state.assign_slot(0,"pickaxe")
	game.select_quick_slot(0)
	var rock=game.world.rocks.values().filter(func(item): return item.ore)[0]
	game.state.player_position=game.Grid.center(rock.cell+Vector2i.DOWN)
	game.world.facing="up"
	preload("fixture.gd").activate(game)
	preload("fixture.gd").activate(game)
	preload("fixture.gd").activate(game)
	preload("fixture.gd").activate(game)
	check(game.state.copper==1 and game.state.stones==1,"mining leaves ore and stone on the cave floor until collected")
	game.leave_building()
	game.state.copper_bars=3
	game.enter_building("ship")
	game.state.player_position=game.world.villagers.vale.position+Vector2(0,15)
	game.interact()
	game.ui.modal_box.get_child(3).pressed.emit()
	check(game.state.delivered and game.state.copper_bars==0,"crew repair consumes copper bars and completes objective")
	game.leave_building()
	game.select_quick_slot(0)
	game.state.player_position=game.world.site_position("pond")
	game.state.fishing_pole=1
	game.state.assign_active("primary","fishing_pole")
	game.start_fishing("pond")
	game.activity_time=1.2
	var caught=game.fishing_species
	var fish_before=game.state.get(caught)
	for i in range(1000):
		game.activity_time=1.2+i*0.01
		if game.fishing_position()>0.4 and game.fishing_position()<0.6: break
	game._finish_fishing()
	check(game.state.get(caught)==fish_before+1 and game.activity=="","fishing timing rewards the hooked species")
	game.state.day=2
	game.state.met_mayor=false
	game.state.minute=719
	game.state.mayor_due=2160
	game.state.player_position=game.world.site_position("bed")+Vector2(0,32)
	game._process(1.0)
	check(not game.state.met_mayor and game.window_open,"mayor arrives at farmhouse when continuous clock reaches noon")
	for i in range(3): game.ui.modal_box.get_child(3).pressed.emit()
	check(game.state.met_mayor,"completing the introduction records meeting the mayor")
	game.close_window()
	game.settings()
	var menu_labels=[]
	for child in game.ui.modal_box.get_children():
		if child is Button: menu_labels.append(child.text)
	check(["Controls","Settings","Development","Save","Quit"].all(func(label):return label in menu_labels),"game menu exposes compact submenus")
	game.close_window()
	game.inventory()
	check(game.window_open,"satchel opens in native interface")
	game.close_window()
	game.journal()
	check(game.window_open,"journal opens in native interface")
	game.close_window()
	game.map_notes()
	check(game.window_open,"directions open in native interface")
	game.close_window()
	check(_destinations_reachable(),"all NPCs sites and garden patches are reachable from the farm")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	print("%d native integration checks passed" % count)
	quit(1 if failed else 0)

func _destinations_reachable() -> bool:
	var world=game.world
	var start=world.Grid.SPAWN_CELL
	var visited={start:true}
	var frontier: Array[Vector2i]=[start]
	var head=0
	while head<frontier.size():
		var cell=frontier[head]
		head+=1
		for delta in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next=cell+delta
			if visited.has(next): continue
			if world.blocked(world.Grid.center(next)): continue
			visited[next]=true
			frontier.append(next)
	var targets: Array=[]
	for p in world.people+world.sites: targets.append(Vector2(p.x,p.y))
	for i in range(20):
		if not visited.has(world.Grid.world_to_cell(world.plot_position(i))): return false
	for target in targets:
		var reachable=false
		for cell in visited:
			if world.Grid.center(cell).distance_to(target)<55:
				reachable=true
				break
		if not reachable:
			print("Unreachable landmark: ",target)
			return false
	return true
