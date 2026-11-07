extends SceneTree
const Game=preload("res://game.gd")
const Faith=preload("res://weekday_magic.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func choices(game: Node2D) -> Array:
	return game.ui.modal_box.get_children().filter(func(node):return node is Button)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	check(Faith.strength(4,1,"nature")==0.5 and Faith.strength(4,1,"water")==1 and Faith.strength(4,1,"air")==1.5,"Gale strengthens wind and weakens growth, without weakening water")
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	for index in range(7):
		var text=game.weekday_lore_text(index)
		check(text.contains(Faith.DAYS[index]) and text.contains("day of the week") and text.contains(Faith.day_effects(index)),"weekday lore names the day and spells out its effects")
	game.state.day=2
	game.next_rift_omen()
	var text=game.ui.modal_box.get_child(2).text
	check(text.contains("Today is Bough") and text.contains("growth") and text.contains("wind") and text.contains("next Rift is in 6 days"),"Iona explains both today's effects and the next Rift")
	check(game.spell_effort_description(15,60)!=game.spell_effort_description(15,600),"spell effort depends on total capacity rather than fixed numerical dialogue")
	game.local_magic_lore()
	check(not game.ui.modal_box.get_child(2).text.to_lower().contains("fifteen mana"),"Iona does not recite a numerical mana cost")
	game.close_window()
	game.state.requests.copper_advice=false
	game.state.requests.bram_requested=false
	game.state.requests.bram_traded=false
	game.state.chat_days.erase("bram_referral_smith")
	game.talk("veteran")
	check(choices(game).size()==1 and choices(game)[0].text.begins_with("Mostly?"),"direct visitors must ask about Bram's mostly peaceful home")
	choices(game)[0].pressed.emit()
	check(game.state.requests.bram_requested and choices(game).any(func(b):return b.text.begins_with("Trade three")),"the danger question opens the three-turnip sword offer")
	game.close_window()
	game.state.requests.bram_requested=false
	game.state.chat_days.bram_referral_smith=game.state.day
	game.talk("veteran")
	choices(game)[0].pressed.emit()
	check(game.state.requests.bram_requested and game.ui.modal_box.get_child(2).text.contains("copper caverns"),"Dain's referral leads directly to Bram's protection offer")
	game.close_window()
	game.state.rusty_sword=1
	game.state.turnips=3
	var friendship=int(game.state.friendships.get("veteran",0))
	preload("res://local_guidance.gd").sword_terms(game)
	check(game.ui.modal_box.get_child(2).text.contains("already got a sword") and not choices(game).any(func(b):return b.text.begins_with("Trade three")),"Bram acknowledges an existing sword and asks only for supper")
	choices(game)[0].pressed.emit()
	check(game.state.turnips==0 and game.state.rusty_sword==1 and game.state.friendships.veteran==friendship+5,"Bram's supper dialogue rewards friendship without duplicating the sword")
	var quest=game.ui.quest_lines().filter(func(line):return line.id=="bram_sword")
	check(quest.size()==1 and quest[0].tasks[0].done,"Bram's supper completes the quest even when already armed")
	game.close_window()
	game.state.player_position=game.Grid.center(Vector2i(63,47))
	preload("res://neighbors.gd").talk(game,"farmer_son")
	check(game.ui.modal_box.get_child(2).text.contains("other side of the sea") and not game.ui.modal_box.get_child(2).text.contains("Have you seen Nessa"),"Pip's off-duty conversation matches the travel reply")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
