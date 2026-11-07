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
	var intro=game.opening
	check(intro.has_method("enemy_reveal"),"the attacker fades into view rather than appearing instantly")
	if intro.has_method("enemy_reveal"):
		intro.elapsed=3
		check(intro.enemy_reveal().alpha==0,"the reveal starts invisible")
		intro.elapsed=3.2
		check(intro.enemy_reveal().alpha>0 and intro.enemy_reveal().alpha<1 and intro.enemy_reveal().offset.length()>0,"the appearing attacker is translucent and unstable")
		intro.elapsed=4
		check(intro.enemy_reveal().alpha==1 and intro.enemy_reveal().offset==Vector2.ZERO,"the attacker settles before the first bridge cut")
		intro.caption_step=1
		intro.elapsed=3
		intro._process(0)
		check(game.sound.battle.decloak.playing and intro.reveal_played,"the reveal plays its dedicated low zap")
	check(intro.has_method("bridge_glare_texture"),"window reflections have a separate layer above the planet")
	if intro.has_method("bridge_glare_texture"):
		var bitmap=intro.bridge_glare_texture().get_image()
		var clear=false
		var reflection=false
		for y in range(bitmap.get_height()):
			for x in range(bitmap.get_width()):
				var alpha=bitmap.get_pixel(x,y).a
				clear=clear or alpha==0
				reflection=reflection or (alpha>0 and alpha<0.5)
		check(clear and reflection,"the glare layer preserves transparent glass and translucent reflections")
	check(Game.BRIEFING.any(func(line):return "water dispenser" in line[1] and "this is all we have" in line[1]),"Vale explains the limited food and water aboard")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
