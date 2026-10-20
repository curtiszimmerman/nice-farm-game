extends Control

const Art=preload("res://art.gd")
const DAYS=["Root","Ember","Tide","Stone","Gale","Star","Veil"]
const PURPLE_NAME="Sael"
const WHITE_NAME="Iri"
const YEAR_DAYS=112.0
var state: RefCounted
var signature=""

static func weekday(day: int) -> int: return posmod(day-1,7)
static func orbit(days: float,period: float) -> float: return fposmod(days/period,1.0)
static func phase(days: float,period: float) -> float: return fposmod(days/period-days/YEAR_DAYS,1.0)
static func phase_index(days: float,period: float) -> int: return posmod(roundi(phase(days,period)*16),16)

func refresh() -> void:
	var days=state.day-1+state.minute/1440.0
	var next="%d/%s/%d/%d" % [weekday(state.day),state.season_name(),phase_index(days,56),phase_index(days,28)]
	if next==signature: return
	signature=next
	tooltip_text="%s day · %s, purple moon: 56-day orbit · %s, white moon: 28-day orbit" % [DAYS[weekday(state.day)],PURPLE_NAME,WHITE_NAME]
	queue_redraw()

func _draw() -> void:
	if state==null: return
	var days=state.day-1+state.minute/1440.0
	Art.sprite(self,"moon_purple"+str(phase_index(days,56)),Vector2(40,0),Vector2(48,48))
	Art.sprite(self,"moon_white"+str(phase_index(days,28)),Vector2(128,0),Vector2(48,48))
	Art.sprite(self,"calendar_ring"+str(weekday(state.day)),Vector2(36,72),Vector2(128,128))
	Art.sprite(self,"season_"+state.season_name(),Vector2(74,124),Vector2(32,32))
	var font=preload("res://pixel_ui.gd").font()
	draw_string(font,Vector2(52,62),PURPLE_NAME,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("ccb0ef"))
	draw_string(font,Vector2(143,62),WHITE_NAME,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("f5eccc"))
