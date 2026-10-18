extends SceneTree

const Game = preload("res://game.gd")
var game: Node2D

func _initialize() -> void:
	call_deferred("run")

func capture(label: String) -> void:
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
	game.state.player_position=Vector2(670,840)
	await capture("garden")
	game.state.player_position=Vector2(880,708)
	game.talk("moss")
	await capture("conversation")
	game.close_window()
	game.settings()
	await capture("settings")
	game.close_window()
	game.development_tools()
	await capture("development-tools")
	game.close_window()
	game.state.player_position=Vector2(1415,690)
	await capture("town")
	game.state.minute=0.0
	await capture("evening")
	game.state.minute=720.0
	game.state.player_position=Vector2(725,460)
	await capture("behind-house")
	game.state.player_position=game.world.trees[0].pos-Vector2(0,45)
	await capture("behind-tree")
	game.state.player_position=game.world.plot_position(6)
	game.world.facing="right"
	game.world.find_nearest()
	await capture("forward-target")
	game.state.player_position=Vector2(1585,1030)
	await capture("outcrop")
	game.sound_settings()
	await capture("sound-settings")
	assert(game.sound.music.playing,"Native music should play")
	game.sound.play_spell("wildgrowth")
	await game.sound.shutdown()
	print("NATIVE VISUAL CHECKS PASSED; sound start/stop passed")
	game.queue_free()
	await process_frame
	quit()
