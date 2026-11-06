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
	for actor in w.villagers.values(): actor.visible=false
	for y in range(30,65):
		for x in range(40,85): w.solid_cells.erase(Vector2i(x,y))
	var start=Vector2i(45,45)
	var goal=Vector2i(75,45)
	w.route_profile={"calls":0,"max_us":0,"expanded":0,"actor":""}
	var path=w._route(start,goal,false,true)
	check(path.size()==30,"a clear NPC route keeps the shortest grid path")
	check(int(w.route_profile.get("radius",-1))==4 and w.route_profile.expanded<400,"NPC searches start in a nine-square corridor instead of flooding the map")
	for y in range(39,52): w.solid_cells[Vector2i(60,y)]="wall"
	w.route_profile={"calls":0,"max_us":0,"expanded":0,"actor":""}
	path=w._route(start,goal,false,true)
	check(not path.is_empty() and int(w.route_profile.get("radius",-1))>4,"the corridor widens when a real obstacle requires a detour")
	check(w.route_profile.expanded<=4096,"NPC searches obey a bounded expansion budget")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
