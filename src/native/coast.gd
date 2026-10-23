extends RefCounted

const Grid=preload("res://grid.gd")
const Art=preload("res://art.gd")
const MIN_X=-28
const JETTY=Rect2i(-22,51,23,3)
const PLATFORM=Rect2i(-26,48,7,7)
const LIGHTHOUSE=Rect2i(-25,48,3,3)
const TIP=Rect2i(-26,51,3,4)
const PATHS=[
	[Vector2i(21,47),Vector2i(21,53)],
	[Vector2i(13,45),Vector2i(14,45),Vector2i(14,54),Vector2i(7,54),Vector2i(7,50),Vector2i(2,50),Vector2i(2,52),Vector2i(0,52)],
	[Vector2i(21,53),Vector2i(21,61),Vector2i(23,61),Vector2i(23,71),Vector2i(33,71),Vector2i(33,83),Vector2i(42,83),Vector2i(42,81)],
	[Vector2i(33,83),Vector2i(29,83),Vector2i(29,80)]
]

static func shoreline(row: int,seed_value: int) -> int:
	return floori(-5+sin(row*0.08+seed_value*0.001)*2+sin(row*0.23+seed_value*0.003))

static func is_ocean(cell: Vector2i,seed_value: int) -> bool:
	return cell.x<shoreline(cell.y,seed_value)

static func dock_cells() -> Dictionary:
	var cells={}
	for bounds in [JETTY,PLATFORM]:
		for y in range(bounds.position.y,bounds.end.y):
			for x in range(bounds.position.x,bounds.end.x): cells[Vector2i(x,y)]=true
	return cells

static func fishing_site(world: Node2D,p: Vector2) -> Dictionary:
	if world.blocked(p): return {}
	var cell=Grid.world_to_cell(p)
	var habitat="ocean_tip" if TIP.has_point(cell) else "ocean"
	var available=JETTY.has_point(cell) or PLATFORM.has_point(cell)
	for direction in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
		if world.in_water(Grid.center(cell+direction)):
			available=true
			if Grid.center(cell+direction).distance_to(Grid.center(world.POND_CELL))<190: habitat="pond"
	if not available: return {}
	return {"type":"site","id":habitat,"cell":cell,"label":"Fish from the jetty's sea end" if habitat=="ocean_tip" else "Fish from the shore"}

static func build_texture(world: Node2D) -> ImageTexture:
	var width=-MIN_X*32
	var image=Image.create(width,int(world.SIZE.y),false,Image.FORMAT_RGBA8)
	image.fill(Color("51868a"))
	var rng=RandomNumberGenerator.new()
	rng.seed=world.state.world_seed+321
	for y in range(Grid.MAP_SIZE.y):
		var shore=shoreline(y,world.state.world_seed)
		for x in range(shore,0):
			var tile=Art.tile_image(Art.seasonal("tile_grass"+str(rng.randi_range(0,3)),world.state.season_name()).trim_prefix("tile_")).duplicate()
			if x-shore<2:
				for py in range(32):
					for px in range(32): tile.set_pixel(px,py,tile.get_pixel(px,py).lerp(Color("c6b48d"),0.8 if x==shore else 0.38))
			image.blit_rect(tile,Rect2i(0,0,32,32),Vector2i((x-MIN_X)*32,y*32))
	var bounds=Rect2(Vector2(MIN_X*32,0),Vector2(width,world.SIZE.y))
	for segment in world.road_segments:
		if segment[2]>10: continue
		var area=Rect2(segment[0],Vector2.ZERO).expand(segment[1]).grow(12).intersection(bounds)
		for y in range(int(area.position.y),int(area.end.y),2):
			for x in range(int(area.position.x),int(area.end.x),2):
				var point=Vector2(x,y)
				if world.in_water(point): continue
				var distance=point.distance_to(Geometry2D.get_closest_point_to_segment(point,segment[0],segment[1]))
				var coverage=(1-smoothstep(3,12,distance))*rng.randf_range(0.35,0.6)
				if coverage<=0: continue
				var pixel=Vector2i(x-MIN_X*32,y)
				image.fill_rect(Rect2i(pixel,Vector2i(2,2)),image.get_pixelv(pixel).lerp(Color("b8a47a"),coverage))
	return ImageTexture.create_from_image(image)

static func draw(world: Node2D) -> void:
	if world.west_terrain!=null: world.draw_texture(world.west_terrain,Vector2(MIN_X*32,0))
	var cells=dock_cells()
	for cell in cells:
		Art.tile(world,"stone_jetty",cell)
		for edge in [[Vector2i.UP,"n"],[Vector2i.RIGHT,"e"],[Vector2i.DOWN,"s"],[Vector2i.LEFT,"w"]]:
			if not cells.has(cell+edge[0]) and is_ocean(cell+edge[0],world.state.world_seed): Art.tile(world,"stone_jetty_edge_"+edge[1],cell)
