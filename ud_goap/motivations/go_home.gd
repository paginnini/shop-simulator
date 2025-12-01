extends GoapMotivation

class_name GoHomeMotivation

const WEIGHT = 1.0


func get_clazz() -> String:
	return "GoHome"

func get_utility(state) -> float:
	# Binary utility state:
	# 0.0 = In Shop (Urgent need to leave if other needs are met)
	# 1.0 = Left Shop (Satisfied)
	
	# Note: In the original file logic, it checked _goap_state["out"].
	# Since 'actor' holds the state, we access it there.
	var is_out = state["out"]
	
	return (1.0 if is_out else 0.0) * WEIGHT
