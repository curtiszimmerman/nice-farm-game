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
	preload("fixture.gd").garden(game.state)
	check(game.state.pause_mode=="all","single player pauses menus and dialogue by default")
	check(game.state.has_method("assign_active"),"primary and auxiliary actions have independent assignments")
	if game.state.has_method("assign_active"):
		check(not game.state.assign_active("aux","wildgrowth"),"unlearned spells cannot be assigned")
		game.state.magic_learned=true
		game.state.hoe=1
		game.state.select_inventory("hoe")
		var count=game.inventory_stacks().size()
		game.state.assign_active("aux","wildgrowth")
		check(game.state.active_item("primary")=="hoe" and game.state.active_item("aux")=="wildgrowth","assigning an auxiliary spell preserves the primary tool")
		check(game.inventory_stacks().size()==count,"known spells do not occupy satchel slots")
		var restored=game.State.new()
		check(restored.restore(game.state.to_dict()) and restored.active_item("aux")=="wildgrowth","both action assignments survive saving")
	game.inventory()
	check(game.ui.has_method("open_character_inventory"),"inventory includes equipment and learned abilities")
	check(game.ui.equipment_slots.size()==9 and game.ui.skill_buttons.size()==1,"character panel includes all nine equipment slots and the learned spell")
	var auxiliary=game.ui.auxiliary_button
	auxiliary.call("_drop_data",Vector2.ZERO,{"type":"ability","id":"wildgrowth"})
	check(game.state.active_item("aux")=="wildgrowth","abilities can be dropped into the auxiliary action")
	game.state.watering_can=1
	game.state.assign_slot(1,"watering_can")
	game.ui.update()
	var can=game.ui.quick_buttons[1]
	check(can.get_node("Picture").texture!=null and can.text=="" and can.get_node("KeyBadge").get_child(0).text=="2" and can.get_node("Quantity").text=="Empty","empty watering cans retain a picture with separate key and charge labels")
	var minute=game.state.minute
	game._process(1)
	check(game.state.minute==minute,"an open inventory holds the world clock")
	check(game.has_method("remap_control"),"controls can be rebound in game")
	if game.has_method("remap_control"):
		game.remap_control("primary",KEY_R)
		check(game.controls.keys.primary==KEY_R,"rebinding changes the actual primary-action mapping")
		var file="res://../../internal/verification/controls-%d.cfg" % Time.get_ticks_usec()
		var fresh=preload("res://controls.gd").new()
		var written=game.controls.save(file)==OK
		fresh.load_keys(file)
		check(written and fresh.keys==game.controls.keys,"custom controls survive a settings-file round trip")
		DirAccess.remove_absolute(file)
		game.close_window()
		var row=game.state.quick_row
		var tab=InputEventKey.new()
		tab.physical_keycode=KEY_TAB
		tab.pressed=true
		game._input(tab)
		check(game.state.quick_row==1-row,"Tab cycles the quick-slot inventory row even after a GUI has held keyboard focus")
		game.state.axe=1
		game.state.assign_active("primary","axe")
		for y in range(65,75):
			for x in range(40,55):
				game.state.player_position=game.Grid.center(Vector2i(x,y))
				if game.world.find_nearest().is_empty(): break
			if game.world.find_nearest().is_empty(): break
		check(game.world.find_nearest().is_empty(),"an empty click target exists for the mouse regression")
		game.ui.message.text=""
		var click=InputEventMouseButton.new()
		click.button_index=MOUSE_BUTTON_LEFT
		click.pressed=true
		game._unhandled_input(click)
		check(game.ui.message.text=="","clicking empty ground with a tool equipped does not show interaction guidance")
		game.world.elapsed+=0.61
		game.state.select_inventory("hoe")
		game.state.player_position=game.world.plot_position(0)+Vector2(0,32)
		game.world.facing="up"
		var key=InputEventKey.new()
		key.pressed=true
		key.physical_keycode=KEY_E
		game._unhandled_key_input(key)
		check(not game.state.plots[0].tilled,"the former primary key stops activating after rebinding")
		key.physical_keycode=KEY_R
		game._unhandled_key_input(key)
		check(game.state.plots[0].tilled,"the rebound primary key performs real farm work")
		game.state.plots[0].planted=game.state.total()
		game.state.plots[0].watered=true
		game.state.day=2
		game.world.elapsed+=0.61
		key.physical_keycode=KEY_Q
		game._unhandled_key_input(key)
		check(game.state.ripe(0) and game.state.mana==45 and game.state.active_item("primary")=="hoe","the auxiliary key casts its own spell while preserving the primary hoe")
		game.talk("iona")
		minute=game.state.minute
		game._process(1)
		check(game.state.minute==minute,"ordinary NPC dialogue pauses single-player simulation")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
