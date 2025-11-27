extends GoapAction

class_name WatchAction

#var going_already = false

var _tv

func get_clazz(): return "WatchAction"


func is_valid(blackboard = null) -> bool:
	return true

func _init() -> void:
	_tv = WorldState.get_elements("tv")[0]

func get_cost(_blackboard = null) -> float:
	if _blackboard["actor"].ud_goap:
		return 0.0
	else:
		return _tv.position.distance_to(_blackboard["position"])


func get_preconditions(_blackboard = null) -> Dictionary:
	return {}


func get_effects(_blackboard = null) -> Dictionary:
	return {
		"watching": true,
		"position": _tv.position
	}


func perform(actor, _delta, agent) -> bool:
	#print("perform ação watch")
	if _tv.position.distance_to(actor.position) <= actor.do_distance:
		#print("ASSISTINDO TV ---------------------------------------------------------------------------------")
		actor._state.set("watching", true)
		actor.going_already = false
		actor.navigation_agent_3d.set_target_position(actor.position)
		return true
	else:
		if not actor.going_already:
			actor.navigation_agent_3d.set_target_position(_tv.position)
			actor.going_already = true
	return false
