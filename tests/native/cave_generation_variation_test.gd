extends SceneTree
const Cave=preload("res://cave.gd")
const State=preload("res://state.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void:
	var bounded=true
	var connected=true
	var ratios=true
	var sizes={}
	var smallest=100000
	for seed_value in range(24):
		var cave=Cave.new()
		cave.state=State.new()
		cave.state.cave_seed=seed_value+1
		cave.level=seed_value%3
		cave.generate()
		smallest=mini(smallest,cave.floor_cells.size())
		for room in cave.chambers:
			sizes[room.size]=true
			bounded=bounded and room.position.x>=0 and room.position.y>=0 and room.end.x<=cave.ROOM_CELLS.x and room.end.y<=cave.ROOM_CELLS.y
		var reached={cave.layout.entry:true}
		var queue=[cave.layout.entry]
		var cursor=0
		while cursor<queue.size():
			var cell: Vector2i=queue[cursor]
			cursor+=1
			for step in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
				var next=cell+step
				if reached.has(next) or not cave.floor_cells.has(next): continue
				reached[next]=true
				queue.append(next)
		connected=connected and reached.size()==cave.floor_cells.size()
		var copper=0
		var coal=0
		for rock in cave.rocks.values():
			if rock.resource=="copper": copper+=1
			if rock.resource=="coal": coal+=1
		var total=float(cave.rocks.size())
		ratios=ratios and abs(copper/total-0.1)<0.02 and abs(coal/total-0.05)<0.02
		cave.free()
	check(bounded and sizes.size()>20,"seeded caves vary chamber sizes within the reduced level bounds")
	check(connected,"every generated chamber and exit connects to the entrance across many seeds")
	check(ratios and smallest>1350,"varied levels retain large walkable floors and the stone/copper/coal proportions")
	quit(1 if failed else 0)
