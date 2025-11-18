extends GoapGoal


class_name LeaveGoal

func get_clazz(): return "LeaveGoal"

# generic will always be available
func is_valid(actor) -> bool:
	return true

# generic has lower priority compared to other goals
func priority(actor) -> int:
	return 3

func get_desired_state(actor) -> Dictionary:
	return {
		str(actor)+"payed": true,
		str(actor)+"out": true
	}
