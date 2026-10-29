extends CanvasLayer

const Art=preload("res://art.gd")

const DURATION=28.0
const CAPTION_TIMES=[0.0,3.0,4.5,9.0,12.5,18.0,21.0,24.0]
var caption_step=0
var stars: Array=[]
var game: Node2D
var elapsed=0.0
var animation_time=0.0
var impact_played=false
var explosion_played=false
var battle_clock=0.0
var battle_started=false
var shot_times: Array=[]
var finished=false
var view: Control

class View extends Control:
	var opening: CanvasLayer
	func _draw() -> void: opening.paint(self)

func _ready() -> void:
	layer=20
	view=View.new()
	view.opening=self
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(view)
	game.ui.root.visible=false
	game.sound.set_cinematic(true)
	var rng=RandomNumberGenerator.new()
	rng.randomize()
	for i in range(120): stars.append({"pos":Vector2(rng.randf_range(0,1280),rng.randf_range(0,570)),"speed":rng.randf_range(3,11),"size":rng.randi_range(1,2),"alpha":rng.randf_range(0.35,1)})
	rng.seed=game.state.world_seed
	for side in [false,true]:
		var clusters=[3.4,6.4,9.7,12.9,15.8] if not side else [9.25,12.0,15.0]
		for cluster in clusters:
			var count=rng.randi_range(1,3)
			for index in range(count):
				var launch=cluster+index*rng.randf_range(0.18,0.34)
				if launch<17.1: shot_times.append({"friendly":side,"launch":launch,"index":shot_times.size()})
	shot_times.sort_custom(func(a,b):return a.launch<b.launch)

func advance() -> void:
	if finished or caption_step>=CAPTION_TIMES.size()-1: return
	caption_step+=1
	elapsed=CAPTION_TIMES[caption_step]
	view.queue_redraw()

func shots_at(time: float) -> Array:
	var shots=[]
	for shot in shot_times:
		var age=time-shot.launch
		if age>=0 and age<1.15: shots.append({"friendly":shot.friendly,"progress":minf(1,age/0.82),"impact":maxf(0,age-0.82),"hit":age>=0.82,"index":shot.index})
	return shots

func scene_at(time: float) -> String:
	if time>=25: return "aftermath"
	if time>=24: return "impact"
	if (time>=4.5 and time<9) or (time>=12.5 and time<18) or time>=21: return "bridge"
	return "space"

func battle_at(time: float) -> Dictionary:
	return {"enemy_fire":time>=3 and time<18,"return_fire":time>=9 and time<18,"destroyed":time>=18}

func battle_events(from: float,to: float) -> Array:
	var events=[]
	for cycle in range(maxi(0,floori(from/15)),floori(to/15)+1):
		for shot in shot_times:
			for sound in ["laser","laser_hit"]:
				var time=cycle*15+shot.launch-3.4+(0.82 if sound=="laser_hit" else 0.0)
				if time>from and time<=to: events.append({"time":time,"sound":sound,"friendly":shot.friendly})
	events.sort_custom(func(a,b):return a.time<b.time)
	return events

func caption_at(time: float) -> String:
	if time>=21: return "CAPTAIN: All hands! Brace for impact!"
	if time>=18: return "The attacker is destroyed. The crew's damaged ship falls toward the planet."
	if time>=12.5: return "VALE: We've taken too much damage. I'm trying to land on that nearby planet!"
	if time>=9: return "CAPTAIN: Return fire! Target their weapons and keep evading!"
	if time>=4.5: return "CAPTAIN: Incoming fire! Evasive pattern delta. Keep us moving!"
	if time>=3: return "Weapons fire cuts across the ship's course."
	return "A quiet course through unfamiliar space."

func _process(dt: float) -> void:
	if finished: return
	animation_time+=dt
	if caption_step<CAPTION_TIMES.size()-1: elapsed=minf(elapsed+dt,CAPTION_TIMES[caption_step+1]-0.001)
	else: elapsed+=dt
	if battle_at(elapsed).enemy_fire:
		var previous=battle_clock if battle_started else -0.001
		battle_started=true
		battle_clock+=dt
		for event in battle_events(previous,battle_clock):
			if event.friendly and not battle_at(elapsed).return_fire: continue
			game.sound.play_battle(event.sound,event.friendly)
	if elapsed>=18 and not explosion_played:
		explosion_played=true
		game.sound.play_battle("explosion")
	if elapsed>=24 and not impact_played:
		impact_played=true
		game.sound.crash.play()
	view.queue_redraw()
	if elapsed>=DURATION: finish()

func finish() -> void:
	if finished: return
	finished=true
	game.ui.root.visible=true
	game.sound.set_cinematic(false)
	game.finish_intro()
	queue_free()

func ship(c: CanvasItem,p: Vector2,scale_value: float,hostile: bool=false) -> void:
	var w=game.outdoors
	c.draw_set_transform(p,0,Vector2.ONE*scale_value)
	if hostile:
		w.poly(c,[Vector2(-85,-25),Vector2(45,-13),Vector2(75,0),Vector2(45,13),Vector2(-85,25),Vector2(-65,0)],"433f50")
		w.r(c,-48,-4,96,8,"a86664")
	else:
		w.poly(c,[Vector2(-80,-27),Vector2(-10,-20),Vector2(72,0),Vector2(-10,20),Vector2(-80,27),Vector2(-48,0)],"a2b7b9")
		w.poly(c,[Vector2(-70,-20),Vector2(-10,-15),Vector2(50,0),Vector2(-20,3)],"d0d9cd")
		for y in [-33,25]:
			w.r(c,-84,y,63,8,"546c81")
			w.r(c,-87,y+1,8,6,"9bd6e1")
		w.r(c,4,-4,19,6,"5c8795")
		for x in range(-45,0,9): w.r(c,x,-5,3,2,"e8d39e")
	c.draw_set_transform(Vector2.ZERO)

func paint(c: CanvasItem) -> void:
	if Art.option==2: paint_pixels(c); return
	var w=game.outdoors
	var scene=scene_at(elapsed)
	if scene=="aftermath":
		c.draw_rect(Rect2(0,0,1280,720),Color(1,1,1,1-smoothstep(25,28,elapsed)))
		return
	w.r(c,0,0,1280,720,"090f20")
	paint_stars(c)
	if scene=="space":
		var center=Vector2(650+sin(animation_time*0.7)*25,340+sin(animation_time)*12)
		ship(c,center,2.2)
		if elapsed>=3 and elapsed<18:
			ship(c,Vector2(160,170),1.25,true)
			paint_shots(c,center,Vector2(160,170))
		if elapsed>=18 and elapsed<20: Art.sprite(c,"explosion"+str(clampi(int((elapsed-18)*3),0,5)),Vector2(64,74),Vector2(192,192))
		if elapsed>=18:
			w.oval(c,1130,620,350,310,"3e7278")
			w.oval(c,1100,600,265,240,"799a76")
	else:
		# The bridge is intact before impact, with the captain seated at its center.
		w.poly(c,[Vector2(80,520),Vector2(250,190),Vector2(1030,190),Vector2(1200,520)],"728187")
		w.r(c,130,110,1020,170,"a2ada9")
		w.r(c,165,125,950,132,"192f48")
		for i in range(30): w.r(c,175+posmod(i*137,920),135+posmod(i*59,110),3,2,"ced6c8")
		for x in [395,650,900]: w.r(c,x,123,7,137,"a2ada9")
		w.poly(c,[Vector2(160,525),Vector2(250,340),Vector2(450,340),Vector2(500,525)],"354d5b")
		w.poly(c,[Vector2(780,525),Vector2(830,340),Vector2(1030,340),Vector2(1120,525)],"354d5b")
		for x in [285,865]:
			w.r(c,x,355,130,60,"172e43")
			for y in range(365,407,8): w.r(c,x+10,y,100-(y%3)*15,2,"a7c9bf")
		w.r(c,591,351,98,126,"32434e")
		w.r(c,601,361,78,96,"6b8d8d")
		w.r(c,626,330,28,31,"d0a981")
		w.r(c,625,328,30,9,"5c5045")
		for x in [632,645]: w.r(c,x,344,4,3,"344648")
		w.r(c,620,362,40,38,"6f9793")
		w.r(c,625,364,5,30,"8bb5a8")
		for x in [610,660]:
			w.r(c,x,368,10,27,"6f9793")
			w.r(c,x,395,10,7,"d0a981")
		for x in [623,645]:
			w.r(c,x,400,17,14,"344a4b")
			w.r(c,x+2,414,13,21,"344a4b")
			w.r(c,x,434,19,7,"4a4b3e")
		w.r(c,583,408,20,44,"9faba3")
		w.r(c,677,408,20,44,"9faba3")
		w.r(c,601,447,78,25,"4d666d")
		w.r(c,616,442,50,5,"8d9c98")
		c.draw_set_transform(Vector2(410,465),0,Vector2.ONE*2)
		w.paint_person(c,{"id":"vale","coat":"8b9baf","hair":"b5a68e","skin":"a97959"},0,"right")
		c.draw_set_transform(Vector2.ZERO)
		if elapsed>=12.5:
			for x in [110,1140]: w.r(c,x,285,20,45,"b67972" if sin(elapsed*5)>0 else "614c52")
			c.draw_rect(Rect2(0,0,1280,620),Color(0.8,0.3,0.2,0.05+maxf(0,sin(elapsed*8))*0.06))
	w.r(c,0,0,1280,75,"090f20")
	w.r(c,0,572,1280,148,"090f20")
	var caption=caption_at(elapsed)
	c.draw_multiline_string(ThemeDB.fallback_font,Vector2(115,626),caption,HORIZONTAL_ALIGNMENT_CENTER,1050,22,-1,Color("eee6cf"))
	paint_continue_hint(c)
	if whiteout_alpha()>0: c.draw_rect(Rect2(0,0,1280,720),Color(1,1,1,whiteout_alpha()))

func paint_pixels(c: CanvasItem) -> void:
	var scene=scene_at(elapsed)
	if scene=="aftermath":
		c.draw_rect(Rect2(0,0,1280,720),Color(1,1,1,1-smoothstep(25,28,elapsed)))
		return
	c.draw_rect(Rect2(0,0,1280,720),Color("090f20"))
	if scene=="space":
		if elapsed>=18: Art.sprite(c,"planet",Vector2(970,390),Vector2(540,540))
		paint_stars(c)
		var center=Vector2(690+sin(animation_time*.7)*25,335+sin(animation_time)*12)
		Art.sprite(c,"ship_crew",center-Vector2(192,96),Vector2(384,192))
		var enemy=Vector2(170,170)
		var battle=battle_at(elapsed)
		if battle.enemy_fire:
			Art.sprite(c,"ship_enemy",enemy-Vector2(96,48))
		paint_shots(c,center,enemy)
		if battle.destroyed and elapsed<20:
			Art.sprite(c,"explosion"+str(clampi(int((elapsed-18)*3),0,5)),enemy-Vector2(96,96),Vector2(192,192))
		if elapsed>=18:
			Art.sprite(c,"explosion"+str(int(animation_time*8)%6),center+Vector2(-150,10),Vector2(48,48))
	else:
		Art.sprite(c,"bridge",Vector2.ZERO,Vector2(1280,620))
		paint_bridge_details(c)
	c.draw_rect(Rect2(0,0,1280,75),Color("090f20"))
	c.draw_rect(Rect2(0,572,1280,148),Color("090f20"))
	c.draw_multiline_string(ThemeDB.fallback_font,Vector2(115,626),caption_at(elapsed),HORIZONTAL_ALIGNMENT_CENTER,1050,22,-1,Color("eee6cf"))
	paint_continue_hint(c)
	if whiteout_alpha()>0: c.draw_rect(Rect2(0,0,1280,720),Color(1,1,1,whiteout_alpha()))

func paint_bridge_details(c: CanvasItem) -> void:
	var bridge=bridge_composition()
	Art.sprite(c,"planet",bridge.planet.position,bridge.planet.size)
	# The chair covers the small figure painted into the original bridge sprite.
	c.draw_rect(Rect2(560,307,160,222),Color("344955"))
	c.draw_rect(Rect2(572,315,136,184),Color("607986"))
	c.draw_rect(Rect2(579,322,122,7),Color("9bb0ad"))
	Art.sprite(c,"actor_player_down0",bridge.captain.position,bridge.captain.size)
	c.draw_rect(Rect2(550,480,180,55),Color("354d59"))
	c.draw_rect(Rect2(560,487,160,32),Color("537079"))
	c.draw_rect(Rect2(570,493,55,7),Color("9bd1c3"))
	c.draw_rect(Rect2(647,493,60,7),Color("87aebf"))
	for x in [575,594,651,680]: c.draw_rect(Rect2(x,508,7,5),Color("d4bc7c"))
	if elapsed>=12.5:
		var flicker=fmod(animation_time*11.0,3.7)
		if flicker<0.38:
			for x in [217,871]:
				c.draw_rect(Rect2(x,365,178,67),Color(0.62,0.72,0.73,0.35))
				for line in range(5): c.draw_rect(Rect2(x+7,368+line*11,160,2),Color(0.86,0.91,0.86,0.6))
		for point in [Vector2(394,345),Vector2(904,359),Vector2(681,426)]:
			if fmod(animation_time*7.0+point.x*0.013,2.9)<0.36:
				Art.sprite(c,"spark"+str(int(animation_time*25)%6),point,Vector2(28,28))

func bridge_composition() -> Dictionary:
	return {"window":Rect2(912,122,210,124),"planet":Rect2(950,130,108,108),"captain":Rect2(565,220,150,300)}

func whiteout_alpha() -> float:
	return smoothstep(24,24.2,elapsed) if caption_step>=7 else 0.0

func bolt(c: CanvasItem,start: Vector2,target: Vector2,t: float,friendly: bool) -> void:
	c.draw_set_transform(start.lerp(target,t),(target-start).angle())
	Art.sprite(c,"bolt_friendly" if friendly else "bolt_enemy",Vector2(-16,-4))
	c.draw_set_transform(Vector2.ZERO)

func paint_shots(c: CanvasItem,center: Vector2,enemy: Vector2) -> void:
	if not battle_at(elapsed).enemy_fire: return
	for shot in shots_at(3.4+fposmod(battle_clock,15)):
		if shot.friendly and not battle_at(elapsed).return_fire: continue
		var start=center+Vector2(-110,-30) if shot.friendly else enemy+Vector2(75,5)
		var target=enemy+Vector2(25,10-shot.index%3*12) if shot.friendly else center+Vector2(-65,shot.index%3*22-20)
		if shot.hit: Art.sprite(c,"explosion"+str(clampi(int(shot.impact*18),0,5)),target-Vector2(18,18),Vector2(36,36))
		else: bolt(c,start,target,shot.progress,shot.friendly)

func paint_continue_hint(c: CanvasItem) -> void:
	if caption_step<7: c.draw_string(ThemeDB.fallback_font,Vector2(440,690),"Click · E · Space to continue",HORIZONTAL_ALIGNMENT_CENTER,400,14,Color("acb9b5"))

func paint_stars(c: CanvasItem) -> void:
	for star in stars:
		var point=Vector2(fposmod(star.pos.x-animation_time*star.speed,1280),star.pos.y)
		Art.sprite(c,"particle",point,Vector2.ONE*star.size,Color(0.7,0.8,0.9,star.alpha))
