extends GoapAction

class_name GetOutAction

#var going_already = false

func get_clazz(): return "GetOutAction"

func is_valid() -> bool:
	return true


func get_cost(_blackboard = null) -> float:
	return 0

func get_preconditions(actor, blackboard = null) -> Dictionary:
	return {
		"bill": 0.0
	}

func get_effects(actor, blackboard = null) -> Dictionary:
	return {
		"out": true
	}


func perform(actor, _delta, agent) -> bool:
	if WorldState.out_position.distance_to(actor.position) < 1.0:
		actor._state.set("out", true)
		actor.going_already = false
		actor.vanish()
		return true
	else:
		if not actor.going_already:
			actor.navigation_agent_3d.set_target_position(WorldState.out_position)
			actor.going_already = true
	return false
