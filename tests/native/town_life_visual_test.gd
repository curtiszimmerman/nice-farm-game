extends "visual_test.gd"
func run() -> void:
	prefix="town-life-"
	game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	game.state.met_mayor=true
	game.state.minute=780
	game.state.weather_override="sunny"
	preload("fixture.gd").tools(game.state)
	game.state.fishing_pole=1
	game.state.learned_spells=["hearthmend","emberthread"]
	game.inventory()
	await capture("inventory")
	var slots=game.ui.inventory_slots
	await drag_controls(slots[0],slots[9])
	game.close_window()
	await press_key(KEY_TAB)
	if game.state.quick_row!=1:
		failed=true
		push_error("FAIL: native Tab did not cycle the inventory row")
	game.state.player_position=game.Grid.center(Vector2i(17,45))
	game.world.facing="up"
	for pack in ["option2","option3","option2","option3"]: game.change_art_pack("res://art/"+pack+"/pack.json")
	game.state.player_position=game.Grid.center(Vector2i(90,70))
	await capture("away-from-chest")
	game.state.player_position=game.Grid.center(Vector2i(17,45))
	game.world.facing="up"
	await capture("chest-after-pack-changes")
	game.open_storage("chest")
	await capture("storage-rows")
	game.close_window()
	game.state.player_position=game.Grid.center(Vector2i(53,59))
	await capture("temple-garden")
	for id in ["temple","priest","assistant","mayor","finch"]:
		game.enter_building(id)
		await capture(id)
		game.leave_building()
	game.state.player_position=game.Grid.center(Vector2i(72,47))
	await capture("store-sign")
	game.state.player_position=game.Grid.center(Vector2i(79,50))
	await capture("smith-sign")
	game.state.player_position=game.Grid.center(Vector2i(75,67))
	await capture("baker-sign")
	game.state.minute=1200
	game.outdoors.update_villagers(0,true)
	game.enter_building("tavern")
	await capture("evening-tavern")
	game.leave_building()
	game.state.minute=780
	game.enter_building("cave")
	game.close_window()
	await capture("cave-entrance")
	game.change_cave_level(1)
	await capture("cave-stairs")
	game.change_cave_level(1)
	game.state.player_position=game.world.spider.position+Vector2(0,70)
	await capture("chrysalis-guardian")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
