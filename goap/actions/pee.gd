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
		"used_wc": true,
		"needs_wc": false,
		#"bladder": 0.0,
	}


func perform(actor, _delta) -> bool:
	#talvez botar um timer
	print(str(actor) + " MIJOU")
	actor._goap_state.set("used_wc", true)
	actor.current_bladder = 0.0
	actor.going_already = false
	return true
