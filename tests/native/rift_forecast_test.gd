extends SceneTree
const Faith=preload("res://weekday_magic.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void:
	var previous=0
	for day in range(2,9):
		var correct=0
		for world_seed in range(500):
			var prediction=Faith.forecast(day,world_seed)
			var truth=Faith.chaos(8,world_seed)
			if prediction.omen==truth: correct+=1
			if world_seed==0: check(prediction.target_day==8 and prediction.days_until==8-day,"forecast identifies its target day")
		check(correct>=previous,"forecast accuracy increases toward Rift")
		var expected=1.0 if day==8 else 0.6+0.05*(day-2)
		check(absf(float(correct)/500-expected)<0.07,"forecast accuracy matches the daily confidence")
		previous=correct
	check(previous==500,"Rift itself is certain")
	quit(1 if failed else 0)
