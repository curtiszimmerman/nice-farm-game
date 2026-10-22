extends RefCounted

# Each stop gives the departure time, destination tile, and whether it is bedtime.
const ROUTINES = {
	"astronomer":[[0,31,14,false,"observatory"],[420,31,14,true,"observatory"],[840,31,14,false,"observatory"],[1020,35,16,false],[1080,31,14,false,"observatory"]],
	"moss":[[0,26,58,true],[360,26,58,false,"moss"],[420,25,59,false],[720,26,58,false,"moss"],[810,31,61,false],[1080,26,58,false,"moss"],[1320,26,58,true]],
	"tavi":[[0,84,54,true],[390,84,54,false,"tavi"],[435,60,45,false],[480,72,45,false,"store"],[750,63,48,false],[780,72,45,false,"store"],[1200,60,48,false],[1245,63,45,false],[1290,84,54,false,"tavi"],[1320,84,54,true]],
	"iona":[[0,65,14,false],[180,61,15,false],[300,61,15,true],[720,61,15,false],[810,65,14,false],[900,60,45,false],[1020,32,47,false],[1170,63,48,false],[1230,61,15,false]],
	"finch":[[0,57,63,true],[390,57,63,false,"finch"],[420,60,48,false],[480,54,38,false,"radio"],[720,60,45,false],[780,54,38,false,"radio"],[1050,63,48,false],[1170,57,63,false,"finch"],[1350,57,63,true]],
	"mayor":[[0,61,35,true],[420,61,35,false,"mayor"],[480,54,46,false,"hall"],[720,60,45,false],[780,54,46,false,"hall"],[1050,63,48,false],[1200,61,35,false,"mayor"],[1380,61,35,true]],
	"vale":[[0,11,14,false]],
	"veteran":[[0,42,80,true],[390,42,80,false,"veteran"],[480,42,83,false],[720,42,80,false,"veteran"],[840,39,81,false],[1080,42,80,false,"veteran"],[1320,42,80,true]],
	"assistant":[[0,86,63,true],[420,86,63,false,"assistant"],[480,54,46,false,"hall"],[720,63,48,false],[780,54,46,false,"hall"],[1080,86,63,false,"assistant"],[1350,86,63,true]],
	"keeper":[[0,-24,51,true],[390,-24,51,false,"keeper"],[690,-19,53,false],[780,-24,51,false,"keeper"],[1080,-21,51,false],[1200,-24,51,false,"keeper"],[1380,-24,51,true]],
	"farmer_mother":[[0,103,47,true,"reed_farm"],[390,103,47,false,"reed_farm"],[450,99,52,false],[720,103,47,false,"reed_farm"],[810,108,54,false],[1080,60,48,false],[1170,103,47,false,"reed_farm"],[1320,103,47,true,"reed_farm"]],
	"farmer_father":[[0,103,47,true,"reed_farm"],[360,103,47,false,"reed_farm"],[420,102,54,false],[720,103,47,false,"reed_farm"],[780,107,51,false],[1080,75,65,false,"bakery"],[1170,103,47,false,"reed_farm"],[1350,103,47,true,"reed_farm"]],
	"farmer_son":[[0,103,47,true,"reed_farm"],[420,103,47,false,"reed_farm"],[480,104,53,false],[720,103,47,false,"reed_farm"],[810,61,49,false],[930,110,55,false],[1110,103,47,false,"reed_farm"],[1260,103,47,true,"reed_farm"]],
	"smith":[[0,79,48,true,"smithy"],[390,79,48,false,"smithy"],[450,79,48,false,"smithy"],[750,63,48,false],[795,79,48,false,"smithy"],[1110,69,38,false,"tavern"],[1230,79,48,false,"smithy"],[1380,79,48,true,"smithy"]],
	"miller":[[0,99,31,true,"mill_home"],[390,99,31,false,"mill_home"],[450,90,29,false,"windmill"],[720,99,31,false,"mill_home"],[780,90,29,false,"windmill"],[1080,69,38,false,"tavern"],[1230,99,31,false,"mill_home"],[1350,99,31,true,"mill_home"]],
	"miller_wife":[[0,99,31,true,"mill_home"],[390,99,31,false,"mill_home"],[480,90,29,false,"windmill"],[750,60,45,false],[810,90,29,false,"windmill"],[1110,99,31,false,"mill_home"],[1320,99,31,true,"mill_home"]],
	"miller_daughter":[[0,99,31,true,"mill_home"],[420,99,31,false,"mill_home"],[480,90,29,false,"windmill"],[720,99,31,false,"mill_home"],[810,54,38,false,"radio"],[1080,99,31,false,"mill_home"],[1320,99,31,true,"mill_home"]],
	"barkeep":[[0,69,38,true,"tavern"],[480,69,38,false,"tavern"],[570,75,65,false,"bakery"],[630,69,38,false,"tavern"],[1380,69,38,true,"tavern"]],
	"baker":[[0,75,65,true,"bakery"],[300,75,65,false,"bakery"],[720,60,48,false],[780,75,65,false,"bakery"],[1110,69,38,false,"tavern"],[1230,75,65,false,"bakery"],[1320,75,65,true,"bakery"]],
	"woodcutter":[[0,29,79,true],[390,29,79,false,"woodcutter"],[450,32,82,false],[720,29,79,false,"woodcutter"],[810,25,82,false],[1080,29,79,false,"woodcutter"],[1320,29,79,true]]
}

static func home_stop(id: String) -> Dictionary:
	var home=ROUTINES[id][0]
	for entry in ROUTINES[id]:
		if entry[3]:
			home=entry
			break
	return {"cell":Vector2i(home[1],home[2]),"sleeping":true,"room":home[4] if home.size()>4 else "ship" if id=="vale" else id}

static func stop(id: String,minute: float) -> Dictionary:
	var chosen=ROUTINES[id][0]
	for entry in ROUTINES[id]:
		if minute>=entry[0]: chosen=entry
	var stop={"cell":Vector2i(chosen[1],chosen[2]),"sleeping":chosen[3],"room":chosen[4] if chosen.size()>4 else id if chosen[3] else ""}
	if id=="moss" and ((minute>=420 and minute<720) or (minute>=810 and minute<1080)):
		stop.cell=[Vector2i(25,62),Vector2i(27,64),Vector2i(31,64),Vector2i(29,67),Vector2i(25,66)][int(minute/30)%5]
	if id in ["farmer_mother","farmer_father","farmer_son"] and stop.room=="" and stop.cell.x>95 and minute<1110:
		var rounds={"farmer_mother":[Vector2i(99,51),Vector2i(101,53),Vector2i(103,55)],"farmer_father":[Vector2i(107,51),Vector2i(109,53),Vector2i(110,55)],"farmer_son":[Vector2i(104,50),Vector2i(105,53),Vector2i(104,56)]}
		stop.cell=rounds[id][int(minute/30)%3]
	return stop
