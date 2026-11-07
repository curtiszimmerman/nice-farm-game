extends SceneTree
const Game=preload("res://game.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")

# Lists everyone the schedule leaves standing outdoors at some point in the day.
func outdoor_stops(world: Node2D,state: RefCounted) -> Array:
	var outside=[]
	for day in range(1,8):
		state.day=day
		for minute in range(0,1440,15):
			state.minute=float(minute)
			for id in world.villagers:
				if world.stop_for(id).get("room","")=="": outside.append("%s day %d at %d" % [id,day,minute])
	return outside

func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	game.state.met_mayor=true
	var world=game.outdoors
	game.state.weather_override="sunny"
	check(not outdoor_stops(world,game.state).is_empty(),"on a dry day people spend time outdoors")
	game.state.weather_override="rainy"
	var outside=outdoor_stops(world,game.state)
	check(outside.is_empty(),"nobody stands around outdoors in the rain")
	if not outside.is_empty(): print("Out in the rain: ",outside.slice(0,10))
	game.state.day=2
	game.state.minute=750.0
	var tavi=world.stop_for("tavi")
	check(tavi.room=="tavi" and not tavi.sleeping,"Tavi takes his rainy lunch break at home, awake")
	game.state.minute=600.0
	check(world.stop_for("smith").room=="smithy","Dain keeps working at the forge in the rain")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
