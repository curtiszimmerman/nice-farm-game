extends RefCounted

const NEIGHBORS=[
	[Vector2i.UP,1],[Vector2i.RIGHT,2],[Vector2i.DOWN,4],[Vector2i.LEFT,8],
	[Vector2i(1,-1),16],[Vector2i(1,1),32],[Vector2i(-1,1),64],[Vector2i(-1,-1),128]
]
const MATERIALS=["dirt","pond","ocean","cliff","soil","tilled","cave"]

static func rect_cells(bounds: Rect2i) -> Dictionary:
	var cells={}
	for y in range(bounds.position.y,bounds.end.y):
		for x in range(bounds.position.x,bounds.end.x): cells[Vector2i(x,y)]=true
	return cells

static func normalize(raw: int) -> int:
	var result=raw&255
	for corner in [[3,16],[6,32],[12,64],[9,128]]:
		if (result&corner[0])!=corner[0]: result&=~corner[1]
	return result

static func mask(cells: Dictionary,cell: Vector2i) -> int:
	var result=0
	for neighbor in NEIGHBORS:
		if cells.has(cell+neighbor[0]): result|=neighbor[1]
	return normalize(result)

static func variant(cell: Vector2i,seed_value: int) -> int:
	return posmod(hash(Vector3i(cell.x,cell.y,seed_value)),4)

static func sprite_id(material: String,connection: int,season: String,weather: String,variation: int) -> String:
	return "tile_border_%s_m%d_%s_%s_%d" % [material,normalize(connection),season,weather,variation]

static func surface_id(material: String,season: String,weather: String,variation: int) -> String:
	return "tile_border_%s_fill_%s_%s_%d" % [material,season,weather,variation]
