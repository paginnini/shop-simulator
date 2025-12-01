extends Node

class_name UDGoapActionPlanner

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

# ==============================================================================
# UD-GOAP Public Interface
# ==============================================================================

func get_plan(motivation: GoapMotivation, world_context: Dictionary) -> Array:
	if not motivation or world_context.is_empty():
		push_error("Cannot plan: Motivation or World Context is invalid.")
		return []
		
	print("\n", str(world_context["actor"]) + " --- Starting UD-GOAP Plan for Motivation: ", motivation.get_clazz(), " ---")
	WorldState.console_message("Motivation: %s" % motivation.get_clazz())
	
	# UD-GOAP: We plan for the specific motivation but consider utility across all motivations
	var plan = build_udgoap_plan(motivation, world_context)
	
	if plan.is_empty():
		print(str(world_context["actor"]) + " --- FAILED to find a plan for Motivation: ", motivation.get_clazz(), " ---")
	else:
		print(str(world_context["actor"]) + " --- UD-GOAP Plan found successfully ---")
		_print_udgoap_plan(plan, world_context)
	
	return plan

# ==============================================================================
# UD-GOAP A* Regression Search with Utility
# ==============================================================================

func build_udgoap_plan(motivation: GoapMotivation, world_context: Dictionary) -> Array:
	# UD-GOAP: We use the motivation's desired improvement as our starting point
	# For continuous motivations, we want to improve the utility value
	
	# 1. Initialization - UD-GOAP uses utility-maximizing search
	var open_list: Array = []
	var all_nodes: Array = []
	var closed_states: Dictionary = {}
	
	# Create start node representing the motivation we want to improve
	var start_node = _create_udgoap_node(
		{"target_motivation": motivation.get_clazz()}, 
		0.0,  # g_cost starts at 0 (utility gained)
		_calculate_udgoap_h(motivation, world_context), 
		null, 
		-1
	)
	open_list.append(start_node)
	all_nodes.append(start_node)
	closed_states[_hash_state({"target_motivation": motivation.get_clazz()})] = 0
	
	# UD-GOAP: Track the best plan found so far
	var best_final_node_index: int = -1
	var best_utility_gain: float = -INF
	
	# 2. A* Search Loop - but we maximize utility instead of minimizing cost
	while not open_list.is_empty():
		# UD-GOAP: Get node with highest potential utility (F score)
		# We sort by f_cost descending since we want to maximize utility
		open_list.sort_custom(func(a, b): return a.f_cost > b.f_cost)
		var current_node = open_list.pop_front()
		var current_node_index = all_nodes.find(current_node)
		
		# UD-GOAP: Check if current plan achieves sufficient utility improvement
		# For continuous motivations, we want to see if this plan significantly improves our state
		var current_utility_gain = _evaluate_plan_utility(current_node, world_context, all_nodes)
		
		if current_utility_gain > best_utility_gain:
			best_utility_gain = current_utility_gain
			best_final_node_index = current_node_index
		
		# UD-GOAP: Check if we've reached a satisfactory utility threshold
		if current_utility_gain >= 0.1:  # Threshold for "good enough" utility improvement
			best_final_node_index = current_node_index
			break
		
		# 3. Expansion: Find actions that could lead to utility improvement
		for action in _actions:
			if not action.is_valid(world_context["actor"]):
				continue
			
			# UD-GOAP: Check if this action improves our target motivation OR any motivation
			var effects = action.get_effects()
			var is_relevant = false
			
			# Check if action affects variables relevant to our target motivation
			# or if it significantly improves overall utility
			var predicted_utility = _predict_action_utility(action, world_context)
			if predicted_utility > 0.01:  # Action provides some utility improvement
				is_relevant = true
			
			if not is_relevant:
				continue
			
			# UD-GOAP: Calculate new state and utility gain
			var preconditions = action.get_preconditions()
			var next_state: Dictionary = preconditions.duplicate()
			
			# Add any existing state requirements
			if current_node.state.has("target_motivation"):
				next_state["target_motivation"] = current_node.state["target_motivation"]
			
			# UD-GOAP: Calculate utility-based "cost" (we want to maximize utility gain)
			var utility_gain = _calculate_action_utility_gain(action, world_context)
			var g_new: float = current_node.g_cost + utility_gain
			var h_new: float = _calculate_udgoap_h(motivation, world_context)
			var f_new: float = g_new + h_new  # Total expected utility
			
			var state_hash: String = _hash_state(next_state)
			
			# Node Collapsing/Pruning - keep the highest utility path
			if closed_states.has(state_hash):
				var existing_node_index = closed_states[state_hash]
				var existing_node = all_nodes[existing_node_index]
				
				# If we found a higher utility path to the same state, update
				if g_new > existing_node.g_cost:  # Higher utility is better
					existing_node.g_cost = g_new
					existing_node.f_cost = f_new
					existing_node.parent_index = current_node_index
					existing_node.action = action
				continue
			
			# 4. Create new node
			var new_node = _create_udgoap_node(next_state, g_new, h_new, action, current_node_index)
			all_nodes.append(new_node)
			closed_states[state_hash] = all_nodes.size() - 1
			
			# Insert into open list (maintain sorted by utility)
			var inserted = false
			for i in range(open_list.size()):
				if f_new > open_list[i].f_cost:  # Higher utility first
					open_list.insert(i, new_node)
					inserted = true
					break
			if not inserted:
				open_list.append(new_node)
	
	# 5. Path Reconstruction
	if best_final_node_index != -1 and best_utility_gain > 0:
		var plan: Array = []
		var current_index = best_final_node_index
		
		while current_index != -1:
			var node = all_nodes[current_index]
			if node.action:
				plan.append(node.action)
			current_index = node.parent_index
		
		return plan
	
	return []

# ==============================================================================
# UD-GOAP Utility Calculation Functions
# ==============================================================================

# Predicts how much utility an action would add if executed
func _predict_action_utility(action: GoapAction, world_context: Dictionary) -> float:
	# Simulate the action's effects on the world state
	var simulated_state = world_context.duplicate()
	var effects = action.get_effects()
	
	# Apply effects to simulated state
	for key in effects.keys():
		if simulated_state.has(key):
			if typeof(effects[key]) == TYPE_BOOL:
				simulated_state[key] = effects[key]
			else:  # Assume numeric effect
				simulated_state[key] += effects[key]
	
	# Calculate utility of new state across all motivations
	var new_utility = _calculate_overall_utility(simulated_state, world_context["motivations"])
	var current_utility = _calculate_overall_utility(world_context, world_context["motivations"])
	
	return new_utility - current_utility

# Calculates the actual utility gain of an action in the current context
func _calculate_action_utility_gain(action: GoapAction, world_context: Dictionary) -> float:
	return _predict_action_utility(action, world_context)

# Evaluates the total utility of a complete plan
func _evaluate_plan_utility(node, world_context: Dictionary, all_nodes) -> float:
	# Reconstruct the plan and simulate its execution
	var plan: Array = []
	var current_index = all_nodes.find(node)
	
	while current_index != -1:
		var current_node = all_nodes[current_index]
		if current_node.action:
			plan.append(current_node.action)
		current_index = current_node.parent_index
	
	# Simulate plan execution
	var simulated_state = world_context.duplicate()
	for action in plan:
		var effects = action.get_effects()
		for key in effects.keys():
			if simulated_state.has(key):
				if typeof(effects[key]) == TYPE_BOOL:
					simulated_state[key] = effects[key]
				else:
					simulated_state[key] += effects[key]
	
	# Calculate final utility
	return _calculate_overall_utility(simulated_state, world_context["motivations"])

# Calculates overall utility across all motivations
func _calculate_overall_utility(state: Dictionary, motivations: Array) -> float:
	var total_utility = 0.0
	for motivation in motivations:
		total_utility += motivation.get_utility(state)
	return total_utility

# UD-GOAP Heuristic: Estimates maximum possible utility improvement
func _calculate_udgoap_h(motivation: GoapMotivation, world_context: Dictionary) -> float:
	# Estimate how much we can improve the target motivation
	# This is optimistic - assumes we can achieve maximum satisfaction
	var current_utility = motivation.get_utility(world_context)
	return 1.0 - current_utility  # Maximum possible improvement

# ==============================================================================
# Internal Helper Functions (Modified for UD-GOAP)
# ==============================================================================

func _create_udgoap_node(state: Dictionary, g: float, h: float, action: GoapAction, parent_index: int) -> Dictionary:
	return {
		"state": state,
		"g_cost": g,      # Accumulated utility gain
		"h_cost": h,      # Estimated remaining utility potential
		"f_cost": g + h,  # Total expected utility
		"action": action,
		"parent_index": parent_index
	}

func _is_state_met(required_state: Dictionary, current_state: Dictionary) -> bool:
	for key in required_state.keys():
		var required_value = required_state[key]
		if not current_state.has(key):
			return false
		
		# Handle different types appropriately
		if typeof(required_value) == TYPE_BOOL:
			if current_state[key] != required_value:
				return false
		else:  # Assume numeric - check if current meets or exceeds requirement
			if current_state[key] < required_value:
				return false
	return true

func _hash_state(state: Dictionary) -> String:
	var keys = state.keys()
	keys.sort()
	var hash_parts: Array = []
	for key in keys:
		hash_parts.append(str(key) + ":" + str(state[key]))
	return ";".join(hash_parts)

# ==============================================================================
# Debugging
# ==============================================================================

func _print_udgoap_plan(plan, blackboard):
	var actions = []
	var pri = []
	var total_utility_gain = 0.0
	
	# Calculate utility gain for the plan
	var initial_utility = _calculate_overall_utility(blackboard, blackboard["motivations"])
	var simulated_state = blackboard.duplicate()
	
	for a in plan:
		actions.push_back([a.get_clazz(), _predict_action_utility(a, simulated_state)])
		pri.push_back(a.get_clazz())
		
		# Update simulated state
		var effects = a.get_effects()
		for key in effects.keys():
			if simulated_state.has(key):
				if typeof(effects[key]) == TYPE_BOOL:
					simulated_state[key] = effects[key]
				else:
					simulated_state[key] += effects[key]
	
	var final_utility = _calculate_overall_utility(simulated_state, blackboard["motivations"])
	total_utility_gain = final_utility - initial_utility
	
	print(str(blackboard["actor"]) + " ", pri)
	print(str(blackboard["actor"]) + " Total Utility Gain: ", total_utility_gain)
	WorldState.console_message({"utility_gain": total_utility_gain, "actions": actions})
