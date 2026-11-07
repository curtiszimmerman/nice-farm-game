extends RefCounted

const Grid=preload("res://grid.gd")
const TOWN=Rect2i(48,31,41,38)
const TEMPLE_FORECOURT=Rect2i(41,61,13,2)

# Each route is a list of corner cells joined by straight runs. Doors have flowerbeds on both sides,
# so a route reaches a door from the cell straight below it, or runs along the door row on the open side.
const STREETS=[
	# Market Row runs behind the town hall from the radio club's steps to the mayor's door, and drops into the square.
	[Vector2i(54,38),Vector2i(54,40),Vector2i(64,40)],
	[Vector2i(61,40),Vector2i(61,42)],
	[Vector2i(67,41),Vector2i(67,42)],
	# The town hall's walk to the square, and the west street past Widow Marsh's gate.
	[Vector2i(53,46),Vector2i(57,46)],
	[Vector2i(50,52),Vector2i(57,52)],
	# Smithy Row passes the store's door, and Smithy Lane passes the smithy's.
	[Vector2i(68,45),Vector2i(77,45)],
	[Vector2i(68,52),Vector2i(75,52)],
	# South Street runs down to Sorrel's door, with walks to Finch's house, the bakery and the temple's main gate.
	[Vector2i(62,52),Vector2i(62,65),Vector2i(68,65)],
	[Vector2i(57,59),Vector2i(62,59)],
	[Vector2i(62,58),Vector2i(69,58)],
	[Vector2i(54,62),Vector2i(62,62)],
	# The farmhouse's front walk.
	[Vector2i(10,52),Vector2i(17,52)],
	[Vector2i(13,51),Vector2i(13,52)]
]
const ROADS=[
	# The farm road, and the roads north to the observatory and Iona's tower.
	[Vector2i(18,52),Vector2i(49,52)],
	[Vector2i(31,15),Vector2i(31,51)],
	[Vector2i(57,39),Vector2i(57,16),Vector2i(61,16)],
	# Moss's lane comes in through his gate and carries on south to the woods.
	[Vector2i(21,53),Vector2i(21,61),Vector2i(26,61),Vector2i(26,59)],
	[Vector2i(23,62),Vector2i(23,66)],
	# Smithy Row becomes the east road, which turns north to the mill, the Bells' gate and the shed.
	[Vector2i(78,45),Vector2i(86,45),Vector2i(86,34),Vector2i(107,34),Vector2i(107,32)],
	[Vector2i(90,33),Vector2i(90,30)],
	[Vector2i(99,33),Vector2i(99,32)],
	# The east lane runs south past Tavi's and Neral's doors, and a farm track leads off it to the Reeds' gate.
	[Vector2i(82,46),Vector2i(82,63),Vector2i(80,63)],
	[Vector2i(75,53),Vector2i(75,55),Vector2i(81,55)],
	[Vector2i(83,56),Vector2i(104,56),Vector2i(104,48),Vector2i(103,48)]
]
const PATHS=[
	[Vector2i(0,52),Vector2i(9,52)],
	# Inside the temple fence: from the west gate to the forecourt, down to the outhouse, and out the south gate
	# towards Bram's, with a walk between the garden beds.
	[Vector2i(24,62),Vector2i(40,62)],
	[Vector2i(40,63),Vector2i(40,70),Vector2i(39,70)],
	[Vector2i(45,63),Vector2i(45,73),Vector2i(37,73),Vector2i(37,86)],
	[Vector2i(45,67),Vector2i(50,67)],
	# From the end of the east lane by Neral's house, down past the copper cave entrance to the old mining shack.
	[Vector2i(82,64),Vector2i(82,65),Vector2i(85,65),Vector2i(85,68),Vector2i(89,68),Vector2i(89,74),Vector2i(104,74),Vector2i(104,73)],
	# The woodland path reaches Rowan's and continues to Bram's cabin through both yard gates.
	[Vector2i(23,67),Vector2i(23,86),Vector2i(42,86),Vector2i(42,82)],
	[Vector2i(29,86),Vector2i(29,83)]
]
# Fences keep the square out of Finch's and the bakery's back yards and the smithy's side yard.
const TOWN_FENCES=[[Vector2i(55,53),Vector2i(60,53),"iron"],[Vector2i(66,53),Vector2i(71,53),"wood"],[Vector2i(69,46),Vector2i(69,50),"iron"]]
# Widow Marsh's fence goes all the way around, with the gate at her door and a small garden on the west side.
const WIDOW_YARD=Rect2i(47,47,10,5)
const WIDOW_GARDEN=Rect2i(48,49,2,2)

static func yards(world: Node2D) -> void:
	town_fences(world)
	for building in world.buildings:
		if building.id in ["priest","iona","observatory","finch","mayor","tavi","assistant"]:
			residential_garden(world,building)
			continue
		if building.id not in ["moss","veteran","reed_farm","mill_home","woodcutter"]: continue
		var bounds=Rect2i(building.cell-Vector2i(2,2),building.tiles+Vector2i(4,5))
		if building.id=="veteran": bounds.size.x=12
		var gate=Vector2i(building.cell.x+int(building.tiles.x/2),bounds.end.y-1)
		if building.id=="reed_farm": gate.x+=1
		for y in range(bounds.position.y-1,bounds.end.y+1):
			for x in range(bounds.position.x-1,bounds.end.x+1): world.reserved_cells[Vector2i(x,y)]=true
		for y in range(bounds.position.y,bounds.end.y):
			for x in range(bounds.position.x,bounds.end.x):
				if x not in [bounds.position.x,bounds.end.x-1] and y not in [bounds.position.y,bounds.end.y-1]: continue
				var cell=Vector2i(x,y)
				if cell==gate:
					world.yard_gates[cell]="wood"
					world.reserved_cells[cell]=true
				elif not world.solid_cells.has(cell):
					world.yard_fences[cell]="wood"
					world._claim(Rect2i(cell,Vector2i.ONE),"yard fence")
		residential_garden(world,building)

static func town_fences(world: Node2D) -> void:
	for line in TOWN_FENCES:
		var cell: Vector2i=line[0]
		while true:
			fence(world,cell,line[2])
			if cell==line[1]: break
			cell+=Vector2i(signi(line[1].x-cell.x),signi(line[1].y-cell.y))
	var gate=Vector2i(WIDOW_YARD.position.x+6,WIDOW_YARD.end.y-1)
	for y in range(WIDOW_YARD.position.y,WIDOW_YARD.end.y):
		for x in range(WIDOW_YARD.position.x,WIDOW_YARD.end.x):
			var cell=Vector2i(x,y)
			if x not in [WIDOW_YARD.position.x,WIDOW_YARD.end.x-1] and y not in [WIDOW_YARD.position.y,WIDOW_YARD.end.y-1]: continue
			if cell==gate:
				world.yard_gates[cell]="iron"
				world.reserved_cells[cell]=true
			else: fence(world,cell,"iron")
	for y in range(WIDOW_GARDEN.position.y,WIDOW_GARDEN.end.y):
		for x in range(WIDOW_GARDEN.position.x,WIDOW_GARDEN.end.x):
			var cell=Vector2i(x,y)
			world.garden_cells[cell]="vegetables"
			world._claim(Rect2i(cell,Vector2i.ONE),"flowerbed")
			world.reserved_cells[cell]=true

static func fence(world: Node2D,cell: Vector2i,material: String) -> void:
	assert(not world.road_cells.has(cell),"A fence would cross the route at %s" % cell)
	world.yard_fences[cell]=material
	world.reserved_cells[cell]=true
	world._claim(Rect2i(cell,Vector2i.ONE),"yard fence")

static func residential_garden(world: Node2D,building: Dictionary) -> void:
	var rng=RandomNumberGenerator.new()
	rng.seed=hash("garden:%d:%s" % [world.state.world_seed,building.id])
	var yard=Rect2i(building.cell-Vector2i(2,2),building.tiles+Vector2i(4,5))
	if building.id=="veteran": yard.size.x=12
	var door=building.cell+Vector2i(int(building.tiles.x/2),building.tiles.y)
	var gate=Vector2i(door.x,yard.end.y-1)
	if building.id=="reed_farm": gate.x+=1
	var candidates=[]
	for dimensions in [Vector2i(1,2),Vector2i(2,1),Vector2i(2,2),Vector2i(2,3),Vector2i(3,2)]:
		for y in range(yard.position.y+1,yard.end.y-dimensions.y):
			for x in range(yard.position.x+1,yard.end.x-dimensions.x):
				var rectangle=Rect2i(Vector2i(x,y),dimensions)
				var clear=true
				for dy in range(dimensions.y):
					for dx in range(dimensions.x):
						var cell=rectangle.position+Vector2i(dx,dy)
						if world.blocked(Grid.center(cell)) or world.yard_gates.has(cell) or world.schedule_cells.has(cell) or world.road_cells.has(cell) or world.paved_cells.has(cell) or world.SQUARE.has_point(cell) or building_door_approach(world,cell) or coastal_path_contains(cell) or cell.distance_to(door)<=1.5 or (cell.x in [door.x,gate.x] and cell.y>=door.y): clear=false
						# A garden behind a house's walls would be hidden by its roof.
						if world.buildings.any(func(other):return Rect2i(other.cell,other.tiles).has_point(cell)): clear=false
						# Iona's tower has no fence, so people walk right past its base. Keep the garden out of those side lanes.
						if building.kind=="tower" and cell.x in [building.cell.x-1,building.cell.x+building.tiles.x] and cell.y>=building.cell.y and cell.y<building.cell.y+building.tiles.y: clear=false
				if clear: candidates.append(rectangle)
	var origin=building.cell
	var offsets=[]
	if not candidates.is_empty():
		var rectangle: Rect2i=candidates[rng.randi_range(0,candidates.size()-1)]
		origin=rectangle.position
		for y in range(rectangle.size.y):
			for x in range(rectangle.size.x): offsets.append(Vector2i(x,y))
	var planted=[]
	for offset in offsets:
		var cell=origin+offset
		world.garden_cells[cell]="vegetables"
		world._claim(Rect2i(cell,Vector2i.ONE),"flowerbed")
		world.reserved_cells[cell]=true
		planted.append(cell)
	var work_options=[]
	for cell in planted:
		for step in [Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP]:
			var work=cell+step
			if work.distance_to(building.cell)<12 and not world.blocked(Grid.center(work)) and not world._route(Grid.SPAWN_CELL,work).is_empty(): work_options.append(work)
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
				if cell.distance_to(building[0].cell)>=12 or world.blocked(Grid.center(cell)): continue
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

const TEMPLE_GATES=[Vector2i(54,62),Vector2i(36,62),Vector2i(45,72)]

static func temple_fence(world: Node2D) -> void:
	var corners=[Vector2i(36,54),Vector2i(54,54),Vector2i(54,72),Vector2i(36,72)]
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
	var edges={}
	for route in STREETS: lay(world,route,"street",edges)
	for route in ROADS: lay(world,route,"road",edges)
	for route in PATHS: lay(world,route,"path",edges)
	# The square and the temple forecourt are paved right across, around anything standing on them.
	for plaza in [world.SQUARE.grow(1),TEMPLE_FORECOURT]:
		for y in range(plaza.position.y,plaza.end.y):
			for x in range(plaza.position.x,plaza.end.x):
				var cell=Vector2i(x,y)
				if world.solid_cells.has(cell): continue
				world.paved_cells[cell]=true
				world.road_cells[cell]=true
	road_fences(world)

static func lay(world: Node2D,route: Array,kind: String,edges: Dictionary) -> void:
	for index in range(route.size()-1):
		var cell: Vector2i=route[index]
		var finish: Vector2i=route[index+1]
		while true:
			assert(not world.solid_cells.has(cell),"The %s at %s runs into a %s" % [kind,cell,world.solid_cells.get(cell,"")])
			world.road_cells[cell]=true
			if kind=="street": world.paved_cells[cell]=true
			if kind=="path":
				world.trail_cells[cell]=true
				world.dirt_cells[cell]=true
			if cell==finish: break
			cell+=Vector2i(signi(finish.x-cell.x),signi(finish.y-cell.y))
		append_road_segment(world,route[index],finish,6.0 if kind=="path" else 14.0,edges)

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
	for start in [Vector2i(31,51),Vector2i(86,38)]:
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
