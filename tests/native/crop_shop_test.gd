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
	# Tavi sells the ordinary seeds; Widow Marsh's exotic ones are only in her curio shop.
	for id in preload("res://crop_art.gd").SEEDS.keys().filter(func(seed):return game.state.Shop.CATALOG.has(seed)):
		game.tavi_shop()
		var label=game.state.Items.CATALOG[id].name.to_lower()
		var button=game.ui.modal_box.find_children("*","Button",true,false).filter(func(b):return b.text.to_lower().contains(label))
		check(button.size()==1,"spring shop offers "+id)
		if not button.is_empty(): button[0].pressed.emit()
		check(game.state.get(id)==5,"buying the seed packet supplies "+id)
	game.tavi_shop()
	for i in range(3): await process_frame
	for purchase in range(3):
		if purchase==2: game.state.money=0
		var scroll=game.ui.modal_scroll
		scroll.scroll_vertical=int(scroll.get_v_scroll_bar().max_value)
		var position=scroll.scroll_vertical
		check(position>0,"the shop has a genuinely scrolling list")
		var buttons=game.ui.modal_box.find_children("*","Button",true,false).filter(func(b):return b.text.to_lower().contains("gladain seeds"))
		var before=game.state.gladain_seeds
		buttons[0].pressed.emit()
		for i in range(3): await process_frame
		check(game.state.gladain_seeds==before+(0 if purchase==2 else 5) and game.ui.modal_scroll.scroll_vertical==position,"purchases and insufficient funds preserve the shop scroll position")
	game.state.day=29
	game.tavi_shop()
	for i in range(3): await process_frame
	check(game.ui.modal_scroll.scroll_vertical==0,"opening a different seasonal listing starts at the top")
	var summer=game.ui.modal_box.find_children("*","Button",true,false)
	check(not summer.any(func(b):return b.text.contains("gladain") or b.text.contains("green onion")),"spring-only seeds leave the summer shop")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
