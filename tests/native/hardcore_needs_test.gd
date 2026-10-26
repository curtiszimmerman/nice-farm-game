extends SceneTree
const Needs=preload("res://journey_needs.gd")
const State=preload("res://state.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void:
	var s=State.new()
	s.needs.hardcore=true
	s.advance(4320)
	check("thirsty" in s.active_statuses() and s.health==100,"three dry days apply thirst without retroactive damage")
	s.energy=0
	s.mana=0
	s.advance(60,false,true)
	check(s.health==90 and s.energy==0 and s.mana==0,"thirst blocks sleep recovery and costs ten maximum HP per hour")
	s.needs.drink()
	s.restore_energy(10)
	check(s.energy>0 and "thirsty" not in s.active_statuses(),"fresh water removes the recovery lock")
	s.needs.without_food=30240
	s.bread=1
	check("starving" in s.active_statuses() and s.consume("bread") and not s.needs.deprived(),"a meal removes starvation and permits its energy recovery")
	s.needs.without_water=4320
	s.health_elixir=1
	s.health=50
	check(s.consume("health_elixir") and s.needs.without_water==0 and s.health==75,"health elixirs also hydrate")
	s.needs.without_water=4320
	s.needs.hardcore=false
	s.energy=0
	s.advance(60,false,true)
	check(s.energy>0 and "thirsty" not in s.active_statuses(),"disabling hardcore removes survival penalties")
	s.needs.mode_chosen=true
	s.crew_food_delivered=true
	var loaded=State.new()
	check(loaded.restore(s.to_dict()) and loaded.needs.mode_chosen and loaded.needs.without_water==s.needs.without_water and loaded.crew_food_delivered,"saving preserves survival clocks, mode choice and the food-deposit milestone")
	quit(1 if failed else 0)
