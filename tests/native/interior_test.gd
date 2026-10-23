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
	preload("fixture.gd").explore(game,true)
	var outside=game.world
	check(game.camera.zoom.is_equal_approx(Vector2.ONE*1.9125),"camera zoom reflects the latest 15 percent reduction")
	var home=outside.buildings[0]
	preload("fixture.gd").face_site(game,"door_home")
	game.interact()
	check(game.world!=outside and not outside.visible,"E at the farmhouse door enters a separate interior map")
	check(not game.world.blocked(game.state.player_position),"interior entrance places the player on walkable floor")
	var room_data=game.state.to_dict()
	var restored=game.State.new()
	check(restored.restore(room_data) and restored.location=="home" and restored.player_position==game.state.player_position,"interior location and position survive a save round trip")
	var kinds={}
	for furniture in game.world.furnishings: kinds[furniture.kind]=true
	check(["sofa","table","chair","bed","kitchen","bath","bookshelf","art","radio","rug"].all(func(kind): return kinds.has(kind)),"home includes living bedroom kitchen bathroom and personal furnishings")
	preload("fixture.gd").face_site(game,"exit")
	game.interact()
	check(game.world==outside and outside.visible,"the interior exit returns to the same outdoor world")
	var reached=true
	for b in outside.buildings:
		game.enter_building(b.id)
		if game.world.blocked(game.state.player_position): reached=false
		game.leave_building()
	check(reached,"every building has an enterable interior")
	var routes_clear=true
	for room in game.rooms.values():
		for site in room.sites:
			if site.id!="exit" and room._route(room.Grid.world_to_cell(room.entry_position()),site.cell).is_empty():
				print("Unreachable interaction: ",room.building.id," / ",site.id," at ",site.cell)
				routes_clear=false
	check(routes_clear,"every room has routes from the entrance to its bed radio and other interactions")
	game.state.day=3
	game.state.minute=600
	game.state.invited=true
	outside.update_villagers(0.0,true)
	game.enter_building("radio")
	game.world.update_villagers(0.0,true)
	check(game.world.villagers.has("finch") and game.world.villagers.finch.visible,"Finch works inside the radio club during club hours")
	game.leave_building()
	game.state.minute=60
	outside.update_villagers(0.0,true)
	game.enter_building("finch")
	check(game.world.villagers.finch.visible and game.world.villagers.finch.data.sleeping,"Finch is asleep in his own bedroom at night")
	game.leave_building()
	var before=game.state.plots.duplicate(true)
	game.state.player_position=outside.Grid.center(outside.MOSS_FIELDS.position)
	game.interact()
	check(before==game.state.plots,"Moss's decorative fields cannot alter player crops")
	game.close_window()
	game.state.met_mayor=true
	game.state.minute=600
	outside.update_villagers(0.0,true)
	check(outside.villagers.moss.position.distance_to(outside.Grid.rect(outside.MOSS_FIELDS.position,outside.MOSS_FIELDS.size).get_center())<150,"Moss spends working hours in his own fields")
	var cabin={}
	for b in outside.buildings:
		if b.id=="veteran": cabin=b
	var secluded=true
	for cell in outside.road_cells:
		if outside.Grid.rect(cabin.cell,cabin.tiles).grow(96).has_point(outside.Grid.center(cell)): secluded=false
	check(secluded,"the veteran's woodland cabin has no road leading to it")
	game.state.minute=600
	game.talk("veteran")
	game.ui.modal_box.get_child(3).pressed.emit()
	check(game.state.rusty_sword==1,"veteran dialogue awards the player's first sword")
	game.state.assign_slot(4,"rusty_sword")
	game.select_quick_slot(4)
	check(game.state.equipped=="rusty_sword","the sword can be equipped through the inventory action")
	game.close_window()
	game.state.day=2
	game.state.minute=719
	game.state.mayor_due=2160
	game.state.met_mayor=false
	game.enter_building("home")
	game._process(1.0)
	check(game.window_open and game.conversation_members.size()==3,"the noon appointment also works when the captain waits inside the farmhouse")
	for i in range(3): game.ui.modal_box.get_child(3).pressed.emit()
	check(game.state.met_mayor,"the indoor introduction completes after its final choice")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
