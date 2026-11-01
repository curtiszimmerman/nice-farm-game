extends SceneTree
const Art=preload("res://art.gd")
const Items=preload("res://items.gd")
const State=preload("res://state.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func pixels(id: String) -> PackedByteArray:
	return Art.pixels.get_region(Rect2i(Art.region(id))).get_data()
func run() -> void:
	Art.select_pack("res://art/option3/pack.json")
	var placeholder=pixels("item_fish")
	var placeholders=Items.CATALOG.keys().filter(func(id):return id!="fish" and Art.catalog.has("item_"+id) and pixels("item_"+id)==placeholder)
	check(placeholders.is_empty(),"every item has its own icon instead of the stand-in fish: %s" % [placeholders])
	check(Items.icon("tomatoes") is AtlasTexture and Items.icon("gladain_seeds") is AtlasTexture,"new crop and seed icons come from the art pack when it has them")
	var plants=[]
	for crop in State.CROPS:
		for ripe in [false,true]:
			var id=Art.plant_overlay(crop,ripe)
			check(Art.catalog.has(id),"%s has a %s field sprite" % [crop,"ripe" if ripe else "growing"])
			plants.append(id)
	check(Art.plant_overlay("turnips",true)=="plant_overlay_turnip" and Art.plant_overlay("star_bulbs",true)=="plant_overlay_bulb","turnips and star bulbs keep their original field sprites")
	var unique={}
	for id in plants.slice(4): unique[id]=true
	check(unique.size()==8,"each new crop looks different while growing and when ripe")
	var styles={}
	for b in preload("res://world.gd").BUILDINGS+preload("res://neighbors.gd").BUILDINGS: styles[Art.roof_style(b)]=true
	check(styles.size()>=4,"the town uses at least four roof styles: %s" % [styles.keys()])
	for style in styles:
		for part in ["roof","ridge","roof_left","roof_right"]:
			var id=Art.roof_part(style,part)
			check(Art.catalog.has(id) and Art.catalog.has(id+"_summer") and pixels(id)!=pixels(id+"_summer"),"%s %s has its own summer look" % [style,part])
	for season in ["autumn","winter"]:
		for part in ["roof","ridge","roof_left","roof_right"]:
			check(Art.catalog.has("tile_roof_cover_%s_%s" % [season,part]),"%s cover exists for %s" % [season,part])
	Art.select_pack("res://art/option2/pack.json")
	var drawable=true
	for style in styles:
		for part in ["roof","ridge","roof_left","roof_right"]: drawable=drawable and Art.catalog.has(Art.roof_part(style,part))
	check(drawable,"packs without the newer roof styles fall back to their shingle roof")
	Art.select_pack("res://art/option3/pack.json")
	quit(1 if failed else 0)
