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

var _action_planner = GoapActionPlanner.new()

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
		_actor.set("watching", false)
		#for s in WorldState._state:
		#	blackboard[s] = WorldState._state[s]

		_current_goal = goal
		_current_plan = _action_planner.get_plan(_current_goal, blackboard)
		_current_plan_step = 0
		_actor.going_already = false
		print("current goal: ", _current_goal.get_clazz())
	else:
		_follow_plan(_current_plan, delta)


# ---------------------------------------------------------------------------------------------------------------------------
func init(actor, goals: Array):
	_actor = actor
	_goals = goals
	
	var keys = ["a", "b", "c"]
	# Randomly choose how many will be true: 1 or 2
	var amount_to_enable = randi_range(1, 2)
	keys.shuffle()
	# Set the first X to true
	for i in range(amount_to_enable):
		self.set(keys[i], true)
	# Set the rest to false
	for i in range(amount_to_enable, keys.size()):
		self.set(keys[i], false)
	
	var actions = [
		PayAction.new(),
		GetOutAction.new(),
		WatchAction.new(),
		PeeAction.new(),
	]
	for item in WorldState.get_elements("item"):
		if not item.client_holding:
			actions.push_back(PickItemAction.new(item))
	#print(actions)
	
	##print("acoes do agente: ")
	for i in actions:
		print("   ", i.get_clazz())
	_action_planner.set_actions(actions)
	
	# ESCOLHE TIPOS DE ITEM QUE QUER COMPRAR
	print("\n",WorldState.item_types)
	var preference_itens = []
	WorldState.item_types.shuffle()
	@warning_ignore("integer_division")
	for i in randi_range(1, WorldState.item_types.size()/2):
		preference_itens.append(WorldState.item_types[i])
	print(WorldState.item_types)
	print(preference_itens)
	
	#DEFINE PREFERENCIA ENTRE AÇÕES
	for i in _actor.preference:
		print(i)
		_actor.preference.set(i, float(randi_range(1, 9))/10.0)
	print(_actor.preference)


#d
# Returns the highest priority goal available.
#
func _get_best_goal():
	var highest_priority
	
	for goal in _goals:
		#print(goal.get_clazz(), " priority: ", goal.priority(_actor), "  | is valid: ", goal.is_valid(_actor))
		@warning_ignore("unassigned_variable")
		if goal.is_valid(_actor) and (highest_priority == null or goal.priority(_actor) > highest_priority.priority(_actor)):
			highest_priority = goal
	
	#print("best goal: ", highest_priority.get_clazz())
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
		print("completou action")
		_current_plan_step += 1
