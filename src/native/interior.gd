extends "res://world.gd"

const Layouts=preload("res://interior_layouts.gd")
var ROOM_CELLS=Vector2i.ZERO
var ROOM_SIZE=Vector2.ZERO
var layout: Dictionary
var floor_cells: Dictionary={}
var building: Dictionary
var outdoors: Node2D
var furnishings: Array=[]

class Furniture extends Node2D:
	var room: Node2D
	var item: Dictionary
	func _draw() -> void: room.paint_furniture(self,item)

func _ready() -> void:
	y_sort_enabled=true
	night_tint=CanvasModulate.new()
	add_child(night_tint)
	layout=Layouts.for_building(building.id)
	ROOM_CELLS=layout.size
	ROOM_SIZE=Vector2(ROOM_CELLS)*Grid.TILE_SIZE
	for area in layout.areas:
		var bounds: Rect2i=area[1]
		for y in range(bounds.position.y,bounds.end.y):
			for x in range(bounds.position.x,bounds.end.x):
				assert(not floor_cells.has(Vector2i(x,y)),"Rooms must not overlap")
				floor_cells[Vector2i(x,y)]=area[0]
	for door in layout.doors: floor_cells[door[2]]="doorway"
	floor_cells[layout.exit]="entry"
	for y in range(ROOM_CELLS.y):
		for x in range(ROOM_CELLS.x):
			if not floor_cells.has(Vector2i(x,y)): solid_cells[Vector2i(x,y)]="wall"
	for item in layout.furniture: add_furniture(item[0],item[1],item[0] not in ["rug","art"])
	add_site("exit",layout.exit,"Leave "+room_name())
	for site in layout.sites:
		add_site(site[0],site[1],{"bed":"Rest in the bedroom","radio":"Listen to the radio","shop":"Browse Tavi's provisions"}[site[0]])
	crops=Node2D.new()
	add_child(crops)
	player=_prop("player",state.player_position,{"coat":"6f9793","hair":"5c5045","skin":"d0a981","id":"player"})
	for person in outdoors.people:
		villagers[person.id]=_prop("person",entry_position(),person.duplicate())
		villagers[person.id].visible=false
	var effects=_prop("effects",Vector2.ZERO,{})
	effects.z_index=5
	update_villagers(0.0,true)

func add_site(id: String,cell: Vector2i,label: String) -> void:
	var p=Grid.center(cell)
	sites.append({"id":id,"cell":cell,"x":p.x,"y":p.y,"label":label})

func add_furniture(kind: String,bounds: Rect2i,solid: bool=true) -> void:
	var data={"kind":kind,"bounds":bounds}
	furnishings.append(data)
	if kind=="rug": return
	if solid:
		for y in range(bounds.position.y,bounds.end.y):
			for x in range(bounds.position.x,bounds.end.x):
				assert(floor_cells.has(Vector2i(x,y)),"Furniture must stand inside a room: %s in %s" % [kind,building.id])
				assert(not solid_cells.has(Vector2i(x,y)),"Furniture footprints must not overlap: %s in %s" % [kind,building.id])
				solid_cells[Vector2i(x,y)]="furniture"
	var prop=Furniture.new()
	prop.room=self
	prop.item=data
	prop.position=Grid.origin(bounds.position+Vector2i(0,bounds.size.y))
	add_child(prop)

func entry_position() -> Vector2: return Grid.center(layout.entry)

func room_name() -> String:
	match building.id:
		"home": return "Your farmhouse"
		"radio": return "Briar Glen Radio Club"
		"store": return "Tavi's provisions"
		"hall": return "Briar Glen town hall"
		"iona": return "Iona's tower"
		"veteran": return "Bram's cabin"
		_: return building.id.capitalize()+"'s home"

func blocked(p: Vector2) -> bool:
	var cell=Grid.world_to_cell(p)
	return not Rect2i(Vector2i.ZERO,ROOM_CELLS).has_point(cell) or solid_cells.has(cell)

func target_plot() -> int: return -1
func in_water(_p: Vector2) -> bool: return false
func audio_context(_p: Vector2) -> Dictionary:
	return {"environment":"indoors","season":state.season_name(),"cave_weight":0.0}

func update_villagers(dt: float,snap: bool=false) -> void:
	for id in villagers:
		var actor: Node2D=villagers[id]
		var outside: Node2D=outdoors.villagers[id]
		var active=outside.data.get("room","")==building.id
		actor.visible=active
		if not active: continue
		var sleeping=outside.data.get("sleeping",false)
		actor.data.sleeping=sleeping
		actor.rotation=PI/2 if sleeping else 0.0
		actor.z_index=2 if sleeping else 0
		if sleeping:
			for item in furnishings:
				if item.kind!="bed": continue
				actor.rotation=PI/2 if item.bounds.size.x>1 else 0.0
				actor.position=Grid.origin(item.bounds.position)+Vector2(10,24) if item.bounds.size.x>1 else Grid.origin(item.bounds.position)+Vector2(16,44)
				break
			actor.queue_redraw()
			continue
		var cell: Vector2i=layout.work[int(state.minute/25)%layout.work.size()]
		var target=Grid.center(cell)
		if snap: actor.position=target
		elif not routes.has(id) or routes[id].target!=target:
			routes[id]={"target":target,"path":_route(Grid.world_to_cell(actor.position),cell)}
		if routes.has(id) and not routes[id].path.is_empty():
			actor.position=actor.position.move_toward(routes[id].path[0],dt*45)
			if actor.position.distance_to(routes[id].path[0])<0.1: routes[id].path.pop_front()
		actor.queue_redraw()

func find_nearest() -> Dictionary:
	var best={}
	var distance=55.0
	for id in villagers:
		var actor: Node2D=villagers[id]
		var d=state.player_position.distance_to(actor.position)
		if actor.visible and not actor.data.get("sleeping",false) and d<distance:
			best={"id":id,"type":"person","label":"Talk to "+actor.data.name}
			distance=d
	for site in sites:
		var d=state.player_position.distance_to(Vector2(site.x,site.y))
		if d<distance:
			best=site.duplicate()
			best.type="site"
			distance=d
	nearest=best
	return best

func refresh() -> void:
	player.position=state.player_position.round()
	player.queue_redraw()
	night_tint.color=Color("d5c4ae") if state.minute<360 or state.minute>1200 else Color.WHITE
	for child in get_children():
		if child is Prop and child.kind=="effects": child.queue_redraw()

func _draw() -> void:
	r(self,-400,-250,ROOM_SIZE.x+800,ROOM_SIZE.y+500,"263732")
	for cell in floor_cells:
		var p=Grid.origin(cell)
		r(self,p.x,p.y,32,32,"9e815b" if (cell.x+cell.y)%3 else "a98b62")
		r(self,p.x+1,p.y+2,30,1,"b99b6d")
		r(self,p.x+14,p.y+3,1,26,"876e50")
		if floor_cells[cell] in ["bathroom","kitchen"]: r(self,p.x+1,p.y+1,30,30,"abb7a4" if (cell.x+cell.y)%2 else "c2c7ae")
	for cell in solid_cells:
		if solid_cells[cell]!="wall": continue
		var p=Grid.origin(cell)
		r(self,p.x,p.y-35,32,65,"cac6a8")
		r(self,p.x,p.y+24,32,8,"766d53")
		r(self,p.x,p.y-35,32,5,"e0d7b7")
	for item in furnishings:
		if item.kind!="rug": continue
		draw_set_transform(Grid.origin(item.bounds.position+Vector2i(0,item.bounds.size.y)))
		paint_furniture(self,item)
	draw_set_transform(Vector2.ZERO)
	var door=site_position("exit")
	r(self,door.x-23,door.y-13,46,25,"586d62")
	r(self,door.x-20,door.y-10,40,18,"b69a65")
	for area in layout.areas:
		if area[0] in ["bathroom","hall"]: continue
		var bounds: Rect2i=area[1]
		var p=Grid.origin(bounds.position)+Vector2(8,-25)
		r(self,p.x,p.y,28,24,"718e88")
		r(self,p.x+13,p.y,2,24,"e3d4ab")
		r(self,p.x,p.y+11,28,2,"e3d4ab")

func paint_furniture(c: CanvasItem,item: Dictionary) -> void:
	var w=item.bounds.size.x*32
	var h=item.bounds.size.y*32
	match item.kind:
		"rug":
			r(c,0,-h,w,h,"667e72" if building.id=="moss" else "7f716f")
			r(c,5,-h+5,w-10,h-10,"8fa18b" if building.id=="moss" else "a38c7c")
			for x in range(10,w-10,14): r(c,x,-h+10,7,h-20,"b5a38b")
		"sofa":
			r(c,0,-h-18,w,h+14,"526f69")
			r(c,7,-h-12,w-14,25,"7e9a86")
			for x in range(8,w-10,36): r(c,x,-h+18,30,maxi(8,h-20),"90a58b")
			r(c,0,-h+10,10,h-10,"688a79")
			r(c,w-10,-h+10,10,h-10,"688a79")
			for x in [18,w-42]:
				r(c,x,-h+3,22,21,"b3ad8b")
				r(c,x+3,-h+6,16,2,"d0c49e")
			for x in range(13,w-10,9): r(c,x,-14,3,2,"49675e")
		"table","chair","desk","counter":
			r(c,4,-h,w-8,h-5,"8f7050")
			r(c,6,-h+2,w-12,3,"bca070")
			for x in [6,w-10]: r(c,x,-8,4,10,"635942")
			if item.kind=="table": oval(c,w/2,-h/2,13,8,"d4ccaa")
			for yy in range(-h+8,-7,9): r(c,9,yy,w-18,1,"a5875f")
			if item.kind=="chair":
				r(c,4,-h-19,w-8,15,"a28a60")
				r(c,7,-h-16,w-14,2,"c1a678")
			if item.kind=="table":
				oval(c,w/2,-h/2,6,4,"b09766")
				r(c,w/2-2,-h/2-8,4,10,"64805c")
			elif item.kind=="desk":
				r(c,10,-h+5,22,14,"dfd7b7")
				for yy in range(4,14,4): r(c,13,-h+5+yy,15,1,"8a9782")
			elif item.kind=="counter":
				r(c,w-29,-h-14,21,17,"627769")
				r(c,w-26,-h-11,14,7,"d0be8a")
		"bed":
			r(c,0,-h,w,h,"796951")
			r(c,5,-h+5,w-10,h-12,"d9d4b7")
			r(c,8,-h+9,w-16,14,"eee2c4")
			r(c,6,-h+25,w-12,h-31,"7d9390")
			r(c,8,-h+28,w-16,4,"a2b7a7")
			for yy in range(-h+36,-8,9): r(c,8,yy,w-16,2,"a0b0a1")
		"kitchen":
			r(c,0,-h,w,h,"939479")
			r(c,0,-h-8,w,12,"ddd4b4")
			for x in range(4,w-6,32): r(c,x,-h+9,25,h-15,"b6ad8d")
			for x in range(4,w-6,32): r(c,x+17,-h+16,6,2,"6e705b")
			r(c,4,-h+15,51,h-25,"586c62")
			r(c,9,-h+20,41,maxi(5,h-37),"839389")
			for x in [15,40]: oval(c,x,-h+2,9,6,"495c54")
			oval(c,w-32,-h+4,19,9,"718a81")
			r(c,w-32,-h-15,3,17,"a9b8a3")
			for x in [85,98,113]:
				if x+10>w: continue
				r(c,x,-h-19,10,17,"9d8a67")
				r(c,x+2,-h-21,6,3,"d3c197")
		"bath","sink":
			r(c,0,-h,w,h,"b5c0ae")
			oval(c,w/2,-h/2,w/2-6,h/2-6,"e1dec3")
			oval(c,w/2,-h/2,w/2-11,h/2-11,"91aaa2")
			r(c,w-13,-h+3,3,12,"82998f")
			if item.kind=="sink":
				r(c,5,-h-39,w-10,31,"8da19b")
				r(c,8,-h-36,w-16,3,"c3d0b9")
		"toilet":
			r(c,5,-h-9,w-10,17,"d9ddc3")
			oval(c,w/2,-h/2+5,12,15,"e4e3c9")
			oval(c,w/2,-h/2+3,7,9,"98ada3")
		"bookshelf":
			r(c,0,-h-30,w,h+28,"6f634c")
			for yy in range(-h-24,-2,18):
				for x in range(5,w-4,9): r(c,x,yy,6,12,["a08569","78988b","a39377","827c8e"][posmod(x+yy,4)])
				r(c,3,yy+13,w-6,3,"b89d72")
		"radio":
			r(c,0,-h,w,h,"856c4e")
			r(c,0,-h-5,w,7,"b19a6d")
			r(c,9,-h-31,w-18,30,"546c63")
			for x in range(14,w-20,14): r(c,x,-h-27,8,14,"b8ae7e")
			r(c,w-25,-h-24,12,12,"d6be7c")
			for x in range(13,w-12,12):
				r(c,x,-h-8,5,5,"d2c596")
				r(c,x,-h+9,5,1,"5e604e")
			r(c,18,-h-46,2,16,"99aaa0")
			r(c,18,-h-46,mini(35,w-22),2,"b5c0ab")
		"stock","crates","seed_tray","tools":
			r(c,0,-h,w,h,"857154")
			for yy in range(-h+5,-2,14):
				for x in range(4,w-4,13):
					r(c,x,yy,9,10,"b7a075" if item.kind=="crates" else "9aa67b")
					r(c,2,yy+10,w-4,2,"c0a477")
			if item.kind=="tools":
				for x in [10,24,38]:
					r(c,x,-h-12,3,20,"a8aaa0")
					r(c,x-3,-h-13,9,3,"657364")
		"telescope":
			poly(c,[Vector2(4,-3),Vector2(17,-30),Vector2(27,-3),Vector2(16,-22)],"8d8362")
			poly(c,[Vector2(2,-31),Vector2(8,-42),Vector2(32,-28),Vector2(26,-18)],"8b9a9b")
		"art":
			r(c,0,-h-22,w,h+12,"8c7453")
			r(c,5,-h-17,w-10,h+2,"93b0a0")
			poly(c,[Vector2(6,-10),Vector2(w/2,-h-10),Vector2(w-6,-10)],"637e65")
		"plant":
			r(c,6,-18,20,18,"a2805b")
			for x in [4,14,22]: oval(c,x,-24,8,15,"6e8c61")

func paint_effects(c: CanvasItem) -> void:
	for actor in villagers.values():
		if actor.visible and actor.position.distance_to(state.player_position)<100:
			c.draw_string(ThemeDB.fallback_font,actor.position+Vector2(-25,-55),"z z z" if actor.data.get("sleeping",false) else actor.data.name,HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("e4d9b5"))
