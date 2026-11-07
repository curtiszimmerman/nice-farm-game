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
	game.state.money=2000
	game.tavi_shop()
	var wallet=game.ui.get("shop_wallet")
	check(wallet!=null and wallet.visible,"shopping shows a separate crowns panel")
	if wallet!=null:
		var before=game.state.money
		var buy=game.ui.modal_box.get_children().filter(func(node):return node is Button and node.text.begins_with("Five moon-turnip"))[0]
		buy.pressed.emit()
		game.ui._process(0.08)
		check(game.state.money<before and game.ui.wallet_amount.text==game.crowns(game.state.money),"wallet displays the actual balance after buying")
		check(game.ui.wallet_amount.scale.x>1 and game.ui.wallet_amount.modulate!=Color.WHITE,"purchase pulses and enlarges the crowns amount")
		game.close_window()
		check(not wallet.visible,"wallet closes with the shop")
		game.tavi_shop()
		game.ui.modal_box.get_children().filter(func(node):return node is Button and node.text.begins_with("Five moon-turnip"))[0].button_down.emit()
		await create_timer(0.65).timeout
		check(game.ui.modal_box.get_child(0).text=="BUY QUANTITY" and wallet.visible,"the crowns panel stays visible while choosing a purchase quantity")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
