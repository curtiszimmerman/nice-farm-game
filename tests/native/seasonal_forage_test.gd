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
	var w=game.outdoors
	check(w.has_method("harvest_forage"),"outdoor fruit can be harvested")
	if w.has_method("harvest_forage"):
		var berries=w.forage_nodes.berries.keys()
		var apples=w.forage_nodes.apples.keys()
		var oaks=w.tree_population.filter(func(t):return w.Art.tree_species(t)=="oak").size()
		check(float(berries.size())/w.bushes.size()>=0.05 and float(berries.size())/w.bushes.size()<=0.1,"five to ten percent of bushes bear berries")
		check(float(apples.size())/oaks>=0.05 and float(apples.size())/oaks<=0.1,"five to ten percent of oaks bear apples")
		var cell=berries[0]
		check(w.harvest_forage("berries",cell) and game.state.berries==1,"spring berries can be gathered")
		check(not w.harvest_forage("berries",cell),"picked fruit cannot be gathered twice")
		game.state.day=7
		check(not w.harvest_forage("berries",cell),"fruit waits a full seven days")
		game.state.day=8
		check(w.harvest_forage("berries",cell),"berries replenish after seven days")
		game.state.day=57
		check(not w.harvest_forage("berries",cell) and w.harvest_forage("apples",apples[0]),"autumn offers apples and no berries")
		game.state.day=85
		check(not w.harvest_forage("apples",apples[1]),"winter offers no apples")
		var saved=game.state.to_dict()
		var restored=game.State.new()
		check(restored.restore(saved) and restored.forage_harvests==game.state.forage_harvests,"harvest timers survive a save and reload")
	game.state.minute=720
	check(not game.fish_pool("ocean_tip").has("lantern_ray"),"rare night fish are absent by day")
	game.state.minute=1260
	check(game.fish_pool("ocean_tip").has("lantern_ray"),"rare night fish visit the jetty after dark")
	game.Art.option=1
	game.state.Items.textures.clear()
	for id in ["berries","apples","ladder"]:
		check(game.state.Items.icon(id).get_image().get_used_rect().has_area(),"new carried item has visible art under original artwork: "+id)
	game.Art.option=2
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
