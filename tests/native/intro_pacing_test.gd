extends SceneTree
const Game=preload("res://game.gd")
var failed=false
func check(value: bool,label: String) -> void:
	if value: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	var intro=game.opening
	intro.set_process(false)
	check(intro.has_method("bridge_composition"),"the bridge exposes its window and captain placement")
	if intro.has_method("bridge_composition"):
		var bridge=intro.bridge_composition()
		check(bridge.window.encloses(bridge.planet),"the planet stays completely inside a bridge window")
		check(bridge.captain.size.x>=150 and bridge.captain.size.y>=300,"the seated captain reads at three times the old scale")
		check(bridge.has("sky") and bridge.window.encloses(bridge.sky) and bridge.sky.encloses(Rect2(920,132,140,105)),"the damaged bridge covers the old planet painted into its window")
		check(bridge.has("left_display") and bridge.left_console.encloses(bridge.left_display) and bridge.right_console.encloses(bridge.right_display),"screen flicker stays on the console displays")
	check(intro.has_method("bridge_spark_positions"),"bridge sparks use positions confined to the consoles")
	if intro.has_method("bridge_spark_positions"):
		var bridge=intro.bridge_composition()
		var spark_points=[]
		for frame in range(24): spark_points.append_array(intro.bridge_spark_positions(frame))
		check(not spark_points.is_empty() and spark_points.all(func(point):return (bridge.left_console.encloses(Rect2(point,Vector2(28,28))) or bridge.right_console.encloses(Rect2(point,Vector2(28,28)))) and not bridge.captain.intersects(Rect2(point,Vector2(28,28)))),"random sparks stay on consoles and away from the captain")
	intro._process(100)
	check(game.opening==intro and intro.elapsed<3,"the first introduction caption waits indefinitely for acknowledgement")
	check(intro.get("animation_time")!=null,"cinematic animation has its own clock while captions wait")
	if intro.get("animation_time")!=null:
		var animation=intro.get("animation_time")
		intro._process(1)
		check(intro.get("animation_time")>animation and intro.elapsed<3,"stars and ships keep moving while the player reads")
	var key=InputEventKey.new()
	key.pressed=true
	key.physical_keycode=KEY_SPACE
	game._input(key)
	check(not game.world_paused and intro.elapsed>=3,"space advances intro dialogue instead of pausing it")
	check(intro.has_method("shots_at"),"battle shots have individual launch and impact times")
	if intro.has_method("shots_at"):
		check(intro.call("shots_at",8.4).is_empty(),"clustered battle volleys leave a readable pause between bursts")
	for i in range(5): intro.advance()
	intro._process(100)
	check(intro.has_method("whiteout_alpha"),"the crash fade has an explicit acknowledgement gate")
	if intro.has_method("whiteout_alpha"): check(intro.call("whiteout_alpha")==0,"the brace-for-impact line remains visible until acknowledged")
	intro.finish()
	var before=game.ui.modal_box.get_child(2).text
	key.physical_keycode=KEY_E
	game._input(key)
	check(game.ui.modal_box.get_child(2).text==before,"briefing dialogue with a Continue button ignores E")
	game.ui.modal_box.get_child(3).pressed.emit()
	check(game.ui.modal_box.get_child(2).text!=before,"briefing dialogue advances through its Continue button")
	game.close_window(true)
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
