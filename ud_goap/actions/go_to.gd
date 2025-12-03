extends UDGoapAction

class_name UDGoToAction

var _object
var _position: Vector3

func get_clazz(): return "UDGoToAction"

func is_valid(state: Dictionary, actor) -> bool:
	return true

func _init(object):
	_object = object
	_position = _object.position

func get_cost(_blackboard = null) -> float:
	return _position.distance_to(_blackboard["position"])

func get_preconditions() -> Dictionary:
	return {}

func get_effects(state: Dictionary) -> Dictionary:
	return {
		"position": _position
	}

func perform(actor, _delta, state = null) -> bool:
	if _position.distance_to(actor.position) <= _object.do_distance:
		#print(str(actor) + " CHEGOU || ||")
		#print("object position: ", _position)
		#print("client position: ", actor.position)
		#print(str(actor) + " CHEGOU || ||")
		actor.going_already = false
		return true
	else:
		if not actor.going_already:
			#print(str(actor) + " INDO --> -->")
			actor.navigation_agent_3d.set_target_position(_position)
			actor.going_already = true
	return false
