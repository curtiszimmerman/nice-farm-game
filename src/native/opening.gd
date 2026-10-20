extends CanvasLayer

const DURATION=28.0
var game: Node2D
var elapsed=0.0
var impact_played=false
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

func scene_at(time: float) -> String:
	if time>=25: return "aftermath"
	if time>=24: return "impact"
	if (time>=4.5 and time<9) or (time>=12.5 and time<18) or time>=21: return "bridge"
	return "space"

func _process(dt: float) -> void:
	if finished: return
	elapsed+=dt
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
	var w=game.outdoors
	var scene=scene_at(elapsed)
	if scene=="aftermath":
		c.draw_rect(Rect2(0,0,1280,720),Color(1,1,1,1-smoothstep(25,28,elapsed)))
		return
	w.r(c,0,0,1280,720,"090f20")
	for i in range(100):
		var x=fposmod(i*137.7-elapsed*(7+i%3),1280)
		var y=fposmod(i*83.3,720)
		w.r(c,x,y,2 if i%4 else 3,2,"adbec8" if i%3 else "667795")
	if scene=="space":
		var center=Vector2(650+sin(elapsed*0.7)*25,340+sin(elapsed)*12)
		ship(c,center,2.2)
		if elapsed>=3:
			ship(c,Vector2(160,170),1.25,true)
			for i in range(3):
				var t=fposmod(elapsed*1.8+i*0.31,1)
				var point=Vector2(230,175).lerp(center,t)
				c.draw_line(point,point+Vector2(42,16),Color("f0a3a0"),3)
			if fmod(elapsed,0.8)<0.2:
				w.oval(c,center.x-30,center.y-5,14,20,"efcf9c")
				for i in range(5): w.oval(c,center.x-20-i*22,center.y+i*8,9+i*2,7+i,"776e6c")
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
	var caption="A quiet course through unfamiliar space."
	if elapsed>=3: caption="Weapons fire cuts across the ship's course."
	if elapsed>=4.5: caption="CAPTAIN: Incoming fire! Evasive pattern delta. Keep us moving!"
	if elapsed>=12.5: caption="VALE: We've taken too much damage. I'm trying to land on that nearby planet!"
	if elapsed>=21: caption="CAPTAIN: All hands! Brace for impact!"
	c.draw_multiline_string(ThemeDB.fallback_font,Vector2(115,626),caption,HORIZONTAL_ALIGNMENT_CENTER,1050,22,-1,Color("eee6cf"))
	if elapsed>=23: c.draw_rect(Rect2(0,0,1280,720),Color(1,1,1,smoothstep(23,24,elapsed)))
