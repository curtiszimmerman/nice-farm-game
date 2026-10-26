extends SceneTree
const State=preload("res://state.gd")
const Calendar=preload("res://calendar.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void:
	var s=State.new()
	s.day=28
	s.minute=1439
	var calendar=Calendar.new()
	calendar.state=s
	calendar.refresh()
	s.advance(1)
	calendar.refresh()
	check(s.day==29 and s.season_day()==1 and s.season_name()=="summer","the twenty-eighth midnight starts the next four-week season")
	check(calendar.previous_day==28 and calendar.displayed_day==29 and calendar.transition==0,"midnight starts a transition between the two weekday rings")
	calendar._process(0.9)
	check(calendar.transition>0 and calendar.transition<1,"the weekday ring transition has an intermediate crossfade")
	calendar._process(2)
	check(calendar.transition==1,"the completed ring transition releases the old drawing")
	calendar.free()
	quit(1 if failed else 0)
