extends GoapMotivation

class_name BeSatisfiedMotivation

const WEIGHT = 1.0

var _curve

func get_clazz() -> String:
	return "BeSatisfied"

func get_utility(state) -> float:
	# Wants current_satisfaction to be high.
	# 0.0 = Hungry, 1.0 = Full
	var val = state["current_satisfaction"] / state["satisfaction_limit"]
	if _curve:
			return _curve.sample(val) * WEIGHT
	return clamp(val, 0.0, 1.0) * WEIGHT
