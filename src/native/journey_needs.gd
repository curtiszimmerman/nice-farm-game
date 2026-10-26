extends RefCounted

const WATER_MINUTES=4320.0
const FOOD_MINUTES=30240.0
var hardcore=false
var mode_chosen=false
var without_water=0.0
var without_food=0.0
var damage_minutes=0.0

func thirsty() -> bool: return hardcore and without_water>=WATER_MINUTES
func starving() -> bool: return hardcore and without_food>=FOOD_MINUTES
func deprived() -> bool: return thirsty() or starving()
func hydration() -> float: return clampf(1-without_water/WATER_MINUTES,0,1)
func nourishment() -> float: return clampf(1-without_food/FOOD_MINUTES,0,1)
func drink() -> void:
	without_water=0
	if not deprived(): damage_minutes=0
func eat() -> void:
	without_food=0
	if not deprived(): damage_minutes=0
func advance(minutes: float,state: RefCounted) -> float:
	if not hardcore: return minutes
	var safe=minf(minutes,maxf(0,minf(WATER_MINUTES-without_water,FOOD_MINUTES-without_food)))
	without_water+=minutes
	without_food+=minutes
	damage_minutes+=minutes-safe
	while damage_minutes>=60:
		damage_minutes-=60
		var damage=minf(10,state.health)
		state.health-=damage
		if damage>0: state.damage_events.append(damage)
	return safe
func to_dict() -> Dictionary:
	return {"hardcore":hardcore,"mode_chosen":mode_chosen,"without_water":without_water,"without_food":without_food,"damage_minutes":damage_minutes}
static func valid(data: Variant) -> bool:
	if not data is Dictionary or not data.get("hardcore") is bool or not data.get("mode_chosen") is bool: return false
	for field in ["without_water","without_food","damage_minutes"]:
		var value=data.get(field)
		if not (value is int or value is float) or not is_finite(value) or value<0: return false
	return data.damage_minutes<60
func restore(data: Dictionary) -> void:
	hardcore=data.hardcore
	mode_chosen=data.mode_chosen
	without_water=float(data.without_water)
	without_food=float(data.without_food)
	damage_minutes=float(data.damage_minutes)
