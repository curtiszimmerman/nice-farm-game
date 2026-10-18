extends RefCounted

# Each stop gives the departure time, destination tile, and whether it is bedtime.
const ROUTINES = {
	"moss":[[0,30,36,true],[360,30,36,false],[420,27,21,false],[720,40,23,false],[810,27,21,false],[1080,30,36,false],[1320,30,36,true]],
	"tavi":[[0,47,26,true],[390,47,26,false],[405,43,23,false],[440,40,20,false],[460,44,21,false],[750,43,23,false],[780,44,21,false],[1200,40,23,false],[1245,43,20,false],[1290,47,26,false],[1320,47,26,true]],
	"iona":[[0,45,9,false],[240,41,11,false],[300,41,11,true],[720,41,11,false],[810,45,9,false],[900,40,20,false],[1020,32,26,false],[1170,43,23,false],[1320,41,11,false]],
	"finch":[[0,40,29,true],[390,40,29,false],[420,40,23,false],[480,34,13,false],[720,40,20,false],[780,34,13,false],[1050,43,23,false],[1170,40,29,false],[1350,40,29,true]],
	"mayor":[[0,41,17,true],[420,41,17,false],[480,34,21,false],[720,40,20,false],[780,34,21,false],[1050,43,23,false],[1200,41,17,false],[1380,41,17,true]],
	"vale":[[0,10,10,false]]
}

static func stop(id: String,minute: float) -> Dictionary:
	var chosen=ROUTINES[id][0]
	for entry in ROUTINES[id]:
		if minute>=entry[0]: chosen=entry
	return {"cell":Vector2i(chosen[1],chosen[2]),"sleeping":chosen[3]}
