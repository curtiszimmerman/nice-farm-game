extends SceneTree

const State = preload("res://state.gd")
var failed = false
var count = 0

class IsolatedVisit extends "res://game.gd":
	var test_file = ""
	func save_path() -> String:
		return test_file

func check(condition: bool,description: String) -> void:
	if condition:
		count+=1
		print("PASS: "+description)
	else:
		failed=true
		push_error("FAIL: "+description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game=IsolatedVisit.new()
	game.test_file=ProjectSettings.globalize_path("res://../../internal/verification/save-test-%d.json" % Time.get_ticks_usec()).simplify_path()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	preload("fixture.gd").tools(game.state)
	game.testing=false
	game.state.money=91
	game.state.invited=true
	game.state.tend(0)
	game.state.tend(0)
	game.state.tend(0)
	check(game.save_visit(),"native save writes successfully inside isolated project path")
	check(FileAccess.file_exists(game.save_path()) and not FileAccess.file_exists(game.save_path()+".tmp"),"atomic save leaves final file without stray temporary file")
	game.state=State.new()
	game._load_visit()
	check(game.state.money==91 and game.state.invited and game.state.plots[0].watered,"native file load restores inventory story and planted crop")
	game.state.money=105
	check(game.save_visit(),"saving again replaces the previous save atomically")
	game.state=State.new()
	game._load_visit()
	check(game.state.money==105,"second save survives a fresh state load")
	game.enter_building("home")
	if game.window_open:
		while game.window_open: game.ui.modal_box.get_child(3).pressed.emit()
		game.enter_building("home")
	var standing=game.state.player_position
	game.begin_rest(240)
	game.save_visit()
	var sleeping_save=JSON.parse_string(FileAccess.get_file_as_string(game.save_path()))
	check(Vector2(sleeping_save.x,sleeping_save.y)==standing,"saving during sleep records the safe position beside the bed")
	game.resting=0
	var corrupt=FileAccess.open(game.save_path(),FileAccess.WRITE)
	corrupt.store_string("{broken save")
	corrupt.close()
	game._load_visit()
	check(game.saving_disabled,"invalid save disables automatic overwrite")
	check(not game.save_visit() and FileAccess.get_file_as_string(game.save_path())=="{broken save","invalid save remains untouched when saving is attempted")
	check(DirAccess.remove_absolute(game.save_path())==OK,"isolated test save is cleaned up")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	print("%d native persistence checks passed" % count)
	quit(1 if failed else 0)
