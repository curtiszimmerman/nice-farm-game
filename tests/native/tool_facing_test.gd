extends SceneTree
const Motion=preload("res://tool_motion.gd")
var failed=false
func _initialize() -> void:
	var motion=Motion.new()
	if not motion.has_method("pose"):
		push_error("FAIL: tool poses account for the business end and facing direction")
		quit(1)
		return
	for id in ["hoe","watering_can","pickaxe","axe","sickle","rusty_sword"]:
		for facing in ["up","down","left","right"]:
			var pose=Motion.pose(id,facing,0.6)
			var tip=pose.tip*pose.scale
			tip=tip.rotated(pose.angle).normalized()
			var forward={"up":Vector2.UP,"down":Vector2.DOWN,"left":Vector2.LEFT,"right":Vector2.RIGHT}[facing]
			if tip.dot(forward)<0.8:
				failed=true
				push_error("FAIL: business end faces away: "+id+" / "+facing)
	print("PASS: working ends face the acted-on tile in all four directions" if not failed else "Tool orientation failed")
	if Motion.DURATION>0.33: failed=true; push_error("FAIL: tool animation should run twice as fast")
	else: print("PASS: tool motions take half their former duration")
	quit(1 if failed else 0)
