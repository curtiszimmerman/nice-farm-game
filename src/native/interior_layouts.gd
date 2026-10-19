extends RefCounted

# Rooms leave a tile for partition walls. Bathrooms open only onto a hall.
static func for_building(id: String) -> Dictionary:
	var plan: Dictionary
	match id:
		"home": plan=_open_house(14,true)
		"finch":
			plan=_open_house(12,false)
			plan.furniture.append(["radio",Rect2i(8,9,3,1)])
			plan.furniture.append(["bookshelf",Rect2i(1,10,3,1)])
			plan.work=[Vector2i(10,8),Vector2i(7,10),Vector2i(7,7)]
		"moss":
			plan=_house(15,12)
			_mirror(plan)
			plan.furniture.append(["seed_tray",Rect2i(10,10,2,1)])
		"tavi":
			plan=_house(15,11)
			plan.furniture.append(["crates",Rect2i(12,8,2,1)])
		"mayor":
			plan=_house(16,12)
			plan.furniture.append(["desk",Rect2i(2,10,2,1)])
		"assistant": plan=_house(15,12)
		"veteran": plan=_cabin()
		"iona": plan=_tower()
		"radio": plan=_club()
		"store": plan=_public_building(false)
		_: plan=_public_building(true)
	return plan

static func _house(w: int,h: int) -> Dictionary:
	var ly=h-5
	var kx=w-5
	return {"size":Vector2i(w,h),"areas":[
		["bedroom",Rect2i(1,1,5,h-8)],["bathroom",Rect2i(9,1,w-10,3)],
		["hall",Rect2i(7,1,1,ly-2)],["living",Rect2i(1,ly,w-7,4)],["kitchen",Rect2i(kx,5,4,h-6)]],
		"doors":[["bedroom","hall",Vector2i(6,2)],["bathroom","hall",Vector2i(8,2)],
		["hall","living",Vector2i(7,ly-1)],["living","kitchen",Vector2i(kx-1,ly+1)]],
		"entry":Vector2i(7,h-2),"exit":Vector2i(7,h-1),
		"furniture":[["bed",Rect2i(2,1,2,2)],["bookshelf",Rect2i(5,1,1,1)],
		["bath",Rect2i(w-3,1,1,2)],["toilet",Rect2i(10,1,1,1)],["sink",Rect2i(9,1,1,1)],
		["rug",Rect2i(4,ly,4,3)],["sofa",Rect2i(1,ly+1,3,1)],["table",Rect2i(5,ly+1,2,1)],
		["chair",Rect2i(4,ly+1,1,1)],["chair",Rect2i(7,ly+1,1,1)],
		["kitchen",Rect2i(kx,5,4,1)],["radio",Rect2i(1,ly,1,1)],
		["plant",Rect2i(w-2,h-2,1,1)],["art",Rect2i(2,0,2,1)]],
		"sites":[["bed",Vector2i(4,2)],["radio",Vector2i(2,ly)]],
		"work":[Vector2i(7,ly),Vector2i(8,h-3),Vector2i(kx+1,7)]}

static func _open_house(h: int,guest: bool) -> Dictionary:
	var furniture=[
		["bed",Rect2i(1,1,2,2)],["bookshelf",Rect2i(1,4,2,1)],
		["bath",Rect2i(11,1,1,2)],["toilet",Rect2i(10,1,1,1)],["sink",Rect2i(9,1,1,1)],
		["sofa",Rect2i(1,8,3,1)],["table",Rect2i(5,9,2,1)],["chair",Rect2i(4,9,1,1)],
		["chair",Rect2i(7,9,1,1)],["kitchen",Rect2i(8,7,4,1)],
		["radio",Rect2i(1,7,1,1)],["rug",Rect2i(4,8,4,3)],["art",Rect2i(3,0,2,1)]]
	if guest: furniture.append(["bed",Rect2i(4,1,2,2)])
	return {"size":Vector2i(13,h),"areas":[["bedroom",Rect2i(1,1,5,4)],
		["bathroom",Rect2i(9,1,3,3)],["hall",Rect2i(7,1,1,5)],["living",Rect2i(1,7,11,h-8)]],
		"doors":[["bedroom","hall",Vector2i(6,3)],["bathroom","hall",Vector2i(8,2)],["hall","living",Vector2i(7,6)]],
		"entry":Vector2i(6,h-2),"exit":Vector2i(6,h-1),"furniture":furniture,
		"sites":[["bed",Vector2i(3,2)],["radio",Vector2i(2,7)]],"work":[Vector2i(7,7),Vector2i(9,9),Vector2i(5,10)]}

static func _cabin() -> Dictionary:
	return {"size":Vector2i(11,11),"areas":[["bedroom",Rect2i(1,1,3,3)],
		["hall",Rect2i(5,1,1,4)],["bathroom",Rect2i(7,1,3,3)],["living",Rect2i(1,6,9,4)]],
		"doors":[["bedroom","hall",Vector2i(4,3)],["bathroom","hall",Vector2i(6,3)],["hall","living",Vector2i(5,5)]],
		"entry":Vector2i(5,9),"exit":Vector2i(5,10),"furniture":[
		["bed",Rect2i(1,1,2,2)],["bookshelf",Rect2i(3,1,1,1)],
		["toilet",Rect2i(7,1,1,1)],["sink",Rect2i(8,1,1,1)],["bath",Rect2i(9,1,1,2)],
		["kitchen",Rect2i(7,6,3,1)],["sofa",Rect2i(1,7,2,1)],
		["table",Rect2i(4,7,2,1)],["chair",Rect2i(6,7,1,1)],["radio",Rect2i(1,6,1,1)],
		["rug",Rect2i(3,7,4,3)],["tools",Rect2i(1,9,2,1)],["art",Rect2i(2,0,1,1)]],
		"sites":[["bed",Vector2i(3,2)],["radio",Vector2i(2,6)]],
		"work":[Vector2i(3,6),Vector2i(7,8),Vector2i(4,9)]}

static func _tower() -> Dictionary:
	return {"size":Vector2i(9,11),"areas":[["bedroom",Rect2i(1,1,2,3)],
		["hall",Rect2i(4,1,1,4)],["bathroom",Rect2i(6,1,2,3)],["study",Rect2i(1,6,7,4)]],
		"doors":[["bedroom","hall",Vector2i(3,3)],["bathroom","hall",Vector2i(5,3)],["hall","study",Vector2i(4,5)]],
		"entry":Vector2i(4,9),"exit":Vector2i(4,10),"furniture":[
		["bed",Rect2i(1,1,1,2)],["toilet",Rect2i(6,1,1,1)],["sink",Rect2i(6,2,1,1)],["bath",Rect2i(7,1,1,2)],
		["bookshelf",Rect2i(1,6,2,1)],["kitchen",Rect2i(6,6,2,1)],["sofa",Rect2i(1,7,2,1)],
		["table",Rect2i(4,7,1,1)],["rug",Rect2i(3,7,3,3)],["telescope",Rect2i(6,8,1,1)],
		["radio",Rect2i(7,9,1,1)],["art",Rect2i(1,0,1,1)]],
		"sites":[["bed",Vector2i(2,3)],["radio",Vector2i(6,9)]],
		"work":[Vector2i(4,6),Vector2i(5,8),Vector2i(3,9)]}

static func _club() -> Dictionary:
	return {"size":Vector2i(16,12),"areas":[["workshop",Rect2i(1,1,9,6)],
		["reception",Rect2i(1,8,9,3)],["hall",Rect2i(11,1,1,10)],
		["bathroom",Rect2i(13,1,2,3)],["kitchen",Rect2i(13,6,2,5)]],
		"doors":[["workshop","reception",Vector2i(5,7)],["workshop","hall",Vector2i(10,3)],
		["reception","hall",Vector2i(10,9)],["bathroom","hall",Vector2i(12,3)],["kitchen","hall",Vector2i(12,8)]],
		"entry":Vector2i(5,10),"exit":Vector2i(5,11),"furniture":[
		["radio",Rect2i(2,1,6,1)],["desk",Rect2i(2,4,2,1)],["chair",Rect2i(2,5,1,1)],
		["bookshelf",Rect2i(8,3,1,3)],["sofa",Rect2i(1,9,3,1)],["rug",Rect2i(5,8,4,3)],
		["table",Rect2i(7,9,2,1)],["kitchen",Rect2i(13,6,2,1)],
		["toilet",Rect2i(13,1,1,1)],["sink",Rect2i(14,1,1,1)],["art",Rect2i(3,0,2,1)]],
		"sites":[["radio",Vector2i(5,2)]],"work":[Vector2i(5,2),Vector2i(7,4),Vector2i(3,6)]}

static func _public_building(hall: bool) -> Dictionary:
	var furniture=[
		["toilet",Rect2i(14,1,1,1)],["sink",Rect2i(15,1,1,1)],["radio",Rect2i(1,9,1,1)],
		["art",Rect2i(4,0,2,1)],["rug",Rect2i(3,8,6,3)]]
	if hall:
		furniture.append_array([["table",Rect2i(3,5,5,2)],["chair",Rect2i(2,5,1,1)],
		["chair",Rect2i(8,5,1,1)],["chair",Rect2i(2,6,1,1)],["chair",Rect2i(8,6,1,1)],
		["desk",Rect2i(4,2,3,1)],["bookshelf",Rect2i(1,1,2,1)],
		["desk",Rect2i(14,6,2,1)],["chair",Rect2i(15,7,1,1)],["bookshelf",Rect2i(14,10,1,1)]])
	else:
		furniture.append_array([["counter",Rect2i(6,6,4,1)],["stock",Rect2i(1,1,8,1)],
		["stock",Rect2i(1,4,1,4)],["stock",Rect2i(5,3,3,1)],
		["crates",Rect2i(14,6,2,2)],["stock",Rect2i(15,9,1,2)]])
	return {"size":Vector2i(17,12),"areas":[["public",Rect2i(1,1,10,10)],
		["hall",Rect2i(12,1,1,10)],["bathroom",Rect2i(14,1,2,3)],
		["office" if hall else "stockroom",Rect2i(14,6,2,5)]],
		"doors":[["public","hall",Vector2i(11,3)],["public","hall",Vector2i(11,8)],
		["bathroom","hall",Vector2i(13,3)],["hall","office" if hall else "stockroom",Vector2i(13,8)]],
		"entry":Vector2i(5,10),"exit":Vector2i(5,11),"furniture":furniture,
		"sites":[["radio",Vector2i(2,9)]] if hall else [["radio",Vector2i(2,9)],["shop",Vector2i(9,7)]],
		"work":[Vector2i(14,8),Vector2i(6,8),Vector2i(9,4)]}

static func _mirror(plan: Dictionary) -> void:
	var w=plan.size.x
	for area in plan.areas: area[1].position.x=w-area[1].end.x
	for item in plan.furniture: item[1].position.x=w-item[1].end.x
	for door in plan.doors: door[2].x=w-1-door[2].x
	for site in plan.sites: site[1].x=w-1-site[1].x
	for i in range(plan.work.size()): plan.work[i].x=w-1-plan.work[i].x
	plan.entry.x=w-1-plan.entry.x
	plan.exit.x=w-1-plan.exit.x
