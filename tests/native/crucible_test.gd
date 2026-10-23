extends SceneTree
const State=preload("res://state.gd")
const Game=preload("res://game.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var s=State.new()
	check(s.has_method("learn_crucible"),"the smith can teach a crucible blueprint")
	if s.has_method("learn_crucible"):
		s.star_bulbs=9
		check(not s.learn_crucible() and s.star_bulbs==9,"the blueprint requires ten star bulbs without taking a partial payment")
		s.star_bulbs=10
		check(s.learn_crucible() and s.star_bulbs==0 and not s.learn_crucible(),"ten star bulbs buy permanent blueprint knowledge exactly once")
		check(s.quick_slots.all(func(id):return id==""),"learning a blueprint never assigns a quick slot")
		var cell=s.Grid.BUILD_AREA.position+Vector2i.ONE
		s.stones=9
		check(not s.build_crucible(cell),"building requires ten mined stone")
		s.stones=20
		check(not s.build_crucible(Vector2i(0,0)),"construction stays within the farmhouse building yard")
		check(s.build_crucible(cell) and s.stones==10 and not s.build_crucible(cell),"a crucible occupies one unique grid square and costs ten stone")
		s.copper=6
		check(s.start_smelting(0) and s.copper==4 and not s.start_smelting(0),"a batch consumes two ore and cannot be started twice")
		s.advance(29.9)
		check(s.crucibles[0].bars==0,"copper needs thirty game minutes in the crucible")
		s.advance(0.1)
		check(s.collect_copper_bar(0) and s.copper_bars==1 and not s.collect_copper_bar(0),"a finished batch yields exactly one copper bar")
		s.start_smelting(0)
		s.advance(30,true)
		check(s.crucibles[0].bars==0,"pausing the world also pauses smelting")
		s.advance(30)
		s.storage_transfer("chest",4,"copper_bars")
		for id in s.Items.CATALOG:
			if id!="copper_bars" and int(s.get(id))==0 and s.carried_slots()<12: s.set(id,1)
		check(not s.collect_copper_bar(0) and s.crucibles[0].bars==1,"a full satchel leaves the finished bar safely inside the crucible")
		s.storage_transfer("chest",5,"bread")
		check(s.collect_copper_bar(0),"the finished bar can be collected after making room")
		var loaded=State.new()
		check(loaded.restore(s.to_dict()) and loaded.crucibles==s.crucibles and loaded.crucible_known,"blueprints and placed crucibles survive saving")
		var bad=s.to_dict()
		bad.crucibles.append(bad.crucibles[0].duplicate())
		check(not loaded.restore(bad),"duplicate saved crucible footprints are rejected")
		bad=s.to_dict()
		bad.crucibles[0].x=0
		check(not loaded.restore(bad),"saved construction outside the building yard is rejected")
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	game.enter_building("ship")
	game.state.copper=3
	game.talk("vale")
	check(game.ui.modal_box.get_child(2).text.to_lower().contains("copper bars"),"Vale asks for refined bars rather than raw ore")
	game.ui.modal_box.get_child(3).pressed.emit()
	check(not game.state.delivered and game.state.copper==3,"raw ore cannot satisfy the crew-link repair")
	game.state.copper_bars=3
	game.talk("vale")
	game.ui.modal_box.get_child(3).pressed.emit()
	check(game.state.delivered and game.state.copper==3 and game.state.copper_bars==0,"Vale accepts three bars and leaves raw ore alone")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
