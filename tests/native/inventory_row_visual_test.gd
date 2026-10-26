extends "visual_test.gd"
func run() -> void:
	prefix="row-qa-"
	game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	preload("fixture.gd").tools(game.state)
	game.state.learned_spells=["hearthmend","emberthread"]
	game.inventory()
	await process_frame
	await drag_controls(game.ui.inventory_slots[0],game.ui.inventory_slots[9])
	var healing=game.ui.skill_buttons.filter(func(button):return button.get_meta("item_id")=="hearthmend")[0]
	await drag_controls(healing,game.ui.quick_buttons[2])
	var fire=game.ui.skill_buttons.filter(func(button):return button.get_meta("item_id")=="emberthread")[0]
	await drag_controls(fire,game.ui.auxiliary_button)
	var good=game.state.inventory_order[9]=="hoe" and game.state.quick_slots[2]=="hearthmend" and game.state.active_item("aux")=="emberthread" and game.state.sickle==1
	if not good:
		failed=true
		push_error("FAIL: native inventory/spell drags did not preserve items and action assignments")
	else: print("PASS: native mouse drags move inventory rows, replace an occupied quickslot with a spell and assign the auxiliary spell")
	await capture("dragged-spells")
	game.close_window()
	await press_key(KEY_TAB)
	if game.state.quick_row!=1 or game.state.quick_slots[1]!="hoe":
		failed=true
		push_error("FAIL: native Tab did not select the rearranged second row")
	else: print("PASS: native Tab selects the rearranged second inventory row")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
