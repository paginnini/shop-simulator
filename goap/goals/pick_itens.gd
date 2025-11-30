extends GoapGoal

class_name PickItensGoal

func get_clazz(): return "PickItensGoal"


func is_valid(actor) -> bool:
	if actor._goap_state["is_satisfied"] or actor._goap_state["done_shopping"]:
		return false
	return true

# generic has lower priority compared to other goals
func priority(actor) -> int:
	return 6

func get_desired_state() -> Dictionary:
	return {
		"is_satisfied": true
	}
