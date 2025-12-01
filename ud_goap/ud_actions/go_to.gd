extends GoapAction

class_name GoToAction

var _location: Vector3

func get_clazz(): return "GoToAction"

func is_valid(actor = null) -> bool:
	return true

func _init(location):
	_location = location

func get_cost(_blackboard = null) -> float:
	return _location.distance_to(_blackboard["position"])

func get_preconditions() -> Dictionary:
	return {}

func get_effects() -> Dictionary:
	return {
		"position": _location
	}

func perform(actor, _delta) -> bool:
	if _location.distance_to(actor.position) <= actor.do_distance:
		print(str(actor) + " CHEGOU || ||")
		actor.going_already = false
		return true
	else:
		if not actor.going_already:
			print(str(actor) + " INDO --> -->")
			actor.navigation_agent_3d.set_target_position(_location)
			actor.going_already = true
	return false
