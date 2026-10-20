extends SceneTree
const Game=preload("res://game.gd")
const Art=preload("res://art.gd")
var failed=false
func check(value: bool,label: String) -> void:
	if value: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	var opening=game.opening
	check(opening.battle_at(11).enemy_fire and opening.battle_at(11).return_fire,"both ships exchange fire during the exterior battle")
	check(opening.battle_at(19).destroyed and not opening.battle_at(19).enemy_fire,"the attacker explodes and stops firing before the crash")
	preload("fixture.gd").explore(game,true)
	Art.load_atlas()
	var hoe=Art.pixels.get_region(Rect2i(Art.region("item_hoe")))
	var sickle=Art.pixels.get_region(Rect2i(Art.region("item_sickle")))
	var pickaxe=Art.pixels.get_region(Rect2i(Art.region("item_pickaxe")))
	check(hoe.get_data()!=sickle.get_data() and hoe.get_data()!=pickaxe.get_data() and sickle.get_data()!=pickaxe.get_data(),"hoe sickle and pickaxe have different pixel silhouettes")
	var wet_visible=true
	for crop in ["sprout","turnip","bulb"]:
		var dry=Art.region("crop_"+crop).position+Vector2(3,7)
		var wet=Art.region("crop_"+crop+"_wet").position+Vector2(3,7)
		if Art.pixels.get_pixelv(Vector2i(wet)).get_luminance()>=Art.pixels.get_pixelv(Vector2i(dry)).get_luminance(): wet_visible=false
	check(wet_visible,"watered soil stays darker underneath each crop stage")
	var left=Art.pixels.get_region(Rect2i(Art.region("tile_fence_mask1")))
	var right=Art.pixels.get_region(Rect2i(Art.region("tile_fence_mask2")))
	check(left.get_pixel(0,13).a>0 and left.get_pixel(31,13).a==0 and right.get_pixel(0,13).a==0 and right.get_pixel(31,13).a>0,"fence end sprites only extend rails toward their neighbor")
	var sofa=Art.pixels.get_region(Rect2i(Art.region("furniture_sofa_3x1")))
	check(sofa.get_pixel(sofa.get_width()/2,sofa.get_height()-5).a==0,"furniture does not cast a detached shadow beneath its base")
	check(Art.catalog.size()>300 and Art.atlas!=null,"the native game loads the complete PNG sprite atlas")
	var trees=true
	for tree in game.outdoors.trees:
		var entry=Art.catalog[Art.tree_id(tree)]
		if int(entry.rect[2])!=96 or int(entry.trunk_tiles[0])!=1 or int(entry.trunk_tiles[1])!=2 or int(entry.canopy_tiles[0])!=3: trees=false
	check(trees,"every populated tree obeys the sprite trunk and canopy tile dimensions")
	check(game.outdoors.bushes.size()>5,"bush sprites soften the foot of the mountain")
	check(game.outdoors.bushes.any(func(cell): return cell.distance_to(game.outdoors.MOSS_ENCOUNTER_CELL)<=4),"bushes are visible around the first trail encounter")
	for building in game.outdoors.buildings:
		game.enter_building(building.id)
		for item in game.world.furnishings:
			var id="furniture_%s_%dx%d" % [item.kind,item.bounds.size.x,item.bounds.size.y]
			check(Art.catalog.has(id),"sprite available for %s in %s" % [item.kind,building.id])
		game.world.refresh()
		await process_frame
		game.leave_building()
	game.enter_building("home")
	game.state.player_position=game.world.site_position("stove")
	game.cooking()
	var labels=[]
	for child in game.ui.modal_box.get_children():
		if child is Button: labels.append(child.text)
	check(not labels.any(func(label): return label.begins_with("Cook ")),"an oven with no cookware offers no recipes")
	game.close_window()
	game.state.pan=1
	game.state.fish=1
	game.state.assign_slot(7,"fish")
	game.select_quick_slot(7)
	game.interact()
	check(game.window_open and game.state.fish==1,"the oven takes priority over consuming the selected ingredient")
	if not game.window_open: game.cooking()
	labels.clear()
	for child in game.ui.modal_box.get_children():
		if child is Button: labels.append(child.text)
	check(labels.any(func(label): return "fish sticks" in label.to_lower()) and not labels.any(func(label): return "fish stew" in label.to_lower()),"a carried pan expands only its oven recipes")
	game.close_window()
	var click=InputEventMouseButton.new()
	click.button_index=MOUSE_BUTTON_LEFT
	click.pressed=true
	click.position=game.get_viewport().get_canvas_transform()*(game.world.site_position("stove")-Vector2(0,40))
	if game.has_method("_unhandled_input"): game._unhandled_input(click)
	check(game.window_open and game.state.fish==1,"clicking the nearby oven opens cooking without selecting cookware")
	game.close_window()
	game.leave_building()
	game.change_art(1)
	await process_frame
	check(Art.option==1,"the preserved artwork remains selectable")
	game.change_art(2)
	await process_frame
	check(Art.option==2,"the modular sprite artwork can be restored without restarting")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
