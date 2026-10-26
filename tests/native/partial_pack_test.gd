extends SceneTree
const Art=preload("res://art.gd")
const Game=preload("res://game.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var folder="res://../../internal/verification/partial-town-pack"
	DirAccess.make_dir_recursive_absolute(folder)
	DirAccess.copy_absolute("res://art/option3/sprites.png",folder+"/sprites.png")
	var baseline=Art.read_json("res://art/option2/sprites.json")
	var entries=Art.read_json("res://art/option3/sprites.json")
	for id in entries.keys():
		if not baseline.has(id) and id not in ["sign_smith","bee0"]: entries.erase(id)
	for record in [["sprites.json",entries],["pack.json",{"id":"partial-town","name":"Partial town extensions","tile_size":16,"atlas":"sprites.png","sprites":"sprites.json"}]]:
		var file=FileAccess.open(folder+"/"+record[0],FileAccess.WRITE)
		file.store_string(JSON.stringify(record[1]))
		file.close()
	check(Art.select_pack(folder+"/pack.json").is_empty(),"a player pack may supply only some optional town additions")
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	game.outdoors.refresh()
	await process_frame
	var bakery=game.outdoors.scenery_layer.get_children().filter(func(node):return node.kind=="building" and node.data.id=="bakery")[0]
	check(bakery.draw_count>0,"the town renders with independently optional signs and bee frames")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
