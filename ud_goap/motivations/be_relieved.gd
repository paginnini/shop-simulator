extends GoapMotivation

class_name BeRelievedMotivation

const WEIGHT = 1.5

var _curve

func get_clazz() -> String:
	return "BeRelieved"

func get_utility(state) -> float:
	# Wants bladder to be empty.
	# If bladder is full (100), utility is 0. 
	# If empty (0), utility is 1.
	var val = 1.0 - (state["current_bladder"] / state["bladder_limit"])
	if _curve:
			return _curve.sample(val) * WEIGHT
	return clamp(val, 0.0, 1.0) * WEIGHT
