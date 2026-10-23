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
	game.state.met_mayor=true
	game.state.harvested=1
	game.state.experience=30
	game.ui.update()
	check(not game.ui.quest_rows.get_children().any(func(row):return row is Button and row.text.contains("Putting down roots")),"completed quest lines leave the small Crew Log")
	game.inventory()
	var tabs=game.ui.get("inventory_tabs")
	check(tabs!=null,"character screen has inventory and stats tabs")
	if tabs!=null:
		check(tabs.get_tab_count()==2 and game.ui.stats_experience.text.contains("30"),"stats tab lists earned experience")
		check(game.ui.equipment_silhouette.size==Vector2(192,384),"equipment silhouette is two hundred percent larger")
		var sizes=[]
		for slot in game.ui.equipment_slots.values(): sizes.append(slot.size)
		check(sizes.all(func(size):return size==Vector2(64,64)),"all equipment slots have identical square dimensions")
		check(game.ui.character_quests.get_children().any(func(row):return row is Button and row.get_meta("quest_id","")=="first_harvest"),"completed quests remain available in character history")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
