extends Node2D

const Art=preload("res://art.gd")
const Grid=preload("res://grid.gd")
var world: Node2D
var signature=""

func _ready() -> void:
	var unshaded=CanvasItemMaterial.new()
	unshaded.light_mode=CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material=unshaded
	z_index=6

func night() -> bool: return world.state.minute>=1140 or world.state.minute<360

func house_lit(building: Dictionary) -> bool:
	if not night(): return false
	if building.id=="home": return world.state.house_tasks.living_light or world.state.house_tasks.bathroom_light
	for person in world.people:
		if world.Schedule.home_stop(person.id).room!=building.id: continue
		if not world.Schedule.stop(person.id,world.state.minute).sleeping: return true
	return building.id=="store" and world.state.minute<1200

func smoking(building: Dictionary) -> bool:
	if building.kind in ["lighthouse","observatory"]: return false
	return building.kind in ["bakery","smithy"] or (night() and world.state.season_name()=="winter")

func refresh() -> void:
	var next="%d/%d/%s" % [int(world.elapsed*12),int(world.state.minute),world.state.season_name()]
	if next==signature: return
	signature=next
	queue_redraw()

func _draw() -> void:
	if world==null: return
	if night():
		for cell in world.LAMP_CELLS:
			var foot=Grid.center(cell)
			Art.sprite(self,"lamp_halo",foot-Vector2(70,24),Vector2(140,70))
			Art.sprite(self,"particle",foot+Vector2(-4,-66),Vector2(8,11),Color("ffe1a1"))
	for building in world.buildings:
		var columns=building.tiles.x
		var anchor=Vector2(building.x,building.y+building.h)
		if house_lit(building):
			if building.kind=="tower":
				Art.sprite(self,"window_warm",anchor+Vector2(int(columns/2)*32,-96),Vector2(32,32))
			elif building.kind=="observatory":
				for x in [34,146]: Art.sprite(self,"window_warm",anchor+Vector2(x,-56),Vector2(22,30))
			elif building.kind!="lighthouse":
				for x in [1,columns-2]:
					if x==int(columns/2): continue
					Art.sprite(self,"window_warm",anchor+Vector2(x*32,-64),Vector2(32,32))
		if not smoking(building): continue
		var rows=5 if building.kind=="windmill" else 4 if building.kind=="tower" else maxi(2,building.tiles.y-2)
		var chimney=anchor+Vector2(maxi(1,columns-2)*32+16,(-rows-3)*32)
		for i in range(3):
			var age=fposmod(world.elapsed+i*0.65,2.0)/2.0
			var pos=chimney+Vector2(sin(age*4+i)*7+age*12,-age*42)
			Art.sprite(self,"chimney_smoke"+str(int(age*4)%4),pos-Vector2(12,12),Vector2(24,24)*(0.6+age),Color(1,1,1,pow(1-age,2)))
