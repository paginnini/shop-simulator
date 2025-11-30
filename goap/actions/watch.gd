extends GoapAction

class_name WatchAction

#var going_already = false

var _tv

func get_clazz(): return "WatchAction"


func is_valid(actor = null) -> bool:
	return true

func _init() -> void:
	_tv = WorldState.get_elements("tv")[0]

func get_cost(_blackboard = null) -> float:
	return _tv.position.distance_to(_blackboard["position"])


func get_preconditions() -> Dictionary:
	return {
		"position": _tv.position
	}


func get_effects() -> Dictionary:
	return {
		"watching": true,
	}


func perform(actor, _delta) -> bool:
	#print("perform ação watch")
	#print("ASSISTINDO TV ---------------------------------------------------------------------------------")
	actor._goap_state.set("watching", true)
	actor.going_already = false
	actor.navigation_agent_3d.set_target_position(actor.position)
	return false
