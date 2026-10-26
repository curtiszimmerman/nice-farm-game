extends RefCounted
const Grid=preload("res://grid.gd")

static func night_id(day: int,minute: float) -> int:
	return day if minute>=1140 else day-1

static func flash_alpha(age: float) -> float:
	if age<0 or age>=0.5: return 0
	return clampf(age/0.07,0,1)*pow(1.0-age/0.5,1.2)

static func setup(world: Node2D) -> void:
	if not world.ambient.is_empty(): return
	var rng=RandomNumberGenerator.new()
	rng.seed=world.state.world_seed^71953
	var water=[]
	for cell in world.water_cells:
		if rng.randf()<0.12: water.append({"position":Grid.center(cell)+Vector2(rng.randf_range(-8,8),rng.randf_range(-8,8)),"phase":rng.randf_range(0,TAU),"speed":rng.randf_range(0.35,0.65)})
	var birds=[]
	for i in range(3): birds.append({"position":world.state.player_position+Vector2(rng.randf_range(-500,500),rng.randf_range(-300,250)),"speed":rng.randf_range(135,195),"phase":rng.randf_range(0,TAU)})
	world.ambient={"rng":rng,"water":water,"birds":birds,"night":-100,"flashes":[],"last":world.elapsed}

static func update(world: Node2D) -> void:
	setup(world)
	var data=world.ambient
	var dt=clampf(world.elapsed-data.last,0,0.5)
	data.last=world.elapsed
	for bird in data.birds:
		bird.position+=Vector2(bird.speed,-bird.speed*0.12)*dt
		if bird.position.x>world.state.player_position.x+650 or bird.position.distance_to(world.state.player_position)>1800:
			bird.position=world.state.player_position+Vector2(-650,data.rng.randf_range(-300,250))
	var night=night_id(world.state.day,world.state.minute)
	if data.night!=night:
		data.night=night
		data.flashes.clear()
		var rng=RandomNumberGenerator.new()
		rng.seed=hash(Vector2i(world.state.world_seed,night))
		for i in range(3):
			var cell=Vector2i(-27,52)
			for attempt in range(100):
				cell=Vector2i(rng.randi_range(-28,-24),rng.randi_range(48,57))
				if world.Coast.is_ocean(cell,world.state.world_seed) and not world.Coast.dock_cells().has(cell): break
			data.flashes.append({"position":Grid.center(cell)+Vector2(rng.randf_range(-10,10),rng.randf_range(-10,10)),"start":world.elapsed+rng.randf_range(5,10),"rng":rng})
	for flash in data.flashes:
		while world.elapsed>=flash.start+0.5: flash.start+=flash.rng.randf_range(5,10)

static func draw(world: Node2D,canvas: CanvasItem) -> void:
	if world.ambient.is_empty(): return
	if world.Art.catalog.has_all(["bee0","bee1"]) and world.state.minute>=360 and world.state.minute<1140 and world.state.season_name()!="winter":
		for hive in [Vector2i(58,56),Vector2i(60,56)]:
			for i in range(3):
				var time=world.elapsed*(0.8+i*0.17)+i*2
				var p=Grid.center(hive)+Vector2(sin(time)*30,cos(time*1.7)*12-25)
				world.Art.sprite(canvas,"bee"+str(int(world.elapsed*10+i)%2),p,Vector2(10,10))
	var night=world.state.minute<360 or world.state.minute>=1140
	for wave in world.ambient.water:
		var phase=world.elapsed*wave.speed+wave.phase
		var opacity=0.06+0.07*(sin(phase)+1)*0.5
		world.Art.sprite(canvas,"ripple",wave.position+Vector2(sin(phase)*5,cos(phase)*1.5),Vector2(18,4),Color(1,1,1,opacity))
	if night:
		for flash in world.ambient.flashes:
			var age=world.elapsed-flash.start
			var alpha=flash_alpha(age)
			if alpha<=0: continue
			canvas.draw_set_transform(flash.position,age/0.5*TAU*2)
			var tint=world.night_tint.color
			world.Art.sprite(canvas,"fish_glint",Vector2(-16,-16),Vector2(32,32),Color(1/tint.r,1/tint.g,1/tint.b,alpha))
			canvas.draw_set_transform(Vector2.ZERO)
	else:
		for bird in world.ambient.birds:
			world.Art.sprite(canvas,"bird"+str(posmod(int(world.elapsed*12+bird.phase),3)),bird.position,Vector2(22,20))
