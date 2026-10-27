extends RefCounted

static func moss(game: Node2D) -> void:
	var s=game.state
	var choices=[
		["I need some copper. Any idea where I could find some?",func(): copper(game)],
		["Where can I learn more about the town?",func(): game.dialog("Moss","A GOOD PLACE TO START","Have a look at the bulletin board in town square. Folks pin up jobs, lost things, little bits of news. And if something doesn't make sense, come ask me. I've been here all my life; my family was here long before that.")]]
	if s.firewood_requested and not s.firewood_given:
		choices.append(["Where can I find an axe to gather wood?",func(): game.dialog("Moss","ROWAN'S WOODS","Go south from my farm and follow the faint path into the woods. Rowan's cabin is just west of Bram's. She knows a good tree from a tired one, and she may have an axe to spare. Tell her what you need it for.")])
	if s.ladder_requested or s.ladder_clue:
		choices.append(["Have you seen Mrs. Bell's missing ladder?",func(): game.dialog("Moss","A LADDER WITH LEGS","Mara can be a touch forgetful when she's got a machine on her mind. I'd be surprised if that ladder had wandered very far from their property. Her daughter likes climbing up to fiddle with aerials, too. Might be worth asking around at home.")])
	choices.append(["Thanks, Moss. Have a good day.",func(): pass])
	game.dialog("Moss","AN OLD HAND AROUND HERE","How are you settling in? If there's something you need, ask away. Someone round here will know, even if I don't.",choices)

static func copper(game: Node2D) -> void:
	game.state.requests.copper_advice=true
	game.save_visit()
	game.dialog("Moss","BEFORE YOU GO UNDERGROUND","There's copper ore in the caves southeast of town. But listen: don't go down there without something to protect yourself. Rats, for a start, and worse things farther in. Go see Bram first. The old army fellow lives south of here, next door to Rowan the woodcutter. He may have something that would help.",[["And the garden?" if game.state.welcome_phase=="moss_lesson" else "Thanks. What else should I know?",func():
		if game.state.welcome_phase=="moss_lesson": game.moss_lesson()
		else: moss(game)]])

static func oren(game: Node2D) -> void:
	var s=game.state
	var choices=[]
	if not s.firewood_given:
		choices.append(["I heard you are in need of some firewood?",func():
			s.accept_firewood_task()
			game.save_visit()
			var replies=[]
			if s.wood>=6:
				replies.append(["I've brought six logs for you.",func():
					if s.deliver_firewood():
						game.save_visit()
						game.dialog("Oren","A WARM WESTERN LIGHT","Ah, that's the stuff! Thank you. Here's my spare fishing pole, and twenty-five crowns. Good line on it, plenty of life left. A fishing pole's good for a few extra coins in your pocket and food in your belly. Come warm your hands any time.")
					else: game.toast("Make a little room for the fishing pole, and keep six logs ready.")])
			if not s.woodcutter_axe_given and s.axe<1:
				replies.append(["I'd get some for you, but I don't have an axe.",func(): axe_directions(game)])
			else: replies.append(["I'll bring you some.",func(): axe_directions(game)])
			game.dialog("Oren","A FAVOR FOR THE KEEPER","I am, yes. Six logs would keep the stove going nicely. I'd cut them myself, but these old knees have had enough of that sort of work. If you could help, I've an old fishing pole around the house and a few coins I could spare.",replies)])
	if not s.firewood_requested or s.firewood_given:
		choices.append(["Any advice for fishing out here?",func(): game.dialog("Oren","OUT BEYOND THE BREAKERS","Sprats and mackerel along the shore. An eel if it's feeling disagreeable. Walk to the sea end of the jetty after dark and you might see a little gold light below the water. Lantern rays. Hard to land, those.")])
		choices.append(["Have a nice day, Oren.",func(): pass])
	game.dialog("Oren","KEEPER OF THE WESTERN LIGHT","Well now, a visitor! Come in out of the wind. How are you getting along?" if not s.firewood_given else "Good to see you again. Warm in here, thanks to you. How's life up at the farmhouse?",choices)

static func axe_directions(game: Node2D) -> void:
	game.dialog("Oren","A POLE AND A PROMISE","Visit Rowan, the woodcutter south of old farmer Moss's house. She may be able to help you with an axe. Bring me six logs and I'll have that fishing pole and twenty-five crowns ready. A fishing pole's good for a few extra coins in your pocket and food in your belly.")

static func rowan(game: Node2D) -> void:
	var s=game.state
	s.requests.update_deadline(s)
	var choices=[]
	if not s.woodcutter_axe_given:
		choices.append(["I'll bring you ten logs in one week. May I take the axe?",func(): game.offer_tool("axe","Rowan")])
	elif not s.requests.axe_paid:
		choices.append(["Here are the ten logs I owe you.",func():
			if s.repay_axe():
				game.save_visit()
				game.dialog("Rowan","A PROMISE KEPT", "Late, but you brought them. Thank you. Next time, tell me if a promise is going to take longer." if s.requests.axe_failed else "Good timber, too. Thank you for keeping your word. That axe is yours; look after the edge and it'll look after you.")
			else: game.dialog("Rowan","TEN LOGS","Ten logs, when you've got them together. I need the whole bundle for the job."),s.wood>=10])
	choices.append(["How do you choose which trees to cut?",func(): game.dialog("Rowan","A FOREST THAT LASTS","Look up first. Then look at the roots. I mark the old and crowded trees and leave the rest room to grow. My mother taught me these woods. I'd like somebody else's daughter to know them too.")])
	choices.append(["I'll leave you to it.",func(): pass])
	var body="I've a spare axe you can keep. One condition: bring me ten logs in one week, seven days. I've a job waiting on the timber. Does that sound fair?" if not s.woodcutter_axe_given else "You've kept the axe in good shape, I hope. Remember our agreement: ten logs within one week, seven days." if not s.requests.axe_paid else "Hello again. Mind the saplings if you're cutting today. Give them a few years yet."
	if s.requests.axe_failed and not s.requests.axe_paid: body="I needed those ten logs last week. If you give your word, I expect you to keep it. Keep the axe, but bring me what you owe."
	game.dialog("Rowan","FOREST WOODCUTTER",body,choices)

static func bram(game: Node2D) -> void:
	var choices=[]
	if not game.state.has_sword():
		choices.append(["I'm going into the mines for copper. Moss thought you might have something to protect me." if game.state.requests.copper_advice else "Have you got a weapon I could take into the mines?",func(): sword_terms(game)])
	choices.append(["What should we know about Veyr?",func(): game.dialog("Bram","RETIRED ARMY","Don't let a uniform do your thinking for you. I learned that rather late. A family in Veyr hid me in their cellar for three nights. No reason to help an Aldermere soldier, and they did it anyway. I still think about them.")])
	choices.append(["Take care, Bram.",func(): pass])
	game.dialog("Bram","A CABIN IN THE SOUTH WOODS","Come in. Mind the boots by the door. Aldermere's army had me for a good many years; these days a quiet fire and something decent for dinner suit me fine.",choices)

static func sword_terms(game: Node2D) -> void:
	game.state.requests.bram_requested=true
	game.save_visit()
	game.dialog("Bram","SOMETHING TO KEEP THE RATS BACK","Bram raises his eyebrows and gives a low whistle. 'The mines? Rats down there, and things I'd rather not meet in the dark. I've an old sword. Bit rusty, but sound. Bring me three moon turnips for dinner and it's yours.'",[
		["Trade three moon turnips for the sword",func():
			if game.state.accept_sword(): game.save_visit(); game.dialog("Bram","A FAIR TRADE","Lovely. That'll make a proper supper. Here's the sword. Keep it between you and anything with too many teeth.")
			else: game.dialog("Bram","WHEN THEY'RE READY","Three moon turnips, and a little room to carry the sword. I'm in no hurry for dinner."),game.state.turnips>=3],
		["I've some turnips in the ground. I'm waiting for them to grow.",func(): game.dialog("Bram","A TRICK OR TWO","Go see Iona. She might teach you a useful trick or two to hurry them along. She's a night owl, so don't try her too early. Tower north of town, a little east of Saeren the astronomer's place. You'll know it when you see it.")],
		["I'll come back with dinner.",func(): pass]])

static func smith_copper(game: Node2D) -> void:
	var at_work=game.shopkeeper_at_work("smith","smithy")
	if not at_work:
		game.dialog("Dain Rusk","COPPER AND COMMON SENSE","The southeast caves have copper, but take something to defend yourself. Ask Moss or Bram if you need advice. Come by the forge when I'm working and we can talk equipment.")
		return
	game.dialog("Dain Rusk","COPPER AND COMMON SENSE","Southeast caves. Plenty of copper ore if you know what to look for, but don't go in without a way to protect yourself. Even the rats can make a mess of an unprepared traveler. I've a serviceable rusty sword at the forge. One thousand crowns.",[
		["Buy rusty sword · 1,000 crowns",func():
			if game.state.buy_sword(): game.save_visit(); game.dialog("Dain Rusk","GOOD STEEL UNDER THE RUST","There you are. Keep the edge clean and don't let yourself get cornered.")
			else: game.toast("You need 1,000 crowns, room for the sword, and no sword already stored."),at_work and game.state.money>=1000 and not game.state.has_sword()],
		["There's no way I could afford that right now.",func(): game.dialog("Dain Rusk","ASK AROUND","Fair enough. Ask Moss. Or the old veteran, Bram, down in the woods. He's been putting off clearing out his army kit for years. Might be something the two of you could work out.")],
		["Thanks for the warning.",func(): pass]])
