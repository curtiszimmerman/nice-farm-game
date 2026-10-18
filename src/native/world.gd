extends Node2D

const SIZE = Vector2(1920, 1440)
const FARM = Vector2(580, 790)
const PEOPLE = [
	{"id": "moss", "name": "Moss", "role": "YOUR NEIGHBOR", "x": 890, "y": 708, "coat": "a7834d", "hair": "d6cb9c", "skin": "d4a776", "hat": true},
	{"id": "tavi", "name": "Tavi", "role": "TRAVELING MERCHANT", "x": 1430, "y": 692, "coat": "aa7262", "hair": "bd996b", "skin": "c0a070", "cat": true},
	{"id": "iona", "name": "Iona", "role": "FIELD MAGICIAN", "x": 1040, "y": 855, "coat": "8885ad", "hair": "e3d7bd", "skin": "ae856c"},
	{"id": "finch", "name": "Finch", "role": "RADIO CLUB SECRETARY", "x": 1320, "y": 530, "coat": "6d96a0", "hair": "765842", "skin": "d3ab88"},
	{"id": "vale", "name": "Chief Vale", "role": "CHIEF ENGINEER", "x": 343, "y": 344, "coat": "8b9baf", "hair": "b5a68e", "skin": "a97959"}
]
const BUILDINGS = [
	{"x": 628, "y": 480, "w": 194, "h": 150, "roof": "a65e50", "kind": "home"},
	{"x": 1205, "y": 354, "w": 150, "h": 125, "roof": "5b8990", "kind": "radio"},
	{"x": 1455, "y": 470, "w": 165, "h": 130, "roof": "ad7956", "kind": "store"},
	{"x": 1250, "y": 650, "w": 150, "h": 115, "roof": "818a60", "kind": "hall"},
	{"x": 890, "y": 1050, "w": 120, "h": 100, "roof": "8c6856", "kind": "cottage"}
]
const SITES = [
	{"id": "bed", "x": 724, "y": 660, "label": "Rest at the farmhouse"},
	{"id": "pond", "x": 420, "y": 1110, "label": "Fish from the jetty"},
	{"id": "ore", "x": 1585, "y": 1090, "label": "Gather copper"},
	{"id": "sign", "x": 1070, "y": 635, "label": "Read the signpost"},
	{"id": "radio", "x": 1210, "y": 545, "label": "Listen to the radio"}
]
const PATHS = [Rect2(810,675,730,55),Rect2(1110,470,55,580),Rect2(680,635,65,400),Rect2(365,990,785,46),Rect2(1130,1010,500,45),Rect2(1280,465,45,250),Rect2(1435,595,70,100)]

var trees: Array = []
var terrain: ImageTexture
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
	_build_terrain()
	var random = RandomNumberGenerator.new()
	random.seed = 41
	for i in range(450):
		var p = Vector2(random.randf_range(110,1860),random.randf_range(130,1360)).round()
		if _clearing(p) or trees.any(func(t): return t.pos.distance_to(p)<43): continue
		var tree = {"pos": p, "size": random.randf_range(0.8,1.3), "warm": random.randf()>0.72}
		trees.append(tree)
		_prop("tree",p,tree)
	for b in BUILDINGS: _prop("building",Vector2(b.x,b.y+b.h),b)
	for p in PEOPLE: _prop("person",Vector2(p.x,p.y),p)
	crops = _prop("crops",Vector2.ZERO,{})
	crops.z_index = 0
	player = _prop("player",state.player_position,{"coat":"6f9793","hair":"5c5045","skin":"d0a981","id":"player"})
	mayor = _prop("person",Vector2(770,696),{"coat":"657b70","hair":"c2c4b0","skin":"d0a181"})
	mayor.visible = false
	var effects = _prop("effects",Vector2.ZERO,{})
	effects.z_index = 5

func _prop(kind: String, pos: Vector2, data: Dictionary) -> Prop:
	var p = Prop.new()
	p.owner_world = self
	p.kind = kind
	p.data = data
	p.position = pos
	add_child(p)
	return p

func refresh() -> void:
	crops.queue_redraw()
	player.position = state.player_position.round()
	player.queue_redraw()
	mayor.visible = state.invited and not state.met_mayor and state.total() >= 2160.0
	for child in get_children():
		if child is Prop and child.kind == "effects": child.queue_redraw()

func plot_position(i: int) -> Vector2:
	return FARM + Vector2(i%5 * 34, int(i/5.0)*34)

func audio_context(player_position: Vector2) -> Dictionary:
	# A future interior supplies cave/mine instead of an outdoor environment.
	var distance=player_position.distance_to(Vector2(1585,1010))
	var cave_weight=clampf(1.0-(distance-30.0)/120.0,0.0,1.0)
	return {"environment":"town" if player_position.x>1120 else "farm","season":state.season_name(),"cave_weight":cave_weight}

func in_water(p: Vector2) -> bool:
	return pow((p.x-280.0)/175.0,2)+pow((p.y-1170.0)/160.0,2)<1.0 or p.x<84+sin(p.y/145.0)*27

func blocked(p: Vector2) -> bool:
	if p.x<110 or p.x>1855 or p.y<120 or p.y>1385 or in_water(p): return true
	for b in BUILDINGS:
		if Rect2(b.x-5,b.y+20,b.w+10,b.h-10).has_point(p): return true
	for t in trees:
		if absf(p.x-t.pos.x)<11 and absf(p.y-t.pos.y)<12: return true
	return Rect2(1465,920,225,100).has_point(p)

func find_nearest() -> Dictionary:
	var best: Dictionary = {}
	var distance = 55.0
	for i in range(20):
		var d = state.player_position.distance_to(plot_position(i))
		if d<minf(distance,36.0):
			var p = state.plots[i]
			var label = "Harvest moon turnip" if state.ripe(i) else "Till the soil" if not p.tilled else "Plant moon turnip" if p.planted<0 else "Water moon turnip" if not p.watered else "Growing · Q casts Wildgrowth"
			best = {"type":"plot","index":i,"label":label}
			distance = d
	for p in PEOPLE:
		var d = state.player_position.distance_to(Vector2(p.x,p.y))
		if d<distance:
			best = p.duplicate()
			best.type = "person"
			best.label = "Talk to " + p.name
			distance = d
	for p in SITES:
		var d = state.player_position.distance_to(Vector2(p.x,p.y))
		if d<distance:
			best = p.duplicate()
			best.type = "site"
			distance = d
	nearest = best
	return best

func _clearing(p: Vector2) -> bool:
	if Rect2(495,420,445,590).has_point(p) or Rect2(1145,330,525,500).has_point(p) or Rect2(245,190,215,210).has_point(p) or Rect2(1440,900,300,330).has_point(p): return true
	for b in BUILDINGS:
		if Rect2(b.x,b.y,b.w,b.h).grow(65).has_point(p): return true
	for path in PATHS:
		if path.grow(35).has_point(p): return true
	return in_water(p)

func _build_terrain() -> void:
	var image = Image.create(1920,1440,false,Image.FORMAT_RGB8)
	image.fill(Color("748c53"))
	var random = RandomNumberGenerator.new()
	random.seed = 73
	var colors = [Color("7a9258"),Color("6f884f"),Color("83975d"),Color("81965a")]
	for i in range(45000): image.fill_rect(Rect2i(random.randi_range(0,1915),random.randi_range(0,1437),random.randi_range(2,5),2),colors[i%4])
	for path in PATHS:
		image.fill_rect(Rect2i(path.grow(5)),Color("87925b"))
		image.fill_rect(Rect2i(path),Color("bdad78"))
		for i in range(int(path.size.x*path.size.y/130.0)):
			image.fill_rect(Rect2i(int(path.position.x+random.randf()*path.size.x),int(path.position.y+random.randf()*path.size.y),3,2),Color("cdbb86") if i%2 else Color("ac9c6d"))
	for y in range(1440):
		var edge = int(84+sin(y/145.0)*27)
		image.fill_rect(Rect2i(0,y,edge+14,1),Color("96a776"))
		image.fill_rect(Rect2i(0,y,edge+6,1),Color("6c998c"))
		image.fill_rect(Rect2i(0,y,edge,1),Color("487e84"))
	for y in range(998,1341):
		var d = (y-1170.0)/169.0
		if absf(d)>1.0: continue
		var radius = int(sqrt(1.0-d*d)*184)
		image.fill_rect(Rect2i(280-radius,y,radius*2,1),Color("9da675"))
		if radius>12: image.fill_rect(Rect2i(290-radius,y,radius*2-20,1),Color("51868a"))
	for i in range(2100):
		var p = Vector2(random.randf_range(120,1840),random.randf_range(150,1370))
		if _clearing(p): continue
		image.fill_rect(Rect2i(p.x,p.y,2,5),Color("597b48"))
		if i%3 == 0: image.fill_rect(Rect2i(p.x-1,p.y-2,4,3),Color("ddd79b") if i%2 else Color("c1acc2"))
	terrain = ImageTexture.create_from_image(image)
	queue_redraw()

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
	r(self,372,1090,82,36,"655d46")
	for i in range(9): r(self,374+i*9,1090,7,34,"b09b6c")
	for x in [375,446]:
		r(self,x,1080,5,49,"776a4e")
		r(self,x,1078,5,3,"d0bb87")
	_fence(520,735,142)
	_fence(768,735,112)
	_fence(520,968,360)
	r(self,535,773,196,133,"596341")
	r(self,538,776,190,127,"7b6446")
	for y in range(750,970,38):
		r(self,516,y,5,26,"aa9870")
		r(self,514,y-3,9,6,"d0bc8d")
	oval(self,1580,1005,124,43,"687f63")
	poly(self,[Vector2(1460,1005),Vector2(1480,950),Vector2(1510,928),Vector2(1540,952),Vector2(1570,915),Vector2(1610,932),Vector2(1668,978),Vector2(1690,1020)],"7c8b7d")
	poly(self,[Vector2(1480,950),Vector2(1510,928),Vector2(1540,952),Vector2(1520,990)],"a8af94")
	poly(self,[Vector2(1570,915),Vector2(1610,932),Vector2(1638,968),Vector2(1590,953)],"9da58e")
	oval(self,1585,986,27,32,"344e47")
	for i in range(11):
		r(self,1490+i*15,1010+sin(i*3.0)*12,8,5,"9b7b5e")
		r(self,1492+i*15,1010+sin(i*3.0)*12,3,3,"c7a36d")
	oval(self,343,280,87,43,"6d8958")
	oval(self,343,280,71,30,"7b9060")
	r(self,1390,732,84,24,"8e7651")
	r(self,1387,729,90,6,"b6a073")
	for x in [1404,1458]:
		oval(self,x,758,9,9,"445249")
		oval(self,x,758,4,4,"bcaa7a")
	for i in range(4):
		r(self,1398+i*18,717,15,12,"9b855c")
		for k in range(3): oval(self,1401+i*18+k*4,716,3,3,"b3b56b" if i%2 else "c29162")
	for p in [Vector2(1183,655),Vector2(1465,814),Vector2(865,658)]:
		r(self,p.x,p.y-74,4,74,"5b6957")
		r(self,p.x-7,p.y-79,18,5,"536251")
		r(self,p.x-5,p.y-74,14,17,"d2c690")
		r(self,p.x-3,p.y-72,10,11,"f1dfac")
	r(self,1066,587,6,55,"837350")
	r(self,1041,592,62,15,"bbab7b")
	r(self,1038,611,53,13,"a99769")
	draw_string(ThemeDB.fallback_font,Vector2(1046,603),"TOWN >",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("515d49"))
	draw_string(ThemeDB.fallback_font,Vector2(1041,621),"< FARM",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("515d49"))
	r(self,1200,519,25,23,"816d4d")
	r(self,1203,522,19,12,"4a6055")
	r(self,1206,538,4,3,"d8c08a")
	r(self,1215,538,4,3,"d8c08a")

func _fence(x: float,y: float,w: int) -> void:
	r(self,x,y+4,w,4,"a28d64")
	r(self,x,y+16,w,4,"a28d64")
	for i in range(0,w+1,28):
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
	for p in PEOPLE:
		var pos = Vector2(p.x,p.y)
		if state.player_position.distance_to(pos)<105:
			r(c,pos.x-34,pos.y-66,68,15,"233e34cc")
			c.draw_string(ThemeDB.fallback_font,pos+Vector2(-29,-55),p.name,HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("e4d9b5"))
	if nearest.get("type") == "plot":
		c.draw_rect(Rect2(plot_position(nearest.index)-Vector2(16,16),Vector2(32,30)),Color("eee0a5"),false,1.0)
	var cloak_color = Color("c2e0d6")
	cloak_color.a = 0.14+sin(elapsed*0.9)*0.045
	c.draw_polyline(PackedVector2Array([Vector2(263,283),Vector2(313,258),Vector2(343,220),Vector2(373,258),Vector2(423,283),Vector2(370,303),Vector2(315,303),Vector2(263,283)]),cloak_color,1.0)
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
