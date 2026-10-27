extends SceneTree
const Faith=preload("res://weekday_magic.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void:
	check(Faith.strength(2,42,"nature")==1.5 and Faith.strength(2,42,"air")==0.5,"Bough favors nature and weakens air")
	check(Faith.strength(3,42,"fire")==1.5 and Faith.strength(3,42,"water")==0.5,"Ember favors fire and weakens water")
	check(Faith.strength(4,42,"air")==1.5 and Faith.strength(4,42,"water")==0.5,"Gale favors air and weakens water")
	check(Faith.strength(5,42,"water")==1.5 and Faith.strength(5,42,"fire")==0.5,"Tide favors water and weakens fire")
	check(Faith.strength(6,42,"nature")==1.15 and Faith.strength(7,42,"fire")==0.85,"Light and Darkness affect every school")
	var collision=false
	var doubled=false
	var silenced=false
	for seed_value in range(300):
		var omen=Faith.chaos(1,seed_value)
		check(omen==Faith.chaos(1,seed_value),"Chaos remains stable for a world and day")
		if omen.favored==omen.weakened:
			collision=true
			var amount=Faith.strength(1,seed_value,omen.favored)
			doubled=doubled or amount==2
			silenced=silenced or amount==0
	check(collision and doubled and silenced,"independent Chaos draws can double or silence the same school")
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
	check(state.grow(0) and is_equal_approx(state.plots[0].growth,state.CROP_MINUTES*0.85),"Wildgrowth respects the Darkness day's weaker magic")
	quit(1 if failed else 0)
