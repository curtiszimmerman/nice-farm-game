extends RefCounted

const CATALOG={
	"wildgrowth":{"name":"Wildgrowth","description":"Hasten a watered crop. Costs 15 mana.","kind":"Spell"},
	"sit":{"name":"Sit","description":"Take a seat on a nearby town bench.","kind":"Skill"}
}

static func known(state: RefCounted,id: String) -> bool:
	return id=="sit" or (id=="wildgrowth" and state.magic_learned)

static func learned(state: RefCounted) -> Array:
	return CATALOG.keys().filter(func(id): return known(state,id))
