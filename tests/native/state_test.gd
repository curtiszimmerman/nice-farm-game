extends SceneTree

const State = preload("res://state.gd")
var count = 0
var failed = false

func check(condition: bool, description: String) -> void:
	if not condition:
		failed = true
		push_error("FAIL: " + description)
		return
	count += 1
	print("PASS: " + description)

func _initialize() -> void:
	var s = State.new()
	preload("fixture.gd").tools(s)
	s.tend(0)
	s.tend(0)
	check(s.seeds == 7 and not s.ripe(0), "planting spends a seed and requires water")
	s.advance(500.0)
	check(not s.ripe(0), "unwatered crops cannot ripen")
	s.tend(0)
	s.advance(4320.0)
	check(s.ripe(0), "watered crop grows after three game days")
	s.tend(0)
	check(s.turnips == 1 and s.harvested == 1, "harvesting yields produce once")
	s.tend(0)
	s.tend(0)
	var mana = s.mana
	check(s.grow(0) and s.mana == mana - 15.0 and s.ripe(0), "growth spell ripens crops and charges mana")
	s.mana = 0.0
	check(not s.grow(1), "magic cannot spend unavailable mana")
	s.minute = 1439.0
	var previous_day=s.day
	s.advance(2.0)
	check(s.day == previous_day+1 and is_equal_approx(s.minute, 1.0) and s.ripe(0), "midnight preserves crops and rolls the date")
	s.pause_mode = "all"
	s.mana = 10.0
	s.advance(10.0, true)
	check(s.minute == 1.0 and s.mana == 10.0, "full pause freezes simulation")
	s.pause_mode = "clock"
	s.advance(10.0, true)
	check(s.minute == 1.0 and s.mana > 10.0, "calendar pause preserves active simulation")
	s.pause_mode = "none"
	s.advance(10.0, true)
	check(s.minute == 11.0, "default menu mode keeps time moving")
	s.turnips = 3
	s.fish = 1
	var money = s.money
	check(s.sell() and s.money == money + 34 and s.turnips == 0 and s.fish == 0, "selling exchanges produce for correct value")
	check(not s.sell(), "empty inventory cannot sell")
	s.money = 0
	check(not s.buy_seeds(), "seed purchases require funds")
	s.money = 10
	check(s.buy_seeds() and s.money == 0, "buying seeds charges the quoted price")
	s.energy = 0.0
	check(not s.mine() and s.copper == 0, "exhausted mining yields no copper")
	s.energy = 100.0
	check(not s.mine(),"mining requires an armed pickaxe")
	s.accept_tool("pickaxe")
	s.assign_slot(7,"pickaxe")
	s.selected_slot=7
	check(s.mine() and s.copper == 1 and s.energy == 95.0, "selected pickaxe mining costs energy")
	check(not s.meet_mayor(), "mayor cannot meet before invitation")
	s.invite_mayor()
	s.advance(119)
	check(not s.meet_mayor(), "appointment does not trigger before Moss's two-hour round trip")
	s.advance(1)
	check(s.meet_mayor() and not s.meet_mayor(), "appointment triggers once when the mayor returns")
	var late = State.new()
	late.invited = true
	late.mayor_due=720
	late.day = 3
	late.minute=720
	check(late.meet_mayor(), "missed appointment remains recoverable")
	var data = s.to_dict()
	var restored = State.new()
	check(restored.restore(data) and restored.copper == s.copper and restored.ripe(0), "save round trip preserves progression and crops")
	data["money"] = -1
	check(not restored.restore(data), "negative resources reject corrupt saves")
	check(not restored.restore({"version": 1}), "incomplete saves are rejected")
	print("%d native simulation checks passed" % count)
	quit(1 if failed else 0)
