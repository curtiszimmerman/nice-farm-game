extends RefCounted

static func key(item: String,cell: Vector2i) -> String:
	return "%s:%d:%d" % [item,cell.x,cell.y]

static func ready(state: RefCounted,item: String,cell: Vector2i) -> bool:
	if item=="berries" and state.season_name() not in ["spring","summer"]: return false
	if item=="apples" and state.season_name()!="autumn": return false
	return state.total()-state.forage_harvests.get(key(item,cell),-10080)>=10080

static func choose(cells: Array,seed_value: int) -> Array:
	var pool=cells.duplicate()
	var rng=RandomNumberGenerator.new()
	rng.seed=seed_value
	for i in range(pool.size()-1,0,-1):
		var j=rng.randi_range(0,i)
		var old=pool[i]
		pool[i]=pool[j]
		pool[j]=old
	return pool.slice(0,maxi(1,roundi(pool.size()*0.075)))
