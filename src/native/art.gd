extends RefCounted

const Grid=preload("res://grid.gd")
static var option=2
static var atlas: ImageTexture
static var pixels: Image
static var catalog: Dictionary={}

static func load_atlas() -> void:
	if atlas!=null: return
	pixels=Image.load_from_file("res://art/option2/sprites.png")
	assert(pixels!=null,"The pixel sprite atlas must exist")
	atlas=ImageTexture.create_from_image(pixels)
	catalog=JSON.parse_string(FileAccess.get_file_as_string("res://art/option2/sprites.json"))

static func region(id: String) -> Rect2:
	load_atlas()
	assert(catalog.has(id),"Missing sprite: "+id)
	var bounds=catalog[id].rect
	return Rect2(bounds[0],bounds[1],bounds[2],bounds[3])

static func sprite(c: CanvasItem,id: String,p: Vector2,size: Vector2=Vector2.ZERO,tint: Color=Color.WHITE) -> void:
	var source=region(id)
	c.draw_texture_rect_region(atlas,Rect2(p.round(),source.size if size==Vector2.ZERO else size),source,tint)

static func tile(c: CanvasItem,id: String,cell: Vector2i,tint: Color=Color.WHITE) -> void:
	sprite(c,"tile_"+id,Grid.origin(cell),Vector2.ZERO,tint)

static func furniture(c: CanvasItem,item: Dictionary) -> void:
	var bounds: Rect2i=item.bounds
	sprite(c,"furniture_%s_%dx%d" % [item.kind,bounds.size.x,bounds.size.y],Vector2(-4,-bounds.size.y*32-24))

static func cover(c: CanvasItem,item: Dictionary) -> void:
	var size: Vector2i=item.bounds.size
	sprite(c,"cover_%dx%d" % [size.x,size.y],Vector2(-4,-size.y*32-24))

static func tree_id(data: Dictionary) -> String:
	var rows=clampi(roundi((data.size-0.8)*4)+2,2,4)
	var species="oak" if data.warm else "birch" if posmod(data.cell.x+data.cell.y,5)==0 else "pine"
	return "tree_%s_%d" % [species,rows]

static func tree(c: CanvasItem,data: Dictionary) -> void:
	var id=tree_id(data)
	sprite(c,id,Vector2(-48,-region(id).size.y+5))

static func person(c: CanvasItem,p: Dictionary,step: float,direction: String) -> void:
	var frame=0 if absf(step)<0.3 else 1 if step>0 else 2
	var id=p.get("id","player")
	if p.get("sleeping",false):
		sprite(c,"actor_%s_sleep0" % id,Vector2(-16,-float(p.get("bed_height",64))+4))
	else: sprite(c,"actor_%s_%s%d" % [id,direction,frame],Vector2(-16,-60))

static func building(c: CanvasItem,b: Dictionary) -> void:
	var columns=int(b.w/32)
	var rows=maxi(2,int(b.h/32)-2)
	if b.kind=="tower": rows=4
	var variant="log" if b.kind=="cabin" else "stone" if b.kind=="tower" else "shop" if b.kind=="store" else "plaster"
	var door=int(columns/2)
	for y in range(rows):
		for x in range(columns):
			var component="foundation" if y==rows-1 else "wall"
			if x==0: component="left"
			if x==columns-1: component="right"
			if y==rows-2 and x in [1,columns-2] and x!=door: component="window"
			if x==door and y==rows-2: component="door_top"
			if x==door and y==rows-1: component="door_bottom"
			if b.kind=="tower" and x==door and y==1: component="window"
			var id="tower_left" if b.kind=="tower" and x==0 else "tower_right" if b.kind=="tower" and x==columns-1 else variant+"_"+component
			tile(c,id,Vector2i(x,y-rows))
	for y in range(2):
		for x in range(columns):
			var component="roof" if y==1 else "ridge"
			if y==0 and x==0: component="roof_left"
			if y==0 and x==columns-1: component="roof_right"
			tile(c,component,Vector2i(x,y-rows-2),roof_tint(b.roof))
	tile(c,"chimney",Vector2i(maxi(1,columns-2),-rows-3))
	for x in [1,columns-2]:
		if x!=door: tile(c,"flowerbed",Vector2i(x,0))
	for x in [door-1,door+1]:
		if x>=0 and x<columns: tile(c,"light",Vector2i(x,-2))

static func roof_tint(value: String) -> Color:
	return Color(value).lerp(Color.WHITE,0.65)

static func cliff(c: CanvasItem,cell: Vector2i,cells: Dictionary) -> void:
	var mask=0
	for pair in [[Vector2i.LEFT,1],[Vector2i.RIGHT,2],[Vector2i.UP,4],[Vector2i.DOWN,8]]:
		if not cells.has(cell+pair[0]): mask|=pair[1]
	tile(c,"cliff"+str(mask),cell)

static func outdoors(w: Node2D) -> void:
	w.draw_texture(w.terrain,Vector2.ZERO)
	for cell in w.mountain_cells: cliff(w,cell,w.mountain_cells)
	for y in range(w.SHIP_MOUNTAIN.position.y,w.SHIP_MOUNTAIN.end.y):
		for x in range(w.SHIP_MOUNTAIN.position.x,w.SHIP_MOUNTAIN.end.x):
			var cell=Vector2i(x,y)
			if w.ship_mountain_cell(cell) and not w.mountain_cells.has(cell): tile(w,"trail",cell)
	for bounds in [w.OUTCROP_CELLS,w.MINE_RIDGE]:
		var rock_cells={}
		for y in range(bounds.position.y,bounds.end.y):
			for x in range(bounds.position.x,bounds.end.x): rock_cells[Vector2i(x,y)]=true
		for cell in rock_cells: cliff(w,cell,rock_cells)
	for y in range(72,74):
		for x in [94,95]: tile(w,"void",Vector2i(x,y))
	tile(w,"cave_arch_left",Vector2i(94,72))
	tile(w,"cave_arch_right",Vector2i(95,72))
	for y in range(w.SQUARE.position.y,w.SQUARE.end.y):
		for x in range(w.SQUARE.position.x,w.SQUARE.end.x): tile(w,"paving"+str(posmod(x+y,4)),Vector2i(x,y))
	sprite(w,"fountain",Grid.origin(w.SQUARE.position+Vector2i(2,2))+Vector2(0,-16))
	for x in range(w.JETTY_CELLS.position.x,w.JETTY_CELLS.end.x): tile(w,"jetty",Vector2i(x,w.JETTY_CELLS.position.y))
	for cell in w.fence_cells: tile(w,"fence",cell)
	for garden in w.DECORATIVE_FIELDS:
		for y in range(garden.position.y,garden.end.y):
			for x in range(garden.position.x,garden.end.x): sprite(w,"crop_turnip" if (x+y)%3 else "crop_sprout",Grid.origin(Vector2i(x,y)))
	sprite(w,"chest",w.site_position("chest")-Vector2(16,40))
	sprite(w,"cart",Grid.origin(w.CART_CELLS.position)-Vector2(0,32))
	sprite(w,"sign",w.site_position("sign")-Vector2(32,52))
	for cell in w.LAMP_CELLS: sprite(w,"lamp",Grid.center(cell)-Vector2(16,86))
	var radio=w.site_position("radio")
	sprite(w,"furniture_table_2x1",radio-Vector2(36,36))
	sprite(w,"furniture_radio_1x1",radio-Vector2(20,70))

static func interior(room: Node2D) -> void:
	room.draw_rect(Rect2(-400,-250,room.ROOM_SIZE.x+800,room.ROOM_SIZE.y+500),Color("263732"))
	for cell in room.floor_cells:
		var id="metal" if room.building.id=="ship" else "bath" if room.floor_cells[cell] in ["bathroom","kitchen"] else "wood"+str(posmod(cell.x+cell.y,4))
		var tint=Color.WHITE
		if room.building.id=="home" and ((cell.y>=7 and not room.state.house_tasks.living_light) or (room.floor_cells[cell]=="bathroom" and not room.state.house_tasks.bathroom_light)): tint=Color("8b9690")
		tile(room,id,cell,tint)
	for item in room.furnishings:
		if item.kind!="rug": continue
		room.draw_set_transform(Grid.origin(item.bounds.position+Vector2i(0,item.bounds.size.y)))
		furniture(room,item)
	room.draw_set_transform(Vector2.ZERO)
	tile(room,"jetty",room.layout.exit)

static func crops(w: Node2D,c: CanvasItem) -> void:
	for i in range(w.state.plots.size()):
		var p=w.state.plots[i]
		var id="soil" if not p.tilled else "wet" if p.watered else "tilled"
		if p.planted>=0: id="bulb" if w.state.ripe(i) and p.crop=="star_bulbs" else "turnip" if w.state.ripe(i) else "sprout"
		sprite(c,"crop_"+id,w.plot_position(i)-Vector2(16,16))

static func particles(w: Node2D,c: CanvasItem) -> void:
	for p in w.particles:
		var color=Color(p.color)
		color.a=minf(1,p.life)
		sprite(c,"particle",p.pos,Vector2.ZERO,color)

static func effects(w: Node2D,c: CanvasItem) -> void:
	for p in w.people:
		if w.villagers[p.id].visible and w.state.player_position.distance_to(w.villagers[p.id].position)<105:
			c.draw_string(ThemeDB.fallback_font,w.villagers[p.id].position+Vector2(-29,-55),p.name,HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("e4d9b5"))
	if w.nearest.get("type")=="plot": c.draw_rect(Rect2(w.plot_position(w.nearest.index)-Vector2(16,16),Vector2(32,30)),Color("eee0a5"),false,1)
	sprite(c,"ship_crew",Grid.center(w.SHIP_CELL)-Vector2(96,68),Vector2.ZERO,Color(0.8,1,0.9,0.12+sin(w.elapsed)*0.03))
	for i in range(12): sprite(c,"ripple",Grid.center(w.POND_CELL)+Vector2(-70+i*12,sin(w.elapsed*.6+i*3)*72))
	for i in range(14):
		var p=Vector2(500+(i*137)%1100+sin(w.elapsed*.4+i)*30,670+(i*79)%570+cos(w.elapsed*.6+i)*20)
		sprite(c,"firefly" if w.state.minute>1140 or w.state.minute<330 else "bird"+str(int(w.elapsed*7+i)%3),p)
	particles(w,c)

static func indoor_effects(room: Node2D,c: CanvasItem) -> void:
	if room.building.id=="home":
		for task in ["living_light","bathroom_light"]:
			sprite(c,"tile_light",room.site_position(task)-Vector2(16,64),Vector2.ZERO,Color.WHITE if room.state.house_tasks[task] else Color("667772"))
	if room.building.id=="ship":
		for origin in [Vector2(135,282),Vector2(265,337),Vector2(385,402)]:
			sprite(c,"cable",origin-Vector2(16,60))
			if fmod(room.elapsed+origin.x*.03,3.7)<.16: sprite(c,"spark"+str(int(room.elapsed*30)%6),origin-Vector2(8,8))
	for actor in room.villagers.values():
		if actor.visible and actor.position.distance_to(room.state.player_position)<100:
			c.draw_string(ThemeDB.fallback_font,actor.position+Vector2(-25,-55),"z z z" if actor.data.get("sleeping",false) else actor.data.name,HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("e4d9b5"))
	particles(room,c)
