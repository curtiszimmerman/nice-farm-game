extends RefCounted

const REST_MINUTES=360.0
const CATALOG={
	"thirsty":{"name":"Thirsty","description":"Three days without water. Energy and mana recovery are blocked, and ten maximum HP are lost each hour. Drink fresh water or a healing elixir."},
	"starving":{"name":"Starving","description":"Three weeks without food. Energy and mana recovery are blocked, and ten maximum HP are lost each hour. Eat to recover."},
	"tired":{"name":"Tired","description":"Each full day without six continuous hours of sleep adds another energy-cost multiplier and reduces energy recovery by the same factor."},
	"poison":{"name":"Poisoned","description":"Lose 2 health every 5 game minutes for one hour."}
}
