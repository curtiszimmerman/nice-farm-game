extends SceneTree
const Game=preload("res://game.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=Game.new()
	game.testing=true
	root.add_child(game)
	game.set_process(false)
	preload("fixture.gd").explore(game,true)
	var ui=game.ui
	var pixel=preload("res://pixel_ui.gd").font()
	check(ui.root.theme.default_font==pixel and ThemeDB.fallback_font==pixel,"the entire interface and drawn text share the pixel font")
	check(ui.quick_tray.size.x<=900 and ui.quick_tray.size.y<=64 and ui.health_label.get_theme_font_size("font_size")<=10,"the ordinary HUD is compact without oversized vital labels")
	check(ui.quick_tray.get_global_rect().end.y>=716 and ui.quick_tray.get_global_rect().end.y<=720,"the main action bar sits just above the viewport bottom")
	game.state.needs.hardcore=true
	ui.update_hud()
	check(ui.quick_tray.size.y<=64 and ui.needs_panel.visible and ui.needs_panel.get_parent()==ui.root,"hardcore adds only a separate needs panel above the vitals")
	check(is_equal_approx(ui.needs_panel.get_global_rect().end.y,ui.quick_tray.get_global_rect().position.y) and ui.needs_panel.get_global_rect().size.x<ui.quick_tray.get_global_rect().size.x*0.25,"the two panels meet in a short L shape")
	var needs_labels=ui.needs_panel.get_children().filter(func(child):return child is Label)
	check(needs_labels.size()==2 and is_equal_approx(needs_labels[0].position.y,ui.health_label.position.y) and is_equal_approx(needs_labels[1].position.y,ui.vitality.position.y) and is_equal_approx(ui.hydration_bar.position.y,ui.health_bar.position.y) and is_equal_approx(ui.nourishment_bar.position.y,ui.energy_bar.position.y),"water and food use the exact vital-row text and bar spacing")
	game.state.awake_minutes=1441
	game.state.apply_poison()
	game.ui.update()
	var strip=game.ui.get("status_strip")
	check(strip!=null,"status indicators have their own top-center HUD strip")
	if strip!=null:
		check(strip.visible and strip.get_child_count()==2 and absf(strip.position.x+strip.size.x/2-640)<1,"tiredness and poison appear centered above the world")
		check(strip.get_children().all(func(icon):return not icon.tooltip_text.is_empty()),"status indicators explain their gameplay effects on hover")
		var eyes=game.ui.status_icons.poison.get_node("PoisonEyes")
		var alpha=eyes.modulate.a
		game.ui._process(0.1)
		check(eyes.modulate.a!=alpha,"the poison skull's red eyes pulse")
		game.dialog("Moss","HELLO","A little conversation.")
		check(not strip.visible,"cutscenes also hide status indicators")
		game.close_window()
		game.ui.update()
		check(strip.visible,"status indicators return after a cutscene")
	game.state.energy=50
	game.state.rusty_sword=1
	game.state.assign_active("primary","rusty_sword")
	check(game.world.attack() and game.state.energy==46,"tired sword swings spend four energy")
	game.state.axe=1
	game.state.assign_active("primary","axe")
	var tree=game.outdoors.trees[0]
	check(game.outdoors.chop_tree(tree.cell) and is_equal_approx(game.state.energy,43.2),"tired axe swings spend reduced energy")
	game.state.health=1
	game.state.status_effects.clear()
	game.state.apply_poison()
	game._process(5)
	check(game.state.health==25,"poison exhaustion uses the existing recovery behavior outside caves too")
	await game.sound.shutdown()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
