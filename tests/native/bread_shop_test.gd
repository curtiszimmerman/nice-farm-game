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
	game.state.met_mayor=true
	game.enter_building("bakery")
	game.talk("baker")
	game.ui.modal_box.get_children().filter(func(node):return node is Button and node.text=="Go on.")[0].pressed.emit()
	var dialogue_buttons=game.ui.modal_box.get_children().filter(func(node):return node is Button)
	var sale_option=dialogue_buttons.filter(func(button):return button.text=="What have you got for sale?")
	check(not sale_option.is_empty(),"Corin offers a single shop entry in his bakery dialogue")
	if not sale_option.is_empty(): sale_option[0].pressed.emit()
	var sale_buttons=game.ui.modal_box.get_children().filter(func(node):return node is Button)
	var bread_option=sale_buttons.filter(func(button):return button.text.contains("Fresh bread"))
	check(not bread_option.is_empty() and bread_option[0].icon!=null and bread_option[0].text.contains("crowns"),"the scrollable bakery list shows bread, price, and item icon")
	check(game.state.has_method("buy_bread"),"fresh bread can be purchased")
	if game.state.has_method("buy_bread"):
		var s=game.state
		s.money=20
		check(s.buy_bread() and s.money==14 and s.bread==1 and s.stock("bread")==19,"a fresh loaf costs six crowns and uses seasonal stock")
		s.Items.Art.option=1
		for id in ["bread","copper_bars","build_crucible"]:
			check(s.Items.icon(id).get_image().get_used_rect().size!=Vector2i.ZERO,"new item artwork remains visible with original artwork selected: "+id)
		s.Items.Art.option=2
		s.Items.textures.clear()
		s.energy=40
		check(s.consume("bread") and s.energy==60 and s.bread==0,"fresh bread restores twenty energy")
		s.money=0
		check(not s.buy_bread() and s.bread==0,"bread purchases cannot spend unavailable money")
		s.shop_remaining["bread"]=0
		game.talk("baker")
		var shop_entry=game.ui.modal_box.get_children().filter(func(node):return node is Button and node.text=="What have you got for sale?")
		if not shop_entry.is_empty(): shop_entry[0].pressed.emit()
		var unavailable=game.ui.modal_box.get_children().filter(func(node):return node is Button and node.text.contains("Out of stock"))
		check(not unavailable.is_empty() and not unavailable[0].disabled and unavailable[0].modulate.r<1.0,"out-of-stock offers stay visible, dimmed, and selectable")
		if not unavailable.is_empty(): unavailable[0].pressed.emit()
		check(game.ui.message.text.contains("Out of stock"),"selecting an empty seasonal offer explains the next delivery")
		s.day=29
		check(s.stock("bread")==20,"shop inventory refreshes at the next season")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
