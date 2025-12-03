extends CharacterBody3D

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

const SPEED = 10.0
const JUMP_VELOCITY = 4.5

var going_already = false

# --- Continuous State Variables (True State/Display) ---
# These are the agent's actual numerical values, not used directly by the classic planner.
var current_money: float = 200.0
var current_bill: float = 0.0
var current_bladder: float = 0.0
var bladder_limit: float = 100.0
var current_satisfaction: float = 0.0
var satisfaction_limit: float = 100.0

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

var _goap_state = {
	"is_satisfied": false, #if satisfaction >= satisfaction_limit
	"done_shopping": false, #if the npc cant pick up more itens because any item cost + bill > money
	"payed": true, #if performed sucessfully the pay action
	"needs_wc": false, #if current_bladder is more than 1/3
	"used_wc": false, #if performed sucessfully the pee action
	"watching": false, #if is performing the action watch
	"out": false, #if performed sucessfully the get_out action
}

var _goals: Array = []
var _current_goal: GoapGoal = null
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
	#define variaveis aleatorias para esse npc
	if WorldState.random:
		current_money = snappedf(randf_range(40.0, 150.0), 0.01)
		current_bladder = snappedf(randf_range(0.0, 70.0), 0.01)
		for key in preference.keys():
			preference[key] = randi_range(2, 8) / 10.0      # convert to 0.0–1.0 in 0.1 steps
	else:
		current_money = snappedf(WorldState.money_rng.randf_range(10.0, 140.0), 0.01)
		dinheiro_inicial = current_money
		current_bladder = snappedf(WorldState.bladder_rng.randf_range(0.0, 70.0), 0.01)
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
	
	$SubViewportContainer/SubViewport/ProgressBar.max_value = satisfaction_limit
	$SubViewportContainer/SubViewport/ProgressBar2.max_value = bladder_limit
	
	_goals = [
		PickItensGoal.new(),
		LeaveGoal.new(),
		WatchTVGoal.new(),
		UseWCGoal.new()
	]
	
	_action_planner =  GoapActionPlanner.new(list_pref)


var ai_timer := 0.0
var exec_interval := 0.2  # update 5 times per second
func _physics_process(delta: float) -> void:
	ai_timer += delta
	if ai_timer >= exec_interval:
		ai_timer -= exec_interval
		update_goap_state()
		
		# Update HUD ----------------------------------------------------------
		var text := "Goal: %s\n" % _current_goal.get_clazz() if _current_goal else "None"
		text += "Money: %f\n" % current_money
		text += "Bill: %f\n" % current_bill
		text += "Bladder: %f\n" % current_bladder
		text += "Satisfaction: %f\n" % current_satisfaction
		for key in _goap_state.keys():
			text += "%s: %s\n" % [key, str(_goap_state[key])]
		text += "%s\n" % str(list_pref)
		text += str(self)
		$labels/label_money.text = text
		$SubViewportContainer/SubViewport/ProgressBar.value = current_satisfaction
		$SubViewportContainer/SubViewport/ProgressBar2.value = current_bladder
		# Update HUD ----------------------------------------------------------

		# On every loop this script checks if the current goal is still
		# the highest priority. if it's not, it requests the action planner a new plan
		# for the new high priority goal.
		var goal = _get_best_goal()
		#print("OBJETIVO ATUAL", goal.get_clazz())
		#print(goal.get_clazz())
		if _current_goal == null or goal != _current_goal:
			var blackboard = {
				"position": global_position,
				"actor": self,
				}
			blackboard.merge(_goap_state, true)
			blackboard.merge(WorldState._state, true)
			_goap_state.set("watching", false)
			_current_goal = goal
			vezes_planejou += 1
			_current_plan = _action_planner.get_plan(_current_goal, blackboard)
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
	var bladder_threshold = bladder_limit * 2/3
	
	# Boolean assignments for GOAP planning
	_goap_state["needs_wc"] = current_bladder >= bladder_threshold
	_goap_state["is_satisfied"] = current_satisfaction >= satisfaction_limit
	_goap_state["payed"] = (current_bill == 0.0)
	
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
	_goap_state["done_shopping"] = ((current_money - current_bill) < min_price) or _goap_state["is_satisfied"] or not found

	
	# Note: Other booleans (done_shopping, payed, used_wc) must be set by actions/goals.

# Returns the highest priority goal available.
func _get_best_goal():
	var highest_priority: GoapGoal = null
	
	for goal in _goals:
		#print("goal: ", goal.get_clazz(), " | ", goal.is_valid(self), " | priority: ", goal.priority(self))
		if goal.is_valid(self) and (highest_priority == null or goal.priority(self) > highest_priority.priority(self)):
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
	
	if not plan[_current_plan_step].is_valid(self):
		_current_goal = null
		return
	
	if can_perform:
		var is_step_complete = plan[_current_plan_step].perform(self, delta)
		
		if is_step_complete:
			_current_plan_step += 1
			if _current_plan_step >= plan.size():
				#plan finish successfully
				_current_goal = null
				_current_plan = []
				_current_plan_step = 0
			#else: print(str(self) + " proxima action")
	#print(WorldState._state)
	#print(is_step_complete)
	#print(_current_plan_step)
	#print(plan.size())


func vanish() -> void:
	var results = "%s|%f|%f|%d|%f|%s|%s" % [str(self), dinheiro_inicial, current_money, vezes_planejou, current_satisfaction, str(tempo_inicial), str(Time.get_unix_time_from_system()) ]
	WorldState.write_to_file(results)
	for i in itens_list:
		if i: i.queue_free()
	itens_list = []
	self.queue_free()
	WorldState.close_game(self)

func print_npc_variables():
	print(str(self) + "------------------------------------------------------------------NEW GOAP NPC------------------------------------------------------------------")
	print(str(self) + " money: ", current_money)
	print(str(self) + " bladder: ", current_bladder)
	print(str(self) + " will only pick: ", list_pref)
	for key in preference.keys():
		print(str(self)," ", key,": ", preference[key])
	print(str(self) + "------------------------------------------------------------------NEW GOAP NPC------------------------------------------------------------------")
