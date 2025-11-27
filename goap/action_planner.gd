#
# Planner. Goap's heart.
#
extends Node

class_name GoapActionPlanner

var _actions: Array


#
# set actions available for planning.
# this can be changed in runtime for more dynamic options.
#
func set_actions(actions: Array):
	_actions = actions


#
# Receives a Goal and an optional blackboard.
# Returns a list of actions to be executed.
#
func get_plan(goal: GoapGoal, blackboard = {}) -> Array:
	#print("Goal: %s" % goal.get_clazz())
	WorldState.console_message("Goal: %s" % goal.get_clazz())
	
	var desired_state = goal.get_desired_state(blackboard.actor).duplicate()
	##print("\ndesired_state inicial: ")
	##print(desired_state)
	if desired_state.is_empty():
		return []
	
	# -------------------------------------------------------------------------
	# CONSTRUCT COMPLETE WORLD STATE
	# Merge: Global WorldState + Agent Internal State + Context Blackboard
	# -------------------------------------------------------------------------
	var current_world_state = {}
	# 1. Agent State (Money, Satisfaction, etc.)
	if blackboard.has("actor"):
		var actor = blackboard["actor"]
		if actor.get("_state") and actor._state is Dictionary:
			current_world_state.merge(actor._state)
	# 2. Blackboard Context (Position, Actor ref) - Overwrites if duplicates exist
	current_world_state.merge(blackboard, true)
	current_world_state.merge(WorldState._state, true)
	# -------------------------------------------------------------------------
	#print(current_world_state)
	
	var sequence = []
	_build_plan_greedy(desired_state, current_world_state, sequence)
	#if goal.get_clazz() == "PickItensGoal":
	#	sequence.reverse()
	_print_plan(sequence, current_world_state)
	#print("sequence: ",sequence)
	return sequence




func _build_plan_greedy(state, blackboard, sequence) -> bool:
	#print("\n-----------------COMEÇO DA FUNÇÃO-----------------")
	var has_followup = false
	
	# checks if the blackboard contains data that can
	# satisfy the current state.
	#print("\nblackboard: ", blackboard)
	
	#print("\nstate atual antes do blackboard:\n", state)
	var duplicado_state = state.duplicate()
	for s in duplicado_state:
		if typeof(duplicado_state[s]) == TYPE_BOOL:
			if duplicado_state[s] == blackboard.get(s):
				state.erase(s)
		elif typeof(duplicado_state[s]) == TYPE_FLOAT:
			if duplicado_state[s] <= blackboard[s]:
				state.erase(s)
	#print("\nstate atual apos verificar com blackboard:\n", state)
	
	if state.is_empty():
		return true
	
	var best_choice = null
	var minimum_cost = 10000
	##print("\n_actions antes: ", _actions.size())
	var _ac = _actions.duplicate()
	for action in _ac:
		if not action:
			_actions.erase(action)
	_ac = []
	##print("\n_actions depois: ", _actions.size())
	for action in _actions:
		#if action.get_clazz() == "PickItemAction":
			#print("-------------------------------------------------")
			#print("action nome: ", action.get_clazz())
			#print("action: ", action)
			#print("item cost: ", action._item.cost)
			#print("preference: ", blackboard["actor"].preference[action._item.type])
			#print("distance: ", action.default_item_position.distance_to(blackboard["position"]))
			#print("action cost: ", action.get_cost(blackboard))
		
		if not action.is_valid(blackboard):
			#print("action nao é valida")
			continue
		#print("action valida")
		
		var effects = action.get_effects(blackboard.actor)
		
		for s in state:
			#print("effects: ",s,": ", effects.get(s))
			if not effects.get(s): continue
			if typeof(state[s]) == TYPE_BOOL:
				if state[s] == effects.get(s):
					if action.get_cost(blackboard) < minimum_cost:
						best_choice = action
						minimum_cost = action.get_cost(blackboard)
			elif typeof(state[s]) == TYPE_FLOAT:
				if effects.get(s):
					if action.get_cost(blackboard) < minimum_cost:
						best_choice = action
						minimum_cost = action.get_cost(blackboard)
	#print("best choice: ", best_choice)
	
	if best_choice:
		
		if best_choice.get_clazz() == "PickItemAction":
			blackboard.set(str(best_choice._item)+"is_picked_up", true)
			print("-------------------------------------------------")
			#print("action nome: ", best_choice.get_clazz())
			#print("action: ", best_choice)
			print("item cost: ", best_choice._item.cost)
			print("money: ", blackboard["money"])
			print("bill: ", blackboard["bill"])
			#print("preference: ", blackboard["actor"].preference[best_choice._item.type])
			#print("distance: ", best_choice.default_item_position.distance_to(blackboard["position"]))
			#print("action cost: ", best_choice.get_cost(blackboard))
		#print("\nbest_choice cost: ", best_choice.get_cost(blackboard))
		#print("\nachou ação\n", best_choice.get_clazz())
		
		
		var preconditions = best_choice.get_preconditions(blackboard.actor)
		var effects = best_choice.get_effects(blackboard.actor)
		
		for p in preconditions:
			state[p] = preconditions[p]
		
		duplicado_state = state.duplicate()
		#print("\ndesired_state atual:\n", desired_state)
		#print("\ndesired_state: ", desired_state)
		for s in duplicado_state:
			#print("\ns: ", s)
			if typeof(duplicado_state[s]) == TYPE_BOOL:
				if duplicado_state[s] == effects.get(s):
					#print("bool element was achieved:\ndesired_state[s]: ", desired_state[s],"\neffects.get(s): ", effects.get(s))
					blackboard[s] = true
					state.erase(s)
			elif typeof(duplicado_state[s]) == TYPE_FLOAT:
				if effects.get(s):
					if duplicado_state[s] > effects.get(s) + blackboard.get(s):
						blackboard[s] += effects.get(s)
						#print("float elements was added to blackboard:\ndesired_state[s]: ", desired_state[s],"\neffects.get(s): ", effects.get(s))
						#print("blackboard.get(s): ", blackboard.get(s))
					else:
						blackboard[s] += effects.get(s)
						#print("float element was achieved:\ndesired_state[s]: ", desired_state[s],"\neffects.get(s): ", effects.get(s))
						#print("blackboard.get(s): ", blackboard.get(s))
						state.erase(s)
		
		#print("teste------------------------")
		if state.is_empty() or _build_plan_greedy(state, blackboard, sequence):
			#step.children.push_back(s)
			sequence.push_back(best_choice)
			#print("\nsequence:\n", sequence)
			has_followup = true
	
	
	#print("has_followup: ", has_followup)
	##print("-----------------FIM DA FUNÇÃO-----------------")
	return true
			
		


#
# Prints plan. Used for Debugging only.
#
func _print_plan(plan, blackboard):
	var actions = []
	var pri = []
	var custo = 0.0
	for a in plan:
		actions.push_back([a.get_clazz(), a.get_cost(blackboard)])
		pri.push_back(a.get_clazz())
		custo += a.get_cost(blackboard)
	#print("", pri)
	WorldState.console_message({"cost": custo, "actions": actions})
