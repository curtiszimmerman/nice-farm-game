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
		var carried=game.state.Items.CATALOG.keys().filter(func(id):return id not in ["berries","apples","ladder"]).slice(0,game.State.INVENTORY_SLOTS)
		for id in carried: game.state.set(id,1)
		check(not w.harvest_forage("berries",cell) and game.state.forage_harvests.is_empty(),"a full satchel leaves fruit and its regrowth timer untouched")
		for id in carried: game.state.set(id,0)
		check(w.harvest_forage("berries",cell) and game.state.berries==1,"spring berries can be gathered")
		check(not w.harvest_forage("berries",cell),"picked fruit cannot be gathered twice")
		game.state.day=7
		check(not w.harvest_forage("berries",cell),"fruit waits a full seven days")
		game.state.day=8
		check(w.harvest_forage("berries",cell),"berries replenish after seven days")
		game.state.day=29
		check(w.harvest_forage("berries",berries[1]) and not w.harvest_forage("apples",apples[0]),"summer keeps berries available while apples wait for autumn")
		game.state.day=57
		check(not w.harvest_forage("berries",cell) and w.harvest_forage("apples",apples[0]),"autumn offers apples and no berries")
		game.state.day=85
		check(not w.harvest_forage("apples",apples[1]),"winter offers no apples")
		var saved=game.state.to_dict()
		var restored=game.State.new()
		check(restored.restore(saved) and restored.forage_harvests==game.state.forage_harvests,"harvest timers survive a save and reload")
		var corrupt=saved.duplicate(true)
		corrupt.day="broken"
		check(not restored.restore(corrupt),"fruit saves with a corrupt calendar are rejected safely")
		corrupt=saved.duplicate(true)
		corrupt.forage_harvests[corrupt.forage_harvests.keys()[0]]=99999999
		check(not restored.restore(corrupt),"future harvest timestamps are rejected")
		game.state.day=57
		game.state.axe=1
		game.state.assign_active("primary","axe")
		for i in range(3):
			w.elapsed+=0.61
			w.chop_tree(apples[1])
		check(not w.harvest_forage("apples",apples[1]),"a felled tree cannot supply fruit before its sprite is freed")
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
