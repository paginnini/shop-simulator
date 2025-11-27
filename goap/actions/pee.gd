extends GoapAction

class_name PeeAction


func get_clazz(): return "PeeAction"

func is_valid(blackboard = null) -> bool:
	return true


func get_cost(_blackboard = null) -> float:
	if _blackboard["actor"].ud_goap:
		return 0.0
	else:
		return WorldState.wc_position.distance_to(_blackboard["position"])

func get_preconditions(_blackboard = null) -> Dictionary:
	return {}

func get_effects(_blackboard = null) -> Dictionary:
	return {
		"used_wc": true,
		"bladder": 0.0,
		"position": WorldState.wc_position
	}


func perform(actor, _delta, agent) -> bool:
	if WorldState.wc_position.distance_to(actor.position) <= 1.0:
		actor._state.set("used_wc", true)
		actor._state.set("bladder", 0.0)
		actor.going_already = false
		return true
	else:
		if not actor.going_already:
			actor.navigation_agent_3d.set_target_position(WorldState.wc_position)
			actor.going_already = true
	return false
