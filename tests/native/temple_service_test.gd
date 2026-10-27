extends SceneTree
const Schedule=preload("res://villager_schedule.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void:
	check(Schedule.stop("moss",600,7).room=="temple" and Schedule.stop("moss",710,7).room=="temple","neighbors spend two hours at Veil morning communion")
	check(Schedule.stop("moss",720,7).room!="temple" and Schedule.stop("moss",600,6).room!="temple","communion ends at noon and only occurs on the seventh day")
	check(Schedule.stop("priest",600,7).room=="temple","the priest is present to lead communion")
	quit(1 if failed else 0)
