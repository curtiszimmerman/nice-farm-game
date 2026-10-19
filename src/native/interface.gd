extends CanvasLayer

const CREAM = Color("f1e7c9")
const GOLD = Color("dfba72")
const MUTED = Color("b6c3ad")
const Items = preload("res://items.gd")
var inventory_slots: Array=[]
var chest_slots: Array=[]
var quick_buttons: Array=[]
var log_panel: Panel
var log_toggle: Button
var log_expanded=true
var quantity_control: SpinBox
var game: Node2D
var root: Control
var place: Label
var region: Label
var clock: Label
var date: Label
var calendar_details: Label
var objective: Label
var next_task: Label
var hint: Label
var message: Label
var vitality: Label
var attunement: Label
var purse: Label
var energy_bar: ProgressBar
var mana_bar: ProgressBar
var health_bar: ProgressBar
var health_label: Label
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
	calendar_details = moons
	moons.size.x = 225
	moons.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	log_panel = _panel(Vector2(990,128),Vector2(250,210),Color("182d2bba"))
	log_toggle=Button.new()
	log_toggle.text="▾ CREW LOG"
	log_toggle.position=Vector2(8,5)
	log_toggle.size=Vector2(234,25)
	_button_style(log_toggle)
	log_toggle.pressed.connect(toggle_log)
	log_panel.add_child(log_toggle)
	_label("A place to begin",Vector2(14,54),20,CREAM,true,log_panel)
	objective = _label("",Vector2(14,90),14,MUTED,false,log_panel)
	objective.size = Vector2(220,80)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	next_task = _label("",Vector2(14,175),11,GOLD,false,log_panel)
	var tray = _panel(Vector2(140,602),Vector2(1000,88),Color("172b2bf5"))
	health_label = _label("HP  100",Vector2(19,7),10,MUTED,false,tray)
	health_bar = _bar(Vector2(19,23),Vector2(132,4),Color("c38e80"),tray)
	vitality = _label("ENERGY  100",Vector2(19,30),10,MUTED,false,tray)
	energy_bar = _bar(Vector2(19,46),Vector2(132,4),Color("a5bb78"),tray)
	attunement = _label("MANA  60",Vector2(19,53),10,MUTED,false,tray)
	mana_bar = _bar(Vector2(19,69),Vector2(132,4),Color("90b9d2"),tray)
	for i in range(8):
		var b = Button.new()
		b.position = Vector2(165+i*66,10)
		b.size = Vector2(61,68)
		b.expand_icon=true
		b.add_theme_constant_override("icon_max_width",28)
		b.add_theme_font_size_override("font_size",12)
		_button_style(b,i==0,true)
		var index = i
		b.pressed.connect(func(): game.select_quick_slot(index))
		tray.add_child(b)
		quick_buttons.append(b)
	var actions=Button.new()
	actions.position=Vector2(705,15)
	actions.size=Vector2(104,58)
	actions.text="Actions"
	_button_style(actions)
	actions.pressed.connect(func(): game.actions())
	tray.add_child(actions)
	purse = _label("24",Vector2(832,18),24,GOLD,true,tray)
	_label("crowns",Vector2(834,51),12,MUTED,false,tray)
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
	_label("NATIVE DEBIAN BUILD · A FIRST-LANDING STUDY\nProgress stays in this project · separate sound controls in settings",Vector2(103,565),11,MUTED,false,title_screen)
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
		b.pressed.connect(func(): game.choose_dialogue(action))
		modal_box.add_child(b)
	var footer = Label.new()
	footer.text = "ESC closes · " + ("Time keeps moving" if game.state.pause_mode=="none" else "Calendar paused; world active" if game.state.pause_mode=="clock" else "World paused")
	footer.add_theme_font_size_override("font_size",10)
	footer.add_theme_color_override("font_color",Color("94ad98"))
	modal_box.add_child(footer)

func add_volume_slider(title: String,value: float,on_changed: Callable) -> void:
	var row=HBoxContainer.new()
	row.add_theme_constant_override("separation",14)
	var label=Label.new()
	label.text=title
	label.custom_minimum_size.x=130
	label.add_theme_color_override("font_color",CREAM)
	row.add_child(label)
	var slider=HSlider.new()
	slider.min_value=0
	slider.max_value=100
	slider.step=1
	slider.value=roundf(value*100.0)
	slider.custom_minimum_size=Vector2(280,32)
	slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	var percent=Label.new()
	percent.text="%d%%" % slider.value
	percent.custom_minimum_size.x=50
	percent.add_theme_color_override("font_color",GOLD)
	row.add_child(percent)
	slider.value_changed.connect(func(level): percent.text="%d%%" % level; on_changed.call(level/100.0))
	modal_box.add_child(row)
	modal_box.move_child(row,modal_box.get_child_count()-4)

func open_inventory() -> void:
	open_modal("Your satchel","SUPPLIES & EQUIPMENT","Hover over an item for details. Select an item to use it.",[["Close satchel",func(): pass]],true)
	modal_box.get_child(2).text="Right-click food to Eat or Drink. Click an item to assign it to a quick slot.\nSelected slot: %d · Water: %d/20" % [game.state.selected_slot+1,game.state.water]
	modal.get_child(1).position.y=55
	inventory_slots.clear()
	var grid=GridContainer.new()
	grid.columns=6
	grid.add_theme_constant_override("h_separation",9)
	grid.add_theme_constant_override("v_separation",9)
	modal_box.add_child(grid)
	modal_box.move_child(grid,3)
	var stacks=game.inventory_stacks()
	for i in range(18):
		var stack: Dictionary=stacks[i] if i<stacks.size() else {}
		var slot=item_slot(stack,84)
		grid.add_child(slot)
		inventory_slots.append(slot)
		slot.disabled=stack.is_empty()
		if not stack.is_empty():
			slot.pressed.connect(func(): game.item_options(stack.id))
			slot.gui_input.connect(func(event):
				if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT and event.pressed:
					game.item_options(stack.id)
					slot.accept_event())

func item_slot(stack: Dictionary,pixels: int) -> Button:
	var slot=Button.new()
	slot.custom_minimum_size=Vector2.ONE*pixels
	_button_style(slot)
	if stack.is_empty(): return slot
	var item=Items.CATALOG[stack.id]
	slot.set_meta("item_id",stack.id)
	slot.tooltip_text="%s\n%s\n%s" % [item.name,item.description,item.action]
	if Items.FOOD.has(stack.id):
		var food=Items.FOOD[stack.id]
		slot.tooltip_text+="\n+%d HP · +%d energy · +%d mana" % [food.health,food.energy,food.mana]
	var picture=TextureRect.new()
	picture.texture=Items.icon(stack.id)
	picture.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	picture.position=Vector2(12,5)
	picture.size=Vector2.ONE*(pixels-26)
	picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
	slot.add_child(picture)
	var count=Label.new()
	count.text=str(stack.count)
	count.position=Vector2(pixels-28,pixels-26)
	count.add_theme_color_override("font_color",CREAM)
	count.mouse_filter=Control.MOUSE_FILTER_IGNORE
	slot.add_child(count)
	return slot

func open_chest(selected: String) -> void:
	var storage: Array=game.state.get(game.storage_name)
	var title={"chest":"Farmhouse chest","cabinet":"Kitchen cabinet","ship_storage":"Crew supplies"}[game.storage_name]
	open_modal(title,"TOOLS & SUPPLIES","Choose a stack, then choose the quantity. Select a carried stack and a storage slot to deposit or swap.",[["Close storage",func(): pass]],true)
	modal.get_child(1).position=Vector2(160,100)
	modal_box.get_child(2).custom_minimum_size.x=920
	if selected!="": modal_box.get_child(2).text="Selected: %s. Choose a chest slot to move or swap this stack." % Items.CATALOG[selected].name
	var row=HBoxContainer.new()
	row.add_theme_constant_override("separation",30)
	modal_box.add_child(row)
	modal_box.move_child(row,3)
	inventory_slots.clear()
	chest_slots.clear()
	var carried=game.inventory_stacks()
	for side in range(2):
		var column=VBoxContainer.new()
		row.add_child(column)
		var label=Label.new()
		label.text="CARRIED · 18 SLOTS" if side==0 else "STORAGE · %d SLOTS" % storage.size()
		column.add_child(label)
		var grid=GridContainer.new()
		grid.columns=6
		column.add_child(grid)
		for i in range(18 if side==0 else storage.size()):
			var stack: Dictionary=(carried[i] if i<carried.size() else {}) if side==0 else storage[i]
			var button=item_slot(stack,68)
			grid.add_child(button)
			if side==0:
				inventory_slots.append(button)
				button.disabled=stack.is_empty()
				if not stack.is_empty(): button.pressed.connect(func(): game.chest_selected=stack.id; game.open_chest())
			else:
				chest_slots.append(button)
				var index=i
				button.pressed.connect(func(): game.transfer_chest(index))

func quantity_picker(maximum: int,confirm: Callable,cancel: Callable) -> void:
	var amount=SpinBox.new()
	amount.min_value=1
	amount.max_value=maximum
	amount.step=1
	amount.value=1
	quantity_control=amount
	open_modal("How many?","TRANSFER QUANTITY","Available: %d. Different item stacks can be swapped only in full." % maximum,[
		["Transfer selected quantity",func(): confirm.call(int(amount.value))],
		["Transfer all · %d" % maximum,func(): confirm.call(maximum)],
		["Cancel",cancel]],true)
	modal_box.add_child(amount)
	modal_box.move_child(amount,3)

func toggle_log() -> void:
	log_expanded=not log_expanded
	for child in log_panel.get_children():
		if child!=log_toggle: child.visible=log_expanded
	log_panel.size.y=210 if log_expanded else 55
	log_toggle.text=("▾" if log_expanded else "▸")+" CREW LOG"

func update() -> void:
	var s = game.state
	for i in range(8):
		var id: String=s.quick_slots[i]
		var button: Button=quick_buttons[i]
		button.text=str(i+1)
		button.icon=Items.icon(id) if Items.CATALOG.has(id) else null
		button.tooltip_text="Empty slot" if id=="" else "Wildgrowth · 15 mana" if id=="wildgrowth" else Items.CATALOG[id].name+" · "+str(s.get(id))
		if id=="watering_can": button.text+="\n%d/20" % s.water
		if id=="wildgrowth": button.text+="\n✦"
		_button_style(button,i==s.selected_slot,true)
	clock.text = "%02d:%02d" % [int(s.minute/60.0),int(s.minute)%60]
	date.text = "%s %02d" % [s.season_name().to_upper(),s.season_day()]
	calendar_details.text = "Waxing moons · year %d" % s.calendar_year()
	purse.text = str(s.money)
	health_label.text="HP  %d" % ceili(s.health)
	health_bar.value=s.health
	vitality.text = "ENERGY  %d" % ceili(s.energy)
	attunement.text = "MANA  %d" % int(s.mana)
	energy_bar.value = s.energy
	mana_bar.value = s.mana/60.0*100.0
	var p = s.player_position
	region.text = "Briar Glen town" if game.world.Grid.rect(game.world.SQUARE.position,game.world.SQUARE.size).grow(350).has_point(p) else "The south meadow" if p.y>1850 else "The hidden clearing" if p.distance_to(game.world.Grid.center(game.world.SHIP_CELL))<220 else "The old south farm"
	if game.world.Grid.rect(game.world.SQUARE.position,game.world.SQUARE.size).has_point(p): region.text="Briar Glen town square"
	elif p.x>1500 and p.x<2500 and p.y<650: region.text="Wizard's tower · northern mountains"
	elif game.world.Grid.rect(game.world.OUTCROP_CELLS.position,game.world.OUTCROP_CELLS.size).grow(200).has_point(p): region.text="Copper foothills"
	if game.world!=game.outdoors: region.text=game.world.room_name()
	place.text = "A quiet signal" if region.text=="The hidden clearing" else "Briar Glen"
	objective.text = "Find Moss at the farm gate. We need somewhere to stay." if not s.invited else "The mayor is waiting at your farmhouse. Head home when you're ready." if not s.met_mayor and s.total()>=2160 else "Meet the mayor at your farmhouse tomorrow at noon. Until then, settle in." if not s.met_mayor else "A home, a little soil, a place in the world. Take your time."
	next_task.text = "○ Tend your first moon turnip" if s.harvested==0 else "○ Chief Vale needs 3 copper" if not s.delivered else "✓ Crew link restored"
	if s.crew_fed_day<s.day: next_task.text="○ Vale needs a cooked meal in the ship locker"
	hint.text = "" if game.window_open else "RESTING · E to get up" if game.resting>0 else "E · "+game.nearest.get("label","") if not game.nearest.is_empty() else ""
	if game.activity=="mining": hint.text = "Gathering copper…"
	if game.activity=="fishing": hint.text = "E · reel in when the marker crosses the gold band"
	action_meter.visible = game.activity=="fishing"
	action_label.text = ""
	if game.activity=="fishing":
		action_meter.value = game.fishing_position()*100.0
		action_meter.queue_redraw()
		action_label.text = "Casting…" if game.activity_time<1.2 else "Gold band: 35–70 · E to reel"
	elif game.resting>0: action_label.text = "The sun keeps its own company."
