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
	game.state.player_position=game.world.plot_position(0)+Vector2.UP*game.world.Grid.TILE_SIZE
	for slot in [0,3,1]:
		game.select_quick_slot(slot)
		game.interact()
	check(game.state.plots[0].watered and game.state.seeds==7,"contextual input tills plants and waters")
	game.select_quick_slot(5)
	game.cast_growth()
	game.select_quick_slot(2)
	game.interact()
	check(game.state.turnips==1 and game.state.harvested==1,"growth magic and harvest connect to inventory")
	game.state.player_position=game.world.villagers.tavi.position+Vector2(0,12)
	game.interact()
	game.ui.modal_box.get_child(3).pressed.emit()
	check(game.state.turnips==0 and game.state.money==32,"merchant dialogue actually sells inventory")
	game.close_window()
	game.state.player_position=game.world.site_position("ore")-Vector2(0,15)
	game.interact()
	game._update_activity(1.2)
	check(game.state.copper==1 and game.activity=="","mining completes through the game controller")
	game.state.copper=3
	game.enter_building("ship")
	game.state.player_position=game.world.villagers.vale.position+Vector2(0,15)
	game.interact()
	game.ui.modal_box.get_child(3).pressed.emit()
	check(game.state.delivered and game.state.copper==0,"crew repair consumes copper and completes objective")
	game.leave_building()
	game.select_quick_slot(0)
	game.state.player_position=game.world.site_position("pond")
	game.interact()
	game.activity_time=1.2
	game.interact()
	check(game.state.fish==1 and game.activity=="","fishing timing rewards a successful catch")
	game.state.day=2
	game.state.minute=719
	game.state.mayor_due=2160
	game.state.player_position=game.world.site_position("bed")+Vector2(0,32)
	game._process(0.5)
	check(not game.state.met_mayor and game.window_open,"mayor arrives at farmhouse when continuous clock reaches noon")
	for i in range(3): game.ui.modal_box.get_child(3).pressed.emit()
	check(game.state.met_mayor,"completing the introduction records meeting the mayor")
	game.close_window()
	game.settings()
	var menu_labels=[]
	for child in game.ui.modal_box.get_children():
		if child is Button: menu_labels.append(child.text)
	check("Development tools · advance time" in menu_labels and "Save and quit" in menu_labels,"settings exposes development tools and standard controls")
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
