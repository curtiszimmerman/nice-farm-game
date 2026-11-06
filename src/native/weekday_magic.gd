extends RefCounted

const DAYS=["Rift","Bough","Ember","Gale","Tide","Gleam","Veil"]
const SCHOOLS=["nature","fire","air","water","light","darkness"]
const DEITIES=[
	["Oruven, the Unfinished","Oruven left a gap in the first sky so creation could keep surprising itself. Rift's violet spiral marks that opening. No two dawns promise the same blessing; sometimes a gift and its undoing arrive together."],
	["Thessil, Keeper of the Small Roots","Thessil sheltered the first seed beneath a fallen leaf. Bough's green leaf honors the patient work of living things. Roots answer readily today, while the wandering winds grow quiet."],
	["Avarren, the Banked Flame","Avarren carried a coal through the long cold in cupped hands. Ember's orange flame recalls warmth preserved and shared. Fire wakes easily under that care; water resists its shaping."],
	["Sivrel, the Unbound Feather","Sivrel loosened the knots that held the first clouds still. Gale's pale feather belongs to every traveler who has trusted an unseen current. Air answers freely, while growing things rest beneath it."],
	["Naeveth, Listener Below","Naeveth gathered the world's unspoken grief into deep pools and taught them to flow. Tide's blue wave remembers that release. Water magic runs strong; flames are harder to coax."],
	["Elunai, the Open Lantern","Elunai raised a lantern with no door, giving its light to strangers as readily as friends. Gleam's golden rays celebrate that welcome. Every school of magic shares a little of its strength."],
	["Vorisel, the Far Veil","Vorisel drew a dark veil beyond the last stars, sheltering mysteries that living eyes cannot bear. Veil's indigo eclipse reminds us how small our lamps are. Magic is quieter; neighbors gather in the temple to keep those lamps together."]]

static func chaos(day: int,world_seed: int) -> Dictionary:
	var rng=RandomNumberGenerator.new()
	rng.seed=hash("weekday:%s:%s"%[world_seed,day])
	return {"favored":SCHOOLS[rng.randi_range(0,SCHOOLS.size()-1)],"weakened":SCHOOLS[rng.randi_range(0,SCHOOLS.size()-1)],"collision":2.0 if rng.randf()<0.5 else 0.0}

static func strength(day: int,world_seed: int,school: String) -> float:
	if day==1: return 1.0
	var weekday=posmod(day-1,7)
	if weekday==0:
		var omen=chaos(day,world_seed)
		if omen.favored==omen.weakened and school==omen.favored: return omen.collision
		if school==omen.favored: return 1.5
		if school==omen.weakened: return 0.5
		return 1.0
	if weekday==5: return 1.15
	if weekday==6: return 0.85
	var favored=["","nature","fire","air","water"]
	var weakened=["","air","water","nature","fire"]
	if school==favored[weekday]: return 1.5
	if school==weakened[weekday]: return 0.5
	return 1.0

static func school_name(school: String) -> String:
	return {"nature":"growth","air":"wind"}.get(school,school)

static func day_effects(index: int) -> String:
	return ["Rift strengthens one kind of magic and weakens another. If both signs select the same kind, it can become twice as strong or fail entirely.","Bough strengthens growth magic and weakens wind magic.","Ember strengthens fire magic and weakens water magic.","Gale strengthens wind magic and weakens growth magic.","Tide strengthens water magic and weakens fire magic.","Gleam makes every kind of magic a little stronger.","Veil makes every kind of magic a little weaker."][index]

static func today_reading(day: int,world_seed: int) -> String:
	var weekday=posmod(day-1,7)
	if weekday!=0: return "Today is %s. %s" % [DAYS[weekday],day_effects(weekday)]
	if day==1: return "Today is Rift. All forms of magic are equally strong today; the signs are clear."
	var omen=chaos(day,world_seed)
	if omen.favored==omen.weakened: return "Today is Rift. The signs are clear: %s magic %s today." % [school_name(omen.favored),"is twice as strong" if omen.collision>1 else "will not answer at all"]
	return "Today is Rift. The signs are clear: %s magic is stronger, while %s magic is weaker." % [school_name(omen.favored),school_name(omen.weakened)]

static func forecast(day: int,world_seed: int) -> Dictionary:
	var weekday=posmod(day-1,7)
	var days_until=0 if weekday==0 else 7-weekday
	var target_day=day+days_until
	var confidence=1.0 if days_until==0 else 0.6+0.05*(6-days_until)
	var omen=chaos(target_day,world_seed)
	var rng=RandomNumberGenerator.new()
	rng.seed=hash("rift-forecast:%d:%d" % [world_seed,target_day])
	if rng.randf()>=confidence:
		omen.favored=SCHOOLS[(SCHOOLS.find(omen.favored)+rng.randi_range(1,SCHOOLS.size()-1))%SCHOOLS.size()]
		omen.weakened=SCHOOLS[(SCHOOLS.find(omen.weakened)+rng.randi_range(1,SCHOOLS.size()-1))%SCHOOLS.size()]
	return {"target_day":target_day,"days_until":days_until,"confidence":confidence,"omen":omen}
