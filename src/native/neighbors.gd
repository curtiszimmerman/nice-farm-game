extends RefCounted

const PEOPLE=[
	{"id":"farmer_mother","name":"Elin Reed","role":"ORCHARD GRAFTER","cell":Vector2i(103,47),"coat":"a88558","hair":"41332d","skin":"a77b59"},
	{"id":"farmer_father","name":"Jory Reed","role":"EAST FARMER","cell":Vector2i(104,47),"coat":"71855b","hair":"775439","skin":"c59a76"},
	{"id":"farmer_son","name":"Pip Reed","role":"YOUNG SEED COLLECTOR","cell":Vector2i(105,47),"coat":"ad6051","hair":"775439","skin":"b88c67"},
	{"id":"smith","name":"Dain Rusk","role":"BLACKSMITH","cell":Vector2i(79,48),"coat":"886447","hair":"aaa59b","skin":"79513e"},
	{"id":"miller","name":"Tomas Bell","role":"MILLER","cell":Vector2i(90,29),"coat":"b5a47b","hair":"594536","skin":"c29672"},
	{"id":"miller_wife","name":"Mara Bell","role":"MILLWRIGHT","cell":Vector2i(99,31),"coat":"618398","hair":"a8754d","skin":"d2a17f"},
	{"id":"miller_daughter","name":"Nessa Bell","role":"RADIO ENTHUSIAST","cell":Vector2i(98,31),"coat":"8f7098","hair":"594536","skin":"bc9479"},
	{"id":"barkeep","name":"Rafe Fen","role":"KEEPER OF THE WAYWARD WREN","cell":Vector2i(69,38),"coat":"846652","hair":"65503b","skin":"bd8e6c"},
	{"id":"baker","name":"Corin Hale","role":"BAKER","cell":Vector2i(75,65),"coat":"d8cdb0","hair":"a46843","skin":"d2aa83"}
]
const BUILDINGS=[
	{"cell":Vector2i(100,42),"tiles":Vector2i(7,5),"roof":"9d6c4b","kind":"reed_farm"},
	{"cell":Vector2i(88,24),"tiles":Vector2i(5,5),"roof":"827058","kind":"windmill","visual_height":240},
	{"cell":Vector2i(96,27),"tiles":Vector2i(6,4),"roof":"8e6659","kind":"mill_home"},
	{"cell":Vector2i(76,43),"tiles":Vector2i(6,5),"roof":"686879","kind":"smithy"},
	{"cell":Vector2i(66,33),"tiles":Vector2i(7,5),"roof":"965d51","kind":"tavern"},
	{"cell":Vector2i(72,61),"tiles":Vector2i(6,4),"roof":"b68a58","kind":"bakery"}
]
const FIELDS=[Rect2i(99,50,5,6),Rect2i(106,50,5,6)]
const BENCHES=[Vector2i(59,44),Vector2i(62,44)]
const FLOWERS=[Vector2i(58,46),Vector2i(58,47),Vector2i(65,46),Vector2i(65,47),Vector2i(60,50),Vector2i(62,50)]
const ROUTES=[
	[Vector2i(69,38),Vector2i(64,38),Vector2i(64,44)],
	[Vector2i(79,48),Vector2i(79,50),Vector2i(72,50),Vector2i(72,57)],
	[Vector2i(75,65),Vector2i(75,67),Vector2i(83,67),Vector2i(83,57)],
	[Vector2i(67,44),Vector2i(74,44),Vector2i(74,39),Vector2i(85,39),Vector2i(85,30),Vector2i(90,30),Vector2i(90,29)],
	[Vector2i(90,30),Vector2i(94,30),Vector2i(94,33),Vector2i(99,33),Vector2i(99,31)],
	[Vector2i(85,39),Vector2i(97,39),Vector2i(97,48),Vector2i(103,48),Vector2i(103,47)]
]
const NAMES={"reed_farm":"Reed family farm","windmill":"Bell's windmill","mill_home":"Bell family home","smithy":"Dain's smithy","tavern":"The Wayward Wren","bakery":"Corin's bakery"}
const STORIES={
	"farmer_mother":"Elin Reed|Grafting trees is mostly persuading two stubborn things to get along. Jory says that's how we met. We brought a handful of cuttings when the river took our old orchard. Corin kept them alive in his warm back room that first winter. These trees have quite a few people to thank.",
	"farmer_father":"Jory Reed|The river changed its mind one spring and planted itself in our house. Elin saved the cuttings; Pip saved a jar of seeds. We came here with wet boots and those two treasures. Moss helped us turn this eastern soil. Now I send flour money to Tomas and vegetables to Corin. Seems fair to keep things moving.",
	"farmer_son":"Pip Reed|I label all my seed jars now. Last time I didn't, we grew squash in the flower pots. Mum says that still counts as an experiment. Nessa lets me listen to faraway stations sometimes. Do you think they grow the same things on the other side of the sea?",
	"smith":"Dain Rusk|Mind the scale on the floor. Hotter than it looks. I used to make hinges for canal gates, until the foundry decided swords paid better. I left. A good hinge lets someone through a door for fifty years. Hard to improve on that sort of work. Bring your tools by sometime; I like seeing honest wear.",
	"miller":"Tomas Bell|Mara rebuilt the gearing after the old mill seized. I put the kettle on, which I maintain was essential work. Rafe and I used to race sacks down this hill as boys. Now he keeps a tavern, I grind the grain, and Corin tells us both when we've been talking too long. Some things improve with age.",
	"miller_wife":"Mara Bell|Hear that? A little knock every fourth turn. Nothing dangerous, but I'll find it. I learned millwrighting on a river barge. Tomas wrote to ask about a replacement cog and kept writing after I sent it. Eventually I came to see whether the mill was really as charming as he claimed.",
	"miller_daughter":"Nessa Bell|The mill's got a rhythm, once you've listened long enough. So does a radio signal. Finch is helping me build a receiver from a cracked valve and an old clock case. I'd like Mum to hear the river weather reports she grew up with. Afternoons are best, before the club gets noisy.",
	"barkeep":"Rafe Fen|Welcome to the Wayward Wren. Tomas and I meant to see the whole world when we were young. He got as far as the mill; I got as far as this bar. Plenty of the world comes through here, though. Corin brings the morning bread and stays to hear who's arrived. Save him a chair and he'll introduce you to half the valley.",
	"baker":"Corin Hale|You're just in time. Well, I say that to everyone, but there's usually something warm. Tomas brings the flour, the Reeds bring whatever's plentiful, Moss brings opinions about the weather, and Rafe brings my baskets back eventually. I started baking after my hearing began to go. People will tell you their whole lives while waiting for a loaf. Pull up a stool."
}

static func talk(game: Node2D,id: String) -> bool:
	if not STORIES.has(id): return false
	var story=STORIES[id].split("|",true,1)
	game.dialog(story[0],PEOPLE.filter(func(p):return p.id==id)[0].role,story[1])
	return true
