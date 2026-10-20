extends RefCounted

static func explore(game: Node2D,meet_moss: bool=false) -> void:
	if game.opening!=null: game.opening.finish()
	while not game.state.briefing_complete:
		game.ui.modal_box.get_child(3).pressed.emit()
	game.leave_building()
	game.state.welcome_phase="complete"
	game.state.player_position=game.Grid.center(game.Grid.SPAWN_CELL)
	if meet_moss:
		game.talk("moss")
		while game.window_open: game.ui.modal_box.get_child(3).pressed.emit()
	game.world.refresh()

static func tools(state: RefCounted) -> void:
	state.magic_learned=true
	for i in range(4): state.chest_transfer(i)
	for pair in [[0,"hoe"],[1,"watering_can"],[2,"sickle"],[3,"seeds"],[5,"wildgrowth"]]: state.assign_slot(pair[0],pair[1])
	state.selected_slot=1
	state.refill_water()
	state.selected_slot=0
