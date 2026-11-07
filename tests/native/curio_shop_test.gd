extends SceneTree
const Game=preload("res://game.gd")
const State=preload("res://state.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")

func buttons(game: Node2D) -> Array:
	return game.ui.modal_box.find_children("*","Button",true,false).filter(func(node):return node.visible)

func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	var s=game.state
	s.met_mayor=true
	s.day=29
	s.minute=600.0
	s.money=2000
	# The stock changes week to week, and only offers seeds that grow in the current season.
	var offers=s.curio_offers()
	var seeds=offers.filter(func(id):return s.crop_for_seed(id)!="")
	var trinkets=offers.filter(func(id):return id in s.Shop.TRINKETS)
	check(seeds.size()>=1 and trinkets.size()==1,"Widow Marsh offers exotic seeds and a trinket (%s)" % str(offers))
	check(seeds.all(func(id):return s.season_name() in s.CROPS[s.crop_for_seed(id)].seasons),"her seeds grow in the current season")
	var seen={}
	for week in range(8):
		s.day=1+week*7
		seen[str(s.curio_offers())]=true
	check(seen.size()>=4,"her stock rotates from week to week")
	s.day=29
	offers=s.curio_offers()
	# Buying is limited per week and resets the next.
	var seed=offers.filter(func(id):return s.crop_for_seed(id)!="")[0]
	var before=int(s.get(seed))
	var bought=0
	while s.buy_curio(seed): bought+=1
	check(bought==s.Shop.CURIOS[seed].stock and int(s.get(seed))==before+bought*s.Shop.CURIOS[seed].count,"a week's packets of %s sell out" % seed)
	s.day+=7
	if seed in s.curio_offers(): check(s.buy_curio(seed),"the next week brings fresh stock")
	# Her trinkets are prized gifts.
	s.brass_spyglass=1
	var friendship=int(s.friendships.get("astronomer",0))
	check(s.give_gift("astronomer","brass_spyglass") and int(s.friendships.get("astronomer",0))==friendship+5,"Saeren treasures a brass spyglass")
	# The exotic crops grow and sell like any other.
	for crop in ["veyr_peppers","moonmelons","frostkale"]:
		check(s.CROPS.has(crop) and s.CROP_PRICES.has(crop),"%s can be grown and sold" % crop)
	# Talking to her at work opens the shop.
	s.day=29
	game.outdoors.update_villagers(0,true)
	game.enter_building("widow")
	game.close_window()
	game.talk("widow")
	preload("fixture.gd").greet(game)
	var shop=buttons(game).filter(func(node):return node.text.begins_with("What's in this week?"))
	check(shop.size()==1,"Celandine offers this week's curios")
	if shop.size()==1:
		shop[0].pressed.emit()
		var listed=buttons(game).map(func(node):return node.text)
		check(s.curio_offers().all(func(id):return listed.any(func(text):return text.begins_with(s.Items.CATALOG[id].name))),"the shop lists every curio on offer this week")
	game.close_window()
	var restored=State.new()
	check(restored.restore(s.to_dict()) and restored.curio_week==s.curio_week and restored.curio_bought==s.curio_bought,"the week's purchases survive a save")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
