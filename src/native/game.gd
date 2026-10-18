extends Node2D

const State = preload("res://state.gd")
const World = preload("res://world.gd")
const Interface = preload("res://interface.gd")
const Sound = preload("res://sound.gd")
const Grid = preload("res://grid.gd")
const Interior = preload("res://interior.gd")

var state = State.new()
var world: Node2D
var outdoors: Node2D
var rooms: Dictionary = {}
var current_room = ""
var return_position = Vector2.ZERO
var ui: CanvasLayer
var camera: Camera2D
var started = false
var window_open = false
var testing = false
var saving_disabled = false
var nearest: Dictionary = {}
var elapsed = 0.0
var save_elapsed = 0.0
var message_until = 0.0
var resting = 0.0
var activity = ""
var activity_time = 0.0
var sound: Node
var screenshot_requested = false

func _ready() -> void:
	Engine.max_fps = 60
	get_tree().auto_accept_quit = false
	testing = testing or OS.get_cmdline_user_args().has("--smoke-test")
	if not testing: _load_visit()
	world = World.new()
	world.state = state
	add_child(world)
	outdoors=world
	var saved_room=state.location
	var saved_position=state.player_position
	if saved_room=="" and world.blocked(state.player_position): state.player_position=Grid.center(Grid.SPAWN_CELL)
	camera = Camera2D.new()
	camera.zoom = Vector2(2.25,2.25)
	camera.position = state.player_position
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(Grid.WORLD_SIZE.x)
	camera.limit_bottom = int(Grid.WORLD_SIZE.y)
	add_child(camera)
	sound = Sound.new()
	sound.testing = testing
	add_child(sound)
	ui = Interface.new()
	ui.game = self
	add_child(ui)
	if saved_room!="":
		enter_building(saved_room)
		if not world.blocked(saved_position): state.player_position=saved_position
	if testing:
		ui.title_screen.queue_free()
		ui.title_screen = null
		begin()
	if OS.get_cmdline_user_args().has("--smoke-test"): _smoke_screenshot()

func begin() -> void:
	started = true
	sound.start()
	toast("WASD to walk. Moss is waiting at the eastern farm gate.",6.0)
	if saving_disabled: toast("An unreadable save was preserved. This visit will not overwrite it.",8.0)

func _process(dt: float) -> void:
	elapsed += dt
	world.elapsed = elapsed
	if not started: return
	var frozen = window_open and state.pause_mode=="all"
	if not frozen:
		var minutes = dt*3.0
		if resting>0.0 and not window_open:
			minutes = minf(resting,dt*90.0)
			resting -= minutes
			state.energy = minf(100.0,state.energy+minutes*0.2)
			if resting<=0.0:
				save_visit()
				toast("A little rest. A new angle on the same day.")
		state.advance(minutes,window_open)
		var walking_dt=dt*maxf(1.0,minutes/maxf(dt*3.0,0.001))
		outdoors.update_villagers(walking_dt)
		if world!=outdoors: world.update_villagers(walking_dt)
		_move(dt)
		_update_activity(dt)
		for p in world.particles:
			p.life -= dt
			p.pos += p.velocity*dt
			p.velocity.y += 15.0*dt
		world.particles = world.particles.filter(func(p): return p.life>0.0)
	else: world.moving=false
	nearest = world.find_nearest()
	var at_farm=current_room=="home" or (world==outdoors and state.player_position.distance_to(world.site_position("bed"))<110)
	if at_farm and state.invited and not state.met_mayor and state.total()>=2160.0 and not window_open and activity.is_empty():
		mayor()
	save_elapsed += dt
	if save_elapsed>12.0:
		save_elapsed = 0.0
		save_visit()
	if elapsed>message_until: ui.message.text=""
	var context=world.audio_context(state.player_position)
	sound.update_context(state.minute,context.environment,context.season,context.cave_weight,dt)
	world.refresh()
	camera.position = state.player_position.round()+Vector2(20,-5)
	ui.update()

func _move(dt: float) -> void:
	world.moving = false
	if resting>0.0 or not activity.is_empty() or window_open: return
	var direction = Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if direction.is_zero_approx(): return
	world.moving = true
	if absf(direction.x)>absf(direction.y): world.facing="right" if direction.x>0 else "left"
	else: world.facing="down" if direction.y>0 else "up"
	var development_multiplier = 3.0 if OS.is_debug_build() else 1.0
	var distance = direction.normalized()*(160.0 if Input.is_physical_key_pressed(KEY_SHIFT) else 105.0)*development_multiplier*minf(dt,0.05)
	# Resolve each axis independently so walking along a wall never feels sticky.
	# Small steps preserve collision at development running speeds, even on slow frames.
	var steps=maxi(1,ceili(distance.length()/6.0))
	var step=distance/steps
	for i in range(steps):
		if not world.blocked(state.player_position+Vector2(step.x,0)): state.player_position.x+=step.x
		if not world.blocked(state.player_position+Vector2(0,step.y)): state.player_position.y+=step.y

func enter_building(id: String) -> void:
	if world!=outdoors: return
	var building={}
	for b in outdoors.buildings:
		if b.id==id: building=b; break
	if building.is_empty(): return
	return_position=Grid.center(building.cell+Vector2i(int(building.tiles.x/2),building.tiles.y))+Vector2(0,32)
	if not rooms.has(id):
		var room=Interior.new()
		room.state=state
		room.building=building
		room.outdoors=outdoors
		add_child(room)
		rooms[id]=room
	world.visible=false
	world=rooms[id]
	world.visible=true
	current_room=id
	state.location=id
	state.outdoor_position=return_position
	state.player_position=world.entry_position()
	activity=""
	resting=0
	world.update_villagers(0.0,true)
	world.refresh()
	camera.limit_right=int(world.ROOM_SIZE.x)
	camera.limit_bottom=int(world.ROOM_SIZE.y)
	camera.position=state.player_position
	toast("%s · E at the front door to leave" % world.room_name(),4)

func leave_building() -> void:
	if world==outdoors: return
	world.visible=false
	world=outdoors
	world.visible=true
	current_room=""
	state.location=""
	state.player_position=return_position
	world.refresh()
	camera.limit_right=int(Grid.WORLD_SIZE.x)
	camera.limit_bottom=int(Grid.WORLD_SIZE.y)
	camera.position=state.player_position
	activity=""

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode==KEY_F11:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	if not started: return
	match event.physical_keycode:
		KEY_ESCAPE:
			if window_open: close_window()
			else: settings()
		KEY_E: interact()
		KEY_Q: cast_growth()
		KEY_I:
			if window_open: close_window()
			else: inventory()
		KEY_J:
			if window_open: close_window()
			else: journal()
		KEY_M:
			if window_open: close_window()
			else: map_notes()

func hotkey(index: int) -> void:
	if not started: return
	match index:
		0: interact()
		1: cast_growth()
		2: inventory()
		3: journal()

func toast(text: String,duration = 4.0) -> void:
	ui.message.text = text
	message_until = elapsed+duration

func burst(pos: Vector2,color = "a5d8c5",count = 20) -> void:
	for i in range(count):
		var angle = randf()*TAU
		world.particles.append({"pos":pos,"velocity":Vector2(cos(angle)*randf_range(10,35),sin(angle)*25-20),"life":randf_range(1,2),"color":color})

func close_window() -> void:
	window_open = false
	sound.save_preferences()
	ui.close_modal()

func dialog(title: String,role: String,text: String,choices: Array = []) -> void:
	window_open = true
	if choices.is_empty(): choices=[["See you around.",func(): pass]]
	ui.open_modal(title,role,text,choices)

func panel(title: String,eyebrow: String,text: String,choices: Array = []) -> void:
	window_open = true
	if choices.is_empty(): choices=[["Back to the morning",func(): pass]]
	ui.open_modal(title,eyebrow,text,choices,true)

func interact() -> void:
	if not started or window_open: return
	if resting>0.0:
		resting=0.0
		toast("Back on your feet.")
		return
	if activity=="fishing":
		_finish_fishing()
		return
	if not activity.is_empty(): return
	nearest=world.find_nearest()
	if nearest.is_empty():
		toast("Walk closer to a person, garden patch, or landmark.")
		return
	if nearest.type=="plot":
		var was_ripe=state.ripe(nearest.index)
		toast(state.tend(nearest.index),2.5)
		burst(world.plot_position(nearest.index),"e5d0a4" if was_ripe else "b8bf86",20 if was_ripe else 7)
		world.crops.queue_redraw()
		if was_ripe: save_visit()
	elif nearest.type=="person": talk(nearest.id)
	else:
		if nearest.has("door"):
			enter_building(nearest.door)
			return
		match nearest.id:
			"exit": leave_building()
			"shop": talk("tavi")
			"bed": rest_options()
			"pond":
				activity="fishing"
				activity_time=0.0
				toast("Line cast. E when the meter is between 35 and 70.")
			"ore":
				if state.energy<5.0: toast("A little rest would help. There's a bed at the farm.")
				else:
					activity="mining"
					activity_time=0.0
			"sign": dialog("A weathered sign","BRIAR GLEN","East: town and market. Southwest: the old mill pond. Southeast: copper outcrop. Northwest: nothing in particular, according to the official map.")
			"radio": radio()

func cast_growth() -> void:
	if not started or window_open or resting>0.0 or not activity.is_empty(): return
	nearest=world.find_nearest()
	if nearest.get("type")!="plot":
		toast("Stand near a planted, watered garden patch.")
		return
	if state.grow(nearest.index):
		sound.play_spell("wildgrowth")
		burst(world.plot_position(nearest.index),"a5d8c5",30)
		toast("Wildgrowth. The roots remember summer.")
		world.crops.queue_redraw()
	else: toast("Needs a growing, watered crop and 15 attunement.")

func _update_activity(dt: float) -> void:
	if activity.is_empty(): return
	activity_time+=dt
	if activity=="mining" and activity_time>=1.1:
		state.mine()
		activity=""
		burst(world.site_position("ore")-Vector2(0,Grid.TILE_SIZE*0.5),"d4ae7b",18)
		toast("+1 copper ore. A quiet seam, no monsters.")
		save_visit()
	elif activity=="fishing" and activity_time>18.0:
		activity=""
		toast("You reel in the line. The pond can wait.")

func fishing_position() -> float:
	return (sin(maxf(0.0,activity_time-1.2)*1.7)+1.0)*0.5

func _finish_fishing() -> void:
	if activity_time<1.2:
		toast("Let the line settle first.",2.0)
		return
	var marker=fishing_position()
	if marker>0.35 and marker<0.7:
		state.fish+=1
		burst(state.player_position-Vector2(0,10),"9ed6cf")
		toast("+1 pond silverfin. Tavi will buy this.")
		save_visit()
	else: toast("It slipped away. No bait lost. Try again.")
	activity=""

func rest_options() -> void:
	dialog("The farmhouse","A BED, A ROOF, A LITTLE QUIET","The bed smells of cedar. The window looks out over your patch of soil. How long would you like to rest?",[
		["Rest for four hours",func(): resting=240.0; toast("Resting. The world keeps turning. E to get up.",6.0)],
		["Rest until the appointment · Spring 02, 11:45" if state.day<2 else "Rest until the next 11:45",func():
			if state.day<2: resting=1440.0+705.0-state.total()
			else:
				resting=fposmod(705.0-state.minute,1440.0)
				if resting<1.0: resting=1440.0],
		["Not tired yet.",func(): pass]])

func talk(id: String) -> void:
	match id:
		"veteran":
			dialog("The veteran","A CABIN IN THE SOUTH WOODS","I served in the army. If you're heading toward the other kingdom, come and talk to me before you go. And take this old blade. Rust comes off. Being unprepared is harder to fix.",[
				["Accept the rusty sword" if state.rusty_sword==0 else "Thank you for the sword",func():
					if state.accept_sword(): save_visit(); toast("Rusty sword added to your satchel. Select it to equip.",6)],
				["What should we know about the other kingdom?",func(): dialog("The veteran","RETIRED ARMY","Start by remembering that a kingdom's people and its government aren't the same thing. I learned that in uniform. Some of the people who helped me most lived on the other side of the border.")]])
		"mayor":
			if state.invited and not state.met_mayor and state.total()>=2160: mayor()
			else: dialog("Mayor Alder","BRIAR GLEN","Good to see you out and about. Most days I'm at the town hall, with a break in the square at noon.")
		"moss":
			if not state.invited:
				dialog("Moss","NEIGHBOR · SOUTH FARM","Well. You look like you've had a long walk. This place has been empty since last harvest. You can stay tonight. Tomorrow at noon, I'll bring the mayor round. Best have someone here to meet him.",[
					["Thank you. Tomorrow at noon. We'll be here.",func(): state.invited=true; save_visit(); toast("Appointment noted · Spring 02, noon · your farmhouse",6.0)],
					["What can we do with this soil?",func(): dialog("Moss","NEIGHBOR · SOUTH FARM","Good earth doesn't care where you're from. Turn a patch, plant, give it water. Three hours for moon turnips here. Iona's lent you a little magic if patience isn't your strong suit.",[["And the mayor?",func(): talk("moss")]])]])
			elif not state.met_mayor and state.total()>=2160.0: mayor()
			else: dialog("Moss","NEIGHBOR · SOUTH FARM","Settling in, then? Tavi buys produce in town. Good neighbor, Tavi. Crosses the border every spring to see family. Funny how a map can make a long journey out of a short road." if state.met_mayor else "Tomorrow at noon, right here. Till then, make yourself comfortable. The pond's good fishing, and the bed's yours if you need a rest.")
		"tavi":
			dialog("Tavi","TRAVELING MERCHANT","Seeds, supper, a good road home. That's most of a life, isn't it? I'm heading across the border for my sister's festival next month. Until then, your turnips are very welcome here.",[
				["Sell produce · %d crowns" % (state.turnips*8+state.fish*10+state.star_bulbs*12),func():
					if state.sell(): save_visit(); toast("Sold. Locally grown, very far from home.")
					else: toast("Bring turnips or silverfin to sell.")],
				["Buy 5 moon-turnip seeds · 10 crowns",func():
					if state.buy_seeds(): save_visit(); toast("Five seeds tucked into your satchel.")
					else: toast("You need 10 crowns.")],
				["Buy 3 star-bulb seeds · 12 crowns",func():
					if state.buy_star_seeds(): save_visit(); toast("Three star-bulb seeds. Select them in your satchel before planting.",6)
					else: toast("You need 12 crowns.")],
				["Just passing through.",func(): pass]])
		"iona": dialog("Iona","FIELD MAGICIAN","Moss says you're new. I've left a little Wildgrowth in your hands. Plant a seed, water it, then press Q beside it. Fifteen attunement; yours returns on its own. Farmers pay me to do whole fields. You can start with one turnip.")
		"finch": dialog("Finch","RADIO CLUB SECRETARY","You're welcome at the club. Last week we heard a dance band from the far side of the border. Clear as anything. Governments can argue all they like; the air doesn't stop at a checkpoint.",[["What's on the air today?",radio],["I'll come back sometime.",func(): pass]])
		"vale":
			if state.delivered: dialog("Chief Vale","CHIEF ENGINEER · SECURE CREW LINK","Copper seated. Local crew link stable. I can hear you all the way to town now. The cloak is holding. Go on, Captain. Find something worth telling me about.")
			else: dialog("Chief Vale","CHIEF ENGINEER · SECURE CREW LINK","Cloak stable. Engines... less so. Three pieces of local copper would get our short-range crew link behaving. There's an exposed seam southeast of town. Safe enough. And Captain? Eat something that didn't come out of a ration packet.",[
				["Hand over three copper." if state.copper>=3 else "I'll look for copper at the southeast outcrop.",func():
					if state.copper>=3:
						state.copper-=3
						state.delivered=true
						save_visit()
						burst(state.player_position,"a3d4d0")
						toast("Crew link restored. One small connection home.",6.0)],
				["How long do we have?",func(): dialog("Chief Vale","CHIEF ENGINEER","As long as the cloak holds, we have room to breathe. No signals. No active scans. I'll keep the lights off. You keep us fed.")]])

func mayor() -> void:
	if not state.meet_mayor(): return
	save_visit()
	dialog("Mayor Alder","BRIAR GLEN · AT YOUR FARM","Moss tells me you're looking for a new beginning. We could use a few more hands, and this farm could use a few more mornings. You're welcome to make a home here.",[
		["We've come a long way. Thank you.",func(): dialog("A voice behind the mayor","AN AIDE, LESS CONVINCED","A long way from which side of the border, exactly? We can't be too careful these days.",[
			["Let the mayor answer.",func(): dialog("Mayor Alder","BRIAR GLEN","We can be careful and civil at the same time. For today, let's see what grows. Moss, leave them be. They've got a farm to settle.",[
				["A place to begin.",func(): toast("A home in Briar Glen. The rest can wait.",7.0); burst(state.player_position,"e7cf8e",30)]])]])]])

func radio() -> void:
	dialog("Briar Glen Radio","LOCAL SERVICE · 1040","...a fair morning across the valley. The north road is open to travelers, with delays at the border crossing. Tonight: the Radio Club's spring music hour. And if anyone has borrowed Mrs. Bell's ladder, she would like it back.")

func inventory() -> void:
	window_open=true
	ui.open_inventory()

func inventory_stacks() -> Array:
	var stacks: Array=[]
	for id in ["seeds","star_seeds","turnips","fish","star_bulbs","copper","rusty_sword"]:
		var count=int(state.get(id))
		if count>0: stacks.append({"id":id,"count":count})
	return stacks

func use_inventory_item(id: String) -> void:
	if id in ["seeds","star_seeds"]:
		state.selected_seed=id
		toast("Selected %s for planting." % ui.Items.CATALOG[id].name)
	elif id=="rusty_sword" and state.rusty_sword>0:
		state.equipped="rusty_sword"
		toast("Rusty sword equipped.")
	elif state.consume(id): toast("A little better. %s eaten." % ui.Items.CATALOG[id].name)
	else: toast("Nothing to restore." if ui.Items.FOOD.has(id) else "Keep this for crafting.")
	save_visit()
	inventory()

func journal() -> void:
	panel("Captain's field notes","FIRST LANDING","%s A roof for the night · speak with Moss.\n\n%s Tomorrow, at noon · Spring 02, farmhouse.\nThe mayor will return if we miss him.\n\n%s Something of our own · harvest a moon turnip.\nTavi buys produce at the market.\n\n%s A quiet channel home · bring Chief Vale 3 copper.\nThe exposed seam is southeast of town." % ["✓" if state.invited else "○","✓" if state.met_mayor else "○","✓" if state.harvested>0 else "○","✓" if state.delivered else "○"])

func map_notes() -> void:
	panel("Around Briar Glen","MOSS'S HAND-DRAWN DIRECTIONS","↖ Hidden ship & Chief Vale\n↑ Radio Club & Finch\n← Your farm & Moss\n→ Town square, homes & Tavi's cart\n↑ Iona's tower in the northern mountains\n↙ Pond & fishing jetty\n↘ Safe copper outcrop\n\nTavi keeps the cart 08:00–20:00, with lunch at 12:30. Iona wakes at noon and sleeps around 05:00.\nFollow the sandy lanes; neighbors have places to be.")

func settings() -> void:
	if not started: return
	var selected = state.pause_mode
	var choices = [
		[("✓ " if selected=="none" else "")+"Time continues · default",func(): state.pause_mode="none"; settings()],
		[("✓ " if selected=="clock" else "")+"Stop calendar · simulation continues",func(): state.pause_mode="clock"; settings()],
		[("✓ " if selected=="all" else "")+"Pause entire world",func(): state.pause_mode="all"; settings()],
		["Sound · music, ambience, and spells",sound_settings],
		["Save this visit",func(): if save_visit(): toast("Visit saved inside this project.")],
		["Begin a new visit…",reset_confirmation],
		["Return to the farm",func(): pass],
		["Save and quit",quit_game]]
	if OS.is_debug_build(): choices.insert(4,["Development tools · advance time",development_tools])
	panel("Make yourself comfortable","FIELD SETTINGS","While a conversation or menu is open:",choices)
	if OS.is_debug_build(): ui.modal.get_child(1).position.y=75

func development_tools() -> void:
	if not OS.is_debug_build(): return
	panel("A little further along","DEVELOPMENT TOOLS","Advance the shared calendar and crop growth. A season currently means 28 days, pending calendar design.\n\nCurrent date: %s %02d, year %d · %02d:%02d" % [state.season_name().capitalize(),state.season_day(),state.calendar_year(),int(state.minute/60.0),int(state.minute)%60],[
		["Advance 1 hour",func(): advance_development_time(60.0)],
		["Advance 12 hours",func(): advance_development_time(720.0)],
		["Advance 24 hours",func(): advance_development_time(1440.0)],
		["Advance 1 season · 28 days",func(): advance_development_time(State.DEVELOPMENT_SEASON_DAYS*1440.0)],
		["Back to settings",settings]])

func advance_development_time(minutes: float) -> void:
	if not OS.is_debug_build(): return
	resting=0.0
	activity=""
	state.advance(minutes)
	outdoors.update_villagers(0.0,true)
	if world!=outdoors: world.update_villagers(0.0,true)
	world.refresh()
	ui.update()
	save_visit()
	development_tools()

func sound_settings() -> void:
	panel("The sound of a place","MUSIC · ENVIRONMENT · SPELLS","Playful strings and keys, birds by day, quiet crickets by night. Water echoes near the mine entrance. Each layer has its own volume.",[
		["Preview Wildgrowth",func(): sound.play_spell("wildgrowth"); sound_settings()],
		["Back to settings",settings]])
	ui.add_volume_slider("Music",sound.music_level,func(value): sound.set_level("music",value))
	ui.add_volume_slider("Ambience",sound.ambience_level,func(value): sound.set_level("ambience",value))
	ui.add_volume_slider("Spell effects",sound.effects_level,func(value): sound.set_level("effects",value))

func reset_confirmation() -> void:
	panel("Begin again?","YOUR SAVED VISIT","This replaces this prototype's save inside the project. The story and farm will start fresh.",[
		["Yes, start a fresh landing",func():
			if world!=outdoors: leave_building()
			state=State.new()
			outdoors.state=state
			for room in rooms.values(): room.state=state
			outdoors.update_villagers(0.0,true)
			saving_disabled=false
			activity=""
			resting=0.0
			save_visit()
			toast("A new morning. A new beginning.")],
		["Keep this visit",settings]])

func save_path() -> String:
	return ProjectSettings.globalize_path("res://").path_join("../../internal/first-landing.json").simplify_path()

func save_visit() -> bool:
	if testing or saving_disabled: return false
	sound.save_preferences()
	var target = save_path()
	var file = FileAccess.open(target+".tmp",FileAccess.WRITE)
	if file==null:
		toast("Could not save. Keep the game open to continue.")
		return false
	file.store_string(JSON.stringify(state.to_dict(),"\t"))
	file.close()
	if DirAccess.rename_absolute(target+".tmp",target)!=OK:
		toast("Could not finalize the save. Your previous save is preserved.")
		return false
	return true

func _load_visit() -> void:
	if not FileAccess.file_exists(save_path()): return
	var raw=FileAccess.get_file_as_string(save_path())
	var parser=JSON.new()
	if parser.parse(raw)!=OK or not state.restore(parser.data): saving_disabled=true

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()

func quit_game() -> void:
	if started: save_visit()
	await sound.shutdown()
	get_tree().quit()

func _smoke_screenshot() -> void:
	for i in range(6): await get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		var path=ProjectSettings.globalize_path("res://../../internal/verification/native-farm.png").simplify_path()
		var result=get_viewport().get_texture().get_image().save_png(path)
		print("Native screenshot: ",path," result=",result)
	print("NATIVE SMOKE PASSED: scene, world, interface and simulation loaded")
	await sound.shutdown()
	get_tree().quit()
