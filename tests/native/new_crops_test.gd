extends SceneTree
const State=preload("res://state.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void:
	var s=State.new()
	if not s.get_property_list().any(func(p):return p.name=="green_onion_seeds"):
		check(false,"the new crops are available")
		quit(1)
		return
	for recipe in [["green_onion_seeds","green_onions",6,0],["tomato_seeds","tomatoes",6,3],["cucumber_seeds","cucumbers",4,4],["gladain_seeds","gladain",14,0]]:
		s=State.new()
		s.hoe=1
		s.sickle=1
		s.set(recipe[0],2)
		preload("fixture.gd").garden(s)
		s.plots[0].tilled=true
		s.selected_seed=recipe[0]
		s.tend(0)
		for day in range(recipe[2]):
			s.plots[0].watered=true
			s.plots[0].water_day=s.day
			s.advance(1440-s.minute)
			check(s.ripe(0)==(day==recipe[2]-1),"correct maturity for %s day %d" % [recipe[1],day+1])
		s.energy=100
		s.tend(0)
		check(s.get(recipe[1])==1,"harvest produces "+recipe[1])
		if recipe[3]>0:
			for day in range(recipe[3]):
				s.plots[0].watered=true
				s.plots[0].water_day=s.day
				s.advance(1440-s.minute)
				check(s.ripe(0)==(day==recipe[3]-1),"correct regrowth for %s day %d" % [recipe[1],day+1])
			var restored=State.new()
			check(restored.restore(JSON.parse_string(JSON.stringify(s.to_dict()))) and restored.ripe(0),"crop growth survives save/load: "+recipe[1])
			s.assign_active("primary","hoe")
			s.farm(0)
			check(s.plots[0].planted<0,"hoe removes repeat-harvest plants")
		s.day=28
		s.plots[0].crop=recipe[1]
		s.plots[0].planted=s.total()
		s.plots[0].growth=0
		s.plots[0].watered=true
		s.plots[0].water_day=28
		s.advance(1440-s.minute)
		check((s.plots[0].planted>=0)==(recipe[3]>0),"correct spring-to-summer survival: "+recipe[1])
		s.day=29
		s.plots.append({"x":10,"y":60,"tilled":true,"planted":-1.0,"crop":"turnips","growth":0.0,"watered":false,"water_day":0})
		s.selected_seed=recipe[0]
		s.tend(1)
		check((s.plots[1].planted>=0)==(recipe[3]>0),"correct summer planting restriction: "+recipe[1])
		s.day=56
		s.plots[0].planted=s.total()
		s.plots[0].crop=recipe[1]
		s.advance(1440-s.minute)
		check(s.plots.all(func(plot):return plot.planted<0),"crop withers at autumn: "+recipe[1])
		check(preload("res://items.gd").icon(recipe[0])!=null and preload("res://items.gd").icon(recipe[1])!=null,"seed and produce have distinct pixel icons")
		var crowns=s.money
		var value=s.sale_value()
		check(s.sell() and s.money==crowns+value and s.get(recipe[1])==0,"the new produce can be sold: "+recipe[1])
	quit(1 if failed else 0)
