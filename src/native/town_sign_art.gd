extends RefCounted

static var textures={}

static func texture(kind: String) -> Texture2D:
	if textures.has(kind): return textures[kind]
	var image=Image.create(72,12,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var tavern=kind=="tavern"
	var dark=Color("302f32") if tavern else Color("253f43")
	var wood=Color("624735") if tavern else Color("426865")
	var trim=Color("c89c60") if tavern else Color("bbb794")
	for y in range(12):
		for x in range(72):
			if (x<2 or x>69) and (y<2 or y>9): continue
			var border=x<2 or x>69 or y<2 or y>9
			var color=dark if x==0 or x==71 or y==11 else trim if border else wood
			if not border and tavern and y in [4,8] and x%13<5: color=Color("70503b")
			image.set_pixel(x,y,color)
	for x in [3,68]:
		image.set_pixel(x,3,Color("f1dfad"))
		image.set_pixel(x,8,dark)
	if tavern:
		var bird=[Vector2i(6,5),Vector2i(7,5),Vector2i(8,5),Vector2i(6,6),Vector2i(7,6),Vector2i(8,6),Vector2i(9,6),Vector2i(10,5),Vector2i(11,5),Vector2i(5,4),Vector2i(4,4),Vector2i(7,7)]
		for pixel in bird: image.set_pixelv(pixel,Color("e0c18a"))
	else:
		for x in range(5,11):
			image.set_pixel(x,4,trim)
			image.set_pixel(x,8,trim)
		for y in range(5,8):
			for x in [6,8,10]: image.set_pixel(x,y,Color("e2dcc0"))
	textures[kind]=ImageTexture.create_from_image(image)
	return textures[kind]

static func draw(canvas: CanvasItem,kind: String,center: float) -> void:
	var at=Vector2(center-72,-89)
	canvas.draw_texture_rect(texture(kind),Rect2(at,Vector2(144,24)),false)
	var font=preload("res://pixel_ui.gd").font()
	var ink=Color("f5e6be")
	if kind=="tavern":
		canvas.draw_string(font,at+Vector2(27,10),"WAYWARD",HORIZONTAL_ALIGNMENT_LEFT,-1,8,ink)
		canvas.draw_string(font,at+Vector2(27,19),"WREN",HORIZONTAL_ALIGNMENT_LEFT,-1,8,ink)
		canvas.draw_string(font,at+Vector2(76,17),"TAVERN",HORIZONTAL_ALIGNMENT_LEFT,-1,12,ink)
	else:
		canvas.draw_string(font,at+Vector2(35,17),"TOWN HALL",HORIZONTAL_ALIGNMENT_LEFT,-1,12,ink)
