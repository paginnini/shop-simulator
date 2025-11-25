extends GoapGoal


class_name WatchTVGoal

func get_clazz(): return "WatchTVGoal"

var _tv

# generic will always be available
func is_valid(actor) -> bool:
	if _tv.position.distance_to(actor.position) < 10:
		return false ###################################################MUDAR PRA TRUE DEPOIS
	return false


func priority(actor) -> int:
	return _tv.value
	
	

func _init() -> void:
	_tv = WorldState.get_elements("tv")[0]


func get_desired_state(actor) -> Dictionary:
	return {
		"watching": true
	}
