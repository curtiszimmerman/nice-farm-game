extends Node2D

const Grid = preload("res://grid.gd")
const SIZE = Grid.WORLD_SIZE
const FARM_CELL = Vector2i(17,24)
const OUTCROP_CELLS = Rect2i(46,28,7,4)
const COPPER_CELLS = Rect2i(46,32,7,1)
const SHIP_CELL = Vector2i(10,8)
const JETTY_CELLS = Rect2i(11,34,3,1)
const CART_CELLS = Rect2i(44,23,3,1)
const LAMP_CELLS = [Vector2i(36,20),Vector2i(45,25),Vector2i(27,20)]
const PEOPLE = [
	{"id":"moss","name":"Moss","role":"YOUR NEIGHBOR","cell":Vector2i(27,21),"coat":"a7834d","hair":"d6cb9c","skin":"d4a776","hat":true},
	{"id":"tavi","name":"Tavi","role":"TRAVELING MERCHANT","cell":Vector2i(44,21),"coat":"aa7262","hair":"bd996b","skin":"c0a070","cat":true},
	{"id":"iona","name":"Iona","role":"FIELD MAGICIAN","cell":Vector2i(32,26),"coat":"8885ad","hair":"e3d7bd","skin":"ae856c"},
	{"id":"finch","name":"Finch","role":"RADIO CLUB SECRETARY","cell":Vector2i(41,16),"coat":"6d96a0","hair":"765842","skin":"d3ab88"},
	{"id":"vale","name":"Chief Vale","role":"CHIEF ENGINEER","cell":Vector2i(10,10),"coat":"8b9baf","hair":"b5a68e","skin":"a97959"}
]
const BUILDINGS = [
	{"cell":Vector2i(19,15),"tiles":Vector2i(7,5),"roof":"a65e50","kind":"home"},
	{"cell":Vector2i(38,11),"tiles":Vector2i(5,4),"roof":"5b8990","kind":"radio"},
	{"cell":Vector2i(45,15),"tiles":Vector2i(5,4),"roof":"ad7956","kind":"store"},
	{"cell":Vector2i(39,20),"tiles":Vector2i(5,4),"roof":"818a60","kind":"hall"},
	{"cell":Vector2i(28,33),"tiles":Vector2i(5,3),"roof":"8c6856","kind":"cottage"}
]
const SITES = [
	{"id":"bed","cell":Vector2i(22,20),"label":"Rest at the farmhouse"},
	{"id":"pond","cell":Vector2i(13,34),"label":"Fish from the jetty"},
	{"id":"ore","cell":Vector2i(49,32),"label":"Gather copper"},
	{"id":"sign","cell":Vector2i(33,19),"label":"Read the signpost"},
	{"id":"radio","cell":Vector2i(37,16),"label":"Listen to the radio"}
]
const ROAD_ROUTES = [
	[Vector2i(22,20),Vector2i(23,20),Vector2i(23,31)],
	[Vector2i(23,21),Vector2i(35,21),Vector2i(35,19),Vector2i(44,19),Vector2i(44,21),Vector2i(47,21)],
	[Vector2i(35,15),Vector2i(35,32)],
	[Vector2i(13,31),Vector2i(35,31),Vector2i(35,32),Vector2i(49,32),Vector2i(49,34)],
	[Vector2i(13,31),Vector2i(13,34)],
	[Vector2i(40,15),Vector2i(40,19)],
	[Vector2i(47,19),Vector2i(47,21)],
	[Vector2i(41,24),Vector2i(35,24)]
]

var people: Array = []
var buildings: Array = []
var sites: Array = []
var road_segments: Array = []
var road_cells: Dictionary = {}
var water_cells: Dictionary = {}
var solid_cells: Dictionary = {}
var reserved_cells: Dictionary = {}
var fence_cells: Array[Vector2i] = []
var trees: Array = []
var terrain: ImageTexture
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

class Prop extends Node2D:
	var owner_world: Node2D
	var kind: String
	var data: Dictionary
	func _draw() -> void:
		if kind == "tree": owner_world.paint_tree(self, data)
		elif kind == "building": owner_world.paint_building(self, data)
		elif kind == "person": owner_world.paint_person(self, data, 0.0, "down")
		elif kind == "player": owner_world.paint_person(self, data, sin(owner_world.elapsed * 14.0) if owner_world.moving else 0.0, owner_world.facing)
		elif kind == "crops": owner_world.paint_crops(self)
		elif kind == "effects": owner_world.paint_effects(self)

func _ready() -> void:
	y_sort_enabled = true
	night_tint=CanvasModulate.new()
	add_child(night_tint)
	_build_layout()
	_build_terrain()
	var random = RandomNumberGenerator.new()
	random.seed = 41
	for i in range(450):
		var cell=Vector2i(random.randi_range(4,56),random.randi_range(5,41))
		var p=Grid.center(cell)
		if solid_cells.has(cell) or reserved_cells.has(cell) or _clearing(p): continue
		if trees.any(func(t): return absi(t.cell.x-cell.x)<=1 and absi(t.cell.y-cell.y)<=1): continue
		var tree = {"cell":cell,"pos":p,"size":random.randf_range(0.8,1.3),"warm":random.randf()>0.72}
		solid_cells[cell]="tree"
		trees.append(tree)
		_prop("tree",p,tree)
	for b in buildings: _prop("building",Vector2(b.x,b.y+b.h),b)
	for p in people: _prop("person",Vector2(p.x,p.y),p)
	crops = _prop("crops",Vector2.ZERO,{})
	crops.z_index = 0
	player = _prop("player",state.player_position,{"coat":"6f9793","hair":"5c5045","skin":"d0a981","id":"player"})
	mayor = _prop("person",Grid.center(Vector2i(24,21)),{"coat":"657b70","hair":"c2c4b0","skin":"d0a181"})
	mayor.visible = false
	var effects = _prop("effects",Vector2.ZERO,{})
	effects.z_index = 5

func _claim(footprint: Rect2i,kind: String) -> void:
	for y in range(footprint.position.y,footprint.end.y):
		for x in range(footprint.position.x,footprint.end.x):
			var cell=Vector2i(x,y)
			assert(not solid_cells.has(cell),"Overlapping map footprints at %s" % cell)
			solid_cells[cell]=kind

func _build_layout() -> void:
	for y in range(Grid.MAP_SIZE.y):
		for x in range(Grid.MAP_SIZE.x):
			var cell=Vector2i(x,y)
			var p=Grid.center(cell)
			var pond=(p-Grid.center(Vector2i(8,36)))/Vector2(160,160)
			if p.x<96.0+sin(p.y/145.0)*22.0 or pond.length_squared()<1.0:
				water_cells[cell]=true
				solid_cells[cell]="water"
	for y in range(JETTY_CELLS.position.y,JETTY_CELLS.end.y):
		for x in range(JETTY_CELLS.position.x,JETTY_CELLS.end.x):
			var cell=Vector2i(x,y)
			solid_cells.erase(cell)
			reserved_cells[cell]=true
	for item in PEOPLE:
		var p=item.duplicate(true)
		var pos=Grid.center(p.cell)
		p.x=pos.x
		p.y=pos.y
		people.append(p)
		reserved_cells[p.cell]=true
	for item in BUILDINGS:
		var b=item.duplicate(true)
		var bounds=Grid.rect(b.cell,b.tiles)
		b.x=bounds.position.x
		b.y=bounds.position.y
		b.w=bounds.size.x
		b.h=bounds.size.y
		buildings.append(b)
		_claim(Rect2i(b.cell,b.tiles),"building")
	for item in SITES:
		var p=item.duplicate(true)
		var pos=Grid.center(p.cell)
		p.x=pos.x
		p.y=pos.y
		if p.id=="ore": p.bounds=Grid.rect(COPPER_CELLS.position,COPPER_CELLS.size)
		sites.append(p)
		reserved_cells[p.cell]=true
	_claim(OUTCROP_CELLS,"rock")
	_claim(CART_CELLS,"cart")
	for cell in LAMP_CELLS: _claim(Rect2i(cell,Vector2i.ONE),"lamp")
	_claim(Rect2i(Vector2i(33,19),Vector2i.ONE),"sign")
	_claim(Rect2i(Vector2i(37,16),Vector2i.ONE),"radio")
	for y in [22,29]:
		for x in range(16,28):
			if x not in [22,23,24]: fence_cells.append(Vector2i(x,y))
	for y in range(23,29): fence_cells.append(Vector2i(16,y))
	for cell in fence_cells: _claim(Rect2i(cell,Vector2i.ONE),"fence")
	for route in ROAD_ROUTES:
		for i in range(route.size()-1):
			var a=route[i]
			var b=route[i+1]
			road_segments.append([Grid.center(a),Grid.center(b),Grid.TILE_SIZE*0.5])
			for y in range(mini(a.y,b.y),maxi(a.y,b.y)+1):
				for x in range(mini(a.x,b.x),maxi(a.x,b.x)+1): road_cells[Vector2i(x,y)]=true

func site_position(id: String) -> Vector2:
	for site in sites:
		if site.id==id: return Grid.center(site.cell)
	return Vector2.ZERO

func _prop(kind: String, pos: Vector2, data: Dictionary) -> Prop:
	var p = Prop.new()
	p.owner_world = self
	p.kind = kind
	p.data = data
	p.position = pos
	add_child(p)
	return p

func refresh() -> void:
	var daylight=smoothstep(330.0,420.0,state.minute)*(1.0-smoothstep(1110.0,1200.0,state.minute))
	night_tint.color=Color(0.32,0.42,0.92).lerp(Color.WHITE,daylight)
	crops.queue_redraw()
	player.position = state.player_position.round()
	player.queue_redraw()
	mayor.visible = state.invited and not state.met_mayor and state.total() >= 2160.0
	for child in get_children():
		if child is Prop:
			if child.kind == "effects": child.queue_redraw()
			elif child.kind in ["tree","building"]:
				var hidden=prop_hides_player(child)
				child.modulate.a=move_toward(child.modulate.a,0.22 if hidden else 1.0,0.14)

func prop_hides_player(prop: Prop) -> bool:
	if state.player_position.y>=prop.position.y: return false
	var bounds: Rect2
	if prop.kind=="tree":
		var scale_factor=prop.data.size
		bounds=Rect2(prop.position+Vector2(-34,-92)*scale_factor,Vector2(68,94)*scale_factor)
	elif prop.kind=="building":
		bounds=Rect2(prop.position+Vector2(-14,-prop.data.h-80),Vector2(prop.data.w+28,prop.data.h+90))
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
	var distance=player_position.distance_to(Grid.center(Vector2i(49,31)))
	var cave_weight=clampf(1.0-(distance-30.0)/120.0,0.0,1.0)
	return {"environment":"town" if player_position.x>1120 else "farm","season":state.season_name(),"cave_weight":cave_weight}

func in_water(p: Vector2) -> bool:
	var cell=Grid.world_to_cell(p)
	return water_cells.has(cell) and not JETTY_CELLS.has_point(cell)

func blocked(p: Vector2) -> bool:
	var cell=Grid.world_to_cell(p)
	return not Grid.PLAYABLE_CELLS.has_point(cell) or solid_cells.has(cell)

func find_nearest() -> Dictionary:
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
		var d = state.player_position.distance_to(Vector2(p.x,p.y))
		if d<distance:
			best = p.duplicate()
			best.type = "person"
			best.label = "Talk to " + p.name
			distance = d
	for p in sites:
		var interaction_point=Vector2(p.x,p.y)
		if p.has("bounds"):
			interaction_point=state.player_position.clamp(p.bounds.position,p.bounds.end)
		var d = state.player_position.distance_to(interaction_point)
		if d<distance:
			best = p.duplicate()
			best.type = "site"
			distance = d
	nearest = best
	return best

func _clearing(p: Vector2) -> bool:
	if Rect2(495,420,445,590).has_point(p) or Rect2(1145,330,525,500).has_point(p) or Rect2(245,190,215,210).has_point(p) or Rect2(1440,900,300,330).has_point(p): return true
	for b in buildings:
		if Rect2(b.x,b.y,b.w,b.h).grow(65).has_point(p): return true
	for segment in road_segments:
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p,segment[0],segment[1]))<segment[2]+35.0: return true
	return in_water(p)

func _build_terrain() -> void:
	var image = Image.create(int(SIZE.x),int(SIZE.y),false,Image.FORMAT_RGB8)
	image.fill(Color("748c53"))
	var random = RandomNumberGenerator.new()
	random.seed = 73
	var colors = [Color("7a9258"),Color("6f884f"),Color("83975d"),Color("81965a")]
	for i in range(45000): image.fill_rect(Rect2i(random.randi_range(0,1915),random.randi_range(0,1437),random.randi_range(2,5),2),colors[i%4])
	_paint_roads(image,random)
	_paint_water(image)
	var decorated_cells={}
	for i in range(2100):
		var cell=Vector2i(random.randi_range(4,56),random.randi_range(5,41))
		var p=Grid.center(cell)
		if decorated_cells.has(cell) or solid_cells.has(cell) or _clearing(p): continue
		decorated_cells[cell]=true
		image.fill_rect(Rect2i(p.x,p.y,2,5),Color("597b48"))
		if i%3 == 0: image.fill_rect(Rect2i(p.x-1,p.y-2,4,3),Color("ddd79b") if i%2 else Color("c1acc2"))
	terrain = ImageTexture.create_from_image(image)
	queue_redraw()

func _paint_water(image: Image) -> void:
	for cell in water_cells:
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
		for y in range(int(bounds.position.y/2.0)*2,int(bounds.end.y)+2,2):
			for x in range(int(bounds.position.x/2.0)*2,int(bounds.end.x)+2,2):
				var p=Vector2(x+1,y+1)
				var distance=p.distance_to(Geometry2D.get_closest_point_to_segment(p,segment[0],segment[1]))
				var roughness=sin(x*0.071)*1.5+sin(y*0.113)*1.3
				var coverage=1.0-smoothstep(segment[2]-3.0+roughness,segment[2]+5.0+roughness,distance)
				if coverage>road_mask.get_pixel(x,y).r:
					road_mask.fill_rect(Rect2i(x,y,2,2),Color(coverage,coverage,coverage))
				var rut=maxf(0.0,1.0-absf(distance-segment[2]*0.43)/2.0)*0.08
				if rut>tracks.get_pixel(x,y).r: tracks.fill_rect(Rect2i(x,y,2,2),Color(rut,rut,rut))
	for y in range(450,1160,2):
		for x in range(370,1635,2):
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
	if not terrain: return
	draw_texture(terrain,Vector2.ZERO)
	draw_set_transform(Grid.origin(JETTY_CELLS.position))
	r(self,0,0,96,32,"655d46")
	for i in range(12): r(self,1+i*8,0,6,32,"b09b6c")
	for x in [2,89]:
		r(self,x,-10,5,48,"776a4e")
		r(self,x,-12,5,3,"d0bb87")
	draw_set_transform(Vector2.ZERO)
	for cell in fence_cells:
		var p=Grid.origin(cell)
		if cell.x==16 and cell.y not in [22,29]:
			r(self,p.x+14,p.y,4,32,"a28d64")
			r(self,p.x+12,p.y+2,8,27,"b8a77a")
		else: _fence(p.x,p.y+2,Grid.TILE_SIZE)
	var field=Grid.rect(FARM_CELL,Vector2i(5,4))
	draw_rect(field.grow(3),Color("596341"))
	draw_rect(field,Color("7b6446"))
	draw_set_transform(Grid.origin(OUTCROP_CELLS.position)+Vector2(112,128))
	oval(self,0,-19,118,32,"687f63")
	poly(self,[Vector2(-112,-19),Vector2(-96,-90),Vector2(-64,-112),Vector2(-32,-90),Vector2(-16,-128),Vector2(32,-112),Vector2(80,-58),Vector2(112,0)],"7c8b7d")
	poly(self,[Vector2(-96,-90),Vector2(-64,-112),Vector2(-32,-90),Vector2(-64,-30)],"a8af94")
	poly(self,[Vector2(-16,-128),Vector2(32,-112),Vector2(64,-64),Vector2(4,-88)],"9da58e")
	oval(self,0,-34,27,32,"344e47")
	for i in range(7):
		r(self,-100+i*32,-12+sin(i*3.0)*5,8,5,"9b7b5e")
		r(self,-98+i*32,-12+sin(i*3.0)*5,3,3,"c7a36d")
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
	r(self,-12,-23,25,23,"816d4d")
	r(self,-9,-20,19,12,"4a6055")
	r(self,-6,-4,4,3,"d8c08a")
	r(self,3,-4,4,3,"d8c08a")
	draw_set_transform(Vector2.ZERO)

func _fence(x: float,y: float,w: int) -> void:
	r(self,x,y+4,w,4,"a28d64")
	r(self,x,y+16,w,4,"a28d64")
	for i in range(0,w+1,Grid.TILE_SIZE):
		r(self,x+i,y,5,27,"b8a77a")
		r(self,x+i-1,y-3,7,5,"d0be8b")

func paint_tree(c: CanvasItem, data: Dictionary) -> void:
	var s = data.size
	oval(c,7,6,28*s,10*s,"263d3450")
	r(c,-5*s,-38*s,11*s,40*s,"6d6547")
	r(c,-s,-30*s,4*s,31*s,"93805a")
	var colors = ["496c51","638653","849755"] if data.warm else ["365e4b","4c7a50","6c9257"]
	for p in [[-29,-60,56,30,0],[-22,-78,44,30,0],[-13,-91,28,27,0],[-25,-67,41,25,1],[-17,-84,29,26,1],[-19,-72,19,12,2],[-10,-86,13,10,2],[5,-56,20,15,1],[-33,-51,18,15,0]]:
		r(c,p[0]*s,p[1]*s,p[2]*s,p[3]*s,colors[p[4]])
	r(c,-18*s,-64*s,5*s,3*s,"91a05d")
	r(c,8*s,-46*s,5*s,3*s,"779453")

func paint_building(c: CanvasItem, b: Dictionary) -> void:
	var w = b.w
	var h = b.h
	var y = -h
	oval(c,w*0.6,5,w*0.65,19,"233f3338")
	r(c,0,y,w,h,"d0c298")
	r(c,5,y+8,w-10,h-8,"c0b58f")
	for yy in range(y+12,0,12): r(c,6,yy,w-12,1,"a89f7d")
	r(c,0,y,w,5,"e0d0a6")
	r(c,0,y,6,h,"e0d0a6")
	r(c,w-6,y,6,h,"8e947a")
	r(c,-5,-9,w+10,13,"9a9478")
	r(c,9,-7,w-18,3,"b3ab8c")
	var door = w*0.5-13
	r(c,door-3,-54,32,48,"7b795d")
	r(c,door,-51,26,45,"5d7869")
	r(c,door+4,-46,18,17,"829f91")
	r(c,door+21,-28,3,3,"d4b87c")
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

func paint_crops(c: CanvasItem) -> void:
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
			oval(c,x,y+2,8,6,"eee0b9")
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
	for p in people:
		var pos = Vector2(p.x,p.y)
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
		var x = 190+i*18
		var y = 1120+sin(elapsed*0.6+i*3)*72
		r(c,x,y,6+sin(elapsed+i)*4,1,"9fc6b477")
	for i in range(14):
		var pos = Vector2(500+(i*137)%1100+sin(elapsed*0.4+i)*30,670+(i*79)%570+cos(elapsed*0.6+i)*20)
		r(c,pos.x,pos.y,4 if sin(elapsed*8+i)>0 else 2,2,"e1db85" if state.minute>1140 or state.minute<330 else "e8d9aa")
	for p in particles:
		var color = Color(p.color)
		color.a = minf(1.0,p.life)
		c.draw_rect(Rect2(p.pos,Vector2(2,2)),color)
