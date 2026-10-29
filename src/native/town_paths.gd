extends RefCounted

const Grid=preload("res://grid.gd")
const HUB=Vector2i(62,48)
const TOWN=Rect2i(48,31,41,38)

static func yards(world: Node2D) -> void:
	for building in world.buildings:
		if building.id not in ["moss","mayor","tavi","finch","assistant","veteran","reed_farm","mill_home","woodcutter","iona","observatory","priest"]: continue
		var bounds=Rect2i(building.cell-Vector2i(2,2),building.tiles+Vector2i(4,5))
		if building.id=="home": bounds=Rect2i(8,44,12,10)
		if building.id in ["priest","iona","observatory","finch"]:
			residential_garden(world,building)
			continue
		if building.id=="veteran": bounds.size.x=12
		var gate=Vector2i(building.cell.x+int(building.tiles.x/2),bounds.end.y-1)
		if building.id=="home": gate=Vector2i(14,53)
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
				if building.id=="home" and y in [51,52]: continue
				if town_home and world.buildings.any(func(other):return other.id!=building.id and Rect2i(other.cell,other.tiles).grow(2).has_point(cell)): continue
				if town_home and ((x in [bounds.position.x,bounds.end.x-1] and y in [side_y,side_y-1]) or (y==bounds.position.y and x==gate.x)): continue
				if cell==gate or (building.id=="home" and cell==Vector2i(18,44)):
					world.yard_gates[cell]=kind
					world.reserved_cells[cell]=true
				elif not world.solid_cells.has(cell):
					world.yard_fences[cell]=kind
					world._claim(Rect2i(cell,Vector2i.ONE),"yard fence")
		residential_garden(world,building)

static func residential_garden(world: Node2D,building: Dictionary) -> void:
	var rng=RandomNumberGenerator.new()
	rng.seed=hash("garden:%d:%s" % [world.state.world_seed,building.id])
	var side=rng.randi_range(0,3)
	var origin=building.cell+Vector2i(building.tiles.x,0) if side==0 else building.cell-Vector2i(2,rng.randi_range(0,maxi(0,building.tiles.y-1))) if side==1 else building.cell+Vector2i(rng.randi_range(0,maxi(0,building.tiles.x-2)),building.tiles.y)
	if building.id=="priest": origin=Vector2i(48,60)
	if building.id=="iona": origin+=Vector2i(3,0)
	var yard=Rect2i(building.cell-Vector2i(2,2),building.tiles+Vector2i(4,5))
	if building.id=="veteran": yard.size.x=12
	var count=rng.randi_range(2,4)
	var door=building.cell+Vector2i(int(building.tiles.x/2),building.tiles.y)
	var gate=Vector2i(door.x,yard.end.y-1)
	if building.id=="reed_farm": gate.x+=1
	var offsets=[Vector2i.ZERO,Vector2i.DOWN,Vector2i.DOWN*2,Vector2i.RIGHT,Vector2i.RIGHT+Vector2i.DOWN,Vector2i.LEFT]
	var selected=[Vector2i.ZERO]
	var planted=[]
	while selected.size()<count:
		var candidate=offsets[rng.randi_range(1,offsets.size()-1)]
		if not selected.has(candidate): selected.append(candidate)
	for offset in selected:
		var cell=origin+offset
		var blocks_door_path=cell.x==door.x and cell.y>=door.y and cell.y<=gate.y
		var blocks_gate_walk=cell.x==gate.x and cell.y>=door.y and cell.y<=gate.y
		if not yard.has_point(cell) or cell.distance_to(door)<=1.5 or blocks_door_path or blocks_gate_walk or building_door_approach(world,cell) or coastal_path_contains(cell) or (cell.y==52 and cell.x<=48) or (cell.y==58 and cell.x>=45 and cell.x<=63): continue
		if world.solid_cells.has(cell) or world.schedule_cells.has(cell) or world.road_cells.has(cell) or world.paved_cells.has(cell): continue
		world.garden_cells[cell]="vegetables"
		world._claim(Rect2i(cell,Vector2i.ONE),"flowerbed")
		world.reserved_cells[cell]=true
		planted.append(cell)
	if planted.size()<2:
		var fallback=[]
		for y in range(yard.position.y,yard.end.y):
			for x in range(yard.position.x,yard.end.x):
				var cell=Vector2i(x,y)
				if planted.has(cell) or cell.distance_to(door)<=1.5 or cell.x==door.x and cell.y>=door.y and cell.y<=gate.y or cell.x==gate.x and cell.y>=door.y and cell.y<=gate.y: continue
				if building_door_approach(world,cell) or coastal_path_contains(cell) or (cell.y==52 and cell.x<=48) or (cell.y==58 and cell.x>=45 and cell.x<=63): continue
				if world.blocked(Grid.center(cell)) or world.schedule_cells.has(cell) or world.road_cells.has(cell) or world.paved_cells.has(cell): continue
				fallback.append(cell)
		for index in range(fallback.size()-1,0,-1):
			var other=rng.randi_range(0,index)
			var cell=fallback[index]
			fallback[index]=fallback[other]
			fallback[other]=cell
		for cell in fallback:
			if planted.size()>=2: break
			world.garden_cells[cell]="vegetables"
			world._claim(Rect2i(cell,Vector2i.ONE),"flowerbed")
			world.reserved_cells[cell]=true
			planted.append(cell)
	var work_options=[]
	for cell in planted:
		for step in [Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP]:
			var work=cell+step
			if work.distance_to(building.cell)<12 and not world.blocked(Grid.center(work)) and not world.road_cells.has(work) and not world.paved_cells.has(work) and not world._route(Grid.SPAWN_CELL,work).is_empty(): work_options.append(work)
	if work_options.is_empty():
		for y in range(yard.position.y,yard.end.y):
			for x in range(yard.position.x,yard.end.x):
				var cell=Vector2i(x,y)
				if world.blocked(Grid.center(cell)) or world.schedule_cells.has(cell) or world.road_cells.has(cell) or world.paved_cells.has(cell) or building_door_approach(world,cell) or (cell.x==door.x and cell.y>=door.y and cell.y<=gate.y) or (cell.x==gate.x and cell.y>=door.y and cell.y<=gate.y) or coastal_path_contains(cell) or (cell.y==52 and cell.x<=48) or (cell.y==58 and cell.x>=45 and cell.x<=63) or cell.distance_to(door)<=1.5: continue
				world.garden_cells[cell]="vegetables"
				world._claim(Rect2i(cell,Vector2i.ONE),"flowerbed")
				planted.append(cell)
				for step in [Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP]:
					var work=cell+step
					if not world.blocked(Grid.center(work)) and not world.road_cells.has(work) and not world.paved_cells.has(work) and not world._route(Grid.SPAWN_CELL,work).is_empty(): work_options.append(work)
				if not work_options.is_empty(): break
			if not work_options.is_empty(): break
	if not work_options.is_empty():
		work_options.sort_custom(func(a,b):return a.distance_squared_to(origin)<b.distance_squared_to(origin))
		world.garden_work[building.id]=work_options[0]
		world.reserved_cells[work_options[0]]=true
	world.garden_cells_by_home[building.id]=planted.duplicate()

static func refresh_garden_work(world: Node2D) -> void:
	for home in world.garden_cells_by_home:
		var building=world.buildings.filter(func(candidate):return candidate.id==home)
		if building.is_empty(): continue
		var options=[]
		for garden_cell in world.garden_cells_by_home[home]:
			for step in [Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP]:
				var cell: Vector2i=garden_cell+step
				if cell.distance_to(building[0].cell)>=12 or world.blocked(Grid.center(cell)) or world.road_cells.has(cell) or world.paved_cells.has(cell): continue
				if world._route(Grid.SPAWN_CELL,cell).is_empty(): continue
				if not options.has(cell): options.append(cell)
		if options.is_empty():
			world.garden_work.erase(home)
			continue
		options.sort_custom(func(a,b):return a.distance_squared_to(world.garden_cells_by_home[home][0])<b.distance_squared_to(world.garden_cells_by_home[home][0]))
		world.garden_work[home]=options[0]
		world.reserved_cells[options[0]]=true

static func coastal_path_contains(cell: Vector2i) -> bool:
	for path in preload("res://coast.gd").PATHS:
		for index in range(path.size()-1):
			var start: Vector2i=path[index]
			var finish: Vector2i=path[index+1]
			if start.x==finish.x and cell.x==start.x and cell.y>=mini(start.y,finish.y) and cell.y<=maxi(start.y,finish.y): return true
			if start.y==finish.y and cell.y==start.y and cell.x>=mini(start.x,finish.x) and cell.x<=maxi(start.x,finish.x): return true
	return false

static func building_door_approach(world: Node2D,cell: Vector2i) -> bool:
	for building in world.buildings:
		var door=building.cell+Vector2i(int(building.tiles.x/2),building.tiles.y)
		if cell==door or cell==door+Vector2i.DOWN: return true
	return false

static func road_blocked(world: Node2D,cell: Vector2i) -> bool:
	if world.blocked(Grid.center(cell)): return true
	for field in world.DECORATIVE_FIELDS+world.Neighbors.FIELDS:
		if field.has_point(cell): return true
	return false

const TEMPLE_GATES=[Vector2i(53,50),Vector2i(62,58),Vector2i(39,52),Vector2i(46,66),Vector2i(53,57)]

static func temple_fence(world: Node2D) -> void:
	var corners=[Vector2i(39,50),Vector2i(58,50),Vector2i(58,52),Vector2i(62,52),Vector2i(62,59),Vector2i(53,59),Vector2i(53,66),Vector2i(39,66)]
	for index in range(corners.size()):
		var cell: Vector2i=corners[index]
		var end: Vector2i=corners[(index+1)%corners.size()]
		while cell!=end:
			world.reserved_cells[cell]=true
			if world.yard_fences.has(cell):
				cell+=Vector2i(signi(end.x-cell.x),signi(end.y-cell.y))
				continue
			if cell in TEMPLE_GATES:
				world.yard_gates[cell]="wood"
			elif not world.solid_cells.has(cell):
				world.yard_fences[cell]="wood"
				world._claim(Rect2i(cell,Vector2i.ONE),"temple fence")
			cell+=Vector2i(signi(end.x-cell.x),signi(end.y-cell.y))

static func build(world: Node2D) -> void:
	var road_edges={}
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
	var temple_doors=[]
	for b in world.buildings:
		if b.id in ["home","keeper","veteran","woodcutter"]: continue
		doors.append(b.cell+Vector2i(int(b.tiles.x/2),b.tiles.y))
		if b.id in ["temple","priest"]: temple_doors.append(doors.back())
	doors.append_array(TEMPLE_GATES)
	doors.append(world.Grid.world_to_cell(world.site_position("ore")))
	doors.append(Vector2i(23,67))
	for door in doors:
		var cell: Vector2i=door
		var path=[]
		while parents.has(cell):
			world.road_cells[cell]=true
			if TOWN.has_point(cell) or cell.distance_to(door)<=1 or door in temple_doors: world.paved_cells[cell]=true
			path.append(cell)
			if cell==HUB: break
			cell=parents[cell]
		for i in range(path.size()-1):
			append_road_segment(world,path[i],path[i+1],14.0,road_edges)
	# The temple's paved forecourt continues as a narrow dirt walk between the hives and garden beds.
	for x in range(45,64):
		var cell=Vector2i(x,58)
		world.road_cells[cell]=true
		if x<58: world.paved_cells[cell]=true
		else:
			world.paved_cells.erase(cell)
			world.trail_cells[cell]=true
			world.dirt_cells[cell]=true
		append_road_segment(world,cell,cell+Vector2i.RIGHT,14.0 if x<58 else 6.0,road_edges)
	# A narrow woodland path reaches Rowan's and continues to Bram's cabin through both yard gates.
	var woodland_path=[Vector2i(23,67),Vector2i(23,86),Vector2i(29,86),Vector2i(29,83),Vector2i(29,86),Vector2i(42,86),Vector2i(42,82)]
	for index in range(woodland_path.size()-1):
		var start: Vector2i=woodland_path[index]
		var finish: Vector2i=woodland_path[index+1]
		var step=Vector2i(signi(finish.x-start.x),signi(finish.y-start.y))
		var cell=start
		while true:
			world.road_cells[cell]=true
			world.trail_cells[cell]=true
			world.dirt_cells[cell]=true
			if cell==finish: break
			cell+=step
		world.add_road_segment(start,finish,6.0)
	for y in range(world.SQUARE.position.y-1,world.SQUARE.end.y+1):
		for x in range(world.SQUARE.position.x-1,world.SQUARE.end.x+1):
			var cell=Vector2i(x,y)
			if not world.solid_cells.has(cell): world.paved_cells[cell]=true
	for x in range(0,49):
		var cell=Vector2i(x,52)
		if world.solid_cells.has(cell): continue
		world.road_cells[cell]=true
		if x in range(10,18): world.paved_cells[cell]=true
		elif x<10: world.trail_cells[cell]=true
		append_road_segment(world,cell,cell+Vector2i.RIGHT,6.0 if x<10 else 14.0,road_edges)
	world.road_cells[Vector2i(13,51)]=true
	world.paved_cells[Vector2i(13,51)]=true
	road_fences(world)

static func append_road_segment(world: Node2D,a: Vector2i,b: Vector2i,width: float,edges: Dictionary) -> void:
	var first=a
	var second=b
	if first.x>second.x or (first.x==second.x and first.y>second.y):
		first=b
		second=a
	var key="%d,%d:%d,%d" % [first.x,first.y,second.x,second.y]
	if edges.has(key): return
	edges[key]=true
	world.add_road_segment(first,second,width)

static func road_fences(world: Node2D) -> void:
	for start in [Vector2i(31,51),Vector2i(71,58),Vector2i(86,38)]:
		for i in range(8):
			var cell=start+Vector2i.RIGHT*i
			if world.solid_cells.has(cell) or world.road_cells.has(cell) or world.paved_cells.has(cell) or world.reserved_cells.has(cell): continue
			world.yard_fences[cell]="wood"
			world._claim(Rect2i(cell,Vector2i.ONE),"road fence")

static func fence_mask(world: Node2D,cell: Vector2i) -> int:
	var mask=0
	for pair in [[Vector2i.LEFT,1],[Vector2i.RIGHT,2],[Vector2i.UP,4],[Vector2i.DOWN,8]]:
		var material=world.yard_fences.get(cell,world.yard_gates.get(cell,""))
		if world.yard_fences.get(cell+pair[0],world.yard_gates.get(cell+pair[0],""))==material: mask|=pair[1]
	return mask
