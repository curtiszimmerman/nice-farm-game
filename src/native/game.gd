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
	["Chief Vale","Ask me again once I've crawled through the wreckage. I'll keep working, but I'm going to need supplies. Quite a lot of them, I suspect."],
	["Chief Vale","There's something else. That attack ship had time to send a signal before we finished it. I doubt it was saying goodbye. Someone will come looking."],
	["Captain","Then we'll get what you need. First order of business: the cloak."],
	["Chief Vale","Already on it. I'm bringing the emergency gravitic power sink online. As long as this planet keeps its gravity well, the cloak should hold. Rather counting on that. It leaves us precious little power for anything else."],
	["Captain","Keeping that cloak running is our main priority until rescue arrives. Outside of that, the basics: food and water, and our local commlink repeater so we can stay in contact."],
	["Chief Vale","Three pieces of copper would get our local repeater talking again. The last scan showed a deposit southeast of a settlement below us. A couple of kilometers, give or take. Assuming I was reading the screen the right way up."],
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
var chest_selected=""
var storage_name="chest"
var rest_return_position=Vector2.ZERO
var conversation_members: Array=[]
var conversation_sequence=false
var conversation_steps=0
var conversation_location=""
var conversation_anchor=Vector2.ZERO
const WELCOME_MEMBERS=["mayor","moss","assistant"]
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
	if not started: return
	if opening!=null: return
	if not conversation_members.is_empty() and (state.location!=conversation_location or state.player_position.distance_to(conversation_anchor)>160): close_window()
	if state.welcome_phase=="waiting":
		state.welcome_elapsed=state.welcome_elapsed+dt if state.house_tasks.values().all(func(done): return done) else 0.0
		if state.welcome_elapsed>=4:
			if window_open: close_window()
			mayor()
	var staged=clock_held()
	var frozen = (window_open and state.pause_mode=="all") or staged
	if not frozen:
		var minutes = dt
		if resting>0.0 and not window_open:
			minutes = minf(resting,dt*90.0)
			resting -= minutes
			state.energy = minf(100.0,state.energy+minutes*0.2)
			if resting<=0.0:
				state.player_position=rest_return_position
				save_visit()
				toast("A little rest. A new angle on the same day.")
		state.advance(minutes,window_open)
		var walking_dt=dt*maxf(1.0,minutes/maxf(dt,0.001))
		for room in rooms.values():
			if room is Interior: room.prepare_departures()
		outdoors.update_villagers(walking_dt)
		for room in rooms.values():
			if room is Interior: room.update_villagers(walking_dt)
		if current_room=="cave":
			world.update_enemies(dt)
			if state.health<=0:
				state.player_position=world.entry_position()
				state.health=25
				toast("You stagger back to the cave entrance. Eat or rest before returning.",6)
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
		world.facing="right" if target.x>state.player_position.x else "left" if target.x<state.player_position.x else "down"
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
	if id=="cave": building={"id":"cave","cell":Vector2i(93,73),"tiles":Vector2i(2,1)}
	if id=="home" and not state.invited and state.briefing_complete:
		if outdoors.villagers.moss.position.distance_to(state.player_position)<75: talk("moss")
		else: toast("Speak to the farmer waiting at the foot of the mountain trail.")
		return
	if building.is_empty(): return
	return_position=outdoors.exit_position(building)
	if not rooms.has(id):
		var room=Cave.new() if id=="cave" else Interior.new()
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
	if id=="home" and state.welcome_phase=="unvisited":
		state.welcome_phase="waiting"
		state.welcome_elapsed=0
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
	if id=="cave" and not state.cave_intro_seen:
		state.cave_intro_seen=true
		save_visit()
		dialog("Captain","AT THE CAVE ENTRANCE","Oh, good. Someone's left a pickaxe against that barrel. I'll need that to break through the rocks and get at any ore. Better take it with us.")

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
	var advance_key=controls.matches(event,"pause") or controls.matches(event,"primary")
	var advance_click=event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT
	if started and (advance_key or advance_click):
		if opening!=null:
			opening.advance()
			get_viewport().set_input_as_handled()
			return
		if window_open and clock_held() and ui.advance_dialogue():
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
	state.action_channel=channel
	if channel=="primary": interact()
	elif state.active_item()=="sit": sit_on_bench()
	elif state.active_item()=="wildgrowth": cast_growth()
	elif state.active_item()!="": interact()
	state.action_channel="primary"

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
	close_window(true)
	action.call()
	if not window_open: end_conversation(false)

func dialog(title: String,role: String,text: String,choices: Array = []) -> void:
	if not conversation_members.is_empty():
		conversation_steps+=1
		if conversation_steps>1: conversation_sequence=true
	window_open = true
	if choices.is_empty(): choices=[["See you around.",func(): pass]]
	ui.open_modal(title,role,text,choices)
	ui.dialogue_open=true
	ui.update_hud()
	if state.welcome_phase in ["meeting","moss_lesson"] or ("moss" in conversation_members and not state.invited): ui.modal.get_child(1).position.y=35

func panel(title: String,eyebrow: String,text: String,choices: Array = []) -> void:
	if welcome_control_locked(): return
	window_open = true
	if choices.is_empty(): choices=[["Back to the morning",func(): pass]]
	ui.open_modal(title,eyebrow,text,choices,true)

func interact() -> void:
	if not started or window_open or opening!=null: return
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
	if nearest.get("id","").begins_with("bench"):
		sit_on_bench()
		return
	if nearest.get("id")=="stove": cooking(); return
	if state.active_item()=="rusty_sword" and nearest.get("type")!="site":
		if world.attack(): burst(state.player_position+Vector2({"up":Vector2.UP,"down":Vector2.DOWN,"left":Vector2.LEFT,"right":Vector2.RIGHT}[world.facing])*26,"e8d2a0",10); save_visit()
		else: toast("Carry and select your sword, and keep enough energy to swing.")
		return
	if ui.Items.FOOD.has(state.active_item()):
		toast("Used %s." % ui.Items.CATALOG[state.active_item()].name if state.consume(state.active_item()) else "Nothing to restore, or none carried.")
		save_visit()
		return
	if world==outdoors and state.active_item()=="watering_can" and world.at_pond_edge(state.player_position):
		toast("Watering can filled · 20 / 20" if state.refill_water() else "Take your watering can from storage first.")
		save_visit()
		return
	if nearest.get("type")=="rock":
		var position=Grid.center(world.rocks[nearest.id].cell)
		if world.mine_rock(nearest.id): burst(position,"c6a47b",12); save_visit(); toast("Rock mined. Five energy spent.")
		else: toast("Select a carried pickaxe. Mining costs 5 energy and needs room in your satchel.")
		return
	if nearest.is_empty():
		toast("Walk closer to a person, garden patch, or landmark.")
		return
	if nearest.type=="plot":
		if state.active_item()=="wildgrowth": cast_growth(); return
		var was_ripe=state.ripe(nearest.index)
		var before: Dictionary=state.plots[nearest.index].duplicate()
		toast(state.farm(nearest.index),2.5)
		if before!=state.plots[nearest.index]:
			preload("res://tool_motion.gd").start(world,state.active_item() if state.active_item()!="" else "sickle" if was_ripe else "hoe")
			burst(world.plot_position(nearest.index),"e5d0a4" if was_ripe else "b8bf86",20 if was_ripe else 7)
			world.crops.queue_redraw()
			save_visit()
	elif nearest.type=="tree":
		if world.chop_tree(nearest.cell):
			burst(Grid.center(nearest.cell),"b89662",12)
			toast("Three pieces of firewood gathered." if not world.solid_cells.has(nearest.cell) else "The axe bites into the trunk.")
			save_visit()
		else: toast("You need an axe, four energy, and room for firewood.")
	elif nearest.type=="person": talk(nearest.id)
	else:
		if nearest.has("door"):
			enter_building(nearest.door)
			return
		match nearest.id:
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
				if state.minute<330 or state.minute>=420: toast("An ordinary-looking plant. Its golden flower opens only at sunrise.")
				elif state.sparkfire_picked_day==state.day: toast("The dawn flower has already been gathered today.")
				elif not state.can_carry("golden_sparkfire_bloom"): toast("Make room in your satchel.")
				else:
					state.golden_sparkfire_bloom+=1
					state.sparkfire_picked_day=state.day
					toast("Golden Sparkfire Bloom gathered in the sunrise.")
					save_visit()
			"stove": cooking()
			"diagnostics": panel("Engineering diagnostics","CLOAKED SHIP · BATTLE DAMAGE","Phase-conjugate manifold: unstable. Gravitic shear compensator: bypassed. Inertial lattice: cracked. Plasma return bus: vented. Vale has isolated the sparking cables; the cloak and bunk section remain safe.")
			"exit": leave_building()
			"shop": talk("tavi")
			"bed":
				if current_room=="home" and not state.house_tasks.bed: tidy_farmhouse("bed")
				else: rest_options()
			"pond","ocean","ocean_tip":
				start_fishing(nearest.id)
			"sign": dialog("A weathered sign","BRIAR GLEN","East: town and market. Southwest: the old mill pond. Southeast: copper outcrop. Northwest: nothing in particular, according to the official map.")
			"radio":
				if current_room=="home" and not state.house_tasks.radio: tidy_farmhouse("radio")
				else: radio()

func tidy_farmhouse(task: String) -> void:
	if state.tidy_house(task):
		toast("Light repaired." if task.ends_with("light") else "Dusty cover folded away.")
		save_visit()
		world.refresh()
		world.queue_redraw()
	else: toast("Take a replacement bulb from the kitchen cabinet first." if task.ends_with("light") and not state.house_tasks[task] else "Already taken care of.")

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
	return ui.Items.FISH.keys().filter(func(id): return ui.Items.FISH[id].habitat==habitat or (habitat=="ocean_tip" and ui.Items.FISH[id].habitat=="ocean"))

func start_fishing(habitat: String) -> void:
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
		if not ui.Items.CATALOG.has(id): return false
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
		if replaced!="" and replaced!=data.id and int(state.get(data.id))==0:
			if amount!=state.get(source)[int(data.index)].count: return false
			if not state.storage_transfer(source,int(data.index),replaced): return false
		elif not state.storage_transfer(source,int(data.index),"",amount): return false
	if index>=0: return state.move_inventory(data.id,index)
	if destination.get("channel","")!="": return state.assign_active(destination.channel,data.id)
	return state.assign_slot(int(destination.quick_index),data.id)

func cooking() -> void:
	if current_room!="home" or state.player_position.distance_to(world.site_position("stove"))>55:
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
			cooking()])
	choices.append(["Open kitchen cabinet",func(): open_storage("cabinet")])
	choices.append(["Done cooking",func(): pass])
	panel("Farmhouse stove","COOKING","Recipes draw ingredients from your satchel and the connected twelve-slot kitchen cabinet. Tavi sells pots and pans for 20 crowns each.",choices)

func talk(id: String) -> void:
	begin_conversation([id],id in ["veteran","finch","vale"] or (id=="moss" and not state.invited))
	if id not in ["smith","woodcutter"] and preload("res://neighbors.gd").talk(self,id): return
	match id:
		"smith":
			var at_work=current_room=="smithy"
			dialog("Dain Rusk","BLACKSMITH","Mind the hot scale. I can tell a lot about a tool by the wear on its edge. Bring yours by when you're ready to talk about better steel." if at_work else "Good to stretch my shoulders after a day at the forge. If you're thinking about upgrading your tools, come see me at the smithy.",[
				["Tell me about your work.",func(): dialog("Dain Rusk","BETTER TOOLS","A sound handle, a balanced head, an edge that holds. That's where I'd start. Bring your tools to the forge and we'll talk about what they need.")],
				["What sort of work do you do?",func(): dialog("Dain Rusk","IRON & HONEST WEAR",preload("res://neighbors.gd").STORIES.smith.split("|",true,1)[1])],
				["See you around.",func(): pass]])
		"woodcutter":
			dialog("Rowan","FOREST WOODCUTTER","Mind the shavings if you're coming in. I've a spare axe, if you're after firewood. Oren's knees aren't what they used to be; he shouldn't be swinging one at all." if current_room=="woodcutter" else "Hello there. Leave the little saplings, won't you? The older trees give us all the wood we need. If you're looking for an axe, I've a spare you can keep.",[
				["I'd appreciate an axe.",func(): offer_tool("axe","Rowan")],
				["How do you choose which trees to cut?",func(): dialog("Rowan","A FOREST THAT LASTS","Look up first. Then look at the roots. I mark the old and crowded trees and leave the rest room to grow. My mother taught me these woods. I'd like somebody else's daughter to know them too.")],
				["I'll be careful. Thank you.",func(): pass]])
		"keeper":
			var choices=[]
			if not state.firewood_given:
				choices.append(["I can chop some wood for you." if not state.firewood_requested else "I've brought your firewood.",func():
					if not state.firewood_requested:
						if state.accept_firewood_task(): dialog("Oren","A FAVOR FOR THE KEEPER","Bless you. Six pieces will keep the stove going nicely. Rowan, the woodcutter down in the southern woods, can help you find an axe. I'll have the kettle on when you get back.")
						else: dialog("Oren","A FAVOR FOR THE KEEPER","You've already done more than enough. Thank you for seeing to the stove.")
					elif state.deliver_firewood(): dialog("Oren","A WARM LIGHT","Ah, that's the stuff. Thank you. Take twenty-five crowns for your trouble, and come warm your hands any time. The kettle's seldom cold.")
					else: dialog("Oren","A FAVOR FOR THE KEEPER","Six pieces, when you've a moment. No need to strip the whole forest on my account.")
					save_visit()])
			choices.append(["Any advice for fishing out here?",func(): dialog("Oren","OUT BEYOND THE BREAKERS","Sprats and mackerel right along the shore. An eel if it's feeling disagreeable. But walk to the very sea end of the jetty and look down after dark. Sometimes there's a little gold light under the water. Lantern rays. Hard to land, those. Worth a patient afternoon.")])
			choices.append(["I'll let you get back to it.",func(): pass])
			dialog("Oren","KEEPER OF THE WESTERN LIGHT","Well now, a visitor! Come in out of that wind. I'm Oren. I mind the light, and the light mostly minds itself these days. The stove's another matter. My knees have rather lost their enthusiasm for chopping wood." if not state.firewood_given else "Good to see you again. Warm in here, thanks to you. How's life up at the old farmhouse?",choices)
		"veteran":
			dialog("Bram","A CABIN IN THE SOUTH WOODS","Aldermere's army had me for a good many years. If you're thinking of heading toward Veyr, stop by first. I've a few things worth telling. Here, take this old blade. Rust comes off. Being unprepared is harder to fix.",[
				["Accept the rusty sword" if not state.has_sword() else "Thank you for the sword",func():
					if state.accept_sword(): save_visit(); toast("Rusty sword added to your satchel. Select it to equip.",6)],
				["What should we know about Veyr?",func(): dialog("Bram","RETIRED ARMY","Don't let a uniform do your thinking for you. I learned that rather late. A family in Veyr hid me in their cellar for three nights. No reason to help an Aldermere soldier, and they did it anyway. I still think about them.")]])
		"mayor":
			if state.mayor_available(): mayor()
			else: dialog("Mayor Alder","BRIAR GLEN","Good to see you out and about. Most days I'm at the town hall, with a break in the square at noon.")
		"assistant":
			if state.mayor_available(): mayor()
			else: dialog("Neral","MAYOR'S ASSISTANT · DARK ELF","If you remember anything else about the light on the mountain, do let me know. We keep records for a reason." if current_room=="hall" else "Moss speaks well of you. I'd like very much to see him proved right. This town has given a good deal to the people who come here; it's worth looking after.")
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
			else: dialog("Moss","NEIGHBOR · SOUTH FARM","Settling in, then? Tools and seeds are in that chest outside. Keep the ground watered and you'll have turnips in three days. Tavi'll buy anything you don't eat. He claims mine are the sweetest in the village. Of course, he says that to everyone." if state.met_mayor else "Go on inside. I'll bring Alder and Neral back shortly. Make yourselves comfortable and see what needs tidying.")
		"tavi":
			conversation_steps=0
			dialog("Tavi","TRAVELING MERCHANT","Hello again! Need anything for the garden? Or have you brought me something good? I'm off to Veyr for my sister's festival next month. Help me travel with a lighter cart, eh?" if current_room=="store" else "A little fresh air before I go back to the shop. My sister says I should learn to leave work at work. Sensible advice, but I've never been terribly good at it. What can I do for you?",[
				["Sell produce · %d crowns" % state.sale_value(),func():
					if state.sell(): save_visit(); toast("Sold. Locally grown, very far from home.")
					else: toast("Bring turnips or silverfin to sell.")
					talk("tavi")],
				["Buy 5 moon-turnip seeds · 10 crowns",func():
					if state.buy_seeds(): save_visit(); toast("Five seeds tucked into your satchel.")
					else: toast("You need 10 crowns.")
					talk("tavi")],
				["Buy 3 star-bulb seeds · 12 crowns",func():
					if state.buy_star_seeds(): save_visit(); toast("Three star-bulb seeds. Select them in your satchel before planting.",6)
					else: toast("You need 12 crowns.")
					talk("tavi")],
				["Buy frying pan · 20 crowns · unlock fish sticks",func(): buy_cookware("pan")],
				["Buy cooking pot · 20 crowns · unlock fish stew",func(): buy_cookware("pot")],
				["Buy elixir of health · 15 crowns",func():
					if state.money>=15 and state.can_carry("health_elixir"): state.money-=15; state.health_elixir+=1; save_visit()
					else: toast("You need 15 crowns and room in your satchel.")
					talk("tavi")],
				["Where can I get tools?",tool_directions],
				["Just passing through.",func(): pass]])
			ui.modal.get_child(1).position.y=125
		"iona":
			if current_room!="iona" and state.player_position.distance_to(Grid.center(Vector2i(61,15)))>160:
				dialog("Iona","FIELD MAGICIAN","Come visit my tower in the northern cliffs if you'd like a lesson. I keep late hours.")
			else:
				dialog("Iona","MAGIC OF BRIAR GLEN","You'll find our deities gentler than the ones near the Veyr border. Mostly they want things to grow. I can show you Wildgrowth, if you like. Water a seed first, then give it a little encouragement. Fifteen mana, and no fee for the lesson. For something more adventurous, bring me a Cave Moth Chrysalis from deep underground, or a Golden Sparkfire Bloom. Mind you, that flower only opens while the sun is rising. Walk past at noon and you'd never give it a second glance.",[
					["Learn the basics" if not state.magic_learned else "Practice Wildgrowth",func(): state.magic_learned=true; save_visit(); toast("Wildgrowth learned. Assign it yourself under Actions → Spells and skills.",7)]])
		"finch": dialog("Finch","RADIO CLUB SECRETARY","Come in, come in. Mind that cable. Last week we picked up a dance band from Veyr, clear as anything. Governments can argue all they like; the air doesn't stop at a checkpoint." if current_room=="radio" else "Good to give my eyes a rest from the wiring. Nessa's coming along nicely with that receiver. Her mother will have river weather reports in the kitchen before long.",[["What's on the air today?",radio],["I'll come back sometime.",func(): pass]])
		"vale":
			if not state.briefing_complete: show_briefing(); return
			if state.delivered: dialog("Chief Vale","CHIEF ENGINEER · SECURE CREW LINK","Give your commlink a try. Hear that? Much better than shouting down a mountain. The cloak's holding, too. "+("Thanks for seeing to supper. I'll try to earn it before the day's out." if state.crew_fed_day==state.day else "I meant to stop for breakfast, but the locker was empty. If you find something to cook, save me a helping?"))
			else: dialog("Chief Vale","CHIEF ENGINEER · SECURE CREW LINK","The cloak's behaving. Wish I could say the same for the engines. Bring me three copper from that southeast cave and we'll at least have our crew link back. How's the search for supper going? The emergency rations won't last forever. Leave me a cooked meal in the locker if you can. I'll try not to get engine grease on it.",[
				["Hand over three copper." if state.copper>=3 else "I'll look inside the southeast cave.",func():
					if state.copper>=3:
						state.copper-=3
						state.delivered=true
						save_visit()
						burst(state.player_position,"a3d4d0")
						toast("Crew link restored. One small connection home.",6.0)],
				["How long do we have?",func(): dialog("Chief Vale","CHIEF ENGINEER","As long as the cloak holds, we have room to breathe. No signals. No active scans. I'll keep the lights off. You keep us fed.")]])

func buy_cookware(id: String) -> void:
	if not state.buy_utensil(id):
		toast("Already purchased, or you need 20 crowns and room in your satchel.")
		talk("tavi")
		return
	save_visit()
	dialog("Tavi","A LITTLE HOME COOKING","There you are. That old stove in your kitchen should serve you well. Leave your food and cookware in the kitchen cabinet and you can cook straight from there. Anything you're carrying works too; no need to haul the whole cupboard about.",[["Thanks. What else have you got?",func(): talk("tavi")]])

func offer_tool(id: String,person: String) -> void:
	var flag="woodcutter_axe_given" if id=="axe" else "cave_pickaxe_taken"
	var response="You've already got the one I set aside for you. Take good care of it."
	if not state.get(flag):
		if state.accept_tool(id):
			save_visit()
			response="There you are. A useful tool, and yours to keep. Mind your footing, and give yourself a rest when your arms get tired."
		else: response="You're carrying rather a lot. Make a little room and come back for it."
	dialog(person,"A TOOL TO GET STARTED",response)

func tool_directions() -> void:
	dialog("Tavi","ASK A LOCAL","For tools, I know just the people. What are you after?",[
		["Where can I get an axe?",func(): dialog("Tavi","ROWAN'S CABIN","Rowan, the woodcutter, lives in the southern woods, west of Bram's cabin. Follow the faint woodland path. Ask her about a spare axe.")],
		["Where can I get a sword?",func(): dialog("Tavi","BRAM'S CABIN","Bram served in Aldermere's army. His log cabin's down south, away from the town roads. He may have an old blade you're welcome to.")],
		["What about better tools?",func(): dialog("Tavi","DAIN'S SMITHY","Dain Rusk keeps the smithy east of the square. Go see him when you're thinking about upgrading your tools. He knows good steel, and he won't talk you into something you don't need.")],
		["Back to shopping",func(): talk("tavi")]])

func bulletin_board() -> void:
	panel("Local postings","BRIAR GLEN NOTICE BOARD","Handwritten notices overlap on a weathered board. Someone has pinned a fresh request beside a flour-dusted visiting card.",[
		["Job: firewood for the lighthouse",func():
			state.accept_firewood_task()
			save_visit()
			panel("Keep the lighthouse warm","OREN · SIX FIREWOOD · 25 CROWNS","Bring Oren six pieces of firewood at the western lighthouse. Rowan in the southern woods can help with an axe. Payment on delivery.")],
		["Notice: a warm loaf and local news",func(): panel("Corin's bakery","FRESH BREAD & GOOD COMPANY","Visitors welcome. Bring your news, your questions, or simply yourself. The bakery is southeast of the square.")],
		["Notice: tool upgrades",func(): panel("Dain Rusk's smithy","BETTER TOOLS, HONEST WORK","Thinking about upgrading your tools? Speak to Dain at the forge east of the square.")]])

func mayor() -> void:
	if current_room=="home" and state.welcome_phase=="waiting":
		state.welcome_phase="arriving"
		for id in WELCOME_MEMBERS:
			outdoors.story_destinations[id]={"cell":Grid.world_to_cell(outdoors.site_position("bed"))+Vector2i.DOWN,"room":"home","sleeping":false}
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
	begin_conversation(["mayor","assistant","moss"],true)
	dialog("Mayor Alder","BRIAR GLEN · AT YOUR FARM","Well, look at that. The lamps are working again! Moss says you're travelers in need of a roof. It's been a long time since anyone called this place home. You're welcome to stay, so long as you look after it. Keep it clean, and we'll get along nicely.",[
		["We can promise that.",func(): dialog("Neral","MAYOR'S ASSISTANT · DARK ELF","Alder, a long stay? With matters as they stand with Veyr, oughtn't we find out a little more before handing over a house? We have their word that they're travelers, and a flash on the mountain. That's a rather thin introduction.",[
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
		actor.position=Grid.center([Vector2i(3,11),Vector2i(5,11),Vector2i(4,12)][i])
		actor.queue_redraw()

func walk_visitor(id: String,cell: Vector2i,dt: float) -> bool:
	return world.walk_actor(id,cell,dt,65)

func update_welcome_arrival(dt: float) -> void:
	if state.player_position.distance_to(Grid.center(Vector2i(4,11)))>1:
		var path=world._route(Grid.world_to_cell(state.player_position),Vector2i(4,11))
		if not path.is_empty():
			state.player_position=state.player_position.move_toward(path[0],dt*65)
			world.moving=true
			return
	outdoors.update_villagers(dt)
	var arrived=true
	for i in range(WELCOME_MEMBERS.size()):
		var id=WELCOME_MEMBERS[i]
		var actor=world.villagers[id]
		if outdoors.villagers[id].data.get("room","")!="home": arrived=false; continue
		if not actor.visible:
			actor.position=world.entry_position()
			actor.visible=true
		if not walk_visitor(id,[Vector2i(3,11),Vector2i(5,11),Vector2i(4,12)][i],dt): arrived=false
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
	dialog("Moss","A LITTLE HELP GETTING STARTED","Before I go, those seeds will do you more good in the ground than in a chest. Hoe a little patch, plant them, and keep it watered. The can's empty, but there's a pond south of here. Three days and you should have a crop. Use the sickle when it's ready. Mind your energy, though. A meal and a rest in your own bed will set you right.",[
		["And the spell you mentioned?",func(): dialog("Moss","THE WIZARD IN THE NORTHERN CLIFFS","Go see Iona, up at the northern tower. She'll introduce you to this area's deities and magic. Might save you a sore back in the garden. Don't knock before noon, though. She's likely only just gone to bed.",[
			["Thanks, Moss. We'll visit her.",func():
				state.welcome_phase="moss_departing"
				end_conversation()
				outdoors.story_destinations.erase("moss")
				save_visit()]])]])

func radio() -> void:
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
	panel(ui.Items.CATALOG[id].name,"ITEM ACTIONS",ui.Items.CATALOG[id].description,choices)
	ui.modal.get_child(1).position.y=30

func journal() -> void:
	var visit="Speak with Moss behind the farmhouse to arrange the visit."
	if state.invited:
		visit="The mayor's welcome is complete." if state.met_mayor else "Wait inside the farmhouse and finish every cover and bulb. Moss brings Alder and Neral after the house is ready. The welcome sequence holds the clock."
	panel("Captain's field notes","FIRST LANDING","%s Shelter · speak with Moss behind the farmhouse.\n\n%s %s\n\n%s Make the house a home · remove the furniture covers and replace both broken light bulbs. Spares are in the kitchen cabinet.\n\n%s Provide for ourselves · harvest a moon turnip; Tavi buys produce.\n\n%s Crew communications · bring Vale three copper from southeast of town. Keep food in the ship locker." % ["✓" if state.invited else "○","✓" if state.met_mayor else "○",visit,"✓" if state.house_tasks.values().all(func(done): return done) else "○","✓" if state.harvested>0 else "○","✓" if state.delivered else "○"])
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
	toast("Original artwork selected." if value==1 else str(Art.read_json(Art.pack_path).get("name","Sprite artwork"))+" selected.")

func redraw_art(node: Node) -> void:
	if node is CanvasItem: node.queue_redraw()
	for child in node.get_children(): redraw_art(child)

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
