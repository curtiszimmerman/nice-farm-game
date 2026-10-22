extends RefCounted

const Art=preload("res://art.gd")
const DURATION=0.65

static func start(world: Node2D,id: String) -> void:
	world.player.data.tool_motion=id
	world.player.data.tool_started=world.elapsed
	world.player.data.tool_facing=world.facing
	world.player.queue_redraw()

static func draw(world: Node2D,canvas: CanvasItem) -> void:
	var data=world.player.data
	var id=data.get("tool_motion","")
	var t=(world.elapsed-data.get("tool_started",-10.0))/DURATION
	if id=="" or t<0 or t>=1: return
	var facing=data.tool_facing
	var direction={"down":Vector2.DOWN,"up":Vector2.UP,"left":Vector2.LEFT,"right":Vector2.RIGHT}[facing]
	var pivot=Vector2(0,-23)+direction*9
	var angle=0.0
	var reach=Vector2(0,-25)
	var stroke=sin(t*PI)
	match id:
		"rusty_sword","sickle":
			angle=direction.angle()+lerpf(-1.8,1.2,t)
			reach=Vector2(25,0)
		"watering_can":
			pivot+=direction*12
			angle=stroke*0.85*(1 if facing!="left" else -1)
			reach=Vector2(0,-8)
		"hoe":
			pivot+=direction*stroke*15+Vector2(0,stroke*13)
			angle=lerpf(-0.8,0.5,t)
		"pickaxe","axe":
			angle=lerpf(-1.4,1.1,pow(t,0.6))*(1 if facing!="left" else -1)
			pivot.y-=12*(1-stroke)
		_: return
	canvas.draw_set_transform(pivot,angle)
	Art.sprite(canvas,"item_"+id,reach-Vector2(16,16),Vector2(32,32))
	canvas.draw_set_transform(Vector2.ZERO)
	if id=="watering_can" and t>0.25 and t<0.85:
		for i in range(4):
			var drop=pivot+direction*17+Vector2(i*3-4,fposmod(t*55+i*7,20))
			Art.sprite(canvas,"particle",drop,Vector2(3,4),Color("a8dce9"))
