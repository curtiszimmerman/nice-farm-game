extends SceneTree
const Art=preload("res://art.gd")
const Borders=preload("res://terrain_borders.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void:
	var masks={}
	for raw in range(256): masks[Borders.normalize(raw)]=true
	for pack in ["option2","option3"]:
		check(Art.select_pack("res://art/"+pack+"/pack.json").is_empty(),"the border artwork pack loads: "+pack)
		var missing=[]
		var wrong_size=[]
		for material in ["dirt","pond","ocean","cliff","soil","tilled","cave"]:
			for season in ["spring","summer","autumn","winter"]:
				for weather in ["sunny","partly_cloudy","rainy"]:
					for variant in range(4):
						for mask in masks:
							var id=Borders.sprite_id(material,mask,season,weather,variant)
							if not Art.catalog.has(id): missing.append(id)
							elif Art.region(id).size!=Vector2.ONE*Art.tile_size: wrong_size.append(id)
						for quadrant in ["nw","ne","sw","se"]:
							for shape in ["fill","horizontal","vertical","outer","inner"]:
								var id="border_quarter_%s_%s_%s_%s_%s_%d" % [material,quadrant,shape,season,weather,variant]
								if not Art.catalog.has(id): missing.append(id)
								elif Art.region(id).size!=Vector2.ONE*Art.tile_size/2: wrong_size.append(id)
		check(missing.is_empty(),"all 47 connections and oriented quarter pieces exist in every season/weather/variant: "+pack)
		check(wrong_size.is_empty(),"full tiles and half-tile corner pieces keep their grid dimensions: "+pack)
		if not missing.is_empty(): print("Missing border examples: ",missing.slice(0,6))
	quit(1 if failed else 0)
