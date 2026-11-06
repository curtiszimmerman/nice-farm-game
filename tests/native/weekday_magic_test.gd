extends SceneTree
const Faith=preload("res://weekday_magic.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void:
	check(Faith.strength(2,42,"nature")==1.5 and Faith.strength(2,42,"air")==0.5,"Bough favors nature and weakens air")
	check(Faith.strength(3,42,"fire")==1.5 and Faith.strength(3,42,"water")==0.5,"Ember favors fire and weakens water")
	check(Faith.strength(4,42,"air")==1.5 and Faith.strength(4,42,"nature")==0.5 and Faith.strength(4,42,"water")==1.0,"Gale favors air and weakens growth, leaving water unchanged")
	check(Faith.strength(5,42,"water")==1.5 and Faith.strength(5,42,"fire")==0.5,"Tide favors water and weakens fire")
	check(Faith.strength(6,42,"nature")==1.15 and Faith.strength(7,42,"fire")==0.85,"Light and Darkness affect every school")
	var collision=false
	var doubled=false
	var silenced=false
	for seed_value in range(300):
		check(Faith.SCHOOLS.all(func(school):return Faith.strength(1,seed_value,school)==1.0),"a new journey starts with neutral magic for every world seed")
		var omen=Faith.chaos(8,seed_value)
		check(omen==Faith.chaos(8,seed_value),"Chaos remains stable for a world and day")
		if omen.favored==omen.weakened:
			collision=true
			var amount=Faith.strength(8,seed_value,omen.favored)
			doubled=doubled or amount==2
			silenced=silenced or amount==0
	check(collision and doubled and silenced,"independent Chaos draws can double or silence the same school")
	check(Faith.SCHOOLS.all(func(school):return Faith.strength(1,42,school)==1.0),"all magic has ordinary strength on the first day")
	var state=preload("res://state.gd").new()
	preload("fixture.gd").garden(state)
	state.learned_spells.append("hearthmend")
	state.health=20
	state.day=6
	check(state.cast_healing() and is_equal_approx(state.health,37.25),"Hearthmend receives the Light day's blessing")
	state.magic_learned=true
	state.day=7
	state.plots[0].planted=0
	state.plots[0].watered=true
	check(state.grow(0) and not state.ripe(0) and is_equal_approx(state.plots[0].growth,state.crop_minutes("turnips")*0.85),"Darkness weakens Wildgrowth's growth contribution")
	for day in [1,2,4]:
		state.day=day
		state.mana=state.MAX_MANA
		state.plots[0].growth=0.0
		check(state.grow(0) and is_equal_approx(state.plots[0].growth,state.crop_minutes("turnips")*(0.5 if day==4 else 1.0)),"Wildgrowth obeys the day's strength with a neutral first day")
	for owns_sword in [false,true]:
		var trade=preload("res://state.gd").new()
		trade.rusty_sword=1 if owns_sword else 0
		trade.turnips=3
		check(trade.accept_sword() and trade.turnips==0 and trade.rusty_sword==1 and trade.friendships.get("veteran",0)==5,"Bram rewards supper with friendship, giving a sword only when needed")
		trade.turnips=3
		check(not trade.accept_sword() and trade.turnips==3 and trade.friendships.get("veteran",0)==5,"Bram's supper reward can only be claimed once")
	quit(1 if failed else 0)
