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
	game.ui.update()
	check(game.ui.has_method("quest_lines"),"crew log supports multiple expandable quest lines")
	if game.ui.has_method("quest_lines"):
		var quests=game.ui.quest_lines()
		var home=quests.filter(func(q):return q.id=="restore_farmhouse")[0]
		check(home.tasks.size()==2 and home.tasks[0].text=="Remove the covers from the furniture" and home.tasks[1].text=="Change the lightbulbs around the house","cleanup groups all covers and both lightbulbs as distinct checklist entries")
		for task in ["sofa","bed","guest_bed","radio"]: game.state.house_tasks[task]=true
		home=game.ui.quest_lines().filter(func(q):return q.id=="restore_farmhouse")[0]
		check(home.tasks[0].done and not home.tasks[1].done,"cover completion is tracked separately from light repairs")
	check(game.ui.has_method("quest_pulse"),"new quests pulse the crew-log background")
	if game.ui.has_method("quest_pulse"):
		check(game.ui.quest_pulse(1.35)<game.ui.quest_pulse(1.7) and game.ui.quest_pulse(1.7)>0.9 and game.ui.quest_pulse(2.0)<0.45,"quest pulse rises with acceleration and falls rapidly into a long tail")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
