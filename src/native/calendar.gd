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
	if transition<1 and previous_day>=0:
		var eased=smoothstep(0.0,1.0,transition)
		draw_set_transform(Vector2(128,168),eased*TAU/7.0)
		Art.sprite(self,"calendar_ring"+str(weekday(previous_day)),Vector2(-96,-96),Vector2(192,192),Color(1,1,1,1-eased))
		draw_set_transform(Vector2.ZERO)
	draw_set_transform(Vector2(128,168),(smoothstep(0.0,1.0,transition)-1)*TAU/7.0)
	Art.sprite(self,"calendar_ring"+str(weekday(state.day)),Vector2(-96,-96),Vector2(192,192),Color(1,1,1,smoothstep(0.0,1.0,transition)))
	draw_set_transform(Vector2.ZERO)
	Art.sprite(self,"season_"+state.season_name(),Vector2(88,162),Vector2(20,20))
	var font=preload("res://pixel_ui.gd").font()
	draw_string(font,Vector2(64,62),PURPLE_NAME,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("ccb0ef"))
	draw_string(font,Vector2(158,62),WHITE_NAME,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("f5eccc"))
	draw_set_transform(Vector2(128,342-128*cos(0.5)),pendulum_angle(state.minute))
	Art.sprite(self,"clock_pendulum",Vector2(-32,0),Vector2(64,128))
	draw_set_transform(Vector2.ZERO)
