extends GoapGoal


class_name UseWCGoal

func get_clazz(): return "UseWCGoal"

# generic will always be available
func is_valid(actor) -> bool:
	if actor.current_bladder >= actor.bladder_limit/3 and not actor._goap_state["used_wc"]:
		return true
	return false

# generic has lower priority compared to other goals
func priority(actor) -> int:
	if actor._goap_state["needs_wc"]:
		return 10
	else:
		return 5

func get_desired_state() -> Dictionary:
	return {
		"used_wc": true
	}
