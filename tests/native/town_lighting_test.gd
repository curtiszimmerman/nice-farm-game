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
	var effects=game.world.get("night_effects")
	check(effects!=null,"town lighting and smoke have a separate animated layer")
	if effects!=null:
		var moss=game.world.buildings.filter(func(b):return b.id=="moss")[0]
		var smith=game.world.buildings.filter(func(b):return b.id=="smithy")[0]
		game.state.minute=1260
		check(effects.house_lit(moss),"home windows glow after sunset before their resident sleeps")
		game.state.minute=1400
		check(not effects.house_lit(moss),"home windows go dark after their resident sleeps")
		game.state.day=85
		check(effects.smoking(moss),"winter homes emit chimney smoke at night")
		game.state.minute=720
		check(not effects.smoking(moss) and effects.smoking(smith),"ordinary chimneys stop by day while the forge keeps smoking")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
