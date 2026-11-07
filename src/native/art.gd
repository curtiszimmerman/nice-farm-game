extends RefCounted

const Grid=preload("res://grid.gd")
const Borders=preload("res://terrain_borders.gd")
static var option=2
static var atlas: ImageTexture
static var pixels: Image
static var catalog: Dictionary={}
static var tile_size=32
static var pack_path="res://art/option3/pack.json"
static var terrain_tiles: Dictionary={}
static var stone_variants: Dictionary={}

static func load_atlas() -> void:
	if atlas!=null: return
	var error=select_pack(pack_path)
	assert(error.is_empty(),error)

static func read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var parser=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK or not parser.data is Dictionary: return {}
	return parser.data

static func select_pack(path: String) -> String:
	var manifest=read_json(path)
	if not manifest.has_all(["id","name","tile_size","atlas","sprites"]): return "Incomplete artwork manifest."
	if not (manifest.tile_size is int or manifest.tile_size is float) or (manifest.tile_size!=16.0 and manifest.tile_size!=32.0): return "Artwork tiles must be 16 or 32 pixels."
	for key in ["atlas","sprites"]:
		if not manifest[key] is String or manifest[key].is_absolute_path() or ".." in manifest[key].split("/"): return "Artwork files must be inside their pack folder."
	var folder=path.get_base_dir()
	var entries=read_json(folder.path_join(manifest.sprites))
	var baseline=read_json("res://art/option2/sprites.json")
	if not entries.has_all(baseline.keys()): return "The artwork pack is missing required sprites."
	var image_path=folder.path_join(manifest.atlas)
	if not FileAccess.file_exists(image_path): return "The artwork PNG is missing."
	var image: Image
	if ResourceLoader.exists(image_path):
		var texture=ResourceLoader.load(image_path) as Texture2D
		if texture==null: return "Could not read the artwork PNG."
		image=texture.get_image()
	else:
		image=Image.load_from_file(image_path)
	if image==null: return "Could not read the artwork PNG."
	var scale=32.0/manifest.tile_size
	for id in entries:
		if not entries[id] is Dictionary or not entries[id].get("rect") is Array or entries[id].rect.size()!=4: return "Invalid sprite rectangle: "+id
		var r=entries[id].rect
		for number in r:
			if not (number is int or number is float) or number!=floor(number): return "Sprite coordinates must be integer pixels: "+id
		if r[0]<0 or r[1]<0 or r[2]<=0 or r[3]<=0 or r[0]+r[2]>image.get_width() or r[1]+r[3]>image.get_height(): return "Sprite lies outside the atlas: "+id
		if baseline.has(id):
			var expected=baseline[id].rect
			if r[2]!=ceil(expected[2]/scale) or r[3]!=ceil(expected[3]/scale): return "Sprite dimensions do not match its world footprint: "+id
	pixels=image
	stone_variants.clear()
	pixels.convert(Image.FORMAT_RGBA8)
	atlas=ImageTexture.create_from_image(image)
	catalog=entries
	tile_size=int(manifest.tile_size)
	pack_path=path
	option=2
	terrain_tiles.clear()
	return ""

static func available_packs() -> Array:
	var result=[]
	for directory in ["res://art","res://art/packs"]:
		if not DirAccess.dir_exists_absolute(directory): continue
		for folder in DirAccess.get_directories_at(directory):
			var path=directory.path_join(folder).path_join("pack.json")
			var manifest=read_json(path)
			if manifest.get("name") is String: result.append({"name":manifest.name,"path":path})
	return result

static func sprite_size(id: String) -> Vector2:
	return region(id).size*(32.0/tile_size)

static func tile_image(id: String) -> Image:
	load_atlas()
	if not terrain_tiles.has(id):
		var image=pixels.get_region(Rect2i(region("tile_"+id)))
		image.resize(32,32,Image.INTERPOLATE_NEAREST)
		terrain_tiles[id]=image
	return terrain_tiles[id]

static func region(id: String) -> Rect2:
	load_atlas()
	assert(catalog.has(id),"Missing sprite: "+id)
	var bounds=catalog[id].rect
	return Rect2(bounds[0],bounds[1],bounds[2],bounds[3])

static func sprite(c: CanvasItem,id: String,p: Vector2,size: Vector2=Vector2.ZERO,tint: Color=Color.WHITE) -> void:
	var source=region(id)
	c.draw_texture_rect_region(atlas,Rect2(p.round(),sprite_size(id) if size==Vector2.ZERO else size),source,tint)

# Draws only the part of a sprite that falls inside clip, as if the rest were hidden behind something.
static func sprite_within(c: CanvasItem,id: String,rect: Rect2,clip: Rect2) -> void:
	var view=rect.intersection(clip)
	if view.has_area(): c.draw_texture_rect_region(atlas,view,source_within(id,rect,view))

# The part of the sprite's atlas region that lands in view when the whole sprite is drawn at rect.
static func source_within(id: String,rect: Rect2,view: Rect2) -> Rect2:
	var source=region(id)
	var scale=source.size/rect.size
	return Rect2(source.position+(view.position-rect.position)*scale,view.size*scale)

static func stone_sprite(c: CanvasItem,id: String,p: Vector2,state: RefCounted) -> void:
	load_atlas()
	var paving=Borders.surface_id("paving",state.season_name(),state.weather_name(),0)
	var key=pack_path+":"+id+":"+paving
	if not stone_variants.has(key):
		var source=pixels.get_region(Rect2i(region(id)))
		var stone=pixels.get_region(Rect2i(region(paving)))
		var result=Image.create(source.get_width(),source.get_height(),false,Image.FORMAT_RGBA8)
		for x in range(0,result.get_width(),tile_size):
			result.blit_rect(stone,Rect2i(0,0,mini(tile_size,result.get_width()-x),tile_size),Vector2i(x,result.get_height()-tile_size))
		result.blend_rect(source,Rect2i(Vector2i.ZERO,source.get_size()),Vector2i.ZERO)
		stone_variants[key]=ImageTexture.create_from_image(result)
	c.draw_texture_rect(stone_variants[key],Rect2(p,sprite_size(id)),false)

static func tile(c: CanvasItem,id: String,cell: Vector2i,tint: Color=Color.WHITE) -> void:
	sprite(c,"tile_"+id,Grid.origin(cell),Vector2.ZERO,tint)

static func border(c: CanvasItem,material: String,cells: Dictionary,cell: Vector2i,state: RefCounted,seed_value: int,tint: Color=Color.WHITE) -> void:
	var id=Borders.sprite_id(material,Borders.mask(cells,cell),state.season_name(),state.weather_name(),Borders.variant(cell,seed_value))
	tile(c,id.trim_prefix("tile_"),cell,tint)

static func tile_strip(c: CanvasItem,id: String,cell: Vector2i,source_band: Rect2i) -> void:
	var base=region("tile_"+id)
	var scale=tile_size/16.0
	var source=Rect2(base.position+Vector2(source_band.position)*scale,Vector2(source_band.size)*scale)
	var destination=Rect2(Grid.origin(cell)+Vector2(source_band.position)*2,Vector2(source_band.size)*2)
	c.draw_texture_rect_region(atlas,destination,source)

static func furniture_id(item: Dictionary) -> String:
	if item.kind in ["shed_ladder","shed_workbench"]: return item.kind
	return "furniture_%s_%dx%d" % [item.kind,item.bounds.size.x,item.bounds.size.y]

static func furniture(c: CanvasItem,item: Dictionary) -> void:
	if item.kind in ["shed_ladder","shed_workbench"]:
		sprite(c,furniture_id(item),Vector2(0,-64 if item.kind=="shed_ladder" else -48),Vector2(32,64) if item.kind=="shed_ladder" else Vector2(64,48))
		return
	var bounds: Rect2i=item.bounds
	sprite(c,furniture_id(item),Vector2(-4,-bounds.size.y*32-24))

static func cover(c: CanvasItem,item: Dictionary) -> void:
	var size: Vector2i=item.bounds.size
	sprite(c,"cover_%dx%d" % [size.x,size.y],Vector2(-4,-size.y*32-24))

static func tree_id(data: Dictionary) -> String:
	var rows=clampi(roundi((data.size-0.8)*4)+2,2,4)
	var species=tree_species(data)
	return seasonal("tree_%s_%d" % [species,rows],data.get("season","spring"))

static func tree_species(data: Dictionary) -> String:
	return "oak" if data.warm else "birch" if posmod(data.cell.x+data.cell.y,5)==0 else "pine"

static func seasonal(id: String,season: String) -> String:
	load_atlas()
	return id+"_"+season if season!="spring" and catalog.has(id+"_"+season) else id

static func tree(c: CanvasItem,data: Dictionary) -> void:
	var id=tree_id(data)
	sprite(c,id,Vector2(-48,-sprite_size(id).y+5))

static func person(c: CanvasItem,p: Dictionary,step: float,direction: String) -> void:
	var frame=0 if absf(step)<0.3 else 1 if step>0 else 2
	var id=p.get("id","player")
	if id=="priest":
		sprite(c,"actor_priest_down0" if catalog.has("actor_priest_down0") else "actor_mayor_down0",Vector2(-16,-60),Vector2(32,64))
		return
	if p.get("seated",false):
		sprite(c,"actor_%s_down0" % id,Vector2(0,-68),Vector2(32,48))
		return
	if p.get("sleeping",false):
		sprite(c,"actor_%s_sleep0" % id,Vector2(-16,-float(p.get("bed_height",64))+4))
	else: sprite(c,"actor_%s_%s%d" % [id,direction,frame],Vector2(-16,-60))

# Flowerbeds sit in the row in front of a building, beside its door. Widow Marsh's front fence and Smithy Row
# both run along that row, and the town hall's walk to the square leaves by its east side, so those get fewer.
static func flowerbed_columns(b: Dictionary) -> Array:
	if b.id in ["widow","store"]: return []
	if b.kind=="hall": return [1]
	return [1,int(b.w/32)-2]

# Each home's wall and wall lanterns, so the cottages around town don't all look alike. Roofs follow the wall.
const FACADES={"mayor":["fieldstone","brass"],"tavi":["clapboard","iron"],"assistant":["brick","iron"],"finch":["timber","brass"],"radio":["stone","copper"],"mill_home":["log","iron"],"widow":["brick","brass"],"herbalist":["timber","copper"]}
# A wall lantern is narrow enough to hang in the gap between a door frame and the window beside it.
# Its glass is where the flame glows at night.
const LANTERN_SIZE=Vector2(10,18)
const LANTERN_GLASS=Rect2(2,4,6,10)

# Where a building's windows and wall lanterns go, relative to the bottom-left of its base.
# Lanterns hang on either edge of the door, so they never cover the glass of the windows beside it.
# Buildings drawn from a single picture have no facade.
static func facade(b: Dictionary) -> Dictionary:
	if b.kind in ["mill_shed","observatory","lighthouse"] or (b.kind=="temple" and catalog.has("building_temple")): return {}
	var columns=int(b.w/32)
	var door=int(columns/2)
	var windows=[]
	for x in [1,columns-2]:
		if x!=door and x not in windows: windows.append(x)
	var kind=FACADES.get(b.get("id",""),["","iron"])[1]
	var lanterns=[]
	for edge in [door,door+1]:
		lanterns.append({"sprite":"wall_lantern_"+kind,"rect":Rect2(edge*32-LANTERN_SIZE.x/2,-60,LANTERN_SIZE.x,LANTERN_SIZE.y)})
	return {"wall":wall_style(b),"roof":roof_style(b),"lantern":kind,"door":door,"windows":windows,"lanterns":lanterns}

static func wall_rows(b: Dictionary) -> int:
	if b.kind=="windmill": return 5
	if b.kind=="tower": return 4
	return maxi(2,int(b.h/32)-2)

# How far a building's artwork reaches above its base, so it only fades when someone is really behind it.
# The chimney is left out: it's narrow, and counting it would fade a house for anyone walking past its back fence.
static func building_height(b: Dictionary) -> int:
	if b.has("visual_height"): return b.visual_height
	if b.kind=="temple" and catalog.has("building_temple"): return TEMPLE_HEIGHT
	if b.kind=="mill_shed": return 96
	return (wall_rows(b)+2)*32

const TEMPLE_HEIGHT=224

static func building(c: CanvasItem,b: Dictionary) -> void:
	if b.kind=="temple" and catalog.has("building_temple"):
		sprite(c,"building_temple",Vector2(0,-TEMPLE_HEIGHT),Vector2(224,TEMPLE_HEIGHT))
		return
	if b.kind=="mill_shed":
		for y in range(3):
			for x in range(4):
				var part="roof" if y==0 else "door_top" if x==2 and y==1 else "door_bottom" if x==2 else "wall"
				tile(c,"shed_"+part,Vector2i(x,y-3))
		return
	if b.kind=="observatory":
		sprite(c,"observatory_exterior",Vector2(0,-224),Vector2(192,224))
		return
	if b.kind=="lighthouse":
		for y in range(6):
			for x in range(3):
				var component="stripe" if y==3 else "wall"
				if x==1 and y==2: component="window"
				if x==1 and y>=4: component="door_top" if y==4 else "door_bottom"
				tile(c,"lighthouse_"+component,Vector2i(x,y-6),Color.WHITE if x==1 else Color("e3e8e4") if x==0 else Color("a6b8bb"))
		for x in range(3):
			tile(c,"lantern_"+["left","center","right"][x],Vector2i(x,-7))
			tile(c,"cap_"+["left","center","right"][x],Vector2i(x,-8))
		return
	var columns=int(b.w/32)
	var rows=wall_rows(b)
	var front=facade(b)
	var variant=front.wall
	var door=front.door
	for y in range(rows):
		for x in range(columns):
			var component="foundation" if y==rows-1 else "wall"
			if x==0: component="left"
			if x==columns-1: component="right"
			if y==rows-2 and x in front.windows: component="window"
			if x==door and y==rows-2: component="door_top"
			if x==door and y==rows-1: component="door_bottom"
			if b.kind=="tower" and x==door and y==1: component="window"
			var id="tower_left" if b.kind=="tower" and x==0 else "tower_right" if b.kind=="tower" and x==columns-1 else variant+"_"+component
			tile(c,id,Vector2i(x,y-rows))
	var style=roof_style(b)
	var season=b.get("season","spring")
	for y in range(2):
		for x in range(columns):
			var component="roof" if y==1 else "ridge"
			if y==0 and x==0: component="roof_left"
			if y==0 and x==columns-1: component="roof_right"
			var at=Grid.origin(Vector2i(x,y-rows-2))
			sprite(c,seasonal(roof_part(style,component),season),at,Vector2.ZERO,roof_tint(b.roof))
			# Leaves and snow sit on top untinted, so they keep their own colours on every roof.
			var cover="tile_roof_cover_%s_%s" % [season,component]
			if catalog.has(cover): sprite(c,cover,at)
	if b.id!="priest_outhouse": tile(c,"chimney",Vector2i(maxi(1,columns-2),-rows-3))
	if b.kind=="store": sprite(c,"sign_general_store" if catalog.has("sign_general_store") else "general_store_sign",Vector2(columns*16-56,-(rows+1)*32+8),Vector2(112,24))
	for x in flowerbed_columns(b):
		if x!=door: sprite(c,seasonal("tile_flowerbed0",b.get("season","spring")),Grid.origin(Vector2i(x,0)))
	for lantern in front.lanterns: sprite(c,lantern.sprite,lantern.rect.position,lantern.rect.size)
	if b.kind=="hall":
		preload("res://town_sign_art.gd").draw(c,"hall",door*32+16)
	if b.kind in ["smithy","bakery"] and catalog.has("sign_smith" if b.kind=="smithy" else "sign_baker"):
		sprite(c,"sign_smith" if b.kind=="smithy" else "sign_baker",Vector2(door*32-16,-88),Vector2(64,32))
	elif b.kind in ["smithy","bakery"]: tile(c,b.kind+"_sign",Vector2i(maxi(0,door-1),-2))
	if b.kind=="radio":
		var mast=Vector2(-30,-150)
		c.draw_line(mast,Vector2(-30,-3),Color("a3aa9c"),4)
		c.draw_line(Vector2(-62,-125),Vector2(2,-125),Color("c4c9b5"),2)
		c.draw_line(Vector2(-51,-110),Vector2(-9,-110),Color("c4c9b5"),2)
		for x in [-58,-44,-30,-16,-2]: c.draw_line(Vector2(x,-131),Vector2(x,-119),Color("d1cfb4"),2)
		c.draw_line(Vector2(-62,-125),Vector2(-73,-4),Color("7d918b"),1)
		c.draw_line(Vector2(2,-125),Vector2(13,-4),Color("7d918b"),1)
	if b.kind=="tavern":
		preload("res://town_sign_art.gd").draw(c,"tavern",door*32+16)

static func wall_style(b: Dictionary) -> String:
	if FACADES.has(b.get("id","")): return FACADES[b.id][0]
	return "log" if b.kind in ["cabin","reed_farm"] else "stone" if b.kind in ["tower","hall","smithy"] else "shop" if b.kind in ["store","bakery","tavern"] else "plaster"

static func roof_style(b: Dictionary) -> String:
	return {"log":"thatch","stone":"slate","shop":"clay","plaster":"shingle","timber":"thatch","brick":"clay","clapboard":"shingle","fieldstone":"slate"}[wall_style(b)]

static func roof_part(style: String,part: String) -> String:
	var id="tile_%s_%s" % [style,part]
	return id if catalog.has(id) else "tile_"+part

static func plant_overlay(crop: String,ripe: bool) -> String:
	var id="plant_overlay_%s_%s" % [crop,"ripe" if ripe else "growing"]
	if catalog.has(id): return id
	return "plant_overlay_"+("bulb" if ripe and crop=="star_bulbs" else "turnip" if ripe else "sprout")

static func roof_tint(value: String) -> Color:
	return Color(value).lerp(Color.WHITE,0.65)

static func cliff(c: CanvasItem,cell: Vector2i,cells: Dictionary) -> void:
	var mask=0
	for pair in [[Vector2i.LEFT,1],[Vector2i.RIGHT,2],[Vector2i.UP,4],[Vector2i.DOWN,8]]:
		if not cells.has(cell+pair[0]): mask|=pair[1]
	tile(c,"cliff"+str(mask),cell)

static func outdoors(w: Node2D) -> void:
	w.draw_texture(w.terrain,Vector2.ZERO)
	w.Coast.draw(w)
	var docks=w.Coast.dock_cells()
	for cell in w.trail_cells:
		if not docks.has(cell): border(w,"dirt",w.path_cells,cell,w.state,w.state.world_seed,Color(1,1,1,0.45))
	for cell in w.cliff_cells: border(w,"cliff",w.cliff_cells,cell,w.state,w.state.world_seed)
	for y in range(w.CAVE_MOUTH.position.y,w.CAVE_MOUTH.end.y):
		for x in range(w.CAVE_MOUTH.position.x,w.CAVE_MOUTH.end.x): tile(w,"void",Vector2i(x,y))
	tile(w,"cave_arch_left",w.CAVE_MOUTH.position)
	tile(w,"cave_arch_right",w.CAVE_MOUTH.position+Vector2i.RIGHT)
	for cell in w.Neighbors.FLOWERS+w.garden_cells.keys():
		if str(w.garden_cells.get(cell))=="vegetables":
			border(w,"tilled",{cell:true},cell,w.state,w.state.world_seed)
			sprite(w,"plant_overlay_turnip",Grid.origin(cell))
		else: sprite(w,seasonal("tile_flowerbed"+str(posmod(cell.x+cell.y,2)),w.state.season_name()),Grid.origin(cell))
	for cell in w.yard_fences: tile(w,"town_"+w.yard_fences[cell]+"_mask"+str(w.TownPaths.fence_mask(w,cell)),cell)
	for cell in w.yard_gates: tile(w,"town_"+w.yard_gates[cell]+"_gate",cell)
	for x in range(w.JETTY_CELLS.position.x,w.JETTY_CELLS.end.x): tile(w,"jetty",Vector2i(x,w.JETTY_CELLS.position.y))
	for cell in w.fence_cells: tile(w,"fence_mask"+str(w.fence_mask(cell)),cell)
	for cell in w.gate_cells: tile(w,"gate_h_open",cell)
	for garden in w.DECORATIVE_FIELDS+w.Neighbors.FIELDS:
		var field=Borders.rect_cells(garden)
		for y in range(garden.position.y,garden.end.y):
			for x in range(garden.position.x,garden.end.x):
				var cell=Vector2i(x,y)
				border(w,"tilled",field,cell,w.state,w.state.world_seed)
				sprite(w,"plant_overlay_turnip" if (x+y)%3 else "plant_overlay_sprout",Grid.origin(cell))
	sprite(w,"cart",Grid.origin(w.CART_CELLS.position)-Vector2(0,32))
	sprite(w,"crossroads_sign",w.site_position("sign")-Vector2(16,40),Vector2(32,48))

static func interior_wall(room: Node2D) -> String:
	return "metal_wall" if room.is_starship() else "wall"

static func interior(room: Node2D) -> void:
	room.draw_rect(Rect2(-400,-250,room.ROOM_SIZE.x+800,room.ROOM_SIZE.y+500),Color("263732"))
	for cell in room.floor_cells:
		var id="metal" if room.is_starship() else "bath" if room.floor_cells[cell] in ["bathroom","kitchen"] else "wood"+str(posmod(hash([room.state.world_seed,room.building.id,cell]),4))
		var tint=Color.WHITE
		if room.building.id=="home" and ((room.floor_cells[cell]=="living" and not room.state.house_tasks.living_light) or (room.floor_cells[cell]=="bedroom" and not room.state.house_tasks.bathroom_light)): tint=Color("8b9690")
		tile(room,id,cell,tint)
	for item in room.furnishings:
		if item.kind!="rug": continue
		room.draw_set_transform(Grid.origin(item.bounds.position+Vector2i(0,item.bounds.size.y)))
		furniture(room,item)
	room.draw_set_transform(Vector2.ZERO)
	tile(room,"metal" if room.is_starship() else "jetty",room.layout.exit)
	for cell in room.layout.get("private_doors",[]):
		tile(room,"plaster_door_top",cell+Vector2i.UP)
		tile(room,"plaster_door_bottom",cell)

static func crops(w: Node2D,c: CanvasItem) -> void:
	for i in range(w.state.plots.size()):
		var p=w.state.plots[i]
		var cell=Grid.world_to_cell(w.plot_position(i))
		var material="tilled" if p.tilled else "soil"
		border(c,material,w.farm_cells,cell,w.state,w.state.world_seed)
		var moisture=w.state.plot_moisture(i)
		if moisture>0 and w.state.weather_name()!="rainy":
			var wet=Borders.sprite_id(material,Borders.mask(w.farm_cells,cell),w.state.season_name(),"rainy",Borders.variant(cell,w.state.world_seed))
			sprite(c,wet,Grid.origin(cell),Vector2.ZERO,Color(1,1,1,moisture))
		if p.planted>=0:
			var plant=plant_overlay(p.crop,w.state.ripe(i))
			# Packs without field art for the newer crops show their code-drawn icon when ripe.
			if w.state.ripe(i) and not plant.ends_with("_ripe") and preload("res://crop_art.gd").COLORS.has(p.crop):
				c.draw_texture_rect(preload("res://crop_art.gd").icon(p.crop),Rect2(Grid.origin(cell)-Vector2(0,16),Vector2(32,32)),false)
				continue
			sprite(c,plant,Grid.origin(cell))

static func particles(w: Node2D,c: CanvasItem) -> void:
	for p in w.particles:
		var color=Color(p.color)
		color.a=minf(1,p.life)
		sprite(c,"particle",p.pos,Vector2.ZERO,color)

static func effects(w: Node2D,c: CanvasItem) -> void:
	preload("res://outdoor_motion.gd").draw(w,c)
	for p in w.people:
		if w.cutscene_hidden(): break
		if w.villagers[p.id].visible and w.state.player_position.distance_to(w.villagers[p.id].position)<105:
			c.draw_string(preload("res://pixel_ui.gd").font(),w.villagers[p.id].position+Vector2(-29,-55),p.name,HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("e4d9b5"))
	if w.nearest.get("type")=="plot": c.draw_rect(Rect2(w.plot_position(w.nearest.index)-Vector2(16,16),Vector2(32,30)),Color("eee0a5"),false,1)
	sprite(c,"ship_crew",Grid.center(w.SHIP_CELL)-Vector2(96,68),Vector2.ZERO,Color(0.8,1,0.9,0.12+sin(w.elapsed)*0.03))
	for i in range(14):
		var p=Vector2(500+(i*137)%1100+sin(w.elapsed*.4+i)*30,670+(i*79)%570+cos(w.elapsed*.6+i)*20)
		if w.state.minute>1140 or w.state.minute<330: sprite(c,"firefly",p)
	particles(w,c)

static func indoor_effects(room: Node2D,c: CanvasItem) -> void:
	if room.building.id=="home":
		for item in room.furnishings:
			if item.kind!="floor_lamp": continue
			var task="living_light" if room.floor_cells[item.bounds.position]=="living" else "bathroom_light"
			if room.state.house_tasks[task]: c.draw_circle(Grid.center(item.bounds.position)-Vector2(0,24),19,Color("f7d78c22"))
	if room.is_starship():
		for origin in room.wire_ends():
			c.draw_rect(Rect2(origin-Vector2(18,64),Vector2(18,6)),Color("657d88"))
			sprite(c,"cable",origin-Vector2(16,60))
			if fmod(room.elapsed+origin.x*.03,3.7)<.16: sprite(c,"spark"+str(int(room.elapsed*30)%6),origin-Vector2(8,8))
	for actor in room.villagers.values():
		if room.cutscene_hidden(): break
		if actor.visible and actor.position.distance_to(room.state.player_position)<100:
			c.draw_string(preload("res://pixel_ui.gd").font(),actor.position+Vector2(-25,-55),"z z z" if actor.data.get("sleeping",false) else actor.data.name,HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("e4d9b5"))
	particles(room,c)
