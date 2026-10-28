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
	if world.blocked(next): return actor.position
	for other in world.villagers.values():
		if other!=actor and other.visible and next.distance_to(other.position)<RADIUS: return actor.position
	if world.state.location!=(world.building.id if world.get("building")!=null else ""): return next
	if next.distance_to(world.state.player_position)>=RADIUS: return next
	return actor.position

static func facing_for(motion: Vector2) -> String:
	return ("right" if motion.x>0 else "left") if absf(motion.x)>absf(motion.y) else ("down" if motion.y>0 else "up")

static func walk_to(world: Node2D,id: String,cell: Vector2i,dt: float,speed: float) -> bool:
	var actor: Node2D=world.villagers[id]
	var target=world.Grid.center(cell)
	var player_cell=world.Grid.world_to_cell(world.state.player_position)
	var route: Dictionary=world.routes.get(id,{})
	var changed=route.is_empty() or route.target!=target
	var retry=not route.is_empty() and route.path.is_empty() and route.get("blocked",false)
	if changed or retry:
		var start=world.Grid.world_to_cell(actor.position)
		var anchor=world.Grid.center(start)
		if not route.is_empty() and not route.path.is_empty():
			anchor=route.path[0]
			start=world.Grid.world_to_cell(anchor)
		var path: Array=world._route(start,cell,true,true,actor)
		if actor.position.distance_to(anchor)>0.1: path.push_front(anchor)
		route={"target":target,"path":path,"player_cell":player_cell,"blocked":path.is_empty() and actor.position.distance_to(target)>1}
		world.routes[id]=route
	var previous=actor.position
	var remaining=dt*speed
	while remaining>0 and not route.path.is_empty():
		var waypoint: Vector2=route.path[0]
		var distance=actor.position.distance_to(waypoint)
		var next=step(world,actor,waypoint,remaining)
		if next==actor.position and distance>0.1:
			var path: Array=world._route(world.Grid.world_to_cell(actor.position),cell,true,true,actor)
			# Replan once for an obstruction, then wait for it to move.
			route.path=path
			route.player_cell=player_cell
			route.blocked=true
			if not path.is_empty() and path[0]==waypoint: route.path=[]
			break
		actor.position=next
		remaining-=distance
		if actor.position.distance_to(waypoint)<0.1: route.path.pop_front()
	var motion=actor.position-previous
	actor.data.walking=motion.length()>0.01
	if not motion.is_zero_approx(): actor.data.direction=facing_for(motion)
	actor.queue_redraw()
	return actor.position.distance_to(target)<1
