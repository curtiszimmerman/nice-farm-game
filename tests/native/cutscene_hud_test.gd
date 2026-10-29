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
	preload("fixture.gd").explore(game,true)
	await process_frame
	check(game.ui.quick_tray.get_global_rect().size.y<84.48,"status bar keeps its compact height")
	game.dialog("Alder","A VISIT","A moment of your time.")
	game.ui.update()
	check(not game.ui.quick_tray.visible and not game.ui.calendar_ring.visible and not game.ui.log_panel.visible and not game.ui.region.visible,"dialogue cutscenes hide all ordinary HUD information")
	check(game.ui.modal.visible,"cutscene dialogue remains visible while the HUD is hidden")
	game.close_window()
	game.ui.update()
	check(game.ui.quick_tray.visible and game.ui.calendar_ring.visible,"the HUD returns after the cutscene")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
