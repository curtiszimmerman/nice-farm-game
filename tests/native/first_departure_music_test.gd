extends SceneTree
const Game=preload("res://game.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	game.sound.choose_music("auto")
	game.opening.finish()
	for i in range(120): game._process(1.0/60)
	check(game.sound.music.volume_db<=-70,"the initial wreck remains musically silent")
	game.sound.music.seek(game.sound.music.stream.get_length()-0.05)
	for i in range(30): await process_frame
	check(not game.sound.music.playing,"a muted song can finish during the initial ship visit")
	preload("fixture.gd").reach_vale(game)
	while game.window_open: game.ui.modal_box.get_child(3).pressed.emit()
	game.leave_building()
	for i in range(180):
		game._process(1.0/60)
		await process_frame
	check(game.sound.music.playing and game.sound.music.volume_db>-20 and game.sound.music_tracks.get(game.sound.music_track,{}).get("theme","") in ["spring","rain"],"the first ship exit starts audible outdoor music")
	print("MUSIC TRACE: ",game.sound.music_track," playing=",game.sound.music.playing," fade=",game.sound.music_fade," cinematic=",game.sound.cinematic)
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
