extends SceneTree
const Game=preload("res://game.gd")
const Interior=preload("res://interior.gd")
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
	game.enter_building("tavern")
	check(game.world.floor_cells[game.world.layout.entry]=="taproom","the tavern entrance opens directly into the bar")
	check(game.world.furnishings.filter(func(f):return f.kind=="chair").size()>=6,"the tavern has chairs around its tables")
	check(game.world.layout.get("private_doors",[]).size()==1,"the bartender's back apartment has one private access door")
	var private_entry=game.world.layout.private_doors[0]
	check(game.world.player_blocked(game.Grid.center(private_entry)) and not game.world.blocked(game.Grid.center(private_entry)),"the tavern apartment door blocks visitors while allowing the resident's route")
	game.leave_building()
	for pair in [["reed_farm","farmer_mother","farmer_father"],["mill_home","miller","miller_wife"]]:
		game.enter_building(pair[0])
		var beds=game.world.layout.get("beds",{})
		check(beds.get(pair[1],-1)==beds.get(pair[2],-2),"married parents share one bed in "+pair[0])
		game.leave_building()
	game.enter_building("windmill")
	check(game.world.furnishings.any(func(f):return f.kind=="millstone") and not game.world.furnishings.any(func(f):return f.kind in ["machine","console","reactor"]),"the mill uses stone and wooden machinery instead of starship equipment")
	game.leave_building()
	game.enter_building("home")
	var hallway_faded=false
	var room_wall_opaque=false
	for wall in game.world.get_children():
		if not wall is Interior.Wall: continue
		var behind=game.Grid.world_to_cell(wall.position)-Vector2i(0,2)
		var room_kind=game.world.floor_cells.get(behind,"")
		if room_kind=="": continue
		game.state.player_position=game.Grid.center(behind)
		game.world.refresh()
		if room_kind in ["hall","back_hall","doorway"] and wall.modulate.a<0.5: hallway_faded=true
		if room_kind not in ["hall","back_hall","doorway"] and wall.modulate.a==1.0: room_wall_opaque=true
	check(hallway_faded and room_wall_opaque,"hallway overhangs fade while overlapping ordinary room walls remain opaque")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
