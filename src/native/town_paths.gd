extends RefCounted

const Grid=preload("res://grid.gd")
const HUB=Vector2i(62,48)
const TOWN=Rect2i(48,31,41,38)

static func yards(world: Node2D) -> void:
	for building in world.buildings:
		if building.id not in ["home","moss","mayor","tavi","finch","assistant","veteran","reed_farm","mill_home","woodcutter"]: continue
		var bounds=Rect2i(building.cell-Vector2i(2,2),building.tiles+Vector2i(4,5))
		if building.id=="home": bounds=Rect2i(8,37,12,10)
		if building.id=="veteran": bounds.size.x=12
		var gate=Vector2i(building.cell.x+int(building.tiles.x/2),bounds.end.y-1)
		if building.id=="home": gate=Vector2i(14,46)
		if building.id=="reed_farm": gate.x+=1
		var kind="iron" if building.id in ["mayor","assistant","finch"] else "wood"
		var town_home=TOWN.has_point(building.cell)
		var side_y=building.cell.y+building.tiles.y+1
		for y in range(bounds.position.y-1,bounds.end.y+1):
			for x in range(bounds.position.x-1,bounds.end.x+1): world.reserved_cells[Vector2i(x,y)]=true
		for y in range(bounds.position.y,bounds.end.y):
			for x in range(bounds.position.x,bounds.end.x):
				if x not in [bounds.position.x,bounds.end.x-1] and y not in [bounds.position.y,bounds.end.y-1]: continue
				var cell=Vector2i(x,y)
				if town_home and world.buildings.any(func(other):return other.id!=building.id and Rect2i(other.cell,other.tiles).grow(2).has_point(cell)): continue
				if town_home and ((x in [bounds.position.x,bounds.end.x-1] and y in [side_y,side_y-1]) or (y==bounds.position.y and x==gate.x)): continue
				if cell==gate or (building.id=="home" and cell==Vector2i(18,37)):
					world.yard_gates[cell]=kind
					world.reserved_cells[cell]=true
				elif not world.solid_cells.has(cell):
					world.yard_fences[cell]=kind
					world._claim(Rect2i(cell,Vector2i.ONE),"yard fence")
		if building.id in ["mayor","finch","assistant"]:
			var garden=Rect2i(building.cell+Vector2i(0,building.tiles.y+1),Vector2i(2,1))
			for x in range(garden.position.x,garden.end.x):
				var cell=Vector2i(x,garden.position.y)
				if world.solid_cells.has(cell): continue
				world.garden_cells[cell]=true
				world._claim(Rect2i(cell,Vector2i.ONE),"flowerbed")

static func road_blocked(world: Node2D,cell: Vector2i) -> bool:
	if Grid.BUILD_AREA.has_point(cell): return true
	if world.blocked(Grid.center(cell)): return true
	if Rect2i(world.FARM_CELL,Vector2i(5,4)).has_point(cell): return true
	for field in world.DECORATIVE_FIELDS+world.Neighbors.FIELDS:
		if field.has_point(cell): return true
	return false

static func build(world: Node2D) -> void:
	var parents={HUB:HUB}
	var frontier=[HUB]
	var cursor=0
	while cursor<frontier.size():
		var cell: Vector2i=frontier[cursor]
		cursor+=1
		for step in [Vector2i.LEFT,Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN]:
			var next=cell+step
			if parents.has(next) or road_blocked(world,next): continue
			parents[next]=cell
			frontier.append(next)
	var doors=[]
	for b in world.buildings:
		if b.id in ["keeper","veteran","woodcutter"]: continue
		doors.append(b.cell+Vector2i(int(b.tiles.x/2),b.tiles.y))
	doors.append(world.Grid.world_to_cell(world.site_position("ore")))
	doors.append(Vector2i(23,67))
	for door in doors:
		var cell: Vector2i=door
		var path=[]
		while parents.has(cell):
			world.road_cells[cell]=true
			if TOWN.has_point(cell) or cell.distance_to(door)<=1: world.paved_cells[cell]=true
			path.append(cell)
			if cell==HUB: break
			cell=parents[cell]
		for i in range(path.size()-1):
			world.road_segments.append([Grid.center(path[i]),Grid.center(path[i+1]),14.0])
	for y in range(world.SQUARE.position.y-1,world.SQUARE.end.y+1):
		for x in range(world.SQUARE.position.x-1,world.SQUARE.end.x+1):
			var cell=Vector2i(x,y)
			if not world.solid_cells.has(cell): world.paved_cells[cell]=true

static func fence_mask(world: Node2D,cell: Vector2i) -> int:
	var mask=0
	for pair in [[Vector2i.LEFT,1],[Vector2i.RIGHT,2],[Vector2i.UP,4],[Vector2i.DOWN,8]]:
		if world.yard_fences.has(cell+pair[0]) or world.yard_gates.has(cell+pair[0]): mask|=pair[1]
	return mask
