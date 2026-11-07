extends SceneTree
# Saves the baked west-coast ground (grass, beach and ocean edges) as a PNG, so shoreline art can be
# reviewed without a display. Used by scripts/coast_preview.py; run it through that script.
#   bash scripts/play.sh --headless --script ../../scripts/coast_dump.gd -- <output.png> [season] [weather]
const Game=preload("res://game.gd")
const Coast=preload("res://coast.gd")

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var args=OS.get_cmdline_user_args()
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("res://../../tests/native/fixture.gd").explore(game,true)
	if args.size()>1: game.state.day=1+["spring","summer","autumn","winter"].find(args[1])*28
	if args.size()>2: game.state.weather_override=args[2]
	game.outdoors.rebuild_visit(game.state)
	var image: Image=Coast.build_connected_image(game.outdoors)
	var error=image.save_png(args[0])
	print("Saved coast to ",args[0]," (error ",error,") seed ",game.state.world_seed)
	await game.sound.shutdown()
	game.queue_free()
	quit(0 if error==OK else 1)
