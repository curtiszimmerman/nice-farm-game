extends SceneTree
const Art=preload("res://art.gd")
var failed=false
func check(value: bool,label: String) -> void:
	if value: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func write_json(path: String,data: Dictionary) -> void:
	var file=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
func run() -> void:
	var art=Art.new()
	check(art.has_method("select_pack"),"artwork accepts player-provided pack manifests")
	if not art.has_method("select_pack"): quit(1); return
	check(art.call("select_pack","res://art/option2/pack.json").is_empty(),"default atlas is itself a selectable pack")
	var texture=Art.atlas
	check(not art.call("select_pack","res://art/missing/pack.json").is_empty() and Art.atlas==texture,"invalid packs leave the active artwork intact")
	var folder="res://../../internal/verification/test-pack16"
	DirAccess.make_dir_recursive_absolute(folder)
	var image=Art.pixels.duplicate()
	image.resize(ceili(image.get_width()/2.0),ceili(image.get_height()/2.0),Image.INTERPOLATE_NEAREST)
	image.save_png(folder.path_join("sprites.png"))
	var entries=Art.catalog.duplicate(true)
	for entry in entries.values():
		var rect=entry.rect
		entry.rect=[floor(rect[0]/2),floor(rect[1]/2),ceil(rect[2]/2),ceil(rect[3]/2)]
	write_json(folder.path_join("sprites.json"),entries)
	var manifest={"id":"fixture16","name":"16-pixel loader fixture","tile_size":16,"atlas":"sprites.png","sprites":"sprites.json"}
	write_json(folder.path_join("pack.json"),manifest)
	check(art.call("select_pack",folder.path_join("pack.json")).is_empty(),"a player-provided 16-pixel pack loads through the same interface")
	check(art.call("sprite_size","tile_grass0")==Vector2(32,32) and Art.region("tile_grass0").size==Vector2(16,16),"16-pixel atlas tiles keep 32-unit world geometry")
	check(art.call("tile_image","grass0").get_size()==Vector2i(32,32),"cached terrain tiles scale to the world grid")
	texture=Art.atlas
	entries.erase("tile_grass0")
	write_json(folder.path_join("sprites.json"),entries)
	check(not art.call("select_pack",folder.path_join("pack.json")).is_empty() and Art.atlas==texture,"missing required sprites cannot replace a working pack")
	entries=Art.catalog.duplicate(true)
	entries.tile_grass0.rect=[-1,0,16,16]
	write_json(folder.path_join("sprites.json"),entries)
	check(not art.call("select_pack",folder.path_join("pack.json")).is_empty() and Art.atlas==texture,"out-of-bounds regions cannot replace a working pack")
	quit(1 if failed else 0)
