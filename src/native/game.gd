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
var opening: CanvasLayer
const BRIEFING=[
	["Captain","Status report?"],
	["Chief Vale","All major systems are down and need repairs. Propulsion, long-range communications, the distress transmitter. We can't even call for help."],
	["Captain","What's your estimate?"],
	["Chief Vale","I'm not sure yet. I'll need a lot of supplies and constant work on the ship. This won't be a quick patch job."],
	["Chief Vale","We destroyed the attacker, but I'm sure it sent out a signal before it exploded. Reinforcements will probably arrive at some point. We need to stay hidden."],
	["Captain","Then we'll get what you need. First order of business: the cloak."],
	["Chief Vale","Initializing the emergency gravitic power sink. The cloak should remain stable as long as this planet's gravity well remains stable. That's all our systems have room for at the moment."],
	["Captain","Keeping that cloak running is our main priority until rescue arrives. Outside of that, the basics: food and water, and our local commlink repeater so we can stay in contact."],
	["Chief Vale","Three pieces of copper would get the local repeater working. Before the crash, scans found a small deposit a couple of kilometers southeast of an inhabited area below us."],
	["Captain","What have we got for food?"],
	["Chief Vale","Six rations in the supply locker by the bunks. I'll use one per day while I work. Once those are gone, leave a cooked meal there each day. We'll need a dependable source of food and fresh water."],
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
	if not state.intro_complete:
		opening=Opening.new()
		opening.game=self
		add_child(opening)
	elif not state.briefing_complete: show_briefing()
	elif state.welcome_phase=="meeting": mayor()
	elif state.welcome_phase=="departing": place_welcome_party()
	elif state.welcome_phase=="moss_lesson":
		place_welcome_party()
		for id in ["mayor","assistant"]: world.villagers[id].visible=false
		moss_lesson()
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
		if state.welcome_elapsed>=8:
			if window_open: close_window()
			mayor()
	var staged=clock_held()
	var frozen = (window_open and state.pause_mode=="all") or staged
	if not frozen:
		var minutes = dt*3.0
		if resting>0.0 and not window_open:
			minutes = minf(resting,dt*90.0)
			resting -= minutes
			state.energy = minf(100.0,state.energy+minutes*0.2)
			if resting<=0.0:
				state.player_position=rest_return_position
				save_visit()
				toast("A little rest. A new angle on the same day.")
		state.advance(minutes,window_open)
		var walking_dt=dt*maxf(1.0,minutes/maxf(dt*3.0,0.001))
		outdoors.update_villagers(walking_dt)
		if world!=outdoors: world.update_villagers(walking_dt)
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
	else:
		world.moving=false
		if state.welcome_phase=="escorting": update_escort(dt)
		elif state.welcome_phase=="departing": update_welcome_departure(dt)
		elif staged and state.welcome_phase!="meeting":
			_move(dt)
			_update_activity(dt)
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
	return not state.ship_departed or state.welcome_phase in ["escorting","waiting","meeting","departing","moss_lesson"] or ("moss" in conversation_members and not state.invited)

func update_escort(dt: float) -> void:
	if escort_path.is_empty():
		escort_path=outdoors._route(Grid.world_to_cell(state.player_position),Grid.world_to_cell(outdoors.site_position("bed"))+Vector2i.DOWN)
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
	if state.welcome_phase in ["escorting","meeting","departing","moss_lesson"]: return
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

func leave_building() -> void:
	if world==outdoors: return
	if current_room=="home" and state.welcome_phase in ["waiting","meeting","departing","moss_lesson"]:
		toast("Wait for Moss and the mayor's party to finish their visit.")
		return
	if current_room=="ship" and not state.briefing_complete:
		show_briefing()
		return
	if current_room=="ship": state.ship_departed=true
	world.visible=false
	world=outdoors
	world.visible=true
	current_room=""
	state.location=""
	state.player_position=return_position
	world.refresh()
	camera.limit_left=0
	camera.limit_top=0
	camera.limit_right=int(Grid.WORLD_SIZE.x)
	camera.limit_bottom=int(Grid.WORLD_SIZE.y)
	camera.position=state.player_position
	activity=""

func _input(event: InputEvent) -> void:
	if started and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_SPACE:
		toggle_pause()
		get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	world_paused=not world_paused
	if world_paused: get_viewport().gui_release_focus()
	if opening!=null: opening.set_process(not world_paused)
	ui.update()

func _unhandled_input(event: InputEvent) -> void:
	if world_paused: return
	if not event is InputEventMouseButton or event.button_index!=MOUSE_BUTTON_LEFT or not event.pressed: return
	if not started or window_open or opening!=null or current_room!="home" or state.welcome_phase in ["meeting","departing","moss_lesson"]: return
	var stove=world.site_position("stove")
	if state.player_position.distance_to(stove)>55: return
	var point=get_viewport().get_canvas_transform().affine_inverse()*event.position
	if Rect2(stove+Vector2(-16,-58),Vector2(64,42)).has_point(point):
		cooking()
		get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode==KEY_F11:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	if not started: return
	if event.physical_keycode==KEY_SPACE:
		toggle_pause()
		return
	if world_paused: return
	if opening!=null: return
	if state.welcome_phase in ["escorting","meeting","departing","moss_lesson"] or ("moss" in conversation_members and not state.invited): return
	match event.physical_keycode:
		KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6,KEY_7,KEY_8:
			select_quick_slot(event.physical_keycode-KEY_1)
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
	if not state.magic_learned:
		panel("Spells and skills","NO SPELLS LEARNED","You have not learned to use this world's magic.")
		return
	var choices=[]
	for i in range(8):
		var index=i
		choices.append(["Assign Wildgrowth to slot %d" % (i+1),func(): state.assign_slot(index,"wildgrowth"); save_visit(); ui.update()])
	panel("Spells and skills","WILDGROWTH","Wildgrowth matures one watered crop for 15 mana. Assign it to a slot, select that slot, then press E or Q.",choices)
	ui.modal.get_child(1).position.y=45

func toast(text: String,duration = 4.0) -> void:
	ui.message.text = text
	message_until = elapsed+duration

func burst(pos: Vector2,color = "a5d8c5",count = 20) -> void:
	for i in range(count):
		var angle = randf()*TAU
		world.particles.append({"pos":pos,"velocity":Vector2(cos(angle)*randf_range(10,35),sin(angle)*25-20),"life":randf_range(1,2),"color":color})

func close_window(preserve_conversation: bool=false) -> void:
	if not preserve_conversation and (state.welcome_phase in ["escorting","meeting","departing","moss_lesson"] or ("moss" in conversation_members and not state.invited)): return
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
	if state.welcome_phase in ["meeting","moss_lesson"] or ("moss" in conversation_members and not state.invited): ui.modal.get_child(1).position.y=35

func panel(title: String,eyebrow: String,text: String,choices: Array = []) -> void:
	if state.welcome_phase in ["escorting","meeting","departing","moss_lesson"] or ("moss" in conversation_members and not state.invited): return
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
	if nearest.get("id")=="stove": cooking(); return
	if current_room=="cave" and state.active_item()=="rusty_sword" and nearest.get("type")!="site":
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
			burst(world.plot_position(nearest.index),"e5d0a4" if was_ripe else "b8bf86",20 if was_ripe else 7)
			world.crops.queue_redraw()
			save_visit()
	elif nearest.type=="person": talk(nearest.id)
	else:
		if nearest.has("door"):
			enter_building(nearest.door)
			return
		match nearest.id:
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
			"pond","ocean":
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
	return ui.Items.FISH.keys().filter(func(id): return ui.Items.FISH[id].habitat==habitat)

func start_fishing(habitat: String) -> void:
	var pool=fish_pool(habitat)
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
	match id:
		"veteran":
			dialog("Bram","A CABIN IN THE SOUTH WOODS","I served in the army. If you're heading toward the other kingdom, come and talk to me before you go. And take this old blade. Rust comes off. Being unprepared is harder to fix.",[
				["Accept the rusty sword" if not state.has_sword() else "Thank you for the sword",func():
					if state.accept_sword(): save_visit(); toast("Rusty sword added to your satchel. Select it to equip.",6)],
				["What should we know about the other kingdom?",func(): dialog("Bram","RETIRED ARMY","Start by remembering that a kingdom's people and its government aren't the same thing. I learned that in uniform. Some of the people who helped me most lived on the other side of the border.")]])
		"mayor":
			if state.mayor_available(): mayor()
			else: dialog("Mayor Alder","BRIAR GLEN","Good to see you out and about. Most days I'm at the town hall, with a break in the square at noon.")
		"assistant":
			if state.mayor_available(): mayor()
			else: dialog("Neral","MAYOR'S ASSISTANT · DARK ELF","I keep the town's appointments and records. Alder likes to arrive early. If Moss has arranged our visit, we'll be at your farm until four.")
		"moss":
			if not state.invited:
				dialog("Moss","AT THE FOOT OF THE MOUNTAIN TRAIL","Hold on there! What was that flash and crashing sound up on the mountain? Looked as though someone cast quite a spell. Are you travelers?",[
					["Answer Moss",func(): dialog("Captain","TRAVELERS","A spell? Oh! Yes, we're travelers. Could you suggest somewhere we might stay for a while?",[
						["Let Moss answer",func(): dialog("Moss","YOUR NEIGHBOR","There's no hotel here, but this farmhouse is abandoned. It can house you for a bit. I live down the road. Go on in while I fetch the mayor. There are clean beds under the covers, and spare bulbs in the kitchen cabinet.",[
							["Thank you. We'll wait inside.",func():
								state.invite_mayor()
								state.welcome_phase="escorting"
								escort_path=outdoors._route(Grid.world_to_cell(state.player_position),Grid.world_to_cell(outdoors.site_position("bed"))+Vector2i.DOWN)
								save_visit()
								toast("You follow Moss's directions into the farmhouse.",7)]])]])]])
			elif state.mayor_available(): mayor()
			else: dialog("Moss","NEIGHBOR · SOUTH FARM","Settling in, then? The chest outside has seeds and tools. Select each tool in a quick slot to use it. Water crops, then give them three days. Tavi buys produce in town." if state.met_mayor else "Go on inside. I'll bring the mayor and Neral back shortly. Make yourselves comfortable and see what needs tidying.")
		"tavi":
			conversation_steps=0
			dialog("Tavi","TRAVELING MERCHANT","Seeds, supper, a good road home. That's most of a life, isn't it? I'm heading across the border for my sister's festival next month. Until then, your turnips are very welcome here.",[
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
				["Just passing through.",func(): pass]])
			ui.modal.get_child(1).position.y=125
		"iona":
			if current_room!="iona" and state.player_position.distance_to(Grid.center(Vector2i(61,15)))>160:
				dialog("Iona","FIELD MAGICIAN","Come visit my tower in the northern cliffs if you'd like a lesson. I keep late hours.")
			else:
				dialog("Iona","MAGIC OF BRIAR GLEN","Our spells answer the gods and goddesses of this region. Another city may work quite different magic. I'll teach you Wildgrowth for free: water a planted seed, then use the spell to hasten its growth. It costs fifteen mana, which returns with time. For further lessons, bring unusual components: a Cave Moth Chrysalis from deep in the caves, or a Golden Sparkfire Bloom. That flower opens only at dawn while the sun rises; at other hours it looks like an ordinary plant.",[
					["Learn the basics" if not state.magic_learned else "Practice Wildgrowth",func(): state.magic_learned=true; save_visit(); toast("Wildgrowth learned. Assign it yourself under Actions → Spells and skills.",7)]])
		"finch": dialog("Finch","RADIO CLUB SECRETARY","You're welcome at the club. Last week we heard a dance band from the far side of the border. Clear as anything. Governments can argue all they like; the air doesn't stop at a checkpoint.",[["What's on the air today?",radio],["I'll come back sometime.",func(): pass]])
		"vale":
			if not state.briefing_complete: show_briefing(); return
			if state.delivered: dialog("Chief Vale","CHIEF ENGINEER · SECURE CREW LINK","Copper seated. Crew link stable; cloak holding. Keep one ration or cooked meal per day in the supply locker beside the bunks. Fish sticks or stew would beat another ration packet. "+("I've eaten today." if state.crew_fed_day==state.day else "The locker was empty at breakfast. Could you bring a cooked meal?"))
			else: dialog("Chief Vale","CHIEF ENGINEER · SECURE CREW LINK","Cloak stable. Engines... less so. Three copper from inside the southeast cave would fix our crew link. There are six rations in the twelve-slot supply locker beside the bunks. I'll eat one each day. When they run out, leave me a cooked meal there every day. Fish sticks or stew would be a welcome change from ration packets, Captain.",[
				["Hand over three copper." if state.copper>=3 else "I'll look inside the southeast cave.",func():
					if state.copper>=3:
						state.copper-=3
						state.delivered=true
						save_visit()
						burst(state.player_position,"a3d4d0")
						toast("Crew link restored. One small connection home.",6.0)],
				["How long do we have?",func(): dialog("Chief Vale","CHIEF ENGINEER","As long as the cloak holds, we have room to breathe. No signals. No active scans. I'll keep the lights off. You keep us fed.")]])

func buy_cookware(id: String) -> void:
	toast("%s purchased. Recipe unlocked at your farmhouse stove." % ui.Items.CATALOG[id].name if state.buy_utensil(id) else "Already purchased, or you need 20 crowns.")
	save_visit()
	talk("tavi")

func mayor() -> void:
	var first_visit=current_room=="home" and state.welcome_phase in ["waiting","meeting"]
	if not first_visit and state.welcome_phase!="complete":
		dialog("Mayor Alder","THE OLD FARMHOUSE","Let's talk inside the farmhouse, where everyone can join us.")
		return
	if not first_visit and not state.mayor_available(): return
	if first_visit:
		state.welcome_phase="meeting"
		resting=0
		activity=""
		place_welcome_party()
	begin_conversation(["mayor","assistant","moss"],true)
	dialog("Mayor Alder","BRIAR GLEN · AT YOUR FARM","Moss tells me you're travelers looking for somewhere to stay. The farmhouse has stood empty for a while. You're welcome to stay if you promise to keep it clean.",[
		["We can promise that.",func(): dialog("Neral","MAYOR'S ASSISTANT · DARK ELF","I'll record that the old farmhouse is occupied again. I'm Neral, the mayor's assistant. Let us know if anything needs attention.",[
			["Thank you, Neral.",func(): dialog("Mayor Alder","BRIAR GLEN","You might work the garden to earn your keep and provide for yourselves. There are seeds and tools in the chest outside, and Tavi buys produce in the square. A little care will make this a home again.",[
				["We'll keep the house clean and make a start in the garden.",func():
					state.met_mayor=true
					end_conversation()
					if first_visit:
						state.welcome_phase="departing"
						departure_paths.clear()
					save_visit()
					toast("A home in Briar Glen. The rest can wait.",7.0)
					burst(state.player_position,"e7cf8e",30)]])]])]])

func place_welcome_party() -> void:
	if current_room!="home": return
	state.player_position=Grid.center(Vector2i(6,12))
	for i in range(WELCOME_MEMBERS.size()):
		var id=WELCOME_MEMBERS[i]
		var actor=world.villagers[id]
		outdoors.villagers[id].data.room="home"
		outdoors.villagers[id].data.sleeping=false
		actor.visible=true
		actor.data.sleeping=false
		actor.position=Grid.center([Vector2i(7,11),Vector2i(5,11),Vector2i(9,11)][i])
		actor.queue_redraw()

func update_welcome_departure(dt: float) -> void:
	var remaining=0
	for id in ["mayor","assistant"]:
		var actor=world.villagers[id]
		if not actor.visible: continue
		if not departure_paths.has(id): departure_paths[id]=world._route(Grid.world_to_cell(actor.position),world.layout.exit)
		var path: Array=departure_paths[id]
		var distance=dt*65
		while distance>0 and not path.is_empty():
			var step=actor.position.distance_to(path[0])
			actor.position=actor.position.move_toward(path[0],distance)
			distance-=step
			if actor.position.distance_to(path[0])<0.1: path.pop_front()
		actor.data.walking=true
		actor.queue_redraw()
		if path.is_empty():
			actor.visible=false
			outdoors.villagers[id].data.room=""
			outdoors.villagers[id].position=outdoors.site_position("bed")+Vector2(WELCOME_MEMBERS.find(id)*24,32)
			outdoors.routes.erase(id)
		else: remaining+=1
	if remaining==0:
		moss_lesson()

func moss_lesson() -> void:
	state.welcome_phase="moss_lesson"
	begin_conversation(["moss"],true)
	dialog("Moss","A LITTLE HELP GETTING STARTED","Before I go: the chest outside holds your seeds, hoe, watering can and sickle. Carry a tool, assign it to a quick slot and select it. Hoe the earth, plant, then water. Fill the empty can at the pond's edge. Crops take three days. Farm work costs energy; food and your own bed restore it.",[
		["And the spell you mentioned?",func(): dialog("Moss","THE WIZARD IN THE NORTHERN CLIFFS","Visit Iona by her tower, north of town. She'll teach you local magic to help the plants grow. Magic here belongs to our region's gods and goddesses, so travelers often need a lesson even if they know spells from another city. Iona rises around noon and stays up almost until sunrise.",[
			["Thanks, Moss. We'll visit her.",func():
				state.welcome_phase="complete"
				end_conversation()
				outdoors.villagers.moss.data.room=""
				outdoors.villagers.moss.position=outdoors.site_position("bed")+Vector2(24,32)
				outdoors.routes.erase("moss")
				world.villagers.moss.visible=false
				save_visit()]])]])

func radio() -> void:
	dialog("Briar Glen Radio","LOCAL SERVICE · 1040","...a fair morning across the valley. The north road is open to travelers, with delays at the border crossing. Tonight: the Radio Club's spring music hour. And if anyone has borrowed Mrs. Bell's ladder, she would like it back.")

func inventory() -> void:
	if state.welcome_phase in ["escorting","meeting","departing","moss_lesson"] or ("moss" in conversation_members and not state.invited): return
	window_open=true
	ui.open_inventory()

func inventory_stacks() -> Array:
	var stacks: Array=[]
	for id in ui.Items.CATALOG:
		var count=int(state.get(id))
		if count>0: stacks.append({"id":id,"count":count})
	return stacks

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
	panel("Around Briar Glen","LOCAL DIRECTIONS","↖ Hidden ship & Chief Vale\n↑ Radio Club & Finch\n← Your farm & Moss\n→ Town square, homes & Tavi's cart\n%s\n↙ Pond & fishing jetty\n↘ Copper cave · bring a pickaxe\n\nTavi keeps the cart 08:00–20:00, with lunch at 12:30.\nFollow the sandy lanes; neighbors have places to be." % wizard)

func settings() -> void:
	if not started: return
	var selected = state.pause_mode
	var choices = [
		[("✓ " if selected=="none" else "")+"Time continues · default",func(): state.pause_mode="none"; settings()],
		[("✓ " if selected=="clock" else "")+"Stop calendar · simulation continues",func(): state.pause_mode="clock"; settings()],
		[("✓ " if selected=="all" else "")+"Pause entire world",func(): state.pause_mode="all"; settings()],
		["Sound · music, ambience, and spells",sound_settings],
		["Artwork · choose a sprite pack",art_settings],
		["Save this visit",func(): if save_visit(): toast("Visit saved inside this project.")],
		["Begin a new visit…",reset_confirmation],
		["Return to the farm",func(): pass],
		["Save and quit",quit_game]]
	if OS.is_debug_build(): choices.insert(4,["Development tools · advance time",development_tools])
	panel("Make yourself comfortable","FIELD SETTINGS","While a conversation or menu is open:",choices)
	if OS.is_debug_build(): ui.modal.get_child(1).position.y=75

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
	toast("Artwork option %d selected." % value)

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
			outdoors.state=state
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
