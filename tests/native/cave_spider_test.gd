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
	game.enter_building("cave")
	game.close_window()
	var cave=game.world
	var spider=cave.get("spider")
	check(spider!=null,"a cave spider guards the final chamber")
	if spider!=null:
		check(cave.chambers.back().has_point(game.Grid.world_to_cell(spider.position)) and spider.info.health==4,"the final-room spider has twice a rat's health")
		for rat in cave.rats: rat.visible=false
		game.state.player_position=spider.position+Vector2(0,20)
		cave.combat_rng.seed=12345
		var poisoned=0
		for i in range(1000):
			game.state.health=100
			game.state.status_effects.clear()
			spider.info.bite=0
			cave.update_enemies(0.01)
			if game.state.status_effects.has("poison"): poisoned+=1
		check(poisoned>=150 and poisoned<=250,"actual spider bites poison approximately twenty percent of the time")
		game.state.rusty_sword=1
		game.state.assign_active("primary","rusty_sword")
		cave.facing="up"
		for hit in range(4):
			cave.swing_cooldown=0
			cave.attack()
			check(spider.visible==(hit<3),"the spider takes four sword strikes to defeat")
		check(game.state.cave_defeated.has(2) and game.state.experience==20,"the defeated spider persists and grants experience once")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
