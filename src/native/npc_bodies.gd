extends RefCounted

const RADIUS=22.0

static func nearby(world: Node2D) -> Dictionary:
	var best={}
	var distance=55.0
	for id in world.villagers:
		var actor: Node2D=world.villagers[id]
		var d=world.state.player_position.distance_to(actor.position)
		if actor.visible and not actor.data.get("sleeping",false) and d<distance:
			best={"type":"person","id":id,"label":"Talk to "+actor.data.name}
			distance=d
	return best

static func player_step(world: Node2D,delta: Vector2,holds: Dictionary) -> bool:
	var target=world.state.player_position+delta
	if world.blocked(target): return false
	var pushes={}
	for id in world.villagers:
		var actor: Node2D=world.villagers[id]
		if not actor.visible or actor.data.get("sleeping",false): continue
		if target.distance_to(actor.position)>=RADIUS: continue
		if holds.has(id): return false
		var direction=(actor.position-target).normalized()
		if direction.is_zero_approx(): direction=delta.normalized()
		var displaced=target+direction*RADIUS
		if world.blocked(displaced): return false
		for other in world.villagers.values():
			if other!=actor and other.visible and displaced.distance_to(other.position)<RADIUS: return false
		pushes[id]=displaced
	for id in pushes:
		world.villagers[id].position=pushes[id]
		world.routes.erase(id)
	world.state.player_position=target
	return true

static func step(world: Node2D,actor: Node2D,target: Vector2,distance: float) -> Vector2:
	var next=actor.position.move_toward(target,distance)
	if world.state.location!=(world.building.id if world.get("building")!=null else ""): return next
	if next.distance_to(world.state.player_position)>=RADIUS: return next
	return actor.position
