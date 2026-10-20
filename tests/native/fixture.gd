extends RefCounted

static func explore(game: Node2D,meet_moss: bool=false) -> void:
	if game.opening!=null: game.opening.finish()
	while not game.state.briefing_complete:
		game.ui.modal_box.get_child(3).pressed.emit()
	game.leave_building()
	game.state.welcome_phase="complete"
	game.state.player_position=game.Grid.center(game.Grid.SPAWN_CELL)
	if meet_moss:
		game.state.invite_mayor()
	game.world.refresh()

static func tools(state: RefCounted) -> void:
	state.magic_learned=true
	for i in range(4): state.chest_transfer(i)
	for pair in [[0,"hoe"],[1,"watering_can"],[2,"sickle"],[3,"seeds"],[5,"wildgrowth"]]: state.assign_slot(pair[0],pair[1])
	state.selected_slot=1
	state.refill_water()
	state.selected_slot=0

static func finish_welcome(game: Node2D) -> void:
	while game.state.welcome_phase=="escorting": game._process(0.1)
	game.state.storage_transfer("cabinet",0)
	for task in game.state.house_tasks: game.tidy_farmhouse(task)
	game._process(8)
	while game.state.welcome_phase!="complete":
		if game.window_open: game.ui.modal_box.get_child(3).pressed.emit()
		else: game._process(0.25)
	game.leave_building()
