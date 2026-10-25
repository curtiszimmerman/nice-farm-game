extends SceneTree
const Game=preload("res://game.gd")
const Borders=preload("res://terrain_borders.gd")
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
	var world=game.outdoors
	game.state.weather_override="sunny"
	world.refresh()
	await process_frame
	var original=world.terrain
	var crop_draws=world.crops.draw_count
	game.state.weather_override="rainy"
	world.refresh()
	await process_frame
	check(world.terrain!=original,"changing weather rebuilds weather-specific terrain once")
	check(world.crops.draw_count>crop_draws,"farm soil updates its artwork when the weather changes")
	var rainy=world.terrain
	crop_draws=world.crops.draw_count
	for i in range(3): world.refresh(); await process_frame
	check(world.terrain==rainy and world.crops.draw_count==crop_draws,"unchanged weather retains terrain and crop draw lists")
	var cell=Vector2i(64,48)
	var id="tile_border_paving_fill_spring_rainy_%d" % Borders.variant(cell,game.state.world_seed)
	check(game.Art.catalog.has(id),"the finished seasonal paving surfaces are in the runtime atlas")
	if game.Art.catalog.has(id):
		var actual=world.terrain.get_image().get_pixelv(Vector2i(game.Grid.center(cell)))
		var expected=game.Art.tile_image(id.trim_prefix("tile_")).get_pixel(16,16)
		check(actual.is_equal_approx(expected),"town paving actually uses the selected weather texture")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
