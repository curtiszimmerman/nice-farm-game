extends RefCounted

# Each stop gives the departure time, destination tile, and whether it is bedtime.
const ROUTINES = {
	"moss":[[0,26,58,true],[360,26,58,false],[420,20,43,false],[720,60,48,false],[810,20,43,false],[1080,26,58,false],[1320,26,58,true]],
	"tavi":[[0,67,51,true],[390,67,51,false],[405,63,48,false],[440,60,45,false],[460,64,46,false],[750,63,48,false],[780,64,46,false],[1200,60,48,false],[1245,63,45,false],[1290,67,51,false],[1320,67,51,true]],
	"iona":[[0,65,14,false],[180,61,15,false],[300,61,15,true],[720,61,15,false],[810,65,14,false],[900,60,45,false],[1020,32,47,false],[1170,63,48,false],[1230,61,15,false]],
	"finch":[[0,60,54,true],[390,60,54,false],[420,60,48,false],[480,54,38,false],[720,60,45,false],[780,54,38,false],[1050,63,48,false],[1170,60,54,false],[1350,60,54,true]],
	"mayor":[[0,61,42,true],[420,61,42,false],[480,54,46,false],[720,60,45,false],[780,54,46,false],[1050,63,48,false],[1200,61,42,false],[1380,61,42,true]],
	"vale":[[0,6,8,false]]
}

static func stop(id: String,minute: float) -> Dictionary:
	var chosen=ROUTINES[id][0]
	for entry in ROUTINES[id]:
		if minute>=entry[0]: chosen=entry
	return {"cell":Vector2i(chosen[1],chosen[2]),"sleeping":chosen[3]}
