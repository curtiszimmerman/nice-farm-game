extends SceneTree
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	check(ResourceLoader.exists("res://calendar.gd"),"the calendar models weekdays and both resonant moons")
	if ResourceLoader.exists("res://calendar.gd"):
		var calendar=load("res://calendar.gd")
		check(calendar.weekday(1)==0 and calendar.weekday(8)==0 and calendar.weekday(7)==6,"seven weekday symbols repeat across four-week months")
		check(is_equal_approx(calendar.orbit(28,28),0) and is_equal_approx(calendar.orbit(56,56),0),"white and purple orbital periods remain 28 and 56 days")
		check(is_zero_approx(calendar.phase(0,28)) and is_zero_approx(calendar.phase(0,56)),"both moons share the initial new-moon alignment")
		check(is_equal_approx(calendar.phase(56,28),0.5) and is_equal_approx(calendar.phase(56,56),0.5),"both moons can be full together relative to the planet's existing year")
		check(calendar.phase_index(112,28)==0 and calendar.phase_index(112,56)==0,"both moons return to new at the next year's start")
		check(calendar.has_method("pendulum_geometry"),"the clock exposes its round pendulum geometry")
		if calendar.has_method("pendulum_geometry"):
			var bob=calendar.pendulum_geometry()
			check(bob.radius>=18 and is_equal_approx(bob.pivot_y+bob.center_y-bob.radius,342),"the round pendulum touches the clock box at its center swing")
	quit(1 if failed else 0)
