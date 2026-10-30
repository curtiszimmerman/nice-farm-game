extends RefCounted

# Quantities are bundles per seasonal delivery; seeds are sold in packets.
const DRINKS={"ale":{"name":"Valley ale","energy":8},"mead":{"name":"Honey mead","energy":12},"whiskey":{"name":"Oak-cask whiskey","energy":5},"wrenlight":{"name":"Wrenlight","energy":15}}
const CATALOG={"ale":{"count":1,"price":8,"stock":20},"mead":{"count":1,"price":12,"stock":15},"whiskey":{"count":1,"price":18,"stock":10},"wrenlight":{"count":1,"price":14,"stock":12},"seeds":{"count":5,"price":10,"stock":80},"star_seeds":{"count":3,"price":12,"stock":48},"pot":{"count":1,"price":20,"stock":1},"pan":{"count":1,"price":20,"stock":1},"health_elixir":{"count":1,"price":15,"stock":10},"sugar":{"count":1,"price":4,"stock":30},"butter":{"count":1,"price":6,"stock":20},"flour":{"count":1,"price":5,"stock":30},"bread":{"count":1,"price":6,"stock":20},"rusty_sword":{"count":1,"price":1000,"stock":1}}
static func amounts() -> Dictionary:
	var result={}
	for id in CATALOG: result[id]=CATALOG[id].stock
	return result

static func daily(id: String) -> bool:
	return id in preload("res://items.gd").FOOD or id in DRINKS or id in ["flour","sugar","butter"]
