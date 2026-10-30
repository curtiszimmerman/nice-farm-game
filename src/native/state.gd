extends RefCounted

const Grid = preload("res://grid.gd")
const Items = preload("res://items.gd")

# Four weeks in every season.
const DEVELOPMENT_SEASON_DAYS = 28

func season_name() -> String:
	return ["spring","summer","autumn","winter"][int((day-1)/float(DEVELOPMENT_SEASON_DAYS))%4]

func season_day() -> int:
	return (day-1)%DEVELOPMENT_SEASON_DAYS+1

func calendar_year() -> int:
	return int((day-1)/float(DEVELOPMENT_SEASON_DAYS*4))+1

var day = 1
var minute = 540.0
var money = 24
var seeds = 0
var turnips = 0
var fish = 0
var moon_pike=0
var sea_sprat=0
var blue_mackerel=0
var storm_eel=0
var rain_glassfish=0
var storm_shiner=0
var copper = 0
var copper_bars=0
var bread=0
var berries=0
var apples=0
var ladder=0
var ladder_requested=false
var ladder_taken=false
var ladder_returned=false
var ladder_clue=false
var ladder_located=false
const Shop=preload("res://shop_stock.gd")
var shop_season=-1
var shop_remaining: Dictionary={}
var met_people: Array=["vale"]
var friendships: Dictionary={}
var chat_days: Dictionary={}
var gift_weeks: Dictionary={}
var star_origin_reply=""
var requests=preload("res://town_requests.gd").new()
var learned_spells: Array=[]
var bloom_harvests: Dictionary={}
var bloom_cells: Array=[]
var cave_level=0
var quick_row=0
var fishing_pole=0
var coal=0
var silver_bars=0
var beehive_known=false
var forage_harvests: Dictionary={}
var star_seeds = 0
var star_bulbs = 0
var rusty_sword = 0
var hoe = 0
var watering_can = 0
var sickle = 0
var chest: Array=[]
var cabinet: Array=[]
var ship_storage: Array=[]
var quick_slots: Array=["","","","","","","",""]
var selected_slot=0
var inventory_selection=""
var inventory_order: Array=[]
var auxiliary_selection=""
var action_channel="primary"
const Skills=preload("res://skills.gd")
var world_seed=0
var lantern_ray=0
var axe=0
var wood=0
var firewood_requested=false
var firewood_given=false
var woodcutter_axe_given=false
var cave_pickaxe_taken=false
var cave_intro_seen=false
var felled_trees: Array=[]
var water=0
var pot=0
var pan=0
var fish_sticks=0
var fish_stew=0
var health_elixir=0
var rations=0
var crew_fed_day=1
var crew_food_delivered=false
var crew_hungry_days=0
var purchased_utensils: Array=[]
var light_bulbs=0
var intro_complete=false
var briefing_complete=false
var ship_departed=false
var welcome_phase="unvisited"
var welcome_elapsed=0.0
var magic_learned=false
var cave_seed=0
var cave_broken: Array=[]
var cave_defeated: Array=[]
var cave_chrysalis_taken=false
var sparkfire_picked_day=0
var cave_barrel: Array=[{},{},{},{}]
var pickaxe=0
var stones=0
var cave_moth_chrysalis=0
var golden_sparkfire_bloom=0
var winter_sparkbloom=0
var berry_preserves=0
var berry_cobbler=0
var flour=0
var sugar=0
var butter=0
var mayor_due=-1.0
var house_tasks={"sofa":false,"bed":false,"guest_bed":false,"radio":false,"living_light":false,"bathroom_light":false}
const INVENTORY_SLOTS=16
const EXTRA_ITEMS=["pot","pan","fish_sticks","fish_stew","health_elixir","rations","light_bulbs","moon_pike","sea_sprat","blue_mackerel","storm_eel","rain_glassfish","storm_shiner","pickaxe","stones","cave_moth_chrysalis","golden_sparkfire_bloom","lantern_ray","axe","wood","bread","copper_bars","berries","apples","ladder","fishing_pole","coal","silver_bars","winter_sparkbloom","berry_preserves","berry_cobbler","flour","sugar","butter"]
const CROP_MINUTES=4320.0
const RECIPES={"fish_sticks":{"utensil":"pan","ingredients":{"fish":1}},"fish_stew":{"utensil":"pot","ingredients":{"turnips":1,"star_bulbs":1,"fish":1}},"berry_preserves":{"utensil":"pot","ingredients":{"berries":2,"sugar":1}},"berry_cobbler":{"utensil":"pan","ingredients":{"berry_preserves":1,"flour":1,"sugar":1,"butter":1}}}
var invitation_day=1
var abandoned_day: Dictionary={}
var equipped = ""
var health = 100.0
var selected_seed = "seeds"
var location = "ship"
var outdoor_position = Grid.center(Grid.SPAWN_CELL)
var harvested = 0
var mana = 60.0
var energy = 100.0
var experience=0
var quest_order: Array=[]
var weather_override=""
var awake_minutes=0.0
var sleep_minutes=0.0
var status_effects: Dictionary={}
var needs=preload("res://journey_needs.gd").new()
var damage_events: Array=[]
const CRUCIBLE_STONE=10
const ORE_PER_BAR=5
const COAL_PER_BAR=2
const SMELT_MINUTES=30.0
var crucible_known=false
var crucibles: Array=[]
var invited = false
var met_mayor = false
var delivered = false
var pause_mode = "all"
var player_position = Grid.center(Vector2i(7,12))
var plots: Array = []

func _init() -> void:
	inventory_order.resize(INVENTORY_SLOTS)
	inventory_order.fill("")
	cave_seed=randi_range(1,2147483646)
	world_seed=randi_range(1,2147483646)
	chest=[{"id":"hoe","count":1},{"id":"watering_can","count":1},{"id":"sickle","count":1}]
	chest.append({"id":"seeds","count":20})
	while chest.size()<18: chest.append({})
	for i in range(12):
		cabinet.append({})
		ship_storage.append({"id":"rations","count":6} if i==0 else {})
	cabinet[0]={"id":"light_bulbs","count":2}

func total() -> float:
	return (day - 1) * 1440.0 + minute

func weather_name(on_day: int=0) -> String:
	return weather_override if weather_override!="" else preload("res://weather.gd").for_day(world_seed,day if on_day==0 else on_day)

func winter_bloom_day() -> bool:
	return weather_name()=="rainy" and preload("res://weather.gd").thundersnow(world_seed,day)

func accept_firewood_task() -> bool:
	if firewood_given: return false
	firewood_requested=true
	return true

func accept_tool(id: String) -> bool:
	sync_inventory()
	if id not in ["axe","pickaxe"]: return false
	var flag="woodcutter_axe_given" if id=="axe" else "cave_pickaxe_taken"
	if get(flag) or not can_carry(id): return false
	set(id,int(get(id))+1)
	set(flag,true)
	if id=="axe": requests.axe_due=total()+10080.0
	return true

func repay_axe() -> bool:
	requests.update_deadline(self)
	if not woodcutter_axe_given or requests.axe_paid or wood<10: return false
	wood-=10
	requests.axe_paid=true
	clear_empty_slots()
	return true

func deliver_firewood() -> bool:
	if not firewood_requested or firewood_given or wood<6 or (not can_carry("fishing_pole") and wood!=6): return false
	wood-=6
	money+=25
	fishing_pole+=1
	change_friendship("keeper",25)
	firewood_given=true
	clear_empty_slots()
	return true

func tired_days() -> int: return int(floor(awake_minutes/1440.0))
func is_tired() -> bool: return tired_days()>0

func energy_cost(base: float) -> float: return base*(tired_days()+1)

func spend_energy(base: float) -> bool:
	var cost=energy_cost(base)
	if energy<cost: return false
	energy-=cost
	return true

func energy_recovery(base: float) -> float: return base/(tired_days()+1)

func restore_energy(base: float) -> void:
	if needs.deprived(): return
	energy=minf(100,energy+energy_recovery(base))

func restore_mana(base: float) -> void:
	if not needs.deprived(): mana=minf(60,mana+base)

func active_statuses() -> Array:
	return (["tired"] if is_tired() else [])+(["thirsty"] if needs.thirsty() else [])+(["starving"] if needs.starving() else [])+status_effects.keys()

func learn_spell(id: String) -> bool:
	if id in learned_spells: return false
	if id=="hearthmend":
		if golden_sparkfire_bloom<1: return false
		golden_sparkfire_bloom-=1
	elif id=="emberthread":
		if cave_moth_chrysalis<1 or wood<10: return false
		cave_moth_chrysalis-=1
		wood-=10
	else: return false
	learned_spells.append(id)
	change_friendship("iona",15)
	clear_empty_slots()
	return true

func cast_healing() -> bool:
	if "hearthmend" not in learned_spells or mana<10 or health>=100: return false
	mana-=10
	health=minf(100,health+15*magic_strength("light"))
	return true

func magic_strength(school: String) -> float:
	return preload("res://weekday_magic.gd").strength(day,world_seed,school)

func apply_poison() -> void:
	if status_effects.has("poison"): status_effects.poison.remaining=60.0
	else: status_effects.poison={"remaining":60.0,"tick":5.0}

func advance_statuses(minutes: float,sleeping: bool) -> void:
	if sleeping:
		var remaining=minutes
		while remaining>0.000001:
			if sleep_minutes>=preload("res://statuses.gd").REST_MINUTES:
				awake_minutes=0
				restore_energy(remaining*0.2)
				sleep_minutes+=remaining
				break
			var span=minf(remaining,minf(360-sleep_minutes,1440-fmod(awake_minutes,1440)))
			restore_energy(span*0.2)
			awake_minutes+=span
			sleep_minutes+=span
			remaining-=span
			if sleep_minutes>=360: awake_minutes=0
	else:
		awake_minutes+=minutes
		sleep_minutes=0
	if status_effects.has("poison"):
		var poison=status_effects.poison
		var elapsed=minf(minutes,poison.remaining)
		poison.remaining-=elapsed
		poison.tick-=elapsed
		while poison.tick<=0.000001:
			var damage=minf(2,health)
			health=maxf(0,health-damage)
			if damage>0: damage_events.append(damage)
			poison.tick+=5
		if poison.remaining<=0.000001: status_effects.erase("poison")

func buy_bread() -> bool:
	return purchase("bread")

func learn_crucible() -> bool:
	if crucible_known or star_bulbs<10: return false
	star_bulbs-=10
	crucible_known=true
	clear_empty_slots()
	return true

func build_crucible(cell: Vector2i) -> bool:
	if not crucible_known or stones<CRUCIBLE_STONE or not Grid.near_farmhouse(cell) or not Grid.farmable(cell): return false
	if crucibles.any(func(station):return Vector2i(station.x,station.y)==cell): return false
	stones-=CRUCIBLE_STONE
	crucibles.append({"x":cell.x,"y":cell.y,"ready_at":-1.0,"bars":0})
	clear_empty_slots()
	return true

func start_smelting(index: int) -> bool:
	if index<0 or index>=crucibles.size() or copper<ORE_PER_BAR or coal<COAL_PER_BAR: return false
	var station=crucibles[index]
	if station.ready_at>=0 or station.bars>0: return false
	copper-=ORE_PER_BAR
	coal-=COAL_PER_BAR
	station.ready_at=total()+SMELT_MINUTES
	clear_empty_slots()
	return true

func update_crucibles() -> void:
	for station in crucibles:
		if station.ready_at>=0 and total()+0.000001>=station.ready_at:
			station.ready_at=-1.0
			station.bars=1

func collect_copper_bar(index: int) -> bool:
	if index<0 or index>=crucibles.size() or crucibles[index].bars<1 or not can_carry("copper_bars"): return false
	sync_inventory()
	crucibles[index].bars-=1
	copper_bars+=1
	return true

func advance(minutes: float, window_open = false,sleeping: bool=false) -> void:
	if window_open and pause_mode == "all":
		return
	if window_open and pause_mode == "clock":
		restore_mana(minutes*0.12)
		return
	var recoverable=needs.advance(minutes,self)
	mana=minf(60,mana+recoverable*0.12)
	advance_statuses(minutes,sleeping)
	var elapsed = total() + minutes
	var previous_day=day
	day = int(elapsed / 1440.0) + 1
	minute = fmod(elapsed, 1440.0)
	requests.update_deadline(self)
	update_crucibles()
	for crop_day in range(previous_day,day):
		stock("bread")
		for id in Shop.CATALOG:
			if Shop.daily(id): shop_remaining[id]=Shop.CATALOG[id].stock
		for index in range(plots.size()-1,-1,-1):
			var plot=plots[index]
			var rain=weather_name(crop_day)=="rainy"
			if posmod(crop_day,DEVELOPMENT_SEASON_DAYS)==0 and plot.planted>=0:
				plot.planted=-1.0
				plot.growth=-1.0
				plot.watered=false
			elif plot.planted>=0 and plot.growth>=0:
				if rain or (plot.watered and plot.water_day==crop_day):
					plot.growth=minf(CROP_MINUTES,plot.growth+1440)
					plot.water_day=crop_day if rain else plot.water_day
				elif crop_day-int(plot.water_day)>=2:
					plot.planted=-1.0
					plot.growth=-1.0
				plot.watered=false
			if plot.planted<0 and (plot.growth<0 or plot.tilled):
				var decay=RandomNumberGenerator.new()
				decay.seed=hash("plot-decay:%d:%d:%d" % [world_seed,plot.x*10000+plot.y,crop_day])
				if decay.randf()<0.15:
					plots.remove_at(index)
					continue
			plot.watered=false
	if weather_name()=="rainy":
		for plot in plots:
			if plot.planted>=0:
				plot.watered=true
				plot.water_day=day
	for meal_day in range(previous_day+1,day+1):
		if take_crew_meal(): crew_fed_day=meal_day
		else: crew_hungry_days+=1

func take_crew_meal() -> bool:
	for food in Items.PREPARED_FOOD:
		for stack in ship_storage:
			if stack.get("id","")!=food or stack.get("count",0)<1: continue
			stack.count-=1
			if stack.count==0: stack.clear()
			return true
	return false

func ripe(index: int) -> bool:
	return index >= 0 and index < plots.size() and plots[index].planted >= 0.0 and plots[index].growth >= CROP_MINUTES

func plot_moisture(index: int) -> float:
	var plot=plots[index]
	if not plot.watered or plot.water_day!=day: return 0.0
	return 1.0-clampf((minute-1140.0)/300.0,0.0,1.0)

func clear_empty_slots() -> void:
	if inventory_selection!="" and not available_action(inventory_selection): inventory_selection=""
	if auxiliary_selection!="" and not available_action(auxiliary_selection): auxiliary_selection=""
	for i in range(quick_slots.size()):
		if quick_slots[i]!="" and not available_action(quick_slots[i]): quick_slots[i]=""
	sync_inventory()
	for i in range(8): quick_slots[i]=inventory_order[quick_row*8+i]

func active_item(channel: String="") -> String:
	clear_empty_slots()
	if (channel if channel!="" else action_channel)=="aux": return auxiliary_selection
	return inventory_selection if selected_slot==8 else quick_slots[selected_slot]

func available_action(id: String) -> bool:
	return Skills.known(self,id) if Skills.CATALOG.has(id) else Items.CATALOG.has(id) and int(get(id))>0

func assign_active(channel: String,id: String) -> bool:
	if channel not in ["primary","aux"] or (id!="" and not available_action(id)): return false
	if channel=="aux": auxiliary_selection=id
	else:
		inventory_selection=id
		selected_slot=8
	return true

func select_inventory(id: String) -> bool:
	if not available_action(id): return false
	inventory_selection=id
	selected_slot=8
	return true

func assign_slot(index: int,id: String) -> bool:
	if index<0 or index>=8 or (id!="" and not available_action(id)): return false
	sync_inventory()
	var target=quick_row*8+index
	if id=="": inventory_order[target]=""
	elif not move_inventory(id,target):
		if not place_shortcut(id,target): return false
	clear_empty_slots()
	return true

func cycle_inventory_row() -> void:
	quick_row=1-quick_row
	clear_empty_slots()

func place_shortcut(id: String,index: int) -> bool:
	if not Skills.known(self,id) or index<0 or index>=INVENTORY_SLOTS: return false
	sync_inventory()
	if id in inventory_order: return move_inventory(id,index)
	if inventory_order[index]!="":
		var empty=inventory_order.find("")
		if empty<0: return false
		inventory_order[empty]=inventory_order[index]
	inventory_order[index]=id
	return true

func plot_cell(index: int) -> Vector2i:
	var plot=plots[index]
	return Vector2i(int(plot.x),int(plot.y))

func prepare_plot(cell: Vector2i) -> bool:
	if active_item()!="hoe" or hoe<1 or not Grid.farmable(cell): return false
	for index in range(plots.size()):
		if plot_cell(index)==cell: return false
	if not spend_energy(1.2): return false
	plots.append({"x":cell.x,"y":cell.y,"tilled":true,"planted":-1.0,"watered":false,"crop":"turnips","growth":0.0,"water_day":0})
	return true

func farm(index: int) -> String:
	if index<0 or index>=plots.size(): return "No soil here."
	var p=plots[index]
	if active_item()=="watering_can": return water_plot(index)
	if p.planted>=0 and p.watered and not ripe(index): return "Growing. Water each day; three watered midnights to mature."+(" Select Wildgrowth to hasten it." if magic_learned else "")
	var needed="sickle" if ripe(index) else "hoe" if not p.tilled else "watering_can" if p.planted>=0 and not p.watered else selected_seed
	if p.tilled and p.planted<0 and active_item() in ["seeds","star_seeds"]: selected_seed=active_item(); needed=selected_seed
	if active_item()!=needed: return "Select %s in a quick slot first." % Items.CATALOG[needed].name
	return tend(index)

func water_plot(index: int) -> String:
	if index<0 or index>=plots.size(): return "No soil here."
	if watering_can<1: return "Carry your watering can from the farmhouse chest."
	if water<1: return "Empty watering can. Refill it at the pond."
	var cost=energy_cost(0.8)
	if energy<cost: return "Too tired. Sleep in your own bed or eat something restorative."
	energy-=cost
	water-=1
	plots[index].watered=true
	plots[index].water_day=day
	return "Watered for today."

func refill_water() -> bool:
	if active_item()!="watering_can" or watering_can<1: return false
	if not spend_energy(0.2): return false
	water=20
	return true

func tend(index: int) -> String:
	if index < 0 or index >= plots.size():
		return "There is no garden patch here."
	var p = plots[index]
	var tool="sickle" if ripe(index) else "hoe" if not p.tilled else "watering_can" if p.planted>=0 and not p.watered else ""
	var cost=energy_cost(0.8 if tool in ["sickle","watering_can"] else 1.2 if tool=="hoe" else 0.3)
	if tool!="" and int(get(tool))==0: return "Carry your %s from the farmhouse chest." % Items.CATALOG[tool].name.to_lower()
	if tool=="watering_can" and water<1: return "Empty watering can. Refill it at the pond."
	if energy<cost: return "Too tired. Sleep in your own bed or eat something restorative."
	if ripe(index):
		if not can_carry(p.crop): return "Your satchel is full. Make room before harvesting."
		energy-=cost
		p.planted = -1.0
		p.growth=0.0
		p.watered = false
		set(p.crop,int(get(p.crop))+1)
		harvested += 1
		if harvested==1: change_friendship("moss",20)
		return "+1 %s. A small, very real victory." % Items.CATALOG[p.crop].name.to_lower()
	if not p.tilled:
		energy-=cost
		p.tilled = true
		return "Good earth. Press E again to plant."
	if p.planted < 0.0:
		if int(get(selected_seed)) == 0:
			return "Out of seeds. Tavi sells more at the town market."
		energy-=cost
		set(selected_seed,int(get(selected_seed))-1)
		clear_empty_slots()
		p.crop="star_bulbs" if selected_seed=="star_seeds" else "turnips"
		p.planted = total()
		p.growth=0.0
		return "%s planted. A little water next." % Items.CATALOG[p.crop].name
	if not p.watered:
		return water_plot(index)
	return "Growing happily."

func grow(index: int) -> bool:
	if not magic_learned: return false
	if index < 0 or index >= plots.size():
		return false
	var p = plots[index]
	if mana < 15.0 or p.planted < 0.0 or p.growth<0 or not p.watered or ripe(index):
		return false
	mana -= 15.0
	p.growth=CROP_MINUTES
	return true

func sell() -> bool:
	var earned=sale_value()
	if earned==0: return false
	money+=earned
	turnips = 0
	for id in Items.FISH: set(id,0)
	star_bulbs=0
	clear_empty_slots()
	return true

func sale_value() -> int:
	var earned=turnips*8+star_bulbs*12
	for id in Items.FISH: earned+=int(get(id))*Items.FISH[id].price
	return earned

func buy_seeds() -> bool:
	return purchase("seeds")

func mine(resource: String="copper") -> bool:
	if resource not in ["copper","stones","coal"] or active_item()!="pickaxe" or pickaxe<1 or not can_carry(resource):
		return false
	var drops=["copper","stones"] if resource=="copper" else [resource]
	var slots=occupied_inventory_slots()
	for id in drops:
		if int(get(id))==0: slots+=1
	if slots>INVENTORY_SLOTS: return false
	if not spend_energy(4): return false
	for id in drops: set(id,int(get(id))+1)
	return true

func consume(id: String) -> bool:
	if not Items.FOOD.has(id) or int(get(id))<=0: return false
	var food=Items.FOOD[id]
	var restores_need=needs.hardcore and (needs.without_water>0 if id=="health_elixir" else id in Items.PREPARED_FOOD and needs.without_food>0)
	if not restores_need and (health>=100 or food.health==0) and (energy>=100 or food.energy==0) and (mana>=60 or food.mana==0): return false
	set(id,int(get(id))-1)
	if id=="health_elixir": needs.drink()
	elif id in Items.PREPARED_FOOD: needs.eat()
	clear_empty_slots()
	health=minf(100,health+food.health)
	restore_energy(food.energy)
	restore_mana(food.mana)
	return true

func accept_sword() -> bool:
	if has_sword() or turnips<3 or (not can_carry("rusty_sword") and turnips!=3): return false
	turnips-=3
	requests.bram_traded=true
	rusty_sword=1
	clear_empty_slots()
	return true

func buy_sword() -> bool:
	if has_sword() or not purchase("rusty_sword"): return false
	return true

func has_sword() -> bool:
	return rusty_sword>0 or chest.any(func(stack): return stack.get("id","")=="rusty_sword")

func chest_transfer(index: int,carried_id: String="",quantity: int=-1) -> bool:
	return storage_transfer("chest",index,carried_id,quantity)

func storage_transfer(storage_name: String,index: int,carried_id: String="",quantity: int=-1) -> bool:
	sync_inventory()
	if storage_name not in ["chest","cabinet","ship_storage","cave_barrel"]: return false
	var storage: Array=get(storage_name)
	if index<0 or index>=storage.size() or (carried_id!="" and (not Items.CATALOG.has(carried_id) or int(get(carried_id))<=0)): return false
	var stored: Dictionary=storage[index]
	var available=int(stored.get("count",0)) if carried_id=="" else int(get(carried_id))
	var amount=available if quantity==-1 else quantity
	if amount<1 or amount>available: return false
	var incoming=stored.get("id","")
	var slots=occupied_inventory_slots()
	if incoming!="" and int(get(incoming))==0: slots+=1
	if carried_id!="" and amount==available: slots-=1
	if slots>INVENTORY_SLOTS: return false
	if carried_id=="":
		if stored.is_empty(): return false
		set(stored.id,int(get(stored.id))+amount)
		stored.count-=amount
		if stored.count==0: storage[index]={}
	else:
		if not stored.is_empty() and stored.id!=carried_id and amount!=available: return false
		set(carried_id,available-amount)
		if not stored.is_empty() and stored.id==carried_id: amount+=int(stored.count)
		elif not stored.is_empty(): set(stored.id,int(get(stored.id))+int(stored.count))
		storage[index]={"id":carried_id,"count":amount}
		if storage_name=="ship_storage" and carried_id in Items.PREPARED_FOOD: crew_food_delivered=true
	if equipped!="" and int(get(equipped))==0: equipped=""
	clear_empty_slots()
	if storage_name=="ship_storage" and crew_fed_day<day and take_crew_meal():
		crew_fed_day=day
		crew_hungry_days=maxi(0,crew_hungry_days-1)
	return true

func carried_slots() -> int:
	var count=0
	for id in Items.CATALOG:
		if int(get(id))>0: count+=1
	return count

func occupied_inventory_slots() -> int:
	return carried_slots()+inventory_order.filter(func(id):return Skills.CATALOG.has(id)).size()

func sync_inventory() -> void:
	for i in range(inventory_order.size()):
		if inventory_order[i]!="" and not available_action(inventory_order[i]): inventory_order[i]=""
	for id in Items.CATALOG:
		if int(get(id))<=0 or id in inventory_order: continue
		var slot=inventory_order.find("")
		if slot>=0: inventory_order[slot]=id

func inventory_cells() -> Array:
	sync_inventory()
	var cells=[]
	for id in inventory_order: cells.append({} if id=="" else {"id":id,"count":0 if Skills.CATALOG.has(id) else int(get(id))})
	return cells

func move_inventory(id: String,index: int) -> bool:
	sync_inventory()
	var previous=inventory_order.find(id)
	if id=="" or previous<0 or index<0 or index>=INVENTORY_SLOTS: return false
	inventory_order[previous]=inventory_order[index]
	inventory_order[index]=id
	return true

func can_carry(id: String) -> bool:
	return Items.CATALOG.has(id) and (int(get(id))>0 or occupied_inventory_slots()<INVENTORY_SLOTS)

func tidy_house(task: String) -> bool:
	if not house_tasks.has(task) or house_tasks[task]: return false
	if task.ends_with("light"):
		if light_bulbs<1: return false
		light_bulbs-=1
	house_tasks[task]=true
	clear_empty_slots()
	return true

func buy_utensil(id: String) -> bool:
	return id in ["pot","pan"] and purchase(id)

func stock(id: String) -> int:
	var season=int((day-1)/28.0)
	if shop_season!=season:
		shop_season=season
		shop_remaining=Shop.amounts()
	return int(shop_remaining.get(id,0))

func purchase_drink(id: String) -> bool:
	if not Shop.DRINKS.has(id) or stock(id)<=0 or money<Shop.CATALOG[id].price: return false
	money-=Shop.CATALOG[id].price
	shop_remaining[id]-=1
	needs.drink()
	restore_energy(Shop.DRINKS[id].energy)
	return true

func purchase(id: String) -> bool:
	if Shop.DRINKS.has(id): return purchase_drink(id)
	if not Shop.CATALOG.has(id) or stock(id)<=0: return false
	var offer=Shop.CATALOG[id]
	if money<offer.price or not can_carry(id): return false
	sync_inventory()
	money-=offer.price
	set(id,int(get(id))+offer.count)
	shop_remaining[id]-=1
	return true

func meet_person(id: String) -> void:
	if id not in met_people: met_people.append(id)

func chat_with(id: String) -> void:
	meet_person(id)
	if int(chat_days.get(id,0))==day: return
	chat_days[id]=day
	change_friendship(id,1)

func gift_preference(id: String,item: String) -> int:
	if id=="veteran" and item=="turnips": return 5
	if item in ["coal","stones"]: return 1 if id in ["smith","miller"] else -1
	if item in ["cave_moth_chrysalis","golden_sparkfire_bloom","star_bulbs"]: return 5 if id in ["iona","astronomer"] else -5 if id=="assistant" else 0
	if item in ["fish_stew","fish_sticks","bread","berry_cobbler"]: return 5 if id in ["vale","keeper","veteran","barkeep"] else 1
	if item in ["berries","apples","turnips"]: return 5 if id in ["moss","farmer_mother","baker"] else 1
	return 0

func give_gift(id: String,item: String) -> bool:
	if item in Items.ESSENTIAL_TOOLS: return false
	if not preload("res://villager_schedule.gd").ROUTINES.has(id) or not Items.CATALOG.has(item) or int(get(item))<1: return false
	var week=int((day-1)/7)
	if int(gift_weeks.get(id,-1))==week: return false
	set(item,int(get(item))-1)
	gift_weeks[id]=week
	change_friendship(id,gift_preference(id,item))
	clear_empty_slots()
	return true

func record_star_origin(truth: bool) -> void:
	if star_origin_reply=="": change_friendship("astronomer",5 if truth else -5)
	star_origin_reply="truth" if truth else "lie"

func change_friendship(id: String,amount: int) -> void:
	meet_person(id)
	friendships[id]=clampi(int(friendships.get(id,0))+amount,-100,100)

func relationship(id: String) -> String:
	var score=int(friendships.get(id,0))
	return "Hated" if score<=-60 else "Disliked" if score<=-20 else "Loved" if score>=60 else "Liked" if score>=20 else "Neutral"

func ingredient_count(id: String) -> int:
	var count=0
	for candidate in ingredient_ids(id):
		count+=int(get(candidate))
		for stack in cabinet:
			if stack.get("id","")==candidate: count+=stack.count
	return count

func ingredient_ids(id: String) -> Array:
	return Items.FISH.keys() if id=="fish" else [id]

func cook(id: String) -> bool:
	if not RECIPES.has(id): return false
	var recipe=RECIPES[id]
	if ingredient_count(recipe.utensil)<1: return false
	for ingredient in recipe.ingredients:
		if ingredient_count(ingredient)<recipe.ingredients[ingredient]: return false
	var slots=carried_slots()+(1 if int(get(id))==0 else 0)
	var used={}
	for ingredient in recipe.ingredients:
		var remaining=int(recipe.ingredients[ingredient])
		for candidate in ingredient_ids(ingredient):
			var amount=mini(remaining,int(get(candidate)))
			used[candidate]=amount
			remaining-=amount
			if amount>0 and amount==int(get(candidate)): slots-=1
	if slots>INVENTORY_SLOTS: return false
	for ingredient in recipe.ingredients:
		var remaining=int(recipe.ingredients[ingredient])
		for candidate in ingredient_ids(ingredient):
			var carried=int(used.get(candidate,0))
			set(candidate,int(get(candidate))-carried)
			remaining-=carried
		for stack in cabinet:
			if remaining==0: break
			if stack.get("id","") not in ingredient_ids(ingredient): continue
			var take=mini(remaining,int(stack.count))
			stack.count-=take
			remaining-=take
			if stack.count==0: stack.clear()
	set(id,int(get(id))+1)
	clear_empty_slots()
	return true

func invite_mayor() -> void:
	invited=true
	invitation_day=day
	mayor_due=total()+120.0

func mayor_visit_start() -> float:
	if mayor_due<0: return -1.0
	return mayor_due+floor(maxf(0,total()-mayor_due)/1440.0)*1440.0

func mayor_available() -> bool:
	var start=mayor_visit_start()
	return invited and not met_mayor and start>=0 and total()>=start and total()<start+240 and abandoned_day.get("mayor",0)!=day

func buy_star_seeds() -> bool:
	return purchase("star_seeds")

func meet_mayor() -> bool:
	if not mayor_available():
		return false
	met_mayor = true
	change_friendship("mayor",10)
	return true

func to_dict() -> Dictionary:
	clear_empty_slots()
	var supplies={}
	for id in EXTRA_ITEMS: supplies[id]=get(id)
	return {"version":19,"requests":requests.to_dict(),"needs":needs.to_dict(),"crew_food_delivered":crew_food_delivered,"town":preload("res://town_progress.gd").snapshot(self),"inventory_order":inventory_order.duplicate(),"woodcutter_axe_given":woodcutter_axe_given,"cave_pickaxe_taken":cave_pickaxe_taken,"cave_intro_seen":cave_intro_seen,"auxiliary_selection":auxiliary_selection,"world_seed":world_seed,"inventory_selection":inventory_selection,"firewood_requested":firewood_requested,"firewood_given":firewood_given,"felled_trees":felled_trees.duplicate(),"day": day, "minute": minute, "money": money,"magic_learned":magic_learned,
		"forage_harvests":forage_harvests.duplicate(),"ladder_requested":ladder_requested,"ladder_taken":ladder_taken,"ladder_returned":ladder_returned,
		"awake_minutes":awake_minutes,"sleep_minutes":sleep_minutes,"status_effects":status_effects.duplicate(true),
		"crucible_known":crucible_known,"crucibles":crucibles.duplicate(true),
		"experience":experience,"quest_order":quest_order.duplicate(),"weather_override":weather_override,
		"cave_seed":cave_seed,"cave_broken":cave_broken.duplicate(),"cave_defeated":cave_defeated.duplicate(),"cave_chrysalis_taken":cave_chrysalis_taken,"sparkfire_picked_day":sparkfire_picked_day,"cave_barrel":cave_barrel.duplicate(true),
		"ship_departed":ship_departed,"welcome_phase":welcome_phase,"welcome_elapsed":welcome_elapsed,
		"intro_complete":intro_complete,"briefing_complete":briefing_complete,"mayor_due":mayor_due,"house_tasks":house_tasks.duplicate(),
		"supplies":supplies,"cabinet":cabinet.duplicate(true),"ship_storage":ship_storage.duplicate(true),"water":water,"quick_slots":quick_slots.duplicate(),"selected_slot":selected_slot,"crew_fed_day":crew_fed_day,"crew_hungry_days":crew_hungry_days,"purchased_utensils":purchased_utensils.duplicate(),
		"hoe":hoe,"watering_can":watering_can,"sickle":sickle,"chest":chest.duplicate(true),"invitation_day":invitation_day,"abandoned_day":abandoned_day.duplicate(),
		"health":health,"star_seeds":star_seeds,"star_bulbs":star_bulbs,"rusty_sword":rusty_sword,"equipped":equipped,"selected_seed":selected_seed,
		"location":location,"outdoor_x":outdoor_position.x,"outdoor_y":outdoor_position.y,
		"seeds": seeds, "turnips": turnips, "fish": fish, "copper": copper,
		"harvested": harvested, "mana": mana, "energy": energy,
		"invited": invited, "met_mayor": met_mayor, "delivered": delivered,
		"pause_mode": pause_mode, "x": player_position.x, "y": player_position.y,
		"plots": plots.duplicate(true)}

func restore(data: Variant) -> bool:
	if not data is Dictionary or data.get("version") != 19:
		return false
	if not requests.valid(data.get("requests")): return false
	if not needs.valid(data.get("needs")) or not data.get("crew_food_delivered") is bool: return false
	if not preload("res://town_progress.gd").valid(data.get("town")): return false
	for field in ["ladder_requested","ladder_taken","ladder_returned"]:
		if not data.get(field) is bool: return false
	if data.ladder_returned and (not data.ladder_taken or not data.ladder_requested): return false
	if not data.get("forage_harvests") is Dictionary: return false
	for key in data.forage_harvests:
		if not key is String: return false
		var parts=key.split(":")
		if parts.size()!=3 or parts[0] not in ["berries","apples","wood"] or not parts[1].is_valid_int() or not parts[2].is_valid_int(): return false
		if not Grid.contains(Vector2i(int(parts[1]),int(parts[2]))): return false
		if not _number(data.forage_harvests[key]) or data.forage_harvests[key]<0: return false
	for field in ["awake_minutes","sleep_minutes"]:
		if not _number(data.get(field)) or data[field]<0: return false
	if not data.get("status_effects") is Dictionary: return false
	if not data.get("crucible_known") is bool or not data.get("crucibles") is Array: return false
	if not data.crucible_known and not data.crucibles.is_empty(): return false
	var stations=[]
	for station in data.crucibles:
		if not station is Dictionary: return false
		for field in ["x","y","bars"]:
			if not _number(station.get(field)) or station[field]!=floor(station[field]): return false
		var cell=Vector2i(station.x,station.y)
		if not Grid.near_farmhouse(cell) or cell in stations: return false
		stations.append(cell)
		if station.bars not in [0,1] or not _number(station.get("ready_at")) or station.ready_at< -1: return false
		if station.ready_at<0 and station.ready_at!= -1: return false
		if station.ready_at>=0 and station.bars>0: return false
	for id in data.status_effects:
		if id!="poison" or not data.status_effects[id] is Dictionary: return false
		var effect=data.status_effects[id]
		if not _number(effect.get("remaining")) or effect.remaining<=0 or effect.remaining>60: return false
		if not _number(effect.get("tick")) or effect.tick<=0 or effect.tick>5: return false
	if not data.get("inventory_order") is Array or data.inventory_order.size()!=INVENTORY_SLOTS: return false
	var ordered=[]
	if not _number(data.get("experience")) or data.experience<0 or data.experience!=floor(data.experience): return false
	if not data.get("quest_order") is Array: return false
	if data.get("weather_override") not in ["","sunny","partly_cloudy","rainy"]: return false
	var quests=[]
	var allowed_quests=["crew_supplies","restore_farmhouse","first_harvest","meet_wizard","keeper_firewood","bells_ladder","axe_repayment","bram_sword"]
	for job in data.requests.jobs: allowed_quests.append(requests.quest_id(job))
	for id in data.quest_order:
		if not id is String or id not in allowed_quests or id in quests: return false
		quests.append(id)
	for id in data.inventory_order:
		if not id is String or (id!="" and ((not Items.CATALOG.has(id) and not Skills.CATALOG.has(id)) or id in ordered)): return false
		if id!="": ordered.append(id)
	if not _number(data.get("world_seed")) or data.world_seed<1 or data.world_seed>2147483646 or data.world_seed!=floor(data.world_seed): return false
	for field in ["inventory_selection","auxiliary_selection"]:
		if not data.get(field) is String: return false
		if data[field]!="" and not Items.CATALOG.has(data[field]) and not Skills.CATALOG.has(data[field]): return false
	if not data.get("firewood_requested") is bool or not data.get("firewood_given") is bool or (data.firewood_given and not data.firewood_requested): return false
	for field in ["woodcutter_axe_given","cave_pickaxe_taken","cave_intro_seen"]:
		if not data.get(field) is bool: return false
	if not data.get("felled_trees") is Array: return false
	for cell in data.felled_trees:
		if not cell is String: return false
		var pair=cell.split(",")
		if pair.size()!=2 or not pair[0].is_valid_int() or not pair[1].is_valid_int() or not Grid.contains(Vector2i(int(pair[0]),int(pair[1]))): return false
	if not data.get("magic_learned") is bool: return false
	if not data.magic_learned and "wildgrowth" in [data.inventory_selection,data.auxiliary_selection]: return false
	if not data.crucible_known and "build_crucible" in [data.inventory_selection,data.auxiliary_selection]: return false
	if not _number(data.get("cave_seed")) or data.cave_seed<1 or data.cave_seed>2147483646 or data.cave_seed!=floor(data.cave_seed): return false
	if not data.get("cave_chrysalis_taken") is bool or not _number(data.get("sparkfire_picked_day")) or data.sparkfire_picked_day<0 or data.sparkfire_picked_day!=floor(data.sparkfire_picked_day): return false
	if not data.get("cave_broken") is Array or not data.get("cave_defeated") is Array: return false
	for id in data.cave_broken:
		if not id is String or not id.is_valid_int() or int(id)<0 or int(id)>=30000: return false
	for id in data.cave_defeated:
		if not _number(id) or id!=floor(id) or int(id)<0 or int(id)>299: return false
	if not data.get("cave_barrel") is Array or data.cave_barrel.size()!=4: return false
	for stack in data.cave_barrel:
		if not valid_stack(stack): return false
	if not data.get("ship_departed") is bool or data.get("welcome_phase") not in ["unvisited","escorting","waiting","arriving","meeting","departing","moss_lesson","moss_departing","complete"] or not _number(data.get("welcome_elapsed")) or data.welcome_elapsed<0: return false
	if not data.get("intro_complete") is bool or not data.get("briefing_complete") is bool or not _number(data.get("mayor_due")) or data.mayor_due< -1: return false
	if not data.get("house_tasks") is Dictionary or data.house_tasks.size()!=house_tasks.size(): return false
	for task in house_tasks:
		if not data.house_tasks.get(task) is bool: return false
	if not data.get("supplies") is Dictionary: return false
	if not data.get("purchased_utensils") is Array: return false
	for id in data.purchased_utensils:
		if id not in ["pot","pan"]: return false
	for id in EXTRA_ITEMS:
		if not _number(data.supplies.get(id)) or data.supplies[id]<0 or data.supplies[id]!=floor(data.supplies[id]): return false
	for field in ["water","selected_slot","crew_fed_day","crew_hungry_days"]:
		if not _number(data.get(field)) or data[field]<0 or data[field]!=floor(data[field]): return false
	if data.water>20 or data.selected_slot>8 or data.crew_fed_day<1: return false
	if not data.get("quick_slots") is Array or data.quick_slots.size()!=8: return false
	for id in data.quick_slots:
		if id!="" and not Skills.CATALOG.has(id) and not Items.CATALOG.has(id): return false
		if id=="wildgrowth" and not data.magic_learned: return false
		if id=="build_crucible" and not data.crucible_known: return false
	for field in ["cabinet","ship_storage"]:
		if not data.get(field) is Array or data[field].size()!=12: return false
		for stack in data[field]:
			if not valid_stack(stack): return false
	for field in ["day", "money", "seeds", "turnips", "fish", "copper", "harvested","star_seeds","star_bulbs","rusty_sword","hoe","watering_can","sickle","invitation_day"]:
		if not _number(data.get(field)) or data[field] < (1 if field in ["day","invitation_day"] else 0) or data[field] != floor(data[field]):
			return false
	for field in ["minute", "mana", "energy", "x", "y","health","outdoor_x","outdoor_y"]:
		if not _number(data.get(field)):
			return false
	if data.minute < 0 or data.minute >= 1440 or data.mana < 0 or data.mana > 60 or data.energy < 0 or data.energy > 100:
		return false
	if data.health<0 or data.health>100 or data.rusty_sword>1: return false
	if data.invitation_day>data.day: return false
	if data.crew_fed_day>data.day: return false
	if data.sparkfire_picked_day>data.day: return false
	for timestamp in data.forage_harvests.values():
		if timestamp>(data.day-1)*1440+data.minute: return false
	var occupied=0
	for id in Items.CATALOG:
		var quantity=data.supplies[id] if id in EXTRA_ITEMS else data[id]
		if quantity>0: occupied+=1
	if occupied>INVENTORY_SLOTS: return false
	if occupied+data.inventory_order.filter(func(id):return Skills.CATALOG.has(id)).size()>INVENTORY_SLOTS: return false
	if not data.get("location") in ["","home","moss","finch","mayor","tavi","iona","radio","store","hall","veteran","assistant","ship","cave","keeper","reed_farm","windmill","mill_home","mill_shed","smithy","tavern","bakery","woodcutter","observatory","temple","priest","priest_outhouse"]: return false
	if not data.get("chest") is Array or data.chest.size()!=18 or not data.get("abandoned_day") is Dictionary: return false
	for stack in data.chest:
		if not stack is Dictionary: return false
		if stack.is_empty(): continue
		if not Items.CATALOG.has(stack.get("id")) or not _number(stack.get("count")) or stack.count<1 or stack.count!=floor(stack.count): return false
	for id in data.abandoned_day:
		if not id in ["moss","mayor","assistant","tavi","iona","finch","vale","veteran","keeper"] and not preload("res://neighbors.gd").STORIES.has(id): return false
		if not _number(data.abandoned_day[id]) or data.abandoned_day[id]<1 or data.abandoned_day[id]>data.day: return false
		if data.abandoned_day[id]!=floor(data.abandoned_day[id]): return false
	if not data.get("selected_seed") in ["seeds","star_seeds"] or not data.get("equipped") in ["","rusty_sword"]: return false
	if data.equipped=="rusty_sword" and data.rusty_sword==0: return false
	if not Grid.contains(Grid.world_to_cell(Vector2(data.outdoor_x,data.outdoor_y))): return false
	if not Grid.contains(Grid.world_to_cell(Vector2(data.x,data.y))):
		return false
	for field in ["invited", "met_mayor", "delivered"]:
		if not data.get(field) is bool:
			return false
	if not data.get("pause_mode") in ["none", "clock", "all"]:
		return false
	if not data.get("plots") is Array or data.plots.size()>1500:
		return false
	var plot_cells=[]
	for index in range(data.plots.size()):
		var p=data.plots[index]
		if not p is Dictionary or not p.get("tilled") is bool or not p.get("watered") is bool or not _number(p.get("planted")):
			return false
		if not _number(p.get("x")) or not _number(p.get("y")) or p.x!=floor(p.x) or p.y!=floor(p.y): return false
		var cell=Vector2i(int(p.x),int(p.y))
		if not Grid.farmable(cell): return false
		if cell in plot_cells: return false
		plot_cells.append(cell)
		if p.planted < -1.0 or p.planted > (data.day - 1) * 1440.0 + data.minute:
			return false
		if not p.get("crop") in ["turnips","star_bulbs"]: return false
		if not _number(p.get("growth")) or p.growth< -1 or p.growth>CROP_MINUTES: return false
		if not _number(p.get("water_day")) or p.water_day<0 or p.water_day>data.day or p.water_day!=floor(p.water_day): return false
	for field in ["day", "money", "seeds", "turnips", "fish", "copper", "harvested","star_seeds","star_bulbs","rusty_sword","hoe","watering_can","sickle","invitation_day"]:
		set(field, int(data[field]))
	for field in ["minute", "mana", "energy", "invited", "met_mayor", "delivered", "pause_mode","health","equipped","selected_seed","location"]:
		set(field, data[field])
	player_position = Vector2(data.x, data.y)
	needs.restore(data.needs)
	requests.restore(data.requests)
	crew_food_delivered=data.crew_food_delivered
	preload("res://town_progress.gd").restore(self,data.town)
	outdoor_position=Vector2(data.outdoor_x,data.outdoor_y)
	plots = data.plots.duplicate(true)
	chest=data.chest.duplicate(true)
	abandoned_day=data.abandoned_day.duplicate()
	for id in EXTRA_ITEMS: set(id,int(data.supplies[id]))
	for field in ["water","selected_slot","crew_fed_day","crew_hungry_days"]: set(field,int(data[field]))
	quick_slots=data.quick_slots.duplicate()
	inventory_selection=data.inventory_selection
	inventory_order=data.inventory_order.duplicate()
	experience=int(data.experience)
	quest_order=data.quest_order.duplicate()
	weather_override=data.weather_override
	awake_minutes=float(data.awake_minutes)
	sleep_minutes=float(data.sleep_minutes)
	status_effects=data.status_effects.duplicate(true)
	crucible_known=data.crucible_known
	crucibles=data.crucibles.duplicate(true)
	damage_events.clear()
	auxiliary_selection=data.auxiliary_selection
	world_seed=int(data.world_seed)
	firewood_requested=data.firewood_requested
	firewood_given=data.firewood_given
	for field in ["ladder_requested","ladder_taken","ladder_returned"]: set(field,data[field])
	forage_harvests=data.forage_harvests.duplicate()
	woodcutter_axe_given=data.woodcutter_axe_given
	cave_pickaxe_taken=data.cave_pickaxe_taken
	cave_intro_seen=data.cave_intro_seen
	felled_trees=data.felled_trees.duplicate()
	cabinet=data.cabinet.duplicate(true)
	ship_storage=data.ship_storage.duplicate(true)
	purchased_utensils=data.purchased_utensils.duplicate()
	intro_complete=data.intro_complete
	briefing_complete=data.briefing_complete
	ship_departed=data.ship_departed
	welcome_phase=data.welcome_phase
	welcome_elapsed=data.welcome_elapsed
	magic_learned=data.magic_learned
	cave_seed=int(data.cave_seed)
	cave_broken=data.cave_broken.duplicate()
	cave_defeated=data.cave_defeated.map(func(id):return int(id))
	cave_barrel=data.cave_barrel.duplicate(true)
	cave_chrysalis_taken=data.cave_chrysalis_taken
	sparkfire_picked_day=int(data.sparkfire_picked_day)
	mayor_due=data.mayor_due
	house_tasks=data.house_tasks.duplicate()
	return true

func valid_stack(stack: Variant) -> bool:
	return stack is Dictionary and (stack.is_empty() or (Items.CATALOG.has(stack.get("id")) and _number(stack.get("count")) and stack.count>0 and stack.count==floor(stack.count)))

func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))
