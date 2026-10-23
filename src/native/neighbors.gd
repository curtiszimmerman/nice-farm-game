extends RefCounted

const PEOPLE=[
	{"id":"astronomer","name":"Saeren","role":"MASTER OBSERVER","cell":Vector2i(31,14),"coat":"586b9b","hair":"d0cdc4","skin":"b3927d"},
	{"id":"farmer_mother","name":"Elin Reed","role":"ORCHARD GRAFTER","cell":Vector2i(103,47),"coat":"a88558","hair":"41332d","skin":"a77b59"},
	{"id":"farmer_father","name":"Jory Reed","role":"EAST FARMER","cell":Vector2i(104,47),"coat":"71855b","hair":"775439","skin":"c59a76"},
	{"id":"farmer_son","name":"Pip Reed","role":"YOUNG SEED COLLECTOR","cell":Vector2i(105,47),"coat":"ad6051","hair":"775439","skin":"b88c67"},
	{"id":"smith","name":"Dain Rusk","role":"BLACKSMITH","cell":Vector2i(79,48),"coat":"886447","hair":"aaa59b","skin":"79513e"},
	{"id":"miller","name":"Tomas Bell","role":"MILLER","cell":Vector2i(90,29),"coat":"b5a47b","hair":"594536","skin":"c29672"},
	{"id":"miller_wife","name":"Mara Bell","role":"MRS. BELL · MILLWRIGHT","cell":Vector2i(99,31),"coat":"618398","hair":"a8754d","skin":"d2a17f"},
	{"id":"miller_daughter","name":"Nessa Bell","role":"RADIO ENTHUSIAST","cell":Vector2i(98,31),"coat":"8f7098","hair":"594536","skin":"bc9479"},
	{"id":"barkeep","name":"Rafe Fen","role":"KEEPER OF THE WAYWARD WREN","cell":Vector2i(69,38),"coat":"846652","hair":"65503b","skin":"bd8e6c"},
	{"id":"baker","name":"Corin Hale","role":"BAKER","cell":Vector2i(75,65),"coat":"d8cdb0","hair":"a46843","skin":"d2aa83"},
	{"id":"woodcutter","name":"Rowan","role":"FOREST WOODCUTTER","cell":Vector2i(29,79),"coat":"59764d","hair":"8d4e36","skin":"b98b67"}
]
const BUILDINGS=[
	{"cell":Vector2i(28,10),"tiles":Vector2i(6,4),"roof":"65808c","kind":"observatory","visual_height":224},
	{"cell":Vector2i(100,42),"tiles":Vector2i(7,5),"roof":"9d6c4b","kind":"reed_farm"},
	{"cell":Vector2i(88,24),"tiles":Vector2i(5,5),"roof":"827058","kind":"windmill","visual_height":240},
	{"cell":Vector2i(96,27),"tiles":Vector2i(6,4),"roof":"8e6659","kind":"mill_home"},
	{"cell":Vector2i(105,28),"tiles":Vector2i(4,3),"roof":"686879","kind":"mill_shed"},
	{"cell":Vector2i(76,43),"tiles":Vector2i(6,5),"roof":"686879","kind":"smithy"},
	{"cell":Vector2i(66,33),"tiles":Vector2i(7,5),"roof":"965d51","kind":"tavern"},
	{"cell":Vector2i(72,61),"tiles":Vector2i(6,4),"roof":"b68a58","kind":"bakery"},
	{"cell":Vector2i(27,75),"tiles":Vector2i(4,4),"roof":"78644d","kind":"cabin","resident":"woodcutter"}
]
const FIELDS=[Rect2i(99,50,5,6),Rect2i(106,50,5,6)]
const BENCHES=[Vector2i(59,44),Vector2i(62,44)]
const FLOWERS=[Vector2i(58,46),Vector2i(58,47),Vector2i(65,46),Vector2i(65,47),Vector2i(62,50)]
const ROUTES=[
	[Vector2i(69,38),Vector2i(64,38),Vector2i(64,44)],
	[Vector2i(79,48),Vector2i(79,50),Vector2i(72,50),Vector2i(72,57)],
	[Vector2i(75,65),Vector2i(75,67),Vector2i(83,67),Vector2i(83,57)],
	[Vector2i(67,44),Vector2i(74,44),Vector2i(74,39),Vector2i(85,39),Vector2i(85,30),Vector2i(90,30),Vector2i(90,29)],
	[Vector2i(90,30),Vector2i(94,30),Vector2i(94,33),Vector2i(99,33),Vector2i(99,31)],
	[Vector2i(85,39),Vector2i(97,39),Vector2i(97,48),Vector2i(103,48),Vector2i(103,47)]
]
const NAMES={"observatory":"Saeren's observatory","reed_farm":"Reed family farm","windmill":"Bell's windmill","mill_home":"Bell family home","smithy":"Dain's smithy","tavern":"The Wayward Wren","bakery":"Corin's bakery","woodcutter":"Rowan's cabin"}
const STORIES={
	"astronomer":"Saeren|You came from the stars. No, don't look so alarmed. I was at the eyepiece when your light crossed the sky. It turned against the fall, twice. Stones don't do that. I don't pretend to understand what carried you, but I've spent fifty years learning the difference between what I see and what I expect to see. Your secret is safe in this room.",
	"woodcutter":"Rowan|My mother taught me these woods. I'd like somebody else's daughter to know them too.",
	"farmer_mother":"Elin Reed|Grafting trees is mostly persuading two stubborn things to get along. Jory says that's how we met. We brought a handful of cuttings when the river took our old orchard. Corin kept them alive in his warm back room that first winter. These trees have quite a few people to thank.",
	"farmer_father":"Jory Reed|Elin and I run the farm east of town. A flood took our old place, so we moved here with Pip and started again. Moss helped us clear these fields. We grow vegetables for Corin's bakery now, and a little grain for Tomas to mill. It's good soil. We're doing all right.",
	"farmer_son":"Pip Reed|I label all my seed jars now. Last time I didn't, we grew squash in the flower pots. Mum says that still counts as an experiment. Nessa lets me listen to faraway stations sometimes. Do you think they grow the same things on the other side of the sea?",
	"smith":"Dain Rusk|Mind the scale on the floor. Hotter than it looks. I used to make hinges for canal gates, until the foundry decided swords paid better. I left. A good hinge lets someone through a door for fifty years. Hard to improve on that sort of work. Bring your tools by sometime; I like seeing honest wear.",
	"miller":"Tomas Bell|Mara rebuilt the gearing after the old mill seized. I put the kettle on, which I maintain was essential work. Rafe and I used to race sacks down this hill as boys. Now he keeps a tavern, I grind the grain, and Corin tells us both when we've been talking too long. Some things improve with age.",
	"miller_wife":"Mara Bell|Hear that? A little knock every fourth turn. Nothing dangerous, but I'll find it. I learned millwrighting on a river barge. Tomas wrote to ask about a replacement cog and kept writing after I sent it. Eventually I came to see whether the mill was really as charming as he claimed.",
	"miller_daughter":"Nessa Bell|The mill's got a rhythm, once you've listened long enough. So does a radio signal. Finch is helping me build a receiver from a cracked valve and an old clock case. I'd like Mum to hear the river weather reports she grew up with. Afternoons are best, before the club gets noisy.",
	"barkeep":"Rafe Fen|Welcome to the Wayward Wren. Tomas and I meant to see the whole world when we were young. He got as far as the mill; I got as far as this bar. Plenty of the world comes through here, though. Corin brings the morning bread and stays to hear who's arrived. Save him a chair and he'll introduce you to half the valley.",
	"baker":"Corin Hale|You're just in time. Well, I say that to everyone, but there's usually something warm. Tomas brings the flour, the Reeds bring whatever's plentiful, Moss brings opinions about the weather, and Rafe brings my baskets back eventually. I started baking after my hearing began to go. People will tell you their whole lives while waiting for a loaf. Pull up a stool."
}
const WORKPLACES={"astronomer":"observatory","smith":"smithy","miller":"windmill","miller_wife":"windmill","miller_daughter":"radio","barkeep":"tavern","baker":"bakery"}
const OFF_DUTY={
	"astronomer":"A little air before the night's work. You see those pale streaks above the ridge? Most people call them clouds. Through the telescope they're quite another thing. Come up to the observatory sometime. There are matters best discussed away from the square.",
	"farmer_mother":"Lovely to have a moment away from the fields. Pip has been trying to persuade me that three seed jars count as suitable supper-table decoration. You can guess how that's going.",
	"farmer_father":"Elin's got the orchard in hand, so I can spare a little time for town. Corin's promised to save us a loaf. You'd think after all these years I'd know when to arrive before he sells out.",
	"farmer_son":"I'm off duty. That's what Dad calls it when he comes into town, so I thought I'd try. Have you seen Nessa? I found a seed that looks just like a tiny radio valve.",
	"smith":"No hammering for a little while. My shoulders have earned a walk.",
	"miller":"Rafe still owes me a rematch at draughts. He says the last board was uneven. Funny how it only tilts when he's losing.",
	"miller_wife":"I used to spend all my spare hours watching the river from the barge. Now a quiet walk and a visit to the bakery suit me nicely. Tomas says I can hear a bad gear from here. He's not entirely wrong.",
	"miller_daughter":"No receiver under my arm for once. Finch says a good radio operator occasionally has to talk to people in the same room. I'm practising.",
	"barkeep":"Corin claims I'm his best customer. I suspect he tells everyone that. Tomas and I used to spend our pocket money here before either of us had the sense to save any. Still not sure we've learned.",
	"baker":"A whole stretch of time when nobody needs me to check an oven. Feels odd, doesn't it? Rafe has a stool waiting, and Tomas will have some story about the mill. Come along if you've nothing pressing."
}

static func talk(game: Node2D,id: String) -> bool:
	if not STORIES.has(id): return false
	var story=STORIES[id].split("|",true,1)
	var working=game.current_room==WORKPLACES.get(id,"unused")
	if id.begins_with("farmer_"): working=game.world==game.outdoors and game.state.player_position.x>95*32
	var text=story[1] if working else OFF_DUTY.get(id,story[1])
	var choices=[]
	if id=="miller_wife":
		if game.state.ladder_returned: text="There you are! That ladder's back where it belongs. Next time Nessa needs to borrow it, she can try asking."
		elif game.state.ladder>0:
			choices.append(["I found your ladder.",game.return_bell_ladder])
		else: choices.append(["I heard you're missing a ladder?",game.ask_bell_ladder])
	if id=="miller_daughter" and not game.state.ladder_returned:
		choices.append(["Have you seen your mother's ladder?",func():
			game.state.ladder_requested=true
			game.dialog("Nessa Bell","A BORROWED LADDER","Oh. Mum noticed? I needed it to get the aerial above the shed roof. Meant to put it back before she missed it. It's leaning inside our tool shed, east of the house. Would you take it back? I'll go and apologise.")
		])
	if id=="baker" and working:
		choices=[["Buy fresh bread · 6 crowns · %s energy" % str(game.state.energy_recovery(game.state.Items.FOOD.bread.energy)),game.buy_bread],["Nothing today, thank you.",func(): pass]]
	game.dialog(story[0],PEOPLE.filter(func(p):return p.id==id)[0].role,text,choices)
	return true
