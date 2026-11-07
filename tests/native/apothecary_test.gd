extends SceneTree
const Game=preload("res://game.gd")
const Foraging=preload("res://foraging.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")

func buttons(game: Node2D) -> Array:
	return game.ui.modal_box.find_children("*","Button",true,false).filter(func(node):return node.visible)

func press(game: Node2D,prefix: String) -> bool:
	var found=buttons(game).filter(func(node):return node.text.begins_with(prefix))
	if found.is_empty():
		print("No button starting '",prefix,"' among ",buttons(game).map(func(node):return node.text))
		return false
	found[0].pressed.emit()
	return true

func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	var s=game.state
	var world=game.outdoors
	s.met_mayor=true
	# Mushrooms grow beside trees in spring and autumn; wildflowers bloom in spring and summer.
	var mushrooms=world.forage_nodes.get("mushrooms",{}).keys()
	var flowers=world.forage_nodes.get("wildflowers",{}).keys()
	check(mushrooms.size()>=12 and flowers.size()>=12,"the countryside has mushrooms and wildflowers to gather (%d, %d)" % [mushrooms.size(),flowers.size()])
	check(mushrooms.all(func(cell):return world.trees.any(func(tree):return tree.cell.distance_to(cell)<=1.5)),"mushrooms come up beside trees")
	var seasons={}
	for season_day in [1,29,57,85]:
		s.day=season_day
		seasons[s.season_name()]=[Foraging.ready(s,"mushrooms",mushrooms[0]),Foraging.ready(s,"wildflowers",flowers[0])]
	check(seasons.spring==[true,true] and seasons.summer==[false,true] and seasons.autumn==[true,false] and seasons.winter==[false,false],"each grows only in its seasons (%s)" % str(seasons))
	s.day=2
	check(world.harvest_forage("mushrooms",mushrooms[0]) and s.mushrooms==1 and world.harvest_forage("wildflowers",flowers[0]) and s.wildflowers==1,"the captain gathers both")
	check(not world.harvest_forage("mushrooms",mushrooms[0]),"a picked patch needs time to come back")
	# Sorrel buys what the captain gathers.
	s.minute=600.0
	world.update_villagers(0,true)
	game.enter_building("herbalist")
	game.close_window()
	s.berries=3
	s.apples=1
	var value=s.forage_sale_value()
	check(value==3*s.Shop.FORAGE_PRICES.berries+s.Shop.FORAGE_PRICES.apples+s.Shop.FORAGE_PRICES.mushrooms+s.Shop.FORAGE_PRICES.wildflowers,"Sorrel prices every foraged find")
	var money=s.money
	s.mushrooms=1
	s.wildflowers=0
	game.talk("herbalist")
	preload("fixture.gd").greet(game)
	check(press(game,"I've brought things from the woods"),"Sorrel offers to buy forage")
	check(s.money==money+3*s.Shop.FORAGE_PRICES.berries+s.Shop.FORAGE_PRICES.apples+s.Shop.FORAGE_PRICES.mushrooms and s.berries==0 and s.mushrooms==0,"selling forage pays for all of it")
	# Her remedies.
	game.close_window()
	s.money=200
	game.talk("herbalist")
	check(press(game,"What remedies do you have?"),"Sorrel sells remedies")
	for id in ["stamina_tonic","clarity_draught","antidote"]:
		check(buttons(game).any(func(node):return node.text.begins_with(s.Items.CATALOG[id].name)),"her shelf has %s" % s.Items.CATALOG[id].name)
	check(press(game,s.Items.CATALOG.stamina_tonic.name) and s.stamina_tonic==1,"buying a stamina tonic")
	game.close_window()
	s.energy=20
	check(s.consume("stamina_tonic") and is_equal_approx(s.energy,60),"a stamina tonic restores forty energy")
	s.status_effects.poison={"remaining":60.0}
	s.antidote=1
	check(s.consume("antidote") and not s.status_effects.has("poison"),"an antidote cures poison")
	# Brewing at her table, from foraged ingredients and a jar.
	s.berries=2
	s.wildflowers=1
	s.glass_jars=1
	preload("fixture.gd").face_site(game,"brewing_table")
	game.interact()
	check(press(game,"Brew "+s.Items.CATALOG.stamina_tonic.name),"her brewing table offers recipes")
	check(s.stamina_tonic==1 and s.berries==0 and s.wildflowers==0 and s.glass_jars==0,"brewing a stamina tonic uses two berries, a wildflower and a jar")
	game.close_window()
	game.leave_building()
	check(not s.brew("clarity_draught"),"nothing brews without the ingredients")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
