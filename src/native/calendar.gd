extends Control

const Art=preload("res://art.gd")
const DAYS=preload("res://weekday_magic.gd").DAYS
const PURPLE_NAME="Sael"
const WHITE_NAME="Iri"
const YEAR_DAYS=112.0
var state: RefCounted
var signature=""
var displayed_day=-1
var previous_day=-1
var transition=1.0

func _process(dt: float) -> void:
	if transition>=1: return
	transition=minf(1,transition+dt/1.8)
	queue_redraw()

static func weekday(day: int) -> int: return posmod(day-1,7)
static func orbit(days: float,period: float) -> float: return fposmod(days/period,1.0)
static func phase(days: float,period: float) -> float: return fposmod(days/period-days/YEAR_DAYS,1.0)
static func phase_index(days: float,period: float) -> int: return posmod(roundi(phase(days,period)*16),16)

static func pendulum_angle(minute: float) -> float:
	var step=int(floor(minute/10.0))
	var t=fposmod(minute,10.0)/10.0
	var eased=1.0-pow(1.0-t,5)
	return lerpf(-0.5,0.5,eased) if step%2==0 else lerpf(0.5,-0.5,eased)

func refresh() -> void:
	if displayed_day<0: displayed_day=state.day
	if displayed_day!=state.day:
		previous_day=displayed_day
		displayed_day=state.day
		transition=0
	var days=state.day-1+state.minute/1440.0
	var next="%d/%s/%d/%d/%.2f" % [weekday(state.day),state.season_name(),phase_index(days,56),phase_index(days,28),state.minute]
	if next==signature: return
	signature=next
	tooltip_text="%s day · %s, purple moon: 56-day orbit · %s, white moon: 28-day orbit" % [DAYS[weekday(state.day)],PURPLE_NAME,WHITE_NAME]
	queue_redraw()

func _draw() -> void:
	if state==null: return
	var days=state.day-1+state.minute/1440.0
	Art.sprite(self,"moon_purple"+str(phase_index(days,56)),Vector2(60,0),Vector2(48,48))
	Art.sprite(self,"moon_white"+str(phase_index(days,28)),Vector2(148,0),Vector2(48,48))
	var turn=posmod(state.day-previous_day,7)*TAU/7.0 if previous_day>=0 else 0.0
	if transition<1 and previous_day>=0:
		var eased=smoothstep(0.0,1.0,transition)
		draw_set_transform(Vector2(128,162),eased*turn)
		Art.sprite(self,"calendar_ring"+str(weekday(previous_day)),Vector2(-96,-96),Vector2(192,192),Color(1,1,1,1-eased))
		draw_set_transform(Vector2.ZERO)
	draw_set_transform(Vector2(128,162),(smoothstep(0.0,1.0,transition)-1)*turn)
	Art.sprite(self,"calendar_ring"+str(weekday(state.day)),Vector2(-96,-96),Vector2(192,192),Color(1,1,1,smoothstep(0.0,1.0,transition)))
	draw_set_transform(Vector2.ZERO)
	Art.sprite(self,"season_"+state.season_name(),Vector2(88,162),Vector2(35,35))
	var font=preload("res://pixel_ui.gd").font()
	draw_string(font,Vector2(50,64),PURPLE_NAME,HORIZONTAL_ALIGNMENT_CENTER,68,16,Color("ccb0ef"))
	draw_string(font,Vector2(138,64),WHITE_NAME,HORIZONTAL_ALIGNMENT_CENTER,68,16,Color("f5eccc"))
	draw_set_transform(Vector2(128,342-100*cos(0.5)+24),pendulum_angle(state.minute))
	draw_rect(Rect2(-4,0,8,7),Color("73562d"))
	draw_rect(Rect2(-2,7,4,93),Color("d8b568"))
	draw_rect(Rect2(0,8,1,89),Color("f9e3a5"))
	draw_rect(Rect2(-14,99,28,17),Color("71502b"))
	draw_rect(Rect2(-12,101,24,13),Color("c99d4c"))
	draw_rect(Rect2(-9,103,11,3),Color("f3d985"))
	draw_rect(Rect2(-6,116,12,3),Color("503a26"))
	draw_set_transform(Vector2.ZERO)
