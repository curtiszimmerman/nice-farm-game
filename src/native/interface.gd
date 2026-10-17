extends CanvasLayer

const CREAM = Color("f1e7c9")
const GOLD = Color("dfba72")
const MUTED = Color("b6c3ad")
var game: Node2D
var root: Control
var place: Label
var region: Label
var clock: Label
var date: Label
var objective: Label
var next_task: Label
var hint: Label
var message: Label
var vitality: Label
var attunement: Label
var purse: Label
var energy_bar: ProgressBar
var mana_bar: ProgressBar
var shade: ColorRect
var modal: Control
var modal_box: VBoxContainer
var title_screen: Control
var action_meter: Control
var action_label: Label
var serif: SystemFont

class RhythmGauge extends Control:
	var value = 0.0
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO,size),Color("415c52"))
		draw_rect(Rect2(size.x*0.35,0,size.x*0.35,size.y),Color("d3ba78"))
		draw_rect(Rect2(size.x*value/100.0-2,-4,4,size.y+8),Color("f5edd2"))

func _ready() -> void:
	serif = SystemFont.new()
	serif.font_names = PackedStringArray(["DejaVu Serif","Liberation Serif"])
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	shade = ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.color = Color(0.04,0.07,0.17,0.0)
	root.add_child(shade)
	_label("FIRST LANDING / NATIVE PLAYABLE STUDY",Vector2(32,23),11,GOLD)
	place = _label("Briar Glen",Vector2(30,42),32,CREAM,true)
	region = _label("The old south farm",Vector2(33,88),13,MUTED)
	date = _label("SPRING 01",Vector2(1075,28),13,CREAM)
	date.size.x = 170
	date.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	clock = _label("08:00",Vector2(1075,45),33,CREAM,true)
	clock.size.x = 170
	clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var moons = _label("Waxing moons · year one",Vector2(1020,96),12,MUTED)
	moons.size.x = 225
	moons.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var log_panel = _panel(Vector2(30,151),Vector2(250,185),Color("182d2bba"))
	_label("CREW LOG",Vector2(14,12),10,GOLD,false,log_panel)
	_label("A place to begin",Vector2(14,34),20,CREAM,true,log_panel)
	objective = _label("",Vector2(14,70),14,MUTED,false,log_panel)
	objective.size = Vector2(220,80)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	next_task = _label("",Vector2(14,150),11,GOLD,false,log_panel)
	var tray = _panel(Vector2(285,602),Vector2(710,88),Color("172b2bf5"))
	vitality = _label("VITALITY  100",Vector2(19,12),10,MUTED,false,tray)
	energy_bar = _bar(Vector2(19,31),Vector2(132,4),Color("a5bb78"),tray)
	attunement = _label("ATTUNEMENT  60",Vector2(19,43),10,MUTED,false,tray)
	mana_bar = _bar(Vector2(19,64),Vector2(132,4),Color("90b9d2"),tray)
	var hotkeys = [["E","Tend / talk"],["Q","Wildgrowth"],["I","Satchel"],["J","Field notes"]]
	for i in range(4):
		var b = Button.new()
		b.position = Vector2(175+i*89,10)
		b.size = Vector2(82,68)
		b.text = hotkeys[i][0]+"\n"+hotkeys[i][1]
		b.add_theme_font_size_override("font_size",12)
		_button_style(b,i==0,true)
		var index = i
		b.pressed.connect(func(): game.hotkey(index))
		tray.add_child(b)
	purse = _label("24",Vector2(556,18),24,GOLD,true,tray)
	_label("crowns",Vector2(558,51),12,MUTED,false,tray)
	var settings_button = Button.new()
	settings_button.position = Vector2(644,24)
	settings_button.size = Vector2(44,40)
	settings_button.text = "≡"
	_button_style(settings_button)
	settings_button.pressed.connect(func(): game.settings())
	tray.add_child(settings_button)
	var controls = _label("WASD / ARROWS  walk    SHIFT  run    E  interact    Q  magic    M  map    ESC  settings    F11  fullscreen",Vector2(0,699),10,MUTED)
	controls.size.x = 1280
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint = _label("",Vector2(340,559),15,CREAM,true)
	hint.size.x = 600
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message = _label("",Vector2(340,117),16,CREAM,true)
	message.size = Vector2(600,70)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_meter = RhythmGauge.new()
	action_meter.position = Vector2(500,516)
	action_meter.size = Vector2(280,9)
	action_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(action_meter)
	action_meter.visible = false
	action_label = _label("",Vector2(440,483),14,CREAM,false)
	action_label.size.x = 400
	action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	show_title()

func _label(text: String,pos: Vector2,font_size: int,color: Color,book = false,parent: Node = null) -> Label:
	var label = Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	label.add_theme_color_override("font_shadow_color",Color("102523aa"))
	label.add_theme_constant_override("shadow_offset_y",2)
	if book: label.add_theme_font_override("font",serif)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent else root).add_child(label)
	return label

func style(fill: Color,border = Color("8d9a7666")) -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(3)
	box.content_margin_left = 17
	box.content_margin_right = 17
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box

func _panel(pos: Vector2,dimensions: Vector2,fill: Color,parent: Node = null) -> Panel:
	var panel = Panel.new()
	panel.position = pos
	panel.size = dimensions
	panel.add_theme_stylebox_override("panel",style(fill))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent else root).add_child(panel)
	return panel

func _bar(pos: Vector2,dimensions: Vector2,color: Color,parent: Node) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.position = pos
	bar.size = dimensions
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background = StyleBoxFlat.new()
	background.bg_color = Color("364b42")
	var fill = StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("background",background)
	bar.add_theme_stylebox_override("fill",fill)
	parent.add_child(bar)
	bar.size = dimensions
	return bar

func _button_style(button: Button,selected = false,compact = false) -> void:
	var normal = style(Color("3e4939") if selected else Color("293f38"),GOLD if selected else Color("a4b48a55"))
	var hover = style(Color("435642"),GOLD)
	var pressed = style(Color("53634a"),GOLD)
	if compact:
		for box in [normal,hover,pressed]:
			box.content_margin_left = 6
			box.content_margin_right = 6
	button.add_theme_stylebox_override("normal",normal)
	button.add_theme_stylebox_override("hover",hover)
	button.add_theme_stylebox_override("pressed",pressed)
	button.add_theme_color_override("font_color",CREAM)
	button.add_theme_color_override("font_hover_color",GOLD)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func show_title() -> void:
	title_screen = Control.new()
	title_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(title_screen)
	var dim = ColorRect.new()
	dim.color = Color("102825ce")
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_screen.add_child(dim)
	_label("A SMALL BEGINNING, ON A VERY DISTANT WORLD",Vector2(100,115),12,GOLD,false,title_screen)
	_label("Somewhere,\nthe Sun Still Rises",Vector2(95,155),54,CREAM,true,title_screen)
	_label("✦",Vector2(100,315),28,GOLD,true,title_screen)
	_label("Your ship is hidden. Your orders are complicated.\nFor now, there is a gate, a stranger, and a patch of good soil.",Vector2(100,380),17,MUTED,true,title_screen)
	var start = Button.new()
	start.text = "Step into the morning    →"
	start.position = Vector2(100,480)
	start.size = Vector2(340,54)
	start.add_theme_font_size_override("font_size",18)
	_button_style(start,true)
	start.pressed.connect(func(): title_screen.queue_free(); title_screen=null; game.begin())
	title_screen.add_child(start)
	_label("NATIVE DEBIAN BUILD · A FIRST-LANDING STUDY\nProgress stays in this project · sound optional in settings",Vector2(103,565),11,MUTED,false,title_screen)
	start.grab_focus()

func close_modal() -> void:
	if is_instance_valid(modal): modal.queue_free()
	modal = null
	modal_box = null

func open_modal(title: String,eyebrow: String,body: String,choices: Array,wide = false) -> void:
	close_modal()
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(modal)
	var dim = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color("10242170")
	modal.add_child(dim)
	var panel = PanelContainer.new()
	panel.position = Vector2(330,135) if wide else Vector2(280,310)
	panel.custom_minimum_size.x = 620 if wide else 720
	panel.add_theme_stylebox_override("panel",style(Color("172d2cfb"),Color("aaab7a99")))
	modal.add_child(panel)
	modal_box = VBoxContainer.new()
	modal_box.add_theme_constant_override("separation",13)
	panel.add_child(modal_box)
	var subtitle = Label.new()
	subtitle.text = eyebrow
	subtitle.add_theme_color_override("font_color",GOLD)
	subtitle.add_theme_font_size_override("font_size",11)
	modal_box.add_child(subtitle)
	var heading = Label.new()
	heading.text = title
	heading.add_theme_font_override("font",serif)
	heading.add_theme_font_size_override("font_size",27)
	heading.add_theme_color_override("font_color",CREAM)
	modal_box.add_child(heading)
	var text = Label.new()
	text.text = body
	text.custom_minimum_size.x = 580 if wide else 680
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_color_override("font_color",MUTED)
	text.add_theme_font_override("font",serif)
	text.add_theme_font_size_override("font_size",16)
	modal_box.add_child(text)
	for option in choices:
		var b = Button.new()
		b.text = option[0]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size",14)
		_button_style(b)
		var action = option[1]
		b.pressed.connect(func(): game.close_window(); action.call())
		modal_box.add_child(b)
	var footer = Label.new()
	footer.text = "ESC closes · " + ("Time keeps moving" if game.state.pause_mode=="none" else "Calendar paused; world active" if game.state.pause_mode=="clock" else "World paused")
	footer.add_theme_font_size_override("font_size",10)
	footer.add_theme_color_override("font_color",Color("94ad98"))
	modal_box.add_child(footer)

func update() -> void:
	var s = game.state
	clock.text = "%02d:%02d" % [int(s.minute/60.0),int(s.minute)%60]
	date.text = "SPRING %02d" % s.day
	purse.text = str(s.money)
	vitality.text = "VITALITY  %d" % ceili(s.energy)
	attunement.text = "ATTUNEMENT  %d" % int(s.mana)
	energy_bar.value = s.energy
	mana_bar.value = s.mana/60.0*100.0
	var p = s.player_position
	region.text = "Briar Glen town" if p.x>1120 else "The south meadow" if p.y>985 else "The hidden clearing" if p.x<470 and p.y<470 else "The old south farm"
	place.text = "A quiet signal" if region.text=="The hidden clearing" else "Briar Glen"
	objective.text = "Find Moss at the farm gate. We need somewhere to stay." if not s.invited else "The mayor is waiting at your farmhouse. Head home when you're ready." if not s.met_mayor and s.total()>=2160 else "Meet the mayor at your farmhouse tomorrow at noon. Until then, settle in." if not s.met_mayor else "A home, a little soil, a place in the world. Take your time."
	next_task.text = "○ Tend your first moon turnip" if s.harvested==0 else "○ Chief Vale needs 3 copper" if not s.delivered else "✓ Crew link restored"
	hint.text = "" if game.window_open else "RESTING · E to get up" if game.resting>0 else "E · "+game.nearest.get("label","") if not game.nearest.is_empty() else ""
	if game.activity=="mining": hint.text = "Gathering copper…"
	if game.activity=="fishing": hint.text = "E · reel in when the marker crosses the gold band"
	var night = 0.0
	if s.minute<330: night=0.43
	elif s.minute<420: night=0.43*(420-s.minute)/90.0
	elif s.minute>1110: night=minf(0.46,(s.minute-1110)/180.0*0.46)
	shade.color = Color(0.04,0.07,0.17,night)
	action_meter.visible = game.activity=="fishing"
	action_label.text = ""
	if game.activity=="fishing":
		action_meter.value = game.fishing_position()*100.0
		action_meter.queue_redraw()
		action_label.text = "Casting…" if game.activity_time<1.2 else "Gold band: 35–70 · E to reel"
	elif game.resting>0: action_label.text = "The sun keeps its own company."
