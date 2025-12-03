extends CharacterBody3D

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

const SPEED = 10.0
const JUMP_VELOCITY = 4.5

var going_already = false
var cant_find_plan_shopping = false

# --- Continuous State Variables (True State/Display) ---
# These are the agent's actual numerical values, not used directly by the classic planner.

var do_distance : float = 6.0

var itens_list = []
var preference
var list_pref

var _udgoap_state

#var _goals: Array = []
var _motivations: Array = []
var _current_motivation: GoapMotivation = null
var _current_plan: Array = []
var _current_plan_step: int = 0

var _action_planner

var can_perform = true

##################test variables##################
var dinheiro_inicial
#dinheiro final == current_money
var vezes_planejou = 0
#satisfacao_final == current satisfaction
var tempo_inicial
var tempo_final
##################test variables##################

func _ready():
	tempo_inicial = Time.get_unix_time_from_system()
	preference = {
		"refrigerante": 0.5,
		"suco": 0.5,
		"agua": 0.5,
		"doce": 0.5,
		"carne": 0.5,
		"massa": 0.5
	}
	_udgoap_state = {
		"current_satisfaction": 0.0,
		"satisfaction_limit": 100.0,
		"is_satisfied": false, #if satisfaction >= satisfaction_limit
		"done_shopping": false, #if the npc cant pick up more itens because any item cost + bill > money
		"current_money": 200.0,
		"initial_money": 200.0,
		"current_bill": 0.0,
		"payed": true, #if performed sucessfully the pay action
		"current_bladder": 0.0,
		"bladder_limit": 100.0,
		"needs_wc": false, #if current_bladder is more than 1/3
		"used_wc": false, #if performed sucessfully the pee action
		"current_entertainment": 8.0,
		"entertainment_limit": 8.0,
		"watching": false, #if is performing the action watch
		"out": false, #if performed sucessfully the get_out action
		"position": global_position,
	}
	#define variaveis aleatorias para esse npc
	if WorldState.random:
		_udgoap_state["initial_money"] = snappedf(randf_range(40.0, 150.0), 0.01)
		_udgoap_state["current_money"] = _udgoap_state["initial_money"]
		_udgoap_state["current_bladder"] = snappedf(randf_range(0.0, 70.0), 0.01)
		for key in preference.keys():
			preference[key] = randi_range(2, 8) / 10.0      # convert to 0.0–1.0 in 0.1 steps
	else:
		_udgoap_state["initial_money"] = snappedf(WorldState.money_rng.randf_range(10.0, 140.0), 0.01)
		_udgoap_state["current_money"] = _udgoap_state["initial_money"]
		dinheiro_inicial = _udgoap_state["initial_money"]
		_udgoap_state["current_bladder"] = snappedf(WorldState.bladder_rng.randf_range(0.0, 70.0), 0.01)
		for key in preference.keys():
			preference[key] = WorldState.preference_rng.randi_range(2, 8) / 10.0      # convert to 0.0–1.0 in 0.1 steps
		list_pref = WorldState.item_types.duplicate()
		for i in range(list_pref.size() - 1, 0, -1):
			var j = WorldState.type_quant_rng.randi_range(0, i)
			var tmp = list_pref[i]
			list_pref[i] = list_pref[j]
			list_pref[j] = tmp
		var quant = WorldState.type_quant_rng.randi_range(3, 5)
		for i in range(quant):
			if list_pref.size() > 0:
				list_pref.pop_back()
	#print_npc_variables()
	
	$SubViewportContainer/SubViewport/ProgressBar.max_value = _udgoap_state["satisfaction_limit"]
	$SubViewportContainer/SubViewport/ProgressBar2.max_value = _udgoap_state["bladder_limit"]
	
	#RETIRAR NO UDGOAP, GOALS SAO GERADOS ON RUNTIME
	#_goals = [
		#UDPickItensGoal.new(),
		#UDLeaveGoal.new(),
		#UDWatchTVGoal.new(),
		#UDUseWCGoal.new()
	#]
	_motivations = [
		BeEntertainedMotivation.new(),
		BeRelievedMotivation.new(),
		BeSatisfiedMotivation.new(),
		SaveMoneyMotivation.new(),
		GoHomeMotivation.new()
	]
	
	_action_planner =  UDGoapActionPlanner.new(list_pref)


var ai_timer := 0.0
var exec_interval := 0.2  # update 5 times per second
func _physics_process(delta: float) -> void:
	ai_timer += delta
	if ai_timer >= exec_interval:
		ai_timer -= exec_interval
		update_goap_state()
		
		# Update HUD ----------------------------------------------------------
		var text := "Goal: %s\n" % _current_motivation.get_clazz() if _current_motivation else "None\n"
		text += "Money: %f\n" % _udgoap_state["current_money"]
		text += "Bill: %f\n" % _udgoap_state["current_bill"]
		text += "Bladder: %f\n" % _udgoap_state["current_bladder"]
		text += "Satisfaction: %f\n" % _udgoap_state["current_satisfaction"]
		for key in _udgoap_state.keys():
			text += "%s: %s\n" % [key, str(_udgoap_state[key])]
		text += "%s\n" % str(list_pref)
		text += str(self)
		$labels/label_money.text = text
		$SubViewportContainer/SubViewport/ProgressBar.value = _udgoap_state["current_satisfaction"]
		$SubViewportContainer/SubViewport/ProgressBar2.value = _udgoap_state["current_bladder"]
		# Update HUD ----------------------------------------------------------
		
		if _udgoap_state["out"] == true:
			return
		# On every loop this script checks if the current goal is still
		# the highest priority. if it's not, it requests the action planner a new plan
		# for the new high priority goal.
		var mot = _get_best_motivation()
		if _current_motivation == null or mot != _current_motivation:
			#print("\n", str(self) + "MOTIVATION ATUAL ", mot.get_clazz(), "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||")
			#print(str(self) + "_udgoap_state: ", _udgoap_state)
			_get_best_motivation(true)
			_current_motivation = mot
			var blackboard = {
				"position": global_position,
				"actor": self,
				}
			blackboard.merge(_udgoap_state, true)
			blackboard.merge(WorldState._state, true)
			_udgoap_state.set("watching", false)
			#print(str(self) + "_udgoap_state: ", _udgoap_state)
			#print(str(self) + "chama get plan")
			vezes_planejou += 1
			_current_plan = _action_planner.get_plan(_current_motivation, blackboard)
			#print(str(self) + "retorna get plan")
			
			# --- START OF FIX ---
			if _current_plan.is_empty():
				#print(str(self) + "Planning FAILED for: ", _current_motivation.get_clazz())
				# If we tried to satisfy ourselves but couldn't (likely due to money constraints),
				# we force the 'done_shopping' state to True.
				if _current_motivation.get_clazz() == "BeSatisfied": 
					cant_find_plan_shopping = true
					_current_motivation.can_be_primary = false
					#print(str(self) + "Fallback: Force cant_find_plan_shopping = true")
				# Reset motivation to null so the agent re-evaluates priorities in the next frame
				# with the new state (done_shopping=true)
				_current_motivation = null 
				return # Skip the rest of this frame
			# --- END OF FIX ---
			
			_current_plan_step = 0
			can_perform = true
			going_already = false
		else:
			_follow_plan(_current_plan, delta)
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	var destination = navigation_agent_3d.get_next_path_position()
	var local_destination = destination - global_position
	var direction = local_destination.normalized()
	
	velocity = direction * SPEED
	move_and_slide()

# Translates continuous/numerical variables into the boolean/symbolic GOAP state.
func update_goap_state() -> void:
	# Boolean assignments for GOAP planning
	_udgoap_state["needs_wc"] = _udgoap_state["current_bladder"] >= _udgoap_state["bladder_limit"] * 2/3
	_udgoap_state["is_satisfied"] = _udgoap_state["current_satisfaction"] >= _udgoap_state["satisfaction_limit"]
	_udgoap_state["payed"] = (_udgoap_state["current_bill"] == 0.0)
	_udgoap_state["current_entertainment"] = WorldState.get_elements("tv")[0].value
	_udgoap_state["position"] = global_position
	
	var min_price := 10000000.0
	var found := false
	for item in WorldState.get_elements("item"):
		if not item.client_holding and (item.type in list_pref):
			if not found or item.cost < min_price:
				min_price = item.cost
				found = true
	#print(str(self) + "min_price: ",min_price)
	#print(str(self) + "found: ", found)
	# If no items found → min_price stays 0.0
	_udgoap_state["done_shopping"] = ((_udgoap_state["current_money"] - _udgoap_state["current_bill"]) < min_price) or _udgoap_state["is_satisfied"] or not found or cant_find_plan_shopping
	# Note: Other booleans (done_shopping, payed, used_wc) must be set by actions/goals.

func _get_best_motivation(debug = null):
	var lowest_utility = null
	
	for mot in _motivations:
		if not mot.can_be_primary:
			continue
		#if debug: print(str(self) + "motivation: ", mot.get_clazz(), " | utility: ", mot.get_utility(_udgoap_state))
		if lowest_utility == null or mot.get_utility(_udgoap_state) < lowest_utility.get_utility(_udgoap_state):
			lowest_utility = mot
	
	return lowest_utility

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
	
	if not plan[_current_plan_step].is_valid(_udgoap_state, self):
		#print(str(self) + " planned action not valid anymore")
		_current_motivation = null
		return
	
	if can_perform:
		var is_step_complete = plan[_current_plan_step].perform(self, delta, WorldState._state)
		
		if is_step_complete:
			_current_plan_step += 1
			if _current_plan_step >= plan.size():
				#print(str(self) + " fim do plano")
				_current_motivation = null
				_current_plan = []
				_current_plan_step = 0
			#else: print(str(self) + " proxima action")
	#print(WorldState._state)
	#print(is_step_complete)
	#print(_current_plan_step)
	#print(plan.size())


func vanish() -> void:
	var results = "%s|%f|%f|%d|%f|%s|%s" % [str(self), dinheiro_inicial, _udgoap_state["current_money"], vezes_planejou, _udgoap_state["current_satisfaction"], str(tempo_inicial), str(Time.get_unix_time_from_system()) ]
	WorldState.write_to_file(results)
	for i in itens_list:
		if i: i.queue_free()
	itens_list = []
	self.queue_free()
	WorldState.close_game(self)


func print_npc_variables():
	print(str(self) + "------------------------------------------------------NEW GOAP NPC------------------------------------------------------")
	print(str(self) + " money: ", _udgoap_state["current_money"])
	print(str(self) + " bladder: ", _udgoap_state["current_bladder"])
	print(str(self) + " will only pick: ", list_pref)
	for key in preference.keys():
		print(str(self)," ", key,": ", preference[key])
	print(str(self) + " _udgoap_state: ", _udgoap_state)
	print(str(self) + "------------------------------------------------------NEW GOAP NPC------------------------------------------------------")
