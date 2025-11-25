extends GoapAction

class_name PeeAction

#var going_already = false

func get_clazz(): return "PeeAction"

func is_valid() -> bool:
	return true


func get_cost(_blackboard = null) -> float:
	return _blackboard["position"].distance_to(WorldState.wc_position)

func get_preconditions(actor = null, blackboard = null) -> Dictionary:
	return {}

func get_effects(actor, blackboard = null) -> Dictionary:
	return {
		"used_wc": true
	}


func perform(actor, _delta, agent) -> bool:
	if WorldState.wc_position.distance_to(actor.position) < 1.0:
		actor._state.set("used_wc", true)
		actor.going_already = false
		return true
	else:
		if not actor.going_already:
			actor.navigation_agent_3d.set_target_position(WorldState.wc_position)
			actor.going_already = true
	return false
