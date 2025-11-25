extends GoapAction

class_name WatchAction

#var going_already = false

var _tv

func get_clazz(): return "WatchAction"


func is_valid() -> bool:
	return true

func _init() -> void:
	_tv = WorldState.get_elements("tv")[0]

func get_cost(_blackboard = null) -> float:
	return 0


func get_preconditions(actor = null, blackboard = null) -> Dictionary:
	return {}


func get_effects(actor, blackboard = null) -> Dictionary:
	return {
		"watching": true
	}


func perform(actor, _delta, agent) -> bool:
	#print("perform ação watch")
	if _tv.position.distance_to(actor.position) < actor.do_distance:
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
