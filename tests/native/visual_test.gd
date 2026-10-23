extends SceneTree

const Game = preload("res://game.gd")
var game: Node2D
var prefix=""
var failed=false

func _initialize() -> void:
	call_deferred("run")

func drag_inventory_item(id: String,index: int,channel: String="",source_slot: int=-1) -> void:
	game.inventory()
	game.ui.inventory_tabs.current_tab=0
	await process_frame
	var sources=game.ui.skill_buttons if game.state.Skills.CATALOG.has(id) else game.ui.inventory_slots
	var slots=sources.filter(func(slot): return slot.get_meta("item_id","")==id)
	if source_slot>=0: slots=[game.ui.quick_buttons[source_slot]]
	assert(not slots.is_empty(),"Drag source must be carried")
	var target=game.ui.quick_buttons[index] if channel=="" else game.ui.active_button if channel=="primary" else game.ui.auxiliary_button
	await drag_controls(slots[0],target)
	if (game.state.quick_slots[index] if channel=="" else game.state.active_item(channel))!=id:
		failed=true
		push_error("FAIL: real GUI drag of "+id+" did not assign its destination")
		return
	print("NATIVE DRAG PASSED: ",id," to ",str(index+1) if channel=="" else channel)

func drag_controls(source: Control,target: Control) -> void:
	var start=source.get_global_rect().get_center()
	var end=target.get_global_rect().get_center()
	var down=InputEventMouseButton.new()
	down.button_index=MOUSE_BUTTON_LEFT
	down.pressed=true
	down.button_mask=MOUSE_BUTTON_MASK_LEFT
	down.position=start
	Input.parse_input_event(down)
	await process_frame
	for point in [start+Vector2(20,0),end]:
		var motion=InputEventMouseMotion.new()
		motion.position=point
		motion.relative=point-start
		motion.button_mask=MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(motion)
		await process_frame
	var up=InputEventMouseButton.new()
	up.button_index=MOUSE_BUTTON_LEFT
	up.pressed=false
	up.position=end
	Input.parse_input_event(up)
	await process_frame

func press_key(code: int) -> void:
	for pressed in [true,false]:
		var key=InputEventKey.new()
		key.physical_keycode=code
		key.pressed=pressed
		Input.parse_input_event(key)
		await process_frame

func capture(label: String) -> void:
	if label!="status-banner": game.ui.message.text=""
	if game.state.welcome_phase not in ["meeting","departing","moss_lesson"]: game.world.update_villagers(0.0,true)
	game.nearest=game.world.find_nearest()
	game.world.refresh()
	game.camera.position=game.state.player_position+Vector2(20,-5)
	game.ui.update()
	for i in range(10):
		game.world.refresh()
		await process_frame
	await RenderingServer.frame_post_draw
	var path=ProjectSettings.globalize_path("res://../../internal/verification/native-"+prefix+label+".png").simplify_path()
	var image=root.get_texture().get_image()
	assert(image.save_png(path)==OK,"Screenshot must stay in the project")
	print("Captured native ",label)

func run() -> void:
	if OS.get_cmdline_user_args().has("--rustic16"):
		var error=preload("res://art.gd").select_pack("res://art/option3/pack.json")
		assert(error.is_empty(),error)
		prefix="rustic16-"
	game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	game.opening.set_process(false)
	for shot in [[2.0,"opening-space"],[6.0,"opening-bridge"],[11.0,"opening-attack"],[18.5,"opening-enemy-explodes"],[24.2,"opening-whiteout"],[26.5,"opening-aftermath"]]:
		game.opening.elapsed=shot[0]
		game.opening.animation_time=shot[0]
		game.opening.battle_clock=maxf(0,shot[0]-3)
		game.opening.caption_step=7 if shot[0]>=24 else 0
		game.opening.view.queue_redraw()
		await capture(shot[1])
	game.opening.finish()
	await capture("opening-status-report")
	while game.window_open: game.ui.modal_box.get_child(3).pressed.emit()
	game.inventory()
	await capture("inventory-none-known")
	game.close_window()
	game.leave_building()
	game.state.player_position=game.world.Grid.center(Vector2i(13,28))
	await capture("mountain-descent")
	game.state.player_position=game.world.Grid.center(game.world.MOSS_ENCOUNTER_CELL)
	game._process(0)
	await capture("moss-first-meeting")
	while game.window_open: game.ui.modal_box.get_child(3).pressed.emit()
	while game.state.welcome_phase=="escorting": game._process(0.1)
	game.enter_building("home")
	await capture("welcome-waiting")
	game.state.storage_transfer("cabinet",0)
	for task in game.state.house_tasks: game.tidy_farmhouse(task)
	game._process(8)
	preload("fixture.gd").await_visitors(game)
	await capture("welcome-party-inside")
	while game.window_open: game.ui.modal_box.get_child(3).pressed.emit()
	game._process(0.4)
	await capture("welcome-departure")
	while game.state.welcome_phase=="departing": game._process(0.25)
	await capture("moss-farming-lesson")
	while game.window_open: game.ui.modal_box.get_child(3).pressed.emit()
	while game.state.welcome_phase=="moss_departing": game._process(0.25)
	game.leave_building()
	game.state.player_position=game.world.Grid.center(game.world.Grid.SPAWN_CELL)
	game.open_chest()
	await capture("chest")
	game.close_window()
	preload("fixture.gd").tools(game.state)
	game.world.elapsed=2.0
	game.ui.message.text=""
	await capture("farm")
	game.toast("Watering can filled. Ready for the garden.")
	await capture("status-banner")
	game.ui.show_title()
	await capture("title")
	game.ui.title_screen.queue_free()
	game.ui.title_screen=null
	for i in range(12):
		game.state.tend(i)
		game.state.tend(i)
		game.state.tend(i)
	preload("fixture.gd").grow_watered_days(game.state)
	game.state.player_position=game.world.plot_position(12)+Vector2(0,32)
	await capture("garden")
	game.state.player_position=game.world.Grid.center(game.world.PEOPLE[0].cell)+Vector2(0,20)
	game.talk("moss")
	await capture("conversation")
	game.close_window()
	game.settings()
	await capture("settings")
	game.close_window()
	game.development_tools()
	await capture("development-tools")
	game.close_window()
	game.state.player_position=game.world.Grid.center(game.world.SQUARE.position+Vector2i(5,2))
	await capture("town")
	game.state.minute=0.0
	await capture("evening")
	game.state.minute=840.0
	game.state.player_position=game.world.Grid.center(Vector2i(64,12))
	await capture("wizard-mountains")
	game.state.minute=720.0
	game.state.player_position=game.world.Grid.center(Vector2i(13,36))
	await capture("behind-house")
	game.state.player_position=game.world.trees[0].pos-Vector2(0,45)
	await capture("behind-tree")
	game.state.player_position=game.world.plot_position(6)
	game.world.facing="right"
	game.world.find_nearest()
	await capture("forward-target")
	game.state.player_position=game.world.site_position("ore")
	await capture("outcrop")
	game.state.player_position=game.world.site_position("radio")+Vector2(0,32)
	await capture("radio-table")
	game.state.player_position=game.world.site_position("pond")
	await capture("dock")
	game.enter_building("cave")
	await capture("cave-discovery")
	game.close_window()
	game.state.player_position=game.Grid.center(Vector2i(6,7))
	await capture("cave-entrance")
	game.state.player_position=game.Grid.center(game.world.chambers[2].get_center()+Vector2i(-1,2))
	await capture("cave-rats")
	game.state.rusty_sword=1
	game.state.select_inventory("rusty_sword")
	var rat=game.world.rats[0]
	game.state.player_position=rat.position+Vector2(0,30)
	game.world.facing="up"
	game.world.attack()
	for entry in game.world.combat_texts: entry.age=0.2
	await capture("enemy-damage-text")
	game.world.swing_cooldown=0
	game.world.attack()
	for entry in game.world.combat_texts: entry.age=0.2
	await capture("experience-gain")
	for motion in [["pickaxe","left"],["watering_can","up"],["hoe","down"],["sickle","right"],["axe","up"]]:
		game.world.elapsed=game.elapsed
		game.world.facing=motion[1]
		preload("res://tool_motion.gd").start(game.world,motion[0])
		game.world.elapsed+=preload("res://tool_motion.gd").DURATION*0.6
		await capture("tool-"+motion[0]+"-"+motion[1])
	game.leave_building()
	game.state.player_position=game.world.Grid.center(game.world.SHIP_CELL)+Vector2(64,64)
	await capture("ship")
	game.state.turnips=4
	game.state.star_bulbs=2
	game.state.star_seeds=3
	game.state.fish=2
	game.state.copper=3
	game.state.accept_sword()
	game.inventory()
	await capture("inventory")
	game.close_window()
	game.enter_building("home")
	game.state.player_position=game.world.entry_position()
	await capture("interior-living")
	game.state.player_position=game.world.site_position("bed")
	await capture("interior-bedroom")
	game.begin_rest(240)
	await capture("interior-sleeping")
	game.interact()
	game.state.player_position=game.world.Grid.center(Vector2i(10,9))
	await capture("interior-kitchen-bath")
	game.state.storage_transfer("cabinet",0,"",2)
	for task in game.state.house_tasks: game.state.tidy_house(task)
	game.world.queue_redraw()
	await capture("interior-tidied")
	game.leave_building()
	game.enter_building("ship")
	game.state.player_position=game.world.Grid.center(Vector2i(8,10))
	await capture("ship-engineering")
	game.state.player_position=game.world.Grid.center(Vector2i(7,3))
	await capture("ship-bunks")
	game.open_storage("ship_storage")
	await capture("ship-storage")
	game.close_window()
	game.leave_building()
	game.state.invited=true
	game.state.met_mayor=true
	game.state.minute=600
	game.outdoors.update_villagers(0.0,true)
	game.enter_building("radio")
	game.state.player_position=game.world.site_position("radio")+Vector2(32,0)
	await capture("interior-radio-club")
	game.leave_building()
	for id in ["moss","finch","tavi","mayor","assistant","veteran","iona","store","hall","reed_farm","windmill","mill_home","smithy","tavern","bakery","woodcutter","observatory"]:
		game.enter_building(id)
		game.state.player_position=game.world.entry_position()
		await capture("interior-"+id)
		if id=="observatory":
			game.state.player_position=game.Grid.center(Vector2i(9,5))
			await capture("observatory-telescope")
		game.leave_building()
	game.enter_building("store")
	game.leave_building()
	await capture("store-exit")
	for point in [["east-farm",Vector2i(104,48)],["east-fields",Vector2i(104,53)],["windmill",Vector2i(90,30)],["mill-family-home",Vector2i(99,32)],["smithy",Vector2i(79,49)],["tavern",Vector2i(69,39)],["bakery",Vector2i(75,66)]]:
		game.state.player_position=game.Grid.center(point[1])
		await capture(point[0])
	game.state.player_position=game.world.Grid.center(game.world.MOSS_FIELDS.position+Vector2i(3,2))
	await capture("moss-fields")
	game.state.player_position=game.world.Grid.center(Vector2i(42,81))
	await capture("veteran-cabin")
	game.state.player_position=game.Grid.center(Vector2i(33,76))
	await capture("bram-footpath")
	game.state.player_position=game.Grid.center(Vector2i(5,50))
	await capture("coast-footpath")
	game.state.player_position=game.Grid.center(Vector2i(-20,48))
	await capture("western-lighthouse")
	game.state.player_position=game.Grid.center(Vector2i(-26,53))
	await capture("stone-jetty-tip")
	game.state.player_position=game.Grid.center(Vector2i(game.world.Coast.shoreline(45,game.state.world_seed),45))
	await capture("western-shore")
	game.state.minute=600
	game.outdoors.update_villagers(0,true)
	game.enter_building("keeper")
	await capture("lighthouse-home")
	game.state.player_position=game.Grid.center(Vector2i(7,4))
	await capture("lighthouse-workshop")
	game.talk("keeper")
	await capture("oren-firewood-offer")
	game.ui.modal_box.get_child(3).pressed.emit()
	while game.window_open: game.ui.modal_box.get_child(3).pressed.emit()
	game.state.accept_tool("axe")
	await drag_inventory_item("axe",7)
	await capture("inventory-dragged-axe")
	await drag_inventory_item("axe",6,"",7)
	if game.state.quick_slots[7]!="":
		failed=true
		push_error("FAIL: moving a quick-slot assignment left its source occupied")
	game.close_window()
	var primary=game.state.active_item("primary")
	await drag_inventory_item("wildgrowth",-1,"aux")
	assert(game.state.active_item("primary")==primary,"Dragging an auxiliary spell must preserve the primary item")
	await capture("inventory-two-actions")
	game.close_window()
	var turnips_before=game.state.turnips
	game.state.chest[10]={"id":"turnips","count":3}
	game.open_storage("chest")
	await process_frame
	await drag_controls(game.ui.chest_slots[10],game.ui.inventory_slots[11])
	assert(game.ui.quantity_control!=null,"Dragging a storage stack must offer quantity selection")
	game.ui.quantity_control.value=2
	game.ui.modal_box.get_child(4).pressed.emit()
	assert(game.state.turnips==turnips_before+2 and game.state.chest[10].count==1,"Real storage drag must transfer the chosen quantity")
	await process_frame
	await drag_controls(game.ui.inventory_slots[11],game.ui.chest_slots[11])
	game.ui.quantity_control.value=1
	game.ui.modal_box.get_child(4).pressed.emit()
	assert(game.state.turnips==turnips_before+1 and game.state.chest[11].count==1,"Real inventory drag must deposit its chosen quantity")
	print("NATIVE DRAG PASSED: storage quantities in both directions")
	await process_frame
	await drag_controls(game.ui.auxiliary_button,game.ui.quick_buttons[4])
	assert(game.state.quick_slots[4]=="wildgrowth","An active spell must also drag into a quick slot")
	print("NATIVE DRAG PASSED: active spell to quick slot")
	game.close_window()
	game.inventory()
	game.ui.inventory_tabs.current_tab=1
	await capture("character-stats-quests")
	var paused_time=game.state.total()
	await press_key(game.controls.keys.pause)
	game._process(0.5)
	await press_key(game.controls.keys.pause)
	game._process(0.5)
	assert(game.window_open and game.state.total()==paused_time,"Real Space input must preserve the inventory pause")
	print("NATIVE PAUSE PASSED: inventory remains paused across Space toggles")
	game.close_window()
	game.control_settings()
	await capture("control-bindings")
	game.close_window()
	game.leave_building()
	game.state.player_position=game.Grid.center(Vector2i(63,48))
	for day in [1,29,57,85]:
		game.state.day=day
		game.state.minute=600
		await capture("season-"+game.state.season_name())
	game.state.day=10
	game.state.minute=720
	for weather in ["sunny","partly_cloudy","rainy"]:
		game.state.weather_override=weather
		game.world.elapsed=20
		game.sound.update_weather(weather,true,2)
		await capture("weather-"+weather)
		if weather!="sunny":
			game.world.elapsed=30
			await capture("weather-"+weather+"-later")
	game.state.weather_override="sunny"
	game.state.day=57
	game.state.minute=0
	await capture("calendar-both-full")
	game.state.day=113
	await capture("calendar-both-new")
	game.ui.quest_opened.restore_farmhouse=true
	game.ui.quest_opened.crew_supplies=true
	if not game.ui.log_expanded: game.ui.toggle_log()
	game.ui.update()
	await capture("quest-line-rollouts")
	game.bulletin_board()
	await capture("bulletin-postings")
	game.close_window()
	game.sound_settings()
	await capture("sound-settings")
	assert(game.sound.music.playing,"Native music should play")
	game.sound.play_spell("wildgrowth")
	await game.sound.shutdown()
	if not failed: print("NATIVE VISUAL CHECKS PASSED; sound start/stop passed")
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
