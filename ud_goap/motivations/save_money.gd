extends GoapMotivation

class_name SaveMoneyMotivation

const WEIGHT = 0.5

var _curve

func get_clazz() -> String:
	return "SaveMoney"

func get_utility(state) -> float:
	# Wants to minimize the bill relative to starting money.
	if state["initial_money"] <= 0: 
		return 0.0
		
	var ratio = state["current_bill"] / state["initial_money"]
	# Utility 0.0 = Spent all money (Bill == Initial)
	# Utility 1.0 = Spent nothing (Bill == 0)
	var val = 1.0 - clamp(ratio, 0.0, 1.0)
	
	return val * WEIGHT
