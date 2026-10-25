extends SceneTree
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void:
	check(ResourceLoader.exists("res://terrain_borders.gd"),"terrain borders use all eight neighboring grid cells")
	if not ResourceLoader.exists("res://terrain_borders.gd"): quit(1); return
	var borders=load("res://terrain_borders.gd")
	var masks={}
	for raw in range(256):
		var normalized=borders.normalize(raw)
		masks[normalized]=true
		check(borders.normalize(normalized)==normalized,"normalizing a border mask is stable: "+str(raw))
	check(masks.size()==47,"eight-neighbor terrain connections produce all 47 valid corner masks")
	check(borders.normalize(240)==0,"diagonal-only contacts cannot join isolated tiles")
	check(borders.normalize(1+2+16)==19,"a northeast diagonal joins only with its north and east sides")
	var cells={Vector2i.ZERO:true,Vector2i.UP:true,Vector2i.RIGHT:true}
	check(borders.mask(cells,Vector2i.ZERO)==3,"an absent northeast diagonal leaves an inside corner")
	cells[Vector2i(1,-1)]=true
	check(borders.mask(cells,Vector2i.ZERO)==19,"the filled diagonal removes that inside corner")
	var ring={}
	for y in range(-1,2):
		for x in range(-1,2):
			if x!=0 or y!=0: ring[Vector2i(x,y)]=true
	check(borders.mask(ring,Vector2i.ZERO)==255,"all eight surrounding tiles remove every border")
	var coast=load("res://coast.gd")
	check(coast.has_method("connection"),"jetty borders consider water and the landward join")
	if coast.has_method("connection"):
		var dock=coast.dock_cells()
		check(coast.call("connection",dock,Vector2i(-26,54),1)==19,"the jetty's southwest end has its own convex corner")
		check(coast.call("connection",dock,Vector2i(-20,53),1)==223,"the wide platform's narrowing creates the missing southeast inner corner")
		check(coast.call("connection",dock,Vector2i(0,52),1)==255,"the stone approach joins the mainland without a curb across the path")
	quit(1 if failed else 0)
