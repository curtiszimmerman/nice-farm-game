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
	game.opening.finish()
	check(game.current_room=="ship_bridge" and not game.window_open,"the crash leaves the captain free to explore the upper bridge")
	if game.current_room=="ship_bridge":
		check(game.world.ROOM_CELLS==Vector2i(12,12),"the upper bridge occupies twelve by twelve squares")
		check(game.world.furnishings.filter(func(item):return item.kind=="ship_chair").size()==4,"the bridge has four spacecraft seats")
		check(game.world.animated_displays.size()>=4,"damaged displays surround the bridge")
		check(not game.world.villagers.vale.visible,"Vale remains downstairs in engineering")
		game.state.player_position=game.Grid.center(Vector2i(2,9))
		game.world.facing="up"
		game.interact()
		check(game.current_room=="ship" and not game.state.ship_departed,"bridge stairs descend internally without leaving the ship")
		game.talk("vale")
		check(game.window_open and game.ui.modal_box.get_child(2).text=="Status report?","the captain asks Vale for a report downstairs")
		while game.window_open: game.ui.modal_box.get_child(3).pressed.emit()
		game.state.player_position=game.Grid.center(Vector2i(2,9))
		game.world.facing="up"
		game.interact()
		check(game.current_room=="ship_bridge","the engineering stairs return to the bridge")
		check(not game.world._route(game.Grid.world_to_cell(game.state.player_position),Vector2i(6,6)).is_empty(),"the bridge stair landing opens onto a clear aisle")
		var saved=game.State.new()
		check(saved.restore(game.state.to_dict()) and saved.location=="ship_bridge","saving retains the upper deck location")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
