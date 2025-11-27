extends CharacterBody3D

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var ud_goap = false
var agent

var going_already = false
var is_attacking = false

var money := 200.0
var bill := 0.0

var bladder := 0.0
var bladder_limit := 100.0

var satisfaction := 0.0
var satisfaction_limit := 100.0

var do_distance := 5.0

var itens_list = []
var preference = {
	"refrigerante": 0.5,
	"suco": 0.5,
	"agua": 0.5,
	"doce": 0.5,
	"carne": 0.5,
	"massa": 0.5
}

var _state = {
	"satisfaction": 0.0,
	"satisfaction_limit": satisfaction_limit,
	"done_shopping": false,
	"money": money,
	"bill": bill,
	"payed": false,
	"bladder": bladder,
	"bladder_limit": bladder_limit,
	"used_wc": false,
	"watching": false,
	"out": false,
	"is_in_debt": false
}


#TIRAR DEPOIS
#func _unhandled_input(event: InputEvent) -> void:
	#if event.is_action_pressed("enter"):
	#	var random_position := Vector3.ZERO
	#	random_position.x = randf_range(-20.0, 10.0)
	#	random_position.z = randf_range(-12.0, 12.0)
	#	navigation_agent_3d.set_target_position(random_position)

func _ready():
	#define variaveis aleatorias para esse npc
	if WorldState.random:
		_state["money"] = randf_range(100.0, 400.0)
		_state["bladder"] = randf_range(0.0, 70.0)
		for key in preference.keys():
			preference[key] = randi_range(0, 10) / 10.0      # convert to 0.0–1.0 in 0.1 steps
	else:
		_state["money"] = WorldState.money_rng.randf_range(40.0, 50.0)
		_state["bladder"] = WorldState.bladder_rng.randf_range(0.0, 70.0)
		for key in preference.keys():
			preference[key] = WorldState.preference_rng.randi_range(2, 8) / 10.0      # convert to 0.0–1.0 in 0.1 steps
	print_npc_variables()
	
	$SubViewportContainer/SubViewport/ProgressBar.max_value = satisfaction_limit
	$SubViewportContainer/SubViewport/ProgressBar2.max_value = bladder_limit
	
	
	agent = GoapAgent.new()
	agent.init(self, [
		PickItensGoal.new(),
		LeaveGoal.new(),
		WatchTVGoal.new(),
		UseWCGoal.new()
	])
	apply_type()
	add_child(agent)



func _physics_process(delta: float) -> void:
	var text := "Goal: %s\n" % agent._current_goal.get_clazz() if agent._current_goal else ""
	for key in _state.keys():
		text += "%s: %s\n" % [key, str(_state[key])]
	$labels/label_money.text = text
	$SubViewportContainer/SubViewport/ProgressBar.value = _state["satisfaction"]
	$SubViewportContainer/SubViewport/ProgressBar2.value =_state["bladder"]
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	var destination = navigation_agent_3d.get_next_path_position()
	var local_destination = destination - global_position
	var direction = local_destination.normalized()
	
	velocity = direction * SPEED
	move_and_slide()
	update_worldstate()


func update_worldstate() -> void:
	#WorldState.
	pass


func vanish() -> void:
	for i in itens_list:
		if i: i.queue_free()
	itens_list = []
	#self.queue_free()


func print_npc_variables():
	print("------------------------------------------------------------------NEW NPC------------------------------------------------------------------")
	print("money: ", _state["money"])
	print("bladder: ", _state["bladder"])
	print("money: ", _state["money"])
	for key in preference.keys():
		print(key,": ", preference[key])
	print("------------------------------------------------------------------NEW NPC------------------------------------------------------------------")

func apply_type():
	var mes
	if ud_goap:
		$MeshInstance3D.material_override = load("res://assets/udgoap.tres")
		mes = load("res://assets/client_udgoap.tres")
	else:
		mes = load("res://assets/client_goap.tres")
	$MeshInstance3D.mesh = mes
