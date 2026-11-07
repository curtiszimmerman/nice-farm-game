extends SceneTree
const Game=preload("res://game.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")

func press(code: Key) -> void:
	var event=InputEventKey.new()
	event.physical_keycode=code
	event.keycode=code
	event.pressed=true
	root.push_input(event)

func world_view(game: Node2D) -> Vector2:
	return game.get_viewport().get_visible_rect().size/game.camera.zoom

func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	root.size=Vector2i(1280,720)
	await process_frame
	var zoom=game.camera.zoom
	var view=world_view(game)
	# A bigger window shows more of the world at the same zoom.
	root.size=Vector2i(1920,1080)
	await process_frame
	await process_frame
	check(game.camera.zoom==zoom,"resizing the window leaves the zoom alone")
	check(world_view(game).is_equal_approx(view*1.5),"a window half again as large shows half again as much of the world (%s → %s)" % [view,world_view(game)])
	var right_gap=1920-(game.ui.calendar_ring.position.x+game.ui.calendar_ring.size.x)
	check(right_gap>=0 and right_gap<40,"the calendar stays in the top-right corner of a larger window (gap %d)" % right_gap)
	var message_middle=game.ui.message_panel.position.x+game.ui.message_panel.size.x/2
	check(absf(message_middle-960)<2,"messages stay centred in a larger window")
	root.size=Vector2i(1280,720)
	await process_frame
	await process_frame
	check(world_view(game).is_equal_approx(view),"shrinking the window back shows the original view")
	# Zoom is a setting of its own, with hotkeys.
	press(KEY_EQUAL)
	await process_frame
	check(game.camera.zoom.x>zoom.x,"the zoom-in key zooms in")
	press(KEY_MINUS)
	press(KEY_MINUS)
	await process_frame
	check(game.camera.zoom.x<zoom.x,"the zoom-out key zooms out")
	var held=game.camera.zoom
	root.size=Vector2i(1600,900)
	await process_frame
	check(game.camera.zoom==held,"a chosen zoom survives a window resize")
	game.preferences()
	var zoom_in=game.ui.modal_box.get_children().filter(func(node):return node is Button and node.text.begins_with("Zoom in"))
	check(zoom_in.size()==1,"Settings offers a zoom control")
	if zoom_in.size()==1: zoom_in[0].pressed.emit()
	check(game.camera.zoom.x>held.x,"the Settings zoom control zooms in")
	game.close_window()
	var path=OS.get_user_data_dir().path_join("zoom_test_controls.cfg")
	game.controls.save(path)
	var reloaded=preload("res://controls.gd").new()
	reloaded.load_keys(path)
	check(is_equal_approx(reloaded.zoom,game.controls.zoom),"the chosen zoom is remembered with the other display preferences")
	DirAccess.remove_absolute(path)
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
