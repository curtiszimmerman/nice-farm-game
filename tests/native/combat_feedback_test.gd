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
	game.state.cave_seed=12345
	game.enter_building("cave")
	game.close_window()
	game.state.rusty_sword=1
	game.state.select_inventory("rusty_sword")
	var rat=game.world.rats[0]
	var rat_cell=game.Grid.world_to_cell(rat.position)
	rat.info.health=2
	game.state.player_position=game.Grid.center(rat_cell+Vector2i.DOWN)
	game.world.facing="up"
	game.world.attack()
	check(game.state.get("experience")==0,"a nonlethal strike does not award kill experience")
	game.world.swing_cooldown=0
	game.world.attack()
	check(game.state.get("experience")==10,"defeating a rat awards ten experience")
	if game.world.get("combat_texts")!=null:
		check(game.world.combat_texts.any(func(entry):return entry.text=="+10xp") and game.world.combat_texts.any(func(entry):return entry.text=="-1"),"experience and inflicted damage produce rising combat text")
	game.world.swing_cooldown=0
	game.world.attack()
	check(game.state.get("experience")==10,"defeated rats cannot award experience twice")
	var loaded=game.State.new()
	check(loaded.restore(game.state.to_dict()) and loaded.get("experience")==10,"experience survives saving")
	var invalid=game.state.to_dict()
	invalid.experience=-1
	check(not loaded.restore(invalid) and loaded.experience==10,"invalid experience cannot replace saved progress")
	var attacker=game.world.rats[1]
	attacker.position=game.state.player_position+Vector2(0,20)
	var before=game.state.health
	game.world.update_enemies(0.01)
	check(game.state.health==before-4 and game.world.combat_texts.any(func(entry):return entry.text=="-4" and entry.color==Color("ff8e7b")),"rat bites display actual player damage in red")
	for enemy in game.world.rats: enemy.visible=false
	game._process(1.4)
	check(game.world.combat_texts.is_empty(),"combat values disappear when their rise and fade finish")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
