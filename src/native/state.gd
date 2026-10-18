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
var minute = 480.0
var money = 24
var seeds = 8
var turnips = 0
var fish = 0
var copper = 0
var star_seeds = 0
var star_bulbs = 0
var rusty_sword = 0
var equipped = ""
var health = 100.0
var selected_seed = "seeds"
var location = ""
var outdoor_position = Grid.center(Grid.SPAWN_CELL)
var harvested = 0
var mana = 60.0
var energy = 100.0
var invited = false
var met_mayor = false
var delivered = false
var pause_mode = "none"
var player_position = Grid.center(Grid.SPAWN_CELL)
var plots: Array = []

func _init() -> void:
	for i in range(20):
		plots.append({"tilled": false, "planted": -1.0, "watered": false,"crop":"turnips"})

func total() -> float:
	return (day - 1) * 1440.0 + minute

func advance(minutes: float, window_open = false) -> void:
	if window_open and pause_mode == "all":
		return
	mana = minf(60.0, mana + minutes * 0.12)
	if window_open and pause_mode == "clock":
		return
	var elapsed = total() + minutes
	day = int(elapsed / 1440.0) + 1
	minute = fmod(elapsed, 1440.0)

func ripe(index: int) -> bool:
	return index >= 0 and index < plots.size() and plots[index].planted >= 0.0 and plots[index].watered and total() - plots[index].planted >= 180.0

func tend(index: int) -> String:
	if index < 0 or index >= plots.size():
		return "There is no garden patch here."
	var p = plots[index]
	if ripe(index):
		p.planted = -1.0
		p.watered = false
		set(p.crop,int(get(p.crop))+1)
		harvested += 1
		return "+1 %s. A small, very real victory." % Items.CATALOG[p.crop].name.to_lower()
	if not p.tilled:
		p.tilled = true
		return "Good earth. Press E again to plant."
	if p.planted < 0.0:
		if int(get(selected_seed)) == 0:
			return "Out of seeds. Tavi sells more at the town market."
		set(selected_seed,int(get(selected_seed))-1)
		p.crop="star_bulbs" if selected_seed=="star_seeds" else "turnips"
		p.planted = total()
		return "%s planted. A little water next." % Items.CATALOG[p.crop].name
	if not p.watered:
		p.watered = true
		p.planted = total()
		return "Watered. Three game hours, or a little Wildgrowth with Q."
	return "Growing happily. Q casts your borrowed growth spell."

func grow(index: int) -> bool:
	if index < 0 or index >= plots.size():
		return false
	var p = plots[index]
	if mana < 15.0 or p.planted < 0.0 or not p.watered or ripe(index):
		return false
	mana -= 15.0
	p.planted = total() - 180.0
	return true

func sell() -> bool:
	if turnips == 0 and fish == 0 and star_bulbs == 0:
		return false
	money += turnips * 8 + fish * 10 + star_bulbs*12
	turnips = 0
	fish = 0
	star_bulbs=0
	return true

func buy_seeds() -> bool:
	if money < 10:
		return false
	money -= 10
	seeds += 5
	return true

func mine() -> bool:
	if energy < 5.0:
		return false
	energy -= 5.0
	copper += 1
	return true

func consume(id: String) -> bool:
	if not Items.FOOD.has(id) or int(get(id))<=0: return false
	var food=Items.FOOD[id]
	if (health>=100 or food.health==0) and (energy>=100 or food.energy==0) and (mana>=60 or food.mana==0): return false
	set(id,int(get(id))-1)
	health=minf(100,health+food.health)
	energy=minf(100,energy+food.energy)
	mana=minf(60,mana+food.mana)
	return true

func accept_sword() -> bool:
	if rusty_sword>0: return false
	rusty_sword=1
	return true

func buy_star_seeds() -> bool:
	if money<12: return false
	money-=12
	star_seeds+=3
	return true

func meet_mayor() -> bool:
	if not invited or met_mayor or total() < 2160.0:
		return false
	met_mayor = true
	return true

func to_dict() -> Dictionary:
	return {"version": 2, "day": day, "minute": minute, "money": money,
		"health":health,"star_seeds":star_seeds,"star_bulbs":star_bulbs,"rusty_sword":rusty_sword,"equipped":equipped,"selected_seed":selected_seed,
		"location":location,"outdoor_x":outdoor_position.x,"outdoor_y":outdoor_position.y,
		"seeds": seeds, "turnips": turnips, "fish": fish, "copper": copper,
		"harvested": harvested, "mana": mana, "energy": energy,
		"invited": invited, "met_mayor": met_mayor, "delivered": delivered,
		"pause_mode": pause_mode, "x": player_position.x, "y": player_position.y,
		"plots": plots.duplicate(true)}

func restore(data: Variant) -> bool:
	if not data is Dictionary or data.get("version") != 2:
		return false
	for field in ["day", "money", "seeds", "turnips", "fish", "copper", "harvested","star_seeds","star_bulbs","rusty_sword"]:
		if not _number(data.get(field)) or data[field] < (1 if field == "day" else 0) or data[field] != floor(data[field]):
			return false
	for field in ["minute", "mana", "energy", "x", "y","health","outdoor_x","outdoor_y"]:
		if not _number(data.get(field)):
			return false
	if data.minute < 0 or data.minute >= 1440 or data.mana < 0 or data.mana > 60 or data.energy < 0 or data.energy > 100:
		return false
	if data.health<0 or data.health>100 or data.rusty_sword>1: return false
	if not data.get("location") in ["","home","moss","finch","mayor","tavi","iona","radio","store","hall","veteran"]: return false
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
	for field in ["day", "money", "seeds", "turnips", "fish", "copper", "harvested","star_seeds","star_bulbs","rusty_sword"]:
		set(field, int(data[field]))
	for field in ["minute", "mana", "energy", "invited", "met_mayor", "delivered", "pause_mode","health","equipped","selected_seed","location"]:
		set(field, data[field])
	player_position = Vector2(data.x, data.y)
	outdoor_position=Vector2(data.outdoor_x,data.outdoor_y)
	plots = data.plots.duplicate(true)
	return true

func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))
