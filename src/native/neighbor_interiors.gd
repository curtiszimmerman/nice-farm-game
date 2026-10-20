extends RefCounted

static func layout(id: String) -> Dictionary:
	if id in ["reed_farm","mill_home"]:
		var family=family_home(id=="reed_farm")
		if id=="reed_farm":
			family.areas[3][1]=Rect2i(1,6,7,4)
			family.areas.append(["mudroom",Rect2i(1,11,7,3)])
			family.doors[2][2]=Vector2i(8,8)
			family.doors.append(["mudroom","hall",Vector2i(8,12)])
			for item in family.furniture:
				if item[0]=="rug": item[1]=Rect2i(2,7,4,2)
			family.furniture.append(["tools",Rect2i(6,11,1,2)])
		return family
	if id=="windmill": return {"size":Vector2i(12,12),"areas":[["grinding",Rect2i(1,1,10,6)],["packing",Rect2i(1,8,6,3)],["bathroom",Rect2i(8,8,3,3)]],"doors":[["grinding","packing",Vector2i(6,7)],["bathroom","packing",Vector2i(7,9)]],"entry":Vector2i(6,10),"exit":Vector2i(6,11),"furniture":[["machine",Rect2i(4,2,3,3)],["flour",Rect2i(1,1,2,1)],["flour",Rect2i(9,4,2,1)],["table",Rect2i(1,8,3,1)],["tools",Rect2i(5,9,1,2)],["toilet",Rect2i(8,8,1,1)],["sink",Rect2i(10,8,1,1)]],"sites":[],"work":[Vector2i(3,3),Vector2i(8,4),Vector2i(4,9)]}
	if id not in ["smithy","tavern","bakery"]: return {}
	var width={"smithy":16,"tavern":19,"bakery":17}[id]
	var depth={"smithy":14,"tavern":15,"bakery":13}[id]
	var plan={"size":Vector2i(width,depth),"areas":[["bedroom",Rect2i(1,1,5,4)],["hall",Rect2i(7,1,1,depth-2)],["bathroom",Rect2i(9,1,width-10,3)],["living",Rect2i(1,6,5,depth-7)],[id,Rect2i(9,5,width-10,depth-6)]],"doors":[["bedroom","hall",Vector2i(6,3)],["bathroom","hall",Vector2i(8,2)],["living","hall",Vector2i(6,8)],[id,"hall",Vector2i(8,9)]],"entry":Vector2i(7,depth-2),"exit":Vector2i(7,depth-1),"furniture":[["bed",Rect2i(1,1,2,3)],["bookshelf",Rect2i(4,1,2,1)],["kitchen",Rect2i(1,6,4,1)],["radio",Rect2i(5,depth-2,1,1)],["sofa",Rect2i(1,depth-3,3,1)],["toilet",Rect2i(9,1,1,1)],["sink",Rect2i(11,1,1,1)],["bath",Rect2i(width-2,1,1,2)]],"sites":[["radio",Vector2i(4,depth-2)]],"work":[]}
	match id:
		"smithy":
			plan.furniture.append_array([["forge",Rect2i(10,5,3,2)],["anvil",Rect2i(11,9,1,1)],["tools",Rect2i(14,7,1,2)],["table",Rect2i(9,12,3,1)]])
			plan.work=[Vector2i(10,9),Vector2i(12,7),Vector2i(13,10)]
		"tavern":
			plan.areas[2][1]=Rect2i(9,1,3,3)
			plan.areas.append(["pantry",Rect2i(13,1,5,3)])
			plan.doors.append(["pantry","tavern",Vector2i(15,4)])
			plan.furniture=plan.furniture.filter(func(item):return item[0]!="bath")
			plan.furniture.append_array([["table",Rect2i(10,7,6,1)],["barrels",Rect2i(15,5,2,1)],["table",Rect2i(10,10,2,1)],["chair",Rect2i(9,10,1,1)],["table",Rect2i(15,11,2,1)],["chair",Rect2i(17,11,1,1)],["rug",Rect2i(13,9,2,4)]])
			plan.work=[Vector2i(12,6),Vector2i(16,8),Vector2i(14,9)]
		"bakery":
			plan.areas[0][1]=Rect2i(9,1,7,4)
			plan.areas[2][1]=Rect2i(1,1,5,4)
			plan.areas[4][1]=Rect2i(9,6,7,6)
			plan.doors[0][2]=Vector2i(8,3)
			plan.doors[1][2]=Vector2i(6,2)
			for item in plan.furniture:
				if item[0]=="bed": item[1]=Rect2i(12,1,2,3)
				elif item[0]=="bookshelf": item[1]=Rect2i(9,1,2,1)
				elif item[0]=="toilet": item[1]=Rect2i(1,1,1,1)
				elif item[0]=="sink": item[1]=Rect2i(3,1,1,1)
				elif item[0]=="bath": item[1]=Rect2i(5,1,1,2)
			plan.furniture.append_array([["oven",Rect2i(9,6,2,2)],["table",Rect2i(12,7,3,1)],["flour",Rect2i(13,6,2,1)],["table",Rect2i(9,10,1,1)],["chair",Rect2i(10,10,1,1)],["bookshelf",Rect2i(15,9,1,2)]])
			plan.work=[Vector2i(11,6),Vector2i(13,8),Vector2i(12,10)]
	return plan

static func family_home(farm: bool) -> Dictionary:
	var h=15 if farm else 14
	var w=18 if farm else 16
	var hall=9 if farm else 7
	var left=hall-2
	var right=hall+2
	return {"size":Vector2i(w,h),"areas":[["parents",Rect2i(1,1,left,4)],["child",Rect2i(right,1,w-right-1,4)],["hall",Rect2i(hall,1,1,h-2)],["living",Rect2i(1,6,left,h-7)],["kitchen",Rect2i(right,6,w-right-1,3)],["bathroom",Rect2i(right,10,w-right-1,h-11)]],"doors":[["parents","hall",Vector2i(hall-1,3)],["child","hall",Vector2i(hall+1,3)],["living","hall",Vector2i(hall-1,9)],["kitchen","hall",Vector2i(hall+1,7)],["bathroom","hall",Vector2i(hall+1,11)]],"entry":Vector2i(hall,h-2),"exit":Vector2i(hall,h-1),
		"furniture":[["bed",Rect2i(1,1,2,3)],["bed",Rect2i(left-1,1,2,3)],["bed",Rect2i(w-4,1,2,3)],["desk",Rect2i(right,1,2,1)],["radio",Rect2i(right,4,1,1)],["kitchen",Rect2i(right,6,w-right-1,1)],["table",Rect2i(right+1,8,2,1)],["sofa",Rect2i(1,6,3,1)],["bookshelf",Rect2i(1,h-3,1,2)],["table",Rect2i(3,9,2,1)],["rug",Rect2i(2,8,3,4)],["toilet",Rect2i(right,10,1,1)],["sink",Rect2i(right+2,10,1,1)],["bath",Rect2i(w-2,10,1,2)]],"sites":[["radio",Vector2i(right+1,4)]],"work":[Vector2i(3,8),Vector2i(right+1,7),Vector2i(right+1,2)],"beds":{"farmer_mother":0,"farmer_father":1,"farmer_son":2} if farm else {"miller":0,"miller_wife":1,"miller_daughter":2}}
