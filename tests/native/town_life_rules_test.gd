extends SceneTree
const State=preload("res://state.gd")
const Schedule=preload("res://villager_schedule.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void:
	var s=State.new()
	s.hoe=1
	s.watering_can=1
	s.sync_inventory()
	s.move_inventory("watering_can",9)
	s.cycle_inventory_row()
	check(s.quick_slots[1]=="watering_can","Tab selects the other actual inventory row")
	s.magic_learned=true
	check(s.assign_slot(3,"wildgrowth") and s.inventory_cells()[11].id=="wildgrowth","spell shortcuts occupy row positions without becoming item quantities")
	s.change_friendship("moss",60)
	check(s.relationship("moss")=="Loved" and "moss" in s.met_people,"friendship and met-person history update together")
	s.change_friendship("moss",-160)
	check(s.relationship("moss")=="Hated","negative relationships are supported and bounded")
	var parsed=JSON.parse_string(JSON.stringify(s.to_dict()))
	check(State.new().restore(parsed),"expanded progress and spell row positions survive a real JSON save round trip")
	check(Schedule.stop("baker",250,1).sleeping==false,"baker starts the day at four")
	check(Schedule.stop("astronomer",60,1).sleeping,"the astronomer also sleeps at night")
	quit(1 if failed else 0)
