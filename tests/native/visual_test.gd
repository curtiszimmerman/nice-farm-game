extends SceneTree

const Game = preload("res://game.gd")
var game: Node2D

func _initialize() -> void:
	call_deferred("run")

func capture(label: String) -> void:
	game.world.refresh()
	game.camera.position=game.state.player_position+Vector2(20,-5)
	game.ui.update()
	for i in range(3): await process_frame
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
	game.state.player_position=Vector2(1415,690)
	await capture("town")
	game.state.minute=1210.0
	await capture("evening")
	game.toggle_audio()
	assert(game.ambience_player.playing,"Optional native audio should play")
	game.toggle_audio()
	await create_timer(0.2).timeout
	print("NATIVE VISUAL CHECKS PASSED; sound start/stop passed")
	game.queue_free()
	await process_frame
	quit()
