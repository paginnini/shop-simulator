extends GoapGoal


class_name UseWCGoal

func get_clazz(): return "UseWCGoal"

# generic will always be available
func is_valid(actor) -> bool:
	if actor._state["used_wc"]:
		return false
	return true

# generic has lower priority compared to other goals
func priority(actor) -> int:
	if actor._state.get("satisfaction") >= actor._state.get("satisfaction_limit")*2/3:
		return 10
	else:
		return 5

func get_desired_state(actor) -> Dictionary:
	return {
		"used_wc": true
	}
