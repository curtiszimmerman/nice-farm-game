extends RefCounted

const Grid = preload("res://grid.gd")
const Items = preload("res://items.gd")

# Provisional calendar length for development time jumps, pending final design.
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
var copper = 0
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
var auxiliary_selection=""
var action_channel="primary"
const Skills=preload("res://skills.gd")
var world_seed=0
var lantern_ray=0
var axe=0
var wood=0
var firewood_requested=false
var firewood_given=false
var felled_trees: Array=[]
var water=0
var pot=0
var pan=0
var fish_sticks=0
var fish_stew=0
var health_elixir=0
var rations=0
var crew_fed_day=1
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
var cave_barrel: Array=[{"id":"pickaxe","count":1},{},{},{}]
var pickaxe=0
var stones=0
var cave_moth_chrysalis=0
var golden_sparkfire_bloom=0
var mayor_due=-1.0
var house_tasks={"sofa":false,"bed":false,"guest_bed":false,"radio":false,"living_light":false,"bathroom_light":false}
const INVENTORY_SLOTS=12
const EXTRA_ITEMS=["pot","pan","fish_sticks","fish_stew","health_elixir","rations","light_bulbs","moon_pike","sea_sprat","blue_mackerel","storm_eel","pickaxe","stones","cave_moth_chrysalis","golden_sparkfire_bloom","lantern_ray","axe","wood"]
const CROP_MINUTES=4320.0
const RECIPES={"fish_sticks":{"utensil":"pan","ingredients":{"fish":1}},"fish_stew":{"utensil":"pot","ingredients":{"turnips":1,"star_bulbs":1,"fish":1}}}
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
var invited = false
var met_mayor = false
var delivered = false
var pause_mode = "all"
var player_position = Grid.center(Vector2i(7,12))
var plots: Array = []

func _init() -> void:
	cave_seed=randi_range(1,2147483646)
	world_seed=randi_range(1,2147483646)
	chest=[{"id":"hoe","count":1},{"id":"watering_can","count":1},{"id":"sickle","count":1}]
	chest.append({"id":"seeds","count":8})
	while chest.size()<18: chest.append({})
	for i in range(12):
		cabinet.append({})
		ship_storage.append({"id":"rations","count":6} if i==0 else {})
	cabinet[0]={"id":"light_bulbs","count":2}
	for i in range(20):
		plots.append({"tilled": false, "planted": -1.0, "watered": false,"crop":"turnips","growth":0.0})

func total() -> float:
	return (day - 1) * 1440.0 + minute

func accept_firewood_task() -> bool:
	if firewood_given: return false
	if axe<1 and not can_carry("axe"): return false
	firewood_requested=true
	axe=1
	return true

func deliver_firewood() -> bool:
	if not firewood_requested or firewood_given or wood<6: return false
	wood-=6
	money+=25
	firewood_given=true
	clear_empty_slots()
	return true

func advance(minutes: float, window_open = false) -> void:
	if window_open and pause_mode == "all":
		return
	mana = minf(60.0, mana + minutes * 0.12)
	if window_open and pause_mode == "clock":
		return
	var elapsed = total() + minutes
	var previous_day=day
	day = int(elapsed / 1440.0) + 1
	minute = fmod(elapsed, 1440.0)
	for meal_day in range(previous_day+1,day+1):
		if take_crew_meal(): crew_fed_day=meal_day
		else: crew_hungry_days+=1

func take_crew_meal() -> bool:
	for food in ["rations","fish_sticks","fish_stew"]:
		for stack in ship_storage:
			if stack.get("id","")!=food or stack.get("count",0)<1: continue
			stack.count-=1
			if stack.count==0: stack.clear()
			return true
	return false

func ripe(index: int) -> bool:
	return index >= 0 and index < plots.size() and plots[index].planted >= 0.0 and plots[index].watered and total() - plots[index].planted+plots[index].growth >= CROP_MINUTES

func clear_empty_slots() -> void:
	if inventory_selection!="" and not available_action(inventory_selection): inventory_selection=""
	if auxiliary_selection!="" and not available_action(auxiliary_selection): auxiliary_selection=""
	for i in range(quick_slots.size()):
		if quick_slots[i]!="" and not available_action(quick_slots[i]): quick_slots[i]=""

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
	if not Items.CATALOG.has(id) or int(get(id))<1: return false
	inventory_selection=id
	selected_slot=8
	return true

func assign_slot(index: int,id: String) -> bool:
	if index<0 or index>=8 or (id!="" and not available_action(id)): return false
	quick_slots[index]=id
	return true

func farm(index: int) -> String:
	if index<0 or index>=plots.size(): return "No soil here."
	var p=plots[index]
	if p.planted>=0 and p.watered and not ripe(index): return "Growing. Three days to mature."+(" Select Wildgrowth to hasten it." if magic_learned else "")
	var needed="sickle" if ripe(index) else "hoe" if not p.tilled else "watering_can" if p.planted>=0 and not p.watered else selected_seed
	if p.tilled and p.planted<0 and active_item() in ["seeds","star_seeds"]: selected_seed=active_item(); needed=selected_seed
	if active_item()!=needed: return "Select %s in a quick slot first." % Items.CATALOG[needed].name
	return tend(index)

func refill_water() -> bool:
	if active_item()!="watering_can" or watering_can<1: return false
	water=20
	return true

func tend(index: int) -> String:
	if index < 0 or index >= plots.size():
		return "There is no garden patch here."
	var p = plots[index]
	var tool="sickle" if ripe(index) else "hoe" if not p.tilled else "watering_can" if p.planted>=0 and not p.watered else ""
	var cost=1.0 if tool in ["sickle","watering_can"] else 2.0 if tool=="hoe" else 0.0
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
		return "+1 %s. A small, very real victory." % Items.CATALOG[p.crop].name.to_lower()
	if not p.tilled:
		energy-=cost
		p.tilled = true
		return "Good earth. Press E again to plant."
	if p.planted < 0.0:
		if int(get(selected_seed)) == 0:
			return "Out of seeds. Tavi sells more at the town market."
		set(selected_seed,int(get(selected_seed))-1)
		clear_empty_slots()
		p.crop="star_bulbs" if selected_seed=="star_seeds" else "turnips"
		p.planted = total()
		return "%s planted. A little water next." % Items.CATALOG[p.crop].name
	if not p.watered:
		energy-=cost
		p.watered = true
		water-=1
		p.planted = total()
		return "Watered. Three days to mature."+(" Select Wildgrowth to hasten it." if magic_learned else "")
	return "Growing happily."

func grow(index: int) -> bool:
	if not magic_learned: return false
	if index < 0 or index >= plots.size():
		return false
	var p = plots[index]
	if mana < 15.0 or p.planted < 0.0 or not p.watered or ripe(index):
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
	if money < 10 or not can_carry("seeds"):
		return false
	money -= 10
	seeds += 5
	return true

func mine(resource: String="copper") -> bool:
	if resource not in ["copper","stones"] or active_item()!="pickaxe" or pickaxe<1 or energy < 5.0 or not can_carry(resource):
		return false
	energy -= 5.0
	set(resource,int(get(resource))+1)
	return true

func consume(id: String) -> bool:
	if not Items.FOOD.has(id) or int(get(id))<=0: return false
	var food=Items.FOOD[id]
	if (health>=100 or food.health==0) and (energy>=100 or food.energy==0) and (mana>=60 or food.mana==0): return false
	set(id,int(get(id))-1)
	clear_empty_slots()
	health=minf(100,health+food.health)
	energy=minf(100,energy+food.energy)
	mana=minf(60,mana+food.mana)
	return true

func accept_sword() -> bool:
	if has_sword() or not can_carry("rusty_sword"): return false
	rusty_sword=1
	return true

func has_sword() -> bool:
	return rusty_sword>0 or chest.any(func(stack): return stack.get("id","")=="rusty_sword")

func chest_transfer(index: int,carried_id: String="",quantity: int=-1) -> bool:
	return storage_transfer("chest",index,carried_id,quantity)

func storage_transfer(storage_name: String,index: int,carried_id: String="",quantity: int=-1) -> bool:
	if storage_name not in ["chest","cabinet","ship_storage","cave_barrel"]: return false
	var storage: Array=get(storage_name)
	if index<0 or index>=storage.size() or (carried_id!="" and (not Items.CATALOG.has(carried_id) or int(get(carried_id))<=0)): return false
	var stored: Dictionary=storage[index]
	var available=int(stored.get("count",0)) if carried_id=="" else int(get(carried_id))
	var amount=available if quantity==-1 else quantity
	if amount<1 or amount>available: return false
	var incoming=stored.get("id","")
	var slots=carried_slots()
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

func can_carry(id: String) -> bool:
	return Items.CATALOG.has(id) and (int(get(id))>0 or carried_slots()<INVENTORY_SLOTS)

func tidy_house(task: String) -> bool:
	if not house_tasks.has(task) or house_tasks[task]: return false
	if task.ends_with("light"):
		if light_bulbs<1: return false
		light_bulbs-=1
	house_tasks[task]=true
	clear_empty_slots()
	return true

func buy_utensil(id: String) -> bool:
	if id not in ["pot","pan"] or money<20 or id in purchased_utensils or not can_carry(id): return false
	money-=20
	set(id,1)
	purchased_utensils.append(id)
	return true

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
	if money<12 or not can_carry("star_seeds"): return false
	money-=12
	star_seeds+=3
	return true

func meet_mayor() -> bool:
	if not mayor_available():
		return false
	met_mayor = true
	return true

func to_dict() -> Dictionary:
	var supplies={}
	for id in EXTRA_ITEMS: supplies[id]=get(id)
	return {"version": 9, "auxiliary_selection":auxiliary_selection,"world_seed":world_seed,"inventory_selection":inventory_selection,"firewood_requested":firewood_requested,"firewood_given":firewood_given,"felled_trees":felled_trees.duplicate(),"day": day, "minute": minute, "money": money,"magic_learned":magic_learned,
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
	if not data is Dictionary or data.get("version") != 9:
		return false
	if not _number(data.get("world_seed")) or data.world_seed<1 or data.world_seed>2147483646 or data.world_seed!=floor(data.world_seed): return false
	for field in ["inventory_selection","auxiliary_selection"]:
		if not data.get(field) is String: return false
		if data[field]!="" and not Items.CATALOG.has(data[field]) and not Skills.CATALOG.has(data[field]): return false
	if not data.get("firewood_requested") is bool or not data.get("firewood_given") is bool or (data.firewood_given and not data.firewood_requested): return false
	if not data.get("felled_trees") is Array: return false
	for cell in data.felled_trees:
		if not cell is String: return false
		var pair=cell.split(",")
		if pair.size()!=2 or not pair[0].is_valid_int() or not pair[1].is_valid_int() or not Grid.contains(Vector2i(int(pair[0]),int(pair[1]))): return false
	if not data.get("magic_learned") is bool: return false
	if not data.magic_learned and "wildgrowth" in [data.inventory_selection,data.auxiliary_selection]: return false
	if not _number(data.get("cave_seed")) or data.cave_seed<1 or data.cave_seed>2147483646 or data.cave_seed!=floor(data.cave_seed): return false
	if not data.get("cave_chrysalis_taken") is bool or not _number(data.get("sparkfire_picked_day")) or data.sparkfire_picked_day<0 or data.sparkfire_picked_day!=floor(data.sparkfire_picked_day): return false
	if not data.get("cave_broken") is Array or not data.get("cave_defeated") is Array: return false
	for id in data.cave_broken:
		if not id is String or not id.is_valid_int() or int(id)<0 or int(id)>=18: return false
	for id in data.cave_defeated:
		if not _number(id) or id not in [0,1]: return false
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
	var occupied=0
	for id in Items.CATALOG:
		var quantity=data.supplies[id] if id in EXTRA_ITEMS else data[id]
		if quantity>0: occupied+=1
	if occupied>INVENTORY_SLOTS: return false
	if not data.get("location") in ["","home","moss","finch","mayor","tavi","iona","radio","store","hall","veteran","assistant","ship","cave","keeper","reed_farm","windmill","mill_home","smithy","tavern","bakery"]: return false
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
	if not data.get("plots") is Array or data.plots.size() != 20:
		return false
	for p in data.plots:
		if not p is Dictionary or not p.get("tilled") is bool or not p.get("watered") is bool or not _number(p.get("planted")):
			return false
		if p.planted < -1.0 or p.planted > (data.day - 1) * 1440.0 + data.minute:
			return false
		if not p.get("crop") in ["turnips","star_bulbs"]: return false
		if not _number(p.get("growth")) or p.growth<0 or p.growth>CROP_MINUTES: return false
	for field in ["day", "money", "seeds", "turnips", "fish", "copper", "harvested","star_seeds","star_bulbs","rusty_sword","hoe","watering_can","sickle","invitation_day"]:
		set(field, int(data[field]))
	for field in ["minute", "mana", "energy", "invited", "met_mayor", "delivered", "pause_mode","health","equipped","selected_seed","location"]:
		set(field, data[field])
	player_position = Vector2(data.x, data.y)
	outdoor_position=Vector2(data.outdoor_x,data.outdoor_y)
	plots = data.plots.duplicate(true)
	chest=data.chest.duplicate(true)
	abandoned_day=data.abandoned_day.duplicate()
	for id in EXTRA_ITEMS: set(id,int(data.supplies[id]))
	for field in ["water","selected_slot","crew_fed_day","crew_hungry_days"]: set(field,int(data[field]))
	quick_slots=data.quick_slots.duplicate()
	inventory_selection=data.inventory_selection
	auxiliary_selection=data.auxiliary_selection
	world_seed=int(data.world_seed)
	firewood_requested=data.firewood_requested
	firewood_given=data.firewood_given
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
	cave_defeated=data.cave_defeated.duplicate()
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
