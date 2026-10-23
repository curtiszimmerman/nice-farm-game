extends RefCounted

const CATALOG={
	"build_crucible":{"name":"Crucible blueprint","description":"Build a one-square stone crucible in the yard east of your garden. Costs 10 stone.","kind":"Blueprint"},
	"wildgrowth":{"name":"Wildgrowth","description":"Hasten a watered crop. Costs 15 mana.","kind":"Spell"},
	"sit":{"name":"Sit","description":"Take a seat on a nearby town bench.","kind":"Skill"}
}

static func known(state: RefCounted,id: String) -> bool:
	return id=="sit" or (id=="wildgrowth" and state.magic_learned) or (id=="build_crucible" and state.crucible_known)

static func learned(state: RefCounted) -> Array:
	return CATALOG.keys().filter(func(id): return id!="sit" and known(state,id))
