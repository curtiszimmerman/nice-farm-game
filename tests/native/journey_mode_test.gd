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
	if is_instance_valid(game.opening): game.opening.queue_free(); game.opening=null
	game.started=false
	game.state.needs.mode_chosen=false
	game.choose_journey_mode()
	check(not game.started and game.window_open,"journey mode is chosen before the intro starts")
	check(game.ui.hud_nodes.all(func(node):return not node.visible) and game.ui.modal.visible,"the journey choice shows no HUD over its backdrop")
	game.start_journey(true)
	check(game.started and game.state.needs.hardcore and game.state.needs.mode_chosen,"choosing hardcore begins the intro with survival enabled")
	game.state.needs.without_water=4320
	game.drink_freshwater()
	check(game.state.needs.without_water==0,"drinking freshwater fully restores hydration")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
