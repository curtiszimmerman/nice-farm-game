extends "visual_test.gd"

func run() -> void:
	prefix="crafting-"
	game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	game.state.met_mayor=true
	for task in game.state.house_tasks: game.state.house_tasks[task]=true
	game.state.minute=600
	game.outdoors.update_villagers(0,true)
	game.enter_building("bakery")
	game.talk("baker")
	await capture("bread-offer")
	game.ui.modal_box.get_child(3).pressed.emit()
	assert(game.state.bread==1 and game.state.money==18,"Corin's actual purchase button sells one loaf")
	game.close_window()
	game.state.awake_minutes=1441
	game.state.energy=10
	game.item_options("bread")
	game.ui.modal_box.get_child(3).pressed.emit()
	assert(game.state.bread==0 and game.state.energy==20,"the Eat action halves bread energy while tired")
	game.close_window()
	game.leave_building()
	game.enter_building("cave")
	game.close_window()
	game.state.player_position=game.world.spider.position+Vector2(50,20)
	await capture("spider-guard")
	game.world.combat_rng.seed=12345
	game.state.player_position=game.world.spider.position+Vector2(0,20)
	for i in range(50):
		if game.state.status_effects.has("poison"): break
		game.world.spider.info.bite=0
		game.world.update_enemies(0.01)
	assert(game.state.status_effects.has("poison"),"live spider attacks apply poison")
	game.state.player_position=game.world.spider.position+Vector2(50,20)
	await capture("poison-and-tired")
	for i in range(25): await process_frame
	await capture("poison-eyes-pulse")
	game.leave_building()
	game.enter_building("home")
	game.begin_rest(360)
	for i in range(4): game._process(1)
	assert(not game.state.is_tired() and game.resting==0 and not game.state.status_effects.has("poison"),"six hours asleep clears tiredness while poison expires on its own clock")
	game.leave_building()
	game.state.star_bulbs=10
	game.state.stones=10
	game.state.copper=6
	game.enter_building("smithy")
	game.talk("smith")
	await capture("blueprint-offer")
	game.ui.modal_box.get_child(3).pressed.emit()
	assert(game.state.crucible_known and game.state.star_bulbs==0,"Dain's actual trade teaches the blueprint for ten star bulbs")
	await capture("blueprint-learned")
	game.ui.modal_box.get_child(3).pressed.emit()
	game.leave_building()
	await drag_inventory_item("build_crucible",-1,"primary")
	await capture("blueprint-assigned")
	game.close_window()
	var cell=game.Grid.BUILD_AREA.position+Vector2i(2,2)
	game.state.player_position=game.Grid.center(cell+Vector2i.LEFT)
	game.world.facing="right"
	await capture("placement-preview")
	game.interact()
	assert(game.state.crucibles.size()==1 and game.state.stones==0 and game.world.blocked(game.Grid.center(cell)),"the selected blueprint builds a solid one-square crucible")
	game.state.assign_active("primary","")
	await capture("built-crucible")
	for batch in range(3):
		game.interact()
		if batch==0: await capture("smelting-menu")
		game.ui.modal_box.get_child(3).pressed.emit()
		game.close_window()
		if batch==0: await capture("hot-crucible")
		game._process(30)
		game.interact()
		if batch==0: await capture("bar-ready")
		game.ui.modal_box.get_child(3).pressed.emit()
		game.close_window()
	assert(game.state.copper_bars==3 and game.state.copper==0,"three actual smelting batches refine six ore into three bars")
	game.inventory()
	await capture("copper-bar-inventory")
	game.close_window()
	game.enter_building("ship")
	game.talk("vale")
	await capture("vale-copper-bars")
	game.ui.modal_box.get_child(3).pressed.emit()
	assert(game.state.delivered and game.state.copper_bars==0,"Vale accepts the bars produced during this native playthrough")
	game.leave_building()
	preload("fixture.gd").face_site(game,"sign")
	await capture("crossroads-sign")
	game.interact()
	await capture("crossroads-directions")
	print("NATIVE CRAFTING VISUAL CHECKS PASSED: bread, statuses, blueprint drag, construction, smelting and repair")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
