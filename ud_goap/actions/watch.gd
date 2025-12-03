extends UDGoapAction

class_name UDWatchAction

var _tv
var entertainment_gain = 30.0  # How much entertainment this provides

func get_clazz(): return "UDWatchAction"

func is_valid(state: Dictionary, actor = null) -> bool:
	return true

func _init() -> void:
	_tv = WorldState.get_elements("tv")[0]

func get_cost(_blackboard = null) -> float:
	return _tv.position.distance_to(_blackboard["position"])

func get_preconditions() -> Dictionary:
	return {
		"position": _tv.position
	}

func get_effects(state: Dictionary) -> Dictionary:
	return {
		"current_entertainment": entertainment_gain,
		"watching": true
	}

func perform(actor, _delta, state = null) -> bool:
	#print(str(self) + " watching")
	actor._udgoap_state["current_entertainment"] += entertainment_gain
	actor._udgoap_state["watching"] = true
	actor.going_already = false
	actor.navigation_agent_3d.set_target_position(actor.position)
	return false  # Continuous action - doesn't complete immediately
