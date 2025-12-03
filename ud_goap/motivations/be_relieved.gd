extends GoapMotivation

class_name BeRelievedMotivation

const WEIGHT = 1.0

var _curve = preload("res://curves/bladder.tres")

var can_be_primary = true

func get_clazz() -> String:
	return "BeRelieved"

func get_utility(state) -> float:
	# Wants bladder to be empty.
	# If bladder is full (100), utility is 0. 
	# If empty (0), utility is 1.
	var val = clamp(1.0 - (state["current_bladder"] / state["bladder_limit"]), 0.0, 1.0)
	if _curve:
			return _curve.sample(val)
	return val

func get_w_utility(state) -> float:
	return get_utility(state) * WEIGHT 

#filter keys
func condition() -> Dictionary:
	return {
		"subject": "actor",
		"variable": "current_bladder"
		}

#generate goal
func generate_goal(actor) -> Dictionary:
	return {
		"filter_key": condition(),
		"motivation_object": actor
	}
