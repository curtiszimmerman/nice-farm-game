extends SceneTree
const State=preload("res://state.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void:
	var s=State.new()
	check(s.has_method("is_tired"),"the player tracks time awake")
	check(s.has_method("apply_poison"),"poison is a timed player status")
	if s.has_method("is_tired"):
		preload("fixture.gd").tools(s)
		s.advance(1440)
		check(not s.is_tired(),"exactly twenty-four hours awake has not crossed the tired threshold")
		s.advance(0.01)
		check(s.is_tired(),"more than twenty-four hours awake applies tiredness")
		var energy=s.energy
		s.tend(0)
		check(s.energy==energy-4,"tired tilling costs twice the normal energy")
		s.pickaxe=1
		s.assign_active("primary","pickaxe")
		energy=s.energy
		check(s.mine() and s.energy==energy-10,"tired mining costs twice the normal energy")
		s.energy=10
		s.rations=1
		check(s.consume("rations") and s.energy==17.5,"tired food restores half its normal energy")
		s.energy=0
		s.advance(359,false,true)
		check(s.is_tired() and is_equal_approx(s.energy,35.9),"short sleep restores half energy while tiredness remains")
		s.advance(1,false,true)
		check(not s.is_tired() and s.awake_minutes==0,"six consecutive hours asleep clears tiredness")
		s.advance(5,false,true)
		check(is_equal_approx(s.energy,37),"energy recovery returns to full strength after tiredness clears")
	if s.has_method("apply_poison"):
		var poisoned=State.new()
		poisoned.apply_poison()
		poisoned.advance(4.9)
		check(poisoned.health==100,"poison waits five game minutes before its first damage")
		poisoned.advance(0.1)
		check(poisoned.health==98,"poison deals two health every five game minutes")
		poisoned.advance(55)
		check(poisoned.health==76 and not poisoned.status_effects.has("poison"),"poison expires after one hour and twelve damage ticks")
		poisoned.advance(60)
		check(poisoned.health==76,"expired poison cannot keep damaging the player")
		poisoned.apply_poison()
		poisoned.advance(4)
		poisoned.apply_poison()
		poisoned.advance(1)
		check(poisoned.health==74,"refreshing poison never postpones its next damage tick")
		var loaded=State.new()
		check(loaded.restore(poisoned.to_dict()) and loaded.status_effects==poisoned.status_effects,"status timers survive saving")
		var paused=State.new()
		paused.apply_poison()
		paused.advance(30,true)
		check(paused.health==100 and paused.status_effects.poison.remaining==60,"a fully paused world also pauses poison")
	quit(1 if failed else 0)
