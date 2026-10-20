extends SceneTree
const Game=preload("res://game.gd")
const Interior=preload("res://interior.gd")
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
	var w=game.world
	w.refresh()
	await process_frame
	var scenery=w.scenery_layer.get_child(0)
	var count=scenery.draw_count
	var crops=w.crops.draw_count
	var player=w.player.draw_count
	for i in range(4):
		w.elapsed+=0.1
		game.state.player_position.x+=1
		w.refresh()
		await process_frame
	check(scenery.draw_count==count and w.crops.draw_count==crops,"moving and animation retain static scenery and unchanged crops")
	check(w.player.draw_count>player,"the moving layer updates independently")
	game.state.plots[0].tilled=true
	w.refresh()
	await process_frame
	check(w.crops.draw_count>crops,"farming invalidates the crop layer")
	game.enter_building("home")
	var home=game.world
	home.refresh()
	await process_frame
	var sofa=home.get_children().filter(func(node): return node is Interior.Furniture and node.item.kind=="sofa")[0]
	var bed=home.get_children().filter(func(node): return node is Interior.Furniture and node.item.kind=="bed")[0]
	var bed_draws=bed.draw_count
	count=sofa.draw_count
	for i in range(4): home.refresh(); await process_frame
	check(sofa.draw_count==count,"static farmhouse furniture is retained across frames")
	game.state.house_tasks.sofa=true
	home.refresh()
	await process_frame
	check(sofa.draw_count==count+1,"removing a cover redraws that furnishing once")
	check(bed.draw_count==bed_draws,"removing the sofa cover retains unrelated bed drawings")
	game.leave_building()
	game.enter_building("ship")
	var ship=game.world
	var console=ship.get_children().filter(func(node): return node is Interior.Furniture and node.item.kind=="console")[0]
	ship.refresh()
	await process_frame
	count=console.draw_count
	var display=console.get_child(0)
	var frames=display.draw_count
	for i in range(4): ship.elapsed+=0.2; ship.refresh(); await process_frame
	check(console.draw_count==count and display.draw_count>frames,"ship displays animate without redrawing their machine bodies")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
