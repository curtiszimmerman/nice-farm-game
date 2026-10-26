extends SceneTree
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void:
	var s=preload("res://state.gd").new()
	s.cabinet[0]={"id":"pot","count":1}
	s.cabinet[1]={"id":"pan","count":1}
	s.cabinet[2]={"id":"berries","count":2}
	s.cabinet[3]={"id":"sugar","count":2}
	s.cabinet[4]={"id":"flour","count":1}
	s.cabinet[5]={"id":"butter","count":1}
	check(s.cook("berry_preserves") and s.berry_preserves==1,"preserves use berries and sugar stored in the cabinet")
	check(s.cook("berry_cobbler") and s.berry_cobbler==1 and s.berry_preserves==0,"cobbler combines preserves with flour, sugar and butter")
	s.needs.hardcore=true
	s.needs.without_food=30240
	check(s.consume("berry_cobbler") and not s.needs.starving(),"a cooked cobbler fully nourishes the player")
	s.ship_storage[0]={"id":"bread","count":1}
	check(s.take_crew_meal() and s.ship_storage[0].is_empty(),"Vale can eat prepared bread from the locker")
	quit(1 if failed else 0)
