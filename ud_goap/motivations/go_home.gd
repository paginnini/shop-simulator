extends GoapMotivation

class_name GoHomeMotivation

const WEIGHT = 1.0

var _curve = preload("res://curves/home.tres")

var can_be_primary = true

func get_clazz() -> String:
	return "GoHomeMotivation"

func get_utility(state) -> float:
	# Wants entertainment to be high.
	# 0.0 = Bored, 1.0 = Entertained
	var motivation_val = 1.0
	if state["done_shopping"] and (state["used_wc"] or not state["needs_wc"]):
		motivation_val = 0.5
	if _curve:
			return _curve.sample(motivation_val)
	return motivation_val

func get_w_utility(state) -> float:
	return get_utility(state) * WEIGHT 

#filter keys
func condition() -> Dictionary:
	return {
		"subject": "actor",
		"variable": "out"
		}

#generate goal
func generate_goal(actor) -> Dictionary:
	return {
		"filter_key": condition(),
		"motivation_object": actor
	}
