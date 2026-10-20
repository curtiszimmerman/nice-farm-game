extends Node2D

const Grid = preload("res://grid.gd")
const Art = preload("res://art.gd")
const Schedule = preload("res://villager_schedule.gd")
const Coast=preload("res://coast.gd")
const SQUARE = Rect2i(59,44,6,6)
const SIZE = Grid.WORLD_SIZE
const FARM_CELL = Vector2i(9,48)
const OUTCROP_CELLS = Rect2i(90,69,9,5)
const COPPER_CELLS = Rect2i(90,74,9,1)
const MINE_RIDGE = Rect2i(97,65,3,4)
const MOSS_FIELDS = Rect2i(25,60,6,4)
const VETERAN_GARDEN = Rect2i(46,79,3,3)
const DECORATIVE_FIELDS = [MOSS_FIELDS,VETERAN_GARDEN]
const SHIP_CELL = Vector2i(11,12)
const SHIP_MOUNTAIN=Rect2i(4,5,18,24)
const DESCENT_AREAS=[Rect2i(8,9,7,7),Rect2i(11,15,2,5),Rect2i(11,18,6,2),Rect2i(15,18,2,6),Rect2i(13,22,4,2),Rect2i(13,22,2,6),Rect2i(13,28,1,1)]
const DESCENT_EXIT=Vector2i(13,28)
const MOSS_ENCOUNTER_CELL=Vector2i(13,30)
const FARMHOUSE_APPROACH=[Vector2i(13,29),Vector2i(13,32),Vector2i(15,32),Vector2i(15,34),Vector2i(18,34),Vector2i(18,45),Vector2i(13,45)]
const POND_CELL = Vector2i(17,67)
const JETTY_CELLS = Rect2i(19,67,4,1)
const CART_CELLS = Rect2i(65,45,3,1)
const LAMP_CELLS = [Vector2i(58,43),Vector2i(64,50),Vector2i(20,42)]
const PEOPLE = [
	{"id":"moss","name":"Moss","role":"YOUR NEIGHBOR","cell":MOSS_ENCOUNTER_CELL,"coat":"a7834d","hair":"d6cb9c","skin":"d4a776","hat":true},
	{"id":"tavi","name":"Tavi","role":"TRAVELING MERCHANT","cell":Vector2i(64,46),"coat":"aa7262","hair":"bd996b","skin":"c0a070","cat":true},
	{"id":"iona","name":"Iona","role":"FIELD MAGICIAN","cell":Vector2i(61,15),"coat":"8885ad","hair":"e3d7bd","skin":"ae856c"},
	{"id":"finch","name":"Finch","role":"RADIO CLUB SECRETARY","cell":Vector2i(54,38),"coat":"6d96a0","hair":"765842","skin":"d3ab88"},
	{"id":"vale","name":"Chief Vale","role":"CHIEF ENGINEER","cell":Vector2i(11,14),"coat":"8b9baf","hair":"b5a68e","skin":"a97959"},
	{"id":"mayor","name":"Mayor Alder","role":"MAYOR","cell":Vector2i(61,42),"coat":"657b70","hair":"c2c4b0","skin":"d0a181"},
	{"id":"veteran","name":"Bram","role":"RETIRED ARMY","cell":Vector2i(43,82),"coat":"777a60","hair":"b9b6a3","skin":"b08f77"},
	{"id":"assistant","name":"Neral","role":"MAYOR'S ASSISTANT · DARK ELF","cell":Vector2i(54,46),"coat":"61758a","hair":"c7cbcd","skin":"65566d","elf":true},
	{"id":"keeper","name":"Oren","role":"LIGHTHOUSE KEEPER","cell":Vector2i(-24,51),"coat":"536e81","hair":"ded8c8","skin":"c99c78"}
]
const BUILDINGS = [
	{"cell":Vector2i(10,39),"tiles":Vector2i(7,5),"roof":"a65e50","kind":"home"},
	{"cell":Vector2i(52,34),"tiles":Vector2i(5,4),"roof":"5b8990","kind":"radio"},
	{"cell":Vector2i(65,40),"tiles":Vector2i(5,4),"roof":"ad7956","kind":"store"},
	{"cell":Vector2i(50,41),"tiles":Vector2i(7,5),"roof":"818a60","kind":"hall"},
	{"cell":Vector2i(59,39),"tiles":Vector2i(5,3),"roof":"8c6856","kind":"cottage","resident":"mayor"},
	{"cell":Vector2i(65,48),"tiles":Vector2i(5,3),"roof":"a87858","kind":"cottage","resident":"tavi"},
	{"cell":Vector2i(58,51),"tiles":Vector2i(5,3),"roof":"65858b","kind":"cottage","resident":"finch"},
	{"cell":Vector2i(60,12),"tiles":Vector2i(3,3),"roof":"68658f","kind":"tower","resident":"iona","visual_height":192},
	{"cell":Vector2i(24,55),"tiles":Vector2i(5,3),"roof":"8c6856","kind":"cottage","resident":"moss"},
	{"cell":Vector2i(40,76),"tiles":Vector2i(5,4),"roof":"70685a","kind":"cabin","resident":"veteran"},
	{"cell":Vector2i(70,53),"tiles":Vector2i(4,3),"roof":"6c7885","kind":"cottage","resident":"assistant"},
	{"cell":Vector2i(-25,48),"tiles":Vector2i(3,3),"roof":"656b75","kind":"lighthouse","resident":"keeper","visual_height":256}
]
const SITES = [
	{"id":"ship_entry","cell":Vector2i(11,14),"door":"ship","label":"Enter cloaked ship"},
	{"id":"bed","cell":Vector2i(13,44),"label":"Rest at the farmhouse"},
	{"id":"chest","cell":Vector2i(17,44),"label":"Open farmhouse chest"},
	{"id":"pond","cell":Vector2i(21,67),"label":"Fish from the jetty"},
	{"id":"ore","cell":Vector2i(94,74),"door":"cave","label":"Enter copper cave"},
	{"id":"sparkfire","cell":Vector2i(58,16),"label":"Inspect woodland plant"},
	{"id":"sign","cell":Vector2i(30,42),"label":"Read the signpost"},
	{"id":"radio","cell":Vector2i(55,39),"label":"Listen to the radio"}
]
const ROAD_ROUTES = [
	[Vector2i(13,44),Vector2i(14,44),Vector2i(14,53)],
	[Vector2i(14,45),Vector2i(50,45),Vector2i(50,46),Vector2i(59,46)],
	[Vector2i(57,40),Vector2i(57,57),Vector2i(87,57),Vector2i(87,74),Vector2i(94,74)],
	[Vector2i(21,53),Vector2i(57,53)],
	[Vector2i(23,53),Vector2i(23,67),Vector2i(22,67)],
	[Vector2i(54,38),Vector2i(54,40),Vector2i(57,40)],
	[Vector2i(67,44),Vector2i(67,46)],
	[Vector2i(61,42),Vector2i(61,44)],
	[Vector2i(64,44),Vector2i(67,44)],
	[Vector2i(64,44),Vector2i(64,16),Vector2i(61,16),Vector2i(61,15)],
	[Vector2i(67,51),Vector2i(64,51),Vector2i(64,49)],
	[Vector2i(60,54),Vector2i(57,54)],
	[Vector2i(61,49),Vector2i(57,49)],
	[Vector2i(26,58),Vector2i(26,53)],
	[Vector2i(14,53),Vector2i(21,53)],
	[Vector2i(72,56),Vector2i(72,57)]
]

var people: Array = []
var conversation_holds: Dictionary={}
var story_destinations: Dictionary={}
var indoor_departures: Dictionary={}
var villagers: Dictionary = {}
var routes: Dictionary = {}
var buildings: Array = []
var sites: Array = []
var road_segments: Array = []
var road_cells: Dictionary = {}
var water_cells: Dictionary = {}
var mountain_cells: Dictionary = {}
var solid_cells: Dictionary = {}
var reserved_cells: Dictionary = {}
var fence_cells: Array[Vector2i] = []
var gate_cells: Array[Vector2i] = []
var trees: Array = []
var bushes: Array=[]
var terrain: ImageTexture
var west_terrain: ImageTexture
var road_mask: Image
var night_tint: CanvasModulate
var state: RefCounted
var crops: Node2D
var mayor: Node2D
var player: Node2D
var elapsed = 0.0
var moving = false
var facing = "down"
var nearest: Dictionary = {}
var particles: Array = []
var scenery_layer: Node2D
var moving_layer: Node2D
var crop_signature=0
var tree_damage: Dictionary={}

class Prop extends Node2D:
	var owner_world: Node2D
	var kind: String
	var data: Dictionary
	var draw_count=0
	func _draw() -> void:
		draw_count+=1
		if kind == "tree": owner_world.paint_tree(self, data)
		elif kind == "building": owner_world.paint_building(self, data)
		elif kind == "person": owner_world.paint_person(self, data, sin(owner_world.elapsed*10.0) if data.get("walking",false) else 0.0, data.get("direction","down"))
		elif kind == "player": owner_world.paint_person(self, data, sin(owner_world.elapsed * 14.0) if owner_world.moving else 0.0, owner_world.facing)
		elif kind == "crops": owner_world.paint_crops(self)
		elif kind == "effects": owner_world.paint_effects(self)
		elif kind == "sparkfire": owner_world.paint_sparkfire(self,data.get("bloom",false))
		elif kind == "bush": Art.sprite(self,"bush"+str(data.variant),Vector2(-32,-42))
		elif kind == "stump": Art.sprite(self,"stump",Vector2(-16,-16))

func _ready() -> void:
	y_sort_enabled = true
	night_tint=CanvasModulate.new()
	add_child(night_tint)
	_build_layout()
	_build_terrain()
	var random = RandomNumberGenerator.new()
	random.seed=state.world_seed
	for anchor in [Vector2i(10,30),Vector2i(8,29),Vector2i(16,29),Vector2i(18,29),Vector2i(7,31),Vector2i(19,32)]:
		var cell=anchor+Vector2i(random.randi_range(0,1),random.randi_range(0,1)) if anchor==Vector2i(10,30) else anchor+Vector2i(random.randi_range(-1,1),random.randi_range(-1,1))
		if solid_cells.has(cell) or _clearing(Grid.center(cell)): continue
		reserved_cells[cell]=true
		solid_cells[cell]="bush"
		bushes.append(cell)
		_prop("bush",Grid.center(cell),{"variant":random.randi_range(0,3)})
	for y in range(24,37):
		for x in range(4,28):
			var cell=Vector2i(x,y)
			if solid_cells.has(cell) or reserved_cells.has(cell) or _clearing(Grid.center(cell)) or random.randf()>0.24: continue
			reserved_cells[cell]=true
			solid_cells[cell]="bush"
			bushes.append(cell)
			_prop("bush",Grid.center(cell),{"variant":random.randi_range(0,3)})
	var placed: Array=[]
	for i in range(1800):
		var cell=Vector2i(random.randi_range(4,Grid.MAP_SIZE.x-4),random.randi_range(5,Grid.MAP_SIZE.y-4))
		var p=Grid.center(cell)
		if solid_cells.has(cell) or reserved_cells.has(cell) or _clearing(p): continue
		if placed.any(func(t): return absi(t.x-cell.x)<=1 and absi(t.y-cell.y)<=1): continue
		var tree = {"cell":cell,"pos":p,"size":random.randf_range(0.8,1.3),"warm":random.randf()>0.72}
		placed.append(cell)
		if "%d,%d" % [cell.x,cell.y] in state.felled_trees:
			_prop("stump",p,{})
			continue
		solid_cells[cell]="tree"
		trees.append(tree)
		tree.node=_prop("tree",p,tree)
	for b in buildings: _prop("building",Vector2(b.x,b.y+b.h),b)
	for p in people: villagers[p.id]=_prop("person",Vector2(p.x,p.y),p)
	crops = _prop("crops",Vector2.ZERO,{})
	crops.z_index = 0
	player = _prop("player",state.player_position,{"coat":"6f9793","hair":"5c5045","skin":"d0a981","id":"player"})
	mayor = villagers.mayor
	update_villagers(0.0,true)
	var effects = _prop("effects",Vector2.ZERO,{})
	effects.z_index = 5
	_prop("sparkfire",site_position("sparkfire"),{"bloom":false})

func _claim(footprint: Rect2i,kind: String) -> void:
	for y in range(footprint.position.y,footprint.end.y):
		for x in range(footprint.position.x,footprint.end.x):
			var cell=Vector2i(x,y)
			assert(not solid_cells.has(cell),"Overlapping map footprints at %s" % cell)
			solid_cells[cell]=kind

func chop_tree(cell: Vector2i) -> bool:
	if state.active_item()!="axe" or state.axe<1 or state.energy<4 or not state.can_carry("wood"): return false
	var found=trees.filter(func(tree): return tree.cell==cell)
	if found.is_empty(): return false
	state.energy-=4
	tree_damage[cell]=tree_damage.get(cell,0)+1
	if tree_damage[cell]<3: return true
	var tree=found[0]
	state.wood+=3
	state.felled_trees.append("%d,%d" % [cell.x,cell.y])
	solid_cells.erase(cell)
	tree.node.queue_free()
	trees.erase(tree)
	_prop("stump",Grid.center(cell),{})
	return true

func rebuild_visit(new_state: RefCounted) -> void:
	for child in get_children(): child.free()
	for field in [people,villagers,routes,buildings,sites,road_segments,road_cells,water_cells,mountain_cells,solid_cells,reserved_cells,fence_cells,gate_cells,trees,bushes,particles,story_destinations,conversation_holds,indoor_departures,tree_damage]: field.clear()
	scenery_layer=null
	moving_layer=null
	crop_signature=0
	state=new_state
	_ready()

func _build_layout() -> void:
	for y in range(Grid.MAP_SIZE.y):
		for x in range(Coast.MIN_X,Grid.MAP_SIZE.x):
			var cell=Vector2i(x,y)
			var p=Grid.center(cell)
			var pond=(p-Grid.center(POND_CELL))/Vector2(160,160)
			if Coast.is_ocean(cell,state.world_seed) or pond.length_squared()<1.0:
				water_cells[cell]=true
				solid_cells[cell]="water"
	for cell in Coast.dock_cells():
		solid_cells.erase(cell)
		reserved_cells[cell]=true
	for dock in [JETTY_CELLS]:
		for y in range(dock.position.y,dock.end.y):
			for x in range(dock.position.x,dock.end.x):
				var cell=Vector2i(x,y)
				solid_cells.erase(cell)
				reserved_cells[cell]=true
	for y in range(29,46):
		for x in range(8,20): reserved_cells[Vector2i(x,y)]=true
	for item in PEOPLE:
		var p=item.duplicate(true)
		var pos=Grid.center(p.cell)
		p.x=pos.x
		p.y=pos.y
		people.append(p)
		reserved_cells[p.cell]=true
	for item in BUILDINGS:
		var b=item.duplicate(true)
		b.id=b.get("resident",b.kind)
		var bounds=Grid.rect(b.cell,b.tiles)
		b.x=bounds.position.x
		b.y=bounds.position.y
		b.w=bounds.size.x
		b.h=bounds.size.y
		buildings.append(b)
		_claim(Rect2i(b.cell,b.tiles),"building")
		var door_cell=b.cell+Vector2i(int(b.tiles.x/2),b.tiles.y)
		var door_pos=Grid.center(door_cell)
		var name={"home":"farmhouse","hall":"town hall","assistant":"Neral's home","keeper":"Oren's lighthouse"}.get(b.id,b.id.capitalize())
		sites.append({"id":"door_"+b.id,"cell":door_cell,"x":door_pos.x,"y":door_pos.y,"door":b.id,"label":"Enter "+name})
		reserved_cells[door_cell]=true
	for item in SITES:
		var p=item.duplicate(true)
		var pos=Grid.center(p.cell)
		p.x=pos.x
		p.y=pos.y
		if p.id=="pond": p.bounds=Grid.rect(JETTY_CELLS.position,JETTY_CELLS.size)
		sites.append(p)
		reserved_cells[p.cell]=true
	_claim(OUTCROP_CELLS,"rock")
	_claim(MINE_RIDGE,"rock")
	_claim(CART_CELLS,"cart")
	_claim(Rect2i(Vector2i(17,44),Vector2i.ONE),"chest")
	for cell in LAMP_CELLS: _claim(Rect2i(cell,Vector2i.ONE),"lamp")
	_claim(Rect2i(Grid.world_to_cell(site_position("sign")),Vector2i.ONE),"sign")
	_claim(Rect2i(Grid.world_to_cell(site_position("radio")),Vector2i.ONE),"radio")
	_claim(Rect2i(SQUARE.position+Vector2i(2,2),Vector2i(2,2)),"fountain")
	for x in range(50,77):
		var front=8+roundi(sin(x*0.23)*2.0+sin(x*0.57))
		if x in range(58,66): front=mini(front,9)
		for y in range(4,front+1):
			var cell=Vector2i(x,y)
			mountain_cells[cell]=true
			_claim(Rect2i(cell,Vector2i.ONE),"mountain")
	for y in range(SHIP_MOUNTAIN.position.y,SHIP_MOUNTAIN.end.y):
		for x in range(SHIP_MOUNTAIN.position.x,SHIP_MOUNTAIN.end.x):
			var cell=Vector2i(x,y)
			if not ship_mountain_cell(cell): continue
			if DESCENT_AREAS.any(func(area): return area.has_point(cell)):
				reserved_cells[cell]=true
			else:
				mountain_cells[cell]=true
				_claim(Rect2i(cell,Vector2i.ONE),"mountain")
	for y in range(SQUARE.position.y,SQUARE.end.y):
		for x in range(SQUARE.position.x,SQUARE.end.x): reserved_cells[Vector2i(x,y)]=true
	for routine in Schedule.ROUTINES.values():
		for stop in routine: reserved_cells[Vector2i(stop[1],stop[2])]=true
	for field in DECORATIVE_FIELDS:
		for y in range(field.position.y-1,field.end.y+1):
			for x in range(field.position.x-1,field.end.x+1): reserved_cells[Vector2i(x,y)]=true
	for y in [FARM_CELL.y-2,FARM_CELL.y+5]:
		for x in range(FARM_CELL.x-1,FARM_CELL.x+11):
			if x!=14: fence_cells.append(Vector2i(x,y))
		gate_cells.append(Vector2i(14,y))
	for y in range(FARM_CELL.y-1,FARM_CELL.y+5): fence_cells.append(Vector2i(FARM_CELL.x-1,y))
	for cell in fence_cells: _claim(Rect2i(cell,Vector2i.ONE),"fence")
	for route in ROAD_ROUTES:
		for i in range(route.size()-1):
			var a=route[i]
			var b=route[i+1]
			road_segments.append([Grid.center(a),Grid.center(b),Grid.TILE_SIZE*0.5])
			for y in range(mini(a.y,b.y),maxi(a.y,b.y)+1):
				for x in range(mini(a.x,b.x),maxi(a.x,b.x)+1): road_cells[Vector2i(x,y)]=true
	var approach=FARMHOUSE_APPROACH
	for i in range(approach.size()-1): road_segments.append([Grid.center(approach[i]),Grid.center(approach[i+1]),7.0])
	for path in Coast.PATHS:
		for i in range(path.size()-1): road_segments.append([Grid.center(path[i]),Grid.center(path[i+1]),6.0])

func site_position(id: String) -> Vector2:
	for site in sites:
		if site.id==id: return Grid.center(site.cell)
	return Vector2.ZERO

func farmhouse_approach(start: Vector2i) -> Array:
	var path=[]
	for cell in FARMHOUSE_APPROACH.slice(1):
		path.append_array(_route(start,cell))
		start=cell
	return path

func exit_position(building: Dictionary) -> Vector2:
	var door=building.cell+Vector2i(int(building.tiles.x/2),building.tiles.y)
	for cell in [door+Vector2i.DOWN,door,door+Vector2i.LEFT,door+Vector2i.RIGHT]:
		if not blocked(Grid.center(cell)): return Grid.center(cell)
	return Grid.center(Grid.SPAWN_CELL)

func _route(start: Vector2i,goal: Vector2i) -> Array:
	var frontier: Array=[goal]
	var parents={goal:goal}
	var cursor=0
	while cursor<frontier.size() and not parents.has(start):
		var cell: Vector2i=frontier[cursor]
		cursor+=1
		for offset in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
			var next: Vector2i=cell+offset
			if parents.has(next) or blocked(Grid.center(next)): continue
			parents[next]=cell
			frontier.append(next)
	var path: Array=[]
	var current=start
	while parents.has(current) and current!=goal:
		current=parents[current]
		path.append(Grid.center(current))
	return path

func update_villagers(dt: float,snap: bool=false) -> void:
	for id in villagers:
		if conversation_holds.has(id) or indoor_departures.has(id):
			villagers[id].data.walking=false
			villagers[id].queue_redraw()
			continue
		var stop=Schedule.stop(id,state.minute)
		if id=="vale": stop.room="ship"
		if id=="moss" and not state.invited: stop={"cell":MOSS_ENCOUNTER_CELL,"sleeping":false,"room":""}
		var visit=state.mayor_visit_start()
		if visit>=0 and state.total()>=visit+240: visit+=1440
		if id=="moss" and state.invited and not state.met_mayor and state.total()<state.mayor_due-60: stop={"cell":Vector2i(54,46),"sleeping":false,"room":"hall"}
		if id in ["moss","mayor","assistant"] and state.invited and not state.met_mayor and visit>=0 and state.total()>=visit-60 and state.total()<visit+240:
			var offset={"moss":Vector2i(3,0),"mayor":Vector2i(1,0),"assistant":Vector2i(2,1)}[id]
			stop={"cell":Grid.SPAWN_CELL+offset,"sleeping":false,"room":"home" if state.location=="home" and state.total()>=visit-8 else ""}
		if state.abandoned_day.get(id,0)==state.day: stop=Schedule.home_stop(id)
		if story_destinations.has(id): stop=story_destinations[id]
		var actor: Node2D=villagers[id]
		var previous=actor.position
		var target=Grid.center(stop.cell)
		if snap:
			actor.position=target
			routes.erase(id)
		elif not routes.has(id) or routes[id].target!=target:
			# Finish the current tile before turning toward a new appointment.
			var cell=Grid.world_to_cell(actor.position)
			var path=_route(cell,stop.cell)
			if actor.position.distance_to(Grid.center(cell))>0.1: path.push_front(Grid.center(cell))
			routes[id]={"target":target,"path":path}
		if routes.has(id):
			var remaining=dt*(180.0 if story_destinations.has(id) else 96.0 if id in ["moss","mayor","assistant"] and state.invited and not state.met_mayor else 56.0)
			var path: Array=routes[id].path
			while remaining>0 and not path.is_empty():
				var distance=actor.position.distance_to(path[0])
				actor.position=actor.position.move_toward(path[0],remaining)
				remaining-=distance
				if actor.position.distance_to(path[0])<0.01: path.pop_front()
				else: break
		var arrived=actor.position.distance_to(target)<1
		actor.data.room=stop.get("room","") if arrived else ""
		actor.data.sleeping=stop.sleeping and arrived
		actor.visible=not arrived or (not stop.sleeping and actor.data.room=="")
		var motion=actor.position-previous
		actor.data.walking=motion.length()>0.01 and not snap
		if motion.length()>0.01:
			actor.data.direction=("right" if motion.x>0 else "left") if absf(motion.x)>absf(motion.y) else ("down" if motion.y>0 else "up")
		actor.queue_redraw()

func _prop(kind: String, pos: Vector2, data: Dictionary) -> Prop:
	if scenery_layer==null:
		scenery_layer=Node2D.new()
		scenery_layer.name="StaticScenery"
		scenery_layer.y_sort_enabled=true
		add_child(scenery_layer)
		moving_layer=Node2D.new()
		moving_layer.name="MovingObjects"
		moving_layer.y_sort_enabled=true
		add_child(moving_layer)
	var p = Prop.new()
	p.owner_world = self
	p.kind = kind
	p.data = data
	p.position = pos
	(scenery_layer if kind in ["tree","building","bush","stump"] else moving_layer).add_child(p)
	return p

func refresh() -> void:
	var daylight=smoothstep(330.0,420.0,state.minute)*(1.0-smoothstep(1110.0,1200.0,state.minute))
	night_tint.color=Color(0.32,0.42,0.92).lerp(Color.WHITE,daylight)
	var ripe_mask=0
	for i in range(state.plots.size()):
		if state.ripe(i): ripe_mask|=1<<i
	var signature=hash(state.plots)^ripe_mask
	if signature!=crop_signature:
		crop_signature=signature
		crops.queue_redraw()
	player.position = state.player_position.round()
	player.queue_redraw()
	for child in scenery_layer.get_children()+moving_layer.get_children():
		if child is Prop:
			if child.kind == "effects": child.queue_redraw()
			elif child.kind=="sparkfire":
				var bloom=state.minute>=330 and state.minute<420 and state.sparkfire_picked_day!=state.day
				if child.data.bloom!=bloom: child.data.bloom=bloom; child.queue_redraw()
			elif child.kind in ["tree","building"]:
				var hidden=prop_hides_player(child)
				child.modulate.a=move_toward(child.modulate.a,0.22 if hidden else 1.0,0.14)

func prop_hides_player(prop: Prop) -> bool:
	if state.player_position.y>=prop.position.y: return false
	var bounds: Rect2
	if prop.kind=="tree":
		if Art.option==2:
			return Rect2(prop.position+Vector2(-48,-Art.sprite_size(Art.tree_id(prop.data)).y),Vector2(96,Art.sprite_size(Art.tree_id(prop.data)).y)).has_point(state.player_position-Vector2(0,20))
		var scale_factor=prop.data.size
		bounds=Rect2(prop.position+Vector2(-34,-92)*scale_factor,Vector2(68,94)*scale_factor)
	elif prop.kind=="building":
		var height=prop.data.get("visual_height",prop.data.h)
		bounds=Rect2(prop.position+Vector2(-14,-height-80),Vector2(prop.data.w+28,height+90))
	else: return false
	return bounds.intersects(Rect2(state.player_position-Vector2(12,44),Vector2(24,46)))

func target_plot() -> int:
	var direction={"up":Vector2.UP,"down":Vector2.DOWN,"left":Vector2.LEFT,"right":Vector2.RIGHT}[facing]
	var point=Grid.world_to_cell(state.player_position)+Vector2i(direction)-FARM_CELL
	var col=point.x
	var row=point.y
	return row*5+col if col>=0 and col<5 and row>=0 and row<4 else -1

func plot_position(i: int) -> Vector2:
	return Grid.center(FARM_CELL+Vector2i(i%5,int(i/5.0)))

func audio_context(player_position: Vector2) -> Dictionary:
	# A future interior supplies cave/mine instead of an outdoor environment.
	var distance=player_position.distance_to(site_position("ore"))
	var cave_weight=clampf(1.0-(distance-30.0)/120.0,0.0,1.0)
	return {"environment":"town" if player_position.x>Grid.origin(SQUARE.position).x-320 else "farm","season":state.season_name(),"cave_weight":cave_weight}

func in_water(p: Vector2) -> bool:
	var cell=Grid.world_to_cell(p)
	return water_cells.has(cell) and not JETTY_CELLS.has_point(cell) and not Coast.JETTY.has_point(cell) and not Coast.PLATFORM.has_point(cell)

func at_pond_edge(p: Vector2) -> bool:
	var cell=Grid.world_to_cell(p)
	if blocked(p) or JETTY_CELLS.has_point(cell): return false
	for direction in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
		var water=cell+direction
		if water_cells.has(water) and Grid.center(water).distance_to(Grid.center(POND_CELL))<190: return true
	return false

func fence_mask(cell: Vector2i) -> int:
	var mask=0
	for pair in [[Vector2i.LEFT,1],[Vector2i.RIGHT,2],[Vector2i.UP,4],[Vector2i.DOWN,8]]:
		if cell+pair[0] in fence_cells or cell+pair[0] in gate_cells: mask|=pair[1]
	return mask

func blocked(p: Vector2) -> bool:
	var cell=Grid.world_to_cell(p)
	return not Grid.PLAYABLE_CELLS.has_point(cell) or solid_cells.has(cell)

func find_nearest() -> Dictionary:
	if state.active_item()=="axe":
		var cell=Grid.world_to_cell(state.player_position)+{"up":Vector2i.UP,"down":Vector2i.DOWN,"left":Vector2i.LEFT,"right":Vector2i.RIGHT}[facing]
		if trees.any(func(tree): return tree.cell==cell): return {"type":"tree","cell":cell,"label":"Chop tree · axe"}
	if JETTY_CELLS.has_point(Grid.world_to_cell(state.player_position)):
		for site in sites:
			if site.id=="pond":
				var result=site.duplicate()
				result.type="site"
				return result
	var best: Dictionary = {}
	var distance = 55.0
	var i=target_plot()
	if i>=0:
		var d = state.player_position.distance_to(plot_position(i))
		if d<distance:
			var p = state.plots[i]
			var label = "Harvest moon turnip" if state.ripe(i) else "Till the soil" if not p.tilled else "Plant moon turnip" if p.planted<0 else "Water moon turnip" if not p.watered else "Growing · Q casts Wildgrowth"
			best = {"type":"plot","index":i,"label":label}
			distance = d
	for p in people:
		if not villagers[p.id].visible: continue
		var d = state.player_position.distance_to(villagers[p.id].position)
		if d<distance:
			best = p.duplicate()
			best.type = "person"
			best.label = "Talk to " + p.name
			distance = d
	for p in sites:
		if p.id=="pond": continue
		var interaction_point=Vector2(p.x,p.y)
		if p.has("bounds"):
			interaction_point=state.player_position.clamp(p.bounds.position,p.bounds.end)
		var d = state.player_position.distance_to(interaction_point)
		if d<distance or (p.has("door") and d<=distance):
			best = p.duplicate()
			best.type = "site"
			distance = d
	if best.is_empty(): best=coastal_fishing(state.player_position)
	nearest = best
	return best

func coastal_fishing(p: Vector2) -> Dictionary:
	return Coast.fishing_site(self,p)

func _clearing(p: Vector2) -> bool:
	if Grid.rect(JETTY_CELLS.position,JETTY_CELLS.size).grow(64).has_point(p): return true
	if Grid.rect(FARM_CELL-Vector2i(2,5),Vector2i(15,14)).has_point(p) or Grid.rect(SQUARE.position-Vector2i(5,6),Vector2i(18,17)).has_point(p) or Rect2(Grid.center(SHIP_CELL)-Vector2(120,100),Vector2(240,230)).has_point(p) or Grid.rect(OUTCROP_CELLS.position,OUTCROP_CELLS.size).grow(100).has_point(p): return true
	for b in buildings:
		if Rect2(b.x,b.y,b.w,b.h).grow(65).has_point(p): return true
	for segment in road_segments:
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p,segment[0],segment[1]))<segment[2]+35.0: return true
	return in_water(p)

func _build_terrain() -> void:
	var image = Image.create(int(SIZE.x),int(SIZE.y),false,Image.FORMAT_RGBA8)
	image.fill(Color("748c53"))
	var random = RandomNumberGenerator.new()
	random.seed = state.world_seed+73
	var colors = [Color("7a9258"),Color("6f884f"),Color("83975d"),Color("81965a")]
	for i in range(180000): image.fill_rect(Rect2i(random.randi_range(0,int(SIZE.x)-5),random.randi_range(0,int(SIZE.y)-3),random.randi_range(2,5),2),colors[i%4])
	if Art.option==2:
		Art.load_atlas()
		for y in range(Grid.MAP_SIZE.y):
			for x in range(Grid.MAP_SIZE.x): image.blit_rect(Art.tile_image("grass"+str(random.randi_range(0,3))),Rect2i(0,0,32,32),Vector2i(x,y)*32)
	_paint_grounding(image,random)
	_paint_roads(image,random)
	_paint_water(image)
	var decorated_cells={}
	for i in range(8400):
		var cell=Vector2i(random.randi_range(4,Grid.MAP_SIZE.x-4),random.randi_range(5,Grid.MAP_SIZE.y-4))
		var p=Grid.center(cell)
		if decorated_cells.has(cell) or solid_cells.has(cell) or _clearing(p): continue
		decorated_cells[cell]=true
		image.fill_rect(Rect2i(p.x,p.y,2,5),Color("597b48"))
		if i%3 == 0: image.fill_rect(Rect2i(p.x-1,p.y-2,4,3),Color("ddd79b") if i%2 else Color("c1acc2"))
	terrain = ImageTexture.create_from_image(image)
	west_terrain=Coast.build_texture(self)
	queue_redraw()

func _paint_grounding(image: Image,random: RandomNumberGenerator) -> void:
	# Rock dust, worn yards and grass share a broken edge rather than a hard outline.
	for y in range(96,int(SIZE.y)-64,3):
		for x in range(96,int(SIZE.x)-64,3):
			var p=Vector2(x,y)
			var mine=(p-Grid.rect(OUTCROP_CELLS.position,OUTCROP_CELLS.size).get_center())/Vector2(225,155)
			var highland=(p-Grid.center(Vector2i(63,9)))/Vector2(520,220)
			var mineral=maxf(1.0-mine.length(),1.0-highland.length())
			if mineral+random.randf_range(-0.2,0.2)>0.04:
				var stone=Color("96977f").lerp(Color("777f73"),clampf(mineral,0,1))
				var broken_edge=sin(x*0.037+y*0.019)*0.07+cos(y*0.061-x*0.013)*0.04
				var coverage=clampf((mineral+broken_edge)*2.4,0,1)
				image.fill_rect(Rect2i(x,y,3,3),image.get_pixel(x,y).lerp(stone.lightened(random.randf_range(-0.025,0.025)),coverage))
	for b in buildings:
		var yard=Rect2(b.x-23,b.y+b.h-10,b.w+46,51)
		for i in range(int(b.w)*6):
			var p=Vector2(random.randf_range(yard.position.x,yard.end.x),random.randf_range(yard.position.y,yard.end.y))
			if random.randf()>0.65 and absf(p.x-(b.x+b.w/2))>25: continue
			image.fill_rect(Rect2i(p,Vector2i(3,2)),Color("9c956f").lightened(random.randf_range(-0.08,0.08)))
		# Individual stepping stones lead out from the door into the worn yard.
		for i in range(3):
			var x=int(b.x+b.w/2)-12+(i%2)*3
			var y=int(b.y+b.h)+9+i*10
			image.fill_rect(Rect2i(x,y,22,7),Color("9a9d87"))
			image.fill_rect(Rect2i(x+2,y,17,2),Color("b4b59b"))

func _paint_water(image: Image) -> void:
	for cell in water_cells:
		if cell.x<0: continue
		var origin=Vector2i(Grid.origin(cell))
		image.fill_rect(Rect2i(origin,Vector2i.ONE*Grid.TILE_SIZE),Color("51868a"))
		for direction in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
			if water_cells.has(cell+direction): continue
			var edge=Rect2i(origin,Vector2i.ONE*Grid.TILE_SIZE)
			if direction.x!=0:
				edge.size.x=4
				if direction.x>0: edge.position.x+=Grid.TILE_SIZE-4
			else:
				edge.size.y=4
				if direction.y>0: edge.position.y+=Grid.TILE_SIZE-4
			image.fill_rect(edge,Color("91a274"))
		for corner in [Vector2i(-1,-1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(1,1)]:
			if water_cells.has(cell+Vector2i(corner.x,0)) or water_cells.has(cell+Vector2i(0,corner.y)): continue
			var start=origin+Vector2i(0 if corner.x<0 else 24,0 if corner.y<0 else 24)
			for y in range(8):
				for x in range(8):
					var p=Vector2(x if corner.x<0 else 7-x,y if corner.y<0 else 7-y)
					if p.distance_to(Vector2(8,8))>8.0: image.set_pixelv(start+Vector2i(x,y),Color("84965d"))

func _paint_roads(image: Image,random: RandomNumberGenerator) -> void:
	road_mask=Image.create(int(SIZE.x),int(SIZE.y),false,Image.FORMAT_L8)
	road_mask.fill(Color.BLACK)
	var tracks=Image.create(int(SIZE.x),int(SIZE.y),false,Image.FORMAT_L8)
	tracks.fill(Color.BLACK)
	# Merge the whole network before shading its shoulders, so junctions have no seams.
	for segment in road_segments:
		var bounds=Rect2(segment[0],Vector2.ZERO).expand(segment[1]).grow(segment[2]+9.0)
		bounds=bounds.intersection(Rect2(Vector2.ZERO,SIZE-Vector2(2,2)))
		for y in range(int(bounds.position.y/2.0)*2,int(bounds.end.y)+2,2):
			for x in range(int(bounds.position.x/2.0)*2,int(bounds.end.x)+2,2):
				var p=Vector2(x+1,y+1)
				var distance=p.distance_to(Geometry2D.get_closest_point_to_segment(p,segment[0],segment[1]))
				var roughness=sin(x*0.071)*1.5+sin(y*0.113)*1.3
				var core=maxf(2.0,segment[2]-3.0+roughness)
				var coverage=1.0-smoothstep(core,maxf(core+1,segment[2]+5.0+roughness),distance)
				if coverage>road_mask.get_pixel(x,y).r:
					road_mask.fill_rect(Rect2i(x,y,2,2),Color(coverage,coverage,coverage))
				var rut=maxf(0.0,1.0-absf(distance-segment[2]*0.43)/2.0)*0.08
				if rut>tracks.get_pixel(x,y).r: tracks.fill_rect(Rect2i(x,y,2,2),Color(rut,rut,rut))
	for y in range(0,int(SIZE.y),2):
		for x in range(0,int(SIZE.x),2):
			var coverage=road_mask.get_pixel(x,y).r
			if coverage<=0.0: continue
			var dirt=Color("b8a47a").lightened(random.randf_range(-0.035,0.035))
			dirt=dirt.darkened(tracks.get_pixel(x,y).r)
			if random.randf()<0.035: dirt=dirt.lightened(0.12)
			image.fill_rect(Rect2i(x,y,2,2),image.get_pixel(x,y).lerp(dirt,coverage))

func r(c: CanvasItem, x: float,y: float,w: float,h: float,color: String) -> void:
	c.draw_rect(Rect2(roundf(x),roundf(y),w,h),Color(color))

func poly(c: CanvasItem, points: Array, color: String) -> void:
	c.draw_colored_polygon(PackedVector2Array(points),Color(color))

func oval(c: CanvasItem, x: float,y: float,rx: float,ry: float,color: String) -> void:
	var points = PackedVector2Array()
	for i in range(20): points.append(Vector2(x+cos(i*TAU/20)*rx,y+sin(i*TAU/20)*ry).round())
	c.draw_colored_polygon(points,Color(color))

func _draw() -> void:
	if Art.option==2:
		if terrain: Art.outdoors(self)
		return
	# Raised terrain and paths share their boundaries with the solid-cell map.
	if not terrain: return
	draw_texture(terrain,Vector2.ZERO)
	Coast.draw(self)
	paint_cliffs(self)
	for y in range(SQUARE.position.y,SQUARE.end.y):
		for x in range(SQUARE.position.x,SQUARE.end.x):
			var p=Grid.origin(Vector2i(x,y))
			r(self,p.x,p.y,32,32,"a6a58b")
			r(self,p.x+1,p.y+1,30,30,"babb9f" if (x+y)%2==0 else "b4b69b")
			for i in range(6):
				var xx=(i%2)*15+2
				var yy=int(i/2)*10+2
				r(self,p.x+xx,p.y+yy,13,8,"afb198" if (i+x+y)%3 else "c0bfa4")
				r(self,p.x+xx+1,p.y+yy,10,1,"cbcab0")
	var fountain=Grid.origin(SQUARE.position+Vector2i(2,2))
	oval(self,fountain.x+32,fountain.y+34,32,25,"747f7d")
	oval(self,fountain.x+32,fountain.y+29,27,19,"709fa9")
	r(self,fountain.x+27,fountain.y+2,10,30,"c9cbb1")
	oval(self,fountain.x+32,fountain.y+4,16,7,"d7d4b9")
	paint_rock_mass(self,Grid.origin(MINE_RIDGE.position+Vector2i(0,MINE_RIDGE.size.y+2)),MINE_RIDGE.size.x*Grid.TILE_SIZE,(MINE_RIDGE.size.y+2)*Grid.TILE_SIZE,117)
	draw_set_transform(Grid.origin(JETTY_CELLS.position))
	var dock_width=JETTY_CELLS.size.x*Grid.TILE_SIZE
	r(self,0,0,dock_width,32,"655d46")
	for i in range(dock_width/8): r(self,1+i*8,0,6,32,"b09b6c")
	for x in [2,dock_width-7]:
		r(self,x,-10,5,48,"776a4e")
		r(self,x,-12,5,3,"d0bb87")
	draw_set_transform(Vector2.ZERO)
	for cell in fence_cells:
		var p=Grid.origin(cell)
		if cell.x==FARM_CELL.x-1 and cell.y not in [FARM_CELL.y-2,FARM_CELL.y+5]:
			r(self,p.x+14,p.y,4,32,"a28d64")
			r(self,p.x+12,p.y+2,8,27,"b8a77a")
		else: _fence(p.x,p.y+2,Grid.TILE_SIZE)
	var field=Grid.rect(FARM_CELL,Vector2i(5,4))
	var chest=site_position("chest")
	r(self,chest.x-15,chest.y-21,30,22,"796345")
	r(self,chest.x-15,chest.y-26,30,8,"baa06d")
	r(self,chest.x+8,chest.y-19,7,20,"5e5741")
	r(self,chest.x-2,chest.y-18,5,8,"e0c38c")
	draw_rect(field.grow(3),Color("596341"))
	draw_rect(field,Color("7b6446"))
	for garden in DECORATIVE_FIELDS: paint_decorative_garden(garden)
	var rock_width=OUTCROP_CELLS.size.x*Grid.TILE_SIZE
	var rock_height=OUTCROP_CELLS.size.y*Grid.TILE_SIZE
	draw_set_transform(Grid.origin(OUTCROP_CELLS.position)+Vector2(rock_width/2,rock_height))
	paint_rock_mass(self,Vector2(-rock_width/2,0),rock_width,rock_height,71)
	oval(self,0,-34,27,32,"344e47")
	poly(self,[Vector2(-24,-7),Vector2(-24,-39),Vector2(-17,-57),Vector2(8,-62),Vector2(23,-49),Vector2(26,-7)],"293d39")
	poly(self,[Vector2(-17,-8),Vector2(-17,-35),Vector2(-8,-50),Vector2(11,-47),Vector2(19,-32),Vector2(19,-8)],"1e302e")
	for i in range(7):
		var a=PI+i*PI/6.0
		var p=Vector2(cos(a)*31,-29+sin(a)*34)
		poly(self,[p+Vector2(-7,-4),p+Vector2(5,-7),p+Vector2(9,5),p+Vector2(-6,9)],"9ba28a" if i%2 else "7f8b7b")
		r(self,p.x-4,p.y-4,8,2,"b0b498")
	for i in range(20):
		var x=-rock_width/2+7+(i*37)%(rock_width-12)
		var y=-6+(i*11)%18
		poly(self,[Vector2(x,y),Vector2(x+5,y-4),Vector2(x+10,y+1),Vector2(x+7,y+4)],"7c8876" if i%3 else "a2a488")
	draw_set_transform(Grid.center(SHIP_CELL))
	oval(self,0,0,87,43,"6d8958")
	oval(self,0,0,71,30,"7b9060")
	draw_set_transform(Grid.origin(CART_CELLS.position))
	r(self,3,0,84,24,"8e7651")
	r(self,0,-3,90,6,"b6a073")
	for x in [17,71]:
		oval(self,x,26,9,9,"445249")
		oval(self,x,26,4,4,"bcaa7a")
	for i in range(4):
		r(self,11+i*18,-15,15,12,"9b855c")
		for k in range(3): oval(self,14+i*18+k*4,-16,3,3,"b3b56b" if i%2 else "c29162")
	draw_set_transform(Vector2.ZERO)
	for cell in LAMP_CELLS:
		var p=Grid.center(cell)
		r(self,p.x,p.y-74,4,74,"5b6957")
		r(self,p.x-7,p.y-79,18,5,"536251")
		r(self,p.x-5,p.y-74,14,17,"d2c690")
		r(self,p.x-3,p.y-72,10,11,"f1dfac")
	draw_set_transform(site_position("sign"))
	r(self,-3,-48,6,55,"837350")
	r(self,-28,-43,62,15,"bbab7b")
	r(self,-31,-24,53,13,"a99769")
	draw_string(ThemeDB.fallback_font,Vector2(-23,-32),"TOWN >",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("515d49"))
	draw_string(ThemeDB.fallback_font,Vector2(-28,-14),"< FARM",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("515d49"))
	draw_set_transform(site_position("radio"))
	r(self,-20,-12,42,7,"9b855e")
	r(self,-17,-5,4,18,"746849")
	r(self,15,-5,4,18,"746849")
	r(self,-12,-35,25,23,"816d4d")
	r(self,-9,-32,19,12,"4a6055")
	r(self,-6,-16,4,3,"d8c08a")
	r(self,3,-16,4,3,"d8c08a")
	draw_set_transform(Vector2.ZERO)

func _fence(x: float,y: float,w: int) -> void:
	r(self,x,y+4,w,4,"a28d64")
	r(self,x,y+16,w,4,"a28d64")
	for i in range(0,w+1,Grid.TILE_SIZE):
		r(self,x+i,y,5,27,"b8a77a")
		r(self,x+i-1,y-3,7,5,"d0be8b")

func paint_decorative_garden(bounds: Rect2i) -> void:
	for y in range(bounds.position.y,bounds.end.y):
		for x in range(bounds.position.x,bounds.end.x):
			var p=Grid.center(Vector2i(x,y))
			r(self,p.x-15,p.y-15,30,30,"796247")
			for i in range(3):
				r(self,p.x-12+i*9,p.y-11,2,22,"5e513d")
				r(self,p.x-8+i*8,p.y-5,4,11,"66874e")
				r(self,p.x-10+i*8,p.y-6,8,4,"93a864")
				if bounds==VETERAN_GARDEN and (x+y+i)%3==0: oval(self,p.x-7+i*8,p.y-8,3,3,"d5ba81")

func rock_surface(c: CanvasItem,p: Vector2,w: int,h: int,seed_value: int,edge: bool) -> void:
	r(c,p.x,p.y,w,h,"7d8879")
	for i in range(12):
		var x=posmod(seed_value+i*19,w-5)
		var y=posmod(seed_value*3+i*11,h-3)
		r(c,p.x+x,p.y+y,4+posmod(i*3,9),2,"929b84" if i%3 else "64776b")
	if edge:
		r(c,p.x,p.y+h-8,w,8,"536b61")
		for i in range(3):
			var x=posmod(seed_value+i*13,w-8)
			r(c,p.x+x,p.y+h-11,7,2,"acb093")
	if seed_value%3==0:
		c.draw_polyline(PackedVector2Array([p+Vector2(8,2),p+Vector2(14,13),p+Vector2(10,24)]),Color("52685e"),1)

func ship_mountain_cell(cell: Vector2i) -> bool:
	var left=5+roundi(sin(cell.y*0.23)*1.7+(cell.y-5)*0.06)
	var right=20+roundi(sin(cell.y*0.31)*1.4)
	return SHIP_MOUNTAIN.has_point(cell) and cell.x>=left and cell.x<=right

func paint_cliffs(c: CanvasItem) -> void:
	for y in range(SHIP_MOUNTAIN.position.y,SHIP_MOUNTAIN.end.y):
		for x in range(SHIP_MOUNTAIN.position.x,SHIP_MOUNTAIN.end.x):
			var cell=Vector2i(x,y)
			var p=Grid.origin(cell)
			if not ship_mountain_cell(cell): continue
			if not mountain_cells.has(cell):
				r(c,p.x,p.y,32,32,"9a987d")
				for i in range(4): r(c,p.x+posmod(x*11+i*17,29),p.y+posmod(y*13+i*7,29),3,2,"b6b299")
				if x==13 and y>=24:
					for yy in [5,16,27]: r(c,p.x+2,p.y+yy,28,2,"6d776b")
				continue
			r(c,p.x,p.y,32,32,"748275")
			for dx in range(0,32,4):
				var weather=sin((p.x+dx)*0.009)*sin(p.y*0.011)
				r(c,p.x+dx,p.y,4,32,Color("778378").lightened(weather*0.07).to_html(false))
			for i in range(3):
				var px=p.x+posmod(x*17+y*7+i*13,25)
				var py=p.y+posmod(y*19+x*11+i*7,28)
				r(c,px,py,3+i*2,2,"84917d" if i%2 else "627366")
			if sin(x*0.7+y*0.43)>0.87:
				var offset=int(sin(x*0.4+y)*6)
				r(c,p.x,p.y+14+offset,32,2,"89947e")
				r(c,p.x+2,p.y+17+offset,28,1,"5f7265")
			if not mountain_cells.has(cell+Vector2i.LEFT):
				poly(c,[p+Vector2(0,0),p+Vector2(5,8),p+Vector2(3,24),p+Vector2(6,32),p+Vector2(0,32)],"a0a98f")
			if not mountain_cells.has(cell+Vector2i.RIGHT):
				poly(c,[p+Vector2(27,0),p+Vector2(25,15),p+Vector2(29,25),p+Vector2(26,32),p+Vector2(32,32),p+Vector2(32,0)],"4e6659")
			if not mountain_cells.has(cell+Vector2i.DOWN):
				r(c,p.x,p.y+12,32,20,"526858")
				r(c,p.x,p.y+12,32,3,"a2aa8e")
				for yy in [19,26]: r(c,p.x,p.y+yy,32,2,"788773")
	# Continuous strata follow one eroded ridge rather than repeating a wall tile.
	var random=RandomNumberGenerator.new()
	random.seed=93
	for x in range(50,77):
		var front=4
		while mountain_cells.has(Vector2i(x,front)): front+=1
		var bottom=front*Grid.TILE_SIZE
		for dx in range(0,Grid.TILE_SIZE,4):
			var px=x*Grid.TILE_SIZE+dx
			var variation=int(sin(px*0.03)*3)
			r(c,px,0,4,bottom,"7f8c7b")
			r(c,px,bottom-12+variation,4,12-variation,"566e60")
			for depth in [20,43,68,96,125,156,190]:
				if depth>bottom: continue
				var yy=bottom-depth+int(sin(px*0.024+depth)*4)
				r(c,px,yy,4,3,"a0aa8f")
				r(c,px,yy+4,4,2,"6a7d6c")
		for i in range(30):
			var px=x*32+random.randi_range(1,27)
			var py=random.randi_range(maxi(0,bottom-180),bottom-16)
			r(c,px,py,random.randi_range(3,11),2,"8f9c83" if i%3 else "6b7e6b")

func paint_rock_mass(c: CanvasItem,base: Vector2,w: int,h: int,seed_value: int) -> void:
	var random=RandomNumberGenerator.new()
	random.seed=seed_value
	# A continuous stepped silhouette reads as a hillside instead of separate boulders.
	for x in range(0,w,4):
		var arch=pow(maxf(0.0,sin(PI*(x+2)/float(w))),0.35)
		var height=int((h-12)*arch+sin(x*0.081)*5+sin(x*0.19)*3)
		height=maxi(6,height)
		r(c,base.x+x,base.y-height,4,height,"7c897a")
		r(c,base.x+x,base.y-height,4,6,"a4ac91")
		for y in range(12,height-6,19):
			var offset=int(sin(x*0.05+y)*3)
			if sin(x*0.13+y)>-0.3:
				r(c,base.x+x,base.y-y+offset,4,2,"606f65")
				r(c,base.x+x,base.y-y+offset-3,4,2,"929e85")
	for i in range(int(w*0.75)):
		var x=random.randf_range(8,w-8)
		var height=(h-20)*pow(sin(PI*x/w),0.35)
		var y=random.randf_range(5,maxf(6,height))
		r(c,base.x+x,base.y-y,random.randi_range(2,9),random.randi_range(1,3),"a0a68d" if i%3 else "6a7b6c")
	for i in range(int(w/9)):
		var x=i*9+random.randf_range(-3,3)
		r(c,base.x+x,base.y-4,7,4,"6d835e")
		r(c,base.x+x+2,base.y-8,3,5,"899b70")

func paint_tree(c: CanvasItem, data: Dictionary) -> void:
	if Art.option==2: Art.tree(c,data); return
	var s = data.size
	oval(c,7,6,28*s,10*s,"263d3450")
	r(c,-5*s,-38*s,11*s,40*s,"6d6547")
	r(c,-s,-30*s,4*s,31*s,"93805a")
	var colors = ["496c51","638653","849755"] if data.warm else ["365e4b","4c7a50","6c9257"]
	for p in [[-29,-60,56,30,0],[-22,-78,44,30,0],[-13,-91,28,27,0],[-25,-67,41,25,1],[-17,-84,29,26,1],[-19,-72,19,12,2],[-10,-86,13,10,2],[5,-56,20,15,1],[-33,-51,18,15,0]]:
		r(c,p[0]*s,p[1]*s,p[2]*s,p[3]*s,colors[p[4]])
	var leaves=RandomNumberGenerator.new()
	leaves.seed=int(data.pos.x*17+data.pos.y*31)
	for i in range(65):
		var x=leaves.randi_range(-27,24)
		var y=leaves.randi_range(-78,-43)
		if absf(x)>20 and y<-69: continue
		r(c,x*s,y*s,(3+i%4)*s,2*s,colors[2] if i%3 else colors[0])
	for x in [-13,-7,8]:
		poly(c,[Vector2(0,-8)*s,Vector2(x,5)*s,Vector2(x+sign(x)*4,3)*s],"6d6547")
	r(c,-18*s,-64*s,5*s,3*s,"91a05d")
	r(c,8*s,-46*s,5*s,3*s,"779453")

func paint_building(c: CanvasItem, b: Dictionary) -> void:
	if Art.option==2: Art.building(c,b); return
	var w = b.w
	var h = b.get("visual_height",b.h)
	var y = -h
	if b.kind=="tower":
		r(c,8,y,w-16,h,"9295a2")
		r(c,8,y,12,h,"a5acaf")
		r(c,w-22,y,14,h,"707e8c")
		oval(c,w/2,0,w/2-8,15,"707e8c")
		oval(c,w/2,y,w/2-8,15,"a5acaf")
		for yy in range(int(y)+8,0,12):
			r(c,9,yy,w-18,2,"737b8b")
			for xx in range(12,w-16,17):
				r(c,xx+(int(yy/12.0)%2)*6,yy-9,1,9,"727f83")
				r(c,xx+2,yy-8,9,1,"a6adab")
		poly(c,[Vector2(-8,y),Vector2(w/2,y-76),Vector2(w+8,y)],"68658f")
		for i in range(1,8):
			var yy=y-i*9
			var inset=i*6
			r(c,-6+inset,yy,w+12-inset*2,2,"89829e")
		r(c,8,-15,w-16,15,"697c70")
		for i in range(15): r(c,12+(i*17)%int(w-24),-3-(i*7)%27,3,3,"869776")
		for yy in [-150,-96]:
			r(c,w/2-8,yy,16,26,"e1c786")
		r(c,w/2-13,-42,26,42,"526c75")
		c.draw_string(ThemeDB.fallback_font,Vector2(25,-48),"IONA",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("dfd3ab"))
		return
	oval(c,w*0.6,5,w*0.65,19,"233f3338")
	r(c,0,y,w,h,"d0c298")
	r(c,5,y+8,w-10,h-8,"c0b58f")
	if b.kind=="cabin":
		r(c,0,y,w,h,"877357")
		for yy in range(int(y)+4,0,12):
			r(c,-4,yy,w+8,9,"a08760")
			r(c,1,yy+1,w-2,2,"b49a6d")
			oval(c,0,yy+5,5,5,"c0a377")
			oval(c,w,yy+5,5,5,"c0a377")
	for yy in range(y+12,0,12): r(c,6,yy,w-12,1,"a89f7d")
	r(c,0,y,w,5,"e0d0a6")
	r(c,0,y,6,h,"e0d0a6")
	r(c,w-6,y,6,h,"8e947a")
	r(c,-5,-9,w+10,13,"9a9478")
	r(c,9,-7,w-18,3,"b3ab8c")
	for i in range(int(w/14)):
		var xx=i*14+3
		r(c,xx,-8,11,4,"797f69")
		r(c,xx,-8,9,1,"cac4a0")
	# Small plaster chips and weather streaks break up the broad flat wall planes.
	for i in range(int(w)):
		var xx=9+(i*29)%int(w-18)
		var yy=y+14+(i*17)%int(h-30)
		r(c,xx,yy,2+i%3,1,"b1ab86" if i%3 else "d5c8a1")
	var door = w*0.5-13
	r(c,door-3,-54,32,48,"7b795d")
	r(c,door,-51,26,45,"5d7869")
	r(c,door+4,-46,18,17,"829f91")
	r(c,door+21,-28,3,3,"d4b87c")
	if b.has("resident"):
		r(c,door-5,-69,37,11,"77765c")
		var plaque="ALDER" if b.resident=="mayor" else "BRAM" if b.resident=="veteran" else b.resident.to_upper()
		c.draw_string(ThemeDB.fallback_font,Vector2(door-2,-61),plaque,HORIZONTAL_ALIGNMENT_LEFT,-1,7,Color("e2d2a5"))
	r(c,door-9,4,44,6,"b7af8b")
	for x in [22,w-49]:
		r(c,x-3,-65,31,36,"eee0b0")
		r(c,x,-62,25,28,"759e9b")
		r(c,x+11,-62,3,28,"d5cca3")
		r(c,x,-49,25,3,"d5cca3")
		r(c,x-6,-28,37,5,"8a8664")
		if b.kind in ["home","cottage"]:
			r(c,x-4,-24,33,8,"897b56")
			for i in range(5): r(c,x+i*6,-28,4,5,"cb9b96" if i%2 else "a4ad74")
	var roof_y = y-58
	poly(c,[Vector2(-14,y+14),Vector2(14,roof_y),Vector2(w-14,roof_y),Vector2(w+14,y+14)],b.roof)
	poly(c,[Vector2(-14,y+14),Vector2(-10,y+21),Vector2(w+15,y+21),Vector2(w+14,y+14)],"614e46")
	r(c,16,roof_y-4,w-32,7,"c08d72")
	for yy in range(roof_y+10,y+12,10):
		var inset = (y+14-yy)*0.4
		r(c,-12+inset,yy,w+24-inset*2,2,"543f4144")
		for x in range(int(inset),int(w-inset),17): r(c,x+(int(yy/10.0)%2)*8,yy-7,1,7,"e3c09a33")
		for x in range(int(inset)+3,int(w-inset)-5,13):
			r(c,x,yy-5,7,1,"d6b69555")
			r(c,x+3,yy-2,6,1,"433f4544")
	for i in range(9):
		var xx=8+i*11
		r(c,xx,y+12,5,2,"7d896344")
	if b.get("resident","") in ["moss","tavi","finch","mayor"]:
		var resident=b.resident
		for i in range(5):
			r(c,3+i*5,-14-i%3*3,3,9,"718855")
			r(c,3+i*5,-16-i%3*3,3,3,"c6b68b" if resident=="moss" else "ad8d91")
		if resident=="tavi":
			for i in range(3):
				r(c,w-26+i*7,-20+i*4,14,15,"8e7754")
				r(c,w-25+i*7,-18+i*4,12,2,"c0a778")
		elif resident=="finch":
			r(c,w-22,-30,2,30,"6c8079")
			r(c,w-34,-28,25,2,"b3b49a")
	r(c,w-42,roof_y-17,18,29,"8a7f6a")
	r(c,w-45,roof_y-20,24,6,"b6ab8d")
	if b.kind == "radio":
		r(c,35,y-125,3,78,"9b9e85")
		r(c,8,y-115,60,2,"bac0a3")
		r(c,20,y-101,36,2,"bac0a3")
		r(c,44,-20,75,13,"617b73")
		c.draw_string(ThemeDB.fallback_font,Vector2(47,-10),"RADIO CLUB",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("e3d4a7"))
	if b.kind == "store":
		r(c,-8,-80,w+16,23,"d7c69d")
		for i in range(0,w+16,22): r(c,-8+i,-80,11,23,"8d9a70")
		r(c,42,-104,82,17,"75694e")
		c.draw_string(ThemeDB.fallback_font,Vector2(50,-92),"PROVISIONS",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("e9d7ad"))

func paint_person(c: CanvasItem, p: Dictionary, step: float, direction: String) -> void:
	if Art.option==2: Art.person(c,p,step,direction); return
	if p.get("sleeping",false):
		var pillow_y=-float(p.get("bed_height",64))+20
		# The body runs down the mattress beneath its blanket.
		r(c,-7,pillow_y-7,14,15,p.skin)
		r(c,-7,pillow_y-8,14,4,p.hair)
		r(c,-7,pillow_y-4,2,8,p.hair)
		for x in [-4,2]: r(c,x,pillow_y+2,3,1,"454b48")
		r(c,-8,pillow_y+8,17,5,p.coat)
		r(c,-10,pillow_y+12,21,3,"a2b7a7")
		return
	oval(c,0,2,10,4,"213e3560")
	r(c,-7,-14,6,13+step*2,"344a4b")
	r(c,2,-14,6,13-step*2,"344a4b")
	r(c,-8,-2+step*2,7,3,"4a4b3e")
	r(c,2,-2-step*2,7,3,"4a4b3e")
	r(c,-8,-29,17,18,p.coat)
	r(c,-5,-27,3,16,"ffffff22")
	r(c,-12,-26,4,13,p.coat)
	r(c,9,-26,4,13,p.coat)
	r(c,-12,-14,4,5,p.skin)
	r(c,9,-14,4,5,p.skin)
	r(c,-6,-42,13,14,p.skin)
	r(c,-7,-43,15,5,p.hair)
	r(c,-7,-38,3,7,p.hair)
	r(c,5,-38,3,7,p.hair)
	if direction != "up":
		r(c,-3,-35,2,2,"33403a")
		r(c,3,-35,2,2,"33403a")
		r(c,0,-31,3,1,"8c6551")
	else: r(c,-5,-39,11,8,p.hair)
	if p.get("elf",false):
		poly(c,[Vector2(-6,-39),Vector2(-13,-44),Vector2(-9,-32)],p.skin)
		poly(c,[Vector2(6,-39),Vector2(13,-44),Vector2(9,-32)],p.skin)
	if p.get("hat",false):
		r(c,-12,-44,25,4,"d2ba7e")
		r(c,-7,-51,15,8,"c3a773")
		r(c,-7,-45,15,2,"806b4a")
	if p.get("cat",false):
		poly(c,[Vector2(-7,-42),Vector2(-8,-50),Vector2(-1,-43)],p.hair)
		poly(c,[Vector2(1,-43),Vector2(8,-50),Vector2(7,-41)],p.hair)
		r(c,11,-17,7,3,p.hair)
		r(c,16,-23,3,8,p.hair)
	if p.get("id") == "player":
		r(c,-7,-27,14,3,"d8bc7c")
		r(c,4,-23,3,3,"dfc98f")
		r(c,-7,-18,14,3,"4e665e")
		if state.equipped=="rusty_sword":
			r(c,12,-26,3,28,"aab1a5")
			r(c,8,-8,12,3,"b39a66")
			r(c,12,-5,3,8,"796448")

func paint_sparkfire(c: CanvasItem,bloom: bool) -> void:
	if Art.option==2: Art.sprite(c,"sparkfire_bloom" if bloom else "sparkfire",Vector2(-16,-42)); return
	oval(c,0,1,12,5,"465c4355")
	r(c,-1,-18,3,20,"526d43")
	for p in [Vector2(-7,-10),Vector2(7,-6),Vector2(-4,-3)]:
		oval(c,p.x,p.y,6,3,"7e9451")
	if bloom:
		for i in range(6):
			var p=Vector2(cos(i*TAU/6),sin(i*TAU/6))*7+Vector2(0,-20)
			oval(c,p.x,p.y,5,4,"e4bb55")
		oval(c,0,-20,4,4,"fff0a3")

func paint_crops(c: CanvasItem) -> void:
	if Art.option==2: Art.crops(self,c); return
	for i in range(20):
		var p = state.plots[i]
		var pos = plot_position(i)
		var x = pos.x
		var y = pos.y
		if not p.tilled:
			r(c,x-13,y-10,26,20,"89724e")
			for j in range(3): r(c,x-10+j*8,y-8,2,16,"a08456")
			continue
		r(c,x-14,y-12,28,24,"655b43" if p.watered else "8b6947")
		for j in range(4): r(c,x-11+j*7,y-10,2,20,"534e3d" if p.watered else "77583f")
		if p.planted < 0.0: continue
		if state.ripe(i):
			oval(c,x,y+2,8,6,"e5c777" if p.crop=="star_bulbs" else "eee0b9")
			if p.crop=="star_bulbs":
				r(c,x-2,y-10,4,24,"f1dfa2")
				r(c,x-11,y-1,22,4,"f1dfa2")
			r(c,x-3,y+5,5,4,"c99c99")
			r(c,x-1,y-12,3,13,"527a46")
			poly(c,[pos+Vector2(0,-5),pos+Vector2(-10,-13),pos+Vector2(-10,-6),pos],"94aa60")
			poly(c,[pos+Vector2(0,-4),pos+Vector2(9,-14),pos+Vector2(10,-7),pos+Vector2(0,1)],"6d9a52")
			r(c,x-5,y,3,2,"faf0cb")
		else:
			r(c,x-1,y-4,3,9,"6c964d")
			r(c,x-6,y-4,5,3,"98ad62")
			r(c,x+2,y-7,6,4,"8ea85b")
			if p.watered: r(c,x+9,y+7,2,2,"8aa8a2")

func paint_effects(c: CanvasItem) -> void:
	if Art.option==2: Art.effects(self,c); return
	for p in people:
		if not villagers[p.id].visible: continue
		var pos = villagers[p.id].position
		if state.player_position.distance_to(pos)<105:
			r(c,pos.x-34,pos.y-66,68,15,"233e34cc")
			c.draw_string(ThemeDB.fallback_font,pos+Vector2(-29,-55),p.name,HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("e4d9b5"))
	if nearest.get("type") == "plot":
		c.draw_rect(Rect2(plot_position(nearest.index)-Vector2(16,16),Vector2(32,30)),Color("eee0a5"),false,1.0)
	var cloak_color = Color("c2e0d6")
	cloak_color.a = 0.14+sin(elapsed*0.9)*0.045
	c.draw_set_transform(Grid.center(SHIP_CELL)-Vector2(343,280))
	c.draw_polyline(PackedVector2Array([Vector2(263,283),Vector2(313,258),Vector2(343,220),Vector2(373,258),Vector2(423,283),Vector2(370,303),Vector2(315,303),Vector2(263,283)]),cloak_color,1.0)
	c.draw_set_transform(Vector2.ZERO)
	for i in range(12):
		var glint=Grid.center(POND_CELL)+Vector2(-70+i*12,sin(elapsed*0.6+i*3)*72)
		r(c,glint.x,glint.y,6+sin(elapsed+i)*4,1,"9fc6b477")
	for i in range(14):
		var pos = Vector2(500+(i*137)%1100+sin(elapsed*0.4+i)*30,670+(i*79)%570+cos(elapsed*0.6+i)*20)
		r(c,pos.x,pos.y,4 if sin(elapsed*8+i)>0 else 2,2,"e1db85" if state.minute>1140 or state.minute<330 else "e8d9aa")
	for p in particles:
		var color = Color(p.color)
		color.a = minf(1.0,p.life)
		c.draw_rect(Rect2(p.pos,Vector2(2,2)),color)
