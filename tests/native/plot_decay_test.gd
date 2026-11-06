extends SceneTree
const State=preload("res://state.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")

# A farm with one planted, watered plot at a fixed world seed and dry weather.
func planted_farm(seed_value: int) -> RefCounted:
	var s=State.new()
	s.world_seed=seed_value
	s.weather_override="sunny"
	preload("fixture.gd").tools(s)
	s.tend(0)
	s.tend(0)
	return s

func nights(s: RefCounted,count: int) -> void:
	for i in range(count): s.advance(1440.0)

func run() -> void:
	# The decay threshold for each plot comes from the world seed, so several seeds cover every case.
	var seeds=range(1,9)
	var ripe_waits=seeds.all(func(seed_value):
		var s=planted_farm(seed_value)
		s.plots[0].growth=s.crop_minutes(s.plots[0].crop)
		nights(s,5)
		return not s.plots.is_empty() and s.plot_cell(0)==Vector2i(9,54) and s.ripe(0))
	check(ripe_waits,"a ripe crop waits through dry nights until it is harvested")
	var withered_keeps_plot=seeds.all(func(seed_value):
		var s=planted_farm(seed_value)
		for night in range(4):
			nights(s,1)
			var plot=s.plots.filter(func(p):return p.x==9 and p.y==54)
			if plot.is_empty(): return false
			if plot[0].planted<0: return true
		return false)
	check(withered_keeps_plot,"an unwatered growing crop withers but leaves its tilled plot behind")
	var empty_reverts=seeds.all(func(seed_value):
		var s=planted_farm(seed_value)
		nights(s,6)
		return not s.plots.any(func(plot):return plot.x==9 and plot.y==54))
	check(empty_reverts,"an empty plot goes back to grass after a few idle nights")
	quit(1 if failed else 0)
