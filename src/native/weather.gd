extends Node2D

const Art=preload("res://art.gd")
const Grid=preload("res://grid.gd")
var world: Node2D
var sky: Node2D
var shadow_signature=""
var sky_signature=""
var lightning_frames=0

class SkyOverlay extends Node2D:
	var weather: Node2D
	func _draw() -> void: weather.paint_sky(self)

static func for_day(seed_value: int,day: int) -> String:
	if day==1: return "sunny"
	var rng=RandomNumberGenerator.new()
	rng.seed=seed_value+day*7919
	var roll=rng.randf()
	var rainfall=[0.3,0.2,0.1,0.2][posmod(int((day-1)/28),4)]
	return "rainy" if roll<rainfall else "partly_cloudy" if roll<rainfall+0.3 else "sunny"

static func thundersnow(seed_value: int,day: int) -> bool:
	if posmod(int((day-1)/28),4)!=3 or for_day(seed_value,day)!="rainy": return false
	var rng=RandomNumberGenerator.new()
	rng.seed=hash("winter lightning:%d:%d"%[seed_value,day])
	return rng.randf()<0.1

func _ready() -> void:
	sky=SkyOverlay.new()
	sky.weather=self
	sky.z_index=8
	add_child(sky)
	RenderingServer.frame_post_draw.connect(finish_frame)

func strike() -> void:
	lightning_frames=2
	sky.queue_redraw()

func finish_frame() -> void:
	if lightning_frames<=0: return
	lightning_frames-=1
	sky.queue_redraw()

func daylight() -> float:
	return smoothstep(330.0,420.0,world.state.minute)*(1-smoothstep(1110.0,1200.0,world.state.minute))

func refresh() -> void:
	var mode=world.state.weather_name()
	if mode!="rainy": lightning_frames=0
	var next="%s/%d" % [mode,int(world.state.minute/10)]
	if next!=shadow_signature:
		shadow_signature=next
		queue_redraw()
	next="%s/%d/%s" % [mode,int(world.elapsed*12),world.state.player_position.round()]
	if next!=sky_signature:
		sky_signature=next
		sky.queue_redraw()

func cloud_positions(time: float) -> PackedVector2Array:
	var positions=PackedVector2Array()
	for y in range(9):
		for x in range(10):
			positions.append(Vector2(-1000+fposmod(x*520+time*12+y*173,5200),y*360-200+sin(x*3+y)*70))
	return positions

func rain_positions(time: float) -> PackedVector2Array:
	var positions=PackedVector2Array()
	for i in range(110):
		positions.append(world.state.player_position-Vector2(410,280)+Vector2(fposmod(i*127-time*25,820),fposmod(i*71+time*(150+i%4*20),560)))
	return positions

func snow_positions(time: float) -> PackedVector2Array:
	var positions=PackedVector2Array()
	for i in range(110):
		positions.append(world.state.player_position-Vector2(410,280)+Vector2(fposmod(i*127+sin(time*0.7+i)*12,820),fposmod(i*71+time*(22+i%4*4),560)))
	return positions

func _draw() -> void:
	if world.state.weather_name()!="sunny" or daylight()<=0: return
	var shade=Color(0.12,0.16,0.24,0.26*daylight())
	for tree in world.trees: Art.sprite(self,"shadow_tree",tree.pos-Vector2(2,22),Vector2(64,40),shade)
	for cell in world.fence_cells+world.yard_fences.keys(): Art.sprite(self,"shadow_fence",Grid.center(cell)-Vector2(16,4),Vector2(40,20),shade)
	for cell in world.LAMP_CELLS: Art.sprite(self,"shadow_lamp",Grid.center(cell)-Vector2(2,38),Vector2(32,48),shade)

func paint_sky(canvas: CanvasItem) -> void:
	var mode=world.state.weather_name()
	if mode=="partly_cloudy":
		for point in cloud_positions(world.elapsed):
			if point.distance_to(world.state.player_position)<850:
				Art.sprite(canvas,"cloud_shadow",point,Vector2(520,260),Color(0.12,0.16,0.24,0.42*daylight()))
	elif mode=="rainy":
		var snow=world.state.season_name()=="winter"
		for point in snow_positions(world.elapsed) if snow else rain_positions(world.elapsed):
			if snow:
				canvas.draw_rect(Rect2(point,Vector2(2,2)),Color(0.9,0.94,1,0.72))
			else: Art.sprite(canvas,"rain_streak",point,Vector2(3,11),Color(0.75,0.85,0.94,0.42))
		for i in range(20):
			if snow: break
			var phase=fposmod(world.elapsed*2+i*0.17,1)
			if phase<0.3:
				var point=world.state.player_position+Vector2((i*97)%740-370,(i*137)%430-215)
				Art.sprite(canvas,"rain_splash",point,Vector2(12,5),Color(0.7,0.8,0.9,(0.3-phase)*1.5))
		if lightning_frames>0:
			var tint=world.night_tint.color
			canvas.draw_rect(Rect2(world.state.player_position-Vector2(800,600),Vector2(1600,1200)),Color(1/tint.r,1/tint.g,1/tint.b,0.75))
