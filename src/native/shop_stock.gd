extends RefCounted

# Quantities are bundles per seasonal delivery; seeds are sold in packets.
const DRINKS={"ale":{"name":"Valley ale","energy":1},"mead":{"name":"Honey mead","energy":1},"whiskey":{"name":"Oak-cask whiskey","energy":1},"wrenlight":{"name":"Wrenlight","energy":1}}
const CATALOG={"glass_jars":{"count":1,"price":3,"stock":30},"green_onion_seeds":{"count":5,"price":10,"stock":80},"tomato_seeds":{"count":5,"price":10,"stock":80},"cucumber_seeds":{"count":5,"price":10,"stock":80},"gladain_seeds":{"count":5,"price":10,"stock":80},"ale":{"count":1,"price":8,"stock":20},"mead":{"count":1,"price":12,"stock":15},"whiskey":{"count":1,"price":18,"stock":10},"wrenlight":{"count":1,"price":14,"stock":12},"seeds":{"count":5,"price":10,"stock":80},"star_seeds":{"count":3,"price":12,"stock":48},"pot":{"count":1,"price":20,"stock":1},"pan":{"count":1,"price":20,"stock":1},"health_elixir":{"count":1,"price":15,"stock":10},"sugar":{"count":1,"price":4,"stock":30},"butter":{"count":1,"price":6,"stock":20},"flour":{"count":1,"price":5,"stock":30},"bread":{"count":1,"price":6,"stock":20},"rusty_sword":{"count":1,"price":1000,"stock":1},"copper_bars":{"count":1,"price":550,"stock":2},"silver_bars":{"count":1,"price":1800,"stock":1}}
# Widow Marsh's curios: seed packets from far away, and trinkets her late husband's trading friends still send.
# Her stock is a few of each, and it changes every week.
const CURIOS={"veyr_pepper_seeds":{"count":5,"price":40,"stock":3},"moonmelon_seeds":{"count":3,"price":60,"stock":3},"frostkale_seeds":{"count":5,"price":30,"stock":3},"veyr_silk_scarf":{"count":1,"price":120,"stock":1},"brass_spyglass":{"count":1,"price":180,"stock":1},"music_box":{"count":1,"price":150,"stock":1}}
const TRINKETS=["veyr_silk_scarf","brass_spyglass","music_box"]

static func bundle(id: String) -> int:
	return int(CURIOS[id].count if CURIOS.has(id) else CATALOG[id].count)

static func restock(id: String) -> String:
	return "next week" if CURIOS.has(id) else "tomorrow" if daily(id) else "next season"

static func amounts() -> Dictionary:
	var result={}
	for id in CATALOG: result[id]=CATALOG[id].stock
	return result

static func daily(id: String) -> bool:
	return id in preload("res://items.gd").FOOD or id in DRINKS or id in ["flour","sugar","butter"]
