extends SceneTree

const Game = preload("res://game.gd")
var game: Node2D

func _initialize() -> void:
	call_deferred("run")

func capture(label: String) -> void:
	game.ui.message.text=""
	game.world.update_villagers(0.0,true)
	game.nearest=game.world.find_nearest()
	game.world.refresh()
	game.camera.position=game.state.player_position+Vector2(20,-5)
	game.ui.update()
	for i in range(10):
		game.world.refresh()
		await process_frame
	await RenderingServer.frame_post_draw
	var path=ProjectSettings.globalize_path("res://../../internal/verification/native-"+label+".png").simplify_path()
	var image=root.get_texture().get_image()
	assert(image.save_png(path)==OK,"Screenshot must stay in the project")
	print("Captured native ",label)

func run() -> void:
	game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	game.world.elapsed=2.0
	game.ui.message.text=""
	await capture("farm")
	game.ui.show_title()
	await capture("title")
	game.ui.title_screen.queue_free()
	game.ui.title_screen=null
	for i in range(12):
		game.state.tend(i)
		game.state.tend(i)
		game.state.tend(i)
	game.state.advance(180.0)
	game.state.player_position=game.world.plot_position(12)+Vector2(0,32)
	await capture("garden")
	game.state.player_position=game.world.Grid.center(game.world.PEOPLE[0].cell)+Vector2(0,20)
	game.talk("moss")
	await capture("conversation")
	game.close_window()
	game.settings()
	await capture("settings")
	game.close_window()
	game.development_tools()
	await capture("development-tools")
	game.close_window()
	game.state.player_position=game.world.Grid.center(game.world.SQUARE.position+Vector2i(5,2))
	await capture("town")
	game.state.minute=0.0
	await capture("evening")
	game.state.minute=840.0
	game.state.player_position=game.world.Grid.center(Vector2i(64,12))
	await capture("wizard-mountains")
	game.state.minute=720.0
	game.state.player_position=game.world.Grid.center(Vector2i(13,36))
	await capture("behind-house")
	game.state.player_position=game.world.trees[0].pos-Vector2(0,45)
	await capture("behind-tree")
	game.state.player_position=game.world.plot_position(6)
	game.world.facing="right"
	game.world.find_nearest()
	await capture("forward-target")
	game.state.player_position=game.world.site_position("ore")
	await capture("outcrop")
	game.state.player_position=game.world.site_position("radio")+Vector2(0,32)
	await capture("radio-table")
	game.state.player_position=game.world.site_position("pond")
	await capture("dock")
	game.state.player_position=game.world.Grid.center(game.world.SHIP_CELL)+Vector2(64,64)
	await capture("ship")
	game.state.turnips=4
	game.state.star_bulbs=2
	game.state.star_seeds=3
	game.state.fish=2
	game.state.copper=3
	game.state.accept_sword()
	game.inventory()
	await capture("inventory")
	game.close_window()
	game.enter_building("home")
	game.state.player_position=game.world.entry_position()
	await capture("interior-living")
	game.state.player_position=game.world.site_position("bed")
	await capture("interior-bedroom")
	game.state.player_position=game.world.Grid.center(Vector2i(10,9))
	await capture("interior-kitchen-bath")
	game.leave_building()
	game.state.invited=true
	game.state.met_mayor=true
	game.state.minute=600
	game.outdoors.update_villagers(0.0,true)
	game.enter_building("radio")
	game.state.player_position=game.world.site_position("radio")+Vector2(32,0)
	await capture("interior-radio-club")
	game.leave_building()
	for id in ["moss","finch","tavi","mayor","veteran","iona","store","hall"]:
		game.enter_building(id)
		game.state.player_position=game.world.entry_position()
		await capture("interior-"+id)
		game.leave_building()
	game.enter_building("store")
	game.leave_building()
	await capture("store-exit")
	game.state.player_position=game.world.Grid.center(game.world.MOSS_FIELDS.position+Vector2i(3,2))
	await capture("moss-fields")
	game.state.player_position=game.world.Grid.center(Vector2i(42,81))
	await capture("veteran-cabin")
	game.sound_settings()
	await capture("sound-settings")
	assert(game.sound.music.playing,"Native music should play")
	game.sound.play_spell("wildgrowth")
	await game.sound.shutdown()
	print("NATIVE VISUAL CHECKS PASSED; sound start/stop passed")
	game.queue_free()
	await process_frame
	quit()
