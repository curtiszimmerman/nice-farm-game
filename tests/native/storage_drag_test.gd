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
	game.open_storage("chest")
	var data={"type":"inventory_item","id":"seeds","storage":"chest","index":3}
	var destination=game.ui.inventory_slots[4]
	check(destination._can_drop_data(Vector2.ZERO,data),"empty carried slots accept an actual storage stack drag")
	if destination._can_drop_data(Vector2.ZERO,data):
		destination._drop_data(Vector2.ZERO,data)
		game.ui.quantity_control.value=3
		game.ui.modal_box.get_child(4).pressed.emit()
		check(game.state.seeds==3 and game.state.chest[3].count==5 and game.state.inventory_order[4]=="seeds","storage drag selects quantity and places it in the requested inventory slot")
		game.ui.chest_slots[5]._drop_data(Vector2.ZERO,{"type":"inventory_item","id":"seeds"})
		game.ui.quantity_control.value=2
		game.ui.modal_box.get_child(4).pressed.emit()
		check(game.state.seeds==1 and game.state.chest[5].count==2,"carried stacks drag back into a chosen chest slot with quantity")
		game.ui.inventory_slots[0]._drop_data(Vector2.ZERO,{"type":"inventory_item","id":"seeds"})
		check(game.state.inventory_order[0]=="seeds" and game.state.inventory_order[4]=="","inventory drags reorder a stack without duplicating it")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
