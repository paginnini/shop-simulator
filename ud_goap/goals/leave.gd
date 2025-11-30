extends UDGoapGoal


class_name UDLeaveGoal

func get_clazz(): return "UDLeaveGoal"

# generic will always be available
func is_valid(actor) -> bool:
	return true

# generic has lower priority compared to other goals
func priority(actor) -> int:
	return 3

func get_desired_state(actor) -> Dictionary:
	return {
		#"payed": true,
		"out": true
	}
