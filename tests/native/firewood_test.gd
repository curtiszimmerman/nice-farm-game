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
	var s=game.state
	var w=game.outdoors
	check(s.accept_firewood_task() and s.axe==0 and s.accept_tool("axe") and s.quick_slots.all(func(id): return id==""),"Oren's job uses Rowan's axe without assigning a quick slot")
	s.select_inventory("axe")
	var energy=s.energy
	for i in range(2):
		var candidates=w.trees.filter(func(tree): return not w.blocked(w.Grid.center(tree.cell+Vector2i.DOWN)))
		check(not candidates.is_empty(),"an accessible tree is available to chop")
		var tree=candidates[0]
		s.player_position=w.Grid.center(tree.cell+Vector2i.DOWN)
		w.facing="up"
		for j in range(3): preload("fixture.gd").activate(game)
		check(not w.solid_cells.has(tree.cell),"a felled tree releases its collision cell")
		preload("fixture.gd").activate(game)
	check(s.wood==6 and is_equal_approx(s.energy,energy-8.4),"six axe swings and collected logs yield six firewood for reduced energy")
	var saved=game.State.new()
	check(saved.restore(s.to_dict()) and saved.felled_trees==s.felled_trees,"tree felling and the firewood task survive saving")
	var rebuilt=game.World.new()
	rebuilt.state=saved
	root.add_child(rebuilt)
	check(rebuilt.trees.map(func(t): return t.cell)==w.trees.map(func(t): return t.cell),"reloading preserves both cleared trees and the remaining forest")
	check(s.deliver_firewood() and s.wood==0 and s.firewood_given and not s.deliver_firewood(),"Oren accepts six firewood and rewards the favor only once")
	rebuilt.queue_free()
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
