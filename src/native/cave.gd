extends "res://world.gd"

var building: Dictionary
var outdoors: Node2D
var ROOM_CELLS=Vector2i(43,28)
var ROOM_SIZE=Vector2(1376,896)
var layout={"entry":Vector2i(5,4),"exit":Vector2i(5,2)}
var chambers: Array[Rect2i]=[]
var floor_cells: Dictionary={}
var rocks: Dictionary={}
var rats: Array=[]
var swing_cooldown=0.0

class CaveObject extends Node2D:
	var cave: Node2D
	var info: Dictionary
	func _draw() -> void:
		cave.paint_object(self,info)

func _ready() -> void:
	y_sort_enabled=true
	night_tint=CanvasModulate.new()
	night_tint.color=Color("b6c2cb")
	add_child(night_tint)
	generate()
	var barrel={"kind":"barrel","cell":Vector2i(3,4)}
	object(barrel)
	solid_cells[barrel.cell]="barrel"
	add_site("exit",layout.exit,"Leave cave")
	add_site("cave_barrel",Vector2i(4,4),"Search entrance barrel")
	if not state.cave_chrysalis_taken:
		var cell=chambers.back().position+Vector2i(1,1)
		var chrysalis=object({"kind":"chrysalis","cell":cell})
		add_site("chrysalis",cell,"Collect Cave Moth Chrysalis")
		chrysalis.name="Chrysalis"
	for i in range(2):
		var cell=chambers[2+i*2].get_center()+Vector2i(0,1)
		var rat=object({"kind":"rat","cell":cell,"id":i,"health":2,"bite":0.0})
		rat.visible=not state.cave_defeated.has(i)
		rats.append(rat)
	crops=Node2D.new()
	add_child(crops)
	player=_prop("player",state.player_position,{"coat":"6f9793","hair":"5c5045","skin":"d0a981","id":"player"})
	var effects=_prop("effects",Vector2.ZERO,{})
	effects.z_index=5

func generate() -> void:
	var rng=RandomNumberGenerator.new()
	var corridors={}
	rng.seed=state.cave_seed
	for i in range(6):
		var col=i if i<3 else 5-i
		var row=0 if i<3 else 1
		var room=Rect2i(col*14+rng.randi_range(2,3),row*13+rng.randi_range(2,3),rng.randi_range(7,10),rng.randi_range(7,10))
		if i==0: room=Rect2i(2,2,8,8)
		chambers.append(room)
		for y in range(room.position.y,room.end.y):
			for x in range(room.position.x,room.end.x): floor_cells[Vector2i(x,y)]=true
		if i>0:
			var cell=chambers[i-1].get_center()
			var target=room.get_center()
			while cell!=target:
				floor_cells[cell]=true
				corridors[cell]=true
				cell+=Vector2i(signi(target.x-cell.x),0) if cell.x!=target.x else Vector2i(0,signi(target.y-cell.y))
			floor_cells[target]=true
	for y in range(ROOM_CELLS.y):
		for x in range(ROOM_CELLS.x):
			var cell=Vector2i(x,y)
			if not floor_cells.has(cell): solid_cells[cell]="wall"
	# Edge deposits leave room centers and connecting corridors clear.
	for i in range(chambers.size()):
		var room=chambers[i]
		for j in range(3):
			var id=str(i*3+j)
			if state.cave_broken.has(id): continue
			var cell=Vector2i(room.position.x+1+j*2,room.end.y-2)
			if corridors.has(cell): continue
			var info={"kind":"rock","id":id,"cell":cell,"ore":j!=1}
			info.node=object(info)
			rocks[id]=info
			solid_cells[cell]="rock"

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
func room_name() -> String: return "Southeast copper cave"
func target_plot() -> int: return -1
func in_water(_p: Vector2) -> bool: return false
func audio_context(_p: Vector2) -> Dictionary:
	return {"environment":"cave","season":state.season_name(),"cave_weight":1.0}
func update_villagers(_dt: float,_snap: bool=false) -> void: pass
func blocked(p: Vector2) -> bool:
	return not floor_cells.has(Grid.world_to_cell(p)) or solid_cells.has(Grid.world_to_cell(p))

func find_nearest() -> Dictionary:
	var best={}
	var distance=46.0
	for site in sites:
		var d=state.player_position.distance_to(Grid.center(site.cell))
		if d<distance: best=site.duplicate(); best.type="site"; distance=d
	for rock in rocks.values():
		var d=state.player_position.distance_to(Grid.center(rock.cell))
		if d<distance:
			best={"id":rock.id,"type":"rock","label":"Mine copper · pickaxe" if rock.ore else "Break rock · pickaxe"}
			distance=d
	if state.active_item()=="rusty_sword" and best.get("type")!="site":
		best={"id":"swing","type":"weapon","label":"Swing sword · 2 energy"}
	nearest=best
	return best

func mine_rock(id: String) -> bool:
	if not rocks.has(id) or state.active_item()!="pickaxe" or state.pickaxe<1 or state.energy<5: return false
	var rock=rocks[id]
	if state.player_position.distance_to(Grid.center(rock.cell))>46: return false
	var resource="copper" if rock.ore else "stones"
	if not state.mine(resource): return false
	state.cave_broken.append(id)
	solid_cells.erase(rock.cell)
	rock.node.queue_free()
	rocks.erase(id)
	return true

func attack() -> bool:
	if state.active_item()!="rusty_sword" or state.rusty_sword<1 or state.energy<2 or swing_cooldown>0: return false
	state.energy-=2
	swing_cooldown=0.35
	var direction={"up":Vector2.UP,"down":Vector2.DOWN,"left":Vector2.LEFT,"right":Vector2.RIGHT}[facing]
	for rat in rats:
		var offset=rat.position-state.player_position
		if not rat.visible or offset.length()>54 or offset.normalized().dot(direction)<0.25: continue
		rat.info.health-=1
		rat.modulate=Color("ffc4aa")
		if rat.info.health<=0:
			rat.visible=false
			state.cave_defeated.append(rat.info.id)
		break
	return true

func update_enemies(dt: float) -> void:
	swing_cooldown=maxf(0,swing_cooldown-dt)
	for rat in rats:
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
			state.health=maxf(0,state.health-4)
			rat.info.bite=1.0
		rat.queue_redraw()

func refresh() -> void:
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
		for cell in solid_cells:
			if solid_cells[cell]=="wall" and floor_cells.has(cell+Vector2i.DOWN): Art.tile(self,"cliff8",cell)
		Art.tile(self,"jetty",layout.exit)
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
	if Art.option==2:
		var id="copper" if info.kind=="rock" and info.ore else "rock" if info.kind=="rock" else "rat"+str(int(elapsed*6)%3) if info.kind=="rat" else info.kind
		var size=Art.region(id).size
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
