extends SceneTree
const State=preload("res://state.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void:
	var s=State.new()
	s.weather_override="sunny"
	s.plots=[{"x":12,"y":53,"tilled":true,"planted":0.0,"watered":false,"crop":"turnips","growth":0.0,"water_day":0}]
	s.advance(2880)
	check(s.plots.is_empty() or (s.plots[0].planted<0 and s.plots[0].growth<0),"two consecutive dry days wither and kill an unwatered crop")
	var watered=State.new()
	watered.weather_override="sunny"
	watered.minute=1439
	watered.plots=[{"x":12,"y":53,"tilled":true,"planted":0.0,"watered":true,"crop":"turnips","growth":0.0,"water_day":1}]
	watered.advance(1)
	check(watered.plots[0].growth==1440 and not watered.plots[0].watered,"a watered day earns one growth day at midnight and dries")
	if watered.has_method("plot_moisture"):
		check(is_zero_approx(watered.plot_moisture(0)),"yesterday's water is visibly dry at midnight")
		watered.advance(180)
		check(is_zero_approx(watered.plot_moisture(0)),"old water stays dry overnight")
		watered.advance(180)
		check(watered.plot_moisture(0)==0,"soil is dry again at sunrise")
	var growing=State.new()
	growing.weather_override="sunny"
	growing.plots=[{"x":12,"y":53,"tilled":true,"planted":0.0,"watered":false,"crop":"turnips","growth":0.0,"water_day":0}]
	for _day in range(3):
		growing.plots[0].watered=true
		growing.plots[0].water_day=growing.day
		growing.advance(1440)
	check(growing.ripe(0),"three consecutive watered midnights mature a crop")
	quit(1 if failed else 0)
