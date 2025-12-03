extends GoapMotivation

class_name BeEntertainedMotivation

const WEIGHT = 1.0

var _curve = preload("res://curves/entertainement.tres")

var can_be_primary = true

func get_clazz() -> String:
	return "BeEntertained"

func get_utility(state) -> float:
	var motivation_val = 1.0
	# Wants entertainment to be high.
	# 0.0 = Bored, 1.0 = Entertained
	if WorldState.get_elements("tv")[0].position.distance_to(state["position"]) < 10.0:
		motivation_val = clamp(1.0 - state["current_entertainment"] / state["entertainment_limit"], 0.0, 1.0)
	
	if _curve:
			return _curve.sample(motivation_val)
	return motivation_val

func get_w_utility(state) -> float:
	return get_utility(state) * WEIGHT 

func is_valid(actor) -> bool:
	#if _tv.position.distance_to(actor.position) < 10:
	#	return true
	return false

#func priority(actor) -> int:
	#return _tv.value


#filter keys
func condition() -> Dictionary:
	return {
		"subject": "actor",
		"variable": "watching"
		}

#generate goal
func generate_goal(actor) -> Dictionary:
	return {
		"filter_key": condition(),
		"motivation_object": actor
	}
