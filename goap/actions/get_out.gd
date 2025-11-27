extends GoapAction

class_name GetOutAction

#var going_already = false

func get_clazz(): return "GetOutAction"

func is_valid(blackboard = null) -> bool:
	return true


func get_cost(_blackboard = null) -> float:
	if _blackboard["actor"].ud_goap:
		return 0.0
	else:
		return WorldState.out_position.distance_to(_blackboard["position"])

func get_preconditions(blackboard = null) -> Dictionary:
	return {
		"payed": true
	}

func get_effects(blackboard = null) -> Dictionary:
	return {
		"out": true,
		"position": WorldState.out_position
	}


func perform(actor, _delta, agent) -> bool:
	if WorldState.out_position.distance_to(actor.position) <= 1.0:
		actor._state.set("out", true)
		actor.going_already = false
		actor.vanish()
		return true
	else:
		if not actor.going_already:
			actor.navigation_agent_3d.set_target_position(WorldState.out_position)
			actor.going_already = true
	return false
