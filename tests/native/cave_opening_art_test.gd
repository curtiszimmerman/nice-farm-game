extends SceneTree
const Art=preload("res://art.gd")
var failed=false
func _initialize() -> void:
	for pack in ["option2","option3"]:
		var error=Art.select_pack("res://art/"+pack+"/pack.json")
		assert(error.is_empty(),error)
		for id in ["cave_exit_day","cave_exit_night"]:
			var image=Art.pixels.get_region(Rect2i(Art.region(id)))
			var scale=image.get_width()/32
			var ground=image.get_pixel(11*scale,29*scale)
			var clear=image.get_pixel(8*scale,29*scale)==ground and image.get_pixel(24*scale,29*scale)==ground
			if clear: print("PASS: both cave exit tile centers show open ground in "+pack+" / "+id)
			else: failed=true; push_error("FAIL: cave opening art narrows across its walkable exit tiles in "+pack+" / "+id)
	quit(1 if failed else 0)
