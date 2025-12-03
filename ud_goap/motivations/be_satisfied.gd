extends GoapMotivation

class_name BeSatisfiedMotivation

const WEIGHT = 1.0

var _curve

var can_be_primary = true

func get_clazz() -> String:
	return "BeSatisfied"

func get_utility(state) -> float:
	# Wants current_satisfaction to be high.
	# 0.0 = Hungry, 1.0 = Full
	var val = clamp(state["current_satisfaction"] / state["satisfaction_limit"], 0.0, 1.0)
	if _curve:
			return _curve.sample(val)
	return val

func get_w_utility(state) -> float:
	return get_utility(state) * WEIGHT 

#filter keys
func condition() -> Dictionary:
	return {
		"subject": "actor",
		"variable": "current_satisfaction"
		}

#generate goal
func generate_goal(actor) -> Dictionary:
	return {
		"filter_key": condition(),
		"motivation_object": actor
	}
