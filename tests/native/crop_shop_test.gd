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
	game.state.money=1000
	for id in preload("res://crop_art.gd").SEEDS:
		game.tavi_shop()
		var label=game.state.Items.CATALOG[id].name.to_lower()
		var button=game.ui.modal_box.find_children("*","Button",true,false).filter(func(b):return b.text.to_lower().contains(label))
		check(button.size()==1,"spring shop offers "+id)
		if not button.is_empty(): button[0].pressed.emit()
		check(game.state.get(id)==5,"buying the seed packet supplies "+id)
	game.state.day=29
	game.tavi_shop()
	var summer=game.ui.modal_box.find_children("*","Button",true,false)
	check(not summer.any(func(b):return b.text.contains("gladain") or b.text.contains("green onion")),"spring-only seeds leave the summer shop")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
