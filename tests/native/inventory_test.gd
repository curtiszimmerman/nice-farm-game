extends SceneTree
const Game=preload("res://game.gd")
const State=preload("res://state.gd")
var failed=false
func check(value: bool,label: String) -> void:
	if value: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var s=State.new()
	preload("fixture.gd").tools(s)
	s.health=60
	s.energy=50
	s.mana=20
	s.turnips=2
	s.fish=1
	s.star_bulbs=1
	check(s.consume("turnips") and s.health==68 and s.energy==62 and s.turnips==1 and s.mana==20,"turnips restore health and energy and consume one item")
	check(s.consume("fish") and s.health==73 and s.energy==70 and s.fish==0,"silverfin restores a little health and energy")
	check(s.consume("star_bulbs") and s.mana==35 and s.health==73,"star bulbs restore mana")
	check(not s.consume("copper") and not s.consume("fish"),"materials and absent food cannot be eaten")
	s.health=99
	s.energy=99
	check(s.consume("turnips") and s.health==100 and s.energy==100,"food respects resource caps")
	s.turnips=1
	check(not s.consume("turnips") and s.turnips==1,"food is preserved when it cannot restore anything")
	s.star_seeds=1
	s.selected_seed="star_seeds"
	s.tend(0); s.tend(0); s.tend(0)
	preload("fixture.gd").grow_watered_days(s)
	s.tend(0)
	check(s.star_bulbs==1 and s.star_seeds==0,"star bulbs grow and harvest through the real farming system")
	check(s.accept_sword() and not s.accept_sword() and s.rusty_sword==1,"veteran sword can be accepted only once")
	var restored=State.new()
	check(restored.restore(s.to_dict()) and restored.rusty_sword==1 and restored.star_bulbs==1 and restored.health==100,"new supplies and health survive saving")
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game)
	game.state.turnips=2
	game.state.health=50
	game.state.energy=50
	game.inventory()
	check(game.ui.inventory_slots.size()==12,"satchel displays twelve inventory slots")
	var slot=null
	for button in game.ui.inventory_slots:
		if button.get_meta("item_id","")=="turnips": slot=button
	check(slot!=null and slot.tooltip_text.contains("Moon turnip") and slot.get_child(0).texture!=null,"item slots show pictures and hover details")
	slot.pressed.emit()
	check(game.state.turnips==2 and game.state.active_item()=="turnips","left-clicking food selects it without consuming it")
	var right_click=InputEventMouseButton.new()
	right_click.button_index=MOUSE_BUTTON_RIGHT
	right_click.pressed=true
	slot.gui_input.emit(right_click)
	game.ui.modal_box.get_child(3).pressed.emit()
	check(game.state.turnips==1 and game.state.health==58 and game.window_open,"the right-click Eat action consumes one and refreshes the satchel")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
