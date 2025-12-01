extends CharacterBody3D

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var going_already = false

var do_distance : float = 6.0

var itens_list = []
var preference = {
	"refrigerante": 0.5,
	"suco": 0.5,
	"agua": 0.5,
	"doce": 0.5,
	"carne": 0.5,
	"massa": 0.5
}
var list_pref

# UD-GOAP: Instead of a boolean state dictionary, we rely on the continuous variables above.
# However, we keep a state dictionary for compatibility if actions read specific flags,
# but the Planner will primarily look at Motivations.

var _udgoap_state = {
	"current_satisfaction": 0.0,
	"satisfaction_limit": 100.0,
	"current_money": 0.0,
	"initial_money": 0.0,
	"current_bill": 0.0,
	"is_satisfied": false, #if satisfaction >= satisfaction_limit
	"done_shopping": false, #if the npc cant pick up more itens because any item cost + bill > money
	"payed": true, #if performed sucessfully the pay action
	"current_bladder": 0.0,
	"bladder_limit": 100.0,
	"needs_wc": false, #if current_bladder is more than 1/3
	"used_wc": false, #if performed sucessfully the pee action
	"current_entertainment": 0.0,
	"entertainment_limit": 100.0,
	"watching": false, #if is performing the action watch
	"out": false, #if performed sucessfully the get_out action
}


var _motivations: Array = []
var _current_motivation = null

var _current_plan: Array = []
var _current_plan_step: int = 0

var _action_planner

var can_perform = true

func _ready():
	#define variaveis aleatorias para esse npc
	if WorldState.random:
		_udgoap_state["current_money"] = snappedf(randf_range(40.0, 150.0), 0.01)
		_udgoap_state["initial_money"] = _udgoap_state["current_money"]
		_udgoap_state["current_bladder"] = snappedf(randf_range(0.0, 70.0), 0.01)
		for key in preference.keys():
			preference[key] = randi_range(2, 8) / 10.0
	else:
		_udgoap_state["current_money"] = snappedf(WorldState.money_rng.randf_range(10.0, 140.0), 0.01)
		_udgoap_state["initial_money"] = _udgoap_state["current_money"]
		_udgoap_state["current_bladder"] = snappedf(WorldState.bladder_rng.randf_range(0.0, 70.0), 0.01)
		for key in preference.keys():
			preference[key] = WorldState.preference_rng.randi_range(2, 8) / 10.0
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
	print_npc_variables()
	
	$SubViewportContainer/SubViewport/ProgressBar.max_value = _udgoap_state["satisfaction_limit"]
	$SubViewportContainer/SubViewport/ProgressBar2.max_value = _udgoap_state["bladder_limit"]
	
	# --- UD-GOAP Setup ---
	# We define motivations instead of GoapGoals.
	_motivations = [
		BeSatisfiedMotivation.new(),
		SaveMoneyMotivation.new(),
		BeRelievedMotivation.new(),
		BeEntertainedMotivation.new(),
		GoHomeMotivation.new(),
	]
	
	# Note: We initialize the planner with list_pref, but the planner implementation 
	# will need to change to support Utility later.
	_action_planner = UDGoapActionPlanner.new(list_pref)


var ai_timer := 0.0
var exec_interval := 0.2  # update 5 times per second
func _physics_process(delta: float) -> void:
	ai_timer += delta
	if ai_timer >= exec_interval:
		ai_timer -= exec_interval
		
		# In UD-GOAP, we update continuous state, but we don't necessarily need to 
		# "booleanize" it like in classic GOAP.
		update_udgoap_state()
		
		# Update HUD ----------------------------------------------------------
		var best_mot_name = _current_motivation.name if _current_motivation else "None"
		var text := "Active Motivation: %s\n" % best_mot_name
		text += "Money: %f\n" % _udgoap_state["current_money"]
		text += "Bill: %f\n" % _udgoap_state["current_bill"]
		text += "Bladder: %f\n" % _udgoap_state["current_bladder"]
		text += "Satisfaction: %f\n" % _udgoap_state["current_satisfaction"]
		for key in _udgoap_state.keys():
			text += "%s: %s\n" % [key, str(_udgoap_state[key])]
		# Debug utilities
		for m in _motivations:
			text += "%s Util: %.2f\n" % [m.name, m.get_utility(_udgoap_state)]
			
		text += "%s\n" % str(list_pref)
		text += str(self)
		$labels/label_money.text = text
		$SubViewportContainer/SubViewport/ProgressBar.value = _udgoap_state["current_satisfaction"]
		$SubViewportContainer/SubViewport/ProgressBar2.value = _udgoap_state["current_bladder"]
		# Update HUD ----------------------------------------------------------
		
		# --- UD-GOAP Decision Logic ---
		# 1. Identify the most critical motivation (lowest utility value).
		# According to the Sloan paper, the "motivation with the lowest motivation value is selected for planning."
		var best_motivation = _get_best_motivation()
		
		# 2. Re-plan if the motivation changes or we have no plan
		if _current_motivation == null or best_motivation != _current_motivation:
			# In UD-GOAP, the planner needs the agent itself to test actions against utility curves,
			# or we pass the specific values.
			var blackboard = {
				"position": global_position,
				"actor": self,
				"motivations": _motivations, # Pass motivations so actions can predict utility changes
			}
			blackboard.merge(_udgoap_state, true)
			blackboard.merge(WorldState._state, true)
			
			_current_motivation = best_motivation
			# Request Plan
			# NOTE: _action_planner needs to be updated to accept a Motivation object 
			# instead of a GoapGoal, or we wrap the Motivation in a Goal structure temporarily.
			_current_plan = _action_planner.get_plan(_current_motivation, blackboard)
			_current_plan_step = 0
			can_perform = true
			going_already = false
		else:
			_follow_plan(_current_plan, delta)

	# Gravity and Movement (Unchanged)
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	var destination = navigation_agent_3d.get_next_path_position()
	var local_destination = destination - global_position
	var direction = local_destination.normalized()
	
	velocity = direction * SPEED
	move_and_slide()

# Updates context data that might be needed by actions (like item prices),
# but avoids hard boolean logic for the core planner where possible.
func update_udgoap_state() -> void:
	# We maintain some logic to help actions decide context, 
	# but the decision to act comes from Utility, not these booleans.
	_udgoap_state["needs_wc"] = _udgoap_state["current_bladder"] >= _udgoap_state["bladder_limit"]* 2/3
	_udgoap_state["is_satisfied"] = _udgoap_state["current_satisfaction"] >= _udgoap_state["satisfaction_limit"]
	_udgoap_state["payed"] = (_udgoap_state["current_bill"] == 0.0)
	
	var min_price := 10000000.0
	var found := false
	for item in WorldState.get_elements("item"):
		if not item.client_holding and (item.type in list_pref):
			if not found or item.cost < min_price:
				min_price = item.cost
				found = true
	
	_udgoap_state["done_shopping"] = ((_udgoap_state["current_money"] - _udgoap_state["current_bill"]) < min_price) or _udgoap_state["is_satisfied"] or not found
	# We store these in _udgoap_state for the Blackboard, 
	# in case 'ShopAction' needs to know if shopping is viable.
	#_udgoap_state["min_price"] = min_price
	#_udgoap_state["items_available"] = found


# UD-GOAP: Selects the motivation with the lowest current utility.
# This represents the "most unsatisfied" desire.
func _get_best_motivation():
	var lowest_motivation = null
	var lowest_val = 2.0 # Utility is 0.0 to 1.0, so 2.0 is safe max
	
	for motivation in _motivations:
		var util = motivation.get_utility(_udgoap_state)
		# We want to fix the problem that is most urgent (lowest utility)
		if lowest_motivation == null or util < lowest_val:
			lowest_val = util
			lowest_motivation = motivation
			
	return lowest_motivation

# Executes plan (Mostly unchanged, as execution logic is similar)
func _follow_plan(plan, delta):
	if plan.size() == 0:
		return
	
	# UD-Note: We might need to check if the plan is still valid based on utility thresholds,
	# but for now we stick to the standard sequence check.
	if not plan[_current_plan_step].is_valid(self):
		_current_motivation = null
		return
	
	if can_perform:
		var is_step_complete = plan[_current_plan_step].perform(self, delta)
		
		if is_step_complete:
			_current_plan_step += 1
			if _current_plan_step >= plan.size():
				#plan finish successfully
				_current_motivation = null
				_current_plan = []
				_current_plan_step = 0
			else: 
				print(str(self) + " proxima action")

func vanish() -> void:
	for i in itens_list:
		if i: i.queue_free()
	itens_list = []
	#self.queue_free()

func print_npc_variables():
	print(str(self) + "----------------------------------NEW UD-GOAP NPC----------------------------------")
	print(str(self) + " money: ", _udgoap_state["current_money"])
	print(str(self) + " bladder: ", _udgoap_state["current_bladder"])
	print(str(self) + " preferences: ", list_pref)
	for key in preference.keys():
		print(str(self)," ", key,": ", preference[key])
	print(str(self) + "-----------------------------------------------------------------------------------")
