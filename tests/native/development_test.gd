extends SceneTree

const Game = preload("res://game.gd")
const State = preload("res://state.gd")
const SEASON_DAYS = State.DEVELOPMENT_SEASON_DAYS
var failed = false
var count = 0

func check(value: bool,description: String) -> void:
	if value:
		count+=1
		print("PASS: "+description)
	else:
		failed=true
		push_error("FAIL: "+description)

func key(code: int,pressed: bool) -> void:
	var event=InputEventKey.new()
	event.physical_keycode=code
	event.keycode=code
	event.pressed=pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game)
	preload("fixture.gd").tools(game.state)
	var start=Vector2.INF
	for cell in game.world.road_cells:
		var candidate=game.Grid.center(cell)
		if game.world.blocked(candidate) or game.world.blocked(candidate+Vector2(32,0)): continue
		if game.world.villagers.values().any(func(actor):return actor.visible and actor.position.distance_to(candidate)<64): continue
		start=candidate
		break
	check(start!=Vector2.INF,"speed checks use a clear stretch of the generated road network")
	game.state.player_position=start
	key(KEY_D,true)
	game._move(0.02)
	check(is_equal_approx(game.state.player_position.x,start.x+6.3),"development walking is three times normal speed")
	key(KEY_SHIFT,true)
	game._move(0.02)
	check(is_equal_approx(game.state.player_position.x,start.x+15.9),"development running is three times normal speed")
	var accessible=game.world.trees.filter(func(tree):return not game.world.blocked(tree.pos-Vector2(17,0)))
	var trunk=accessible[0].pos
	game.state.player_position=trunk-Vector2(17,0)
	game._move(0.05)
	check(game.state.player_position.x<trunk.x and not game.world.blocked(game.state.player_position),"fast development movement cannot tunnel through thin tree trunks")
	key(KEY_D,false)
	key(KEY_SHIFT,false)
	game.state.pause_mode="all"
	game.state.tend(0)
	game.state.tend(0)
	game.state.tend(0)
	game.state.tend(0)
	game.development_tools()
	for option in [[3,60.0],[4,720.0],[5,1440.0],[6,SEASON_DAYS*1440.0]]:
		var before=game.state.total()
		game.ui.modal_box.get_child(option[0]).pressed.emit()
		check(is_equal_approx(game.state.total()-before,option[1]),"development menu advances exactly %d minutes even in full pause" % option[1])
	var first_plot_survived=game.state.plots.any(func(plot):return plot.x==9 and plot.y==54 and plot.planted>=0)
	check(not first_plot_survived,"time jumps do not mature a crop across skipped dry days")
	check(game.state.season_name()=="summer" and game.world.audio_context(game.state.player_position).season=="summer","season jump updates calendar and environmental audio together")
	game.state.day=SEASON_DAYS*4+1
	check(game.state.season_name()=="spring" and game.state.calendar_year()==2,"development calendar wraps seasons into a new year")
	game.close_window()
	game.ui.update()
	check(game.ui.date.text=="01" and game.ui.season_word.text=="SPRING","calendar displays the day beside its separate season label")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	print("%d development checks passed" % count)
	quit(1 if failed else 0)
