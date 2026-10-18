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
	check(game.started and game.world.player!=null and game.ui.root!=null,"native world and interface initialize")
	check(game.world.crops.z_index>=0,"garden is drawn above terrain")
	check(game.ui.energy_bar.size.y==4 and game.ui.mana_bar.size.y==4,"resource bars preserve compact layout")
	game.state.player_position=Vector2(880,708)
	game.interact()
	check(game.window_open and game.ui.modal_box.get_child(1).text=="Moss","proximity opens neighbor conversation")
	game.ui.modal_box.get_child(3).pressed.emit()
	check(game.state.invited and not game.window_open,"dialogue choice records appointment")
	game.state.player_position=game.world.plot_position(0)
	for i in range(3): game.interact()
	check(game.state.plots[0].watered and game.state.seeds==7,"contextual input tills plants and waters")
	game.cast_growth()
	game.interact()
	check(game.state.turnips==1 and game.state.harvested==1,"growth magic and harvest connect to inventory")
	game.state.player_position=Vector2(1430,700)
	game.interact()
	game.ui.modal_box.get_child(3).pressed.emit()
	check(game.state.turnips==0 and game.state.money==32,"merchant dialogue actually sells inventory")
	game.state.player_position=Vector2(1585,1090)
	game.interact()
	game._update_activity(1.2)
	check(game.state.copper==1 and game.activity=="","mining completes through the game controller")
	game.state.copper=3
	game.state.player_position=Vector2(343,355)
	game.interact()
	game.ui.modal_box.get_child(3).pressed.emit()
	check(game.state.delivered and game.state.copper==0,"crew repair consumes copper and completes objective")
	game.state.player_position=Vector2(420,1110)
	game.interact()
	game.activity_time=1.2
	game.interact()
	check(game.state.fish==1 and game.activity=="","fishing timing rewards a successful catch")
	game.state.day=2
	game.state.minute=719
	game.state.player_position=Vector2(724,690)
	game._process(0.5)
	check(game.state.met_mayor and game.window_open,"mayor arrives at farmhouse when continuous clock reaches noon")
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
	var step=10
	var start=Vector2i(65,73)
	var visited={start:true}
	var frontier: Array[Vector2i]=[start]
	var head=0
	while head<frontier.size():
		var cell=frontier[head]
		head+=1
		for delta in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next=cell+delta
			if visited.has(next): continue
			if world.blocked(Vector2(next)*step): continue
			visited[next]=true
			frontier.append(next)
	var targets: Array=[]
	for p in world.PEOPLE+world.SITES: targets.append(Vector2(p.x,p.y))
	for i in range(20): targets.append(world.plot_position(i))
	for target in targets:
		var reachable=false
		for cell in visited:
			if (Vector2(cell)*step).distance_to(target)<30:
				reachable=true
				break
		if not reachable:
			print("Unreachable landmark: ",target)
			return false
	return true
