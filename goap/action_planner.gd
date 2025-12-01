extends Node

class_name GoapActionPlanner

var _actions: Array

func _init(list_pref) -> void:
	_actions = [
		PayAction.new(),
		GetOutAction.new(),
		WatchAction.new(),
		PeeAction.new()
	]
	
	for item in WorldState.get_elements("item"):
		if not item.client_holding and item.type in list_pref:
			_actions.push_back(GoToAction.new(item.position))
			_actions.push_back(PickItemAction.new(item))
	
	_actions.push_back(GoToAction.new(WorldState.get_elements("wc")[0].position))
	_actions.push_back(GoToAction.new(WorldState.get_elements("tv")[0].position))
	_actions.push_back(GoToAction.new(WorldState.get_elements("caixa")[0].position))
	_actions.push_back(GoToAction.new(WorldState.get_elements("out")[0].position))
	
	
	#print("acoes do agente: ")
	for i in _actions:
		print("   ", i.get_clazz())

# ==============================================================================
# Public Interface
# ==============================================================================

func get_plan(goal: GoapGoal, world_context: Dictionary) -> Array:
	if not goal or not goal.get_desired_state() or world_context.is_empty():
		push_error("Cannot plan: Goal or World Context is invalid.")
		return []
		
	print("\n", str(world_context["actor"]) + " --- Starting Plan for Goal: ", goal.get_clazz(), " ---")
	WorldState.console_message("Goal: %s" % goal.get_clazz())
	
	# The A* search is performed backward (regression) from the goal's pre-conditions.
	var plan = build_plan(goal, world_context)
	
	if plan.is_empty():
		print(str(world_context["actor"]) + " --- FAILED to find a plan for Goal: ", goal.get_clazz(), " ---")
	else:
		print(str(world_context["actor"]) + " --- Plan found successfully ---")
		_print_plan(plan, world_context)
	
	return plan


# ==============================================================================
# A* Regression Search (Core Algorithm)
# ==============================================================================

# Uses A* to search backward from the goal state's pre-conditions to the world_context.
# @param goal: The GoapGoal instance.
# @param world_context: The current world state.
# @return: Array of GoapAction objects (the plan).
func build_plan(goal: GoapGoal, world_context: Dictionary) -> Array:
	# 1. Initialization
	var goal_state: Dictionary = goal.get_desired_state()
	
	# Open list (Nodes to evaluate), sorted by f_cost (min-heap structure simulated with Array)
	var open_list: Array = []
	# All nodes created during the search (for path reconstruction)
	var all_nodes: Array = []
	# Closed states (used for node collapsing/pruning: state_hash -> index of best node)
	var closed_states: Dictionary = {}
	
	# Create the start node (which is the goal state in regression)
	var start_node = _create_node(goal_state, 0.0, _calculate_h(goal_state, world_context), null, -1)
	open_list.append(start_node)
	all_nodes.append(start_node)
	closed_states[_hash_state(goal_state)] = 0
	
	# 2. A* Search Loop
	var final_node_index: int = -1
	
	while not open_list.is_empty():
		# Get the node with the lowest F cost (A* requirement)
		# NOTE: In production, this should be a proper priority queue for performance.
		#print(open_list)
		var current_node = open_list.pop_front()
		var current_node_index = all_nodes.find(current_node)
		print(str(world_context["actor"]) + " current goal state: ", current_node.state)
		
		# Check if the current state is satisfied by the World Context (Goal Reached)
		if _is_state_met(current_node.state, world_context):
			final_node_index = current_node_index
			break
		
		# 3. Expansion: Find actions that achieve the current node's state (regression)
		for action in _actions:
			if not action.is_valid(world_context["actor"]):
				continue
			
			#print(str(world_context["actor"]) + " action: ", action.get_clazz())
			
			var achieved_conditions: Dictionary = {}
			var is_relevant = false

			 # fetch effects/preconditions with the selected context
			var effects = action.get_effects()            # <- changed
			var preconditions = action.get_preconditions()     # <- changed
			
			# Check for overlap: does the action's effects achieve *any* required condition?
			#Also check for a precondition with a value that differs from the one in the current node state
			for key in current_node.state.keys():
				var required_value = current_node.state[key]
				#print("required value: ", required_value)
				#print("action effect: ", effects.get(key))
				if effects.has(key) and effects[key] == required_value:
					achieved_conditions[key] = required_value
					is_relevant = true
				if preconditions.has(key) and preconditions[key] != required_value:
					is_relevant = false
					break
			
			# If the action achieves none of the required conditions, skip it.
			if not is_relevant:
				continue
			
			# If the action is relevant, calculate the new state (the required pre-conditions for the previous step).
			# next_state = (Action's Pre-conditions) + (Remaining unachieved conditions from parent state)
			var next_state: Dictionary = preconditions.duplicate()
			
			for key in current_node.state.keys():
				# Add back any required condition that this action did NOT achieve
				if not achieved_conditions.has(key):
					next_state[key] = current_node.state[key]
			
			# Calculate costs
			var g_new: float = current_node.g_cost + action.get_cost(world_context)
			var h_new: float = _calculate_h(next_state, world_context)
			var f_new: float = g_new + h_new
			
			var state_hash: String = _hash_state(next_state)
			
			# Node Collapsing/Pruning check
			if closed_states.has(state_hash):
				var existing_node_index = closed_states[state_hash]
				var existing_node = all_nodes[existing_node_index]
				
				# If we found a cheaper path to the same state, update the existing node
				if g_new < existing_node.g_cost:
					# Update node in place (optimization)
					existing_node.g_cost = g_new
					existing_node.f_cost = f_new
					existing_node.parent_index = current_node_index
					existing_node.action = action
				
				# Skip creating a new node as a better (or equal) path to this state was found.
				continue 
			
			# 4. Create new node and add to lists
			var new_node = _create_node(next_state, g_new, h_new, action, current_node_index)
			all_nodes.append(new_node)
			closed_states[state_hash] = all_nodes.size() - 1
			
			# Insert into open list and maintain sorted order by f_cost
			var inserted = false
			for i in range(open_list.size()):
				if f_new < open_list[i].f_cost:
					open_list.insert(i, new_node)
					inserted = true
					break
			if not inserted:
				open_list.append(new_node)
	
	# 5. Path Reconstruction
	if final_node_index != -1:
		var plan: Array = []
		var current_index = final_node_index
		
		# Trace back the parent links from the final node to the start node (goal state)
		# The final plan must be reversed because we searched backward.
		while current_index != -1:
			var node = all_nodes[current_index]
			if node.action:
				plan.append(node.action)
			current_index = node.parent_index
		
		return plan
	
	return []


# ==============================================================================
# Internal Helper Functions
# ==============================================================================

# Creates a new A* node dictionary.
func _create_node(state: Dictionary, g: float, h: float, action: GoapAction, parent_index: int) -> Dictionary:
	return {
		"state": state,
		"g_cost": g,
		"h_cost": h,
		"f_cost": g + h,
		"action": action,
		"parent_index": parent_index
	}

# Heuristic Function (H-Cost)
# Estimates how "close" a state (the action's preconditions) is to the World Context.
# We use the number of unsatisfied conditions in the proposed state that are NOT in the world context.
# This prevents switching to nodes that move away from the current world state.
# @param next_state: The required state (action preconditions).
# @param world_context: The current state of the world.
# @return: Integer representing the number of mismatches.
func _calculate_h(next_state: Dictionary, world_context: Dictionary) -> float:
	var mismatches: int = 0
	for key in next_state.keys():
		var required_value = next_state[key]
		# Check if the requirement is NOT met by the world context
		if not world_context.has(key) or world_context[key] != required_value:
			mismatches += 1
	return float(mismatches)

# Checks if a required state is met by the current world context.
# @param required_state: The dictionary of required world facts.
# @param current_state: The dictionary of actual world facts.
func _is_state_met(required_state: Dictionary, current_state: Dictionary) -> bool:
	for key in required_state.keys():
		var required_value = required_state[key]
		if not current_state.has(key) or current_state[key] != required_value:
			return false
	return true

# Converts a state dictionary to a deterministic string for fast lookup in closed_states.
# This is crucial for node collapsing.
func _hash_state(state: Dictionary) -> String:
	var keys = state.keys()
	keys.sort()
	var hash_parts: Array = []
	for key in keys:
		hash_parts.append(str(key) + ":" + str(state[key]))
	return ";".join(hash_parts)



#
#-------------------------------------------------------------------------------------------------------------------------------------
#


# func _build_plan_greedy(state, blackboard, sequence) -> bool:
# 	#print("\n-----------------COMEÇO DA FUNÇÃO-----------------")
# 	var has_followup = false
# 	# checks if the blackboard contains data that can
# 	# satisfy the current state.
# 	#print("\nblackboard: ", blackboard)
#	
# 	#print("\nstate atual antes do blackboard:\n", state)
# 	var duplicado_state = state.duplicate()
# 	for s in duplicado_state:
# 		if typeof(duplicado_state[s]) == TYPE_BOOL:
# 			if duplicado_state[s] == blackboard.get(s):
# 				state.erase(s)
# 		elif typeof(duplicado_state[s]) == TYPE_FLOAT:
# 			if duplicado_state[s] <= blackboard[s]:
# 				state.erase(s)
# 	#print("\nstate atual apos verificar com blackboard:\n", state)
#	
# 	if state.is_empty():
# 		return true
#	
# 	var best_choice = null
# 	var minimum_cost = 10000
# 	##print("\n_actions antes: ", _actions.size())
# 	var _ac = _actions.duplicate()
# 	for action in _ac:
# 		if not action:
# 			_actions.erase(action)
# 	_ac = []
# 	##print("\n_actions depois: ", _actions.size())
# 	for action in _actions:
# 		#if action.get_clazz() == "PickItemAction":
# 			#print("-------------------------------------------------")
# 			#print("action nome: ", action.get_clazz())
# 			#print("action: ", action)
# 			#print("item cost: ", action._item.cost)
# 			#print("preference: ", blackboard["actor"].preference[action._item.type])
# 			#print("distance: ", action.default_item_position.distance_to(blackboard["position"]))
# 			#print("action cost: ", action.get_cost(blackboard))
#		
# 		if not action.is_valid(blackboard):
# 			#print("action nao é valida")
# 			continue
# 		#print("action valida")
#		
# 		var effects = action.get_effects(blackboard.actor)
#		
# 		for s in state:
# 			#print("effects: ",s,": ", effects.get(s))
# 			if not effects.get(s): continue
# 			if typeof(state[s]) == TYPE_BOOL:
# 				if state[s] == effects.get(s):
# 					if action.get_cost(blackboard) < minimum_cost:
# 						best_choice = action
# 						minimum_cost = action.get_cost(blackboard)
# 			elif typeof(state[s]) == TYPE_FLOAT:
# 				if effects.get(s):
# 					if action.get_cost(blackboard) < minimum_cost:
# 						best_choice = action
# 						minimum_cost = action.get_cost(blackboard)
# 	#print("best choice: ", best_choice)
#	
# 	if best_choice:
#		
# 		if best_choice.get_clazz() == "PickItemAction":
# 			blackboard.set(str(best_choice._item)+"is_picked_up", true)
# 			print("-------------------------------------------------")
# 			#print("action nome: ", best_choice.get_clazz())
# 			#print("action: ", best_choice)
# 			print("item cost: ", best_choice._item.cost)
# 			print("money: ", blackboard["money"])
# 			print("bill: ", blackboard["bill"])
# 			#print("preference: ", blackboard["actor"].preference[best_choice._item.type])
# 			#print("distance: ", best_choice.default_item_position.distance_to(blackboard["position"]))
# 			#print("action cost: ", best_choice.get_cost(blackboard))
# 		#print("\nbest_choice cost: ", best_choice.get_cost(blackboard))
# 		#print("\nachou ação\n", best_choice.get_clazz())
#		
#		
# 		var preconditions = best_choice.get_preconditions(blackboard.actor)
# 		var effects = best_choice.get_effects(blackboard.actor)
#		
# 		for p in preconditions:
# 			state[p] = preconditions[p]
#		
# 		duplicado_state = state.duplicate()
# 		#print("\ndesired_state atual:\n", desired_state)
# 		#print("\ndesired_state: ", desired_state)
# 		for s in duplicado_state:
# 			#print("\ns: ", s)
# 			if typeof(duplicado_state[s]) == TYPE_BOOL:
# 				if duplicado_state[s] == effects.get(s):
# 					#print("bool element was achieved:\ndesired_state[s]: ", desired_state[s],"\neffects.get(s): ", effects.get(s))
# 					blackboard[s] = true
# 					state.erase(s)
# 			elif typeof(duplicado_state[s]) == TYPE_FLOAT:
# 				if effects.get(s):
# 					if duplicado_state[s] > effects.get(s) + blackboard.get(s):
# 						blackboard[s] += effects.get(s)
# 						#print("float elements was added to blackboard:\ndesired_state[s]: ", desired_state[s],"\neffects.get(s): ", effects.get(s))
# 						#print("blackboard.get(s): ", blackboard.get(s))
# 					else:
# 						blackboard[s] += effects.get(s)
# 						#print("float element was achieved:\ndesired_state[s]: ", desired_state[s],"\neffects.get(s): ", effects.get(s))
# 						#print("blackboard.get(s): ", blackboard.get(s))
# 						state.erase(s)
#		
# 		#print("teste------------------------")
# 		if state.is_empty() or _build_plan_greedy(state, blackboard, sequence):
# 			#step.children.push_back(s)
# 			sequence.push_back(best_choice)
# 			#print("\nsequence:\n", sequence)
# 			has_followup = true
#	
#	
# 	#print("has_followup: ", has_followup)
# 	##print("-----------------FIM DA FUNÇÃO-----------------")
# 	return true




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
	print(str(blackboard["actor"]) + " ", pri)
	WorldState.console_message({"cost": custo, "actions": actions})
