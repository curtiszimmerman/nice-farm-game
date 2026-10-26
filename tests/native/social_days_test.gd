extends SceneTree
const State=preload("res://state.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void:
	var s=State.new()
	s.chat_with("moss")
	s.chat_with("moss")
	check(s.friendships.moss==1,"conversation earns friendship once per day")
	s.day=2
	s.chat_with("moss")
	check(s.friendships.moss==2,"a new day permits another conversation point")
	s.star_bulbs=2
	check(s.give_gift("iona","star_bulbs") and s.star_bulbs==1 and not s.give_gift("iona","star_bulbs"),"only one gift per person per calendar week is consumed")
	s.day=8
	check(s.give_gift("iona","star_bulbs"),"the next week permits a new gift")
	var friendship=s.friendships.iona
	s.record_star_origin(false)
	check(s.star_origin_reply=="lie" and s.friendships.iona==friendship,"the captain's claim is recorded independently of friendship")
	var loaded=State.new()
	check(loaded.restore(s.to_dict()) and loaded.chat_days==s.chat_days and loaded.gift_weeks==s.gift_weeks and loaded.star_origin_reply=="lie","social history and the captain's claim survive saving")
	quit(1 if failed else 0)
