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
var quest_scroll: ScrollContainer
var quest_rows: VBoxContainer
var quest_opened: Dictionary={}
var quest_signature=0
var quick_tray: Panel
var hint_panel: PanelContainer
var pulse_time=0.0
var status_strip: HBoxContainer
var status_icons: Dictionary={}
var shown_statuses: Array=[]
var pause_shield: Control
var pause_badge: PanelContainer
var active_button: ItemButton
var auxiliary_button: ItemButton
const Skills=preload("res://skills.gd")
var equipment_slots: Dictionary={}
var skill_buttons: Array=[]
var dialogue_open=false
var controls_hint: Label
var container_view=""
var hud_nodes: Array=[]
var hud_visibility: Dictionary={}
var hud_hidden=false
var inventory_tabs: TabContainer
var inventory_tab=0
var equipment_silhouette: TextureRect
var stats_experience: Label
var character_quests: VBoxContainer
var history_opened: Dictionary={}

class ItemButton extends Button:
	var interface: CanvasLayer
	var quick_index=-1
	var inventory_source=false
	var skill_source=false
	var active_channel=""
	var inventory_index=-1
	var storage_source=""
	var storage_index=-1
	func _get_drag_data(_position: Vector2) -> Variant:
		if not (inventory_source or skill_source or quick_index>=0 or active_channel!="" or storage_source!="") or not has_meta("item_id"): return null
		var id: String=get_meta("item_id")
		if storage_source=="" and not interface.game.state.available_action(id): return null
		var preview=TextureRect.new()
		preview.texture=Items.icon(id)
		preview.custom_minimum_size=Vector2(40,40)
		preview.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		set_drag_preview(preview)
		return {"type":"ability" if skill_source or Skills.CATALOG.has(id) else "inventory_item","id":id,"storage":storage_source,"index":storage_index}
	func destination() -> Dictionary:
		return {"storage":storage_source,"index":storage_index,"inventory_index":inventory_index,"quick_index":quick_index,"channel":active_channel}
	func _can_drop_data(_position: Vector2,data: Variant) -> bool:
		return interface.game.can_drop_item(data,destination())
	func _drop_data(position: Vector2,data: Variant) -> void:
		if not _can_drop_data(position,data): return
		interface.game.drop_item(data,destination())
var quantity_control: SpinBox
var game: Node2D
var root: Control
var place: Label
var region: Label
var clock: Label
var date: Label
var calendar_details: Label
var calendar_ring: Control
var season_word: Label
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
var modal_scroll: ScrollContainer
var title_screen: Control
var action_meter: Control
var action_label: Label
var serif: Font

class RhythmGauge extends Control:
	var value = 0.0
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO,size),Color("415c52"))
		draw_rect(Rect2(size.x*0.35,0,size.x*0.35,size.y),Color("d3ba78"))
		draw_rect(Rect2(size.x*value/100.0-2,-4,4,size.y+8),Color("f5edd2"))

func _ready() -> void:
	serif = preload("res://pixel_ui.gd").font()
	root = Control.new()
	root.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	root.theme=Theme.new()
	root.theme.default_font=serif
	root.theme.default_font_size=20
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_label("FIRST LANDING / NATIVE PLAYABLE STUDY",Vector2(32,23),11,GOLD)
	place = _label("Briar Glen",Vector2(30,42),32,CREAM,true)
	region = _label("The old south farm",Vector2(33,88),13,MUTED)
	calendar_ring=preload("res://calendar.gd").new()
	calendar_ring.state=game.state
	calendar_ring.position=Vector2(1010,8)
	calendar_ring.size=Vector2(220,250)
	root.add_child(calendar_ring)
	season_word=_label("SPRING",Vector2(1118,125),10,GOLD)
	date = _label("01",Vector2(1118,139),24,CREAM)
	date.size.x = 40
	clock = _label("08:00",Vector2(1055,225),27,CREAM,true)
	clock.size.x = 130
	clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var moons = _label("Root · year one",Vector2(1020,210),10,MUTED)
	calendar_details = moons
	moons.size.x = 225
	moons.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	log_panel = _panel(Vector2(970,302),Vector2(280,278),Color("182d2bf5"))
	log_toggle=Button.new()
	log_toggle.text="▾ CREW LOG"
	log_toggle.position=Vector2(8,5)
	log_toggle.size=Vector2(264,32)
	_button_style(log_toggle)
	log_toggle.pressed.connect(toggle_log)
	log_panel.add_child(log_toggle)
	objective = _label("",Vector2(14,90),14,MUTED,false,log_panel)
	objective.size = Vector2(220,80)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	next_task = _label("",Vector2(14,175),11,GOLD,false,log_panel)
	quest_scroll=ScrollContainer.new()
	quest_scroll.position=Vector2(12,50)
	quest_scroll.size=Vector2(256,214)
	log_panel.add_child(quest_scroll)
	quest_rows=VBoxContainer.new()
	quest_rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	quest_rows.add_theme_constant_override("separation",12)
	quest_scroll.add_child(quest_rows)
	toggle_log()
	var tray = _panel(Vector2(140,602),Vector2(1000,88),Color("172b2bf5"))
	quick_tray=tray
	tray.scale=Vector2(1.2,1.2)
	tray.position=Vector2(40,582)
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
	tray.size.y*=0.8
	tray.position.y+=88*1.2*0.2
	for child in tray.get_children():
		child.position.y*=0.8
		if child is Button:
			child.size.y*=0.8
			if child.has_node("Quantity"): child.get_node("Quantity").position.y=child.size.y-17
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
	status_strip=HBoxContainer.new()
	status_strip.add_theme_constant_override("separation",4)
	status_strip.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.add_child(status_strip)
	for child in root.get_children():
		if child!=pause_shield and child!=title_screen: hud_nodes.append(child)

func update_hud() -> void:
	var hidden=game.cutscene_active()
	if hidden and not hud_hidden:
		for node in hud_nodes: hud_visibility[node]=node.visible
	elif not hidden and hud_hidden:
		for node in hud_nodes: node.visible=hud_visibility.get(node,true)
		hud_visibility.clear()
	hud_hidden=hidden
	if hidden:
		for node in hud_nodes: node.hide()

func _label(text: String,pos: Vector2,font_size: int,color: Color,book = false,parent: Node = null) -> Label:
	var label = Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size",20 if font_size>=13 and font_size<20 else font_size)
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
	box.anti_aliasing=false
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(0)
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
	if not hud_nodes.is_empty(): update_hud()
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
	modal_scroll=ScrollContainer.new()
	modal_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(modal_scroll)
	modal_scroll.add_child(modal_box)
	modal_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
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
	text.add_theme_font_size_override("font_size",20)
	modal_box.add_child(text)
	for option in choices:
		var b = Button.new()
		b.text = option[0]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size",20)
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
	container_view="inventory"
	modal_box.get_child(1).hide()
	modal_box.get_child(2).hide()
	modal.get_child(1).position=Vector2(40,12)
	modal.get_child(1).custom_minimum_size.x=1200
	modal.mouse_filter=Control.MOUSE_FILTER_IGNORE
	modal.get_child(0).mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.move_child(quick_tray,-1)
	inventory_slots.clear()
	skill_buttons.clear()
	equipment_slots.clear()
	inventory_tabs=TabContainer.new()
	inventory_tabs.custom_minimum_size=Vector2(1130,460)
	modal_box.add_child(inventory_tabs)
	modal_box.move_child(inventory_tabs,3)
	var row=HBoxContainer.new()
	row.name="Inventory"
	row.add_theme_constant_override("separation",26)
	inventory_tabs.add_child(row)
	var equipment=Control.new()
	equipment.custom_minimum_size=Vector2(440,470)
	row.add_child(equipment)
	_label("EQUIPMENT",Vector2(160,0),12,GOLD,false,equipment)
	for points in [[Vector2(96,334),Vector2(150,326)],[Vector2(344,334),Vector2(296,326)],[Vector2(344,178),Vector2(220,204)]]:
		var line=Line2D.new()
		line.points=PackedVector2Array(points)
		line.width=1
		line.default_color=MUTED
		equipment.add_child(line)
	var silhouette=TextureRect.new()
	equipment_silhouette=silhouette
	var portrait=AtlasTexture.new()
	portrait.atlas=Items.Art.atlas
	portrait.region=Items.Art.region("actor_player_down0")
	silhouette.texture=portrait
	silhouette.modulate=Color("728b8060")
	silhouette.position=Vector2(108,8)
	silhouette.size=Vector2(224,448)
	silhouette.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	silhouette.mouse_filter=Control.MOUSE_FILTER_IGNORE
	equipment.add_child(silhouette)
	var positions={"head":Vector2(188,86),"necklace":Vector2(344,146),"chest":Vector2(188,214),"arms":Vector2(284,220),"hands":Vector2(118,294),"legs":Vector2(188,328),"feet":Vector2(188,400),"left_ring":Vector2(32,302),"right_ring":Vector2(344,302)}
	for id in positions:
		var slot=Button.new()
		slot.position=positions[id]
		slot.custom_minimum_size=Vector2(64,64)
		slot.size=Vector2(64,64)
		slot.tooltip_text={"head":"Helmet / head armor","chest":"Chest armor","arms":"Arm armor","hands":"Gloves / hand armor","legs":"Leg armor","feet":"Boots / foot armor","necklace":"Necklace","left_ring":"Left-hand ring","right_ring":"Right-hand ring"}[id]
		_button_style(slot,false,true)
		var placeholder=TextureRect.new()
		var picture=AtlasTexture.new()
		picture.atlas=Items.Art.atlas
		picture.region=Items.Art.region("equipment_"+id)
		placeholder.texture=picture
		placeholder.position=Vector2(12,12)
		placeholder.size=Vector2(40,40)
		placeholder.mouse_filter=Control.MOUSE_FILTER_IGNORE
		slot.add_child(placeholder)
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
	var stacks=game.state.inventory_cells()
	for i in range(game.State.INVENTORY_SLOTS):
		var stack: Dictionary=stacks[i] if i<stacks.size() else {}
		var slot=item_slot(stack,64)
		grid.add_child(slot)
		inventory_slots.append(slot)
		slot.inventory_index=i
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
	if Skills.learned(game.state).is_empty():
		var empty=Label.new()
		empty.text="[ None Known ]"
		list.add_child(empty)
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
	add_character_stats()
	inventory_tabs.current_tab=inventory_tab
	inventory_tabs.tab_changed.connect(func(index): inventory_tab=index)

func add_character_stats() -> void:
	var row=HBoxContainer.new()
	row.name="Stats & Quests"
	row.add_theme_constant_override("separation",40)
	inventory_tabs.add_child(row)
	var stats=VBoxContainer.new()
	stats.custom_minimum_size.x=330
	stats.add_theme_constant_override("separation",18)
	row.add_child(stats)
	var state=game.state
	for text in ["CAPTAIN'S RECORD","Health: %d / 100" % state.health,"Energy: %d / 100" % state.energy,"Mana: %d / 60" % state.mana,"Experience: %d XP" % state.experience,"Crowns: %d" % state.money]:
		var label=Label.new()
		label.text=text
		if text.begins_with("Experience"): stats_experience=label
		stats.add_child(label)
	var scroll=ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(730,420)
	row.add_child(scroll)
	character_quests=VBoxContainer.new()
	character_quests.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(character_quests)
	render_quest_list(character_quests,quest_lines(),history_opened,680)

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
	bubble.set_corner_radius_all(2)
	bubble.anti_aliasing=false
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
	button.set_meta("item_id",id)
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
		slot.tooltip_text+="\n+%d HP · +%s energy · +%d mana" % [food.health,str(game.state.energy_recovery(food.energy)),food.mana]
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
	container_view="storage"
	modal.mouse_filter=Control.MOUSE_FILTER_IGNORE
	modal.get_child(0).mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.move_child(quick_tray,-1)
	modal.get_child(1).position=Vector2(160,100)
	modal_box.get_child(2).custom_minimum_size.x=920
	if selected!="": modal_box.get_child(2).text="Selected: %s. Choose a chest slot to move or swap this stack." % Items.CATALOG[selected].name
	var row=HBoxContainer.new()
	row.add_theme_constant_override("separation",30)
	modal_box.add_child(row)
	modal_box.move_child(row,3)
	inventory_slots.clear()
	chest_slots.clear()
	var carried=game.state.inventory_cells()
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
			var button=item_slot(stack,64)
			grid.add_child(button)
			if side==0:
				inventory_slots.append(button)
				button.inventory_index=i
				button.inventory_source=true
				if not stack.is_empty(): button.pressed.connect(func(): game.chest_selected=stack.id; game.open_chest())
			else:
				button.storage_source=game.storage_name
				button.storage_index=i
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
		if child!=log_toggle: child.visible=log_expanded and child not in [objective,next_task]
	log_panel.size.y=278 if log_expanded else 55
	log_toggle.text=("▾" if log_expanded else "▸")+" CREW LOG"

func quest_lines() -> Array:
	var s=game.state
	var lines=[{"id":"crew_supplies","title":"A quiet signal home","description":"Vale is keeping the cloak stable. Help him restore contact and keep the crew fed.","tasks":[{"text":"Bring Vale three copper","done":s.delivered},{"text":"Leave food in the ship locker","done":s.crew_fed_day>=s.day}]}]
	if s.invited:
		lines.append({"id":"restore_farmhouse","title":"A place to begin","description":"Make the abandoned farmhouse welcoming before Moss brings the mayor.","tasks":[{"text":"Remove the covers from the furniture","done":["sofa","bed","guest_bed","radio"].all(func(id):return s.house_tasks[id])},{"text":"Change the lightbulbs around the house","done":s.house_tasks.living_light and s.house_tasks.bathroom_light}]})
	if s.met_mayor: lines.append({"id":"first_harvest","title":"Putting down roots","description":"Moss left tools and seeds. Work a small garden to provide for yourselves.","tasks":[{"text":"Harvest a moon turnip","done":s.harvested>0}]})
	if s.welcome_phase=="complete": lines.append({"id":"meet_wizard","title":"Gentler magic","description":"Visit Iona at the northern tower after noon to learn local magic.","tasks":[{"text":"Learn Wildgrowth from Iona","done":s.magic_learned}]})
	if s.firewood_requested: lines.append({"id":"keeper_firewood","title":"A warm western light","description":"Oren needs firewood for his lighthouse stove. Ask the forest woodcutter about an axe.","tasks":[{"text":"Bring Oren six firewood","done":s.firewood_given}]})
	for quest in lines:
		if quest.id not in s.quest_order: s.quest_order.append(quest.id)
	lines.sort_custom(func(a,b):return s.quest_order.find(a.id)<s.quest_order.find(b.id))
	var active=[]
	var completed=[]
	for quest in lines:
		quest.complete=quest.tasks.all(func(task):return task.done)
		if quest.complete: completed.append(quest)
		else: active.append(quest)
	return active+completed

func render_quests() -> void:
	var lines=quest_lines().filter(func(quest):return not quest.complete)
	var signature=hash(lines)^hash(quest_opened)
	if signature==quest_signature: return
	quest_signature=signature
	render_quest_list(quest_rows,lines,quest_opened,230)

func render_quest_list(container: VBoxContainer,lines: Array,opened: Dictionary,width: int) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
	for quest in lines:
		var header=Button.new()
		header.text=("▾ " if opened.get(quest.id,false) else "▸ ")+quest.title
		header.set_meta("quest_id",quest.id)
		header.alignment=HORIZONTAL_ALIGNMENT_LEFT
		header.add_theme_font_size_override("font_size",20)
		_button_style(header)
		if quest.complete: header.modulate=Color("7b837d")
		header.pressed.connect(func(): opened[quest.id]=not opened.get(quest.id,false); render_quest_list(container,lines,opened,width))
		container.add_child(header)
		if not opened.get(quest.id,false): continue
		var content=VBoxContainer.new()
		if quest.complete: content.modulate=Color("7b837d")
		content.add_theme_constant_override("separation",14)
		container.add_child(content)
		var description=Label.new()
		description.text=quest.description
		description.custom_minimum_size.x=width
		description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		description.add_theme_font_size_override("font_size",20)
		description.add_theme_color_override("font_color",MUTED)
		content.add_child(description)
		for task in quest.tasks:
			var row=Label.new()
			row.text=("✓ " if task.done else "○ ")+task.text
			row.custom_minimum_size.x=width
			row.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			row.add_theme_font_size_override("font_size",20)
			row.add_theme_color_override("font_color",GOLD if task.done else CREAM)
			content.add_child(row)

func quest_pulse(time: float) -> float:
	var phase=fposmod(time,5.0)
	if phase<=1.7: return pow(phase/1.7,5)
	return 0.84*exp(-12*(phase-1.7))+0.16*exp(-0.7*(phase-1.7))

func status_picture(id: String) -> TextureRect:
	var picture=TextureRect.new()
	var texture=AtlasTexture.new()
	texture.atlas=Items.Art.atlas
	texture.region=Items.Art.region(id)
	picture.texture=texture
	picture.position=Vector2(6,6)
	picture.size=Vector2(32,32)
	picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return picture

func update_statuses() -> void:
	var active=game.state.active_statuses()
	if active!=shown_statuses:
		shown_statuses=active.duplicate()
		for child in status_strip.get_children():
			status_strip.remove_child(child)
			child.queue_free()
		status_icons.clear()
		for id in active:
			var button=Button.new()
			button.custom_minimum_size=Vector2(44,44)
			_button_style(button,false,true)
			button.add_child(status_picture("status_"+id))
			if id=="poison":
				var eyes=status_picture("status_poison_eyes")
				eyes.name="PoisonEyes"
				button.add_child(eyes)
			status_strip.add_child(button)
			status_icons[id]=button
	for id in active:
		var status=preload("res://statuses.gd").CATALOG[id]
		status_icons[id].tooltip_text=status.name+"\n"+status.description
		if id=="poison": status_icons[id].tooltip_text+="\n%d game minutes remaining" % ceili(game.state.status_effects.poison.remaining)
	var width=maxi(0,active.size()*48-4)
	status_strip.size=Vector2(width,44)
	status_strip.position=Vector2(640-width/2.0,14)
	status_strip.visible=not active.is_empty()

func _process(dt: float) -> void:
	if game==null or quick_tray==null: return
	update_hud()
	if is_instance_valid(modal) and modal_box!=null:
		var panel=modal.get_child(1)
		panel.size.y=clampf(modal_box.get_combined_minimum_size().y+24,80,690-panel.position.y)
	pulse_time+=dt
	if status_icons.has("poison"): status_icons.poison.get_node("PoisonEyes").modulate.a=0.3+(sin(pulse_time*3)+1)*0.35
	var glow=quest_pulse(pulse_time) if quest_unread else 0.0
	log_toggle.modulate=Color.WHITE.lerp(Color("fff2a1"),0.2+glow*0.3) if quest_unread else Color.WHITE
	var background: StyleBoxFlat=log_panel.get_theme_stylebox("panel")
	background.bg_color=Color("182d2bf5").lerp(Color("ffcf18"),glow)
	background.border_color=Color("8d9a7666").lerp(Color("fff181"),glow)
	var screen=get_viewport().get_canvas_transform()*game.state.player_position
	var avatar=Rect2(screen-Vector2(15,58)*game.camera.zoom,Vector2(30,64)*game.camera.zoom)
	var obscured=quick_tray.get_global_rect().intersects(avatar)
	quick_tray.modulate.a=move_toward(quick_tray.modulate.a,0.22 if obscured else 1.0,dt*4)

func update() -> void:
	game.state.clear_empty_slots()
	update_statuses()
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
	for quest in quest_lines():
		if quest.id not in known_quests:
			known_quests.append(quest.id)
			quest_unread=true
			pulse_time=0
	render_quests()
	for i in range(8):
		var id: String=s.quick_slots[i]
		var button: Button=quick_buttons[i]
		show_action(button,id)
		button.get_node("KeyBadge").get_child(0).text=OS.get_keycode_string(game.controls.keys["slot"+str(i+1)])
		_button_style(button,i==s.selected_slot,true)
	clock.text = "%02d:%02d" % [int(s.minute/60.0),int(s.minute/10)%6*10]
	calendar_ring.state=s
	calendar_ring.refresh()
	season_word.text=s.season_name().to_upper()
	date.text = "%02d" % s.season_day()
	calendar_details.text = "%s · year %d" % [preload("res://calendar.gd").DAYS[preload("res://calendar.gd").weekday(s.day)],s.calendar_year()]
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
	update_hud()
