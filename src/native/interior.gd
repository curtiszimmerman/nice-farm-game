extends "res://world.gd"

const Layouts=preload("res://interior_layouts.gd")
var ROOM_CELLS=Vector2i.ZERO
var ROOM_SIZE=Vector2.ZERO
var layout: Dictionary
var floor_cells: Dictionary={}
var building: Dictionary
var outdoors: Node2D
var furnishings: Array=[]
var rendered_tasks: Dictionary={}
var animated_displays: Array=[]

class Furniture extends Node2D:
	var room: Node2D
	var item: Dictionary
	var draw_count=0
	func _draw() -> void:
		draw_count+=1
		room.paint_furniture(self,item)
		if item.has("task") and not room.state.house_tasks[item.task]: room.paint_cover(self,item)

class Display extends Node2D:
	var room: Node2D
	var item: Dictionary
	var draw_count=0
	func _draw() -> void:
		draw_count+=1
		room.paint_display(self,item)

class Wall extends Node2D:
	var room: Node2D
	var front=false
	var mask=0
	func _draw() -> void:
		if Art.option==2:
			Art.sprite(self,"tile_metal_wall" if room.building.id=="ship" else "wall_house_mask"+str(mask),Vector2(0,-64),Vector2(32,64))
			return
		room.r(self,0,-40,32,40,"3e554e")
		if front:
			room.r(self,0,-29,32,27,"75877a")
			room.r(self,0,-4,32,4,"344c45")
			room.r(self,0,-7,32,3,"a1ac91")
			room.r(self,0,-35,32,6,"bec0a7")
			room.r(self,0,-29,32,2,"d1ceb2")

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
	thin_partitions()
	for y in range(ROOM_CELLS.y):
		for x in range(ROOM_CELLS.x):
			if not floor_cells.has(Vector2i(x,y)): solid_cells[Vector2i(x,y)]="wall"
	for cell in solid_cells:
		if not [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT].any(func(direction):return floor_cells.has(cell+direction)): continue
		var wall=Wall.new()
		wall.room=self
		wall.front=floor_cells.has(cell+Vector2i.DOWN)
		for pair in [[Vector2i.LEFT,1],[Vector2i.RIGHT,2],[Vector2i.UP,4],[Vector2i.DOWN,8]]:
			if solid_cells.has(cell+pair[0]): wall.mask|=pair[1]
		wall.position=Grid.origin(cell)+Vector2(0,32)
		add_child(wall)
	for item in layout.furniture:
		if item[0]=="shed_ladder" and state.ladder_taken: continue
		add_furniture(item[0],item[1],item[0] not in ["rug","art"])
	add_site("exit",layout.exit,"Leave "+room_name())
	for site in layout.sites:
		if site[0]=="ladder":
			if not state.ladder_taken: add_site("ladder",site[1],"Collect Mrs. Bell's ladder")
			continue
		add_site(site[0],site[1],{"bed":"Rest in the bedroom","radio":"Listen to the radio","shop":"Browse Tavi's provisions","cabinet":"Open kitchen cabinet","stove":"Cook at the stove","ship_storage":"Open crew supply locker","diagnostics":"Inspect damaged machinery","uncover_sofa":"Remove sofa cover","uncover_guest_bed":"Remove guest bed cover","living_light":"Replace living-room lamp bulb","bathroom_light":"Replace bedroom lamp bulb","private_door":"Rafe's private quarters"}[site[0]])
	crops=Node2D.new()
	add_child(crops)
	player=_prop("player",state.player_position,{"coat":"6f9793","hair":"5c5045","skin":"d0a981","id":"player"})
	for person in outdoors.people:
		villagers[person.id]=_prop("person",entry_position(),person.duplicate())
		villagers[person.id].visible=false
	var effects=_prop("effects",Vector2.ZERO,{})
	effects.z_index=5
	update_villagers(0.0,true)

func thin_partitions() -> void:
	# Give spare partition space back to a room while keeping its separating wall.
	var changed=true
	while changed:
		changed=false
		for cell in floor_cells.keys():
			for direction in [Vector2i.RIGHT,Vector2i.DOWN]:
				var other=cell+direction*3
				if not floor_cells.has(other) or floor_cells.has(cell+direction) or floor_cells.has(cell+direction*2): continue
				for pair in [[cell+direction,floor_cells[cell]],[cell+direction*2,floor_cells[other]]]:
					if pair[1] in ["doorway","entry"]: continue
					var safe=true
					for step in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
						if floor_cells.has(pair[0]+step) and floor_cells[pair[0]+step]!=pair[1]: safe=false
					if safe:
						floor_cells[pair[0]]=pair[1]
						changed=true
						break

func add_site(id: String,cell: Vector2i,label: String) -> void:
	var p=Grid.center(cell)
	sites.append({"id":id,"cell":cell,"x":p.x,"y":p.y,"label":label})

func add_furniture(kind: String,bounds: Rect2i,solid: bool=true) -> void:
	var data={"kind":kind,"bounds":bounds}
	if building.id=="home" and kind in ["bed","sofa","radio"]:
		data.task="guest_bed" if kind=="bed" and bounds.position.x==4 else kind
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
	if kind in ["reactor","machine","console"]:
		var display=Display.new()
		display.room=self
		display.item=data
		prop.add_child(display)
		animated_displays.append(display)

func entry_position() -> Vector2: return Grid.center(layout.entry)

func bed_position(resident: String="") -> Vector2:
	var beds=furnishings.filter(func(item):return item.kind=="bed")
	var index=int(layout.get("beds",{}).get(resident,0))
	if resident=="":
		for i in range(beds.size()):
			if beds[i].bounds.has_point(front_cell()):
				index=i
				break
	for item in beds.slice(index,index+1):
		if item.kind=="bed": return Grid.origin(item.bounds.position)+Vector2(item.bounds.size.x*16+layout.get("bed_offsets",{}).get(resident,0),item.bounds.size.y*32-8)
	return entry_position()

func room_name() -> String:
	if building.id=="temple": return "Village temple"
	if building.id=="priest": return "Brother Aven's home"
	if building.id=="priest_outhouse": return "Temple outhouse"
	if building.id=="mill_shed": return "Bell family tool shed"
	if Neighbors.NAMES.has(building.id): return Neighbors.NAMES[building.id]
	match building.id:
		"ship": return "Cloaked ship · engineering & bunks"
		"home": return "Your farmhouse"
		"radio": return "Briar Glen Radio Club"
		"store": return "Tavi's provisions"
		"hall": return "Briar Glen town hall"
		"iona": return "Iona's tower"
		"veteran": return "Bram's cabin"
		"assistant": return "Neral's home"
		"keeper": return "Oren's lighthouse"
		_: return building.id.capitalize()+"'s home"

func blocked(p: Vector2) -> bool:
	var cell=Grid.world_to_cell(p)
	return not Rect2i(Vector2i.ZERO,ROOM_CELLS).has_point(cell) or solid_cells.has(cell)

func player_blocked(p: Vector2) -> bool:
	return blocked(p) or Grid.world_to_cell(p) in layout.get("private_doors",[])

func wall_can_fade(wall: Wall) -> bool:
	var cell=Grid.world_to_cell(wall.position)-Vector2i.DOWN
	return floor_cells.get(cell+Vector2i.UP,"") in ["hall","back_hall","doorway"]

func target_plot() -> int: return -1
func in_water(_p: Vector2) -> bool: return false
func audio_context(_p: Vector2) -> Dictionary:
	return {"environment":"ship" if building.id=="ship" else "indoors","season":state.season_name(),"cave_weight":0.0}

func prepare_departures() -> void:
	for id in villagers:
		if id=="vale" or outdoors.conversation_holds.has(id): continue
		if villagers[id].visible and outdoors.villagers[id].data.get("room","")==building.id and outdoors.stop_for(id).room!=building.id:
			outdoors.indoor_departures[id]=building.id

func walk_actor(id: String,cell: Vector2i,dt: float,speed: float=45) -> bool:
	return Bodies.walk_to(self,id,cell,dt,speed)

func step_out_of_bed(actor: Node2D,dt: float) -> bool:
	var bed=bed_position(actor.data.id)
	if not blocked(actor.position) or actor.position.distance_to(bed)>40: return false
	actor.data.sleeping=false
	actor.data.walking=true
	actor.position=actor.position.move_toward(Grid.center(Grid.world_to_cell(bed)+Vector2i.DOWN),dt*45)
	actor.queue_redraw()
	return true

func update_villagers(dt: float,snap: bool=false) -> void:
	for id in villagers:
		if outdoors.conversation_holds.has(id): continue
		var actor: Node2D=villagers[id]
		var outside: Node2D=outdoors.villagers[id]
		if outdoors.indoor_departures.get(id,"")==building.id:
			actor.data.sleeping=false
			if step_out_of_bed(actor,dt): continue
			if walk_actor(id,layout.exit,dt):
				actor.visible=false
				outside.data.room=""
				outside.data.sleeping=false
				outside.position=outdoors.exit_position(building)
				outside.visible=true
				outdoors.indoor_departures.erase(id)
			continue
		var active=outside.data.get("room","")==building.id
		var was_visible=actor.visible
		actor.visible=active
		if not active: continue
		if not was_visible and not snap:
			actor.position=entry_position()
			routes.erase(id)
		var sleeping=outside.data.get("sleeping",false)
		actor.data.sleeping=false
		actor.rotation=0.0
		actor.z_index=0
		if sleeping:
			var bed=bed_position(id)
			if snap: actor.position=bed
			elif actor.position.distance_to(bed)<35:
				actor.position=actor.position.move_toward(bed,dt*45)
				actor.data.walking=true
			else: walk_actor(id,Grid.world_to_cell(bed)+Vector2i.DOWN,dt)
			actor.data.sleeping=actor.position.distance_to(bed)<1
			actor.z_index=2 if actor.data.sleeping else 0
			actor.data.bed_height=bed_height()
			actor.queue_redraw()
			continue
		if not snap and step_out_of_bed(actor,dt): continue
		var cell: Vector2i=layout.work[int(state.minute/25)%layout.work.size()]
		if layout.work.size()>1 and id in Neighbors.STORIES:
			cell=layout.work[(int(state.minute/25)+Neighbors.STORIES.keys().find(id))%layout.work.size()]
		if building.id=="hall":
			cell=[Vector2i(14,9),Vector2i(14,10)][int(state.minute/35)%2] if id=="mayor" else [Vector2i(6,3),Vector2i(6,4),Vector2i(2,3)][int(state.minute/30)%3]
		if building.id=="tavern" and id!="barkeep": cell=tavern_guest_spot(id)
		var target=Grid.center(cell)
		if snap: actor.position=target
		else: walk_actor(id,cell,dt)
		actor.queue_redraw()

func tavern_guest_spot(id: String) -> Vector2i:
	var guests=outdoors.people.filter(func(person):return person.id!="barkeep" and outdoors.stop_for(person.id).room=="tavern").map(func(person):return person.id)
	guests.sort()
	var spots=[]
	for y in [10,12]:
		for x in range(2,18,2):
			var cell=Vector2i(x,y)
			if not blocked(Grid.center(cell)): spots.append(cell)
	return spots[posmod(guests.find(id),spots.size())] if not spots.is_empty() else layout.entry

func find_nearest() -> Dictionary:
	var person=preload("res://npc_bodies.gd").nearby(self)
	if not person.is_empty():
		if state.player_position.distance_to(site_position("exit"))<55 and villagers[person.id].position.distance_to(site_position("exit"))<Bodies.RADIUS+3:
			nearest=person
			return person
	var best={}
	var distance=55.0
	for id in villagers:
		var actor: Node2D=villagers[id]
		var d=state.player_position.distance_to(actor.position)
		if actor.visible and not actor.data.get("sleeping",false) and d<distance:
			best={"id":id,"type":"person","label":"Talk to "+actor.data.name}
			distance=d
	for site in sites:
		if building.id=="home":
			var task=site.id.trim_prefix("uncover_")
			if task in ["sofa","living_light","bathroom_light"] and (state.met_mayor or state.house_tasks[task]): continue
			if site.id=="uncover_guest_bed":
				if state.house_tasks.guest_bed or state.met_mayor: continue
		if front_cell() not in activation_cells(site): continue
		var d=state.player_position.distance_to(Vector2(site.x,site.y))
		if best.is_empty() or d<distance:
			best=site.duplicate()
			best.type="site"
			distance=d
	nearest=best
	return best

func activation_cells(site: Dictionary) -> Array:
	if site.id=="ladder": return [Vector2i(6,2)]
	if site.id=="exit": return [layout.exit,layout.exit+Vector2i.DOWN]
	if site.id=="private_door": return layout.private_doors
	var kind={"bed":"bed","uncover_guest_bed":"bed","uncover_sofa":"sofa","radio":"radio","stove":"kitchen","cabinet":"cabinet","shop":"counter","ship_storage":"cabinet","diagnostics":"machine","living_light":"floor_lamp","bathroom_light":"floor_lamp"}.get(site.id,"")
	var cells=[]
	for item in furnishings:
		if item.kind!=kind: continue
		if site.id=="stove": return [item.bounds.position]
		if site.id=="uncover_guest_bed" and item.get("task","")!="guest_bed": continue
		if kind=="floor_lamp" and (floor_cells[item.bounds.position]=="living")!=(site.id=="living_light"): continue
		for y in range(item.bounds.position.y,item.bounds.end.y):
			for x in range(item.bounds.position.x,item.bounds.end.x): cells.append(Vector2i(x,y))
	return cells if not cells.is_empty() else [site.cell]

func refresh() -> void:
	var previous_tasks=rendered_tasks
	var tasks_changed=rendered_tasks!=state.house_tasks
	if tasks_changed:
		rendered_tasks=state.house_tasks.duplicate()
		if building.id=="home": queue_redraw()
	for display in animated_displays: display.queue_redraw()
	player.position=state.player_position.round()
	player.data.sleeping=get_parent().resting>0
	player.data.bed_height=bed_height()
	player.z_index=2 if player.data.sleeping else 0
	player.queue_redraw()
	night_tint.color=Color("b3c9d0") if building.id=="ship" else Color("d5c4ae") if state.minute<360 or state.minute>1200 else Color.WHITE
	for child in moving_layer.get_children():
		if child is Prop and child.kind=="effects": child.queue_redraw()
	for child in get_children():
		if tasks_changed and child is Furniture and child.item.has("task"):
			if previous_tasks.get(child.item.task)!=state.house_tasks[child.item.task]: child.queue_redraw()
		if building.id=="home" and child is Furniture:
			var cell: Vector2i=child.item.bounds.position
			var kind=floor_cells.get(cell,"")
			var dim=(kind=="living" and not state.house_tasks.living_light) or (kind=="bedroom" and not state.house_tasks.bathroom_light)
			child.modulate=Color("929b94") if dim else Color.WHITE
		if child is Furniture or child is Wall:
			var width=32.0 if child is Wall else child.item.bounds.size.x*32.0
			var height=64.0 if child is Wall else child.item.bounds.size.y*32.0+30
			var covers=state.player_position.y<child.position.y and Rect2(child.position-Vector2(0,height),Vector2(width,height)).grow(8).has_point(state.player_position-Vector2(0,20))
			if child is Wall: covers=covers and wall_can_fade(child) and floor_cells.get(Grid.world_to_cell(state.player_position),"") in ["hall","back_hall","doorway"]
			child.modulate.a=0.3 if covers and not player.data.sleeping else 1.0

func bed_height() -> float:
	for item in furnishings:
		if item.kind=="bed": return item.bounds.size.y*32.0
	return 64.0

func _draw() -> void:
	if Art.option==2: Art.interior(self); return
	r(self,-400,-250,ROOM_SIZE.x+800,ROOM_SIZE.y+500,"263732")
	for cell in floor_cells:
		var p=Grid.origin(cell)
		if building.id=="ship":
			r(self,p.x,p.y,32,32,"35454f")
			r(self,p.x+2,p.y+2,28,28,"52636b" if (cell.x+cell.y)%3 else "485a63")
			r(self,p.x+5,p.y+4,2,2,"8ba0a1")
			if cell.x==7: r(self,p.x+14,p.y+2,3,28,"a99f70")
			continue
		r(self,p.x,p.y,32,32,"9e815b" if (cell.x+cell.y)%3 else "a98b62")
		r(self,p.x+1,p.y+2,30,1,"b99b6d")
		r(self,p.x+14,p.y+3,1,26,"876e50")
		if floor_cells[cell] in ["bathroom","kitchen"]: r(self,p.x+1,p.y+1,30,30,"abb7a4" if (cell.x+cell.y)%2 else "c2c7ae")
		if building.id=="home":
			if (floor_cells[cell]=="living" and not state.house_tasks.living_light) or (floor_cells[cell]=="bedroom" and not state.house_tasks.bathroom_light): r(self,p.x,p.y,32,32,"17232a55")
			if not state.house_tasks.sofa and posmod(cell.x*13+cell.y*7,5)==0:
				for i in range(4): r(self,p.x+4+i*5,p.y+posmod(i*7+cell.y,25),3,1,"c3bba077")
	for item in furnishings:
		if item.kind!="rug": continue
		draw_set_transform(Grid.origin(item.bounds.position+Vector2i(0,item.bounds.size.y)))
		paint_furniture(self,item)
	draw_set_transform(Vector2.ZERO)
	var door=site_position("exit")
	r(self,door.x-23,door.y-13,46,25,"586d62")
	r(self,door.x-20,door.y-10,40,18,"b69a65")
	if building.id=="ship": return
	for area in layout.areas:
		if area[0] in ["bathroom","hall"]: continue
		var bounds: Rect2i=area[1]
		var p=Grid.origin(bounds.position)+Vector2(8,-25)
		r(self,p.x,p.y,28,24,"718e88")
		r(self,p.x+13,p.y,2,24,"e3d4ab")
		r(self,p.x,p.y+11,28,2,"e3d4ab")

func paint_furniture(c: CanvasItem,item: Dictionary) -> void:
	if item.kind.begins_with("shed_"):
		Art.furniture(c,item)
		return
	if Art.option==2: Art.furniture(c,item); return
	var w=item.bounds.size.x*32
	var h=item.bounds.size.y*32
	if item.kind not in ["rug","art"]:
		oval(c,w/2+3,-3,w/2+4,7,"172d3455")
		r(c,3,-h+5,w-3,h-2,"263a3b55")
	match item.kind:
		"rug":
			r(c,0,-h,w,h,"667e72" if building.id=="moss" else "7f716f")
			r(c,5,-h+5,w-10,h-10,"8fa18b" if building.id=="moss" else "a38c7c")
			for x in range(10,w-10,14): r(c,x,-h+10,7,h-20,"b5a38b")
		"sofa":
			for x in [7,w-14]: r(c,x,-4,6,7,"4b4a3b")
			r(c,0,-h-18,w,h+14,"526f69")
			r(c,7,-h-12,w-14,25,"7e9a86")
			for x in range(8,w-10,36): r(c,x,-h+18,30,maxi(8,h-20),"90a58b")
			r(c,0,-h+10,10,h-10,"688a79")
			r(c,w-10,-h+10,10,h-10,"688a79")
			for x in [18,w-42]:
				r(c,x,-h+3,22,21,"b3ad8b")
				r(c,x+3,-h+6,16,2,"d0c49e")
			for x in range(13,w-10,9): r(c,x,-14,3,2,"49675e")
			r(c,w-9,-h+12,6,h-13,"3e6059")
			r(c,9,-5,w-18,3,"3d5b53")
		"table","chair","desk","counter":
			for x in [6,w-10]:
				r(c,x,-h+2,4,h,"574c3c")
				r(c,x,-h+2,1,h,"aa8860")
			r(c,4,-h-11,w-8,h-5,"aa875d")
			r(c,4,-16,w-8,7,"6c533d")
			r(c,w-9,-h-9,5,h-7,"785c42")
			r(c,6,-h-9,w-14,2,"d4b37e")
			if item.kind=="table": oval(c,w/2,-h/2,13,8,"d4ccaa")
			for yy in range(-h,-18,9): r(c,9,yy,w-21,1,"92704d")
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
			r(c,0,-h-12,w,14,"705943")
			r(c,3,-h-10,w-6,3,"bc9a6c")
			r(c,0,-h,w,h,"796951")
			r(c,5,-h+5,w-10,h-12,"d9d4b7")
			r(c,8,-h+9,w-16,14,"eee2c4")
			r(c,6,-h+25,w-12,h-31,"7d9390")
			r(c,8,-h+28,w-16,4,"a2b7a7")
			for yy in range(-h+36,-8,9): r(c,8,yy,w-16,2,"a0b0a1")
			r(c,w-7,-h+26,3,h-32,"536f73")
			r(c,0,-6,w,8,"584b3c")
			r(c,2,-6,w-4,2,"ae8e61")
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
			r(c,3,-h+3,w-6,h-3,"7e958d")
			r(c,5,-12,w-10,9,"b0bcaa")
			oval(c,w/2,-h/2-7,w/2-3,h/2-4,"e1dec3")
			oval(c,w/2,-h/2-8,w/2-8,h/2-9,"708f89")
			oval(c,w/2,-h/2-6,w/2-10,h/2-12,"a6c3b8")
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
			r(c,0,-h-35,w,5,"c2a37a")
			r(c,w-5,-h-30,5,h+28,"4c493b")
			for yy in range(-h-24,-2,18):
				for x in range(5,w-7,9):
					r(c,x,yy,6,12,["a08569","78988b","a39377","827c8e"][posmod(x+yy,4)])
					r(c,x,yy,1,12,"ded0a477")
					r(c,x+5,yy,1,12,"343d3955")
					for line in range(3):
						r(c,x+2,yy+3+line*2,2+posmod(x+line,2),1,"e2d3b0")
				r(c,3,yy+13,w-6,3,"b89d72")
				r(c,3,yy+16,w-6,2,"443f34")
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
			r(c,0,-h-6,w,6,"c2a27a")
			r(c,w-5,-h,5,h,"594f3d")
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
			poly(c,[Vector2(6,-18),Vector2(26,-18),Vector2(23,0),Vector2(9,0)],"a2805b")
			r(c,20,-16,4,12,"7c624c")
			oval(c,16,-18,11,4,"c3a077")
			for x in [4,14,22]: oval(c,x,-24,8,15,"6e8c61")
		"cabinet":
			r(c,0,-h-8,w,h+8,"887351" if building.id!="ship" else "526b75")
			r(c,0,-h-12,w,5,"c3a677" if building.id!="ship" else "91a4a9")
			for x in range(4,w-4,32):
				r(c,x,-h-4,26,h-1,"ab9168" if building.id!="ship" else "718b91")
				r(c,x+18,-h+8,5,2,"e1cd93")
		"reactor","machine","console":
			r(c,1,-h-20,w-2,h+18,"263842")
			r(c,3,-h-24,w-6,6,"9aadae")
			r(c,5,-h-17,w-15,h+7,"586f78")
			r(c,w-10,-h-18,8,h+14,"344751")

func paint_display(c: CanvasItem,item: Dictionary) -> void:
	if Art.option==2:
		var glitch=fmod(elapsed+item.bounds.position.x*1.7,11)<0.45
		Art.sprite(c,"display_"+item.kind+str(4 if glitch else int(elapsed*2)%4),Vector2(8,-item.bounds.size.y*32-13),Vector2(maxi(16,item.bounds.size.x*32-20),24))
		return
	var w=item.bounds.size.x*32
	var h=item.bounds.size.y*32
	match item.kind:
		"reactor","machine","console":
			if item.kind=="reactor":
				for y in range(-h-10,-8,14):
					r(c,16,y,w-40,8,"335358")
					r(c,19,y+1,w-46,4,"8fc9c0" if sin(elapsed*0.8)>0 else "658f98")
				c.draw_string(ThemeDB.fallback_font,Vector2(6,-3),"PHASE CORE",HORIZONTAL_ALIGNMENT_LEFT,-1,7,Color("bfcbc0"))
			elif item.kind=="console":
				r(c,8,-h-13,w-24,23,"172b38")
				var glitch=fmod(elapsed+item.bounds.position.x*1.7,11)<0.45
				for y in range(18):
					for x in range(0,w-28,3):
						if glitch: r(c,10+x,-h-11+y,2,1,"a7bbbd" if posmod(x*7+y*13+int(elapsed*35),5)>2 else "344e5c")
						elif y%5==0: r(c,10+x,-h-11+y,2,1,"79b5ad" if x%7 else "c0aa73")
				for x in range(10,w-15,9): r(c,x,-10,4,2,"adbbac")
			else:
				for x in range(10,w-12,11):
					r(c,x,-h-9,5,h-8,"354d57")
					r(c,x,-h+1,3,4,"d4b37a" if sin(elapsed+float(x))>0.3 else "5a756c")
				poly(c,[Vector2(6,-h+12),Vector2(w-15,-h+25),Vector2(12,-7)],"28383e")

func paint_cover(c: CanvasItem,item: Dictionary) -> void:
	if Art.option==2: Art.cover(c,item); return
	var w=item.bounds.size.x*32.0
	var h=item.bounds.size.y*32.0
	var lift=31 if item.kind=="radio" else 17 if item.kind=="sofa" else 8
	poly(c,[Vector2(0,-h-lift),Vector2(w-5,-h-lift+2),Vector2(w+2,-3),Vector2(w-5,1),Vector2(5,-2),Vector2(-3,1)],"b2af96")
	poly(c,[Vector2(w-12,-h-lift+3),Vector2(w-4,-h-lift+4),Vector2(w+2,-3),Vector2(w-10,-2)],"858d7e")
	for x in range(8,int(w)-5,17):
		c.draw_line(Vector2(x,-h-lift+7),Vector2(x+4,-5),Color("929a87"),2)
		c.draw_line(Vector2(x+3,-h-lift+6),Vector2(x+7,-6),Color("c5bea0"),1)
	for i in range(6): r(c,5+posmod(i*13,int(w)-10),-h+posmod(i*7,int(h)-4),2,1,"7d887a")

func paint_effects(c: CanvasItem) -> void:
	if Art.option==2: Art.indoor_effects(self,c); return
	if building.id=="home":
		for task in ["living_light","bathroom_light"]:
			var p=site_position(task)-Vector2(0,40)
			var working=state.house_tasks[task]
			r(c,p.x-1,p.y-12,2,12,"525c53")
			if working: oval(c,p.x,p.y+2,18,11,"e7d39833")
			oval(c,p.x,p.y,4,6,"ead9a2" if working else "737c76")
			if not working: r(c,p.x-2,p.y-1,5,2,"384b46")
	if building.id=="ship":
		for origin in [Vector2(135,282),Vector2(265,337),Vector2(385,402)]:
			c.draw_polyline(PackedVector2Array([origin-Vector2(14,60),origin-Vector2(5,35),origin+Vector2(-11,-15),origin]),Color("172a35"),3)
			c.draw_polyline(PackedVector2Array([origin-Vector2(9,60),origin-Vector2(2,34),origin+Vector2(-6,-13),origin+Vector2(4,1)]),Color("aa7b54"),1)
			if fmod(elapsed+origin.x*0.03,3.7)<0.16:
				for i in range(5):
					var angle=i*1.25+elapsed*7
					c.draw_line(origin,origin+Vector2(cos(angle),sin(angle))*9,Color("edcf83"),1)
		c.draw_string(ThemeDB.fallback_font,Vector2(38,314),"GRAVITIC SHEAR BUS",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("b5bdb1"))
		c.draw_string(ThemeDB.fallback_font,Vector2(162,314),"INERTIAL LATTICE",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("b5bdb1"))
	for actor in villagers.values():
		if actor.visible and actor.position.distance_to(state.player_position)<100:
			c.draw_string(ThemeDB.fallback_font,actor.position+Vector2(-25,-55),"z z z" if actor.data.get("sleeping",false) else actor.data.name,HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("e4d9b5"))
