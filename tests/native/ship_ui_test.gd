extends SceneTree
const Game=preload("res://game.gd")
var failed=false
func check(value: bool,label: String) -> void:
	if value: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	check(game.ui.quick_buttons.size()==8,"HUD has eight selectable quick slots")
	var key=InputEventKey.new()
	key.pressed=true
	key.physical_keycode=KEY_8
	game._unhandled_key_input(key)
	check(game.state.selected_slot==7,"number eight selects the eighth quick slot")
	game.state.chest_transfer(0)
	game.state.player_position=game.world.plot_position(0)+Vector2.UP*32
	var particle_count=game.world.particles.size()
	game.interact()
	check(not game.state.plots[0].tilled and game.world.particles.size()==particle_count,"an unselected hoe causes neither work nor false action effects")
	game.ui.log_toggle.pressed.emit()
	check(game.ui.quest_scroll.visible and game.ui.quest_rows.get_child_count()>0,"crew log opens its quest list when clicked")
	game.ui.log_toggle.pressed.emit()
	check(not game.ui.quest_scroll.visible and game.ui.log_panel.position.x<100,"crew log collapses on the left beneath the location heading")
	game.open_storage("ship_storage")
	game.ui.chest_slots[0].pressed.emit()
	game.ui.quantity_control.value=2
	game.ui.modal_box.get_child(4).pressed.emit()
	check(game.state.rations==2 and game.state.ship_storage[0].count==4,"native quantity chooser transfers the requested amount")
	game.close_window()
	game.enter_building("ship")
	check(game.current_room=="ship" and not game.world.blocked(game.state.player_position),"the cloaked ship has an enterable interior")
	var kinds={}
	for item in game.world.furnishings: kinds[item.kind]=true
	check(kinds.has("reactor") and kinds.has("console") and kinds.has("bed"),"ship contains engineering machines displays and crew bunks")
	var separated=true
	for item in game.world.furnishings:
		if item.kind in ["bed","cabinet"] and item.bounds.end.y>6: separated=false
		if item.kind in ["reactor","machine","console"] and item.bounds.position.y<7: separated=false
	check(separated,"bunks and supplies occupy the upper rear while broken machinery stays in front")
	check(game.world.villagers.vale.visible,"Vale works inside the damaged ship")
	check(game.world.audio_context(Vector2.ZERO).environment=="ship","ship requests engineering ambience")
	game.sound.update_context(720,"ship","spring",0,10)
	check(game.sound.ship.playing and game.sound.ship.volume_db>-79 and game.sound.music.volume_db<-70 and game.sound.birds.volume_db<-70,"engineering hum plays while music and wildlife fade out")
	game.begin_rest(240)
	check(game.resting>0,"crew bunks permit player rest")
	game.interact()
	game.leave_building()
	check(not game.world.blocked(game.state.player_position),"ship exit returns to clear ground")
	game.enter_building("home")
	check(game.world.sites.any(func(site): return site.id=="cabinet") and game.world.sites.any(func(site): return site.id=="stove"),"farmhouse kitchen has cabinet and stove interactions")
	game.state.health_elixir=1
	game.item_options("health_elixir")
	check(game.ui.modal_box.get_child(3).text=="Drink","elixir context menu offers Drink")
	game.state.health=50
	game.ui.modal_box.get_child(3).pressed.emit()
	check(game.state.health==75,"the Drink menu consumes and heals")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
