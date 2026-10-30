extends RefCounted

const SEEDS={"green_onion_seeds":"green_onions","tomato_seeds":"tomatoes","cucumber_seeds":"cucumbers","gladain_seeds":"gladain"}
const COLORS={"green_onions":"e0dfb0","tomatoes":"df6547","cucumbers":"689446","gladain":"d7b45b"}
static var textures={}

static func icon(id: String) -> Texture2D:
	if textures.has(id): return textures[id]
	var crop=SEEDS.get(id,id)
	var packet=SEEDS.has(id)
	var image=Image.create(16,16,false,Image.FORMAT_RGBA8)
	for y in range(16):
		for x in range(16):
			var color=Color.TRANSPARENT
			if packet and x>=2 and x<=13 and y>=1 and y<=14:
				color=Color("d2ba86") if x not in [2,13] and y not in [1,14] else Color("766347")
			var body=false
			match crop:
				"green_onions":
					body=x in [5,6,9,10] and y>=9 and y<=13
					if x in [4,5,9,10] and y>=3 and y<=9: color=Color("71965a") if x%2==0 else Color("abc67c")
				"tomatoes":
					body=Vector2(x-8,y-9).length()<5
					if y in [3,4] and x>=5 and x<=10: color=Color("598448")
				"cucumbers":
					body=pow((x-8)/3.2,2)+pow((y-8)/6.0,2)<1
				"gladain":
					body=pow((x-8)/5.5,2)+pow((y-9)/4.2,2)<1
			if body:
				color=Color(COLORS[crop]).darkened(0.22 if x>8 else 0)
				if (x*3+y*5)%17==0: color=color.darkened(0.2)
				elif x<7 and y<9: color=color.lightened(0.15)
			image.set_pixel(x,y,color)
	textures[id]=ImageTexture.create_from_image(image)
	return textures[id]
