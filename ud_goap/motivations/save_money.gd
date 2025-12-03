extends GoapMotivation

class_name SaveMoneyMotivation

const WEIGHT = 1.0

var _curve = preload("res://curves/money.tres")

var can_be_primary = false

func get_clazz() -> String:
	return "SaveMoney"

func get_utility(state) -> float:
	var val = clamp(1.0 - (state["current_bill"] / state["initial_money"]), 0.0, 1.0)
	# Utility 0.0 = Spent all money (Bill == Initial)
	# Utility 1.0 = Spent nothing (Bill == 0)
	if _curve:
			return _curve.sample(val)
	return val

func get_w_utility(state) -> float:
	return get_utility(state) * WEIGHT 



#filter keys
func condition() -> Dictionary:
	return {
		"subject": "actor",
		"variable": "current_bill"
		}

#generate goal
func generate_goal(actor) -> Dictionary:
	return {
		"filter_key": condition(),
		"motivation_object": actor
	}
