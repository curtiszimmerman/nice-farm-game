extends RefCounted

const DEFAULTS={"up":KEY_W,"down":KEY_S,"left":KEY_A,"right":KEY_D,"run":KEY_SHIFT,"primary":KEY_E,"aux":KEY_Q,"inventory":KEY_I,"journal":KEY_J,"map":KEY_M,"menu":KEY_ESCAPE,"pause":KEY_SPACE,"fullscreen":KEY_F11,"slot1":KEY_1,"slot2":KEY_2,"slot3":KEY_3,"slot4":KEY_4,"slot5":KEY_5,"slot6":KEY_6,"slot7":KEY_7,"slot8":KEY_8}
const LABELS={"inventory_row":"Next inventory row","up":"Walk up","down":"Walk down","left":"Walk left","right":"Walk right","run":"Run","primary":"Primary action / left click","aux":"Auxiliary action / right click","inventory":"Inventory","journal":"Crew log","map":"Map","menu":"Game menu","pause":"Pause world","fullscreen":"Fullscreen"}
const PATH="res://../../internal/controls.cfg"
var keys=DEFAULTS.duplicate()
var show_target=true

func _init() -> void:
	reset()

func reset() -> void:
	keys=DEFAULTS.duplicate()
	keys["inventory_row"]=KEY_TAB
	keys.merge({"up_arrow":KEY_UP,"down_arrow":KEY_DOWN,"left_arrow":KEY_LEFT,"right_arrow":KEY_RIGHT})

func matches(event: InputEvent,action: String) -> bool:
	return event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==keys[action]

func held(action: String) -> bool:
	return Input.is_physical_key_pressed(keys[action])

func rebind(action: String,key: int) -> void:
	if not keys.has(action) or key==0: return
	var old=keys[action]
	for other in keys:
		if other!=action and keys[other]==key: keys[other]=old
	keys[action]=key

func save(path: String=PATH) -> Error:
	var file=ConfigFile.new()
	file.set_value("display","show_target",show_target)
	for action in keys: file.set_value("keyboard",action,keys[action])
	return file.save(path)

func load_keys(path: String=PATH) -> void:
	var file=ConfigFile.new()
	if file.load(path)!=OK: return
	var loaded={}
	for action in keys:
		var key=file.get_value("keyboard",action)
		if not key is int or key<=0 or key in loaded.values(): return
		loaded[action]=key
	keys=loaded
	var display=file.get_value("display","show_target",true)
	if display is bool: show_target=display
