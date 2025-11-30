extends UDGoapGoal


class_name UDUseWCGoal

func get_clazz(): return "UDUseWCGoal"

# generic will always be available
func is_valid(actor) -> bool:
	if actor._state["bladder"] >= actor._state["bladder_limit"]/3 and not actor._state["used_wc"]:
		return true
	return false

# generic has lower priority compared to other goals
func priority(actor) -> int:
	if actor._state["bladder"] >= actor._state["bladder_limit"]*2/3:
		return 10
	else:
		return 5

func get_desired_state(actor) -> Dictionary:
	return {
		"used_wc": true
	}
