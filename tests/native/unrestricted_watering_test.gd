extends SceneTree
const State=preload("res://state.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void:
	var s=State.new()
	preload("fixture.gd").tools(s)
	s.assign_active("primary","watering_can")
	var energy=s.energy
	s.farm(0)
	check(s.plots[0].watered and not s.plots[0].tilled and s.energy==energy-1 and s.water==19,"the watering can waters untilled bare ground")
	s.assign_active("primary","hoe")
	s.farm(0)
	check(s.plots[0].watered and s.plots[0].tilled,"tilling preserves water already on a plot")
	s.assign_active("primary","seeds")
	s.farm(0)
	check(s.plots[0].planted>=0 and s.plots[0].watered,"seeds can be planted into previously watered ground")
	s.assign_active("primary","watering_can")
	var water=s.water
	s.farm(0)
	check(s.water==water-1,"watering remains available even on an already wet planted plot")
	s.advance(1440-s.minute)
	check(s.plots[0].growth==1440,"pre-watered planting earns its midnight growth credit")
	s.plots[0].growth=s.CROP_MINUTES
	water=s.water
	s.farm(0)
	check(s.ripe(0) and s.water==water-1,"mature plants can also be watered without harvesting them")
	s.water=0
	energy=s.energy
	s.farm(1)
	check(not s.plots[1].watered and s.energy==energy,"an empty can cannot water bare ground or spend energy")
	quit(1 if failed else 0)
