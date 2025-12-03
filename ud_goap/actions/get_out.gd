extends UDGoapAction

class_name UDGetOutAction

var _out

func get_clazz(): return "UDGetOutAction"

func _init() -> void:
	_out = WorldState.get_elements("out")[0]

func is_valid(state: Dictionary, actor) -> bool:
	return true

func get_cost(_blackboard = null) -> float:
	return WorldState.out_position.distance_to(_blackboard["position"])

func get_preconditions() -> Dictionary:
	return {
		"payed": true,
		"position": _out.position
	}

func get_effects(state: Dictionary) -> Dictionary:
	return {
		"out": true
	}

func perform(actor, _delta, state = null) -> bool:
	actor._udgoap_state["out"] = true
	actor.going_already = false
	actor.vanish()
	return true
