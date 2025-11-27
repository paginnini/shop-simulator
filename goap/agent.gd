#
# This script integrates the actor (NPC) with goap.
# In your implementation you could have this logic
# inside your NPC script.
#
# As good practice, I suggest leaving it isolated like
# this, so it makes re-use easy and it doesn't get tied
# to unrelated implementation details (movement, collisions, etc)
extends Node

class_name GoapAgent

var _goals
var _current_goal
var _current_plan
var _current_plan_step = 0

var _actor

var _action_planner =  GoapActionPlanner.new()

var a := false
var b := false
var c := false
#
# On every loop this script checks if the current goal is still
# the highest priority. if it's not, it requests the action planner a new plan
# for the new high priority goal.
#
func _process(delta):
	var goal = _get_best_goal()
	#print("OBJETIVO ATUAL", goal.get_clazz())
	#print(goal.get_clazz())
	if _current_goal == null or goal != _current_goal:
	# You can set in the blackboard any relevant information you want to use
	# when calculating action costs and status. I'm not sure here is the best
	# place to leave it, but I kept here to keep things simple.
		var blackboard = {
			"position": _actor.position,
			"actor": _actor
			}
		_actor._state.set("watching", false)
		_current_goal = goal
		_current_plan = _action_planner.get_plan(_current_goal, blackboard)
		_current_plan_step = 0
		_actor.going_already = false
	else:
		_follow_plan(_current_plan, delta)


# ---------------------------------------------------------------------------------------------------------------------------
func init(actor, goals: Array):
	_actor = actor
	_goals = goals
	
	var actions = [
		PayAction.new(),
		GetOutAction.new(),
		WatchAction.new(),
		PeeAction.new()
	]
	
	for item in WorldState.get_elements("item"):
		if not item.client_holding:
			actions.push_back(PickItemAction.new(item))
	
	#print("acoes do agente: ")
	#for i in actions:
		#print("   ", i.get_clazz())
	_action_planner.set_actions(actions)
	


#d
# Returns the highest priority goal available.
#
func _get_best_goal():
	var highest_priority

	for goal in _goals:
		if goal.is_valid(_actor) and (highest_priority == null or goal.priority(_actor) > highest_priority.priority(_actor)):
			highest_priority = goal

	return highest_priority


#
# Executes plan. This function is called on every game loop.
# "plan" is the current list of actions, and delta is the time since last loop.
#
# Every action exposes a function called perform, which will return true when
# the job is complete, so the agent can jump to the next action in the list.
#
func _follow_plan(plan, delta):
	if plan.size() == 0:
		return
	
	#if not plan[_current_plan_step].is_valid():
	#	_current_goal = null
	var is_step_complete = plan[_current_plan_step].perform(_actor, delta, self)
	#print(WorldState._state)
	#print(is_step_complete)
	#print(_current_plan_step)
	#print(plan.size())
	if is_step_complete and _current_plan_step < plan.size() - 1:
		print("proxima action")
		_current_plan_step += 1
