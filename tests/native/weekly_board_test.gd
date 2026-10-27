extends SceneTree
const State=preload("res://state.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func live(s: RefCounted) -> Array:
	return s.requests.jobs.filter(func(job):return job.status in ["offered","active"])
func _initialize() -> void:
	var s=State.new()
	s.world_seed=7331
	s.requests.refresh(s)
	check(live(s).size()==2,"the two permanent notices leave two weekly board positions")
	var before=s.requests.to_dict()
	s.requests.refresh(s)
	check(s.requests.to_dict()==before,"reopening the board cannot reroll its jobs")
	s.firewood_requested=true
	s.firewood_given=true
	s.ladder_returned=true
	s.ladder_requested=true
	s.ladder_taken=true
	s.requests.refresh(s)
	check(live(s).size()==4,"finished story requests free positions up to the four-notice limit")
	var job=live(s)[0]
	var id=s.requests.quest_id(job)
	var terms=s.requests.POOL[job.template]
	check(s.requests.accept(s,id) and not s.requests.accept(s,id),"a weekly request can be accepted once")
	s.set(terms[1],terms[2]-1)
	var money=s.money
	check(not s.requests.deliver(s,id,terms[0]) and s.money==money,"partial deliveries consume nothing and earn nothing")
	s.set(terms[1],terms[2])
	check(not s.requests.deliver(s,id,"vale"),"deliveries belong to the NPC who posted them")
	check(s.requests.deliver(s,id,terms[0]) and s.get(terms[1])==0 and s.money==money+terms[3] and s.friendships[terms[0]]==3,"complete deliveries pay crowns and friendship exactly once")
	check(not s.requests.deliver(s,id,terms[0]),"completed jobs cannot pay twice")
	s.requests.refresh(s)
	check(live(s).size()==4,"a completed job frees its board position")
	var next=live(s)[0]
	s.requests.accept(s,s.requests.quest_id(next))
	s.day=8
	s.requests.refresh(s)
	check(next.status=="expired" and live(s).all(func(entry):return int(entry.week)==1),"weekly refresh expires unfinished jobs and posts a fresh week")
	s.day=85
	check(not s.requests.eligible(s,1),"winter requests do not ask for spring and summer berries")
	var loaded=State.new()
	check(loaded.restore(JSON.parse_string(JSON.stringify(s.to_dict()))) and loaded.requests.to_dict()==s.requests.to_dict(),"offers, completed requests and expired history survive JSON saving")
	var bad=s.to_dict()
	bad.requests.jobs.append(bad.requests.jobs[0].duplicate())
	check(not loaded.restore(bad),"duplicate saved notices are rejected")
	quit(1 if failed else 0)
