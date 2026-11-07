extends SceneTree
const Game=preload("res://game.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var s=preload("res://state.gd").new()
	s.pot=1
	s.berries=2
	s.sugar=1
	check(not s.cook("berry_preserves") and s.berries==2,"preserves need an empty jar and preserve partial ingredients")
	s.glass_jars=1
	check(s.cook("berry_preserves") and s.glass_jars==0 and s.berry_preserves==1,"preserves consume one empty jar")
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	check(game.sound.mix_for(720,"cave","summer").drips==0 and game.sound.mix_for(720,"mine","summer").drips==0,"cavern interiors have no dripping-water ambience")
	check(game.ui.quest_scroll.horizontal_scroll_mode==ScrollContainer.SCROLL_MODE_DISABLED,"the Crew Log never scrolls horizontally")
	var motion=preload("res://outdoor_motion.gd")
	game.state.day=29
	game.state.minute=1200
	motion.update(game.outdoors)
	check(motion.firefly_night(game.state) and not game.outdoors.ambient.fireflies.is_empty(),"summer evenings populate the woods with fireflies")
	game.state.minute=120
	check(not motion.firefly_night(game.state),"fireflies settle before the later half of the night")
	game.state.day=85
	game.state.minute=1200
	check(not motion.firefly_night(game.state),"winter evenings have no fireflies")
	game.state.day=1
	game.state.minute=720
	game.state.woodcutter_axe_given=true
	game.state.requests.axe_due=game.state.total()+1440*3
	var quest=game.ui.quest_lines().filter(func(q):return q.id=="axe_repayment")[0]
	check("within 3 days" in quest.description,"Rowan's quest shows the actual remaining days")
	preload("fixture.gd").tools(game.state)
	game.state.star_seeds=1
	game.state.assign_active("primary","star_seeds")
	game.state.plots[0].tilled=true
	game.state.plots[0].planted=-1
	game.state.player_position=game.Grid.center(game.state.plot_cell(0)+Vector2i.DOWN)
	game.outdoors.facing="up"
	check("star bulb" in game.outdoors.find_nearest().get("label","").to_lower(),"the planting prompt names the active seed's crop")
	game.enter_building("home")
	game.state.minute=1360
	game.begin_rest(480)
	game._process(480.0/90.0)
	check(not "same day" in game.ui.message.text,"rest completion does not claim an overnight sleep stayed on the same day")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
