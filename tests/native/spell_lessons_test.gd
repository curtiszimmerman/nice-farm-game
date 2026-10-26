extends SceneTree
const State=preload("res://state.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void:
	var s=State.new()
	check(not s.learn_spell("emberthread"),"fire lesson requires its components")
	s.cave_moth_chrysalis=1
	s.wood=10
	check(s.learn_spell("emberthread") and s.wood==0 and s.cave_moth_chrysalis==0,"fire lesson spends one chrysalis and ten logs")
	check(not s.learn_spell("emberthread"),"known spells cannot consume another lesson fee")
	s.golden_sparkfire_bloom=1
	check(s.learn_spell("hearthmend"),"one dawn bloom teaches Hearthmend")
	s.health=60
	s.mana=30
	check(s.cast_healing() and s.health==75 and s.mana==20,"Hearthmend spends mana to restore health")
	quit(1 if failed else 0)
