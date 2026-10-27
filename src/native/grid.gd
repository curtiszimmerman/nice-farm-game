extends RefCounted

const TILE_SIZE = 32
const MAP_SIZE = Vector2i(120,90)
const WORLD_SIZE = Vector2(MAP_SIZE.x*TILE_SIZE,MAP_SIZE.y*TILE_SIZE)
const WORLD_CELLS=Rect2i(-28,0,MAP_SIZE.x+28,MAP_SIZE.y)
const PLAYABLE_CELLS = Rect2i(-27,4,MAP_SIZE.x+25,MAP_SIZE.y-6)
const SPAWN_CELL = Vector2i(13,45)
const BUILD_AREA=Rect2i(25,49,12,8)
const FARMHOUSE=Rect2i(10,39,7,5)
const BUILD_RADIUS=15

static func near_farmhouse(cell: Vector2i) -> bool:
	var nearest=Vector2i(clampi(cell.x,FARMHOUSE.position.x,FARMHOUSE.end.x-1),clampi(cell.y,FARMHOUSE.position.y,FARMHOUSE.end.y-1))
	return contains(cell) and Vector2(cell).distance_to(nearest)<=BUILD_RADIUS

static func world_to_cell(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x/TILE_SIZE),floori(point.y/TILE_SIZE))

static func origin(cell: Vector2i) -> Vector2:
	return Vector2(cell)*TILE_SIZE

static func center(cell: Vector2i) -> Vector2:
	return origin(cell)+Vector2.ONE*TILE_SIZE*0.5

static func rect(cell: Vector2i,tiles: Vector2i) -> Rect2:
	return Rect2(origin(cell),Vector2(tiles)*TILE_SIZE)

static func contains(cell: Vector2i) -> bool:
	return WORLD_CELLS.has_point(cell)
