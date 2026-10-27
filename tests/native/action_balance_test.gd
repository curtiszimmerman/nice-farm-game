extends SceneTree
const State=preload("res://state.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void:
	var s=State.new()
	check(s.plots.is_empty(),"new farms start as grass without predefined plots")
	s.hoe=1
	s.watering_can=1
	s.seeds=20
	s.assign_active("primary","watering_can")
	s.refill_water()
	for i in range(20):
		s.assign_active("primary","hoe")
		check(s.prepare_plot(Vector2i(8+i%10,51+int(i/10))),"clear southern ground can be tilled")
		s.assign_active("primary","seeds")
		s.farm(i)
		s.assign_active("primary","watering_can")
		s.farm(i)
	for i in range(18): s.spend_energy(2)
	for i in range(5): s.spend_energy(0.4); s.spend_energy(1)
	check(is_equal_approx(s.energy,10.8),"the day-one activity budget leaves 10.8 energy for mistakes")
	s=State.new()
	s.money=999
	check(not s.buy_sword(),"Dain requires the full thousand crowns")
	s.money=1000
	check(s.buy_sword() and s.money==0,"Dain sells the sword for one thousand crowns")
	quit(1 if failed else 0)
