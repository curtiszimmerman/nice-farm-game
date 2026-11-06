extends SceneTree
const Game=preload("res://game.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var s=preload("res://state.gd").new()
	check(not s.purchase("copper_bars") and not s.purchase("silver_bars"),"new captains cannot afford Dain's metals")
	s.money=5000
	check(s.purchase("copper_bars") and s.purchase("copper_bars") and s.copper_bars==2 and s.money==3900,"two copper bars cost 550 crowns each")
	check(not s.purchase("copper_bars") and s.money==3900,"only two copper bars are available")
	check(s.purchase("silver_bars") and s.silver_bars==1 and s.money==2100,"one silver ingot costs 1800 crowns")
	check(not s.purchase("silver_bars"),"only one silver ingot is available")
	s.advance(1440)
	check(s.stock("copper_bars")==0 and s.stock("silver_bars")==0,"metal supplies do not refresh daily")
	s.day=29
	check(s.stock("copper_bars")==2 and s.stock("silver_bars")==1,"metal supplies refresh with the seasonal delivery")
	var legacy=preload("res://state.gd").new()
	legacy.stock("bread")
	legacy.shop_remaining.erase("copper_bars")
	legacy.shop_remaining.erase("silver_bars")
	var upgraded=preload("res://state.gd").new()
	check(upgraded.restore(legacy.to_dict()) and upgraded.stock("copper_bars")==2 and upgraded.stock("silver_bars")==1,"existing saved shops receive their new metal stock immediately")
	upgraded.money=5000
	upgraded.purchase("copper_bars")
	upgraded.purchase("copper_bars")
	upgraded.purchase("silver_bars")
	var loaded=preload("res://state.gd").new()
	check(loaded.restore(upgraded.to_dict()) and loaded.stock("copper_bars")==0 and loaded.stock("silver_bars")==0,"saving and loading never refills sold-out metal stock")
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	game.smith_shop()
	var buttons=game.ui.modal_box.find_children("*","Button",true,false)
	check(buttons.any(func(b):return "Copper bar" in b.text and "550" in b.text) and buttons.any(func(b):return "Silver ingot" in b.text and "1,800" in b.text),"Dain's real shop lists the metals and their prices")
	check(game.ui.quest_lines()[0].title=="A quiet local signal","the Crew Log uses the local signal title")
	game.state.money=5000
	game.smith_shop()
	game.ui.modal_box.find_children("*","Button",true,false).filter(func(b):return b.text.begins_with("Copper bar"))[0].pressed.emit()
	check(game.state.copper_bars==1 and game.state.silver_bars==0 and game.state.money==4450,"the copper purchase button grants copper at its own price")
	game.ui.modal_box.find_children("*","Button",true,false).filter(func(b):return b.text.begins_with("Silver ingot"))[0].pressed.emit()
	check(game.state.silver_bars==1 and game.state.money==2650,"the silver purchase button grants silver at its own price")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
