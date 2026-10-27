extends RefCounted

# Each stop gives the departure time, destination tile, and whether it is bedtime.
const ROUTINES = {
	"priest":[[0,45,57,true,"priest"],[360,45,57,false,"priest"],[420,53,57,false,"temple"],[720,58,55,false],[780,53,57,false,"temple"],[1260,45,57,false,"priest"],[1320,45,57,true,"priest"]],
	"astronomer":[[0,31,14,false,"observatory"],[420,31,14,true,"observatory"],[840,31,14,false,"observatory"],[1020,35,16,false],[1080,31,14,false,"observatory"]],
	"moss":[[0,26,58,true],[360,26,58,false,"moss"],[420,25,59,false],[720,26,58,false,"moss"],[810,31,61,false],[1080,26,58,false,"moss"],[1320,26,58,true]],
	"tavi":[[0,84,54,true],[390,84,54,false,"tavi"],[435,60,45,false],[480,72,45,false,"store"],[750,63,48,false],[780,72,45,false,"store"],[1200,60,48,false],[1245,63,45,false],[1290,84,54,false,"tavi"],[1320,84,54,true]],
	"iona":[[0,61,15,false,"iona"],[300,61,15,true,"iona"],[720,61,49,false],[900,61,15,false,"iona"]],
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

const SLEEP={"baker":[1320,240],"farmer_father":[1320,360],"farmer_mother":[1320,390],"farmer_son":[1320,420],"moss":[1320,360],"miller":[1350,390],"miller_wife":[1320,390],"miller_daughter":[1350,420],"smith":[1350,390],"finch":[1380,420],"mayor":[1350,420],"assistant":[1380,420],"tavi":[1380,420],"keeper":[1320,390],"veteran":[1320,390],"woodcutter":[1320,360],"astronomer":[1380,420],"vale":[1320,420],"barkeep":[1440,480],"priest":[1320,360]}
const COMMUNION=["moss","mayor","miller_wife","farmer_mother","keeper","veteran"]
const TAVERN_DAYS={"baker":[0,2],"moss":[0,2,4,6],"miller":[0,1,2,3,4,6],"miller_wife":[1,4,6],"miller_daughter":[2,5],"smith":[0,1,3,4,5],"finch":[0,2,4,6],"mayor":[1,3,5],"assistant":[3],"tavi":[0,2,4,6],"keeper":[2],"veteran":[1,4],"woodcutter":[0,3,5,6],"farmer_mother":[1,5],"farmer_father":[0,2,4,6],"farmer_son":[5],"astronomer":[1,4,6]}

static func observations_closed(day: int,minute: float) -> bool:
	var weekday=posmod(day-1,7)
	return weekday==0 or (weekday==6 and minute>=1380) or (weekday==1 and minute<420)

static func stop(id: String,minute: float,day: int=1) -> Dictionary:
	if id=="astronomer" and posmod(day-1,7)==0:
		return {"cell":Vector2i(31,14),"room":"observatory","sleeping":minute<420 or minute>=1380}
	var chosen=ROUTINES[id][0]
	for entry in ROUTINES[id]:
		if minute>=entry[0]: chosen=entry
	var stop={"cell":Vector2i(chosen[1],chosen[2]),"sleeping":chosen[3],"room":chosen[4] if chosen.size()>4 else id if chosen[3] else ""}
	if id=="moss" and ((minute>=420 and minute<720) or (minute>=810 and minute<1080)):
		stop.cell=[Vector2i(25,62),Vector2i(27,64),Vector2i(31,64),Vector2i(29,67),Vector2i(25,66)][int(minute/30)%5]
	if id in ["farmer_mother","farmer_father","farmer_son"] and stop.room=="" and stop.cell.x>95 and minute<1110:
		var rounds={"farmer_mother":[Vector2i(99,51),Vector2i(101,53),Vector2i(103,55)],"farmer_father":[Vector2i(107,51),Vector2i(109,53),Vector2i(110,55)],"farmer_son":[Vector2i(104,50),Vector2i(105,53),Vector2i(104,56)]}
		stop.cell=rounds[id][int(minute/30)%3]
	if id=="iona":
		if posmod(day-1,7) in [2,5] and minute>=1140 and minute<1320: return {"cell":Vector2i(69,38),"room":"tavern","sleeping":false}
		return stop
	var hours=SLEEP.get(id,[1320,420])
	if minute<hours[1] or minute>=hours[0]: return home_stop(id)
	if stop.sleeping:
		stop=home_stop(id)
		stop.sleeping=false
	if id in ["tavi","smith","baker"] and minute>=hours[1] and minute<1140 and not (id=="tavi" and minute>=750 and minute<780):
		stop={"cell":home_stop(id).cell if id!="tavi" else Vector2i(72,45),"room":{"tavi":"store","smith":"smithy","baker":"bakery"}[id],"sleeping":false}
	if posmod(day-1,7)==6 and minute>=600 and minute<720 and (id in COMMUNION or id=="priest"):
		return {"cell":Vector2i(53,57),"room":"temple","sleeping":false}
	if id=="priest": return stop
	if minute<1140 and stop.room=="tavern":
		stop=home_stop(id)
		stop.sleeping=false
	if id=="barkeep": return {"cell":Vector2i(69,38),"room":"tavern","sleeping":false}
	if minute>=1140:
		var end=1260 if id=="baker" else 1320
		if id in TAVERN_DAYS and posmod(day-1,7) in TAVERN_DAYS[id] and minute<end:
			return {"cell":Vector2i(69,38),"room":"tavern","sleeping":false}
		stop=home_stop(id)
		stop.sleeping=false
	return stop
