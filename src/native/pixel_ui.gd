extends RefCounted

static var bitmap: FontFile

static func font() -> FontFile:
	if bitmap==null:
		bitmap=FontFile.new()
		assert(bitmap.load_bitmap_font("res://art/ui/pixel-font.fnt")==OK,"Pixel font could not be loaded")
		bitmap.fixed_size=10
		bitmap.fixed_size_scale_mode=TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
		ThemeDB.fallback_font=bitmap
	return bitmap
