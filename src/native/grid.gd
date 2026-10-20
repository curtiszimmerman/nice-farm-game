extends RefCounted

const TILE_SIZE = 32
const MAP_SIZE = Vector2i(120,90)
const WORLD_SIZE = Vector2(MAP_SIZE.x*TILE_SIZE,MAP_SIZE.y*TILE_SIZE)
const PLAYABLE_CELLS = Rect2i(3,4,MAP_SIZE.x-5,MAP_SIZE.y-6)
const SPAWN_CELL = Vector2i(13,45)

static func world_to_cell(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x/TILE_SIZE),floori(point.y/TILE_SIZE))

static func origin(cell: Vector2i) -> Vector2:
	return Vector2(cell)*TILE_SIZE

static func center(cell: Vector2i) -> Vector2:
	return origin(cell)+Vector2.ONE*TILE_SIZE*0.5

static func rect(cell: Vector2i,tiles: Vector2i) -> Rect2:
	return Rect2(origin(cell),Vector2(tiles)*TILE_SIZE)

static func contains(cell: Vector2i) -> bool:
	return Rect2i(Vector2i.ZERO,MAP_SIZE).has_point(cell)
