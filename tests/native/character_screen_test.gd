extends SceneTree
const Game=preload("res://game.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	game.state.firewood_requested=true
	game.ui.quest_lines()
	game.state.met_mayor=true
	var ordered=game.ui.quest_lines().map(func(quest):return quest.id)
	check(ordered.find("keeper_firewood")<ordered.find("first_harvest"),"quest history follows assignment order within active quests")
	game.state.harvested=1
	game.state.experience=30
	game.ui.update()
	check(not game.ui.quest_rows.get_children().any(func(row):return row is Button and row.text.contains("Putting down roots")),"completed quest lines leave the small Crew Log")
	game.inventory()
	var tabs=game.ui.get("inventory_tabs")
	check(tabs!=null,"character screen has inventory and stats tabs")
	if tabs!=null:
		check(tabs.get_tab_count()==3 and game.ui.stats_experience.text.contains("30"),"stats tab lists earned experience alongside inventory and people tabs")
		check(game.ui.equipment_silhouette.size.x>192 and game.ui.equipment_silhouette.size.y>384,"equipment silhouette leaves more room to arrange armor")
		check(game.ui.equipment_slots.values().all(func(slot):return not slot.tooltip_text.is_empty()),"every equipment position explains its purpose on hover")
		var sizes=[]
		for slot in game.ui.equipment_slots.values(): sizes.append(slot.size)
		check(sizes.all(func(size):return size==Vector2(64,64)),"all equipment slots have identical square dimensions")
		check(game.ui.character_quests.get_children().any(func(row):return row is Button and row.get_meta("quest_id","")=="first_harvest"),"completed quests remain available in character history")
	var loaded=game.State.new()
	check(loaded.restore(game.state.to_dict()) and loaded.get("quest_order") is Array and loaded.quest_order==game.state.quest_order,"quest assignment order survives saving")
	var invalid=game.state.to_dict()
	invalid.quest_order=["crew_supplies","crew_supplies"]
	check(not loaded.restore(invalid),"duplicate quest history entries are rejected")
	invalid.quest_order=["unknown_quest"]
	check(not loaded.restore(invalid),"unknown quest history entries are rejected")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
