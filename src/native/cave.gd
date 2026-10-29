extends "res://world.gd"

var building: Dictionary
var outdoors: Node2D
var ROOM_CELLS=Vector2i(81,61)
var ROOM_SIZE=Vector2(2592,1952)
var level=0
var layout={"entry":Vector2i(5,3),"exit":Vector2i(5,1)}
var chambers: Array[Rect2i]=[]
var floor_cells: Dictionary={}
var rocks: Dictionary={}
var rats: Array=[]
var rat_cells: Array[Vector2i]=[]
var spider_cell=Vector2i.ZERO
var floor_drops: Array=[]
var spider: Node2D
var combat_rng=RandomNumberGenerator.new()
var swing_cooldown=0.0

class CaveObject extends Node2D:
	var cave: Node2D
	var info: Dictionary
	func _draw() -> void:
		cave.paint_object(self,info)

func _ready() -> void:
	level=state.cave_level
	combat_rng.randomize()
	y_sort_enabled=true
	night_tint=CanvasModulate.new()
	night_tint.color=Color("b6c2cb")
	add_child(night_tint)
	generate()
	if level==0:
		var barrel={"kind":"barrel","cell":Vector2i(3,4)}
		object(barrel)
		solid_cells[barrel.cell]="barrel"
		add_site("exit",layout.exit,"Leave cave")
		add_site("cave_barrel",Vector2i(4,4),"Search entrance barrel")
		add_site("cave_pickaxe",Vector2i(4,5),"Take the leaning pickaxe")
		if not state.cave_pickaxe_taken: object({"kind":"pickaxe","cell":Vector2i(4,4)})
	else:
		add_site("stairs_up",layout.entry,"Ascend to level %d" % level)
		object({"kind":"stairs_up","cell":layout.entry})
	if level<2:
		add_site("stairs_down",chambers.back().get_center(),"Descend to level %d" % (level+2))
		object({"kind":"stairs_down","cell":chambers.back().get_center()})
	if level==2 and not state.cave_chrysalis_taken:
		var cell=chambers.back().position+Vector2i(1,1)
		var chrysalis=object({"kind":"chrysalis","cell":cell})
		add_site("chrysalis",cell,"Collect Cave Moth Chrysalis")
		chrysalis.name="Chrysalis"
	for i in range(4):
		var cell=rat_cells[i]
		var rat=object({"kind":"rat","cell":cell,"id":level*100+i,"health":2,"bite":0.0})
		rat.visible=not state.cave_defeated.has(level*100+i)
		rats.append(rat)
	if level==2:
		spider=object({"kind":"spider","cell":spider_cell,"id":299,"health":4,"bite":0.0})
		spider.visible=not state.cave_defeated.has(299)
	crops=Node2D.new()
	add_child(crops)
	player=_prop("player",state.player_position,{"coat":"6f9793","hair":"5c5045","skin":"d0a981","id":"player"})
	var effects=_prop("effects",Vector2.ZERO,{})
	effects.z_index=5

func generate() -> void:
	var rng=RandomNumberGenerator.new()
	var corridors={}
	rng.seed=hash(Vector2i(state.cave_seed,level))
	for i in range(7):
		var row=int(i/3.0)
		var col=i%3 if row%2==0 else 2-i%3
		var room=Rect2i(col*25+rng.randi_range(2,14),row*19+rng.randi_range(1,11),rng.randi_range(2,6),rng.randi_range(2,6))
		if i==0: room=Rect2i(2,2,6,6)
		if i==6: room.size=Vector2i(maxi(3,room.size.x),maxi(3,room.size.y))
		chambers.append(room)
		for y in range(room.position.y,room.end.y):
			for x in range(room.position.x,room.end.x):
				if x in [room.position.x,room.end.x-1] and y in [room.position.y,room.end.y-1]: continue
				floor_cells[Vector2i(x,y)]=true
		if i>0:
			var cell=chambers[rng.randi_range(maxi(0,i-3),i-1)].get_center()
			var target=room.get_center()
			var horizontal_first=rng.randf()<0.5
			var corridor_width=rng.randi_range(1,3)
			var turn_after=rng.randi_range(3,8)
			var steps=0
			while cell!=target:
				var perpendicular=Vector2i.DOWN if horizontal_first else Vector2i.RIGHT
				for lane in range(corridor_width):
					var offset=lane-int(corridor_width/2)
					var passage=cell+perpendicular*offset
					floor_cells[passage]=true
					corridors[passage]=true
				if (horizontal_first and cell.x!=target.x) or cell.y==target.y: cell+=Vector2i(signi(target.x-cell.x),0)
				else: cell+=Vector2i(0,signi(target.y-cell.y))
				steps+=1
				if steps>=turn_after and cell!=target:
					horizontal_first=not horizontal_first
					turn_after+=rng.randi_range(3,8)
			floor_cells[target]=true
	floor_cells[layout.exit]=true
	floor_cells[layout.exit+Vector2i.LEFT]=true
	var occupied={}
	for cell in [layout.entry,layout.exit,layout.exit+Vector2i.UP,layout.exit+Vector2i.LEFT,layout.exit+Vector2i.UP+Vector2i.LEFT,chambers.back().get_center()]: occupied[cell]=true
	if level==2 and not state.cave_chrysalis_taken: occupied[chambers.back().position+Vector2i.ONE]=true
	var mob_candidates=[]
	for cell in floor_cells:
		if occupied.has(cell): continue
		if level==0 and cell.distance_to(Vector2i(4,4))<=2.0: continue
		if chambers.any(func(room):return room.has_point(cell)) and floor_cells.has(cell): mob_candidates.append(cell)
	if level==2:
		var spider_candidates=mob_candidates.filter(func(cell):return chambers.back().has_point(cell))
		spider_candidates.sort_custom(func(a,b):return a.distance_squared_to(chambers.back().get_center())<b.distance_squared_to(chambers.back().get_center()))
		spider_cell=spider_candidates.front()
		occupied[spider_cell]=true
		mob_candidates.erase(spider_cell)
	for index in range(mob_candidates.size()-1,0,-1):
		var other=rng.randi_range(0,index)
		var cell=mob_candidates[index]
		mob_candidates[index]=mob_candidates[other]
		mob_candidates[other]=cell
	for index in range(mini(4,mob_candidates.size())):
		rat_cells.append(mob_candidates[index])
		occupied[mob_candidates[index]]=true
	for y in range(ROOM_CELLS.y):
		for x in range(ROOM_CELLS.x):
			var cell=Vector2i(x,y)
			if not floor_cells.has(cell): solid_cells[cell]="wall"
	# Resource rocks cluster in wider floor areas while leaving a connected route through each level.
	var candidates=[]
	for cell in floor_cells:
		if cell in [Vector2i(3,4),Vector2i(4,4),Vector2i(3,5),Vector2i(4,5),layout.entry,layout.exit,layout.exit+Vector2i.UP,layout.exit+Vector2i.LEFT,layout.exit+Vector2i.UP+Vector2i.LEFT,chambers.back().position+Vector2i.ONE] or occupied.has(cell): continue
		if chambers.any(func(room):return room.get_center()==cell): continue
		var neighbors=0
		for step in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
			if floor_cells.has(cell+step): neighbors+=1
		if neighbors>=1: candidates.append(cell)
	var clusters=[]
	for _index in range(4):
		if not candidates.is_empty(): clusters.append(candidates[rng.randi_range(0,candidates.size()-1)])
	var weights={}
	for cell in candidates:
		var nearest_cluster=INF
		for cluster in clusters: nearest_cluster=minf(nearest_cluster,Vector2(cell).distance_to(cluster))
		weights[cell]=nearest_cluster*0.45+rng.randf_range(0,6)
	candidates.sort_custom(func(a,b):return weights[a]<weights[b])
	var deposits=[]
	var amount=mini(candidates.size(),roundi(floor_cells.size()*0.17))
	for cell in candidates:
		deposits.append(cell)
		if not floor_connected_without(deposits): deposits.pop_back(); continue
		if deposits.size()>=amount: break
	var resource_order=[]
	var copper_count=maxi(6,roundi(deposits.size()*0.1))
	var coal_count=maxi(3,roundi(deposits.size()*0.05))
	for i in range(deposits.size()): resource_order.append("copper" if i<copper_count else "coal" if i<copper_count+coal_count else "stones")
	for i in range(resource_order.size()-1,0,-1):
		var other=rng.randi_range(0,i)
		var resource=resource_order[i]
		resource_order[i]=resource_order[other]
		resource_order[other]=resource
	for i in range(deposits.size()):
		var id=str(level*10000+i)
		if state.cave_broken.has(id): continue
		var info={"kind":"rock","id":id,"cell":deposits[i],"ore":resource_order[i]=="copper","resource":resource_order[i],"hits":1 if resource_order[i]=="stones" else 2}
		info.node=object(info)
		rocks[id]=info
		solid_cells[info.cell]="rock"

func floor_connected_without(rocks_on_floor: Array) -> bool:
	var blocked_cells={}
	for cell in rocks_on_floor: blocked_cells[cell]=true
	var reached={layout.entry:true}
	var queue=[layout.entry]
	var cursor=0
	while cursor<queue.size():
		var cell: Vector2i=queue[cursor]
		cursor+=1
		for step in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
			var next=cell+step
			if not floor_cells.has(next) or blocked_cells.has(next) or reached.has(next): continue
			reached[next]=true
			queue.append(next)
	return reached.size()==floor_cells.size()-blocked_cells.size()

func object(info: Dictionary) -> Node2D:
	var prop=CaveObject.new()
	prop.cave=self
	prop.info=info
	prop.position=Grid.center(info.cell)
	add_child(prop)
	return prop

func add_site(id: String,cell: Vector2i,label: String) -> void:
	var p=Grid.center(cell)
	sites.append({"id":id,"cell":cell,"x":p.x,"y":p.y,"label":label})

func entry_position() -> Vector2: return Grid.center(layout.entry)
func room_name() -> String: return "Copper caverns · level %d" % (level+1)
func target_plot() -> int: return -1
func in_water(_p: Vector2) -> bool: return false
func audio_context(_p: Vector2) -> Dictionary:
	return {"environment":"cave","season":state.season_name(),"cave_weight":1.0}
func update_villagers(_dt: float,_snap: bool=false) -> void: pass
func blocked(p: Vector2) -> bool:
	return not floor_cells.has(Grid.world_to_cell(p)) or solid_cells.has(Grid.world_to_cell(p))

func find_nearest() -> Dictionary:
	if state.active_item()=="pickaxe":
		var front=Grid.world_to_cell(state.player_position)+{"up":Vector2i.UP,"down":Vector2i.DOWN,"left":Vector2i.LEFT,"right":Vector2i.RIGHT}[facing]
		for rock in rocks.values():
			if rock.cell==front: return {"id":rock.id,"type":"rock","label":rock_label(rock)}
	var best={}
	var distance=46.0
	for site in sites:
		if site.id=="cave_pickaxe" and state.cave_pickaxe_taken: continue
		if front_cell() not in activation_cells(site): continue
		var d=state.player_position.distance_to(Grid.center(site.cell))
		if d<distance: best=site.duplicate(); best.type="site"; distance=d
	for rock in rocks.values():
		if rock.cell!=front_cell(): continue
		var d=state.player_position.distance_to(Grid.center(rock.cell))
		if d<distance:
			best={"id":rock.id,"type":"rock","label":rock_label(rock)}
			distance=d
	for drop in floor_drops:
		if drop.node==null or not is_instance_valid(drop.node) or drop.cell!=front_cell(): continue
		best={"id":"drop_"+drop.id,"type":"drop","label":"Pick up "+preload("res://items.gd").CATALOG[drop.item].name}
	if state.active_item() in ["rusty_sword","pickaxe","axe","sickle"] and has_attack_target():
		best={"id":"swing","type":"weapon","label":"Swing weapon · 2 energy"}
	nearest=best
	return best

func has_attack_target() -> bool:
	var direction={"up":Vector2i.UP,"down":Vector2i.DOWN,"left":Vector2i.LEFT,"right":Vector2i.RIGHT}[facing]
	var lateral=Vector2i(-direction.y,direction.x)
	var target=Grid.world_to_cell(state.player_position)+direction
	for creature in creatures():
		if not creature.visible: continue
		var cell=Grid.world_to_cell(creature.position)
		if [Grid.world_to_cell(state.player_position),target-lateral,target,target+lateral].has(cell): return true
	return false

func rock_label(rock: Dictionary) -> String:
	return "Break stone · pickaxe" if rock.resource=="stones" else "Mine %s · pickaxe" % rock.resource

func activation_cells(site: Dictionary) -> Array:
	if site.id=="exit": return [layout.exit,layout.exit+Vector2i.UP,layout.exit+Vector2i.LEFT,layout.exit+Vector2i.LEFT+Vector2i.UP]
	if site.id=="cave_barrel": return [Vector2i(3,4)]
	if site.id=="cave_pickaxe": return [Vector2i(4,4)]
	return [site.cell]

func mine_rock(id: String) -> bool:
	if not rocks.has(id) or state.active_item()!="pickaxe" or state.pickaxe<1 or state.energy<4: return false
	var rock=rocks[id]
	if rock.cell!=front_cell(): return false
	if not state.spend_energy(4): return false
	preload("res://tool_motion.gd").start(self,"pickaxe")
	rock.hits-=1
	rock.node.queue_redraw()
	if rock.hits>0: return true
	solid_cells.erase(rock.cell)
	rock.node.queue_free()
	rocks.erase(id)
	add_floor_drop(id,id,rock.resource,rock.cell)
	if rock.resource=="copper": add_floor_drop(id+"_stones",id,"stones",rock.cell)
	return true

func add_floor_drop(drop_id: String,rock_id: String,item: String,cell: Vector2i) -> void:
	var drop={"id":drop_id,"rock_id":rock_id,"item":item,"cell":cell}
	drop.node=object({"kind":"drop","item":item,"cell":cell})
	floor_drops.append(drop)

func collect_drop(id: String) -> bool:
	var source=id.trim_prefix("drop_")
	for drop in floor_drops:
		if drop.id!=source or not state.can_carry(drop.item): continue
		state.set(drop.item,int(state.get(drop.item))+1)
		drop.node.queue_free()
		floor_drops.erase(drop)
		if not floor_drops.any(func(other):return other.rock_id==drop.rock_id) and not state.cave_broken.has(drop.rock_id): state.cave_broken.append(drop.rock_id)
		return true
	return false

func attack() -> bool:
	if swing_cooldown>0 or not super.attack(): return false
	swing_cooldown=0.35
	damage_front_creatures(1)
	return true

func attack_with_tool(id: String) -> bool:
	if swing_cooldown>0 or not super.attack_with_tool(id): return false
	swing_cooldown=0.6
	damage_front_creatures(0.5)
	return true

func damage_front_creatures(amount: float) -> void:
	var direction={"up":Vector2i.UP,"down":Vector2i.DOWN,"left":Vector2i.LEFT,"right":Vector2i.RIGHT}[facing]
	var lateral=Vector2i(-direction.y,direction.x)
	var target=Grid.world_to_cell(state.player_position)+direction
	for rat in creatures():
		var cell=Grid.world_to_cell(rat.position)
		if not rat.visible or not [Grid.world_to_cell(state.player_position),target-lateral,target,target+lateral].has(cell): continue
		damage_creature(rat,amount)

func creatures() -> Array: return rats+([spider] if spider!=null else [])

func damage_creature(creature: Node2D,amount: float) -> void:
	creature.info.health-=amount
	var label=str(int(amount)) if is_equal_approx(amount,roundf(amount)) else "%.2f"%amount
	combat_text("-"+label,creature.position+Vector2(0,30),Color("ffe7a0"))
	creature.modulate=Color("ffc4aa")
	if creature.info.health<=0:
		creature.visible=false
		state.cave_defeated.append(creature.info.id)
		var earned=20 if creature.info.kind=="spider" else 10
		state.experience+=earned
		combat_text("+%dxp" % earned,state.player_position,Color("8aee83"))

func burn_at(point: Vector2,damage: float=2.0) -> bool:
	for creature in creatures():
		if creature.visible and creature.position.distance_to(point)<24:
			damage_creature(creature,damage)
			return true
	return false

func update_enemies(dt: float) -> void:
	swing_cooldown=maxf(0,swing_cooldown-dt)
	for rat in creatures():
		if not rat.visible: continue
		rat.modulate=rat.modulate.lerp(Color.WHITE,minf(1,dt*5))
		rat.info.bite=maxf(0,rat.info.bite-dt)
		var distance=rat.position.distance_to(state.player_position)
		if distance<160 and distance>23:
			var path=_route(Grid.world_to_cell(rat.position),Grid.world_to_cell(state.player_position))
			var target=path[0] if not path.is_empty() else state.player_position
			var step=rat.position.move_toward(target,minf(dt,0.5)*55)
			if not blocked(step): rat.position=step
		if rat.position.distance_to(state.player_position)<=26 and rat.info.bite<=0:
			var damage=minf(4,state.health)
			state.health=maxf(0,state.health-4)
			if damage>0: combat_text("-%d" % int(damage),state.player_position,Color("ff8e7b"))
			if rat.info.kind=="spider" and combat_rng.randf()<0.2: state.apply_poison()
			rat.info.bite=1.0
		rat.queue_redraw()

var exit_night=false
var border_signature=""
func refresh() -> void:
	var signature=state.season_name()+"/"+state.weather_name()
	if signature!=border_signature:
		border_signature=signature
		queue_redraw()
	var night=state.minute<360 or state.minute>=1140
	if night!=exit_night:
		exit_night=night
		queue_redraw()
	player.position=state.player_position.round()
	player.queue_redraw()
	for child in moving_layer.get_children():
		if child is Prop and child.kind=="effects": child.queue_redraw()

func collect_chrysalis() -> bool:
	if state.cave_chrysalis_taken or not state.can_carry("cave_moth_chrysalis"): return false
	state.cave_chrysalis_taken=true
	state.cave_moth_chrysalis+=1
	sites=sites.filter(func(site): return site.id!="chrysalis")
	get_node("Chrysalis").queue_free()
	return true

func _draw() -> void:
	if Art.option==2:
		draw_rect(Rect2(-400,-400,ROOM_SIZE.x+800,ROOM_SIZE.y+800),Color("20282e"))
		for cell in floor_cells: Art.tile(self,"cave"+str(posmod(cell.x+cell.y,4)),cell)
		var walls={}
		for cell in solid_cells:
			if solid_cells[cell]=="wall": walls[cell]=true
		for cell in walls:
			if Borders.NEIGHBORS.any(func(pair):return floor_cells.has(cell+pair[0])):
				Art.border(self,"cave",walls,cell,state,state.cave_seed)
		if level==0: Art.sprite(self,"cave_exit_night" if state.minute<360 or state.minute>=1140 else "cave_exit_day",Grid.origin(layout.exit+Vector2i(-1,-1)),Vector2(64,64))
		return
	r(self,-400,-400,ROOM_SIZE.x+800,ROOM_SIZE.y+800,"20282e")
	for y in range(ROOM_CELLS.y):
		for x in range(ROOM_CELLS.x):
			var cell=Vector2i(x,y)
			var p=Grid.origin(cell)
			if floor_cells.has(cell):
				r(self,p.x,p.y,32,32,"555d60" if (x*7+y*13)%3 else "5c6466")
				r(self,p.x+5,p.y+9,7,1,"6b7372")
				r(self,p.x+21,p.y+23,3,2,"444f54")
			elif floor_cells.has(cell+Vector2i.DOWN):
				r(self,p.x,p.y-14,32,46,"333e47")
				r(self,p.x+1,p.y-14,30,8,"737b7a")
				r(self,p.x+3,p.y-4,26,2,"47535b")
				r(self,p.x,p.y+29,32,3,"26343c")
	var exit=Grid.origin(layout.exit)
	r(self,exit.x,exit.y,32,32,"8d998e")
	for i in range(4): r(self,exit.x+3,exit.y+i*7,26,2,"c0bca0")

func paint_effects(c: CanvasItem) -> void:
	if Art.option==2:
		Art.particles(self,c)
		if swing_cooldown>.15: Art.sprite(c,"spark"+str(int(elapsed*30)%6),state.player_position-Vector2(8,25))
		return
	for p in particles:
		var color=Color(p.color)
		color.a=minf(1,p.life)
		c.draw_rect(Rect2(p.pos,Vector2(3,3)),color)
	if swing_cooldown>0.15:
		var direction={"up":Vector2.UP,"down":Vector2.DOWN,"left":Vector2.LEFT,"right":Vector2.RIGHT}[facing]
		var points=PackedVector2Array()
		for i in range(7):
			var angle=direction.angle()-0.8+i*1.6/6
			points.append(state.player_position+Vector2(cos(angle),sin(angle))*38)
		c.draw_polyline(points,Color("ebd7a4aa"),2)

func paint_object(c: CanvasItem,info: Dictionary) -> void:
	if info.kind=="drop":
		oval(c,0,7,12,5,"1c282b99")
		var sprite="item_"+info.item
		if Art.catalog.has(sprite): Art.sprite(c,sprite,Vector2(-12,-22),Vector2(24,24))
		else:
			var color="bd916c" if info.item=="copper" else "484e50" if info.item=="coal" else "a2a39a"
			poly(c,[Vector2(-9,1),Vector2(-7,-12),Vector2(3,-18),Vector2(11,-8),Vector2(7,3)],color)
		return
	if info.kind in ["stairs_up","stairs_down"]:
		var id="cave_"+info.kind
		Art.sprite(c,id if Art.catalog.has(id) else "tile_cave0",Vector2(-16,-16),Vector2(32,32))
		return
	if info.get("resource","")=="coal" and Art.catalog.has("cave_coal"):
		Art.sprite(c,"cave_coal",Vector2(-16,-16),Vector2(32,32))
		return
	if info.kind=="pickaxe":
		if not state.cave_pickaxe_taken: Art.sprite(c,"item_pickaxe",Vector2(-12,-16),Vector2(24,24))
		return
	if Art.option==2 or info.kind=="spider":
		var id="copper" if info.kind=="rock" and info.ore else "rock" if info.kind=="rock" else info.kind+str(int(elapsed*6)%3) if info.kind in ["rat","spider"] else info.kind
		var size=Art.sprite_size(id)
		Art.sprite(c,id,Vector2(-size.x/2,-size.y+8))
		return
	match info.kind:
		"rock":
			oval(c,0,8,16,8,"28353b88")
			poly(c,[Vector2(-14,4),Vector2(-11,-12),Vector2(0,-20),Vector2(14,-9),Vector2(15,7),Vector2(0,12)],"727d80")
			poly(c,[Vector2(-11,-12),Vector2(0,-20),Vector2(14,-9),Vector2(1,-5)],"9ba29b")
			poly(c,[Vector2(1,-5),Vector2(14,-9),Vector2(15,7),Vector2(0,12)],"55636c")
			if info.ore:
				for p in [Vector2(-7,-9),Vector2(2,2),Vector2(8,-4)]:
					r(c,p.x,p.y,5,4,"bf845b")
					r(c,p.x,p.y,3,1,"edba79")
		"barrel":
			oval(c,0,8,14,7,"26333c88")
			r(c,-11,-18,22,27,"92714b")
			for x in [-8,-2,5]: r(c,x,-16,2,23,"6b513a")
			oval(c,0,-18,11,5,"b39362")
			for y in [-12,3]: r(c,-12,y,24,3,"66777b")
		"rat":
			oval(c,0,4,13,5,"23343a77")
			c.draw_polyline(PackedVector2Array([Vector2(-6,2),Vector2(-16,4),Vector2(-20,-1)]),Color("c29292"),2)
			oval(c,0,-2,10,7,"8e8d88")
			oval(c,7,-3,6,5,"b4a99c")
			oval(c,6,-10,4,4,"bda5a0")
			oval(c,6,-10,2,2,"d5b3ad")
			r(c,11,-5,2,2,"231e22")
			r(c,13,-1,3,2,"d7a3a1")
			for x in [-5,5]: r(c,x,4,4,2,"c2a6a0")
		"chrysalis":
			c.draw_line(Vector2(0,-27),Vector2(0,-14),Color("8faaa4"),1)
			oval(c,0,-6,5,11,"a8c2b6")
			for y in [-13,-8,-3,2]: r(c,-3,y,6,1,"628a91")
