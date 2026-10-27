extends SceneTree
const State=preload("res://state.gd")
var failed=false
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: "+label)
	else: failed=true; push_error("FAIL: "+label)
func _initialize() -> void:
	var s=State.new()
	for tool in ["hoe","watering_can","sickle","axe","pickaxe","fishing_pole","rusty_sword","pot","pan"]:
		s=State.new()
		s.set(tool,1)
		check(not s.give_gift("moss",tool) and s.get(tool)==1,"essential equipment cannot be gifted: "+tool)
	s=State.new()
	check(s.accept_tool("axe"),"Rowan can lend the starting axe")
	s.advance(10079)
	check(not s.requests.axe_failed,"the player has a full seven days to repay Rowan")
	s.advance(1)
	check(s.requests.axe_failed and s.friendships.woodcutter== -5 and s.axe==1,"missing the deadline costs five friendship and never confiscates the axe")
	s.advance(1440)
	check(s.friendships.woodcutter== -5,"the deadline penalty happens only once")
	s.wood=10
	check(s.repay_axe() and s.wood==0 and not s.repay_axe(),"late repayment consumes ten logs exactly once")
	s=State.new()
	s.turnips=2
	check(not s.accept_sword() and s.turnips==2,"Bram never takes a partial sword payment")
	s.turnips=3
	check(s.accept_sword() and s.turnips==0 and s.rusty_sword==1,"three moon turnips buy Bram's sword")
	check(s.gift_preference("veteran","turnips")==5,"Bram loves moon turnip gifts")
	s=State.new()
	s.money=249
	check(not s.buy_sword() and s.money==249,"Dain's sword requires the full 250 crowns")
	s.money=250
	check(s.buy_sword() and s.money==0 and s.rusty_sword==1,"Dain can sell the expensive alternative")
	var loaded=State.new()
	check(loaded.restore(s.to_dict()),"the expanded request state survives a real save snapshot")
	quit(1 if failed else 0)
