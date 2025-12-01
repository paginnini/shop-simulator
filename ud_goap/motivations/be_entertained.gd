extends GoapMotivation

class_name BeEntertainedMotivation

const WEIGHT = 0.8

var _curve

func get_clazz() -> String:
	return "BeEntertained"

func get_utility(state) -> float:
	# Wants entertainment to be high.
	# 0.0 = Bored, 1.0 = Entertained
	var val = state["current_entertainment"] / state["entertainment_limit"]
	if _curve:
			return _curve.sample(val) * WEIGHT
	return clamp(val, 0.0, 1.0) * WEIGHT
