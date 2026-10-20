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
	preload("fixture.gd").explore(game,true)
	game.state.chest_transfer(0)
	game.inventory()
	check(game.ui.modal.mouse_filter==Control.MOUSE_FILTER_IGNORE,"inventory overlay lets drag events reach the quick bar")
	game.ui.inventory_slots[0].pressed.emit()
	check(game.window_open and game.state.active_item()=="hoe" and game.state.quick_slots.all(func(id):return id==""),"left click selects a carried item without assigning a quick slot or opening another menu")
	var target=game.ui.quick_buttons[3]
	check(target.has_method("_drop_data"),"quick slots accept inventory drag data")
	if target.has_method("_drop_data"):
		target.call("_drop_data",Vector2.ZERO,{"type":"inventory_item","id":"hoe"})
		check(game.state.quick_slots[3]=="hoe","dropping a carried tool assigns exactly the destination quick slot")
	game.state.welcome_phase="waiting"
	var click=InputEventMouseButton.new()
	click.pressed=true
	click.button_index=MOUSE_BUTTON_LEFT
	game._input(click)
	check(game.window_open,"intro click-to-continue does not dismiss the inventory during cleanup")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
