extends GoapAction

class_name GoToWCAction

#var going_already = false

func get_clazz(): return "GoToWCAction"

func is_valid() -> bool:
	return true


func get_cost(_blackboard = null) -> float:
	return 0

func get_preconditions(actor) -> Dictionary:
	return {}

func get_effects(actor) -> Dictionary:
	return {
		str(actor)+"used_wc": true
	}


func perform(actor, _delta, agent) -> bool:
	if WorldState.wc_position.distance_to(actor.position) < 1.0:
		WorldState.set_state(str(actor)+"used_wc", true)
		actor.going_already = false
		return true
	else:
		if not actor.going_already:
			actor.navigation_agent_3d.set_target_position(WorldState.wc_position)
			actor.going_already = true
	return false
