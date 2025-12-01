extends GoapAction

class_name PeeAction

var _wc

func get_clazz(): return "PeeAction"

func _init():
	_wc = WorldState.get_elements("wc")[0]

func is_valid(actor = null) -> bool:
	return true

func get_cost(_blackboard = null) -> float:
	return WorldState.wc_position.distance_to(_blackboard["position"])

func get_preconditions() -> Dictionary:
	return {
		"position": _wc.position
	}

func get_effects() -> Dictionary:
	return {
		"current_bladder": -100.0,  # Reset bladder completely
		"used_wc": true
	}

func perform(actor, _delta) -> bool:
	print(str(actor) + " MIJOU")
	actor._udgoap_state["current_bladder"] = 0.0
	actor._udgoap_state["used_wc"] = true
	actor._udgoap_state["needs_wc"] = false
	actor.going_already = false
	return true
