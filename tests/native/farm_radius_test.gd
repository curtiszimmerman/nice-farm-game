extends SceneTree
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void:
	var s=preload("res://state.gd").new()
	s.crucible_known=true
	s.stones=30
	check(s.build_crucible(Vector2i(0,47)),"construction is available west of the farmhouse")
	check(s.build_crucible(Vector2i(20,40)),"construction is available north-east of the farmhouse")
	check(not s.build_crucible(Vector2i(-10,47)),"construction ends fifteen squares from the farmhouse")
	var loaded=preload("res://state.gd").new()
	check(loaded.restore(s.to_dict()),"structures placed throughout the farmhouse radius survive saving")
	s.hoe=1
	s.assign_active("primary","hoe")
	check(s.prepare_plot(Vector2i(5,47)) and s.plots.back().tilled,"a selected hoe creates a new field outside the starter garden")
	check(not s.prepare_plot(Vector2i(5,47)),"the same field square cannot be created twice")
	check(loaded.restore(s.to_dict()) and loaded.plots.size()==1 and loaded.plot_cell(0)==Vector2i(5,47),"new farm locations survive saving")
	var bad=s.to_dict()
	bad.plots[0].x=999
	bad.plots[0].y=999
	check(not loaded.restore(bad),"saved starter plots cannot be moved outside their fixed field")
	quit(1 if failed else 0)
