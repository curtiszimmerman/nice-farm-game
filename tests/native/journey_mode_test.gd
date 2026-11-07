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
	if is_instance_valid(game.opening): game.opening.queue_free(); game.opening=null
	game.started=false
	game.state.needs.mode_chosen=false
	game.choose_journey_mode()
	check(not game.started and game.window_open,"the food and water notice appears before the intro starts")
	check(game.ui.hud_nodes.all(func(node):return not node.visible) and game.ui.modal.visible,"the food and water notice shows no HUD over its backdrop")
	var buttons=game.ui.modal_box.get_children().filter(func(node):return node is Button and node.visible)
	check(buttons.size()==1,"the notice only informs, with a single button and no choice to make")
	check(game.ui.modal_box.get_children().any(func(node):return node is Label and "food and water mode is enabled by default" in node.text.to_lower() and "settings" in node.text.to_lower()),"the notice says food and water mode is on and can be turned off in Settings")
	buttons[0].pressed.emit()
	check(game.started and game.state.needs.hardcore and game.state.needs.mode_chosen,"continuing begins the intro with food and water mode on")
	game.preferences()
	var toggle=game.ui.modal_box.get_children().filter(func(node):return node is Button and "Food and water" in node.text)
	check(toggle.size()==1 and toggle[0].text.begins_with("✓"),"Settings shows food and water mode switched on")
	toggle[0].pressed.emit()
	check(not game.state.needs.hardcore,"Settings turns food and water mode off")
	game.close_window()
	if is_instance_valid(game.opening): game.opening.queue_free(); game.opening=null
	game.state.needs.hardcore=true
	# The ship carries two weeks of rations and a water dispenser beside the crew locker.
	var rations=game.state.ship_storage.reduce(func(total,slot):return total+(int(slot.get("count",0)) if slot.get("id","")=="rations" else 0),0)
	check(rations==14,"the ship's locker starts with fourteen emergency rations")
	game.enter_building("ship")
	game.close_window()
	var dispenser=game.world.sites.filter(func(site):return site.id=="water_dispenser")
	var locker=game.world.sites.filter(func(site):return site.id=="ship_storage")
	check(dispenser.size()==1 and locker.size()==1 and dispenser[0].cell.distance_to(locker[0].cell)<=2.5,"a water dispenser stands beside the crew supply locker")
	game.state.needs.without_water=3000
	var reserve=game.state.ship_water
	preload("fixture.gd").face_site(game,"water_dispenser")
	game.interact()
	check(game.state.needs.without_water==0 and game.state.ship_water==reserve-1,"drinking from the dispenser quenches thirst and draws down the ship's water")
	game.state.ship_water=0
	game.state.needs.without_water=3000
	game.interact()
	check(game.state.needs.without_water==3000,"an empty dispenser gives nothing")
	var restored=game.State.new()
	check(restored.restore(game.state.to_dict()) and restored.ship_water==0,"the ship's water reserve survives a save")
	game.leave_building()
	check(game.BRIEFING.any(func(line):return "Fourteen" in line[1] and "dispenser" in line[1]),"Vale's briefing mentions the rations and the water dispenser")
	game.state.needs.without_water=4320
	game.drink_freshwater()
	check(game.state.needs.without_water==0,"drinking freshwater fully restores hydration")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
