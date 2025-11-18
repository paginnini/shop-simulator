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
	##print("Goal: %s" % goal.get_clazz())
	WorldState.console_message("Goal: %s" % goal.get_clazz())
	var desired_state = goal.get_desired_state(blackboard.actor).duplicate()
	##print("\ndesired_state inicial: ")
	##print(desired_state)
	
	if desired_state.is_empty():
		return []
	
	var list_sequence = _find_best_plan(desired_state, blackboard)
	if goal.get_clazz() == "PickItensGoal":
		list_sequence.reverse()
	_print_plan(list_sequence, blackboard)
	return list_sequence



func _find_best_plan(desired_state, blackboard):
  # goal is set as root action. It does feel weird
  # but the code is simpler this way.
	
	var sequence = []
	
  # build plans will populate root with children.
  # In case it doesn't find a valid path, it will return false.
	if _build_plan_greedy(desired_state, blackboard.duplicate(), sequence):
		#3print("\ndesired_state:\n", desired_state,"\n\n")
		#var plans = _transform_tree_into_array(root, blackboard)
		##print("\nsequence:\n", sequence)
		return sequence
	
	return []


func _build_plan_greedy(state, blackboard, sequence):
	##print("\n-----------------COMEÇO DA FUNÇÃO-----------------")
	var has_followup = false
	#var state = step.state.duplicate()
	
	# checks if the blackboard contains data that can
	# satisfy the current state.
	#print("\nblackboard: ", blackboard)
	
	#print("\nstate atual antes do blackboard:\n", state)
	
	var desired_state = state.duplicate()
	for s in desired_state:
		if typeof(desired_state[s]) == TYPE_BOOL:
			if desired_state[s] == blackboard.get(s):
				state.erase(s)
		elif typeof(desired_state[s]) == TYPE_FLOAT:
			if desired_state[s] <= blackboard.get(s):
				state.erase(s)
	#print("\nstate atual apos verificar com blackboard:\n", state)
	
	if state.is_empty():
		return true
	
	var best_choice
	var minimum_cost = 10000
	##print("\n_actions antes: ", _actions.size())
	var _ac = _actions.duplicate()
	for action in _ac:
		if not action:
			_actions.erase(action)
	_ac = []
	##print("\n_actions depois: ", _actions.size())
	for action in _actions:
		#print("\naction nome: ", action.get_clazz())
		#print("action: ", action)
		#print("action cost: ", action.get_cost(blackboard))
		
		if blackboard.get(str(action)+"used") or not action.is_valid():
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
	
	
	if best_choice:
		#print("\nbest_choice cost: ", best_choice.get_cost(blackboard))
		blackboard.set(str(best_choice)+"used", true)
		#print("\nachou ação\n", best_choice.get_clazz())
		
		
		var preconditions = best_choice.get_preconditions(blackboard.actor)
		var effects = best_choice.get_effects(blackboard.actor)
		
		for p in preconditions:
			desired_state[p] = preconditions[p]
		
		desired_state = state.duplicate()
		#print("\ndesired_state atual:\n", desired_state)
		#print("\ndesired_state: ", desired_state)
		for s in desired_state:
			#print("\ns: ", s)
			if typeof(desired_state[s]) == TYPE_BOOL:
				if desired_state[s] == effects.get(s):
					#print("bool element was achieved:\ndesired_state[s]: ", desired_state[s],"\neffects.get(s): ", effects.get(s))
					blackboard[s] = true
					state.erase(s)
			elif typeof(desired_state[s]) == TYPE_FLOAT:
				if effects.get(s):
					if desired_state[s] > effects.get(s) + blackboard.get(s):
						blackboard[s] += effects.get(s)
						#print("float elements was added to blackboard:\ndesired_state[s]: ", desired_state[s],"\neffects.get(s): ", effects.get(s))
						#print("blackboard.get(s): ", blackboard.get(s))
					else:
						blackboard[s] += effects.get(s)
						#print("float element was achieved:\ndesired_state[s]: ", desired_state[s],"\neffects.get(s): ", effects.get(s))
						#print("blackboard.get(s): ", blackboard.get(s))
						state.erase(s)
		
		#print("teste------------------------")
		if desired_state.is_empty() or _build_plan_greedy(state, blackboard.duplicate(), sequence):
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
	var custo = 0.0
	for a in plan:
		actions.push_back([a.get_clazz(), a.get_cost(blackboard)])
		custo += a.get_cost(blackboard)
	##print({"cost": custo, "actions": actions})
	WorldState.console_message({"cost": custo, "actions": actions})
