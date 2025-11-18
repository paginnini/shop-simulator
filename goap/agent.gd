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
		WorldState.set_state(str(_actor)+"watching", false)
		for s in WorldState._state:
			blackboard[s] = WorldState._state[s]

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
	#print("KEYS: ", keys)
	#print(a, b, c)
	if a: actor.hunger = actor.food_limit
	if b: actor.thirst = actor.drink_limit
	if c: actor.hygiene = actor.product_limit
	#print("a: ", a, " | actor.hunger: ", actor.hunger, " | actor.food_limit: ", actor.food_limit)
	#print("b: ", b, " | actor.thirst: ", actor.thirst, " | actor.drink_limit: ", actor.drink_limit)
	#print("c: ", c, " | actor.hygiene: ", actor.hygiene, " | actor.product_limit: ", actor.product_limit)
	WorldState.set_state(str(actor)+"hunger", actor.hunger)
	WorldState.set_state(str(actor)+"thirst", actor.thirst)
	WorldState.set_state(str(actor)+"hygiene", actor.hygiene)
	WorldState.set_state(str(actor)+"hunger_limit", a)
	WorldState.set_state(str(actor)+"thirst_limit", b)
	WorldState.set_state(str(actor)+"hygiene_limit", c)
	WorldState.set_state(str(actor)+"payed", false)
	WorldState.set_state(str(actor)+"out", false)
	
	var actions = [
		PayAction.new(),
		GoToOutAction.new(),
		WatchAction.new(),
		GoToWCAction.new()
	]
	
	for item in WorldState.get_elements("food"):
		if not item.client_holding or a:
			actions.push_back(GoToFoodAction.new(item))
	for item in WorldState.get_elements("drink"):
		if not item.client_holding or b:
			actions.push_back(GoToDrinkAction.new(item))
	for item in WorldState.get_elements("product"):
		if not item.client_holding or c:
			actions.push_back(GoToProductAction.new(item))
	
	##print("acoes do agente: ")
	#for i in actions:
	#	print("   ", i.get_clazz())
	_action_planner.set_actions(actions)
	
	print("\n",WorldState.item_types)
	var preference_itens = []
	WorldState.item_types.shuffle()
	for i in randi_range(1, WorldState.item_types.size()/2):
		preference_itens.append(WorldState.item_types[i])
	print(WorldState.item_types)
	print(preference_itens)
	


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
		print("teste")
		_current_plan_step += 1
