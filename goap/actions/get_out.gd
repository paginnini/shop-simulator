extends GoapAction

class_name GetOutAction

#var going_already = false

var _out

func get_clazz(): return "GetOutAction"

func _init() -> void:
	_out = WorldState.get_elements("out")[0]

func is_valid(actor = null) -> bool:
	return true


func get_cost(_blackboard = null) -> float:
	return WorldState.out_position.distance_to(_blackboard["position"])

func get_preconditions() -> Dictionary:
	return {
		"payed": true,
		"position": _out.position
	}

func get_effects() -> Dictionary:
	return {
		"out": true,
	}


func perform(actor, _delta) -> bool:
	actor._goap_state.set("out", true)
	actor.going_already = false
	actor.vanish()
	return true
