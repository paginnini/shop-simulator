extends Node

class_name UDGoapActionPlanner

var _actions: Array

var debug = false

func _init(list_pref) -> void:
	_actions = [
		UDPayAction.new(),
		UDGetOutAction.new(),
		UDWatchAction.new(),
		UDPeeAction.new()
	]
	
	# Instantiate actions for Smart Objects (Items)
	# In a dynamic world, this list might be rebuilt or actions might be discovered at runtime.
	for item in WorldState.get_elements("item"):
		if not item.client_holding and item.type in list_pref:
			_actions.push_back(UDGoToAction.new(item))
			_actions.push_back(UDPickItemAction.new(item))
	
	_actions.push_back(UDGoToAction.new(WorldState.get_elements("wc")[0]))
	_actions.push_back(UDGoToAction.new(WorldState.get_elements("tv")[0]))
	_actions.push_back(UDGoToAction.new(WorldState.get_elements("caixa")[0]))
	_actions.push_back(UDGoToAction.new(WorldState.get_elements("out")[0]))

# ==============================================================================
# Public Interface
# ==============================================================================

func get_plan(motivation: GoapMotivation, world_context: Dictionary) -> Array:
	var actor = world_context["actor"]
	
	# 1. Generate the Goal / Planning Objective
	# In UD-GOAP, this returns the Filter Key and the Motivation context
	var goal_definition = motivation.generate_goal(actor)

	if goal_definition.is_empty() or world_context.is_empty():
		push_error("Cannot plan: Goal or World Context is invalid.")
		return []
	
	#print("\n", str(actor) + " --- Starting UD-GOAP Plan for: ", motivation.get_clazz(), " ---")
	#print("\n", str(actor) + " world_context: ", world_context)
	# 2. Build Plan using Utility Regression
	#print("\n", str(actor) + "goal_definition: ", goal_definition)
	var plan = build_plan(goal_definition, world_context, motivation)
	
	#if plan.is_empty():
		#print(str(actor) + " --- FAILED to find a plan ---")
	#else:
		#print(str(actor) + " --- Plan found successfully ---")
		#_print_plan(plan, world_context)
	
	return plan


# ==============================================================================
# UD-GOAP Regression Search
# ==============================================================================

func build_plan(goal_definition: Dictionary, world_context: Dictionary, primary_motivation: GoapMotivation) -> Array:
	var actor = world_context["actor"]
	
	var goal_filter = goal_definition["filter_key"]
	#print("\n", str(actor) + "goal_filter: ", goal_filter)
	
	# We start the search from a "Dummy" node representing the fulfilled goal.
	var initial_required_state = {} 
	
	# Calculate initial utility (Base Utility)
	var current_total_utility = _calculate_total_utility(actor._udgoap_state, actor)
	if debug: print("\n", str(actor) + "current_total_utility: ", current_total_utility)
	
	# Open list: Nodes to evaluate, sorted by f_cost (which is -Utility)
	var open_list: Array = []
	var all_nodes: Array = []
	var closed_states: Dictionary = {} # hash -> index
	
	# Create Start Node: 'state' is the actor's current world state at the start.
	var start_node = _create_node(initial_required_state, 0.0, current_total_utility, 0.0, null, -1, world_context.duplicate())
	open_list.append(start_node)
	all_nodes.append(start_node)
	closed_states[_hash_state(initial_required_state, world_context)] = 0
	
	#print("\n", str(actor) + " start_node: ", start_node)
	
	var final_node_index: int = -1
	
	# --- ADD THIS: Safety Counter ---
	var iterations: int = 0
	var max_iterations: int = 100 # Stop after 1000 nodes to prevent freezing
	
	# 3. A* Search Loop
	while not open_list.is_empty():
		iterations += 1
		if iterations > max_iterations:
			push_warning(str(actor) + " UD-GOAP: Planning iteration limit reached for %s. Aborting." % primary_motivation.get_clazz())
			break
		
		if debug: print(str(actor) + "-----------------------------------------------------------")
		var current_node = open_list.pop_front()
		var current_node_index = all_nodes.find(current_node)
		if current_node.action:
			if debug: print(str(actor) +" current_node.action: ", current_node.action.get_clazz(), " | ", current_node_index)
			if debug: print(str(actor) + " current_node.state_utility: ", current_node.state_utility)
		
		# 3b. Check if Plan is Complete (Goal Satisfied)
		# Checks if the required state of the current node is met by the ACTUAL world state.
		if debug: print(str(actor) + " _is_state_met: ", _is_state_met(current_node.required_state, actor._udgoap_state))
		if current_node.action != null and _is_state_met(current_node.required_state, actor._udgoap_state):
			# Additionally, for UD-GOAP, ensure we improved utility or have valid stop condition
			if debug: print(str(actor) + " current_node.state_utility: ", current_node.state_utility)
			if debug: print(str(actor) + " current_total_utility: ", current_total_utility)
			final_node_index = current_node_index
			#print(str(actor) + " ACHOU")
			break
			#if current_node.state_utility > current_total_utility:
				#final_node_index = current_node_index
				#print(str(actor) + " ACHOU")
				#break
		
		#print(str(actor) + " procura action")
		# 3c. Expansion: Find actions
		for action in _actions:
			if not action.is_valid(current_node.state, current_node.state["actor"]):
				continue
			#print("action: ", action.get_clazz())
			# --- 1. Filter Key Check (UD-GOAP Specific) ---
			# Only check filter on the first step of regression (last action of plan)
			if current_node.action == null: 
				var effects = action.get_effects(current_node.state)
				if not effects.has(goal_filter.variable):
					continue
			#print(str(actor) + " action: ", action.get_clazz()," effects: ", action.get_effects(current_node.state))
			#print(str(actor) + " goal_filter.variable: ", goal_filter.variable)
			# --- 2. Standard Validity Check ---
			# We must check validity against the SIMULATED state of the current node (the state *before* this action)
			if not action.is_valid(current_node.state, actor):
				continue
			#print("action valida")
			var effects = action.get_effects(current_node.state)
			var preconditions = action.get_preconditions()
			
			var achieved_conditions: Dictionary = {}
			var is_relevant = false
			
			# --- 3. Relevance & Conflict Check ---
			if current_node.required_state.is_empty():
				is_relevant = true # Passed Filter Key check previously
			else:
				for key in current_node.required_state.keys():
					var required_val = current_node.required_state[key]
					
					# Relevance
					if effects.has(key):
						if effects[key] == required_val:
							achieved_conditions[key] = true
							is_relevant = true
					
					# Conflict
					if preconditions.has(key) and preconditions[key] != required_val:
						is_relevant = false
						break
						# Simple conflict check. 
						#if typeof(required_val) == TYPE_BOOL or typeof(required_val) == TYPE_STRING:
			if effects.has("position") and not current_node.required_state.has("position"):
				is_relevant = false
			
			if not is_relevant:
				continue
			if debug: print(str(actor) + " action: ", action.get_clazz(), " é relevante")
			if debug: print(str(actor) +" action: ", action.get_clazz(), " preconditions: ", preconditions)
			if debug: print(str(actor) + " required state: ", current_node.required_state)

			# --- 4. Calculate New State (Requirements for Previous Step) ---
			var next_required_state: Dictionary = preconditions.duplicate()
			for key in current_node.required_state.keys():
				if not achieved_conditions.has(key):
					next_required_state[key] = current_node.required_state[key]
			#print("action: ", action.get_clazz(), " next required_state: ", next_required_state)
			# --- 5. Calculate Action Rating (Delta Utility) ---
			var rating = _calculate_action_rating(action, current_node.state, actor)
			
			var new_total_utility = current_node.state_utility + rating 
			
			#print("eee ", current_node.state)
			var new_accumulated_cost = current_node.g_cost + action.get_cost(current_node.state)
			
			# --- 7. Create New Node ---
			# We need to simulate the new world state to pass down for the next step's simulation/validity check.
			var new_simulated_state = current_node.state.duplicate()
			for key in effects.keys():
				# Apply effects to the simulated state
				if (typeof(effects[key]) == TYPE_FLOAT or typeof(effects[key]) == TYPE_INT) and new_simulated_state.has(key):
					new_simulated_state[key] += effects[key]
				else:
					new_simulated_state[key] = effects[key]
			
			# --- 6. Node Pruning ---
			var state_hash = _hash_state(next_required_state, new_simulated_state)
			if closed_states.has(state_hash):
				#print("state hash: ", state_hash)
				var existing_idx = closed_states[state_hash]
				var existing_node = all_nodes[existing_idx]
				
				# Prefer Higher Utility, then Lower Cost
				if new_total_utility > existing_node.state_utility:
					existing_node.state_utility = new_total_utility
					existing_node.f_cost = -new_total_utility
					existing_node.parent_index = current_node_index
					existing_node.action = action
					continue
				elif is_equal_approx(new_total_utility, existing_node.state_utility) and new_accumulated_cost < existing_node.g_cost:
					existing_node.g_cost = new_accumulated_cost
					existing_node.parent_index = current_node_index
					existing_node.action = action
					continue
				else:
					continue 
			#print("action: ", action.get_clazz(), "passou do pruning")
			
			var new_node = _create_node(
				next_required_state, 
				new_accumulated_cost, 
				new_total_utility, 
				rating, 
				action, 
				current_node_index,
				new_simulated_state # Pass the simulated state AFTER the action is performed
			)
			all_nodes.append(new_node)
			closed_states[state_hash] = all_nodes.size() - 1
			
			# Insert into open list and maintain sorted order by f_cost
			var inserted = false
			for i in range(open_list.size()):
				if -new_total_utility < open_list[i].f_cost:
					open_list.insert(i, new_node)
					inserted = true
					break
			if not inserted:
				open_list.append(new_node)
	
	#print("\nnall nodes: ")
	#for node in all_nodes:
		#if node.action:
			#print(node.action.get_clazz())
		#else: print("none")
	
	#print("\nclosed nodes: ")
	#for key in closed_states.keys():
		#print(key)
	
	#print("final_node_index: ", final_node_index)
	# 4. Path Reconstruction
	if final_node_index != -1:
		#print("tem algo aqui")
		var reconstructed_plan: Array = []
		var curr_idx = final_node_index
		
		while curr_idx != -1:
			var node = all_nodes[curr_idx]
			if node.action:
				reconstructed_plan.append(node.action)
			curr_idx = node.parent_index
		
		return reconstructed_plan
	#print(str(actor) + " iterations: ", iterations)
	return []

# ==============================================================================
# Utility Calculations
# ==============================================================================

# Calculates the Agent's total utility for a given set of state variables.
func _calculate_total_utility(state_vars: Dictionary, actor) -> float:
	var total: float = 0.0
	# We access the motivations directly from the actor
	
	if actor.get("_motivations"):
		for mot in actor._motivations:
			# Each motivation calculates its own satisfaction based on the state dictionary
			# Then we multiply by its weight
			#print("\n", str(actor) + " motivation: ", mot.get_clazz(), " utility: ", mot.get_utility(state_vars))
			total += mot.get_w_utility(state_vars) # * mot.WEIGHT is handled inside           ty in your example
	return total

# Calculates the delta utility (Rating) for a specific action
func _calculate_action_rating(action: UDGoapAction, current_state: Dictionary, actor) -> float:
	# 1. Simulate the state AFTER the action
	var simulated_state = current_state.duplicate()
	var effects = action.get_effects(simulated_state)
	
	for key in effects:
		# If the value is numeric, we assume it's additive
		if (typeof(effects[key]) == TYPE_FLOAT or typeof(effects[key]) == TYPE_INT) and simulated_state.has(key):
			simulated_state[key] += effects[key]
		elif typeof(effects[key]) == TYPE_VECTOR3:
			simulated_state[key] = effects[key]
		else:
			# Boolean or Set value
			simulated_state[key] = effects[key]
	
	# 2. Calculate Utilities
	var util_before = _calculate_total_utility(current_state, actor)
	var util_after = _calculate_total_utility(simulated_state, actor)
	
	# 3. Rating = Improvement
	return util_after - util_before

# ==============================================================================
# Helper Functions
# ==============================================================================

func _create_node(req_state: Dictionary, accumulated_cost, state_utility: float, action_rating: float, action: UDGoapAction, parent_index: int, state: Dictionary) -> Dictionary:
	# UD-GOAP Metric: We want to MAXIMIZE utility.
	# A* Min-Heap sorts by lowest number. So we use NEGATIVE utility.
	var a_star_metric: float = -state_utility
	
	return {
		"required_state": req_state,
		"state_utility": state_utility,
		"action_rating": action_rating,
		"g_cost": accumulated_cost,
		"f_cost": a_star_metric,
		"action": action,
		"parent_index": parent_index,
		"state": state
	}

func _is_state_met(required_state: Dictionary, current_state: Dictionary) -> bool:
	#print("fff required_state: ", required_state) #comes from node
	#print("fff current_state: ", current_state) #actor.+udgoap_state real
	for key in required_state.keys():
		var required_val = required_state[key]
		
		# If the requirement is not in world state, we can't satisfy it
		if not current_state.has(key):
			return false
		var actual_val = current_state[key]
		#print("tem chave: ", actual)
		
		# For Booleans/Strings, check exact match
		if typeof(required_val) == TYPE_BOOL or typeof(required_val) == TYPE_STRING:
			if actual_val != required_val:
				return false
		# For numbers, usually regression implies "We have enough". 
		# But standard GOAP checks equality.
		# If required is just "exists", we might skip value check?
		# Sticking to equality for safety, or custom logic for floats if needed.
		elif actual_val != required_val:
			return false
			
	return true


func _hash_state(required_state: Dictionary, simulated_state: Dictionary) -> String:
	return _hash_dict(required_state) + "|" + _hash_dict(simulated_state)

func _hash_dict(state: Dictionary) -> String:
	if state.is_empty():
		return "{}"
	
	var keys = state.keys()
	keys.sort()
	var hash_parts: Array = []
	for key in keys:
		hash_parts.append(str(key) + ":" + str(state[key]))
	return "{" + ";".join(hash_parts) + "}"



# Prints plan. Used for Debugging only.
func _print_plan(plan, world_context):
	var action_names = []
	for a in plan:
		action_names.push_back(a.get_clazz())
		#cost += a.get_cost(world_context)
	print(str(world_context["actor"]) + " Final Plan: ", action_names)
