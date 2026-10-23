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
	state.weather_override="sunny"
	state.magic_learned=true
	for i in range(4): state.chest_transfer(i)
	for pair in [[0,"hoe"],[1,"watering_can"],[2,"sickle"],[3,"seeds"],[5,"wildgrowth"]]: state.assign_slot(pair[0],pair[1])
	state.selected_slot=1
	state.refill_water()
	state.selected_slot=0

static func face_site(game: Node2D,id: String) -> void:
	var sites=game.world.sites.filter(func(site):return site.id==id)
	assert(not sites.is_empty(),"The interaction site must exist: "+id)
	var site=sites[0]
	var targets=game.world.activation_cells(site)
	var directions={"up":Vector2i.UP,"down":Vector2i.DOWN,"left":Vector2i.LEFT,"right":Vector2i.RIGHT}
	for facing in directions:
		if site.cell+directions[facing] in targets and not game.world.blocked(game.Grid.center(site.cell)):
			game.state.player_position=game.Grid.center(site.cell)
			game.world.facing=facing
			return
	for target in targets:
		for facing in directions:
			var stand=target-directions[facing]
			if game.world.blocked(game.Grid.center(stand)): continue
			game.state.player_position=game.Grid.center(stand)
			game.world.facing=facing
			return
	assert(false,"The interaction must have an accessible facing tile: "+id)

static func grow_watered_days(state: RefCounted,days: int=3) -> void:
	var selected=state.inventory_selection
	var slot=state.selected_slot
	state.assign_active("primary","watering_can")
	for day in range(days):
		state.refill_water()
		for i in range(state.plots.size()):
			if state.plots[i].planted>=0 and not state.plots[i].watered and not state.ripe(i): state.tend(i)
		state.advance(1440-state.minute)
	state.inventory_selection=selected
	state.selected_slot=slot

static func finish_welcome(game: Node2D) -> void:
	while game.state.welcome_phase=="escorting": game._process(0.1)
	game.state.storage_transfer("cabinet",0)
	for task in game.state.house_tasks: game.tidy_farmhouse(task)
	game._process(8)
	while game.state.welcome_phase!="complete":
		if game.window_open: game.ui.modal_box.get_child(3).pressed.emit()
		else: game._process(0.25)
	game.leave_building()

static func await_visitors(game: Node2D) -> void:
	for i in range(1200):
		if game.state.welcome_phase!="arriving": return
		game._process(0.1)
	assert(false,"The visitors must reach the farmhouse on foot")
