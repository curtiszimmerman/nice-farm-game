extends SceneTree
const State=preload("res://state.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void:
	var state=State.new()
	state.fish=2
	state.seeds=4
	check(state.has_method("inventory_cells"),"inventory tracks stable physical slot positions")
	if state.has_method("inventory_cells"):
		var before=state.inventory_cells().filter(func(stack):return not stack.is_empty()).map(func(stack):return stack.id)
		state.accept_tool("axe")
		var after=state.inventory_cells().filter(func(stack):return not stack.is_empty()).map(func(stack):return stack.id)
		check(after.slice(0,before.size())==before and after.back()=="axe","newly collected axe appends after everything already carried")
		check(state.move_inventory("axe",7) and state.inventory_cells()[7].id=="axe","stacks can move into any empty inventory slot")
		state.chest_transfer(0)
		check(state.inventory_cells()[8].id=="hoe","new supplies append after existing items even when there are earlier holes")
		var loaded=State.new()
		check(loaded.restore(state.to_dict()) and loaded.inventory_cells()==state.inventory_cells(),"inventory arrangement survives saving")
	quit(1 if failed else 0)
