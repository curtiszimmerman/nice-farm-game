extends RefCounted

const Art=preload("res://art.gd")

const FOOD={"turnips":{"health":8,"energy":12,"mana":0},"fish":{"health":5,"energy":8,"mana":0},"star_bulbs":{"health":0,"energy":0,"mana":15},"health_elixir":{"health":25,"energy":0,"mana":0},"fish_sticks":{"health":12,"energy":20,"mana":0},"fish_stew":{"health":20,"energy":30,"mana":15},"rations":{"health":0,"energy":15,"mana":0},"moon_pike":{"health":7,"energy":10,"mana":0},"sea_sprat":{"health":4,"energy":6,"mana":0},"blue_mackerel":{"health":5,"energy":8,"mana":0},"storm_eel":{"health":8,"energy":12,"mana":0}}
const FISH={"fish":{"habitat":"pond","hard":false,"price":10,"color":"9dbcc0"},"moon_pike":{"habitat":"pond","hard":true,"price":35,"color":"a8ad7b"},"sea_sprat":{"habitat":"ocean","hard":false,"price":12,"color":"c1c7b2"},"blue_mackerel":{"habitat":"ocean","hard":false,"price":16,"color":"729ab6"},"storm_eel":{"habitat":"ocean","hard":true,"price":50,"color":"a58bb6"}}

const CATALOG={
	"pickaxe":{"name":"Pickaxe","description":"Select to break cave rocks and copper deposits. Costs 5 energy per rock.","action":"Mining tool"},
	"stones":{"name":"Stone","description":"Rock collected in the cave.","action":"Building material"},
	"cave_moth_chrysalis":{"name":"Cave Moth Chrysalis","description":"Found deep in the caves. Iona seeks it for further magic lessons.","action":"Magic component"},
	"golden_sparkfire_bloom":{"name":"Golden Sparkfire Bloom","description":"A magical flower that opens only during sunrise.","action":"Magic component"},
	"moon_pike":{"name":"Moon pike","description":"An elusive, valuable pond predator. Difficult to catch; suitable for cooking.","action":"Cooking ingredient · sell for 35 crowns"},
	"sea_sprat":{"name":"Sea sprat","description":"A small, easy coastal catch. Suitable for cooking.","action":"Cooking ingredient · sell for 12 crowns"},
	"blue_mackerel":{"name":"Blue mackerel","description":"A striped coastal fish. Easy to catch; suitable for cooking.","action":"Cooking ingredient · sell for 16 crowns"},
	"storm_eel":{"name":"Storm eel","description":"An erratic, valuable ocean catch. Difficult to land; suitable for cooking.","action":"Cooking ingredient · sell for 50 crowns"},
	"light_bulbs":{"name":"Light bulb","description":"A replacement bulb for the farmhouse bathroom or living room.","action":"Use at a broken light fixture"},
	"pot":{"name":"Cooking pot","description":"Keep in your satchel or kitchen cabinet to cook fish stew at the oven.","action":"Cooking equipment"},
	"pan":{"name":"Frying pan","description":"Keep in your satchel or kitchen cabinet to cook fish sticks at the oven.","action":"Cooking equipment"},
	"fish_sticks":{"name":"Fish sticks","description":"Crisp pan-fried fish. A cooked meal for you or Vale.","action":"Eat"},
	"fish_stew":{"name":"Fish stew","description":"Fish, moon turnip and star bulb in a warm broth.","action":"Eat"},
	"health_elixir":{"name":"Elixir of health","description":"Restores 25 health.","action":"Drink"},
	"rations":{"name":"Starship ration","description":"Sealed crew food. Vale needs one ration or cooked meal daily.","action":"Eat"},
	"hoe":{"name":"Hoe","description":"Select to till. Costs 2 energy per plot.","action":"Farming tool"},
	"watering_can":{"name":"Watering can","description":"Holds 20 water. Refill at the pond. Costs 1 energy per plot.","action":"Farming tool"},
	"sickle":{"name":"Harvesting sickle","description":"Select to harvest. Costs 1 energy per plot.","action":"Farming tool"},
	"seeds":{"name":"Moon-turnip seeds","description":"Plant in your own tilled soil. Water, then allow three days.","action":"Select for planting"},
	"star_seeds":{"name":"Star-bulb seeds","description":"A small luminous crop. Its bulb restores attunement.","action":"Select for planting"},
	"turnips":{"name":"Moon turnip","description":"A crisp, sweet root. Restores a little health and energy.","action":"Eat one"},
	"fish":{"name":"Pond silverfin","description":"A small freshwater fish. Restores a little health and energy.","action":"Eat one"},
	"star_bulbs":{"name":"Star bulb","description":"Cool and peppery, with a faint light beneath its skin. Restores mana.","action":"Eat one"},
	"copper":{"name":"Copper ore","description":"Local copper for Chief Vale's crew-link repair.","action":"Crafting material"},
	"rusty_sword":{"name":"Rusty sword","description":"Bram's old army blade. Select and activate to swing in caves. Costs 2 energy.","action":"Weapon"}
}
static var textures: Dictionary={}

static func icon(id: String) -> Texture2D:
	if Art.option==2:
		var key="sprite_"+id
		if not textures.has(key):
			var texture=AtlasTexture.new()
			texture.region=Art.region("item_"+id)
			texture.atlas=Art.atlas
			textures[key]=texture
		return textures[key]
	if textures.has(id): return textures[id]
	var image=Image.create(24,24,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y in range(24):
		for x in range(24):
			var color=Color.TRANSPARENT
			match id:
				"pickaxe":
					if abs(x+y-24)<2 and x in range(5,20): color=Color("aa8555")
					if y in range(4,8) and x in range(6,22): color=Color("a6b8bc") if y<6 else Color("61747c")
				"stones":
					if Vector2(x-12,y-14).length()<8: color=Color("8c9291") if x+y<26 else Color("555f64")
				"cave_moth_chrysalis":
					if pow((x-12)/5.0,2)+pow((y-12)/9.0,2)<1: color=Color("acbcb2") if y%4 else Color("668a91")
				"golden_sparkfire_bloom":
					if x in range(11,14) and y>10: color=Color("6b9754")
					if Vector2(x-12,y-9).length()<7: color=Color("eac363") if (x+y)%3 else Color("fff0a0")
				"light_bulbs":
					if Vector2(x-12,y-10).length()<6: color=Color("e9deb0") if x<13 else Color("c5b67e")
					if x in range(9,16) and y in range(14,21): color=Color("819499") if y%2 else Color("afbbb7")
				"pot","pan","fish_stew":
					if pow((x-12)/8.0,2)+pow((y-14)/6.0,2)<1: color=Color("66808a") if y>13 else Color("b7c4be")
					if id=="fish_stew" and pow((x-12)/6.0,2)+pow((y-12)/3.0,2)<1: color=Color("c09c65")
					if id=="pan" and x in range(11,14) and y<12: color=Color("74614d")
					if id=="pot" and y in range(11,15) and (x<5 or x>19): color=Color("8fa29e")
				"fish_sticks":
					if x in range(3,21) and (y in range(6,10) or y in range(13,17)): color=Color("d4ae64") if y%3 else Color("936a42")
				"health_elixir":
					if x in range(9,15) and y in range(3,11): color=Color("becfc9")
					if Vector2(x-12,y-16).length()<7: color=Color("ba6674") if x>9 else Color("e8b2ac")
				"rations":
					if x in range(4,20) and y in range(5,21): color=Color("889a8b") if x<17 else Color("566b63")
					if x in range(7,16) and y in range(10,16): color=Color("d2c591")
				"hoe","sickle":
					if x in range(10,13) and y in range(5,23): color=Color("a58a5a")
					if id=="hoe" and x in range(4,20) and y in range(4,8): color=Color("9ea99f")
					if id=="sickle" and absf(Vector2(x-12,y-9).length()-7)<2 and x>=12: color=Color("b9c3b6")
				"watering_can":
					if x in range(4,17) and y in range(10,21): color=Color("83a7ab")
					if x in range(9,14) and y in range(5,12): color=Color("b3c5ba")
					if x in range(16,23) and y in range(11,15): color=Color("9db6b4")
				"turnips","star_bulbs":
					var p=(Vector2(x,y)-Vector2(12,15))/Vector2(7,6)
					if p.length_squared()<1: color=Color("e3d6ad") if id=="turnips" else Color("e5c777")
					if x in range(10,14) and y in range(5,13): color=Color("769a63")
					if y in range(5,8) and x in range(6,18): color=Color("95b57b")
					if id=="star_bulbs" and ((abs(x-12)<2 and y in range(10,23)) or (abs(y-15)<2 and x in range(3,22))): color=Color("f8e7a3")
				"fish","moon_pike","sea_sprat","blue_mackerel","storm_eel":
					if pow((x-11)/8.0,2)+pow((y-12)/4.5,2)<1: color=Color(FISH[id].color) if y<12 else Color(FISH[id].color).darkened(0.2)
					if x>=17 and x<=22 and abs(y-12)<=x-17: color=Color("86a8ad")
					if x==6 and y==11: color=Color("314d50")
				"seeds","star_seeds":
					if x in range(5,20) and y in range(5,22): color=Color("bca16f") if x<17 else Color("927950")
					if x in range(7,18) and y in range(7,18): color=Color("718969") if id=="seeds" else Color("827f9b")
					if abs(x-12)+abs(y-12)<4: color=Color("ddd1a2")
				"copper":
					if x in range(4,21) and y in range(6,21) and abs(x-12)+abs(y-14)<13: color=Color("9e7956") if (x+y)%5 else Color("d1a36d")
				"rusty_sword":
					if abs(x+y-22)<=2 and x in range(8,22): color=Color("a1aaa0") if x%4 else Color("a07b58")
					if abs(x+y-22)<2 and x in range(2,9): color=Color("77654b")
					if abs(x-y)<2 and x in range(5,13): color=Color("ba9e67")
			image.set_pixel(x,y,color)
	var texture=ImageTexture.create_from_image(image)
	textures[id]=texture
	return texture
