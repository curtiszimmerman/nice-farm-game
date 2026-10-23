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
	check(game.ui.modal_box.get_children().any(func(node):return node is Button and node.text.to_lower().contains("buy fresh bread")),"Corin offers fresh bread in his bakery")
	check(game.state.has_method("buy_bread"),"fresh bread can be purchased")
	if game.state.has_method("buy_bread"):
		var s=game.state
		s.money=20
		check(s.buy_bread() and s.money==14 and s.bread==1,"a fresh loaf costs six crowns")
		s.energy=40
		check(s.consume("bread") and s.energy==60 and s.bread==0,"fresh bread restores twenty energy")
		s.money=0
		check(not s.buy_bread() and s.bread==0,"bread purchases cannot spend unavailable money")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
