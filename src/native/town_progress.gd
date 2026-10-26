extends RefCounted
const FIELDS=["ladder_clue","ladder_located","shop_season","shop_remaining","met_people","friendships","learned_spells","bloom_harvests","bloom_cells","cave_level","quick_row","beehive_known","chat_days","gift_weeks","star_origin_reply"]
static func integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(value) and value==floor(value)
static func snapshot(state: RefCounted) -> Dictionary:
	var data={}
	for field in FIELDS:
		var value=state.get(field)
		data[field]=value.duplicate(true) if value is Dictionary or value is Array else value
	return data
static func valid(data: Variant) -> bool:
	if not data is Dictionary or not data.has_all(FIELDS): return false
	if data.star_origin_reply not in ["","truth","lie"]: return false
	for field in ["chat_days","gift_weeks"]:
		if not data[field] is Dictionary: return false
		for id in data[field]:
			if not preload("res://villager_schedule.gd").ROUTINES.has(id) or not integer(data[field][id]) or data[field][id]<0: return false
	if not data.ladder_clue is bool or not data.ladder_located is bool or not data.beehive_known is bool: return false
	if not integer(data.shop_season) or data.shop_season< -1: return false
	if not integer(data.cave_level) or data.cave_level<0 or data.cave_level>2: return false
	if not integer(data.quick_row) or data.quick_row<0 or data.quick_row>1: return false
	for field in ["shop_remaining","friendships","bloom_harvests"]:
		if not data[field] is Dictionary: return false
	for id in data.shop_remaining:
		if not preload("res://shop_stock.gd").CATALOG.has(id): return false
		var count=data.shop_remaining[id]
		if not integer(count) or count<0 or count>preload("res://shop_stock.gd").CATALOG[id].stock: return false
	for field in ["met_people","learned_spells"]:
		if not data[field] is Array: return false
		for id in data[field]:
			if not id is String: return false
	if not data.bloom_cells is Array or data.bloom_cells.size()>12: return false
	for cell in data.bloom_cells:
		if not cell is String or data.bloom_cells.count(cell)!=1: return false
		var pair=cell.split(",")
		if pair.size()!=2 or not pair[0].is_valid_int() or not pair[1].is_valid_int(): return false
		if not preload("res://grid.gd").contains(Vector2i(int(pair[0]),int(pair[1]))): return false
	var people=preload("res://villager_schedule.gd").ROUTINES
	for id in data.met_people:
		if not people.has(id) or data.met_people.count(id)!=1: return false
	for id in data.learned_spells:
		if id not in ["hearthmend","emberthread"] or data.learned_spells.count(id)!=1: return false
	for id in data.friendships:
		if not people.has(id) or id not in data.met_people: return false
		if not integer(data.friendships[id]) or abs(data.friendships[id])>100: return false
	for key in data.bloom_harvests:
		if not key is String or not integer(data.bloom_harvests[key]) or data.bloom_harvests[key]<1: return false
	return true
static func restore(state: RefCounted,data: Dictionary) -> void:
	for field in FIELDS: state.set(field,data[field].duplicate(true) if data[field] is Array or data[field] is Dictionary else data[field])
	for field in ["shop_season","cave_level","quick_row"]: state.set(field,int(data[field]))
