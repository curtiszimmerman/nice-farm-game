extends RefCounted

# Quantities are bundles per seasonal delivery; seeds are sold in packets.
const CATALOG={"seeds":{"count":5,"price":10,"stock":20},"star_seeds":{"count":3,"price":12,"stock":12},"pot":{"count":1,"price":20,"stock":1},"pan":{"count":1,"price":20,"stock":1},"health_elixir":{"count":1,"price":15,"stock":10},"sugar":{"count":1,"price":4,"stock":30},"butter":{"count":1,"price":6,"stock":20},"flour":{"count":1,"price":5,"stock":30}}
static func amounts() -> Dictionary:
	var result={}
	for id in CATALOG: result[id]=CATALOG[id].stock
	return result
