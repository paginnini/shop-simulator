#
# Action Contract
#
extends Node

class_name UDGoapAction


func is_valid(state: Dictionary, actor) -> bool:
	return true


func get_cost(_blackboard = null) -> float:
	return 1000

#
func get_preconditions() -> Dictionary:
	return {}


func get_effects(state: Dictionary) -> Dictionary:
	return {}


func perform(_actor, _delta, state) -> bool:
	return false
