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
		var light=effects.house_lamp_position(moss,1)
		var enclosure=Rect2(Vector2(moss.x+32+10,moss.y+moss.h-58),Vector2(12,14))
		check(enclosure.encloses(Rect2(light-Vector2(3,4),Vector2(6,8))),"the exterior flame stays inside its lantern's glass enclosure")
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
