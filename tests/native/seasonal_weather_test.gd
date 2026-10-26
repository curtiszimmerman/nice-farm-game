extends SceneTree
const Weather=preload("res://weather.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void:
	var counts=[0,0,0,0]
	var snowstorms=0
	for seed_value in range(500):
		for season in range(4):
			var day=season*28+2
			if Weather.for_day(seed_value,day)=="rainy":
				counts[season]+=1
				if season==3 and Weather.thundersnow(seed_value,day): snowstorms+=1
	check(counts[0]>counts[1]*1.25 and counts[2]<counts[1]*0.75,"spring is wetter and autumn drier than summer")
	check(snowstorms>0 and snowstorms<counts[3]*0.2,"only a rare fraction of winter snow days permit thunder")
	check(not Weather.thundersnow(1,2),"summer weather cannot create a winter sparkbloom day")
	quit(1 if failed else 0)
