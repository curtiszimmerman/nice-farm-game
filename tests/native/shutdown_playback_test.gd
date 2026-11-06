extends SceneTree
const Game=preload("res://game.gd")
var failed=false
var attempted=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func restart_audio(sound: Node) -> void:
	await create_timer(0.15).timeout
	sound.start()
	sound.play_battle("laser_hit")
	sound.play_spell("wildgrowth")
	sound.set_bridge_ambience(true,true)
	attempted=true
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	call_deferred("restart_audio",game.sound)
	await game.sound.shutdown()
	check(attempted,"real audio producers attempted playback during shutdown")
	check(not game.sound.active and game.sound.get_children().filter(func(node):return node is AudioStreamPlayer).all(func(player):return not player.playing),"shutdown rejects playback scheduled during audio cleanup")
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
