#
# Motivation contract (Equivalent to GoapGoal for UD-GOAP)
#
extends Node

class_name GoapMotivation

#var weight

func get_clazz() -> String:
	return "GoapMotivation"

func get_utility(state) -> float:
	return 0.0

#filter keys
func condition() -> Dictionary:
	return {}

#generate goal
func generate_goal(actor) -> Dictionary:
	return {}
