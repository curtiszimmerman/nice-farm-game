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
	var s=game.state
	var crew=game.ui.quest_lines()[0]
	check(not crew.tasks.back().done,"initial emergency rations do not complete the player food-deposit task")
	s.hoe=1
	s.seeds=1
	s.sync_inventory()
	s.move_inventory("seeds",5)
	s.axe=1
	s.sync_inventory()
	check(s.inventory_order[1]=="axe" and s.inventory_order[5]=="seeds","new items occupy the first empty inventory position")
	s.fish_sticks=2
	s.storage_transfer("ship_storage",2,"fish_sticks",2)
	check(game.ui.quest_lines()[0].tasks.back().done,"depositing prepared food completes the supply milestone")
	preload("fixture.gd").explore(game,true)
	s.met_mayor=true
	game.talk("moss")
	check(not game.ui.modal_box.get_children().any(func(node):return node is Button and node.text.contains("[Rude]")),"ordinary friendly conversations do not offer a gratuitous insult")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
