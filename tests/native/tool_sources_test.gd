extends SceneTree
const State=preload("res://state.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var s=State.new()
	check(s.accept_firewood_task() and s.axe==0,"Oren offers his firewood job without giving an axe")
	check(s.has_method("accept_tool"),"tools can be collected from the woodcutter and the cave")
	if s.has_method("accept_tool"):
		check(s.accept_tool("axe") and s.axe==1 and not s.accept_tool("axe"),"Rowan gives an axe once")
		check(s.accept_tool("pickaxe") and s.pickaxe==1 and not s.accept_tool("pickaxe"),"the cave pickaxe can be collected once")
		check(s.quick_slots.all(func(id):return id==""),"gifted tools are never assigned automatically")
		var restored=State.new()
		check(restored.restore(s.to_dict()) and not restored.accept_tool("axe") and not restored.accept_tool("pickaxe"),"tool handouts remain unique after saving")
	quit(1 if failed else 0)
