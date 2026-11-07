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
	preload("fixture.gd").explore(game,true)
	game.state.met_mayor=true
	var world=game.outdoors
	var names={}
	for person in world.people: names[person.id]=person.name
	check(names.get("widow")=="Celandine Marsh" and names.get("herbalist")=="Sorrel Ashby","Celandine Marsh and Sorrel Ashby live in Briar Glen")
	check(["widow","herbalist"].all(func(id):return game.Art.catalog.has("actor_%s_down0" % id) and game.Art.catalog.has("actor_%s_sleep0" % id)),"both have their own sprites")
	game.state.day=2
	game.state.minute=600.0
	check(world.stop_for("widow").room=="widow" and world.stop_for("herbalist").room=="herbalist","both mind their shops through the working day")
	game.state.minute=1400.0
	check(world.stop_for("widow").sleeping and world.stop_for("widow").room=="widow" and world.stop_for("herbalist").sleeping and world.stop_for("herbalist").room=="herbalist","both sleep at home")
	game.state.minute=420.0
	var foraging=world.stop_for("herbalist")
	check(foraging.room=="" and foraging.cell.x<45,"Sorrel spends early mornings gathering in the woods")
	game.state.weather_override="rainy"
	check(world.stop_for("herbalist").room=="herbalist","but not in the rain")
	game.state.weather_override="sunny"
	game.state.minute=600.0
	world.update_villagers(0,true)
	for id in ["widow","herbalist"]:
		var greeting=preload("res://npc_greetings.gd").LINES.get(id,"")
		check(greeting!="" and preload("res://npc_greetings.gd").REPLIES.has(id),"%s has a first-meeting greeting" % names[id])
		check(preload("res://neighbors.gd").STORIES.has(id) and preload("res://neighbors.gd").OFF_DUTY.has(id),"%s has a life story and an off-duty line" % names[id])
	check("Edwin" in preload("res://neighbors.gd").STORIES.widow and "Veyr" in preload("res://neighbors.gd").STORIES.widow,"Celandine talks about her late husband's trading and her friends in Veyr")
	check("mushroom" in preload("res://neighbors.gd").STORIES.herbalist,"Sorrel talks about what grows in the woods")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
