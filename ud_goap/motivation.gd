#
# Motivation contract (Equivalent to GoapGoal for UD-GOAP)
#
extends Node

class_name GoapMotivation

#
# Returns the calculated utility value for this motivation.
# In UD-GOAP, this combines the normalized state value (0.0 to 1.0)
# with the motivation's weight.
#
# Higher value = The state is "better" for this motivation.
# Lower value = The need is urgent.
#
func get_utility(state) -> float:
	return 0.0

#
# Returns the unique name of this motivation
#
func get_clazz() -> String:
	return "GoapMotivation"
