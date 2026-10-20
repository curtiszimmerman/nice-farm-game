extends SceneTree
const State=preload("res://state.gd")
const Game=preload("res://game.gd")
var failed=false
func check(value: bool,label: String) -> void:
	if value: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var s=State.new()
	check(s.chest.size()==18 and s.hoe==0,"starter tools begin in the eighteen-slot farmhouse chest")
	s.tend(0)
	check(not s.plots[0].tilled and s.energy==100,"tilling requires a carried hoe")
	for i in range(3): s.chest_transfer(i)
	s.chest_transfer(3)
	s.quick_slots[1]="watering_can"
	s.selected_slot=1
	s.refill_water()
	check(s.hoe==1 and s.watering_can==1 and s.sickle==1,"tools can be taken from the chest")
	s.tend(0)
	s.tend(0)
	s.watering_can=0
	var energy_before=s.energy
	s.tend(0)
	check(not s.plots[0].watered and s.energy==energy_before,"watering requires its tool without wasting energy")
	s.watering_can=1
	s.tend(0)
	s.advance(4320)
	s.sickle=0
	s.tend(0)
	check(s.ripe(0) and s.harvested==0,"harvesting requires a carried sickle")
	s=State.new()
	preload("fixture.gd").tools(s)
	s.seeds=80
	for cycle in range(2):
		for i in range(20):
			if cycle==0: s.tend(i)
			s.tend(i)
			s.tend(i)
		s.advance(4320)
		for i in range(20): s.tend(i)
		if cycle==0: s.water=20
	check(s.energy==0 and s.harvested==20 and s.total()==9180,"doubled farming costs exhaust energy during the second full-field harvest")
	var before=s.plots.duplicate(true)
	s.tend(1)
	s.tend(1)
	check(s.plots==before and s.energy==0,"exhaustion prevents work without spending unavailable energy")
	s.advance(240)
	check(s.energy==0,"passing time never restores energy")
	check(s.chest_transfer(0,"hoe") and s.hoe==0 and s.chest[0].id=="hoe","carried items can be deposited into a chosen chest slot")
	s.fish=2
	check(s.chest_transfer(0,"fish") and s.fish==0 and s.hoe==1 and s.chest[0].count==2,"occupied chest slots can swap whole stacks with carried items")
	var restored=State.new()
	check(restored.restore(s.to_dict()) and restored.chest[0].id=="fish" and restored.hoe==1,"chest contents and tools survive saving")
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game)
	game.state.player_position=game.world.site_position("chest")+Vector2(0,32)
	game.interact()
	check(game.window_open and game.ui.chest_slots.size()==18,"E opens the farmhouse chest's eighteen slots")
	game.ui.chest_slots[0].pressed.emit()
	check(game.state.hoe==1,"the real chest interface withdraws a tool")
	game.close_window()
	game.enter_building("moss")
	game.rest_options()
	check(not game.window_open and game.resting==0,"other residents' beds cannot restore player energy")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
