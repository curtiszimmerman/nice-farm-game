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
	var s=game.state
	check(s.quick_slots.all(func(id): return id=="") and s.selected_slot==0,"new players have eight empty quick slots with one selected")
	check(s.seeds==0 and s.chest.any(func(stack): return stack.get("id")=="seeds" and stack.count==8),"starting seeds are stored with the tools")
	check(s.water==0,"the starter watering can is empty")
	s.chest_transfer(0)
	check(s.quick_slots.all(func(id): return id==""),"taking a tool never assigns it to a slot")
	game.inventory()
	check(game.ui.inventory_slots.size()==12,"the satchel has twelve slots")
	var single=game.ui.item_slot({"id":"hoe","count":1},68)
	var multiple=game.ui.item_slot({"id":"seeds","count":8},68)
	check(single.get_child(1).text=="" and multiple.get_child(1).text=="8","only stacks larger than one display a quantity")
	single.free()
	multiple.free()
	for id in ["hoe","watering_can","sickle","seeds","star_seeds","turnips","fish","star_bulbs","copper","pot","pan","rations"]: s.set(id,1)
	s.chest[5]={"id":"health_elixir","count":2}
	check(not s.chest_transfer(5,"",1) and s.chest[5].count==2,"a full satchel rejects a new stack without losing supplies")
	check(s.chest_transfer(5,"hoe",1) and s.health_elixir==2 and s.hoe==0,"a full satchel can swap a complete carried stack")
	s.copper=0
	s.fish_stew=1
	var energy=s.energy
	check(not s.mine() and s.energy==energy and s.copper==0,"gathering cannot create an invisible thirteenth stack")
	s.money=100
	s.buy_utensil("pan")
	s.fish=2
	check(not s.cook("fish_sticks") and s.fish==2,"cooking preserves ingredients when its result will not fit")
	check(not s.accept_sword() and s.rusty_sword==0,"quest equipment requires a free carried slot")
	var invalid=s.to_dict()
	invalid.supplies.fish_sticks=1
	check(not game.State.new().restore(invalid),"a saved inventory cannot exceed its twelve carried slots")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
