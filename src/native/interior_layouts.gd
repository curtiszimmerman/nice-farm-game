extends RefCounted

# Rooms leave a tile for partition walls. Bathrooms open only onto a hall.
static func for_building(id: String) -> Dictionary:
	var neighbor=preload("res://neighbor_interiors.gd").layout(id)
	if not neighbor.is_empty(): return neighbor
	var plan: Dictionary
	match id:
		"home":
			plan=_farmhouse()
		"ship": plan=_ship()
		"finch": plan=_finch()
		"moss": plan=_moss()
		"tavi": plan=_tavi()
		"mayor": plan=_alder()
		"assistant": plan=_neral()
		"veteran": plan=_cabin()
		"iona": plan=_tower()
		"radio": plan=_club()
		"store": plan=_public_building(false)
		"keeper": plan=_lighthouse()
		_: plan=_council()
	return plan

static func _farmhouse() -> Dictionary:
	return {"size":Vector2i(13,14),"areas":[["bedroom",Rect2i(1,1,5,4)],["bathroom",Rect2i(9,1,3,4)],["hall",Rect2i(7,1,1,12)],["living",Rect2i(1,6,5,7)],["kitchen",Rect2i(9,6,3,7)]],
		"doors":[["bedroom","hall",Vector2i(6,3)],["bathroom","hall",Vector2i(8,3)],["hall","living",Vector2i(6,9)],["hall","kitchen",Vector2i(8,9)]],
		"entry":Vector2i(7,12),"exit":Vector2i(7,13),"furniture":[["bed",Rect2i(1,1,2,2)],["bed",Rect2i(4,1,2,2)],["bookshelf",Rect2i(1,4,2,1)],["floor_lamp",Rect2i(5,4,1,1)],["floor_lamp",Rect2i(1,12,1,1)],
		["bath",Rect2i(11,1,1,2)],["toilet",Rect2i(10,1,1,1)],["sink",Rect2i(9,1,1,1)],["sofa",Rect2i(1,7,3,1)],["table",Rect2i(3,9,2,1)],["chair",Rect2i(2,9,1,1)],["chair",Rect2i(3,10,1,1)],
		["kitchen",Rect2i(9,6,3,1)],["cabinet",Rect2i(10,10,2,1)],["radio",Rect2i(1,6,1,1)],["rug",Rect2i(3,8,3,3)],["art",Rect2i(3,0,2,1)]],
		"sites":[["bed",Vector2i(3,2)],["radio",Vector2i(2,6)],["cabinet",Vector2i(10,11)],["stove",Vector2i(9,7)],["uncover_sofa",Vector2i(2,8)],["uncover_guest_bed",Vector2i(5,3)],["living_light",Vector2i(2,12)],["bathroom_light",Vector2i(4,4)]],"work":[Vector2i(7,10),Vector2i(9,9),Vector2i(5,11)]}

static func _lighthouse() -> Dictionary:
	return {"size":Vector2i(12,16),"areas":[["lamp_workshop",Rect2i(1,1,10,4)],
		["kitchen",Rect2i(1,6,4,3)],["hall",Rect2i(6,6,1,9)],["bedroom",Rect2i(8,6,3,4)],
		["living",Rect2i(1,10,4,5)],["bathroom",Rect2i(8,12,3,3)]],
		"doors":[["lamp_workshop","hall",Vector2i(6,5)],["kitchen","hall",Vector2i(5,7)],
		["bedroom","hall",Vector2i(7,9)],["living","hall",Vector2i(5,12)],["bathroom","hall",Vector2i(7,13)]],
		"entry":Vector2i(6,14),"exit":Vector2i(6,15),"furniture":[
		["desk",Rect2i(1,1,3,1)],["tools",Rect2i(1,3,1,2)],["telescope",Rect2i(9,1,1,1)],["cabinet",Rect2i(8,3,2,1)],
		["kitchen",Rect2i(1,6,4,1)],["table",Rect2i(2,8,2,1)],["bed",Rect2i(8,6,2,3)],["bookshelf",Rect2i(10,6,1,1)],
		["sofa",Rect2i(1,10,3,1)],["rug",Rect2i(2,11,2,3)],["table",Rect2i(2,12,2,1)],["chair",Rect2i(1,12,1,1)],
		["radio",Rect2i(1,14,1,1)],["toilet",Rect2i(8,12,1,1)],["sink",Rect2i(9,12,1,1)],["bath",Rect2i(10,13,1,2)],
		["art",Rect2i(1,9,2,1)]],"sites":[["radio",Vector2i(2,14)],["bed",Vector2i(10,7)]],
		"work":[Vector2i(6,3),Vector2i(9,4),Vector2i(6,12)]}

static func _moss() -> Dictionary:
	return {"size":Vector2i(14,14),"areas":[["hall",Rect2i(6,1,1,12)],
		["bathroom",Rect2i(1,1,4,3)],["bedroom",Rect2i(8,1,5,4)],
		["kitchen",Rect2i(1,6,4,7)],["living",Rect2i(8,7,5,6)]],
		"doors":[["bathroom","hall",Vector2i(5,3)],["bedroom","hall",Vector2i(7,3)],
		["kitchen","hall",Vector2i(5,8)],["living","hall",Vector2i(7,10)]],
		"entry":Vector2i(6,12),"exit":Vector2i(6,13),"furniture":[
		["toilet",Rect2i(1,1,1,1)],["sink",Rect2i(2,1,1,1)],["bath",Rect2i(4,1,1,2)],
		["bed",Rect2i(9,1,2,3)],["bookshelf",Rect2i(11,1,2,1)],
		["kitchen",Rect2i(1,6,4,1)],["tools",Rect2i(1,10,1,2)],["seed_tray",Rect2i(3,11,2,1)],
		["radio",Rect2i(8,7,1,1)],["sofa",Rect2i(10,8,3,1)],["table",Rect2i(9,11,2,1)],
		["chair",Rect2i(8,11,1,1)],["plant",Rect2i(12,12,1,1)],["rug",Rect2i(9,9,3,3)],["art",Rect2i(9,6,2,1)]],
		"sites":[["bed",Vector2i(8,2)],["radio",Vector2i(9,7)]],
		"work":[Vector2i(6,8),Vector2i(2,8),Vector2i(10,10)]}

static func _tavi() -> Dictionary:
	return {"size":Vector2i(15,12),"areas":[["bedroom",Rect2i(1,1,5,4)],
		["bathroom",Rect2i(9,1,5,3)],["hall",Rect2i(7,1,1,5)],
		["living",Rect2i(1,7,9,4)],["kitchen",Rect2i(11,6,3,5)]],
		"doors":[["bedroom","hall",Vector2i(6,3)],["bathroom","hall",Vector2i(8,3)],
		["hall","living",Vector2i(7,6)],["living","kitchen",Vector2i(10,8)]],
		"entry":Vector2i(3,10),"exit":Vector2i(3,11),"furniture":[
		["bed",Rect2i(1,1,2,3)],["bookshelf",Rect2i(4,1,2,1)],
		["sink",Rect2i(9,1,1,1)],["toilet",Rect2i(10,1,1,1)],["bath",Rect2i(12,1,2,2)],
		["sofa",Rect2i(1,7,2,1)],["table",Rect2i(5,8,2,1)],["chair",Rect2i(7,8,1,1)],
		["radio",Rect2i(1,9,1,1)],["crates",Rect2i(8,9,2,2)],["kitchen",Rect2i(11,6,3,1)],
		["stock",Rect2i(13,8,1,2)],["rug",Rect2i(3,8,4,3)],["art",Rect2i(3,6,2,1)]],
		"sites":[["bed",Vector2i(3,2)],["radio",Vector2i(2,9)]],
		"work":[Vector2i(5,10),Vector2i(12,8),Vector2i(8,7)]}

static func _finch() -> Dictionary:
	return {"size":Vector2i(14,13),"areas":[["living",Rect2i(1,1,8,5)],
		["kitchen",Rect2i(10,1,3,5)],["hall",Rect2i(1,7,12,1)],["hall",Rect2i(8,8,1,4)],
		["bedroom",Rect2i(1,9,6,3)],["bathroom",Rect2i(10,9,3,3)]],
		"doors":[["living","hall",Vector2i(3,6)],["kitchen","hall",Vector2i(11,6)],
		["bedroom","hall",Vector2i(3,8)],["bathroom","hall",Vector2i(9,10)]],
		"entry":Vector2i(8,11),"exit":Vector2i(8,12),"furniture":[
		["bed",Rect2i(1,9,2,2)],["bookshelf",Rect2i(4,9,2,1)],
		["sofa",Rect2i(1,2,3,1)],["radio",Rect2i(5,1,3,1)],["desk",Rect2i(5,4,2,1)],
		["chair",Rect2i(5,5,1,1)],["table",Rect2i(1,4,2,1)],["chair",Rect2i(3,4,1,1)],
		["kitchen",Rect2i(10,1,3,1)],["bath",Rect2i(12,9,1,2)],
		["toilet",Rect2i(10,9,1,1)],["sink",Rect2i(11,9,1,1)],
		["rug",Rect2i(4,3,3,3)],["art",Rect2i(2,0,2,1)]],
		"sites":[["bed",Vector2i(3,10)],["radio",Vector2i(6,2)]],
		"work":[Vector2i(6,3),Vector2i(3,5),Vector2i(11,3)]}

static func _alder() -> Dictionary:
	return {"size":Vector2i(16,13),"areas":[["living",Rect2i(1,1,8,5)],
		["office",Rect2i(1,7,5,5)],["kitchen",Rect2i(7,7,2,5)],["hall",Rect2i(10,1,1,11)],
		["bedroom",Rect2i(12,1,3,5)],["bathroom",Rect2i(12,7,3,5)]],
		"doors":[["living","hall",Vector2i(9,3)],["bedroom","hall",Vector2i(11,3)],
		["bathroom","hall",Vector2i(11,8)],["kitchen","hall",Vector2i(9,10)],
		["living","office",Vector2i(3,6)],["living","kitchen",Vector2i(7,6)],["office","kitchen",Vector2i(6,9)]],
		"entry":Vector2i(10,11),"exit":Vector2i(10,12),"furniture":[
		["bed",Rect2i(12,1,2,2)],["bath",Rect2i(14,7,1,2)],
		["toilet",Rect2i(12,7,1,1)],["sink",Rect2i(13,7,1,1)],["kitchen",Rect2i(7,11,2,1)],
		["sofa",Rect2i(1,2,3,1)],["table",Rect2i(5,3,3,1)],["chair",Rect2i(4,4,1,1)],
		["chair",Rect2i(8,2,1,1)],["radio",Rect2i(1,1,1,1)],["bookshelf",Rect2i(1,11,3,1)],
		["desk",Rect2i(2,9,3,1)],["chair",Rect2i(2,10,1,1)],
		["plant",Rect2i(5,11,1,1)],["rug",Rect2i(4,2,4,3)],["art",Rect2i(3,0,2,1)]],
		"sites":[["bed",Vector2i(14,2)],["radio",Vector2i(2,1)]],
		"work":[Vector2i(3,8),Vector2i(7,9),Vector2i(7,4)]}

static func _neral() -> Dictionary:
	return {"size":Vector2i(12,14),"areas":[["hall",Rect2i(6,1,1,12)],
		["study",Rect2i(1,1,4,7)],["bedroom",Rect2i(8,1,3,6)],
		["bathroom",Rect2i(1,9,4,4)],["kitchen",Rect2i(8,8,3,5)]],
		"doors":[["study","hall",Vector2i(5,3)],["bedroom","hall",Vector2i(7,3)],
		["bathroom","hall",Vector2i(5,10)],["kitchen","hall",Vector2i(7,10)]],
		"entry":Vector2i(6,12),"exit":Vector2i(6,13),"furniture":[
		["sofa",Rect2i(1,4,2,1)],["desk",Rect2i(1,1,2,1)],["chair",Rect2i(1,2,1,1)],
		["bookshelf",Rect2i(4,1,1,2)],["radio",Rect2i(3,1,1,1)],
		["bed",Rect2i(8,1,2,2)],["bookshelf",Rect2i(10,1,1,1)],
		["bath",Rect2i(1,9,1,2)],["sink",Rect2i(2,9,1,1)],["toilet",Rect2i(3,9,1,1)],
		["kitchen",Rect2i(8,8,3,1)],["table",Rect2i(8,11,2,1)],["chair",Rect2i(10,11,1,1)],
		["rug",Rect2i(2,2,2,3)],["art",Rect2i(1,0,2,1)]],
		"sites":[["bed",Vector2i(10,2)],["radio",Vector2i(3,2)]],
		"work":[Vector2i(3,3),Vector2i(6,8),Vector2i(9,10)]}

static func _council() -> Dictionary:
	return {"size":Vector2i(16,13),"areas":[["reception",Rect2i(1,1,9,6)],
		["council",Rect2i(1,8,9,4)],["hall",Rect2i(11,1,1,11)],
		["bathroom",Rect2i(13,1,2,3)],["office",Rect2i(13,7,2,5)]],
		"doors":[["reception","council",Vector2i(5,7)],["reception","hall",Vector2i(10,3)],
		["council","hall",Vector2i(10,9)],["bathroom","hall",Vector2i(12,3)],["office","hall",Vector2i(12,9)]],
		"entry":Vector2i(5,11),"exit":Vector2i(5,12),"furniture":[
		["table",Rect2i(3,9,4,1)],["chair",Rect2i(2,9,1,1)],["chair",Rect2i(7,9,1,1)],
		["desk",Rect2i(3,2,3,1)],["bookshelf",Rect2i(1,1,2,1)],
		["radio",Rect2i(1,8,1,1)],["rug",Rect2i(3,8,5,3)],
		["desk",Rect2i(13,7,2,1)],["chair",Rect2i(14,8,1,1)],
		["toilet",Rect2i(13,1,1,1)],["sink",Rect2i(14,1,1,1)],["art",Rect2i(4,0,2,1)]],
		"sites":[["radio",Vector2i(2,8)]],"work":[Vector2i(14,9),Vector2i(6,4),Vector2i(8,10)]}

static func _ship() -> Dictionary:
	return {"size":Vector2i(15,14),"areas":[["crew",Rect2i(1,1,13,5)],["engineering",Rect2i(1,7,13,6)]],
		"doors":[["crew","engineering",Vector2i(7,6)]],"entry":Vector2i(7,12),"exit":Vector2i(7,13),
		"furniture":[["reactor",Rect2i(10,8,3,3)],["machine",Rect2i(1,10,3,2)],["machine",Rect2i(5,10,2,2)],
		["console",Rect2i(2,7,2,1)],["console",Rect2i(5,7,2,1)],["console",Rect2i(8,7,2,1)],
		["bed",Rect2i(1,1,2,3)],["bed",Rect2i(4,1,2,3)],["cabinet",Rect2i(10,1,3,1)],["table",Rect2i(10,4,2,1)]],
		"sites":[["bed",Vector2i(3,3)],["ship_storage",Vector2i(11,2)],["diagnostics",Vector2i(8,10)]],
		"work":[Vector2i(8,9),Vector2i(9,11),Vector2i(7,10)]}

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
		["hall",Rect2i(5,1,1,4)],["bathroom",Rect2i(7,1,3,3)],["living",Rect2i(1,6,5,4)],["kitchen",Rect2i(7,6,3,4)]],
		"doors":[["bedroom","hall",Vector2i(4,3)],["bathroom","hall",Vector2i(6,3)],["hall","living",Vector2i(5,5)],["living","kitchen",Vector2i(6,8)]],
		"entry":Vector2i(5,9),"exit":Vector2i(5,10),"furniture":[
		["bed",Rect2i(1,1,2,2)],["bookshelf",Rect2i(3,1,1,1)],
		["toilet",Rect2i(7,1,1,1)],["sink",Rect2i(8,1,1,1)],["bath",Rect2i(9,1,1,2)],
		["kitchen",Rect2i(7,6,3,1)],["sofa",Rect2i(1,7,2,1)],
		["table",Rect2i(2,8,2,1)],["chair",Rect2i(1,8,1,1)],["radio",Rect2i(1,6,1,1)],
		["rug",Rect2i(3,7,3,3)],["tools",Rect2i(1,9,2,1)],["art",Rect2i(2,0,1,1)]],
		"sites":[["bed",Vector2i(3,2)],["radio",Vector2i(2,6)]],
		"work":[Vector2i(3,6),Vector2i(7,8),Vector2i(4,9)]}

static func _tower() -> Dictionary:
	return {"size":Vector2i(9,11),"areas":[["bedroom",Rect2i(1,1,2,3)],
		["hall",Rect2i(4,1,1,4)],["bathroom",Rect2i(6,1,2,3)],["study",Rect2i(1,6,4,4)],["kitchen",Rect2i(6,6,2,4)]],
		"doors":[["bedroom","hall",Vector2i(3,3)],["bathroom","hall",Vector2i(5,3)],["hall","study",Vector2i(4,5)],["study","kitchen",Vector2i(5,8)]],
		"entry":Vector2i(4,9),"exit":Vector2i(4,10),"furniture":[
		["bed",Rect2i(1,1,1,2)],["toilet",Rect2i(6,1,1,1)],["sink",Rect2i(6,2,1,1)],["bath",Rect2i(7,1,1,2)],
		["bookshelf",Rect2i(1,6,2,1)],["kitchen",Rect2i(6,6,2,1)],["sofa",Rect2i(1,7,2,1)],
		["table",Rect2i(4,7,1,1)],["rug",Rect2i(3,7,2,3)],["telescope",Rect2i(1,9,1,1)],
		["radio",Rect2i(7,9,1,1)],["art",Rect2i(1,0,1,1)]],
		"sites":[["bed",Vector2i(2,3)],["radio",Vector2i(6,9)]],
		"work":[Vector2i(4,6),Vector2i(4,8),Vector2i(3,9)]}

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
