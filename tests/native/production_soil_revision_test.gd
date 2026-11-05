extends SceneTree
const State=preload("res://state.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void:
	var s=State.new()
	s.pot=1
	s.berries=200
	s.sugar=100
	var cooked=0
	while s.cook("berry_preserves"): cooked+=1
	check(cooked==100 and s.berry_preserves==100 and s.berries==0 and s.sugar==0,"preserves production is limited only by available ingredients")
	s=State.new()
	s.weather_override="sunny"
	preload("fixture.gd").garden(s)
	for plot in s.plots: plot.tilled=true
	s.advance(4320)
	check(s.plots.is_empty(),"unattended empty soil returns to grass within three days")
	var motion=preload("res://tool_motion.gd")
	var pose=motion.pose("hoe","right",0.5)
	check((pose.tip*pose.scale).rotated(pose.angle).y>0,"the hoe blade points down into the ground with its handle up")
	quit(1 if failed else 0)
