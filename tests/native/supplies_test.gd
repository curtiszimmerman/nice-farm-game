extends SceneTree
const State=preload("res://state.gd")
var failed=false
func check(value: bool,label: String) -> void:
	if value: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void:
	var s=State.new()
	s.chest_transfer(0,"",1)
	s.seeds=10
	s.chest_transfer(4,"seeds",4)
	check(s.seeds==6 and s.chest[4].count==4,"deposit only the selected quantity")
	s.chest_transfer(4,"",2)
	check(s.seeds==8 and s.chest[4].count==2,"withdraw only the selected quantity")
	check(not s.chest_transfer(4,"",9),"reject quantities above the available stack")
	s.quick_slots[0]="watering_can"
	s.farm(0)
	check(not s.plots[0].tilled,"a carried hoe cannot till unless selected")
	s.quick_slots[0]="hoe"
	s.farm(0)
	check(s.plots[0].tilled and s.energy==98,"selected hoe tills at doubled energy cost")
	s.quick_slots[0]="seeds"
	s.farm(0)
	s.chest_transfer(1)
	s.quick_slots[0]="watering_can"
	s.water=0
	s.farm(0)
	check(not s.plots[0].watered,"an empty watering can cannot water")
	s.refill_water()
	s.farm(0)
	check(s.plots[0].watered and s.water==19,"watering spends one of twenty charges")
	s.advance(4319)
	check(not s.ripe(0),"plants need three days to mature")
	s.advance(1)
	check(s.ripe(0),"plants mature at three full days")
	s.fish=3
	check(not s.cook("fish_sticks"),"fish sticks require a purchased pan")
	s.money=100
	s.buy_utensil("pan")
	check(s.cook("fish_sticks") and s.fish==2 and s.fish_sticks==1,"a pan unlocks fish sticks")
	s.storage_transfer("cabinet",3,"pan",1)
	check(s.cook("fish_sticks"),"putting purchased cookware away keeps its recipe unlocked")
	s.fish=2
	s.buy_utensil("pot")
	s.cabinet[0]={"id":"turnips","count":1}
	s.cabinet[1]={"id":"star_bulbs","count":1}
	check(s.cook("fish_stew") and s.fish_stew==1 and s.cabinet[0].is_empty(),"stew uses cabinet and carried ingredients together")
	s.health=50
	s.health_elixir=1
	s.consume("health_elixir")
	check(s.health==75,"health elixirs restore twenty-five health")
	var crew=State.new()
	crew.advance(1440*6)
	check(crew.ship_storage[0].is_empty() and crew.crew_fed_day==7,"six rations feed Vale across six daily boundaries")
	crew.ship_storage[1]={"id":"fish_stew","count":1}
	crew.advance(1440)
	check(crew.ship_storage[1].is_empty() and crew.crew_fed_day==8,"Vale eats a cooked meal when rations run out")
	crew.advance(1440)
	check(crew.crew_hungry_days==1,"a missing daily meal is recorded without inventing a punishment")
	crew.fish_sticks=2
	crew.storage_transfer("ship_storage",2,"fish_sticks",2)
	check(crew.crew_fed_day==crew.day and crew.ship_storage[2].count==1 and crew.crew_hungry_days==0,"a meal delivered later satisfies the current day exactly once")
	var restored=State.new()
	check(restored.restore(s.to_dict()) and restored.water==s.water and restored.pot==1 and restored.quick_slots==s.quick_slots,"new supplies and quick slots survive a save round trip")
	quit(1 if failed else 0)
