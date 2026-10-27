extends RefCounted

const CATALOG={
	"hearthmend":{"name":"Hearthmend","description":"A small warmth that closes wounds. Restore 15 HP for 10 mana.","kind":"Spell"},
	"emberthread":{"name":"Emberthread","description":"Cast a narrow tongue of fire ahead. Deals 2 damage for 12 mana.","kind":"Spell"},
	"build_crucible":{"name":"Crucible blueprint","description":"Build a one-square stone crucible on clear ground within fifteen squares of your farmhouse. Costs 10 stone.","kind":"Blueprint"},
	"wildgrowth":{"name":"Wildgrowth","description":"Hasten a watered crop. Costs 15 mana.","kind":"Spell"},
	"sit":{"name":"Sit","description":"Take a seat on a nearby town bench.","kind":"Skill"}
}

static func known(state: RefCounted,id: String) -> bool:
	return id in state.learned_spells or id=="sit" or (id=="wildgrowth" and state.magic_learned) or (id=="build_crucible" and state.crucible_known)

static func learned(state: RefCounted) -> Array:
	return CATALOG.keys().filter(func(id): return id!="sit" and known(state,id))
