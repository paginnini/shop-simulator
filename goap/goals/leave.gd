extends GoapGoal


class_name LeaveGoal

func get_clazz(): return "LeaveGoal"

# generic will always be available
func is_valid(actor) -> bool:
	return true

# generic has lower priority compared to other goals
func priority(actor) -> int:
	return 0

func get_desired_state(actor) -> Dictionary:
	return {
		"bill": 0.0,
		"out": true
	}
