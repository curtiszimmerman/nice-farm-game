extends SceneTree
const Art=preload("res://art.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void:
	Art.select_pack("res://art/option3/pack.json")
	var copper=Art.pixels.get_region(Rect2i(Art.region("item_copper_bars")))
	var silver=Art.pixels.get_region(Rect2i(Art.region("item_silver_bars")))
	var same_shape=copper.get_size()==silver.get_size()
	if same_shape:
		for y in range(copper.get_height()):
			for x in range(copper.get_width()):
				if not is_equal_approx(copper.get_pixel(x,y).a,silver.get_pixel(x,y).a): same_shape=false
	check(same_shape and copper.get_data()!=silver.get_data(),"silver ingots reuse the bar shape with a distinct metal palette")
	quit(1 if failed else 0)
