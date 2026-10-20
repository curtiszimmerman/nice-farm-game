extends RefCounted

# Each stop gives the departure time, destination tile, and whether it is bedtime.
const ROUTINES = {
	"moss":[[0,26,58,true],[360,26,58,false,"moss"],[420,25,59,false],[720,26,58,false,"moss"],[810,31,61,false],[1080,26,58,false,"moss"],[1320,26,58,true]],
	"tavi":[[0,67,51,true],[390,67,51,false],[405,63,48,false],[440,60,45,false],[460,64,46,false],[750,63,48,false],[780,64,46,false],[1200,60,48,false],[1245,63,45,false],[1290,67,51,false],[1320,67,51,true]],
	"iona":[[0,65,14,false],[180,61,15,false],[300,61,15,true],[720,61,15,false],[810,65,14,false],[900,60,45,false],[1020,32,47,false],[1170,63,48,false],[1230,61,15,false]],
	"finch":[[0,60,54,true],[390,60,54,false,"finch"],[420,60,48,false],[480,54,38,false,"radio"],[720,60,45,false],[780,54,38,false,"radio"],[1050,63,48,false],[1170,60,54,false,"finch"],[1350,60,54,true]],
	"mayor":[[0,61,42,true],[420,61,42,false,"mayor"],[480,54,46,false,"hall"],[720,60,45,false],[780,54,46,false,"hall"],[1050,63,48,false],[1200,61,42,false,"mayor"],[1380,61,42,true]],
	"vale":[[0,11,14,false]],
	"veteran":[[0,42,80,true],[390,42,80,false,"veteran"],[480,43,82,false],[720,42,80,false,"veteran"],[840,39,81,false],[1080,42,80,false,"veteran"],[1320,42,80,true]],
	"assistant":[[0,72,56,true],[420,72,56,false,"assistant"],[480,54,46,false,"hall"],[720,63,48,false],[780,54,46,false,"hall"],[1080,72,56,false,"assistant"],[1350,72,56,true]]
}

static func home_stop(id: String) -> Dictionary:
	var home=ROUTINES[id][0]
	for entry in ROUTINES[id]:
		if entry[3]:
			home=entry
			break
	return {"cell":Vector2i(home[1],home[2]),"sleeping":true,"room":"ship" if id=="vale" else id}

static func stop(id: String,minute: float) -> Dictionary:
	var chosen=ROUTINES[id][0]
	for entry in ROUTINES[id]:
		if minute>=entry[0]: chosen=entry
	var stop={"cell":Vector2i(chosen[1],chosen[2]),"sleeping":chosen[3],"room":chosen[4] if chosen.size()>4 else id if chosen[3] else ""}
	if id=="moss" and ((minute>=420 and minute<720) or (minute>=810 and minute<1080)):
		stop.cell=[Vector2i(25,59),Vector2i(27,61),Vector2i(31,61),Vector2i(29,64),Vector2i(25,63)][int(minute/30)%5]
	return stop
