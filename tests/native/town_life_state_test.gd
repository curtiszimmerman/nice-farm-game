extends SceneTree
const State=preload("res://state.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void:
	var s=State.new()
	check(s.INVENTORY_SLOTS==16,"satchel has two rows of eight")
	s.money=1000
	check(s.buy_utensil("pot"),"one pot can be purchased")
	check(not s.buy_utensil("pot"),"a second pot is unavailable this season")
	s.day=29
	check(s.buy_utensil("pot") and s.pot==2,"new season restocks cookware without deleting the owned pot")
	for id in s.Shop.CATALOG:
		var initial=s.stock(id)
		for i in range(initial): check(s.purchase(id),"available seasonal stock can be bought: "+id)
		check(s.stock(id)==0 and not s.purchase(id),"sold-out stock cannot be bought: "+id)
	s.awake_minutes=4320
	check(is_equal_approx(s.energy_cost(5),20) and is_equal_approx(s.energy_recovery(20),5),"three sleepless days quadruple costs and quarter recovery")
	s.plots[0].watered=true
	s.plots[0].water_day=s.day
	s.minute=1260
	check(s.plot_moisture(0)>0 and s.plot_moisture(0)<1,"wet soil visibly dries between sunset and midnight")
	s.minute=1439
	s.advance(1)
	check(s.plot_moisture(0)==0,"yesterday's water has no visible moisture after midnight")
	s.awake_minutes=1439
	s.sleep_minutes=0
	s.advance(1,false,true)
	check(s.is_tired(),"a short nap does not postpone a full day without restorative sleep")
	quit(1 if failed else 0)
