extends RefCounted

const Art=preload("res://art.gd")
const DURATION=0.325
const ACTION_DURATION=0.6
const TIPS={"hoe":Vector2(8,-9),"watering_can":Vector2(12,-2),"axe":Vector2(9,-9),"pickaxe":Vector2(9,-9),"sickle":Vector2(9,-9),"rusty_sword":Vector2(9,-11)}

static func start(world: Node2D,id: String) -> void:
	world.player.data.tool_motion=id
	world.player.data.tool_started=world.elapsed
	world.player.data.tool_facing=world.facing
	world.player.queue_redraw()

static func pose(id: String,facing: String,t: float) -> Dictionary:
	var direction={"down":Vector2.DOWN,"up":Vector2.UP,"left":Vector2.LEFT,"right":Vector2.RIGHT}[facing]
	var scale=Vector2(-1,1) if facing=="left" else Vector2.ONE
	var tip: Vector2=TIPS.get(id,Vector2(9,-9))
	var angle=direction.angle()-(tip*scale).angle()
	var pivot=Vector2(0,-23)+direction*16
	var stroke=sin(t*PI)
	match id:
		"rusty_sword","sickle":
			angle+=lerpf(-1.0,1.0,t)
		"watering_can":
			angle+=stroke*0.35
		"hoe":
			pivot+=direction*stroke*14
			angle+=stroke*0.2
		"pickaxe","axe":
			angle+=lerpf(-1.2,0,pow(minf(t/0.6,1),0.7)) if t<=0.6 else (t-0.6)*1.5
			pivot.y-=10*(1-stroke)
	return {"position":pivot,"angle":angle,"scale":scale,"tip":tip}

static func draw(world: Node2D,canvas: CanvasItem) -> void:
	var data=world.player.data
	var id=data.get("tool_motion","")
	var t=(world.elapsed-data.get("tool_started",-10.0))/(DURATION if id=="rusty_sword" else ACTION_DURATION)
	if not TIPS.has(id) or t<0 or t>=1: return
	var frame=pose(id,data.tool_facing,t)
	canvas.draw_set_transform(frame.position,frame.angle,frame.scale)
	Art.sprite(canvas,"item_"+id,Vector2(-16,-16),Vector2(32,32))
	canvas.draw_set_transform(Vector2.ZERO)
	if id=="watering_can" and t>0.25 and t<0.85:
		var direction={"down":Vector2.DOWN,"up":Vector2.UP,"left":Vector2.LEFT,"right":Vector2.RIGHT}[data.tool_facing]
		for i in range(4):
			var drop=frame.position+direction*17+Vector2(i*3-4,fposmod(t*55+i*7,20))
			Art.sprite(canvas,"particle",drop,Vector2(3,4),Color("a8dce9"))
