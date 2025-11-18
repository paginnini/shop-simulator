extends GoapGoal


class_name UseWCGoal

func get_clazz(): return "UseWCGoal"

# generic will always be available
func is_valid(actor) -> bool:
	if actor.thirst >= actor.drink_limit/3:
		return true if not WorldState.get_state(str(actor)+"used_wc") else false
	return false

# generic has lower priority compared to other goals
func priority(actor) -> int:
	if actor.thirst >= actor.drink_limit*2/3:
		return 10
	else:
		return 5

func get_desired_state(actor) -> Dictionary:
	return {
		str(actor)+"used_wc": true
	}
