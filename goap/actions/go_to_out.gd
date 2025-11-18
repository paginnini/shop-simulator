extends GoapAction

class_name GoToOutAction

#var going_already = false

func get_clazz(): return "GoToOutAction"

func is_valid() -> bool:
	return true


func get_cost(_blackboard = null) -> float:
	return 0

func get_preconditions(actor) -> Dictionary:
	return {
		str(actor)+"payed": true
	}

func get_effects(actor) -> Dictionary:
	return {
		str(actor)+"out": true
	}


func perform(actor, _delta, agent) -> bool:
	if WorldState.out_position.distance_to(actor.position) < 1.0:
		WorldState.set_state(str(actor)+"out", true)
		actor.going_already = false
		actor.vanish()
		return true
	else:
		if not actor.going_already:
			actor.navigation_agent_3d.set_target_position(WorldState.out_position)
			actor.going_already = true
	return false
