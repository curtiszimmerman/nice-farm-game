extends SceneTree
const Schedule=preload("res://villager_schedule.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void:
	check(not Schedule.observations_closed(7,1379),"Saeren's extended closure starts when he goes to bed before Rift")
	check(Schedule.observations_closed(7,1380),"the observatory closes at bedtime before Rift")
	for minute in [0,420,720,1140,1439]:
		check(Schedule.observations_closed(8,minute),"the observatory remains closed throughout Rift")
	check(Schedule.observations_closed(9,419),"the observatory stays closed until Saeren wakes the following day")
	check(not Schedule.observations_closed(9,420),"the observatory reopens when Saeren wakes after Rift")
	check(not Schedule.observations_closed(4,900),"ordinary afternoons do not inherit Rift's closure")
	quit(1 if failed else 0)
