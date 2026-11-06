extends RefCounted

static var seats: Texture2D
static var steps: Texture2D

static func chair(c: CanvasItem) -> void:
	if seats==null:
		var pixels=["................","....ssssssss....","...slllllllls...","..slddddddddls..","..slddddddddls..","..slddddddddls..","..slddddddddls..","..slddddddddls..","..slddddddddls..","..slddddddddls..","..slllllllllls..",".ssllllllllllss.",".slssssssssssls.",".slddddddddddls.",".slddddddddddls.",".ssllllllllllss.","..ssssssssssss..",".....ssssss.....","......slls......","......slls......","....ssssssss....","...slllllllls...","....ssssssss....","................"]
		var colors={"s":Color("273b49"),"l":Color("8ba6b1"),"d":Color("42697c")}
		var bitmap=Image.create(16,24,false,Image.FORMAT_RGBA8)
		bitmap.fill(Color.TRANSPARENT)
		for y in range(pixels.size()):
			for x in range(16):
				if colors.has(pixels[y][x]): bitmap.set_pixel(x,y,colors[pixels[y][x]])
		seats=ImageTexture.create_from_image(bitmap)
	c.draw_texture_rect(seats,Rect2(0,-48,32,48),false)

static func stairs(c: CanvasItem) -> void:
	if steps==null:
		var bitmap=Image.create(32,16,false,Image.FORMAT_RGBA8)
		bitmap.fill(Color("172b36"))
		for y in range(16):
			for x in range(32):
				var color=Color("a3b5ba") if x<2 or x>29 else Color("708790") if y%3==0 else Color("344b59")
				if (x==3 or x==28) and y%4<2: color=Color("d4b575")
				bitmap.set_pixel(x,y,color)
		steps=ImageTexture.create_from_image(bitmap)
	c.draw_texture_rect(steps,Rect2(0,-32,64,32),false)
