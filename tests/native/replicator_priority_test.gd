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
	var quests=game.ui.quest_lines()
	check(quests.size()==1 and quests[0].title=="Find Chief Vale" and quests[0].tasks.size()==1 and quests[0].tasks[0].text=="Find and talk to Chief Vale.","a new crew starts only with finding Vale")
	game.state.needs.hardcore=true
	game.state.needs.without_water=0
	var reserve=game.state.ship_water
	game.drink_from_dispenser()
	check(game.state.ship_water==reserve,"full hydration never spends ship water")
	game.state.needs.without_water=60
	game.drink_from_dispenser()
	check(game.state.ship_water==reserve-1 and game.state.needs.without_water==0,"a thirsty player can still drink one supply")
	check(not game.save_path().ends_with("/first-landing.json"),"new journeys never overwrite the old repair-order save")
	preload("fixture.gd").explore(game,true)
	quests=game.ui.quest_lines()
	check(quests.any(func(q):return q.title=="Find Chief Vale" and q.complete),"talking to Vale completes the search quest")
	check(quests.any(func(q):return q.title=="Food and water for the long haul") and not quests.any(func(q):return q.title=="A quiet local signal"),"Vale first assigns food and water, with the commlink still undisclosed")
	var supplies=game.State.new()
	supplies.copper_bars=1
	check(not supplies.deliver_replicator_copper() and supplies.copper_bars==1,"an incomplete delivery never consumes copper")
	supplies.copper_bars=3
	check(supplies.deliver_replicator_copper() and supplies.copper_bars==1 and not supplies.deliver_replicator_copper(),"one repair takes exactly two bars and cannot be paid twice")
	for slot in supplies.ship_storage: slot.clear()
	supplies.ship_water=0
	supplies.advance(1440)
	check(supplies.crew_hungry_days==1 and supplies.ship_water==supplies.SHIP_WATER,"finishing after midnight does not retroactively feed Vale before the machine worked")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
