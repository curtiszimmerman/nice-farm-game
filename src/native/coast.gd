extends RefCounted

const Grid=preload("res://grid.gd")
const Art=preload("res://art.gd")
const Borders=preload("res://terrain_borders.gd")
const MIN_X=-28
const JETTY=Rect2i(-22,51,23,3)
const PLATFORM=Rect2i(-26,48,7,7)
const LIGHTHOUSE=Rect2i(-25,48,3,3)
const TIP=Rect2i(-26,51,3,4)
const PATHS=[
	[Vector2i(21,47),Vector2i(21,53)]
]

static func shoreline(row: int,seed_value: int) -> int:
	return floori(-5+sin(row*0.08+seed_value*0.001)*2+sin(row*0.23+seed_value*0.003))

static func is_ocean(cell: Vector2i,seed_value: int) -> bool:
	return cell.x<shoreline(cell.y,seed_value)

static func beach_width(row: int,seed_value: int) -> int:
	return 2+posmod(hash(Vector2i(int(row/5.0),seed_value)),2)

static func is_beach(cell: Vector2i,seed_value: int) -> bool:
	var shore=shoreline(cell.y,seed_value)
	return cell.y>=JETTY.end.y and cell.x>=shore and cell.x<shore+beach_width(cell.y,seed_value)

static func beside_beach(cell: Vector2i,seed_value: int) -> bool:
	return Borders.NEIGHBORS.any(func(pair):return is_beach(cell+pair[0],seed_value))

# Sand connects to more beach and to the sea, so its ragged edge only shows where it meets the grass.
static func sand_connection(cell: Vector2i,seed_value: int) -> int:
	var neighbors={}
	for pair in Borders.NEIGHBORS:
		var adjacent: Vector2i=cell+pair[0]
		if is_beach(adjacent,seed_value) or is_ocean(adjacent,seed_value): neighbors[adjacent]=true
	return Borders.mask(neighbors,cell)

static func is_cliff(cell: Vector2i,seed_value: int) -> bool:
	var shore=shoreline(cell.y,seed_value)
	return cell.y<JETTY.position.y and cell.x>=shore and cell.x<shore+3 and not PLATFORM.has_point(cell)

static func dock_cells() -> Dictionary:
	var cells={}
	for bounds in [JETTY,PLATFORM]:
		for y in range(bounds.position.y,bounds.end.y):
			for x in range(bounds.position.x,bounds.end.x): cells[Vector2i(x,y)]=true
	return cells

static func connection(cells: Dictionary,cell: Vector2i,seed_value: int) -> int:
	var neighbors={}
	var borders=preload("res://terrain_borders.gd")
	for pair in borders.NEIGHBORS:
		var adjacent=cell+pair[0]
		if cells.has(adjacent) or not is_ocean(adjacent,seed_value): neighbors[adjacent]=true
	return borders.mask(neighbors,cell)

static func fishing_site(world: Node2D,p: Vector2) -> Dictionary:
	if world.state.active_item()!="fishing_pole": return {}
	var cell=Grid.world_to_cell(p)
	if cell.x<0 and cell.y<JETTY.position.y and not PLATFORM.has_point(cell): return {}
	if world.blocked(p) and not is_ocean(cell,world.state.world_seed) and not world.in_water(p): return {}
	var habitat="ocean_tip" if TIP.has_point(cell) else "ocean"
	var available=JETTY.has_point(cell) or PLATFORM.has_point(cell) or is_ocean(cell,world.state.world_seed)
	if available and is_ocean(cell,world.state.world_seed):
		available=[Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT].any(func(step):return not is_ocean(cell+step,world.state.world_seed) and not world.blocked(Grid.center(cell+step)))
	for direction in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
		if world.in_water(Grid.center(cell+direction)):
			available=true
			if Grid.center(cell+direction).distance_to(Grid.center(world.POND_CELL))<190: habitat="pond"
	if not available: return {}
	return {"type":"site","id":habitat,"cell":cell,"label":"Fish from the jetty's sea end" if habitat=="ocean_tip" else "Fish from the shore"}

static func build_texture(world: Node2D) -> ImageTexture:
	if Art.option==2: return build_connected_texture(world)
	var width=-MIN_X*32
	var image=Image.create(width,int(world.SIZE.y),false,Image.FORMAT_RGBA8)
	image.fill(Color("51868a"))
	var rng=RandomNumberGenerator.new()
	rng.seed=world.state.world_seed+321
	for y in range(Grid.MAP_SIZE.y):
		var shore=shoreline(y,world.state.world_seed)
		for x in range(shore,0):
			var tile=Art.tile_image(Art.seasonal("tile_grass"+str(rng.randi_range(0,3)),world.state.season_name()).trim_prefix("tile_")).duplicate()
			if y>=JETTY.end.y and x-shore<beach_width(y,world.state.world_seed):
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

static func build_connected_texture(world: Node2D) -> ImageTexture:
	return ImageTexture.create_from_image(build_connected_image(world))

static func build_connected_image(world: Node2D) -> Image:
	var image=Image.create(-MIN_X*32,int(world.SIZE.y),false,Image.FORMAT_RGBA8)
	for y in range(Grid.MAP_SIZE.y):
		for x in range(MIN_X,0):
			var cell=Vector2i(x,y)
			var position=Vector2i((x-MIN_X)*32,y*32)
			var variation=Borders.variant(cell,world.state.world_seed)
			var grass=Art.seasonal("tile_grass"+str(variation),world.state.season_name()).trim_prefix("tile_")
			image.blit_rect(Art.tile_image(grass),Rect2i(0,0,32,32),position)
			# Sand runs under the water along the beach, so the sea's own shore band meets it without a strip of grass.
			var sandy=is_beach(cell,world.state.world_seed) or (is_ocean(cell,world.state.world_seed) and beside_beach(cell,world.state.world_seed))
			if sandy:
				var sand=Borders.sprite_id("sand",sand_connection(cell,world.state.world_seed),world.state.season_name(),world.state.weather_name(),variation)
				image.blend_rect(Art.tile_image(sand.trim_prefix("tile_")),Rect2i(0,0,32,32),position)
			if is_ocean(cell,world.state.world_seed):
				var id=Borders.sprite_id("ocean",world.water_connection(cell),world.state.season_name(),world.state.weather_name(),variation)
				image.blend_rect(Art.tile_image(id.trim_prefix("tile_")),Rect2i(0,0,32,32),position)
	return image

static func draw(world: Node2D) -> void:
	if world.west_terrain!=null: world.draw_texture(world.west_terrain,Vector2(MIN_X*32,0))
	if Art.option!=2:
		for cell in world.cliff_cells:
			if cell.x<0: Art.border(world,"cliff",world.cliff_cells,cell,world.state,world.state.world_seed)
	var cells=dock_cells()
	for cell in cells:
		var id=Borders.surface_id("jetty",world.state.season_name(),world.state.weather_name(),Borders.variant(cell,world.state.world_seed))
		Art.tile(world,id.trim_prefix("tile_"),cell)
		var mask=connection(cells,cell,world.state.world_seed)
		for edge in [[1,"n",Rect2i(0,0,16,5)],[2,"e",Rect2i(11,0,5,16)],[4,"s",Rect2i(0,10,16,6)],[8,"w",Rect2i(0,0,5,16)]]:
			if (mask&edge[0])==0: Art.tile_strip(world,"stone_jetty_edge_"+edge[1],cell,edge[2])

# Surf washes up the beach along the waterline. Each row runs a little behind the one above,
# so a wave sweeps down the length of the beach rather than arriving everywhere at once.
const WASH_FRAMES=8

static func wash_frame(row: int,elapsed: float) -> int:
	return posmod(int(floor((elapsed*0.18-row*0.035)*WASH_FRAMES)),WASH_FRAMES)

static func draw_beach_waves(world: Node2D,canvas: CanvasItem) -> void:
	for row in range(JETTY.end.y,Grid.MAP_SIZE.y):
		var origin=Grid.origin(Vector2i(shoreline(row,world.state.world_seed)-1,row))
		if origin.distance_to(world.state.player_position)>850: continue
		Art.sprite(canvas,"shore_wash_%d" % wash_frame(row,world.elapsed),origin,Vector2(64,32))
