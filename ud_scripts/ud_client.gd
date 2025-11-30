extends CharacterBody3D

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

const SPEED = 1.0
const JUMP_VELOCITY = 4.5

var agent

var going_already = false

# --- Continuous State Variables (True State/Display) ---
# These are the agent's actual numerical values, not used directly by the classic planner.
#var current_money: float = 200.0
#var current_bill: float = 0.0
#var current_bladder: float = 0.0
#var bladder_limit: float = 100.0
#var current_satisfaction: float = 0.0
#var satisfaction_limit: float = 100.0

var do_distance : float = 5.0

var itens_list = []
var preference = {
	"refrigerante": 0.5,
	"suco": 0.5,
	"agua": 0.5,
	"doce": 0.5,
	"carne": 0.5,
	"massa": 0.5
}

var _udgoap_state = {
	"satisfaction": 0.0,
	"satisfaction_limit": 100.0, #doesnt change
	"is_satisfied": false, #if satisfaction >= satisfaction_limit
	"done_shopping": false, #if the npc cant pick up more itens because any item cost + bill > money
	"money": 200.0,
	"bill": 0.0,
	"has_money_to_pay": true, #if current_money >= current_bill
	"payed": true, #if performed sucessfully the pay action
	"bladder": 0.0,
	"bladder_limit": 100.0, #doesnt change
	"needs_wc": false, #if current_bladder is more than 1/3
	"used_wc": false, #if performed sucessfully the pee action
	"watching": false, #if is performing the action watch
	"out": false, #if performed sucessfully the get_out action
}

var _goals
var _current_goal
var _current_plan
var _current_plan_step = 0

var _action_planner =  UDGoapActionPlanner.new()

var can_perform = true

func _ready():
	#define variaveis aleatorias para esse npc
	if WorldState.random:
		_udgoap_state["money"] = randf_range(100.0, 400.0)
		_udgoap_state["bladder"] = randf_range(0.0, 70.0)
		for key in preference.keys():
			preference[key] = randi_range(0, 10) / 10.0      # convert to 0.0–1.0 in 0.1 steps
	else:
		_udgoap_state["money"] = WorldState.money_rng.randf_range(40.0, 150.0)
		_udgoap_state["bladder"] = WorldState.bladder_rng.randf_range(0.0, 70.0)
		for key in preference.keys():
			preference[key] = WorldState.preference_rng.randi_range(2, 8) / 10.0      # convert to 0.0–1.0 in 0.1 steps
	print_npc_variables()
	
	$SubViewportContainer/SubViewport/ProgressBar.max_value = _udgoap_state["satisfaction_limit"]
	$SubViewportContainer/SubViewport/ProgressBar2.max_value = _udgoap_state["bladder_limit"]
	
	#isso talvez mude depois // udgoap gerar os goal apartir das motivations
	_goals = [
		UDPickItensGoal.new(),
		UDLeaveGoal.new(),
		UDWatchTVGoal.new(),
		UDUseWCGoal.new()
	]



var ai_timer := 0.0
var exec_interval := 0.2  # update 5 times per second
func _physics_process(delta: float) -> void:
	ai_timer += delta
	if ai_timer >= exec_interval:
		ai_timer -= exec_interval
		update_udgoap_state()
		# Update HUD ----------------------------------------------------------
		var text := "Goal: %s\n" % agent._current_goal.get_clazz() if agent._current_goal else ""
		for key in _udgoap_state.keys():
			text += "%s: %s\n" % [key, str(_udgoap_state[key])]
		$labels/label_money.text = text
		$SubViewportContainer/SubViewport/ProgressBar.value = _udgoap_state["satisfaction"]
		$SubViewportContainer/SubViewport/ProgressBar2.value =_udgoap_state["bladder"]
		# Update HUD ----------------------------------------------------------

		var goal = _get_best_goal()
		#print("OBJETIVO ATUAL", goal.get_clazz())
		#print(goal.get_clazz())
		if _current_goal == null or goal != _current_goal:
		# You can set in the blackboard any relevant information you want to use
		# when calculating action costs and status. I'm not sure here is the best
		# place to leave it, but I kept here to keep things simple.
			var blackboard = {
				"position": global_position,
				"actor": self,
				"world_state": _udgoap_state
				}
			_udgoap_state.set("watching", false)
			_current_goal = goal
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
func update_udgoap_state() -> void:
	# Boolean assignments for GOAP planning
	_udgoap_state["needs_wc"] = _udgoap_state["bladder"] >= _udgoap_state["bladder_limit"] / 3
	_udgoap_state["is_satisfied"] = _udgoap_state["satisfaction"] >= _udgoap_state["satisfaction_limit"]
	_udgoap_state["has_money_to_pay"] = _udgoap_state["money"] >= _udgoap_state["bill"]
	_udgoap_state["payed"] = _udgoap_state["bill"] == 0.0
	
	# Note: Other booleans (done_shopping, payed, used_wc) must be set by actions/goals.


# Returns the highest priority goal available.
#
func _get_best_goal():
	var highest_priority: GoapGoal = null

	for goal in _goals:
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
			else: print("proxima action")
	#print(WorldState._state)
	#print(is_step_complete)
	#print(_current_plan_step)
	#print(plan.size())
	


func vanish() -> void:
	for i in itens_list:
		if i: i.queue_free()
	itens_list = []
	#self.queue_free()


func print_npc_variables():
	print("------------------------------------------------------------------NEW NPC------------------------------------------------------------------")
	print("money: ", _udgoap_state["money"])
	print("bladder: ", _udgoap_state["bladder"])
	for key in preference.keys():
		print(key,": ", preference[key])
	print("------------------------------------------------------------------NEW NPC------------------------------------------------------------------")
