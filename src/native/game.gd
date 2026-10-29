extends Node2D

const State = preload("res://state.gd")
const World = preload("res://world.gd")
const Interface = preload("res://interface.gd")
const Sound = preload("res://sound.gd")
const Grid = preload("res://grid.gd")
const Interior = preload("res://interior.gd")
const Cave = preload("res://cave.gd")
const Opening = preload("res://opening.gd")
const Art = preload("res://art.gd")
var controls=preload("res://controls.gd").new()
var remapping=""
var opening: CanvasLayer
const BRIEFING=[
	["Captain","Status report?"],
	["Chief Vale","We're in one piece. The ship... less so. Engines are gone, long-range comms are dead, and the distress transmitter took a direct hit. We can't call anyone."],
	["Captain","What's your estimate?"],
	["Chief Vale","Ask me again once I've crawled through the wreckage. I'll keep working, but I'm going to need supplies. Quite a lot of them, I suspect. Check in with me each day, Captain. I'll report what I've managed, and the break will do us both good."],
	["Chief Vale","There's something else. That attack ship had time to send a signal before we finished it. I doubt it was saying goodbye. Someone will come looking."],
	["Captain","Then we'll get what you need. First order of business: the cloak."],
	["Chief Vale","Already on it. I'm bringing the emergency gravitic power sink online. As long as this planet keeps its gravity well, the cloak should hold. Rather counting on that. It leaves us precious little power for anything else."],
	["Captain","Keeping that cloak running is our main priority until rescue arrives. Outside of that, the basics: food and water, and our local commlink repeater so we can stay in contact."],
	["Chief Vale","Three copper bars would get our local repeater talking again. Raw ore won't do; we'll need it refined. The last scan showed a deposit southeast of a settlement below us. A couple of kilometers, give or take. If there's a smith in that settlement, perhaps they can help. With the scanners gone, I can't tell you any more than that."],
	["Captain","What have we got for food?"],
	["Chief Vale","Six emergency rations stowed by the bunks. One a day for each of us doesn't leave much breathing room. We'll need fresh water and something local to eat. And if you find a kitchen, I'd dearly love a meal that doesn't come out of a foil packet. Leave me something in the locker while I'm working, would you?"],
	["Captain","We'll find water, food, and the supplies you need. Keep the cloak stable, Vale. We'll start by seeing who's down the mountain."]]

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
var world_paused=false
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
var title_backdrop_active=false
var title_camera: Dictionary={}
var chest_selected=""
var storage_name="chest"
var rest_return_position=Vector2.ZERO
var conversation_members: Array=[]
var conversation_sequence=false
var welcome_entry_times: Dictionary={}
var conversation_steps=0
var conversation_location=""
var conversation_anchor=Vector2.ZERO
const WELCOME_MEMBERS=["mayor","moss","assistant"]
const WELCOME_POSITIONS=[Vector2i(2,10),Vector2i(3,12),Vector2i(5,12)]
var departure_paths: Dictionary={}
var escort_path: Array=[]
var fishing_species="fish"
var fishing_phase=0.0
var fishing_rng=RandomNumberGenerator.new()

func _ready() -> void:
	Engine.max_fps = 60
	fishing_rng.randomize()
	get_tree().auto_accept_quit = false
	testing = testing or OS.get_cmdline_user_args().has("--smoke-test")
	if not testing: controls.load_keys()
	if not testing: _load_visit()
	world = World.new()
	world.state = state
	add_child(world)
	outdoors=world
	var saved_room=state.location
	var saved_position=state.player_position
	if saved_room=="" and world.blocked(state.player_position): state.player_position=Grid.center(Grid.SPAWN_CELL)
	camera = Camera2D.new()
	camera.zoom = Vector2(1.9125,1.9125)
	camera.position = state.player_position
	camera.limit_left = Grid.WORLD_CELLS.position.x*Grid.TILE_SIZE
	camera.limit_top = 0
	camera.limit_right = int(Grid.WORLD_SIZE.x)
	camera.limit_bottom = int(Grid.WORLD_SIZE.y)
	add_child(camera)
	sound = Sound.new()
	sound.testing = testing
	add_child(sound)
	sound.lightning.connect(func(): outdoors.weather_effects.strike())
	ui = Interface.new()
	ui.game = self
	add_child(ui)
	if saved_room!="":
		enter_building(saved_room)
		if not world.blocked(saved_position): state.player_position=saved_position
	if not testing: show_title_backdrop()
	if testing:
		ui.title_screen.queue_free()
		ui.title_screen = null
		begin()
	if OS.get_cmdline_user_args().has("--smoke-test"): _smoke_screenshot()

func update_weather_sound(dt: float) -> void:
	var snow=state.season_name()=="winter"
	var lightning=not snow or preload("res://weather.gd").thundersnow(state.world_seed,state.day)
	sound.update_weather(state.weather_name(),world==outdoors,dt,lightning,snow)

func choose_journey_mode() -> void:
	panel("Before we begin","YOUR JOURNEY","Choose how you want to live here. Hardcore adds hunger and thirst: drink before three days pass, and eat before three weeks. Going without blocks energy and mana recovery and costs health. You can change this in Settings.",[["A gentler journey",func(): start_journey(false)],["Hardcore · food and water matter",func(): start_journey(true)]])

func show_title_backdrop() -> void:
	if title_backdrop_active: return
	title_backdrop_active=true
	title_camera={"position":camera.position,"left":camera.limit_left,"top":camera.limit_top,"right":camera.limit_right,"bottom":camera.limit_bottom}
	world.visible=false
	outdoors.visible=true
	outdoors.update_villagers(0.0,true)
	var views=[Vector2i(98,49),Vector2i(104,51),Vector2i(110,46)]
	camera.position=Grid.center(views[randi()%views.size()])
	camera.limit_left=Grid.WORLD_CELLS.position.x*Grid.TILE_SIZE
	camera.limit_top=0
	camera.limit_right=int(Grid.WORLD_SIZE.x)
	camera.limit_bottom=int(Grid.WORLD_SIZE.y)

func restore_title_backdrop() -> void:
	if not title_backdrop_active: return
	title_backdrop_active=false
	outdoors.visible=world==outdoors
	world.visible=true
	camera.position=title_camera.position
	camera.limit_left=title_camera.left
	camera.limit_top=title_camera.top
	camera.limit_right=title_camera.right
	camera.limit_bottom=title_camera.bottom

func start_journey(hardcore: bool) -> void:
	state.needs.hardcore=hardcore
	state.needs.mode_chosen=true
	close_window()
	begin()

func drink_freshwater() -> void:
	state.needs.drink()
	toast("A long, cool drink. Hydration restored.")
	save_visit()

func begin() -> void:
	if not testing and not state.intro_complete and not state.needs.mode_chosen:
		choose_journey_mode()
		return
	restore_title_backdrop()
	started = true
	sound.start()
	if not state.intro_complete:
		opening=Opening.new()
		opening.game=self
		add_child(opening)
	elif not state.briefing_complete: show_briefing()
	elif state.welcome_phase=="meeting":
		place_welcome_party()
		mayor()
	elif state.welcome_phase=="arriving":
		state.welcome_phase="waiting"
		mayor()
	elif state.welcome_phase=="departing": place_welcome_party()
	elif state.welcome_phase=="moss_lesson":
		place_welcome_party()
		for id in ["mayor","assistant"]: world.villagers[id].visible=false
		moss_lesson()
	elif state.welcome_phase=="moss_departing":
		place_welcome_party()
		for id in ["mayor","assistant"]: world.villagers[id].visible=false
	else: toast("WASD to walk. E to interact. Follow the mountain path down.",6)
	if saving_disabled: toast("An unreadable save was preserved. This visit will not overwrite it.",8.0)

func finish_intro() -> void:
	opening=null
	state.intro_complete=true
	state.player_position=Grid.center(Vector2i(7,9))
	world.refresh()
	show_briefing()

func show_briefing(step: int=0) -> void:
	if step>=BRIEFING.size():
		state.briefing_complete=true
		end_conversation()
		save_visit()
		toast("Follow the mountain descent. Keep the ship's location to yourselves.",7)
		return
	state.abandoned_day.erase("vale")
	outdoors.villagers.vale.data.sleeping=false
	begin_conversation(["vale"],true)
	var line=BRIEFING[step]
	dialog(line[0],"CLOAKED SHIP · AFTER THE CRASH",line[1],[["Continue",func(): show_briefing(step+1)]])

func _process(dt: float) -> void:
	if world_paused: return
	elapsed += dt
	world.elapsed = elapsed
	outdoors.elapsed = elapsed
	for room in rooms.values(): room.elapsed = elapsed
	if not started:
		if title_backdrop_active: outdoors.update_villagers(dt)
		return
	if opening!=null: return
	if not conversation_members.is_empty() and (state.location!=conversation_location or state.player_position.distance_to(conversation_anchor)>160): close_window()
	if state.welcome_phase=="waiting":
		state.welcome_elapsed=state.welcome_elapsed+dt if state.house_tasks.values().all(func(done): return done) else 0.0
		if state.welcome_elapsed>=1:
			if window_open: close_window()
			mayor()
	var staged=clock_held()
	var frozen = (window_open and state.pause_mode=="all") or staged
	if not frozen:
		var minutes = dt
		var sleeping=resting>0.0 and not window_open
		if sleeping:
			minutes = minf(resting,dt*90.0)
			resting -= minutes
			if resting<=0.0:
				state.player_position=rest_return_position
				save_visit()
				toast("A little rest. A new angle on the same day.")
		state.advance(minutes,window_open,sleeping)
		for damage in state.damage_events: world.combat_text("-%d" % int(damage),state.player_position,Color("c895ed"))
		state.damage_events.clear()
		var walking_dt=dt*maxf(1.0,minutes/maxf(dt,0.001))
		for room in rooms.values():
			if room is Interior: room.prepare_departures()
		outdoors.update_villagers(walking_dt)
		for room in rooms.values():
			if room is Interior: room.update_villagers(walking_dt)
		if current_room=="cave":
			world.update_enemies(dt)
		if state.health<=0:
			state.player_position=world.entry_position() if world!=outdoors else Grid.center(Grid.SPAWN_CELL)
			state.health=25
			resting=0
			toast("You stagger back to the cave entrance. Eat or rest before returning." if current_room=="cave" else "You find a safe place to catch your breath. Eat or rest before carrying on.",6)
		_move(dt)
		_update_activity(dt)
		for p in world.particles:
			p.life -= dt
			p.pos += p.velocity*dt
			p.velocity.y += 15.0*dt
		world.particles = world.particles.filter(func(p): return p.life>0.0)
		for entry in world.combat_texts: entry.age+=dt
		world.combat_texts=world.combat_texts.filter(func(entry):return entry.age<entry.duration)
	else:
		world.moving=false
		if state.welcome_phase=="escorting":
			update_escort(dt)
			outdoors.update_villagers(dt)
		elif state.welcome_phase=="arriving": update_welcome_arrival(dt)
		elif state.welcome_phase=="departing": update_welcome_departure(dt)
		elif state.welcome_phase=="moss_departing": update_welcome_departure(dt,["moss"])
		elif staged and state.welcome_phase!="meeting":
			_move(dt)
			_update_activity(dt)
			outdoors.update_villagers(dt)
	nearest = world.find_nearest()
	var near_moss=state.player_position.distance_to(outdoors.villagers.moss.position)<75
	if world==outdoors and not state.invited and state.briefing_complete and near_moss and not window_open:
		state.abandoned_day.erase("moss")
		outdoors.villagers.moss.data.sleeping=false
		outdoors.villagers.moss.visible=true
		talk("moss")
	var at_farm=current_room=="home" or (world==outdoors and state.player_position.distance_to(world.site_position("bed"))<110)
	if at_farm and state.welcome_phase=="complete" and state.mayor_available() and not window_open and activity.is_empty():
		mayor()
	save_elapsed += dt
	if save_elapsed>12.0:
		save_elapsed = 0.0
		save_visit()
	if elapsed>message_until: ui.message.text=""
	var context=world.audio_context(state.player_position)
	sound.update_context(state.minute,context.environment,context.season,context.cave_weight,dt)
	update_weather_sound(dt)
	world.refresh()
	camera.position = state.player_position.round()+Vector2(20,-5)
	ui.update()

func clock_held() -> bool:
	return not state.ship_departed or state.welcome_phase in ["escorting","waiting","arriving","meeting","departing","moss_lesson","moss_departing"] or ("moss" in conversation_members and not state.invited)

func cutscene_active() -> bool:
	return opening!=null or welcome_control_locked() or ui.dialogue_open

func welcome_control_locked() -> bool:
	return state.welcome_phase in ["escorting","arriving","meeting","departing","moss_lesson","moss_departing"] or ("moss" in conversation_members and not state.invited)

func update_escort(dt: float) -> void:
	if escort_path.is_empty():
		escort_path=outdoors.farmhouse_approach(Grid.world_to_cell(state.player_position))
	var distance=dt*180
	while distance>0 and not escort_path.is_empty():
		var target: Vector2=escort_path[0]
		var step=state.player_position.distance_to(target)
		if target.distance_to(state.player_position)>0.1: world.facing=World.Bodies.facing_for(target-state.player_position)
		state.player_position=state.player_position.move_toward(target,distance)
		distance-=step
		if state.player_position.distance_to(target)<0.1: escort_path.pop_front()
	world.moving=true
	if escort_path.is_empty():
		state.welcome_phase="unvisited"
		enter_building("home")
		save_visit()

func _move(dt: float) -> void:
	world.moving = false
	if welcome_control_locked(): return
	if resting>0.0 or not activity.is_empty() or window_open: return
	var direction = Vector2(
		float(controls.held("right") or controls.held("right_arrow"))-float(controls.held("left") or controls.held("left_arrow")),
		float(controls.held("down") or controls.held("down_arrow"))-float(controls.held("up") or controls.held("up_arrow")))
	if direction.is_zero_approx(): return
	world.moving = true
	world.player.data.seated=false
	if absf(direction.x)>absf(direction.y): world.facing="right" if direction.x>0 else "left"
	else: world.facing="down" if direction.y>0 else "up"
	var development_multiplier = 3.0 if OS.is_debug_build() else 1.0
	var distance = direction.normalized()*(160.0 if controls.held("run") else 105.0)*development_multiplier*minf(dt,0.05)
	# Resolve each axis independently so walking along a wall never feels sticky.
	# Small steps preserve collision at development running speeds, even on slow frames.
	var steps=maxi(1,ceili(distance.length()/6.0))
	var step=distance/steps
	for i in range(steps):
		try_player_step(Vector2(step.x,0))
		try_player_step(Vector2(0,step.y))

func try_player_step(delta: Vector2) -> bool:
	if world is Interior and world.player_blocked(state.player_position+delta): return false
	if world is Cave:
		if world.blocked(state.player_position+delta): return false
		state.player_position+=delta
		return true
	return preload("res://npc_bodies.gd").player_step(world,delta,outdoors.conversation_holds)

func enter_building(id: String) -> void:
	if world!=outdoors: return
	var building={}
	for b in outdoors.buildings:
		if b.id==id: building=b; break
	if id=="ship": building={"id":"ship","cell":World.SHIP_CELL+Vector2i(-1,0),"tiles":Vector2i(2,2)}
	if id=="cave": building={"id":"cave","cell":World.CAVE_MOUTH.position+Vector2i.DOWN,"tiles":Vector2i(2,1)}
	if id=="home" and not state.invited and state.briefing_complete:
		if outdoors.villagers.moss.position.distance_to(state.player_position)<75: talk("moss")
		else: toast("Speak to the farmer waiting at the foot of the mountain trail.")
		return
	if building.is_empty(): return
	if id=="observatory" and outdoors.Schedule.observations_closed(state.day,state.minute):
		dialog("A sign on the door","OBSERVATORY","A sign is hanging on the door. It reads: 'closed to-day and every Rift for observations'")
		return
	var residents=outdoors.people.filter(func(person):return outdoors.Schedule.home_stop(person.id).room==id)
	if id!="ship" and residents.any(func(person):return outdoors.stop_for(person.id).sleeping and outdoors.villagers[person.id].data.get("sleeping",false) and outdoors.villagers[person.id].data.get("room","")==id) and not residents.any(func(person):return state.relationship(person.id)=="Loved"):
		toast("The household has gone to bed. Best come back in the morning.")
		return
	return_position=outdoors.exit_position(building)
	var room_key="cave_%d" % state.cave_level if id=="cave" else id
	if not rooms.has(room_key):
		var room=Cave.new() if id=="cave" else Interior.new()
		room.state=state
		room.building=building
		room.outdoors=outdoors
		add_child(room)
		rooms[room_key]=room
	world.visible=false
	world=rooms[room_key]
	world.visible=true
	current_room=id
	state.location=id
	state.outdoor_position=return_position
	state.player_position=world.entry_position()
	if id=="home" and state.welcome_phase=="unvisited":
		state.welcome_phase="waiting"
		state.welcome_elapsed=0
		prepare_welcome_party()
	activity=""
	resting=0
	world.update_villagers(0.0,true)
	world.refresh()
	var visible_size=get_viewport_rect().size/camera.zoom
	var margin=(visible_size-world.ROOM_SIZE).max(Vector2.ZERO)*0.5
	camera.limit_left=floori(-margin.x)
	camera.limit_top=floori(-margin.y)
	camera.limit_right=ceili(world.ROOM_SIZE.x+margin.x)
	camera.limit_bottom=ceili(world.ROOM_SIZE.y+margin.y)
	camera.position=state.player_position
	toast("%s · E at the front door to leave" % world.room_name(),4)
	if id=="cave" and state.cave_level==0 and not state.cave_intro_seen:
		state.cave_intro_seen=true
		save_visit()
		dialog("Captain","AT THE CAVE ENTRANCE","Oh, good. Someone's left a pickaxe against that barrel. I'll need that to break through the rocks and get at any ore. Better take it with us.")

func change_cave_level(direction: int) -> void:
	if not world is Cave or direction not in [-1,1] or state.cave_level+direction not in range(3): return
	var destination=state.cave_level+direction
	world.visible=false
	world=outdoors
	state.cave_level=destination
	enter_building("cave")
	if direction<0: state.player_position=Grid.center(world.chambers.back().get_center())
	else: state.player_position=Grid.center(world.layout.entry)
	world.refresh()
	camera.position=state.player_position
	save_visit()

func leave_building() -> void:
	if world==outdoors: return
	if current_room=="home" and (state.welcome_phase=="waiting" or welcome_control_locked()):
		toast("Wait for Moss and the mayor's party to finish their visit.")
		return
	if current_room=="ship" and not state.briefing_complete:
		show_briefing()
		return
	if current_room=="ship": state.ship_departed=true
	world.visible=false
	world=outdoors
	world.visible=true
	world.facing="down"
	current_room=""
	state.location=""
	state.player_position=return_position
	world.refresh()
	camera.limit_left=Grid.WORLD_CELLS.position.x*Grid.TILE_SIZE
	camera.limit_top=0
	camera.limit_right=int(Grid.WORLD_SIZE.x)
	camera.limit_bottom=int(Grid.WORLD_SIZE.y)
	camera.position=state.player_position
	activity=""

func _input(event: InputEvent) -> void:
	if remapping!="" and event is InputEventKey and event.pressed and not event.echo:
		var action=remapping
		remapping=""
		if event.physical_keycode!=KEY_ESCAPE: remap_control(action,event.physical_keycode)
		control_settings()
		get_viewport().set_input_as_handled()
		return
	if started and not window_open and opening==null and not world_paused and controls.matches(event,"inventory_row"):
		state.cycle_inventory_row()
		ui.update()
		get_viewport().set_input_as_handled()
		return
	var advance_key=controls.matches(event,"pause") or controls.matches(event,"primary")
	var advance_click=event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT
	if started and (advance_key or advance_click):
		if opening!=null:
			opening.advance()
			get_viewport().set_input_as_handled()
			return
		if window_open and ui.dialogue_open and advance_key:
			get_viewport().set_input_as_handled()
			return
	if started and controls.matches(event,"pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	world_paused=not world_paused
	if world_paused: get_viewport().gui_release_focus()
	if opening!=null: opening.set_process(not world_paused)
	ui.update()

func _unhandled_input(event: InputEvent) -> void:
	if world_paused: return
	if not event is InputEventMouseButton or not event.pressed: return
	if not started or window_open or opening!=null or welcome_control_locked(): return
	if event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]:
		if world.find_nearest().is_empty() and state.active_item("primary" if event.button_index==MOUSE_BUTTON_LEFT else "aux") not in ["rusty_sword","pickaxe","axe","sickle","hearthmend","emberthread"]: return
		activate_channel("primary" if event.button_index==MOUSE_BUTTON_LEFT else "aux")
		get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if controls.matches(event,"fullscreen"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	if not started: return
	if controls.matches(event,"pause"):
		toggle_pause()
		return
	if world_paused: return
	if opening!=null: return
	if welcome_control_locked(): return
	for i in range(8):
		if controls.matches(event,"slot"+str(i+1)): select_quick_slot(i); return
	if controls.matches(event,"menu"):
		if window_open: close_window()
		else: settings()
	elif controls.matches(event,"primary"): activate_channel("primary")
	elif controls.matches(event,"aux"): activate_channel("aux")
	elif controls.matches(event,"inventory"):
		if window_open: close_window()
		else: inventory()
	elif controls.matches(event,"journal"):
		if window_open: close_window()
		else: journal()
	elif controls.matches(event,"map"):
		if window_open: close_window()
		else: map_notes()

func activate_channel(channel: String) -> void:
	if action_busy(): return
	state.action_channel=channel
	if state.active_item() in ["hearthmend","emberthread"] or (channel=="aux" and state.active_item()=="wildgrowth"): begin_action()
	if state.active_item() in ["hearthmend","emberthread"]: cast_local_spell(state.active_item())
	elif channel=="primary": interact()
	elif state.active_item()=="sit": sit_on_bench()
	elif state.active_item()=="wildgrowth": cast_growth()
	elif state.active_item()!="": interact()
	state.action_channel="primary"

func action_busy() -> bool:
	return world.elapsed-world.player.data.get("action_started",-10.0)<0.6

func begin_action() -> void:
	world.player.data.action_started=world.elapsed

func sit_on_bench() -> void:
	var site=world.find_nearest()
	if site.get("id","").begins_with("bench"):
		world.player.data.seated=true
		toast("A moment to sit. Move when you're ready to go.")
	else: toast("Find a bench to sit on.")

func hotkey(index: int) -> void:
	if not started: return
	match index:
		0: interact()
		1: cast_growth()
		2: inventory()
		3: journal()

func select_inventory_item(id: String) -> void:
	if not state.select_inventory(id): return
	state.equipped="rusty_sword" if id=="rusty_sword" else ""
	ui.update()

func select_quick_slot(index: int) -> void:
	if index<0 or index>7: return
	state.selected_slot=index
	state.equipped="rusty_sword" if state.active_item()=="rusty_sword" and state.rusty_sword>0 else ""
	ui.update()

func actions() -> void:
	if window_open: close_window()
	panel("Actions","CREW CONTROLS","Select quick slots with 1–8. E uses the selected item or interacts with the world.",[
		["Use selected item / interact · E",interact],["Inventory · I",inventory],["Spells and skills",spell_slots],["Field notes · J",journal],["Map · M",map_notes],["Settings · Esc",settings]])

func spell_slots() -> void:
	inventory()

func toast(text: String,duration = 4.0) -> void:
	ui.message.text = text
	message_until = elapsed+duration

func burst(pos: Vector2,color = "a5d8c5",count = 20) -> void:
	for i in range(count):
		var angle = randf()*TAU
		world.particles.append({"pos":pos,"velocity":Vector2(cos(angle)*randf_range(10,35),sin(angle)*25-20),"life":randf_range(1,2),"color":color})

func close_window(preserve_conversation: bool=false) -> void:
	if not preserve_conversation and welcome_control_locked(): return
	window_open = false
	if not preserve_conversation: end_conversation(conversation_sequence)
	sound.save_preferences()
	ui.close_modal()

func begin_conversation(members: Array,sequence: bool=false) -> void:
	for id in members: state.meet_person(id)
	if conversation_members.is_empty():
		conversation_location=state.location
		conversation_anchor=state.player_position
		conversation_steps=0
	for id in members:
		if not conversation_members.has(id): conversation_members.append(id)
		outdoors.conversation_holds[id]=true
	conversation_sequence=conversation_sequence or sequence or conversation_members.size()>1

func end_conversation(abandoned: bool=false) -> void:
	for id in conversation_members:
		outdoors.conversation_holds.erase(id)
		if abandoned: state.abandoned_day[id]=state.day
	conversation_members.clear()
	conversation_sequence=false
	conversation_steps=0

func choose_dialogue(action: Callable) -> void:
	var speaker=conversation_members[0] if conversation_members.size()==1 else ""
	var scripted=welcome_control_locked() or not state.briefing_complete or conversation_members.size()>1
	close_window(true)
	action.call()
	if not window_open and speaker!="" and not scripted and conversation_members.has(speaker): talk(speaker)
	elif not window_open: end_conversation(false)

func is_exit_reply(label: String) -> bool:
	var reply=label.to_lower()
	return ["see you","have a nice day","have a good day","take care","i'll leave you","i'll come back","just passing","enjoy your walk","thanks, i'm all set","goodbye"].any(func(ending):return reply.contains(ending))

func dialog(title: String,role: String,text: String,choices: Array = []) -> void:
	if not conversation_members.is_empty():
		conversation_steps+=1
		if conversation_steps>1 and not (conversation_members.size()==1 and conversation_members[0] in ["tavi","baker"]): conversation_sequence=true
	window_open = true
	if choices.is_empty(): choices=[[neutral_reply(text),func(): pass]]
	var ordinary=conversation_members.size()==1 and state.briefing_complete and not welcome_control_locked()
	if ordinary and not (conversation_members[0]=="keeper" and state.firewood_requested and not state.firewood_given):
		var person=conversation_members[0]
		state.requests.refresh(state)
		for job in state.requests.jobs:
			var terms=state.requests.POOL[int(job.template)]
			if job.status!="active" or terms[0]!=person: continue
			var request_id=state.requests.quest_id(job)
			var recipient=person
			choices=choices.duplicate()
			choices.append(["Complete request · %s"%state.requests.supplies(int(job.template)),func():
				if state.requests.deliver(state,request_id,recipient):
					save_visit()
					dialog(title,"A LITTLE HELP","That's everything. Thank you! Here are the crowns I promised. You've saved me a trip.")
				else: toast("Bring the full amount before the weekly notice-board refresh."),int(state.get(terms[1]))>=terms[2]])
		var item=state.active_item()
		if state.Items.CATALOG.has(item) and item not in state.Items.ESSENTIAL_TOOLS and int(state.get(item))>0 and int(state.gift_weeks.get(person,-1))!=int((state.day-1)/7):
			choices=choices.duplicate()
			choices.append(["Give "+state.Items.CATALOG[item].name,func():
				var preference=state.gift_preference(person,item)
				if state.give_gift(person,item):
					save_visit()
					dialog(title,"A GIFT", "Oh, that's wonderful. Thank you!" if preference==5 else "That's kind of you. Thank you." if preference==1 else "Thank you for thinking of me." if preference==0 else "Oh. I'm afraid this isn't really for me." if preference== -1 else "Please don't bring me anything like that again.")])
	if ordinary:
		var replies=[]
		var exits=[]
		for option in choices:
			if is_exit_reply(option[0]): exits.append([option[0],func(): end_conversation()])
			else: replies.append(option)
		if exits.is_empty(): exits.append(["Goodbye.",func(): end_conversation()])
		choices=replies+exits
	ui.open_modal(title,role,text,choices,false,dialogue_speaker(title))
	ui.dialogue_open=true
	ui.update_hud()
	if state.welcome_phase in ["meeting","moss_lesson"] or ("moss" in conversation_members and not state.invited): ui.modal.get_child(1).position.y=35

func dialogue_speaker(title: String) -> String:
	if title=="Captain": return "player"
	if title=="Briar Glen Radio": return ""
	if title=="Mrs. Bell": return "miller_wife"
	for person in outdoors.people:
		if person.name==title: return person.id
	return conversation_members[0] if conversation_members.size()==1 else ""

func neutral_reply(text: String) -> String:
	if "thank" in text.to_lower(): return "You're welcome."
	if "?" in text: return "I'll keep that in mind."
	return ["Sounds good.","I see.","That helps.","I'll keep that in mind."][posmod(hash(text)+state.day,4)]

func panel(title: String,eyebrow: String,text: String,choices: Array = []) -> void:
	if welcome_control_locked(): return
	window_open = true
	if choices.is_empty(): choices=[["Back to the morning",func(): pass]]
	ui.open_modal(title,eyebrow,text,choices,true)

func interact() -> void:
	if not started or window_open or opening!=null: return
	if action_busy(): return
	if resting>0.0:
		resting=0.0
		state.player_position=rest_return_position
		toast("Back on your feet.")
		return
	if activity=="fishing":
		_finish_fishing()
		return
	if not activity.is_empty(): return
	nearest=world.find_nearest()
	if nearest.get("type")=="person": talk(nearest.id); return
	if nearest.get("type")=="drop" and world is Cave:
		if world.collect_drop(nearest.id):
			save_visit()
			toast("Picked up the mined material.")
		else: toast("Make room in your satchel before collecting it.")
		return
	if state.active_item()!="rusty_sword": begin_action()
	if world==outdoors and state.active_item()=="hoe" and world.target_plot()<0 and nearest.is_empty():
		var cell=world.front_cell()
		if world.can_build_crucible(cell) and state.prepare_plot(cell):
			world.farm_cells[cell]=true
			preload("res://tool_motion.gd").start(world,"hoe")
			save_visit()
			toast("Good earth. Select seeds to plant here.")
		else: toast("Face clear ground within fifteen squares of the farmhouse, with enough energy to till.")
		return
	if nearest.get("type")=="build":
		build_crucible()
		return
	if nearest.get("id","").begins_with("bench"):
		sit_on_bench()
		return
	if nearest.get("id")=="stove": cooking(); return
	if state.active_item()=="rusty_sword" and nearest.get("type")!="site":
		if world.attack(): burst(state.player_position+Vector2({"up":Vector2.UP,"down":Vector2.DOWN,"left":Vector2.LEFT,"right":Vector2.RIGHT}[world.facing])*26,"e8d2a0",10); save_visit()
		else: toast("Carry and select your sword, and keep enough energy to swing.")
		return
	if state.active_item() in ["pickaxe","axe","sickle"] and (nearest.is_empty() or nearest.get("type")=="weapon"):
		if world.attack_with_tool(state.active_item()): save_visit()
		else: toast("You need the tool and enough energy to swing.")
		return
	if ui.Items.FOOD.has(state.active_item()):
		var food_id=state.active_item()
		toast("Used %s." % ui.Items.CATALOG[food_id].name if state.consume(food_id) else "Nothing to restore, or none carried.")
		save_visit()
		return
	if world==outdoors and state.active_item()=="watering_can" and world.in_water(Grid.center(world.front_cell())) and Grid.center(world.front_cell()).distance_to(Grid.center(world.POND_CELL))<190:
		toast("Watering can filled · 20 / 20" if state.refill_water() else "Take your watering can from storage first.")
		save_visit()
		return
	if world==outdoors and nearest.get("id") in ["drink_pond","drink_fountain"]:
		panel("Fresh water","TAKE A MOMENT","Cool, clear water. A welcome pause.",[["Drink",drink_freshwater],["Leave it for now",func(): pass]])
		return
	if nearest.get("type")=="rock":
		var position=Grid.center(world.rocks[nearest.id].cell)
		if world.mine_rock(nearest.id):
			sound.mining.play()
			burst(position,"c6a47b",12)
			save_visit()
			toast("A blow lands. %d energy spent." % int(state.energy_cost(4)))
		else: toast("Select a carried pickaxe. Mining costs %d energy." % int(state.energy_cost(4)))
		return
	if nearest.is_empty():
		toast("Walk closer to a person, garden patch, or landmark.")
		return
	if nearest.type=="plot":
		if state.active_item()=="wildgrowth": cast_growth(); return
		var was_ripe=state.ripe(nearest.index)
		var before: Dictionary=state.plots[nearest.index].duplicate()
		var previous_water=state.water
		toast(state.farm(nearest.index),2.5)
		if before!=state.plots[nearest.index] or previous_water!=state.water:
			preload("res://tool_motion.gd").start(world,state.active_item() if state.active_item()!="" else "sickle" if was_ripe else "hoe")
			burst(world.plot_position(nearest.index),"e5d0a4" if was_ripe else "b8bf86",20 if was_ripe else 7)
			world.crops.queue_redraw()
			save_visit()
	elif nearest.type=="tree":
		if world.chop_tree(nearest.cell):
			burst(Grid.center(nearest.cell),"b89662",12)
			toast("Timber! Pick up the fallen logs." if not world.solid_cells.has(nearest.cell) else "The axe bites into the trunk.")
			save_visit()
		else: toast("You need an axe and %d energy." % int(state.energy_cost(2)))
	elif nearest.type=="logs":
		if not state.can_carry("wood"): toast("Make room for the logs."); return
		state.wood+=3
		state.forage_harvests["wood:%d:%d" % [nearest.cell.x,nearest.cell.y]]=state.total()
		for node in world.moving_layer.get_children():
			if node.kind=="logs" and node.data.cell==nearest.cell: node.queue_free()
		save_visit()
		toast("Three logs picked up.")
	elif nearest.type=="forage":
		toast("Gathered "+nearest.item+"." if outdoors.harvest_forage(nearest.item,nearest.cell) else "Make room in your satchel.")
		save_visit()
	elif nearest.type=="person": talk(nearest.id)
	else:
		if nearest.has("door"):
			enter_building(nearest.door)
			return
		match nearest.id:
			"ladder":
				if state.ladder_taken: return
				if not state.can_carry("ladder"): toast("Make room in your satchel for the ladder."); return
				state.ladder=1
				state.ladder_taken=true
				state.ladder_requested=true
				state.ladder_located=true
				world.sites=world.sites.filter(func(site):return site.id!="ladder")
				world.solid_cells.erase(Vector2i(6,2))
				for child in world.get_children():
					if child is Interior.Furniture and child.item.kind=="shed_ladder": child.queue_free()
				toast("Mrs. Bell's ladder. Better take it back to Mara.")
				save_visit()
			"crucible": crucible_menu(nearest.index)
			"private_door": dialog("A private door","THE WAYWARD WREN","Rafe's living quarters are beyond the bar. Best to leave him his privacy.")
			"cave_pickaxe":
				if state.accept_tool("pickaxe"):
					world.queue_redraw()
					for child in world.get_children():
						if child is Cave.CaveObject and child.info.kind=="pickaxe": child.queue_redraw()
					save_visit()
					toast("Pickaxe collected. Select it from your satchel or assign a quick slot to mine.")
				else: toast("Make room in your satchel for the pickaxe.")
			"bulletin_board": bulletin_board()
			"uncover_sofa","uncover_guest_bed","living_light","bathroom_light":
				tidy_farmhouse(nearest.id.trim_prefix("uncover_"))
			"chest","cabinet","ship_storage","cave_barrel": open_storage(nearest.id)
			"chrysalis":
				toast("Cave Moth Chrysalis collected." if world.collect_chrysalis() else "Make room in your satchel.")
				save_visit()
			"sparkfire":
				var key="%d:%d" % [nearest.cell.x,nearest.cell.y]
				if state.weather_name()=="rainy": toast("The rain has hidden the sunrise. The flower stays closed."); return
				if state.winter_bloom_day():
					if state.bloom_harvests.get(key,0)==state.day: toast("This winter sparkbloom has already been gathered.")
					elif not state.can_carry("winter_sparkbloom"): toast("Make room in your satchel.")
					else:
						state.winter_sparkbloom+=1
						state.bloom_harvests[key]=state.day
						toast("Winter sparkbloom gathered. A little lightning kept in a flower.")
						save_visit()
					return
				if state.minute<330 or state.minute>=420: toast("An ordinary-looking plant. Its golden flower opens only at sunrise.")
				elif state.bloom_harvests.get(key,0)==state.day: toast("The dawn flower has already been gathered today.")
				elif not state.can_carry("golden_sparkfire_bloom"): toast("Make room in your satchel.")
				else:
					state.golden_sparkfire_bloom+=1
					state.sparkfire_picked_day=state.day
					state.bloom_harvests[key]=state.day
					toast("Golden Sparkfire Bloom gathered in the sunrise.")
					save_visit()
			"stove": cooking()
			"diagnostics": panel("Engineering diagnostics","CLOAKED SHIP · BATTLE DAMAGE","Phase-conjugate manifold: unstable. Gravitic shear compensator: bypassed. Inertial lattice: cracked. Plasma return bus: vented. Vale has isolated the sparking cables; the cloak and bunk section remain safe.")
			"stairs_down": change_cave_level(1)
			"stairs_up": change_cave_level(-1)
			"exit": leave_building()
			"shop":
				if shopkeeper_at_work("tavi","store"): talk("tavi")
				else: toast("The counter is unattended. Come back when Tavi is here.")
			"bed":
				var cover_task=""
				if current_room=="home" and not state.met_mayor:
					for furnishing in world.furnishings:
						if furnishing.kind!="bed" or not furnishing.bounds.has_point(world.front_cell()): continue
						var task=furnishing.get("task","bed")
						if not state.house_tasks[task]: cover_task=task; break
				if cover_task!="": tidy_farmhouse(cover_task)
				else: rest_options()
			"pond","ocean","ocean_tip":
				start_fishing(nearest.id)
			"drink_pond","drink_fountain":
				if state.needs.hardcore: drink_freshwater()
				else: toast("Fresh water, cool and clean.")
			"sign": dialog("The farmhouse crossroads","BRIAR GLEN","East: Briar Glen, general store and smithy. West: the old farmhouse and the coastal path. South: the mill pond and woodland cabins. For the copper cave, take the southeast road from town.",[ ["Okay.",func(): pass] ])
			"radio":
				if current_room=="home" and not state.met_mayor and not state.house_tasks.radio: tidy_farmhouse("radio")
				else: radio()

func tidy_farmhouse(task: String) -> void:
	if state.tidy_house(task):
		toast("Light repaired." if task.ends_with("light") else "Dusty cover folded away.")
		save_visit()
		world.refresh()
		world.queue_redraw()
	else: toast("Take a replacement bulb from the kitchen cabinet first." if task.ends_with("light") and not state.house_tasks[task] else "Already taken care of.")

func learn_local_spell(id: String) -> void:
	if state.learn_spell(id):
		save_visit()
		dialog("Iona","A LITTLE PRACTICE", "Think of the warmth of a hearth, and let it find the hurt. Gently. Healing isn't a contest." if id=="hearthmend" else "Follow the thread of warmth out of your hand. Keep it narrow, and mind where you point it. We're learning a spell, not burning my garden down.")
	else: toast("Bring a Golden Sparkfire Bloom." if id=="hearthmend" else "Bring a Cave Moth Chrysalis and ten wood logs.")

func cast_local_spell(id: String) -> void:
	if window_open or resting>0 or world_paused or not state.Skills.known(state,id): return
	if id=="hearthmend":
		if not state.cast_healing(): toast("You need 10 mana and an injury to mend."); return
		burst(state.player_position,"f5dc92",24)
	else:
		if state.mana<12: toast("Emberthread needs 12 mana."); return
		state.mana-=12
		var direction={"up":Vector2.UP,"down":Vector2.DOWN,"left":Vector2.LEFT,"right":Vector2.RIGHT}[world.facing]
		for step in range(1,6):
			var point=state.player_position+direction*step*24
			if world.blocked(point): break
			burst(point,"ec9b55",5)
			if world is Cave and world.burn_at(point,2*state.magic_strength("fire")): break
	sound.play_spell(id)
	save_visit()

func cast_growth() -> void:
	if not started or window_open or resting>0.0 or not activity.is_empty(): return
	if not state.magic_learned: toast("You have not learned to use local magic."); return
	if state.active_item()!="wildgrowth": toast("Select Wildgrowth in a quick slot first."); return
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
	if activity=="fishing" and activity_time>18.0:
		activity=""
		toast("You reel in the line. The pond can wait.")

func fishing_position() -> float:
	var time=maxf(0.0,activity_time-1.2)
	if ui.Items.FISH[fishing_species].hard:
		return clampf((sin(time*4.8+fishing_phase+sin(time*3.1+fishing_phase*0.7)*1.4)+sin(time*11.2+fishing_phase)*0.2+1.2)/2.4,0,1)
	return (sin(time*1.7+fishing_phase)+1.0)*0.5

func fish_pool(habitat: String) -> Array:
	return ui.Items.FISH.keys().filter(func(id): return (not ui.Items.FISH[id].get("rainy_only",false) or state.weather_name()=="rainy") and (id!="lantern_ray" or state.minute<360 or state.minute>=1140) and (ui.Items.FISH[id].habitat==habitat or (habitat=="ocean_tip" and ui.Items.FISH[id].habitat=="ocean")))

func start_fishing(habitat: String) -> void:
	if state.fishing_pole<1 or state.active_item()!="fishing_pole":
		toast("Select a fishing pole first. Oren at the lighthouse has a spare.")
		return
	if not state.spend_energy(1):
		toast("Too tired to cast. Rest or eat something first.")
		return
	var pool=fish_pool(habitat)
	if habitat=="ocean_tip":
		var weighted=[]
		for id in pool:
			for i in range(int(ui.Items.FISH[id].get("weight",2 if ui.Items.FISH[id].hard else 4))): weighted.append(id)
		pool=weighted
	fishing_species=pool[fishing_rng.randi_range(0,pool.size()-1)]
	fishing_phase=fishing_rng.randf_range(0,TAU)
	activity="fishing"
	activity_time=0
	toast("Line cast. %s pull on the line. Activate in the gold band." % ("Erratic" if ui.Items.FISH[fishing_species].hard else "Gentle"))

func _finish_fishing() -> void:
	if activity_time<1.2:
		toast("Let the line settle first.",2.0)
		return
	var marker=fishing_position()
	if marker>0.35 and marker<0.7:
		if not state.can_carry(fishing_species):
			toast("Your satchel is full. Make room before catching fish.")
			activity=""
			return
		state.set(fishing_species,int(state.get(fishing_species))+1)
		burst(state.player_position-Vector2(0,10),"9ed6cf")
		toast("Caught %s. Tavi will buy this." % ui.Items.CATALOG[fishing_species].name)
		save_visit()
	else: toast("It slipped away. No bait lost. Try again.")
	activity=""

func rest_options() -> void:
	if current_room=="home" and not state.met_mayor:
		for task in ["bed","guest_bed"]:
			if not state.house_tasks[task]: tidy_farmhouse(task); return
	if clock_held(): toast("Wait until the opening welcome is finished before resting."); return
	if current_room not in ["home","ship"]:
		toast("This bed belongs to someone else. Rest in your own farmhouse bed.")
		return
	dialog("Crew bunks" if current_room=="ship" else "The farmhouse","A LITTLE REST","The ship hums quietly around the bunks. How long would you like to rest?" if current_room=="ship" else "The bed smells of cedar. How long would you like to rest?",[
		["Rest for four hours",func(): begin_rest(240)],
		["Rest until the mayor returns" if state.invited and not state.met_mayor else "Rest for eight hours",func():
			if state.invited and not state.met_mayor:
				if state.mayor_available(): toast("The mayor's party is already here."); return
				var target=state.mayor_visit_start()
				if target<=state.total(): target+=1440
				begin_rest(target-state.total())
			else: begin_rest(480)],
		["Not tired yet.",func(): pass]])

func begin_rest(minutes: float) -> void:
	if current_room not in ["home","ship"]: return
	rest_return_position=state.player_position
	resting=minutes
	state.sleep_minutes=0
	state.player_position=world.bed_position()
	toast("Resting. The world keeps turning. E to get up.",6)

func open_chest() -> void:
	window_open=true
	ui.open_chest(chest_selected)

func open_storage(id: String) -> void:
	storage_name=id
	chest_selected=""
	open_chest()

func transfer_chest(index: int) -> void:
	var stack: Dictionary=state.get(storage_name)[index]
	var available=int(stack.get("count",0)) if chest_selected=="" else int(state.get(chest_selected))
	if available<1: return
	var selected=chest_selected
	if available==1:
		if state.storage_transfer(storage_name,index,selected,1): save_visit()
		else: toast("Your satchel is full. Make room before taking another item.")
		chest_selected=""
		open_chest()
		return
	window_open=true
	ui.quantity_picker(available,func(amount):
		if state.storage_transfer(storage_name,index,selected,amount): save_visit()
		else: toast("Use the full carried stack to swap different items, or choose an empty slot.")
		chest_selected=""
		open_chest(),open_chest)

func can_drop_item(data: Variant,destination: Dictionary) -> bool:
	if not data is Dictionary or data.get("type") not in ["inventory_item","ability"]: return false
	var id=data.get("id","")
	var storage=data.get("storage","")
	if storage!="":
		if storage not in ["chest","cabinet","ship_storage","cave_barrel"]: return false
		var index=int(data.get("index",-1))
		var cells: Array=state.get(storage)
		if index<0 or index>=cells.size() or cells[index].get("id","")!=id: return false
	elif not state.available_action(id): return false
	if destination.get("storage","")!="" or destination.get("inventory_index",-1)>=0:
		if destination.get("storage","")!="" and not ui.Items.CATALOG.has(id): return false
		var name=destination.get("storage","")
		if name!="": return name in ["chest","cabinet","ship_storage","cave_barrel"] and int(destination.get("index",-1))>=0 and int(destination.index)<state.get(name).size()
		return int(destination.inventory_index)<State.INVENTORY_SLOTS
	return destination.get("quick_index",-1) in range(8) or destination.get("channel","") in ["primary","aux"]

func drop_item(data: Dictionary,destination: Dictionary) -> void:
	if not can_drop_item(data,destination): return
	var source=data.get("storage","")
	var target=destination.get("storage","")
	var view=ui.container_view
	var physical=source!="" or target!=""
	var count=int(state.get(source)[int(data.index)].count) if source!="" else int(state.get(data.id)) if ui.Items.CATALOG.has(data.id) else 1
	var confirm=func(amount):
		if perform_drop(data,destination,amount): save_visit()
		else: toast("That transfer needs an empty slot, enough room, or the full stack for a swap.")
		if view=="storage": open_chest()
		elif view=="inventory": inventory()
		ui.update()
	if physical and count>1:
		ui.quantity_picker(count,confirm,func(): open_chest() if view=="storage" else inventory())
	else: confirm.call(count)

func perform_drop(data: Dictionary,destination: Dictionary,amount: int) -> bool:
	state.sync_inventory()
	var source=data.get("storage","")
	var target=destination.get("storage","")
	var index=int(destination.get("inventory_index",-1))
	if index<0 and int(destination.get("quick_index",-1))>=0: index=state.quick_row*8+int(destination.quick_index)
	if source!="" and target!="":
		var from_cells: Array=state.get(source)
		var to_cells: Array=state.get(target)
		var from_index=int(data.index)
		var to_index=int(destination.index)
		if source==target and from_index==to_index: return true
		var stack: Dictionary=from_cells[from_index]
		var other: Dictionary=to_cells[to_index]
		if amount<1 or amount>stack.count: return false
		if not other.is_empty() and other.id!=stack.id:
			if amount!=stack.count: return false
			from_cells[from_index]=other
			to_cells[to_index]=stack
		else:
			to_cells[to_index]={"id":stack.id,"count":amount+int(other.get("count",0))}
			from_cells[from_index]={} if amount==stack.count else {"id":stack.id,"count":stack.count-amount}
		return true
	if target!="":
		var replaced=state.get(target)[int(destination.index)].get("id","")
		var previous=state.inventory_order.find(data.id)
		if not state.storage_transfer(target,int(destination.index),data.id,amount): return false
		if replaced!="" and replaced!=data.id and int(state.get(data.id))==0: state.move_inventory(replaced,previous)
		return true
	if source!="":
		var replaced=state.inventory_order[index] if index>=0 else ""
		if state.Skills.CATALOG.has(replaced):
			state.inventory_order[index]=""
			if not state.storage_transfer(source,int(data.index),"",amount):
				state.inventory_order[index]=replaced
				return false
			return state.move_inventory(data.id,index)
		if replaced!="" and replaced!=data.id and int(state.get(data.id))==0:
			if amount!=state.get(source)[int(data.index)].count: return false
			if not state.storage_transfer(source,int(data.index),replaced): return false
		elif not state.storage_transfer(source,int(data.index),"",amount): return false
	if index>=0:
		if state.Skills.CATALOG.has(data.id) and data.id not in state.inventory_order:
			return state.place_shortcut(data.id,index)
		return state.move_inventory(data.id,index)
	if destination.get("channel","")!="": return state.assign_active(destination.channel,data.id)
	return state.assign_slot(int(destination.quick_index),data.id)

func build_crucible() -> void:
	if world!=outdoors or not outdoors.can_build_crucible(world.front_cell()):
		toast("Face a clear square within fifteen squares of your farmhouse.")
		return
	if not state.build_crucible(world.front_cell()):
		toast("Learn Dain's blueprint and carry %d stone to build a crucible." % State.CRUCIBLE_STONE)
		return
	outdoors.add_crucible(state.crucibles.size()-1)
	save_visit()
	toast("Stone crucible built. Face it to smelt copper ore.")

func crucible_menu(index: int) -> void:
	var station=state.crucibles[index]
	var choices=[]
	var description="%d copper ore and %d coal become one bar in %d game minutes." % [State.ORE_PER_BAR,State.COAL_PER_BAR,int(State.SMELT_MINUTES)]
	if station.bars>0:
		choices.append(["Collect copper bar",func():
			toast("Copper bar collected." if state.collect_copper_bar(index) else "Make room in your satchel for the copper bar.")
			save_visit()
			crucible_menu(index)])
	elif station.ready_at>=0:
		description+="\n\nSmelting: %d game minutes remaining. Leave it working while you get on with your day." % ceili(station.ready_at-state.total())
	else:
		choices.append(["Smelt %d copper ore + %d coal · %d minutes" % [State.ORE_PER_BAR,State.COAL_PER_BAR,int(State.SMELT_MINUTES)],func():
			toast("The copper begins to melt." if state.start_smelting(index) else "You need %d copper ore and %d coal in your satchel." % [State.ORE_PER_BAR,State.COAL_PER_BAR])
			save_visit()
			crucible_menu(index),state.copper>=State.ORE_PER_BAR and state.coal>=State.COAL_PER_BAR])
	choices.append(["Leave the crucible",func(): pass])
	panel("Stone crucible","COPPER REFINING",description,choices)

func learn_crucible() -> void:
	if not state.learn_crucible():
		dialog("Dain Rusk","A FAIR EXCHANGE","Bring me ten star bulbs and I'll show you how to build a stone crucible. I use them to check the temper of a blade; that little glow shows up a crack beautifully.")
		return
	save_visit()
	dialog("Dain Rusk","CRUCIBLE BLUEPRINT LEARNED","There you are. Ten pieces of stone make a small crucible. Select the plans, then face a clear patch near your farmhouse. Five pieces of ore and two coal make a bar in half an hour. Set it going and get on with your day. Good metal's useful wherever your travels take you.")

func cooking() -> void:
	if current_room!="home" or world.front_cell() not in world.activation_cells(world.sites.filter(func(site):return site.id=="stove")[0]):
		toast("Use the farmhouse oven to cook.")
		return
	var choices=[]
	for id in State.RECIPES:
		var recipe=State.RECIPES[id]
		if state.ingredient_count(recipe.utensil)<1: continue
		var details=[]
		for ingredient in recipe.ingredients:
			var available=state.ingredient_count(ingredient)
			var label="Any fish" if ingredient=="fish" else ui.Items.CATALOG[ingredient].name
			details.append("%s · %s" % [label,"missing" if available==0 else "ready" if available==1 else "%d available" % available])
		var meal=id
		choices.append(["Cook %s · %s · requires %s" % [ui.Items.CATALOG[id].name,", ".join(details),recipe.utensil],func():
			toast("Cooked %s." % ui.Items.CATALOG[meal].name if state.cook(meal) else "Missing cookware or ingredients. Ingredients can be carried or in your kitchen cabinet.")
			save_visit()
			cooking(),recipe.ingredients.keys().all(func(ingredient):return state.ingredient_count(ingredient)>=recipe.ingredients[ingredient])])
	choices.append(["Open kitchen cabinet",func(): open_storage("cabinet")])
	choices.append(["Done cooking",func(): pass])
	panel("Farmhouse stove","COOKING","Recipes draw ingredients from your satchel and the connected twelve-slot kitchen cabinet. Tavi sells pots and pans for 20 crowns each.",choices)

func shopkeeper_at_work(id: String,room: String) -> bool:
	return current_room==room and world.villagers.has(id) and world.villagers[id].visible and not world.villagers[id].data.get("sleeping",false)

func talk(id: String) -> void:
	var first_meeting=not state.chat_days.has(id)
	state.chat_with(id)
	begin_conversation([id],id in ["veteran","finch","vale"] or (id=="moss" and not state.invited))
	var greetings=preload("res://npc_greetings.gd").LINES
	if first_meeting and id not in ["vale","moss","mayor","assistant"] and greetings.has(id):
		dialog(person_name(id),"A FIRST HELLO",greetings[id],[["Go on.",func(): talk(id)]])
		return
	if id not in ["smith","woodcutter"] and preload("res://neighbors.gd").talk(self,id): return
	match id:
		"smith":
			var at_work=shopkeeper_at_work("smith","smithy")
			var choices=[
				["What should I know about mining copper?",func(): preload("res://local_guidance.gd").smith_copper(self)],
				["Tell me about your work.",func(): dialog("Dain Rusk","IRON & HONEST WEAR",preload("res://neighbors.gd").STORIES.smith.split("|",true,1)[1]+" A sound handle, a balanced head, an edge that holds. Bring your tools to the forge and we'll talk about what they need.")],
				["See you around.",func(): pass]]
			if at_work:
				choices.push_front(["What have you got for sale?",smith_shop])
				if not state.crucible_known: choices.push_front(["Learn crucible blueprint · 10 star bulbs",learn_crucible,state.star_bulbs>=10])
			dialog("Dain Rusk","BLACKSMITH","Mind the hot scale. I can tell a lot about a tool by the wear on its edge. Bring yours by when you're ready to talk about better steel." if at_work else "Good to stretch my shoulders after a day at the forge. If you're thinking about upgrading your tools, come see me at the smithy.",choices)
		"woodcutter":
			preload("res://local_guidance.gd").rowan(self)
		"keeper":
			preload("res://local_guidance.gd").oren(self)
		"veteran":
			preload("res://local_guidance.gd").bram(self)
		"mayor":
			if state.mayor_available(): mayor()
			else: dialog("Mayor Alder","BRIAR GLEN","How are things coming along at the farmhouse? Have a look at the bulletin board when you get a chance. And if you need help, ask Moss. His family has lived here longer than any of ours; he knows the ground and the people on it.")
		"assistant":
			if state.mayor_available(): mayor()
			else: dialog("Neral","MAYOR'S ASSISTANT · DARK ELF","How are things coming along? The bulletin board is worth checking. Moss knows the country better than anyone, so ask him if you need help. He says you're settling in. I'd rather hear it from you. And if you remember anything about that light on the mountain, tell me.")
		"moss":
			if not state.invited:
				dialog("Moss","AT THE FOOT OF THE MOUNTAIN TRAIL","Hold on there! What was that flash and crashing sound up on the mountain? Looked as though someone cast quite a spell. Are you travelers?",[
					["Answer Moss",func(): dialog("Captain","TRAVELERS","A spell? Oh! Yes, we're travelers. Could you suggest somewhere we might stay for a while?",[
						["Let Moss answer",func(): dialog("Moss","YOUR NEIGHBOR","There's no hotel here, but this farmhouse is abandoned. It can house you for a bit. I live down the road. Go on in while I fetch the mayor. There are clean beds under the covers, and spare bulbs in the kitchen cabinet.",[
							["Thank you. We'll wait inside.",func():
								state.invite_mayor()
								state.welcome_phase="escorting"
								escort_path=outdoors.farmhouse_approach(Grid.world_to_cell(state.player_position))
								save_visit()
								toast("You follow Moss's directions into the farmhouse.",7)]])]])]])
			elif state.mayor_available(): mayor()
			elif state.met_mayor: preload("res://local_guidance.gd").moss(self)
			else: dialog("Moss","NEIGHBOR · SOUTH FARM","Go on inside. I'll bring Alder and Neral back shortly. Make yourselves comfortable and see what needs tidying.")
		"tavi":
			conversation_steps=0
			if not shopkeeper_at_work("tavi","store"):
				dialog("Tavi","A MOMENT OFF DUTY","A little fresh air does me good. My sister says I should leave work at work. Come by the grocery when I'm behind the counter if you need anything.",[["Where can I get tools?",tool_directions],["Enjoy your walk.",func(): pass]])
				return
			dialog("Tavi","TRAVELING MERCHANT","Hello again! Need anything for the garden? Or have you brought me something good? I'm off to Veyr for my sister's festival next month. Help me travel with a lighter cart, eh?" if current_room=="store" else "A little fresh air before I go back to the shop. My sister says I should learn to leave work at work. Sensible advice, but I've never been terribly good at it. What can I do for you?",[
				["Sell produce · %d crowns" % state.sale_value(),func():
					if state.sell(): save_visit(); toast("Sold. Locally grown, very far from home.")
					else: toast("Bring turnips or silverfin to sell.")
					talk("tavi"),state.sale_value()>0],
				["What have you got for sale?",tavi_shop],
				["Where can I get tools?",tool_directions],
				["Just passing through.",func(): pass]])
			ui.modal.get_child(1).position.y=125
		"iona":
			if outdoors.stop_for("iona").sleeping:
				dialog("Iona","FIELD MAGICIAN","Come visit my tower in the northern cliffs if you'd like a lesson. I keep late hours.")
			else:
				var lessons=[
					["Tell me about the seven days",weekday_lore]]
				if state.chat_days.has("weekday_lore"): lessons.append(["Which magic might be stronger or weaker on the next Rift?",next_rift_omen])
				lessons.append(["Learn the local lore",local_magic_lore])
				lessons.append_array([
					["Hearthmend · one Golden Sparkfire Bloom",func(): learn_local_spell("hearthmend"),state.golden_sparkfire_bloom>=1],
					["Emberthread · one Cave Moth Chrysalis + 10 logs",func(): learn_local_spell("emberthread"),state.cave_moth_chrysalis>=1 and state.wood>=10]])
				dialog("Iona","MAGIC OF BRIAR GLEN","You'll find our deities gentler than the ones near the Veyr border. Mostly they want things to grow. I can show you Wildgrowth, if you like. Water a seed first, then give it a little encouragement. Fifteen mana, and no fee for the lesson. For something more adventurous, bring me a Cave Moth Chrysalis from deep underground, or a Golden Sparkfire Bloom. Mind you, that flower only opens while the sun is rising. Walk past at noon and you'd never give it a second glance.",lessons)
		"finch": dialog("Finch","RADIO CLUB SECRETARY","Come in, come in. Mind that cable. Last week we picked up a dance band from Veyr, clear as anything. Governments can argue all they like; the air doesn't stop at a checkpoint." if current_room=="radio" else "Good to give my eyes a rest from the wiring. Nessa's coming along nicely with that receiver. Her mother will have river weather reports in the kitchen before long.",[["What's on the air today?",radio],["I'll come back sometime.",func(): pass]])
		"vale":
			if not state.briefing_complete: show_briefing(); return
			var choices=vale_checkin_choices()
			if not state.delivered and state.copper_bars>=3:
				choices.push_front(["Hand over three copper bars.",func():
					state.copper_bars-=3
					state.delivered=true
					state.change_friendship("vale",25)
					save_visit()
					burst(state.player_position,"a3d4d0")
					toast("Crew link restored. One small connection home.",6.0)])
			choices.append(["How long do we have?",func(): dialog("Chief Vale","CHIEF ENGINEER","As long as the cloak holds, we have room to breathe. No signals. No active scans. I'll keep the lights off. You keep us fed.")])
			var body="Give your commlink a try. Hear that? Much better than shouting down a mountain. The cloak's holding, too. "+("Thanks for seeing to supper. I'll try to earn it before the day's out." if state.crew_fed_day==state.day else "I meant to stop for breakfast, but the locker was empty. If you find something to cook, save me a helping?") if state.delivered else "The cloak's behaving. Wish I could say the same for the engines. Three copper bars should get our crew link back. That deposit on the last scan was southeast of the settlement, but the ore will need refining. Might be worth asking whether anyone down there works metal. I'm rather in the dark up here with the scanners dead. Any luck finding supper? Leave me a cooked meal in the locker if you can. I'll try not to get engine grease on it."
			dialog("Chief Vale","CHIEF ENGINEER · SHIPBOARD CONVERSATION",body,choices)

func buy_ingredient(id: String) -> void:
	if state.purchase(id):
		save_visit()
		toast("Bought "+state.Items.CATALOG[id].name+".")
	else: toast("Out of stock. Delivery next season." if state.stock(id)==0 else "You need enough crowns and room in your satchel.")

func shop_menu(title: String,role: String,text: String,offers: Array) -> void:
	var choices=[]
	for offer in offers:
		var item: String=offer[0]
		var label: String=offer[1]
		var price: int=offer[2]
		var stock_id: String=offer[3]
		var action: Callable=offer[4]
		var count=state.stock(stock_id)
		var status="Out of stock · delivery next season" if count==0 else "%s crowns · %d available" % [crowns(price),count]
		var can_buy=count>0 and state.money>=price
		choices.append([label+" · "+status,func():
			if count==0: toast("Out of stock. Delivery next season.")
			elif state.money<price: toast("You need %d crowns." % price)
			elif not action.call(): toast("Make room in your satchel before buying that.")
			else:
				save_visit()
				toast("Bought "+(state.Items.CATALOG[item].name if state.Items.CATALOG.has(item) else label)+".")
			shop_menu(title,role,text,offers),can_buy,item,true])
	choices.append(["Thanks, I'm all set.",func(): pass])
	panel(title,role,text,choices)

func crowns(amount: int) -> String:
	return "1,000" if amount==1000 else str(amount)

func tavi_shop() -> void:
	var offers=[
		["seeds","Five moon-turnip seeds",10,"seeds",func(): state.buy_seeds()],
		["star_seeds","Three star-bulb seeds",12,"star_seeds",func(): state.buy_star_seeds()],
		["pan","Frying pan",20,"pan",func(): state.buy_utensil("pan")],
		["pot","Cooking pot",20,"pot",func(): state.buy_utensil("pot")],
		["health_elixir","Health elixir",15,"health_elixir",func(): state.purchase("health_elixir")],
		["sugar","Sugar",4,"sugar",func(): state.purchase("sugar")],
		["butter","Butter",6,"butter",func(): state.purchase("butter")]]
	shop_menu("Tavi's Grocery","SEASONAL STOCK","Here's what's on the shelves today. Seed packets, cookware, and baking supplies arrive with the seasonal cart. Pots and pans work from your kitchen cabinet or satchel.",offers)

func smith_shop() -> void:
	var offers=[["rusty_sword","Rusty sword",1000,"rusty_sword",func(): state.buy_sword()]]
	shop_menu("Dain's Smithy","FORGED GOODS","A plain blade, kept sharp enough. One thousand crowns. More steelwork is possible once you have the right materials.",offers)

func vale_checkin_choices() -> Array:
	return [["What's the status on repairs?",func(): dialog("Chief Vale","REPAIR STATUS","The cloak is steady. Everything else still needs parts and patience. I'm keeping the power sink stable and making a list of what can be repaired first. Ask me again whenever you like; I'll tell you when something changes.")]]

func baking_supplies() -> void:
	var choices=[]
	for id in ["sugar","butter"]:
		var ingredient=id
		choices.append(["%s · %d crowns · %d available"%[state.Items.CATALOG[id].name,preload("res://shop_stock.gd").CATALOG[id].price,state.stock(id)],func(): buy_ingredient(ingredient); baking_supplies(),state.money>=preload("res://shop_stock.gd").CATALOG[id].price])
	choices.append(["Back",func(): talk("tavi")])
	dialog("Tavi","SOMETHING SWEET","Preserves need berries and sugar in a pot. For cobbler, add flour and butter and fetch your pan. Tomas sells flour at the mill.",choices)

func weekday_lore() -> void:
	if not state.chat_days.has("weekday_lore"):
		weekday_lore_chain(0)
		return
	var faith=preload("res://weekday_magic.gd")
	var choices=[]
	for index in range(7):
		var selected=index
		choices.append([faith.DAYS[index]+" · "+faith.DEITIES[index][0],func():
			dialog("Iona",faith.DAYS[selected].to_upper(),weekday_lore_text(selected),[["And the other days?",weekday_lore],["Back to Iona",func(): talk("iona")]])])
	dialog("Iona","SEVEN TURNS OF THE SKY","The day matters as much as the words. Which of the seven would you like to hear about?",choices)

func weekday_lore_chain(index: int) -> void:
	var faith=preload("res://weekday_magic.gd")
	var next=index+1
	dialog("Iona",faith.DAYS[index].to_upper(),weekday_lore_text(index),[["Tell me about "+faith.DAYS[next]+"." if next<7 else "And that makes seven days.",func():
		if next<7: weekday_lore_chain(next)
		else:
			state.chat_days["weekday_lore"]=state.day
			save_visit()
			talk("iona")]])

func weekday_lore_text(index: int) -> String:
	var openings=["A day of chaos.","A day of growth.","A day of fire.","A day of air.","A day of water.","A day of light.","A day of darkness."]
	return openings[index]+" "+preload("res://weekday_magic.gd").DEITIES[index][1]

func local_magic_lore() -> void:
	dialog("Iona","MAGIC OF BRIAR GLEN","Here, Thessil's growing things answer more readily than they do near the border. Wildgrowth lends a watered seed a little of that strength. It costs fifteen mana, and I can teach you for free.",[["Teach me Wildgrowth" if not state.magic_learned else "Practice Wildgrowth",func():
		state.magic_learned=true
		save_visit()
		dialog("Iona","WILDGROWTH","There you are. Water a seed first, then give it a little encouragement. You can assign Wildgrowth under Actions, in Spells and skills.")]])

func next_rift_omen() -> void:
	var faith=preload("res://weekday_magic.gd")
	var next_day=state.day+(7-posmod(state.day-1,7))
	var omen=faith.chaos(next_day,state.world_seed)
	var body="On the next Rift, I expect %s magic to answer more strongly, while %s magic may be harder to shape." % [omen.favored,omen.weakened]
	if omen.favored==omen.weakened: body="The two signs both point to %s magic. On that Rift it may %s." % [omen.favored,"be twice as strong" if omen.collision>1 else "fail entirely"]
	dialog("Iona","THE NEXT RIFT",body)

func buy_cookware(id: String) -> void:
	if state.stock(id)==0:
		dialog("Tavi","OUT OF STOCK","That's the last of this season's delivery. I'll have more next season. Come back then, won't you?")
		return
	if not state.buy_utensil(id):
		toast("You'll need 20 crowns and room in your satchel.")
		talk("tavi")
		return
	save_visit()
	dialog("Tavi","A LITTLE HOME COOKING","There you are. That old stove in your kitchen should serve you well. Leave your food and cookware in the kitchen cabinet and you can cook straight from there. Anything you're carrying works too; no need to haul the whole cupboard about.",[["Thanks. What else have you got?",func(): talk("tavi")]])

func buy_bread() -> void:
	toast("A fresh loaf, still warm from Corin's oven." if state.buy_bread() else "You need six crowns and room for a loaf.")
	save_visit()
	talk("baker")

func offer_tool(id: String,person: String) -> void:
	var flag="woodcutter_axe_given" if id=="axe" else "cave_pickaxe_taken"
	var response="You've already got the one I set aside for you. Take good care of it."
	if not state.get(flag):
		if state.accept_tool(id):
			save_visit()
			response="There you are. Bring me ten logs in one week, seven days, as we agreed. The axe is yours to keep. Mind your footing, and rest when your arms get tired." if id=="axe" else "There you are. A useful tool, and yours to keep. Mind your footing."
		else: response="You're carrying rather a lot. Make a little room and come back for it."
	dialog(person,"A TOOL TO GET STARTED",response)

func tool_directions() -> void:
	dialog("Tavi","ASK A LOCAL","For tools, I know just the people. What are you after?",[
		["Where can I get an axe?",func(): dialog("Tavi","ROWAN'S CABIN","Rowan, the woodcutter, lives in the southern woods, west of Bram's cabin. Follow the faint woodland path. Ask her about a spare axe.")],
		["Where can I get a sword?",func(): dialog("Tavi","BRAM'S CABIN","Bram served in Aldermere's army. His log cabin's down south, away from the town roads. He may be willing to trade an old blade for something for supper.")],
		["What about better tools?",func(): dialog("Tavi","DAIN'S SMITHY","Dain Rusk keeps the smithy east of the square. Go see him when you're thinking about upgrading your tools. He knows good steel, and he won't talk you into something you don't need.")],
		["Back to shopping",func(): talk("tavi")]])

func bulletin_board() -> void:
	state.requests.refresh(state)
	var choices=[]
	if not state.firewood_given:
		choices.append(["Job: firewood for Oren at the lighthouse",func():
			state.accept_firewood_task()
			save_visit()
			panel("Keep the lighthouse warm","OREN · SIX LOGS","The lighthouse stove needs firewood. Come see Oren at the western light if you can help. A few coins and an old fishing pole await a willing pair of hands.")])
	if not state.ladder_returned: choices.append(["Notice: Mrs. Bell's missing ladder",ask_bell_ladder])
	for job in state.requests.jobs:
		if int(job.week)!=state.requests.week or job.status not in ["offered","active"]: continue
		var id=state.requests.quest_id(job)
		var terms=state.requests.POOL[int(job.template)]
		choices.append(["%s for %s"%[state.requests.supplies(int(job.template)),person_name(terms[0])],func(): read_local_request(id)])
	panel("Local postings","BRIAR GLEN NOTICE BOARD","Four places for local notices. Weekly requests change each week; deliver an accepted request to the person who posted it before the next refresh.",choices)

func person_name(id: String) -> String:
	for person in outdoors.people:
		if person.id==id: return person.name
	return id.capitalize()

func read_local_request(id: String) -> void:
	state.requests.refresh(state)
	for job in state.requests.jobs:
		if state.requests.quest_id(job)!=id or job.status not in ["offered","active"]: continue
		var terms=state.requests.POOL[int(job.template)]
		var choices=[]
		if job.status=="offered": choices.append(["I'll take this request",func(): state.requests.accept(state,id); save_visit(); bulletin_board()])
		choices.append(["Back to the board",bulletin_board])
		panel("A request from "+person_name(terms[0]),"LOCAL HELP WANTED","Complete the task: %s. Get the result to %s before the week is out. Reward: %d crowns."%[state.requests.supplies(int(job.template)),person_name(terms[0]),terms[3]],choices)
		return
	toast("That notice is no longer on the board.")

func prepare_welcome_party() -> void:
	welcome_entry_times.clear()
	for visitor in WELCOME_MEMBERS:
		outdoors.story_destinations[visitor]={"cell":Grid.world_to_cell(outdoors.site_position("bed")),"room":"","sleeping":false}

func mayor() -> void:
	if current_room=="home" and state.welcome_phase=="waiting":
		prepare_welcome_party()
		state.welcome_phase="arriving"
		ui.update_hud()
		return
	var first_visit=current_room=="home" and state.welcome_phase in ["arriving","meeting"]
	if not first_visit and state.welcome_phase!="complete":
		dialog("Mayor Alder","THE OLD FARMHOUSE","Let's talk inside the farmhouse, where everyone can join us.")
		return
	if not first_visit and not state.mayor_available(): return
	if first_visit:
		state.welcome_phase="meeting"
		resting=0
		activity=""
		face_welcome_party()
	begin_conversation(["mayor","assistant","moss"],true)
	dialog("Mayor Alder","BRIAR GLEN · AT YOUR FARM","Well, look at that. The lamps are working again! Moss says you're travelers in need of a roof. It's been a long time since anyone called this place home. You're welcome to stay, so long as you look after it. Keep it clean, and we'll get along nicely.",[
		["We can promise that.",func(): dialog("Neral","MAYOR'S ASSISTANT · DARK ELF","Alder, a long stay? With matters as they stand along the border with Veyr, oughtn't we find out more before handing over a house? We don't know anything about them. They're strangers! How can we take them at their word? And that flash on the mountain still has no explanation.",[
			["Thank you, Neral.",func(): dialog("Mayor Alder","BRIAR GLEN","Now, Neral, let our guests catch their breath. There's a garden out there if you'd like to earn your keep. Moss left seeds and tools in the chest, and Tavi buys produce in the square. Good food on your table and a little money in your pocket. Not a bad place to begin.",[
				["We'll keep the house clean and make a start in the garden.",func():
					state.met_mayor=true
					end_conversation()
					if first_visit:
						state.welcome_phase="departing"
						departure_paths.clear()
						for id in ["mayor","assistant"]: outdoors.story_destinations.erase(id)
					save_visit()
					toast("A home in Briar Glen. The rest can wait.",7.0)
					burst(state.player_position,"e7cf8e",30)]])]])]])

func place_welcome_party() -> void:
	if current_room!="home": return
	state.player_position=Grid.center(Vector2i(4,11))
	for i in range(WELCOME_MEMBERS.size()):
		var id=WELCOME_MEMBERS[i]
		var actor=world.villagers[id]
		outdoors.villagers[id].data.room="home"
		outdoors.villagers[id].data.sleeping=false
		outdoors.villagers[id].position=outdoors.site_position("bed")+Vector2(0,32)
		actor.visible=true
		actor.data.sleeping=false
		actor.position=Grid.center(WELCOME_POSITIONS[i])
		actor.queue_redraw()
	face_welcome_party()

func face_welcome_party() -> void:
	for actor in world.villagers.values():
		if not actor.visible: continue
		actor.data.direction=World.Bodies.facing_for(state.player_position-actor.position)
		actor.data.walking=false
		actor.queue_redraw()
	world.facing=World.Bodies.facing_for(world.villagers.mayor.position-state.player_position)

func walk_visitor(id: String,cell: Vector2i,dt: float) -> bool:
	return world.walk_actor(id,cell,dt,100)

func update_welcome_arrival(dt: float) -> void:
	outdoors.update_villagers(dt*2)
	if state.player_position.distance_to(Grid.center(Vector2i(4,11)))>1:
		var path=world._route(Grid.world_to_cell(state.player_position),Vector2i(4,11))
		var next=path[0] if not path.is_empty() else Grid.center(Vector2i(4,11))
		world.facing=World.Bodies.facing_for(next-state.player_position)
		state.player_position=state.player_position.move_toward(next,dt*120)
		world.moving=true
		return
	var arrived=true
	for i in range(WELCOME_MEMBERS.size()):
		var id=WELCOME_MEMBERS[i]
		var actor=world.villagers[id]
		if i>0 and (not welcome_entry_times.has(WELCOME_MEMBERS[i-1]) or elapsed-float(welcome_entry_times[WELCOME_MEMBERS[i-1]])<0.5 or world.villagers[WELCOME_MEMBERS[i-1]].position.distance_to(world.entry_position())<World.Bodies.RADIUS*1.5):
			arrived=false
			break
		outdoors.story_destinations[id]={"cell":Grid.world_to_cell(outdoors.site_position("bed")),"room":"home","sleeping":false}
		if outdoors.villagers[id].data.get("room","")!="home": arrived=false; continue
		if not actor.visible:
			actor.position=world.entry_position()
			actor.visible=true
			welcome_entry_times[id]=elapsed
		if not walk_visitor(id,WELCOME_POSITIONS[i],dt): arrived=false
		else:
			actor.data.direction=World.Bodies.facing_for(state.player_position-actor.position)
			actor.queue_redraw()
	if arrived: mayor()

func update_welcome_departure(dt: float,members: Array=["mayor","assistant"]) -> void:
	var remaining=0
	for id in members:
		var actor=world.villagers[id]
		if not actor.visible: continue
		if walk_visitor(id,world.layout.exit,dt):
			actor.visible=false
			outdoors.villagers[id].data.room=""
			outdoors.villagers[id].visible=true
			outdoors.routes.erase(id)
		else: remaining+=1
	if remaining==0:
		if members==["moss"]: state.welcome_phase="complete"
		else: moss_lesson()

func moss_lesson() -> void:
	state.welcome_phase="moss_lesson"
	begin_conversation(["moss"],true)
	dialog("Moss","A LITTLE HELP GETTING STARTED","Before I go, those seeds will do you more good in the ground than in a chest. Hoe a little patch and plant them. The can's empty, but there's a pond south of here. Give them water each day; three watered nights and you should have a crop. The soil dries out by sunrise, so don't forget the next morning. Use the sickle when it's ready. Mind your energy, though. A meal and a rest in your own bed will set you right. And listen to the radio regularly; news travels farther than any of us can walk.",[
		["I need some copper. Any idea where I could find some?",func(): preload("res://local_guidance.gd").copper(self)],
		["And the spell you mentioned?",func(): dialog("Moss","THE WIZARD IN THE NORTHERN CLIFFS","Go see Iona. She'll introduce you to this area's deities and magic. Might save you a sore back in the garden. She's a night owl and sleeps till noon, then spends a few hours around the square before working at her northern tower. Ask her whenever she's awake; she's happy to teach.",[
			["Thanks, Moss. We'll visit her.",func():
				state.welcome_phase="moss_departing"
				end_conversation()
				outdoors.story_destinations.erase("moss")
				save_visit()]])]])

func ask_bell_ladder() -> void:
	state.ladder_clue=true
	state.ladder_requested=true
	dialog("Mrs. Bell","A LADDER WITH LEGS","My good ladder's gone wandering. Nessa was asking how high a radio aerial needs to be, which may be a clue. Would you ask her about it? I'd like it back before my climbing roses take over the house.")
	save_visit()

func return_bell_ladder() -> void:
	if state.ladder<1: return
	state.ladder-=1
	state.clear_empty_slots()
	state.ladder_requested=true
	state.ladder_returned=true
	state.change_friendship("miller_wife",25)
	dialog("Mrs. Bell","BACK WHERE IT BELONGS","There it is! Thank you. I'll have a word with Nessa. I don't mind lending things, but it's nice to be asked before I'm left balancing on a flour sack.")
	save_visit()

func radio() -> void:
	if state.ladder_returned:
		dialog("Briar Glen Radio","LOCAL SERVICE · 1040","...the north road remains open, with delays at the border. Mrs. Bell sends her thanks to the travelers who returned her ladder. Tonight: the Radio Club's music hour.")
		return
	dialog("Briar Glen Radio","LOCAL SERVICE · 1040","...a fair morning across the valley. The north road is open to travelers, with delays at the border crossing. Tonight: the Radio Club's spring music hour. And if anyone has borrowed Mrs. Bell's ladder, she would like it back.")

func inventory() -> void:
	if welcome_control_locked(): return
	window_open=true
	ui.open_inventory()

func inventory_stacks() -> Array:
	return state.inventory_cells().filter(func(stack):return not stack.is_empty())

func use_inventory_item(id: String) -> void:
	if state.consume(id): toast("%s %s." % [ui.Items.CATALOG[id].name,"drunk" if id=="health_elixir" else "eaten"])
	else: toast("Nothing to restore." if ui.Items.FOOD.has(id) else "Keep this for crafting.")
	save_visit()
	inventory()

func item_options(id: String) -> void:
	var choices=[]
	if ui.Items.FOOD.has(id):
		choices.append(["Drink" if id=="health_elixir" else "Eat",func(): use_inventory_item(id)])
	for i in range(8):
		var index=i
		choices.append(["Save to quick slot %d" % (i+1),func(): state.assign_slot(index,id); select_quick_slot(state.selected_slot); save_visit(); inventory()])
	choices.append(["Back to inventory",inventory])
	var info=ui.Items.CATALOG[id] if ui.Items.CATALOG.has(id) else state.Skills.CATALOG[id]
	panel(info.name,"ITEM ACTIONS",info.description,choices)
	ui.modal.get_child(1).position.y=30

func journal() -> void:
	var visit="Speak with Moss behind the farmhouse to arrange the visit."
	if state.invited:
		visit="The mayor's welcome is complete." if state.met_mayor else "Wait inside the farmhouse and finish every cover and bulb. Moss brings Alder and Neral after the house is ready. The welcome sequence holds the clock."
	panel("Captain's field notes","FIRST LANDING","%s Shelter · speak with Moss behind the farmhouse.\n\n%s %s\n\n%s Make the house a home · remove the furniture covers and replace both broken light bulbs. Spares are in the kitchen cabinet.\n\n%s Provide for ourselves · harvest a moon turnip; Tavi buys produce.\n\n%s Crew communications · bring Vale three copper bars. Dain teaches a crucible blueprint for ten star bulbs; build it with stone and smelt the cave ore. Keep food in the ship locker." % ["✓" if state.invited else "○","✓" if state.met_mayor else "○",visit,"✓" if state.house_tasks.values().all(func(done): return done) else "○","✓" if state.harvested>0 else "○","✓" if state.delivered else "○"])
	ui.modal.get_child(1).position.y=55

func map_notes() -> void:
	var wizard="↑ Iona's tower in the northern mountains · she rises at noon" if state.welcome_phase=="complete" else "↑ Northern cliffs"
	panel("Around Briar Glen","ALDERMERE · LOCAL DIRECTIONS","NW Hidden ship & Chief Vale\nN Mountain observatory & Saeren\nN Radio Club & Finch\nW Western shore, stone jetty & Oren's lighthouse\nE Town square, town hall & Tavi's grocery store\n%s\nSW Pond & fishing dock\nS Woodland paths to Bram and Rowan\nSE Copper cave · Dain discusses tool upgrades in town\n\nTavi opens the grocery 08:00–20:00, with lunch at 12:30.\nFaint paths lead from the farm to the coast and southern woods." % wizard)

func settings() -> void:
	if not started: return
	var choices=[["Controls",control_settings],["Settings",preferences],["Save",save_menu],["Quit",quit_menu],["Return to game",func(): pass]]
	if OS.is_debug_build(): choices.insert(2,["Development",development_tools])
	panel("Game menu","BRIAR GLEN","Take a moment.",choices)
	ui.modal.get_child(1).position.y=125

func save_menu() -> void:
	panel("Your visit","SAVE", "Progress is stored inside this project.",[["Save this visit",func(): if save_visit(): toast("Visit saved.")],["Begin a new visit…",reset_confirmation],["Back",settings]])

func quit_menu() -> void:
	panel("Leaving for now?","QUIT","Save your visit before closing the game.",[["Save and quit",quit_game],["Back",settings]])

func preferences() -> void:
	var selected = state.pause_mode
	var choices = [
		[("✓ " if state.needs.hardcore else "")+"Hardcore · hunger and thirst",func(): state.needs.hardcore=not state.needs.hardcore; save_visit(); preferences()],
		[("✓ " if selected=="none" else "")+"Time continues",func(): state.pause_mode="none"; preferences()],
		[("✓ " if selected=="clock" else "")+"Stop calendar · simulation continues",func(): state.pause_mode="clock"; preferences()],
		[("✓ " if selected=="all" else "")+"Pause entire world · single-player default",func(): state.pause_mode="all"; preferences()],
		[("✓ " if controls.show_target else "")+"Always show the facing square",func():
			controls.show_target=not controls.show_target
			if not testing: controls.save()
			preferences()],
		["Sound · music, ambience, and spells",sound_settings],
		["Artwork · choose a sprite pack",art_settings],
		["Back",settings]]
	panel("Make yourself comfortable","FIELD SETTINGS","While a conversation or menu is open:",choices)
	if OS.is_debug_build(): ui.modal.get_child(1).position.y=75

func remap_control(action: String,key: int) -> void:
	controls.rebind(action,key)
	if not testing: controls.save()

func control_settings() -> void:
	panel("Controls","KEYBOARD & MOUSE","Choose a binding, then press a key. Escape cancels. Conflicting keys swap assignments. Left/right mouse buttons use primary/auxiliary actions.",[["Restore defaults",reset_controls],["Back",settings]])
	ui.add_control_bindings()

func reset_controls() -> void:
	controls.reset()
	if not testing: controls.save()
	control_settings()

func art_settings() -> void:
	var choices=[["Option 1 · original artwork",func(): change_art(1)]]
	for pack in Art.available_packs():
		var path: String=pack.path
		choices.append([pack.name,func(): change_art_pack(path)])
	choices.append(["Back to settings",settings])
	panel("Artwork","SPRITE PACKS","Choose the artwork for this session. Install your own pack under src/native/art/packs/ to add it here.",choices)

func change_art_pack(path: String) -> void:
	var error=Art.select_pack(path)
	if not error.is_empty(): toast(error); return
	change_art(2)

func change_art(value: int) -> void:
	Art.option=value
	ui.Items.textures.clear()
	outdoors._build_terrain()
	redraw_art(outdoors)
	for room in rooms.values(): redraw_art(room)
	ui.shown_statuses.clear()
	ui.update()
	redraw_art(ui)
	toast("Original artwork selected." if value==1 else str(Art.read_json(Art.pack_path).get("name","Sprite artwork"))+" selected.")

func redraw_art(node: Node) -> void:
	if node is CanvasItem: node.queue_redraw()
	for child in node.get_children(): redraw_art(child)

func development_tools() -> void:
	if not OS.is_debug_build(): return
	panel("A little further along","DEVELOPMENT TOOLS","Advance the shared calendar and crop growth. Every season has 28 days.\n\nCurrent date: %s %02d, year %d · %02d:%02d" % [state.season_name().capitalize(),state.season_day(),state.calendar_year(),int(state.minute/60.0),int(state.minute)%60],[
		["Advance 1 hour",func(): advance_development_time(60.0)],
		["Advance 12 hours",func(): advance_development_time(720.0)],
		["Advance 24 hours",func(): advance_development_time(1440.0)],
		["Advance 1 season · 28 days",func(): advance_development_time(State.DEVELOPMENT_SEASON_DAYS*1440.0)],
		["Weather · "+state.weather_name().replace("_"," "),development_weather],
		["Return to farmhouse",func():
			if current_room!="": leave_building()
			state.player_position=Grid.center(Vector2i(13,51))
			world.refresh()
			close_window(true)
			],
		["Restore vitals, grant tools and 100,000 crowns",development_supplies],
		["Back to settings",settings]])

func development_supplies() -> void:
	state.health=100
	state.energy=100
	state.mana=60
	state.needs.drink()
	state.needs.eat()
	state.money+=100000
	var missing=[]
	for id in ["rusty_sword","pickaxe","axe","hoe","watering_can","sickle","fishing_pole"]:
		if int(state.get(id))>0: continue
		if state.can_carry(id): state.set(id,1)
		else: missing.append(state.Items.CATALOG[id].name)
	state.inventory_cells()
	save_visit()
	development_tools()
	if not missing.is_empty(): toast("Vitals and crowns restored. Free satchel slots, then use this again for: "+", ".join(missing),8)

func development_weather() -> void:
	var choices=[]
	for mode in ["","sunny","partly_cloudy","rainy"]:
		var weather: String=mode
		choices.append(["Follow the daily forecast" if mode=="" else mode.replace("_"," ").capitalize(),func():
			state.weather_override=weather
			world.refresh()
			update_weather_sound(1)
			save_visit()
			development_tools()])
	panel("Weather","DEVELOPMENT PREVIEW","Preview sunshine, passing clouds or gentle rain. The daily forecast is reproducible for this visit.",choices)

func advance_development_time(minutes: float) -> void:
	if not OS.is_debug_build(): return
	if clock_held(): toast("The opening sequence is holding the clock."); return
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
			state.welcome_phase="complete"
			state.briefing_complete=true
			if world!=outdoors: leave_building()
			end_conversation()
			state=State.new()
			outdoors.rebuild_visit(state)
			for room in rooms.values(): room.state=state
			if rooms.has("cave"):
				rooms.cave.queue_free()
				rooms.erase("cave")
			outdoors.update_villagers(0.0,true)
			saving_disabled=false
			activity=""
			resting=0.0
			enter_building("ship")
			save_visit()
			begin()],
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
	var data=state.to_dict()
	if resting>0:
		data.x=rest_return_position.x
		data.y=rest_return_position.y
	file.store_string(JSON.stringify(data,"\t"))
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
	end_conversation(conversation_sequence)
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
