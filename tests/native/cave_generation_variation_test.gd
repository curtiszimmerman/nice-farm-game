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
	var copper_total=0
	var coal_total=0
	var rock_total=0
	var spider_guarded=true
	var entrance_clear=true
	for seed_value in range(24):
		var cave=Cave.new()
		cave.state=State.new()
		cave.state.cave_seed=seed_value+1
		cave.level=seed_value%3
		cave.generate()
		if cave.level==0:
			for rat_cell in cave.rat_cells:
				entrance_clear=entrance_clear and rat_cell.distance_to(Vector2i(4,4))>2.0
		if cave.level==2:
			spider_guarded=spider_guarded and cave.chambers.back().has_point(cave.spider_cell) and cave.floor_cells.has(cave.spider_cell) and not cave.rat_cells.has(cave.spider_cell)
		smallest=mini(smallest,cave.floor_cells.size())
		for room in cave.chambers:
			sizes[room.size]=true
			bounded=bounded and room.position.x>=0 and room.position.y>=0 and room.end.x<=cave.ROOM_CELLS.x and room.end.y<=cave.ROOM_CELLS.y
		for cell in [cave.layout.exit,cave.layout.exit+Vector2i.UP,cave.layout.exit+Vector2i.LEFT,cave.layout.exit+Vector2i.UP+Vector2i.LEFT]:
			for rock in cave.rocks.values(): connected=connected and rock.cell!=cell
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
		for rock in cave.rocks.values():
			if rock.resource=="copper": copper_total+=1
			if rock.resource=="coal": coal_total+=1
		rock_total+=cave.rocks.size()
		cave.free()
	for seed_value in range(96):
		var bottom=Cave.new()
		bottom.state=State.new()
		bottom.state.cave_seed=seed_value+1
		bottom.level=2
		bottom.generate()
		spider_guarded=spider_guarded and bottom.chambers.back().has_point(bottom.spider_cell) and bottom.floor_cells.has(bottom.spider_cell) and not bottom.rat_cells.has(bottom.spider_cell)
		bottom.free()
	check(bounded and sizes.size()>20,"seeded caves vary chamber sizes within the reduced level bounds")
	check(connected,"every generated chamber and exit connects to the entrance across many seeds")
	check(spider_guarded,"the spider guards the final chamber on every generated bottom level")
	check(entrance_clear,"rats leave the entrance tools and barrel clear for a new explorer")
	ratios=abs(float(copper_total)/rock_total-0.1)<0.03 and abs(float(coal_total)/rock_total-0.05)<0.02
	check(ratios and smallest>300,"varied levels retain connected walkable floors and the stone/copper/coal proportions")
	quit(1 if failed else 0)
