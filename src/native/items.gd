extends RefCounted

const FOOD={"turnips":{"health":8,"energy":12,"mana":0},"fish":{"health":5,"energy":8,"mana":0},"star_bulbs":{"health":0,"energy":0,"mana":15}}

const CATALOG={
	"seeds":{"name":"Moon-turnip seeds","description":"Plant in your own tilled soil. Water, then allow three game hours.","action":"Select for planting"},
	"star_seeds":{"name":"Star-bulb seeds","description":"A small luminous crop. Its bulb restores attunement.","action":"Select for planting"},
	"turnips":{"name":"Moon turnip","description":"A crisp, sweet root. Restores a little health and energy.","action":"Eat one"},
	"fish":{"name":"Pond silverfin","description":"A small freshwater fish. Restores a little health and energy.","action":"Eat one"},
	"star_bulbs":{"name":"Star bulb","description":"Cool and peppery, with a faint light beneath its skin. Restores mana.","action":"Eat one"},
	"copper":{"name":"Copper ore","description":"Local copper for Chief Vale's crew-link repair.","action":"Crafting material"},
	"rusty_sword":{"name":"Rusty sword","description":"An old army blade. Worn, serviceable, and freely given.","action":"Equip"}
}
static var textures: Dictionary={}

static func icon(id: String) -> Texture2D:
	if textures.has(id): return textures[id]
	var image=Image.create(24,24,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y in range(24):
		for x in range(24):
			var color=Color.TRANSPARENT
			match id:
				"turnips","star_bulbs":
					var p=(Vector2(x,y)-Vector2(12,15))/Vector2(7,6)
					if p.length_squared()<1: color=Color("e3d6ad") if id=="turnips" else Color("e5c777")
					if x in range(10,14) and y in range(5,13): color=Color("769a63")
					if y in range(5,8) and x in range(6,18): color=Color("95b57b")
					if id=="star_bulbs" and ((abs(x-12)<2 and y in range(10,23)) or (abs(y-15)<2 and x in range(3,22))): color=Color("f8e7a3")
				"fish":
					if pow((x-11)/8.0,2)+pow((y-12)/4.5,2)<1: color=Color("9dbcc0") if y<12 else Color("6e929c")
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
