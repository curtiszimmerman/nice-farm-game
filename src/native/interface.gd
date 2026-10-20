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
var quest_unread=false
var known_quests: Array=[]
var quick_tray: Panel
var hint_panel: PanelContainer
var pulse_time=0.0
var pause_shield: Control
var pause_badge: PanelContainer
var active_button: ItemButton
var auxiliary_button: ItemButton
const Skills=preload("res://skills.gd")
var equipment_slots: Dictionary={}
var skill_buttons: Array=[]
var dialogue_open=false
var controls_hint: Label

class ItemButton extends Button:
	var interface: CanvasLayer
	var quick_index=-1
	var inventory_source=false
	var skill_source=false
	var active_channel=""
	func _get_drag_data(_position: Vector2) -> Variant:
		if not (inventory_source or skill_source) or not has_meta("item_id"): return null
		var id: String=get_meta("item_id")
		if not interface.game.state.available_action(id): return null
		var preview=TextureRect.new()
		preview.texture=Items.icon(id)
		preview.custom_minimum_size=Vector2(40,40)
		preview.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		set_drag_preview(preview)
		return {"type":"ability" if skill_source else "inventory_item","id":id}
	func _can_drop_data(_position: Vector2,data: Variant) -> bool:
		return (quick_index>=0 or active_channel!="") and data is Dictionary and data.get("type") in ["inventory_item","ability"] and interface.game.state.available_action(data.get("id",""))
	func _drop_data(position: Vector2,data: Variant) -> void:
		if not _can_drop_data(position,data): return
		if active_channel!="": interface.game.state.assign_active(active_channel,data.id)
		else: interface.game.state.assign_slot(quick_index,data.id)
		interface.game.save_visit()
		interface.update()
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
var message_panel: PanelContainer
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
	toggle_log()
	var tray = _panel(Vector2(140,602),Vector2(1000,88),Color("172b2bf5"))
	quick_tray=tray
	health_label = _label("HP  100",Vector2(19,7),10,MUTED,false,tray)
	health_bar = _bar(Vector2(19,23),Vector2(132,4),Color("c38e80"),tray)
	vitality = _label("ENERGY  100",Vector2(19,30),10,MUTED,false,tray)
	energy_bar = _bar(Vector2(19,46),Vector2(132,4),Color("a5bb78"),tray)
	attunement = _label("MANA  60",Vector2(19,53),10,MUTED,false,tray)
	mana_bar = _bar(Vector2(19,69),Vector2(132,4),Color("90b9d2"),tray)
	_label("PRIMARY",Vector2(163,3),8,GOLD,false,tray)
	active_button=ItemButton.new()
	active_button.interface=self
	active_button.active_channel="primary"
	active_button.position=Vector2(162,20)
	active_button.size=Vector2(48,57)
	active_button.expand_icon=true
	active_button.add_theme_constant_override("icon_max_width",28)
	_button_style(active_button,true,true)
	tray.add_child(active_button)
	decorate_action_slot(active_button,"E")
	_label("AUX",Vector2(220,3),8,GOLD,false,tray)
	auxiliary_button=ItemButton.new()
	auxiliary_button.interface=self
	auxiliary_button.active_channel="aux"
	auxiliary_button.position=Vector2(216,20)
	auxiliary_button.size=Vector2(48,57)
	_button_style(auxiliary_button,false,true)
	tray.add_child(auxiliary_button)
	decorate_action_slot(auxiliary_button,"Q")
	for i in range(8):
		var b = ItemButton.new()
		b.interface=self
		b.quick_index=i
		b.position = Vector2(274+i*54,10)
		b.size = Vector2(50,68)
		b.expand_icon=true
		b.add_theme_constant_override("icon_max_width",28)
		b.add_theme_font_size_override("font_size",12)
		_button_style(b,i==0,true)
		var index = i
		b.pressed.connect(func(): game.select_quick_slot(index))
		tray.add_child(b)
		decorate_action_slot(b,str(i+1))
		quick_buttons.append(b)
	var actions=Button.new()
	actions.position=Vector2(712,15)
	actions.size=Vector2(104,58)
	actions.text="Actions"
	_button_style(actions)
	actions.pressed.connect(func(): game.actions())
	tray.add_child(actions)
	purse = _label("24",Vector2(832,18),24,GOLD,true,tray)
	_label("crowns",Vector2(834,51),12,MUTED,false,tray)
	controls_hint = _label("",Vector2(0,699),10,MUTED)
	controls_hint.size.x = 1280
	controls_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_panel=PanelContainer.new()
	hint_panel.position=Vector2(390,554)
	hint_panel.size=Vector2(500,30)
	var hint_style=style(Color("172b2be8"))
	hint_style.content_margin_left=10
	hint_style.content_margin_right=10
	hint_style.content_margin_top=5
	hint_style.content_margin_bottom=5
	hint_panel.add_theme_stylebox_override("panel",hint_style)
	hint_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.add_child(hint_panel)
	hint = _label("",Vector2.ZERO,14,CREAM,true,hint_panel)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_panel=PanelContainer.new()
	message_panel.position=Vector2(420,112)
	message_panel.size=Vector2(440,38)
	var border=style(Color("172d30f5"),GOLD)
	border.content_margin_left=12
	border.content_margin_right=12
	border.content_margin_top=7
	border.content_margin_bottom=7
	message_panel.add_theme_stylebox_override("panel",border)
	message_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.add_child(message_panel)
	message = _label("",Vector2.ZERO,14,CREAM,true,message_panel)
	message.custom_minimum_size=Vector2(416,20)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
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
	pause_shield=Control.new()
	pause_shield.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_shield.mouse_filter=Control.MOUSE_FILTER_STOP
	pause_shield.visible=false
	root.add_child(pause_shield)
	var pause_layer=CanvasLayer.new()
	pause_layer.layer=30
	add_child(pause_layer)
	pause_badge=PanelContainer.new()
	pause_badge.position=Vector2(525,18)
	pause_badge.size=Vector2(230,34)
	pause_badge.add_theme_stylebox_override("panel",hint_style)
	pause_badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
	pause_badge.visible=false
	pause_layer.add_child(pause_badge)
	var pause_text=_label("PAUSED · Space to resume",Vector2.ZERO,14,GOLD,false,pause_badge)
	pause_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER

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
	dialogue_open=false
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
	footer.text = "Story sequence holds time" if game.clock_held() else "ESC closes · " + ("Time keeps moving" if game.state.pause_mode=="none" else "Calendar paused; world active" if game.state.pause_mode=="clock" else "World paused")
	footer.add_theme_font_size_override("font_size",10)
	footer.add_theme_color_override("font_color",Color("94ad98"))
	modal_box.add_child(footer)

func advance_dialogue() -> bool:
	if not dialogue_open: return false
	if modal_box==null or not is_instance_valid(modal_box): return false
	var choices=modal_box.get_children().filter(func(child): return child is Button and not child.disabled)
	if choices.size()!=1: return false
	choices[0].pressed.emit()
	return true

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
	open_character_inventory()

func open_character_inventory() -> void:
	# The quick bar remains a drop target while the satchel is open.
	open_modal("Your satchel","SUPPLIES & EQUIPMENT","Hover over an item for details. Select an item to use it.",[["Close satchel",func(): pass]],true)
	var water=game.state.water
	modal_box.get_child(2).text="Click to select · drag onto either action or a quick slot · right-click food to eat or drink"
	modal_box.get_child(2).custom_minimum_size.x=1000
	modal.get_child(1).position=Vector2(100,40)
	modal.mouse_filter=Control.MOUSE_FILTER_IGNORE
	modal.get_child(0).mouse_filter=Control.MOUSE_FILTER_IGNORE
	inventory_slots.clear()
	skill_buttons.clear()
	equipment_slots.clear()
	var row=HBoxContainer.new()
	row.add_theme_constant_override("separation",26)
	modal_box.add_child(row)
	modal_box.move_child(row,3)
	var equipment=Control.new()
	equipment.custom_minimum_size=Vector2(250,280)
	row.add_child(equipment)
	_label("EQUIPMENT",Vector2(65,0),12,GOLD,false,equipment)
	var silhouette=TextureRect.new()
	var portrait=AtlasTexture.new()
	portrait.atlas=Items.Art.atlas
	portrait.region=Items.Art.region("actor_player_down0")
	silhouette.texture=portrait
	silhouette.modulate=Color("728b8060")
	silhouette.position=Vector2(94,70)
	silhouette.size=Vector2(64,128)
	silhouette.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	equipment.add_child(silhouette)
	var positions={"head":Vector2(100,22),"necklace":Vector2(10,22),"chest":Vector2(10,82),"arms":Vector2(190,82),"hands":Vector2(10,142),"legs":Vector2(190,142),"feet":Vector2(100,212),"left_ring":Vector2(10,212),"right_ring":Vector2(190,212)}
	for id in positions:
		var slot=Button.new()
		slot.position=positions[id]
		slot.size=Vector2(54,48)
		slot.text=id.replace("_ring","\nring").capitalize()
		slot.add_theme_font_size_override("font_size",10)
		slot.tooltip_text="Empty "+id.replace("_"," ")+" slot"
		_button_style(slot)
		equipment.add_child(slot)
		equipment_slots[id]=slot
	var supplies=VBoxContainer.new()
	row.add_child(supplies)
	var heading=Label.new()
	heading.text="SATCHEL · 12 SLOTS"
	heading.add_theme_color_override("font_color",GOLD)
	supplies.add_child(heading)
	var grid=GridContainer.new()
	grid.columns=4
	grid.add_theme_constant_override("h_separation",9)
	grid.add_theme_constant_override("v_separation",9)
	supplies.add_child(grid)
	var stacks=game.inventory_stacks()
	for i in range(game.State.INVENTORY_SLOTS):
		var stack: Dictionary=stacks[i] if i<stacks.size() else {}
		var slot=item_slot(stack,70)
		grid.add_child(slot)
		inventory_slots.append(slot)
		slot.disabled=stack.is_empty()
		if not stack.is_empty():
			slot.inventory_source=true
			slot.pressed.connect(func(): game.select_inventory_item(stack.id))
			slot.gui_input.connect(func(event):
				if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT and event.pressed:
					game.item_options(stack.id)
					slot.accept_event())
	var abilities=VBoxContainer.new()
	abilities.custom_minimum_size.x=260
	row.add_child(abilities)
	var title=Label.new()
	title.text="SPELLS & SKILLS"
	title.add_theme_color_override("font_color",GOLD)
	abilities.add_child(title)
	var scroll=ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(260,260)
	abilities.add_child(scroll)
	var list=VBoxContainer.new()
	list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for id in Skills.learned(game.state):
		var button=ItemButton.new()
		button.interface=self
		button.skill_source=true
		button.set_meta("item_id",id)
		button.text=Skills.CATALOG[id].name+"\n"+Skills.CATALOG[id].kind
		button.icon=Items.icon(id)
		button.expand_icon=true
		button.add_theme_constant_override("icon_max_width",32)
		button.custom_minimum_size=Vector2(245,60)
		button.tooltip_text=Skills.CATALOG[id].description+" Drag to E, Q or a quick slot."
		_button_style(button)
		button.pressed.connect(func(): game.state.assign_active("primary",id); update())
		list.add_child(button)
		skill_buttons.append(button)

func decorate_action_slot(button: Button,key: String) -> void:
	var picture=TextureRect.new()
	picture.name="Picture"
	picture.position=Vector2(8,8)
	picture.size=Vector2(32,32)
	picture.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
	button.add_child(picture)
	var badge=PanelContainer.new()
	badge.name="KeyBadge"
	badge.position=Vector2(button.size.x-17,0)
	var bubble=StyleBoxFlat.new()
	bubble.bg_color=Color("40544b")
	bubble.border_color=GOLD
	bubble.set_border_width_all(1)
	bubble.set_corner_radius_all(5)
	bubble.content_margin_left=3
	bubble.content_margin_right=3
	bubble.content_margin_top=1
	bubble.content_margin_bottom=1
	badge.add_theme_stylebox_override("panel",bubble)
	badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
	button.add_child(badge)
	var key_label=Label.new()
	key_label.text=key
	key_label.add_theme_font_size_override("font_size",9)
	key_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	badge.add_child(key_label)
	var charge=Label.new()
	charge.name="Quantity"
	charge.position=Vector2(0,button.size.y-19)
	charge.size.x=button.size.x
	charge.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	charge.add_theme_font_size_override("font_size",10)
	charge.mouse_filter=Control.MOUSE_FILTER_IGNORE
	button.add_child(charge)

func show_action(button: Button,id: String) -> void:
	button.text=""
	button.icon=null
	button.get_node("Picture").texture=Items.icon(id) if id!="" else null
	button.tooltip_text=Items.CATALOG[id].name if Items.CATALOG.has(id) else Skills.CATALOG[id].name if Skills.CATALOG.has(id) else "Empty action slot"
	button.get_node("Quantity").text=("Empty" if game.state.water==0 else "%d/20" % game.state.water) if id=="watering_can" else str(game.state.get(id)) if Items.CATALOG.has(id) and game.state.get(id)>1 else ""

func add_control_bindings() -> void:
	modal.get_child(1).position=Vector2(250,35)
	var scroll=ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(700,370)
	modal_box.add_child(scroll)
	modal_box.move_child(scroll,3)
	var list=VBoxContainer.new()
	list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for action in game.controls.keys:
		var button=Button.new()
		button.text=game.controls.LABELS.get(action,action.capitalize())+"     "+OS.get_keycode_string(game.controls.keys[action])
		_button_style(button)
		button.pressed.connect(func(): game.remapping=action; button.text="Press a key… (Escape cancels)")
		list.add_child(button)

func item_slot(stack: Dictionary,pixels: int) -> Button:
	var slot=ItemButton.new()
	slot.interface=self
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
	count.text=str(stack.count) if stack.count>1 else ""
	count.position=Vector2(pixels-28,pixels-26)
	count.add_theme_color_override("font_color",CREAM)
	count.mouse_filter=Control.MOUSE_FILTER_IGNORE
	slot.add_child(count)
	return slot

func open_chest(selected: String) -> void:
	var storage: Array=game.state.get(game.storage_name)
	var title={"chest":"Farmhouse chest","cabinet":"Kitchen cabinet","ship_storage":"Crew supplies","cave_barrel":"Cave entrance barrel"}[game.storage_name]
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
		label.text="CARRIED · 12 SLOTS" if side==0 else "STORAGE · %d SLOTS" % storage.size()
		column.add_child(label)
		var grid=GridContainer.new()
		grid.columns=6
		column.add_child(grid)
		for i in range(game.State.INVENTORY_SLOTS if side==0 else storage.size()):
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
	quest_unread=false
	log_expanded=not log_expanded
	for child in log_panel.get_children():
		if child!=log_toggle: child.visible=log_expanded
	log_panel.size.y=210 if log_expanded else 55
	log_toggle.text=("▾" if log_expanded else "▸")+" CREW LOG"

func _process(dt: float) -> void:
	if game==null or quick_tray==null: return
	pulse_time+=dt
	log_toggle.modulate=Color.WHITE.lerp(Color("ffd276"),0.45+0.4*sin(pulse_time*TAU/3.5)) if quest_unread else Color.WHITE
	var screen=get_viewport().get_canvas_transform()*game.state.player_position
	var avatar=Rect2(screen-Vector2(15,58)*game.camera.zoom,Vector2(30,64)*game.camera.zoom)
	var obscured=quick_tray.get_global_rect().intersects(avatar)
	quick_tray.modulate.a=move_toward(quick_tray.modulate.a,0.22 if obscured else 1.0,dt*4)

func update() -> void:
	game.state.clear_empty_slots()
	message_panel.visible=not message.text.is_empty()
	message_panel.size=Vector2(440,0)
	pause_shield.visible=game.world_paused
	pause_badge.visible=game.world_paused
	root.move_child(pause_shield,-1)
	var s = game.state
	var active=s.active_item("primary")
	show_action(active_button,active)
	show_action(auxiliary_button,s.active_item("aux"))
	active_button.get_node("KeyBadge").get_child(0).text=OS.get_keycode_string(game.controls.keys.primary)
	auxiliary_button.get_node("KeyBadge").get_child(0).text=OS.get_keycode_string(game.controls.keys.aux)
	for slot in inventory_slots:
		if is_instance_valid(slot): _button_style(slot,slot.get_meta("item_id","")==active and active!="",true)
	var quests=["crew_supplies"]
	if s.invited: quests.append("restore_farmhouse")
	if s.met_mayor: quests.append("first_harvest")
	if s.welcome_phase=="complete": quests.append("meet_wizard")
	if s.firewood_requested: quests.append("keeper_firewood")
	for quest in quests:
		if quest not in known_quests:
			known_quests.append(quest)
			quest_unread=true
	for i in range(8):
		var id: String=s.quick_slots[i]
		var button: Button=quick_buttons[i]
		show_action(button,id)
		button.get_node("KeyBadge").get_child(0).text=OS.get_keycode_string(game.controls.keys["slot"+str(i+1)])
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
	elif game.world.SHIP_MOUNTAIN.has_point(game.world.Grid.world_to_cell(p)): region.text="Shipwreck ridge · mountain trail"
	elif p.y>2550: region.text="Southern woodland"
	elif game.world.Grid.rect(game.world.OUTCROP_CELLS.position,game.world.OUTCROP_CELLS.size).grow(200).has_point(p): region.text="Copper foothills"
	if game.world!=game.outdoors: region.text=game.world.room_name()
	place.text = "A quiet signal" if region.text=="The hidden clearing" else "Briar Glen"
	objective.text = "Follow the mountain path to the back of the farmhouse. Find out who lives here." if not s.invited else "The mayor's party is waiting at the farmhouse." if not s.met_mayor and s.mayor_available() else "Moss is fetching the mayor. They return two hours after you spoke. Tidy the farmhouse while you wait." if not s.met_mayor else "A home, a little soil, a place in the world. Keep the farmhouse clean and work the garden."
	if s.invited and not s.met_mayor: objective.text="Uncover the farmhouse furniture and replace both bulbs. Moss will return with the mayor after the house is ready."
	next_task.text = "○ Tend your first moon turnip" if s.harvested==0 else "○ Chief Vale needs 3 copper" if not s.delivered else "✓ Crew link restored"
	if s.invited:
		for task in s.house_tasks:
			if not s.house_tasks[task]:
				next_task.text="○ "+{"sofa":"Remove the sofa cover","bed":"Uncover your bed","guest_bed":"Uncover the guest bed","radio":"Uncover the radio","living_light":"Replace the living-room bulb","bathroom_light":"Replace the bathroom bulb"}[task]
				break
	if s.crew_fed_day<s.day: next_task.text="○ Vale needs a cooked meal in the ship locker"
	if s.firewood_requested and not s.firewood_given: next_task.text="○ Bring Oren six firewood"
	var primary_key=OS.get_keycode_string(game.controls.keys.primary)
	hint.text = "" if game.window_open else "RESTING · "+primary_key+" to get up" if game.resting>0 else primary_key+" · "+game.nearest.get("label","") if not game.nearest.is_empty() else ""
	if game.activity=="mining": hint.text = "Gathering copper…"
	if game.activity=="fishing": hint.text = primary_key+" · reel in when the marker crosses the gold band"
	controls_hint.text="%s%s%s%s / arrows  walk    %s  run    %s / left click  primary    %s / right click  auxiliary    %s  inventory    %s  menu" % [OS.get_keycode_string(game.controls.keys.up),OS.get_keycode_string(game.controls.keys.left),OS.get_keycode_string(game.controls.keys.down),OS.get_keycode_string(game.controls.keys.right),OS.get_keycode_string(game.controls.keys.run),primary_key,OS.get_keycode_string(game.controls.keys.aux),OS.get_keycode_string(game.controls.keys.inventory),OS.get_keycode_string(game.controls.keys.menu)]
	if game.world_paused: hint.text=""
	hint_panel.visible=not hint.text.is_empty()
	var hint_width=hint.get_theme_font("font").get_string_size(hint.text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x+24
	hint_panel.size=Vector2(minf(740,hint_width),0)
	hint_panel.position.x=(1280-hint_panel.size.x)/2
	action_meter.visible = game.activity=="fishing"
	action_label.text = ""
	if game.activity=="fishing":
		action_meter.value = game.fishing_position()*100.0
		action_meter.queue_redraw()
		action_label.text = "Casting…" if game.activity_time<1.2 else "%s · %s · E in gold band" % [Items.CATALOG[game.fishing_species].name,"Hard" if Items.FISH[game.fishing_species].hard else "Easy"]
	elif game.resting>0: action_label.text = "The sun keeps its own company."
