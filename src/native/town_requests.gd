extends RefCounted

const POOL=[
	["tavi","fish",5,35], ["miller_wife","berries",5,25], ["astronomer","star_bulbs",5,40],
	["moss","turnips",3,24], ["baker","berries",5,25], ["farmer_mother","turnips",4,28],
	["farmer_father","wood",6,24], ["farmer_son","apples",3,24], ["iona","star_bulbs",4,36],
	["finch","copper",2,24], ["smith","coal",3,30], ["miller","wood",5,20],
	["barkeep","fish",3,24], ["priest","berries",4,20], ["keeper","wood",4,18],
	["veteran","turnips",3,24], ["woodcutter","stones",5,20], ["assistant","bread",2,20],
	["mayor","apples",4,32], ["miller_daughter","copper",2,24]]
const SUPPLIES={"fish":"pond silverfin","berries":"berries","star_bulbs":"star bulbs","turnips":"moon turnips","wood":"logs","apples":"apples","copper":"copper ore","coal":"coal","stones":"stone","bread":"loaves of bread"}
var axe_due=-1.0
var axe_paid=false
var axe_failed=false
var copper_advice=false
var bram_requested=false
var bram_traded=false
var week=-1
var jobs: Array=[]

static func quest_id(job: Dictionary) -> String: return "board_%d_%d"%[int(job.week),int(job.template)]
static func supplies(index: int) -> String: return "%d %s"%[POOL[index][2],SUPPLIES[POOL[index][1]]]

func eligible(state: RefCounted,index: int) -> bool:
	var item=POOL[index][1]
	if item=="berries" and state.season_name() not in ["spring","summer"]: return false
	if item=="apples" and state.season_name()!="autumn": return false
	if item=="fish" and not state.firewood_given: return false
	if item=="wood" and not state.woodcutter_axe_given: return false
	if item in ["stones","copper","coal"] and not state.cave_pickaxe_taken: return false
	return true

func refresh(state: RefCounted) -> void:
	var current=int((state.day-1)/7)
	if week!=current:
		for job in jobs:
			if job.status=="active": job.status="expired"
		jobs=jobs.filter(func(job):return job.status!="offered")
		week=current
	var capacity=4-(0 if state.firewood_given else 1)-(0 if state.ladder_returned else 1)
	var live=jobs.filter(func(job):return int(job.week)==week and job.status in ["offered","active"])
	if live.size()>=capacity: return
	var candidates=[]
	for index in range(POOL.size()):
		if eligible(state,index) and not jobs.any(func(job):return int(job.week)==week and int(job.template)==index): candidates.append(index)
	var rng=RandomNumberGenerator.new()
	rng.seed=hash("board:%d:%d"%[state.world_seed,week])
	while live.size()<capacity and not candidates.is_empty():
		var pick=rng.randi_range(0,candidates.size()-1)
		var job={"week":week,"template":candidates[pick],"status":"offered"}
		candidates.remove_at(pick)
		jobs.append(job)
		live.append(job)

func accept(state: RefCounted,id: String) -> bool:
	refresh(state)
	for job in jobs:
		if quest_id(job)==id and job.status=="offered":
			job.status="active"
			if id not in state.quest_order: state.quest_order.append(id)
			return true
	return false

func deliver(state: RefCounted,id: String,person: String) -> bool:
	refresh(state)
	for job in jobs:
		var request=POOL[int(job.template)]
		if quest_id(job)!=id or job.status!="active" or request[0]!=person: continue
		if int(state.get(request[1]))<request[2]: return false
		state.set(request[1],int(state.get(request[1]))-request[2])
		state.money+=request[3]
		state.change_friendship(person,3)
		state.clear_empty_slots()
		job.status="complete"
		return true
	return false

func update_deadline(state: RefCounted) -> void:
	if axe_due>=0 and not axe_paid and not axe_failed and state.total()>=axe_due:
		axe_failed=true
		state.change_friendship("woodcutter",-5)

func to_dict() -> Dictionary:
	return {"axe_due":axe_due,"axe_paid":axe_paid,"axe_failed":axe_failed,"copper_advice":copper_advice,"bram_requested":bram_requested,"bram_traded":bram_traded,"week":week,"jobs":jobs.duplicate(true)}

static func valid(data: Variant) -> bool:
	if not data is Dictionary: return false
	for field in ["axe_paid","axe_failed","copper_advice","bram_requested","bram_traded"]:
		if not data.get(field) is bool: return false
	if not preload("res://town_progress.gd").integer(data.get("week")) or data.week< -1: return false
	var due=data.get("axe_due")
	if not (due is int or due is float) or not is_finite(due) or (due!= -1 and due<0): return false
	if due== -1 and (data.axe_paid or data.axe_failed): return false
	if not data.get("jobs") is Array: return false
	var ids=[]
	for job in data.jobs:
		if not job is Dictionary: return false
		for field in ["week","template"]:
			if not preload("res://town_progress.gd").integer(job.get(field)): return false
		if job.week<0 or job.week>data.week or job.template<0 or job.template>=POOL.size(): return false
		if job.get("status") not in ["offered","active","complete","expired"]: return false
		var id=quest_id(job)
		if id in ids: return false
		ids.append(id)
	return true

func restore(data: Dictionary) -> void:
	axe_due=float(data.axe_due)
	axe_paid=data.axe_paid
	axe_failed=data.axe_failed
	copper_advice=data.copper_advice
	bram_requested=data.bram_requested
	bram_traded=data.bram_traded
	week=int(data.week)
	jobs=data.jobs.duplicate(true)
	for job in jobs:
		job.week=int(job.week)
		job.template=int(job.template)
